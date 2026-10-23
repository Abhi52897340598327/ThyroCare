#!/usr/bin/env python3
"""Synthetic localhost integration test. Creates temporary storage; never uses deployed patient data."""
import json
import os
import pathlib
import socket
import subprocess
import tempfile
import time
import urllib.request
import urllib.error
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
BINARY = ROOT / "Backend/.build/debug/Run"

def main():
    with tempfile.TemporaryDirectory(prefix="thyrocare-api-test-") as storage:
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0)); port = sock.getsockname()[1]
        base = f"http://127.0.0.1:{port}/v1/"
        password = "synthetic-test-" + uuid.uuid4().hex
        env = dict(os.environ, CARE_DATA_DIRECTORY=storage, HOST="127.0.0.1", PORT=str(port))
        provision = dict(env, CARE_PROVISION_CLINICIAN="1", CARE_CLINICIAN_EMAIL="clinician@example.test", CARE_CLINICIAN_NAME="Synthetic Clinician", CARE_CLINICIAN_PASSWORD=password)
        subprocess.run([str(BINARY)], env=provision, cwd=ROOT / "Backend", check=True, stdout=subprocess.DEVNULL)
        log = open(pathlib.Path(storage) / "server.log", "w")
        server = None
        def start():
            process = subprocess.Popen([str(BINARY)], env=env, cwd=ROOT / "Backend", stdout=log, stderr=log)
            for _ in range(100):
                try:
                    urllib.request.urlopen(f"http://127.0.0.1:{port}/health", timeout=1).close()
                    return process
                except Exception:
                    if process.poll() is not None: raise RuntimeError("Test server failed to start")
                    time.sleep(.1)
            process.terminate(); raise RuntimeError("Test server did not become ready")
        def call(path, method="GET", body=None, token=None, expected=200):
            headers = {"Content-Type": "application/json"}
            if token: headers["Authorization"] = "Bearer " + token
            req = urllib.request.Request(base + path, data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method)
            try:
                with urllib.request.urlopen(req, timeout=10) as response:
                    status, data = response.status, response.read()
            except urllib.error.HTTPError as error:
                status, data = error.code, error.read()
            assert status == expected, (method, path, status, expected, data)
            return json.loads(data) if data else None
        def write(patient, kind, fields, token, id=None, version=0):
            return call(f"patients/{patient}/{kind}", "POST", {"id": id or str(uuid.uuid4()), "expectedVersion": version, "fields": fields}, token)
        try:
            server = start()
            a = call("auth/register", "POST", {"email": "a@example.test", "password": password, "name": "Synthetic A"})
            b = call("auth/register", "POST", {"email": "b@example.test", "password": password, "name": "Synthetic B"})
            clinician = call("auth/login", "POST", {"email": "clinician@example.test", "password": password})
            pid, token, ct = a["user"]["id"], a["token"], clinician["token"]
            for kind in ["labs", "symptoms", "weekly-checkins", "medications", "vitals", "meals", "messages", "notes", "requests", "appointments", "care-plans", "administrations", "questionnaire"]:
                assert call(f"patients/{pid}/{kind}", token=token) == []
            meal = write(pid, "meals", {"description": "Synthetic manual meal", "observedDate": "2026-01-02", "mealTime": "12:00"}, token)
            assert call(f"patients/{pid}/meals", token=token) == [meal]
            call("auth/login", "POST", {"email": "a@example.test", "password": "wrong-password"}, expected=401)
            call(f"patients/{pid}/labs", token=b["token"], expected=403)
            call(f"patients/{pid}/labs", token=ct, expected=403)
            invitation = call("invitations", "POST", token=ct)
            preview = call("invitations/preview", "POST", invitation, token)
            assert preview["id"] == clinician["user"]["id"]
            call("invitations/accept", "POST", invitation, token, 204)
            questionnaire = write(pid, "questionnaire", {"step": "2", "status": "in-progress", "ironSupplement": "", "source": "Patient-reported questionnaire"}, token)
            lab = write(pid, "labs", {"analyte": "Free T4", "result": "<0.01", "unit": "ng/dL", "receivedDate": "2026-01-02", "source": "Synthetic report"}, token)
            same = write(pid, "labs", lab["fields"], token, lab["id"])
            assert same == lab
            message = write(pid, "messages", {"body": "I received my Free T4 result today"}, token)
            assert call(f"patients/{pid}/messages", token=ct)[0] == message
            reply = write(pid, "messages", {"body": "Please upload or enter the report interval."}, ct)
            note = write(pid, "notes", {"body": "Synthetic clinician discussion", "state": "signed", "visibility": "patient"}, ct)
            assert call(f"patients/{pid}/notes", token=token)[0] == note
            request = write(pid, "requests", {"body": "Please confirm the interval", "status": "Submitted"}, token)
            answered = write(pid, "requests", {**request["fields"], "status": "Answered", "response": "Please use the interval on the original report."}, ct, request["id"], 1)
            assert call(f"patients/{pid}/requests", token=token)[0] == answered
            server.terminate(); server.wait(timeout=10); server = start()
            messages = call(f"patients/{pid}/messages", token=token)
            assert messages == [message, reply]
            assert call(f"patients/{pid}/messages", token=ct) == messages
            assert len(call(f"patients/{pid}/labs", token=token)) == 1
            assert call(f"patients/{pid}/questionnaire", token=token) == [questionnaire]
            exported = call(f"patients/{pid}/export", token=token)
            assert exported["patientID"] == pid
            assert meal in exported["records"] and lab in exported["records"]
            call(f"patients/{pid}/export", token=b["token"], expected=403)
            call(f"care-team/{clinician['user']['id']}", "DELETE", token=token, expected=204)
            call(f"patients/{pid}/messages", token=ct, expected=403)
            call("auth/logout", "POST", token=token, expected=204)
            call("me", token=token, expected=401)
            result = {"status": "passed", "checks": ["every record collection route", "questionnaire progress survives restart", "meal collection and export", "export patient isolation", "password verification", "patient ID isolation", "clinician invitation and consent", "idempotent lab save with missing collection date and interval", "identical two-way messages", "patient-visible signed notes", "request answered by clinician", "durability across process restart", "access revocation", "session revocation"], "scope": "Local HTTP API, synthetic accounts; not device/browser interaction evidence"}
            (ROOT / "Docs/api-integration-result.json").write_text(json.dumps(result, indent=2) + "\n")
            print(json.dumps(result, indent=2))
        finally:
            if server and server.poll() is None: server.terminate(); server.wait(timeout=10)
            log.close()

if __name__ == "__main__": main()
