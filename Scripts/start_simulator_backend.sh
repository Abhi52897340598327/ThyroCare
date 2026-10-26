#!/bin/bash
# Run from any directory. Keep this terminal open while using the simulator.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root/Backend"
swift build --disable-sandbox --build-system native \
    --cache-path /tmp/thyrocare-swift-cache \
    -Xswiftc -module-cache-path -Xswiftc /tmp/thyrocare-module-cache
export HOST=0.0.0.0
export PORT=8080
export CARE_WEB_ORIGIN=http://localhost:3000
export CARE_DATA_DIRECTORY="$project_root/Backend/CareData"
exec .build/debug/Run
