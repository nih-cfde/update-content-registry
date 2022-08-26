#! /usr/bin/env python
import argparse
import sys
import csv
import json
import urllib.parse
import os.path

import cfde_common

__directory__, __base__ = os.path.split(__file__)
__root__, _ = os.path.split(__directory__)

INPUT_GENE_ID_LIST = os.path.join('data', 'inputs', 'gene_IDs_for_lincs_geo_reverse_appyter.txt')

def make_markdown(cv_id, genesym):
    return f"""The **LINCS Gene Centric GEO Reverse Search Appyter** for [{genesym} ({cv_id})](https://appyters.maayanlab.cloud/Gene_Centric_GEO_Reverse_Search/#?args.species_input=Human&args.human_gene={genesym}&submit) allows users to query for a gene in a species of interest and returns an interactive volcano plot visualization of LINCS L1000 signatures in which the given gene is up- or down-regulated.\n"""

def build_id_list():
    ''' Usage:
    cd scripts && python -c 'import importlib; importlib.import_module("build-appyter-gene-links-lincs-geo-reverse").build_id_list()'
    '''
    import os
    import pandas as pd
    os.chdir(__root__)

    # get reverse name => gencode gene mappings
    ref_file = cfde_common.REF_FILES.get('gene')
    ref_name_to_id = {}
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_name_to_id[row['name']] = row['id']

    # get genes from appyter
    endpoint = 'https://appyters.maayanlab.cloud/storage/Gene_Centric_GEO_Reverse_Search'
    species = 'human'
    pval_df_input = pd.read_feather(f"{endpoint}/{species}_pval.f").set_index('index')
    genes = pval_df_input.columns.tolist()
    del pval_df_input

    # construct input id list
    with open(INPUT_GENE_ID_LIST, 'w') as fw:
        for gene in genes:
            cv_id = ref_name_to_id.get(gene)
            if cv_id:
                fw.write(cv_id + '\n')

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
    if term not in cfde_common.REF_FILES:
        print(f"ERROR: unknown term type '{term}'", file=sys.stderr)
        sys.exit(-1)

    print(f"Running with term: {term}", file=sys.stderr)

    # output dir default
    output_dir = args.output_dir
    if output_dir is None:
        output_dir = f"output_pieces_{term}"
    print(f"Using output dir {output_dir} for pieces.")

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    # validate that ID list is contained within actual IDs in database
    ref_file = cfde_common.REF_FILES.get(term)
    if ref_file is None:
        print(f"ERROR: no ref file for term. Dying terribly.", file=sys.stderr)
        sys.exit(-1)

    # load in ref file; ID is first column
    ref_id_list = set()
    ref_id_to_name = {}
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_id = row['id']
            ref_id_to_name[ref_id] = row['name']
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
                if line not in ref_id_list:
                    print(f"ERROR: requested input id {line} not found in ref_id_list", file=sys.stderr)
                    print(f"skipping!", file=sys.stderr)
                    continue
                    #sys.exit(-1)

                id_list.add(line)

    print(f"Loaded {len(id_list)} IDs from {args.id_list}",
          file=sys.stderr)

    # now iterate over and make markdown, then save JSON + md.
    for cv_id in id_list:
        md = make_markdown(cv_id, ref_id_to_name[cv_id])

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, md)


if __name__ == '__main__':
    sys.exit(main())
