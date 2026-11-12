"""Print the UDID of an available iPhone for a runtime: the requested name if present,
else a 6.1-6.3 inch 'Pro' model, else any iPhone."""

import json
import subprocess
import sys

runtime, wanted = sys.argv[1], sys.argv[2]
devices = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
phones = [d for d in devices["devices"].get(runtime, []) if d["name"].startswith("iPhone")]
print("available:", [d["name"] for d in phones], file=sys.stderr)


def rank(device):
    name = device["name"]
    if name == wanted:
        return 0
    if name.endswith(" Pro"):
        return 1
    if "Max" not in name and "Plus" not in name and "Air" not in name and " e" not in name:
        return 2
    return 3


choice = sorted(phones, key=rank)[0]
print("using:", choice["name"], file=sys.stderr)
print(choice["udid"])
