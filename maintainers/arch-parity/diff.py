"""Compare two inventories: the Arch one from arch-inventory.sh and the NixOS
one from nixos-inventory.nix. Prints, per category, what only Arch has.

    python3 diff.py arch.txt nixos.txt [category ...]
"""

import sys, collections
def load(p):
    secs = collections.OrderedDict(); cur = None
    for line in open(p):
        line = line.rstrip("\n")
        if line.startswith("## "):
            cur = line[3:]; secs.setdefault(cur, set()); continue
        if cur and line.strip():
            secs[cur].add(line.strip().lstrip("./"))
    return secs
arch, nix = load(sys.argv[1]), load(sys.argv[2])
only = sys.argv[3:] or list(arch)
for sec in only:
    a, n = arch.get(sec, set()), nix.get(sec, set())
    missing = sorted(a - n)
    print(f"\n### {sec}: Arch {len(a)}, NixOS {len(n)}, only on Arch: {len(missing)}")
    print("  " + "  ".join(missing) if missing else "  (none)")
