#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

import sys
import json
import hashlib
import argparse
from os import urandom
from zipfile import ZipInfo, ZipFile, ZIP_DEFLATED

def parse_version(version_str):
    parts = [int(x) for x in version_str.split('.')]
    result = {}
    if parts[0]: result['major'] = parts[0]
    if parts[1]: result['minor'] = parts[1]
    if parts[2]: result['patch'] = parts[2]
    return result

def parse_args():
    parser = argparse.ArgumentParser(description='Build Oasis .orc file')

    # Required arguments
    parser.add_argument('--out', required=True, metavar="filename.orc", help='Output .orc file path')
    parser.add_argument('--version', required=True, metavar="x.x.x", help='Version number in x.x.x format')
    parser.add_argument('--name', required=True, help='Name of ROFL package')
    parser.add_argument('--runtime', help="Runtime ID", choices=['sapphire-localnet','sapphire-testnet','sapphire-mainnet'])

    # Optional arguments
    parser.add_argument('--elf', required=False, help='Path to ELF file')
    parser.add_argument('--sgxs', required=False, metavar="filename.sgxs", help='Path to SGXS file')
    parser.add_argument('--sig', required=False, metavar="filename.sig", help='Path to signature file')

    return parser.parse_args()

def main():
    args = parse_args()
    version = parse_version(args.version)

    infiles = {}
    if args.elf:
        infiles['app.elf'] = args.elf
    if args.sgxs:
        infiles['app.sgxs'] = args.sgxs
        if not args.sig:
            infiles['app.sig'] = args.sgxs + '.sig'
    if args.sgxs:
        infiles['app.sig'] = args.sig

    digests = {}
    for k, v in infiles.items():
        h = hashlib.new('sha512_256')
        with open(v, 'rb') as f:
            h.update(f.read())
        digests[k] = h.hexdigest()

    if args.runtime == 'sapphire-testnet':
        runtime_id = '000000000000000000000000000000000000000000000000a6d1e3ebf60dff6c'
    elif args.runtime == 'sapphire-mainnet':
        runtime_id = '000000000000000000000000000000000000000000000000f80306c9858e7279'
    elif args.runtime == 'sapphire-localnet':
        runtime_id = '8000000000000000000000000000000000000000000000000000000000000000'
    else:
        raise RuntimeError("Unknown runtime ID!")

    #runtime_id = runtime_id[:-10] + urandom(5).hex()

    component = {
        'kind': 'rofl',
        'name': args.name
    }

    if 'app.elf' in infiles:
        component['executable'] = 'app.elf'

    if 'app.sgxs' in infiles:
        component['sgx'] = {
            'executable': 'app.sgxs',
            'signature': 'app.sig'
        }

    manifest = {
        'name': args.name,
        'id': runtime_id,
        'version': version,
        'components': [component],
        'digests': digests
    }

    print(json.dumps(manifest,indent=4))

    with ZipFile(args.out, 'w', ZIP_DEFLATED) as zf:
        zinfo = ZipInfo("META-INF/MANIFEST.MF")
        zf.writestr(zinfo, json.dumps(manifest))
        for k,v in infiles.items():
            zinfo = ZipInfo(k)
            with open(v, "rb") as f:
                zf.writestr(zinfo, f.read())

    return 0

if __name__ == "__main__":
    sys.exit(main())
