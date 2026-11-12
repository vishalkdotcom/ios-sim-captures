"""Create a standard portrait iPhone on an iOS runtime matching the SDK version; print its UDID.

Some images ship two runtimes with one version (one only for a foldable), so every
matching runtime is tried. Preference: the requested type, then 'iPhone NN Pro'
newest first, then plain iPhones; anything else only as a last resort."""

import json
import re
import subprocess
import sys

sdk_version, wanted = sys.argv[1], sys.argv[2]
runtimes = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"]))["runtimes"]
candidates = [r for r in runtimes if r["platform"] == "iOS" and r["isAvailable"] and r["version"].startswith(sdk_version)]
types = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "-j"]))["devicetypes"]
names = [t["name"] for t in types if t["name"].startswith("iPhone")]


def generation(name):
    match = re.search(r"iPhone (\d+)", name)
    return int(match.group(1)) if match else 0


pro = sorted([n for n in names if re.fullmatch(r"iPhone \d+ Pro", n)], key=generation, reverse=True)
plain = sorted([n for n in names if re.fullmatch(r"iPhone \d+", n)], key=generation, reverse=True)
order = list(dict.fromkeys([wanted] + pro + plain + names))

for name in order:
    if name not in names:
        continue
    for runtime in candidates:
        result = subprocess.run(["xcrun", "simctl", "create", "capture", name, runtime["identifier"]],
                                capture_output=True, text=True)
        if result.returncode == 0:
            print("using:", name, "on", runtime["identifier"], runtime.get("buildversion"), file=sys.stderr)
            print(result.stdout.strip())
            sys.exit(0)

sys.exit("no compatible iPhone device type")
