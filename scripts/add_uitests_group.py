"""Attach a BoxHelperUITests source folder to BoxHelper's existing (empty) UI test target.

Build-step only: BoxHelper's app sources are not touched. The project uses
Xcode 16+ synchronized folders (objectVersion 77), so one root group pointing
at BoxHelperUITests/ is enough for xcodebuild to compile the test files in it.
"""

import pathlib
import sys

GROUP_ID = "CA9000000000000000000001"
UITEST_TARGET_ID = "841B925C2DC02D2D0012A574"
MAIN_GROUP_MARKER = "mainGroup = "

pbx_path = pathlib.Path(sys.argv[1])
text = pbx_path.read_text(encoding="utf-8")

if GROUP_ID in text:
    print("already patched")
    sys.exit(0)

group = (
    f"\t\t{GROUP_ID} /* BoxHelperUITests */ = {{\n"
    "\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n"
    "\t\t\tpath = BoxHelperUITests;\n"
    '\t\t\tsourceTree = "<group>";\n'
    "\t\t};\n"
)
end_marker = "/* End PBXFileSystemSynchronizedRootGroup section */"
assert end_marker in text
text = text.replace(end_marker, group + end_marker, 1)

main_group_id = text.split(MAIN_GROUP_MARKER, 1)[1].split(";", 1)[0].strip()
main_block_start = text.index(f"\t\t{main_group_id}")
children_at = text.index("children = (\n", main_block_start) + len("children = (\n")
text = text[:children_at] + f"\t\t\t\t{GROUP_ID} /* BoxHelperUITests */,\n" + text[children_at:]

target_start = text.index(f"\t\t{UITEST_TARGET_ID} /* BoxHelperUITests */ = {{")
name_at = text.index("\t\t\tname = BoxHelperUITests;", target_start)
text = (
    text[:name_at]
    + f"\t\t\tfileSystemSynchronizedGroups = (\n\t\t\t\t{GROUP_ID} /* BoxHelperUITests */,\n\t\t\t);\n"
    + text[name_at:]
)

pbx_path.write_text(text, encoding="utf-8")
print("patched", pbx_path)
