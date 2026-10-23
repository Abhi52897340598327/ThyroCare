#!/usr/bin/env python3
"""Download public research inputs, verify file signatures and produce a checksummed manifest.
Raw public data are ignored by Git. This script never accesses operational patient records.
"""
import concurrent.futures
import datetime
import hashlib
import json
import pathlib
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
DEST = ROOT / "Research" / "raw"
FAMILIES = ["THYROD", "DEMO", "BMX", "DR1TOT", "DR2TOT", "RXQ_RX", "BPX", "DPQ", "SLQ", "MCQ", "UIO", "VID"]

def fetch(item):
    url, name, kind = item
    target = DEST / name
    if target.exists():
        data = target.read_bytes()
    else:
        request = urllib.request.Request(url, headers={"User-Agent": "ThyroCareResearchManifest/1.0"})
        with urllib.request.urlopen(request, timeout=90) as response:
            data = response.read()
    if kind == "xpt" and not data.startswith(b"HEADER RECORD*******LIBRARY HEADER RECORD"):
        raise ValueError(f"Not an XPT file: {name}")
    if kind == "zip" and not data.startswith(b"PK"):
        raise ValueError(f"Not a ZIP archive: {name}")
    if kind == "codebook" and b"<html" not in data[:1000].lower():
        raise ValueError(f"Not an HTML codebook: {name}")
    target.write_bytes(data)
    return {"file": name, "url": url, "kind": kind, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()}

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    items = []
    for year, suffix in [(2007, "E"), (2009, "F"), (2011, "G")]:
        for family in FAMILIES:
            for ext, kind in [("xpt", "xpt"), ("htm", "codebook")]:
                name = f"{family}_{suffix}.{ext}"
                items.append((f"https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{name}", name, kind))
    items.append(("https://archive.ics.uci.edu/static/public/102/thyroid+disease.zip", "uci-thyroid-disease.zip", "zip"))
    records, failures = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(fetch, item): item for item in items}
        for future in concurrent.futures.as_completed(futures):
            try:
                record = future.result()
                records.append(record)
                print("Verified", record["file"], flush=True)
            except Exception as error:
                failures.append({"url": futures[future][0], "error": str(error)})
    manifest = {"retrieved_at": datetime.datetime.now(datetime.timezone.utc).isoformat(), "purpose": "Cross-sectional research only; not longitudinal symptom or meal-response validation", "files": sorted(records, key=lambda r: r["file"]), "failures": failures}
    (ROOT / "Research" / "data-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"{len(records)} verified files; {len(failures)} failures")
    if failures:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
