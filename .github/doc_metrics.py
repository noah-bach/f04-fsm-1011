import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
metrics = data.get("metrics", data)

if not isinstance(metrics, dict):
    raise SystemExit("Unsupported metrics format")

print(f"Metrics source: {path}")
keywords = ("instance", "area", "timing", "drc", "lvs",
            "antenna", "power", "clock")

for key, value in sorted(metrics.items()):
    if any(word in key.lower() for word in keywords):
        print(f"{key}: {json.dumps(value, ensure_ascii=False)}")
