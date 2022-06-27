#! /usr/bin/env python
import argparse
import sys
import os
import json
from collections import defaultdict


def main():
    p = argparse.ArgumentParser()
    p.add_argument('pieces_dirs', nargs="+")
    p.add_argument('--output-json', '-o', required=True)
    args = p.parse_args()

    for pieces_dir in args.pieces_dirs:
        if not os.path.isdir(pieces_dir):
            print(f"ERROR: '{pieces_dir}' is not a directory.", file=sys.stderr)
            sys.exit(-1)

    def walk_em_all(dirlist):
        for dirname in dirlist:
            for x in os.walk(dirname):
                yield x

    chunks_by_cv_id = defaultdict(list)
    for (dirpath, dirnames, filenames) in walk_em_all(args.pieces_dirs):
        for filename in filenames:
            if not filename.endswith('.json'):
                print(f"skipping {filename} - does not end with .json")
                continue

            filename = os.path.join(dirpath, filename)
            print(f"Loading from {filename}", file=sys.stderr)

            with open(filename, 'rt') as fp:
                d = json.load(fp)
                assert 'id' in d.keys()
                assert 'resource_markdown' in d.keys()

                cv_id = d['id']
                chunks_by_cv_id[cv_id].append((filename, d))

    chunks = []
    cv_id_list = sorted(chunks_by_cv_id.keys())
    for cv_id in cv_id_list:
        vv = sorted(chunks_by_cv_id[cv_id]) #  sort by filename
        combined_md = []
        for _, d in vv:
            assert d['id'] == cv_id
            combined_md.append(d['resource_markdown'])

        combined_md = "\n".join(combined_md) + "\n"

        chunks.append(dict(id=cv_id, resource_markdown=combined_md))

    with open(args.output_json, 'wt') as fp:
        json.dump(chunks, fp)

    print(f"Wrote {len(chunks)} chunks to {args.output_json}", file=sys.stderr)


if __name__ == '__main__':
    sys.exit(main())
