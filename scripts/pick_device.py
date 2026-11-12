"""Create a standard portrait iPhone for a runtime and print its UDID.

Tries the requested device type first, then 'iPhone NN Pro' types newest first,
then other plain iPhones; foldable/wide types are only a last resort."""

import json
import re
import subprocess
import sys

runtime, wanted = sys.argv[1], sys.argv[2]
types = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "-j"]))["devicetypes"]
names = [t["name"] for t in types if t["name"].startswith("iPhone")]
print("device types:", names, file=sys.stderr)


def generation(name):
    match = re.search(r"iPhone (\d+)", name)
    return int(match.group(1)) if match else 0


pro = sorted([n for n in names if re.fullmatch(r"iPhone \d+ Pro", n)], key=generation, reverse=True)
plain = sorted([n for n in names if re.fullmatch(r"iPhone \d+", n)], key=generation, reverse=True)
order = [wanted] + pro + plain + [n for n in names if n not in pro + plain]

for name in dict.fromkeys(order):
    if name not in names:
        continue
    result = subprocess.run(["xcrun", "simctl", "create", "capture", name, runtime], capture_output=True, text=True)
    if result.returncode == 0:
        print("using:", name, file=sys.stderr)
        print(result.stdout.strip())
        sys.exit(0)
    print("skip", name, result.stderr.strip().splitlines()[-1:], file=sys.stderr)

sys.exit("no compatible iPhone device type")
