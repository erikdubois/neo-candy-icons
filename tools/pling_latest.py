#!/usr/bin/env python3
"""Print version, change date and a fresh download link of the newest Pling file whose name starts with a prefix."""
# Pling links carry a short-lived token bound to the caller's IP: use the printed URL at once
import re
import sys
import urllib.request


def _vkey(v):
    return [int(x) for x in re.findall(r"\d+", v)]


def main():
    """Query the Pling OCS API: pling_latest.py <content-id> <file-prefix>."""
    cid, prefix = sys.argv[1], sys.argv[2]
    req = urllib.request.Request(f"https://api.pling.com/ocs/v1/content/data/{cid}",
                                 headers={"User-Agent": "neo-candy-update-upstream"})
    with urllib.request.urlopen(req, timeout=60) as r:
        xml = r.read().decode()
    changed = re.search(r"<changed>([^<]*)", xml).group(1)
    files = []
    for n in sorted({int(x) for x in re.findall(r"<downloadname(\d+)>", xml)}):
        name = re.search(rf"<downloadname{n}>([^<]*)", xml).group(1)
        vm = re.search(rf"<download_version{n}>([^<]*)", xml)
        ver = vm.group(1) if vm else ""
        link = re.search(rf"<downloadlink{n}>([^<]*)", xml).group(1).replace("&amp;", "&")
        # anchored: "BeautyLine" must not match BeautyLineSimple.tar.gz
        if re.fullmatch(re.escape(prefix) + r"(-\d+)?\.(tar\.gz|tar\.xz|zip)", name):
            files.append((_vkey(ver), ver, name, link))
    if not files:
        print(f"no file starting with {prefix}", file=sys.stderr)
        return 1
    # several uploads share the top version (dated copy + plain name): the plain name is the current one
    top = max(f[0] for f in files)
    best = min((f for f in files if f[0] == top), key=lambda f: len(f[2]))
    print(f"{best[1]}\t{changed}\t{best[3]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
