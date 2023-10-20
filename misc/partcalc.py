#!/usr/bin/env python3

import sys
import os
from dataclasses import dataclass


@dataclass
class Part:
    name: str
    size: float


def partcalc(space, parts):
    if not parts:
        return
    
    last = parts.pop()
    if last.size >= 1:
        return partcalc(space - last.size, parts)

    for p in parts:
        p.size = round(space * p.size) if p.size < 1 else p.size
        space -= p.size
    
    last.size = space


def usage():
    prog = os.path.basename(sys.argv[0])
    print(f"""\
Usage: {prog} [-B] <TOTALSIZE> ...[<NAME> <SIZE>] <NAME> <SIZE>

Size calculator for partition schemes with recursive factors and fixed amounts.

SIZE can be a multiplier (if lesser than 1) or a fixed amount otherwise (GiB).
The last partition having a multiplier SIZE will get the remaining amount,
ignoring the one specified.

Options:
    -B         Do not convert TOTALSIZE from GB (common storage measure) to GiB

Examples:
> 1024  files .5
    • files        1024 GB 1048576 MB
    
> 1024  files .5  other 9
    • files        1015 GB 1039360 MB
    • other           9 GB    9216 MB
    
> 1024  files .5  system .5  other 8
    • files         508 GB  520192 MB
    • system        508 GB  520192 MB
    • other           8 GB    8192 MB

> 1000  files 500  linux .6  windows 0  rescue 8  sandbox 8  swap 8  boot 1
    • files         500 GB  512000 MB
    • linux         244 GB  249856 MB
    • windows       162 GB  166218 MB
    • rescue          8 GB    8192 MB
    • sandbox         8 GB    8192 MB
    • swap            8 GB    8192 MB
    • boot            1 GB    1024 MB

Protip — Always sort the partitions in order from largest to smallest. This is
because it can be extremely tedious to extend a partition to the left, as it
requires copying ALL data and then extend to the right.
"""[:-1])


def main(arg0, *args):
    if not args:
        usage()
        return 1
    
    if '--help' in args:
        usage()
        return 0
    
    to_gib = 1000**3 / 1024**3
    
    args = list(args)
    while args[0][0] == '-':
        opt = args.pop(0)
        if opt == '--':
            break
        if opt == '-B':
            to_gib = 1
        else:
            print("Unknown option:", opt)
    
    target_total = float(args.pop(0)) * to_gib
    parts = []
    while args:
        parts.append(Part(
            name=args.pop(0),
            size=float(args.pop(0))
        ))
    
    partcalc(target_total, list(parts))
    
    calc_total = 0
    print()
    for p in parts:
        print(f"• {p.name:<12s} {p.size:>4.0f} GB {p.size*1024:>7.0f} MB")
        calc_total += p.size
    print()
    print("total:", round(calc_total, 2))
    print()


if __name__ == '__main__':
    sys.exit(main(*sys.argv) or 0)
