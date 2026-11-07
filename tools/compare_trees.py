#!/usr/bin/env python3
"""Compare an upstream icon tree with our vendored copy and print what a sync would change."""
import argparse
import hashlib
import os
import re
import sys
from collections import Counter

JUNK = re.compile(r"(^|/)\.directory$|\(copy \d+\)| |^\.github/")
# Files of ours that are not upstream's and survive the sync
LOCAL = {"places/16/folder-library.svg"}


def walk(root):
    """Map relative path -> link target or content hash for every file and symlink under root."""
    out = {}
    for d, dirs, files in os.walk(root):
        dirs[:] = [x for x in dirs if x != ".git"]
        for f in files + [x for x in dirs if os.path.islink(os.path.join(d, x))]:
            p = os.path.join(d, f)
            rel = os.path.relpath(p, root)
            if os.path.islink(p):
                out[rel] = "L:" + os.readlink(p)
            elif os.path.isfile(p):
                with open(p, "rb") as fh:
                    out[rel] = "F:" + hashlib.md5(fh.read()).hexdigest()
    return out


def directories(root):
    """Return the Directories= entries of a theme's index.theme."""
    try:
        with open(os.path.join(root, "index.theme"), errors="ignore") as fh:
            m = re.search(r"^Directories=(.*)$", fh.read(), re.MULTILINE)
    except FileNotFoundError:
        return set()
    return set(m.group(1).split(",")) if m else set()


def main():
    """Print a per-context summary; with --list, write every path by category."""
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("upstream")
    ap.add_argument("ours")
    ap.add_argument("--list", help="write the full new/changed/removed lists to this file")
    ap.add_argument("--contexts-only", action="store_true", help="ignore files in the theme root")
    args = ap.parse_args()

    def keep(k):
        return k != "index.theme" and not (args.contexts_only and "/" not in k)

    up = {k: v for k, v in walk(args.upstream).items() if keep(k) and not JUNK.search(k)}
    ours = {k: v for k, v in walk(args.ours).items() if keep(k) and k not in LOCAL}
    cats = {
        "new": sorted(k for k in up if k not in ours),
        "changed": sorted(k for k in up if k in ours and up[k] != ours[k]),
        "removed": sorted(k for k in ours if k not in up),
    }
    same = sum(1 for k in up if ours.get(k) == up[k])
    print(f"  identical={same} new={len(cats['new'])} changed={len(cats['changed'])} "
          f"only-ours={len(cats['removed'])}")
    for name, paths in cats.items():
        if paths:
            top = Counter(os.path.dirname(p) or "." for p in paths).most_common(6)
            print(f"  {name:8} " + ", ".join(f"{d} {n}" for d, n in top))
    extra = directories(args.upstream) - directories(args.ours)
    if extra:
        print("  upstream index.theme lists directories we don't: " + ",".join(sorted(extra)))
    if args.list:
        with open(args.list, "w") as fh:
            for name, paths in cats.items():
                fh.writelines(f"{name}\t{p}\n" for p in paths)
    return 0


if __name__ == "__main__":
    sys.exit(main())
