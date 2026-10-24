#!/usr/bin/env python3
"""Set Cindarc identity, landscape, and export compliance on an Info.plist."""

import plistlib
import sys
from pathlib import Path

LANDSCAPE = [
    "UIInterfaceOrientationLandscapeRight",
    "UIInterfaceOrientationLandscapeLeft",
]


def main() -> None:
    path = Path(sys.argv[1])
    version = sys.argv[2] if len(sys.argv) > 2 else "0.1.0"
    build = sys.argv[3] if len(sys.argv) > 3 else "1"
    bundle = sys.argv[4] if len(sys.argv) > 4 else "es.verkvest.cindarc"
    name = sys.argv[5] if len(sys.argv) > 5 else "Cindarc"
    with path.open("rb") as handle:
        data = plistlib.load(handle)
    # Keep the executable name macro so it still matches the built binary.
    data["CFBundleIdentifier"] = bundle
    data["CFBundleDisplayName"] = name
    data["CFBundleName"] = name
    data["CFBundleShortVersionString"] = version
    data["CFBundleVersion"] = str(build)
    data["ITSAppUsesNonExemptEncryption"] = False
    data["UIRequiresFullScreen"] = True
    data["UIStatusBarHidden"] = True
    data["UISupportedInterfaceOrientations"] = LANDSCAPE
    data["UISupportedInterfaceOrientations~ipad"] = LANDSCAPE
    data["NSMicrophoneUsageDescription"] = "Cindarc does not record audio."
    data["NSBluetoothAlwaysUsageDescription"] = "Cindarc does not use Bluetooth. This text is required because the LÖVE engine links the controller APIs."
    with path.open("wb") as handle:
        plistlib.dump(data, handle)
    print(f"patched {path}")


if __name__ == "__main__":
    main()
