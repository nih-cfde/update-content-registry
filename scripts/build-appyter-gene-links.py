#! /usr/bin/env python
import argparse
import sys
import csv
import json
import urllib.parse
import os.path

import cfde_common


def make_markdown(cv_id):
    return f"""The **CFDE Gene Partnership Appyter** for  [{cv_id}](https://appyters.maayanlab.cloud/CFDE-Gene-Partnership/#?args.gene={cv_id}&submit) provides up-to-date information from across the Common Fund Data Ecosystem. The Appyter collects gene-centric data from Common Fund supported programs via their API. The source code within the Appyter demonstrates how you can programmatically access CFDE data sources for integrative analyses.\n"""


def main():
    p = argparse.ArgumentParser()
    p.add_argument('termtype', help="controlled vocabulary term type - gene, disease, compound, or anatomy")
    p.add_argument('id_list', help="file containing list of IDs to build markdown for")
    p.add_argument('--widget-name', default="widget",
                   help="widget name, used to set the output filename(s)")
    p.add_argument('--output-dir', '-o',
                   help="output directory, defaults to 'output_pieces_{termtype}")
    args = p.parse_args()

    # validate term
    term = args.termtype
    if term not in cfde_common.ID_FILES:
        print(f"WARNING: unknown term type '{term}'", file=sys.stderr)

    print(f"Running with term: {term}", file=sys.stderr)

    # output dir default
    output_dir = args.output_dir
    if output_dir is None:
        output_dir = f"output_pieces_{term}"
    print(f"Using output dir {output_dir} for pieces.")

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    # validate that ID list is contained within actual IDs in database
    ref_file = cfde_common.ID_FILES.get(term)
    if ref_file is None:
        print(f"WARNING: no ref file for term.", file=sys.stderr)

    # load in ref file; ID is first column
    ref_id_list = set()
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_id = row['id']
            ref_id_list.add(ref_id)

    print(f"Loaded {len(ref_id_list)} reference IDs from {ref_file}",
          file=sys.stderr)

    # load up each ID in id_list file - is it in the ref_id_list?
    # if not, complain.
    # we could also remove them here. we don't want to output markdown
    # for them!
    id_list = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line  in ref_id_list:
                    id_list.add(line)
                if line not in ref_id_list:
                    print(f"WARNING: requested input id {line} not found in ref_id_list", file=sys.stderr)
    print(f"Loaded {len(id_list)} IDs from {args.id_list}",
          file=sys.stderr)

    # now iterate over and make markdown, then save JSON + md.
    for cv_id in id_list:
        md = make_markdown(cv_id)

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, md)


if __name__ == '__main__':
    sys.exit(main())
