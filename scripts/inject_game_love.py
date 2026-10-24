#!/usr/bin/env python3
"""Add ios/game.love to the LÖVE iOS target's Copy Bundle Resources phase."""

import sys
from pathlib import Path

FILE_REF = (
    "\t\tCINDARC0000000000000A1 /* game.love */ = {isa = PBXFileReference; "
    "includeInIndex = 0; lastKnownFileType = file; path = ios/game.love; "
    'sourceTree = "<group>"; };\n'
)
BUILD_FILE = (
    "\t\tCINDARC0000000000000A2 /* game.love in Resources */ = {isa = PBXBuildFile; "
    "fileRef = CINDARC0000000000000A1 /* game.love */; };\n"
)


def main() -> None:
    path = Path(sys.argv[1])
    text = path.read_text()
    if "game.love in Resources" in text:
        print("game.love already in project")
        return
    marker = "/* Begin PBXBuildFile section */\n"
    if marker not in text:
        sys.exit("PBXBuildFile section not found")
    text = text.replace(marker, marker + BUILD_FILE, 1)
    marker = "/* Begin PBXFileReference section */\n"
    if marker not in text:
        sys.exit("PBXFileReference section not found")
    text = text.replace(marker, marker + FILE_REF, 1)
    old = """\t\tFA0B7F041A95AAF3000E1D17 /* Resources */ = {
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""
    new = old + "\t\t\t\tCINDARC0000000000000A2 /* game.love in Resources */,\n"
    if old not in text:
        sys.exit("love-ios Resources phase not found")
    text = text.replace(old, new, 1)
    old_group = "\t\t\t\tFA5D24971A96CE1E00C6FC8F /* love-ios.plist */,"
    new_group = old_group + "\n\t\t\t\tCINDARC0000000000000A1 /* game.love */,"
    if old_group not in text:
        sys.exit("love-ios.plist group entry not found")
    text = text.replace(old_group, new_group, 1)
    path.write_text(text)
    print("injected game.love into love-ios")


if __name__ == "__main__":
    main()
