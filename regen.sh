#!/usr/bin/env bash
# Wrapper around `xcodegen generate` that re-applies manual pbxproj patches
# xcodegen 2.25 cannot model folder.iconcomposer.icon (Xcode 26 type), so
# chalk_app_icon.icon must be wired in manually after every regeneration.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PBXPROJ="$SCRIPT_DIR/Chalk.xcodeproj/project.pbxproj"

xcodegen generate

python3 - "$PBXPROJ" <<'PYTHON'
import sys, pathlib

path = pathlib.Path(sys.argv[1])
src = path.read_text()

FILE_REF = '\t\tAA1B2C3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon */ = {isa = PBXFileReference; lastKnownFileType = folder.iconcomposer.icon; path = chalk_app_icon.icon; sourceTree = "<group>"; };'
BUILD_FILE_IOS   = '\t\tCC1A2B3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon in Resources */ = {isa = PBXBuildFile; fileRef = AA1B2C3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon */; };'
BUILD_FILE_WATCH = '\t\tDD2A3B4C5D6E7F8A9B0C1D2E /* chalk_app_icon.icon in Resources */ = {isa = PBXBuildFile; fileRef = AA1B2C3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon */; };'

patches = [
    # 1. PBXFileReference entry
    (
        '/* End PBXFileReference section */',
        FILE_REF + '\n/* End PBXFileReference section */'
    ),
    # 2. PBXBuildFile entries
    (
        '/* End PBXBuildFile section */',
        BUILD_FILE_IOS + '\n' + BUILD_FILE_WATCH + '\n/* End PBXBuildFile section */'
    ),
    # 3. File ref in Chalk group (after Assets.xcassets)
    (
        'F4653102AB269C5F14198ED2 /* Assets.xcassets */,\n\t\t\t\t98F12DA7CE371E02E20D1218 /* Chalk.entitlements */,',
        'F4653102AB269C5F14198ED2 /* Assets.xcassets */,\n\t\t\t\tAA1B2C3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon */,\n\t\t\t\t98F12DA7CE371E02E20D1218 /* Chalk.entitlements */,'
    ),
    # 4. File ref in ChalkWatch group (after Assets.xcassets)
    (
        '871B0D601CAFFDC4967012FB /* Assets.xcassets */,\n\t\t\t\t90F9C85CBBFFCF10A9B5763B /* ChalkWatch.entitlements */,',
        '871B0D601CAFFDC4967012FB /* Assets.xcassets */,\n\t\t\t\tAA1B2C3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon */,\n\t\t\t\t90F9C85CBBFFCF10A9B5763B /* ChalkWatch.entitlements */,'
    ),
    # 5. Build file in iOS Resources phase (888924702A17F06A644D7203)
    (
        '39E8F6EA15A0388675697DDC /* Assets.xcassets in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\tDCC355C91E37DA97EB3A9289 /* Resources */',
        '39E8F6EA15A0388675697DDC /* Assets.xcassets in Resources */,\n\t\t\t\tCC1A2B3D4E5F6A7B8C9D0E1F /* chalk_app_icon.icon in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n\t\tDCC355C91E37DA97EB3A9289 /* Resources */'
    ),
    # 6. Build file in ChalkWatch Resources phase (DCC355C91E37DA97EB3A9289)
    (
        '815574C0DC5556766D3BBB6E /* Assets.xcassets in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXResourcesBuildPhase section */',
        '815574C0DC5556766D3BBB6E /* Assets.xcassets in Resources */,\n\t\t\t\tDD2A3B4C5D6E7F8A9B0C1D2E /* chalk_app_icon.icon in Resources */,\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t};\n/* End PBXResourcesBuildPhase section */'
    ),
]

already_patched = 'AA1B2C3D4E5F6A7B8C9D0E1F' in src

if already_patched:
    print("regen.sh: chalk_app_icon.icon patches already present, skipping.")
    sys.exit(0)

for old, new in patches:
    if old not in src:
        print(f"regen.sh: WARNING — patch anchor not found:\n  {old[:80]}...", file=sys.stderr)
        sys.exit(1)
    src = src.replace(old, new, 1)

path.write_text(src)
print("regen.sh: chalk_app_icon.icon patches applied successfully.")
PYTHON
