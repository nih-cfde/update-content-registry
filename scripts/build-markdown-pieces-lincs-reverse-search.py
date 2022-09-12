#! /usr/bin/env python
import argparse
import sys
import csv
import json
import os.path

import cfde_common

__directory__, __base__ = os.path.split(__file__)
__root__, _ = os.path.split(__directory__)

API_ENDPOINT = 'https://lincs-reverse-search-dashboard.dev.maayanlab.cloud'
TEMPLATES = set([('gene', 'reverse_search_widget'),
                 ])
INPUT_ID_LIST = os.path.join('data', 'inputs', 'gene_IDs_for_lincs_reverse_search.txt')

def build_id_list():
    ''' Usage:
    cd scripts && python -c 'import importlib; importlib.import_module("build-markdown-pieces-lincs-reverse-search").build_id_list()'
    '''
    import os
    import urllib.request
    os.chdir(__root__)

    # get reverse name => gencode gene mappings
    ref_file = cfde_common.REF_FILES.get('gene')
    ref_name_to_id = {}
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_name_to_id[row['name']] = row['id']

    # get supported genes from API
    with urllib.request.urlopen(f"{API_ENDPOINT}/api/info/") as fr:
        info = json.load(fr)

    # construct input id list
    with open(INPUT_ID_LIST, 'w') as fw:
        for gene in info.keys():
            cv_id = ref_name_to_id.get(gene)
            if cv_id:
                fw.write(cv_id + '\n')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('term')
    p.add_argument('id_list')
    p.add_argument('--widget-name', default="widget",
                   help="widget name, used to set the output filename(s)")
    p.add_argument('--output-dir', '-o')
    args = p.parse_args()

    # validate term
    term = args.term
    if term not in cfde_common.REF_FILES:
        print(f"ERROR: unknown term type '{term}'", file=sys.stderr)
        sys.exit(-1)

    # validate template_name
    tup = (term, args.widget_name)
    if tup not in TEMPLATES:
        print(f"ERROR: unknown term/template pair {tup}", file=sys.stderr)
        sys.exit(-1)
    template_name = args.widget_name

    print(f"Running with term: {term}", file=sys.stderr)

    # output dir default
    output_dir = args.output_dir
    if output_dir is None:
        output_dir = f"output_pieces_{term}"
    print(f"Using output dir {output_dir} for pieces.")

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

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

    # load in id list
    skipped_list = set()
    id_list = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line not in ref_id_list:
                
                    skipped_list.add(line)
                    
                    f = open("logs/skipped.csv", "a")
                    f.write(f"{args.widget_name},{term},{line},alias\n")
                    f.close()

                id_list.add(line)

    print(f"Loaded {len(id_list)} IDs from {args.id_list}.\nSkipped {len(skipped_list)} IDs not found in {ref_file}.",
          file=sys.stderr)
          
          
          
    # validate that ID list is contained within actual IDs in portal
    ref_file2 = cfde_common.ID_FILES.get(term)
    if ref_file2 is None:
        print(f"ERROR: no ref file for term. Dying terribly.", file=sys.stderr)
        sys.exit(-1)

    # load in ref file; ID is first column
    ref_id_list2 = set()
    with open(ref_file2, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter=',')
        for row in r:
            ref_id = row['id']
            ref_id_list2.add(ref_id)


    # load in id list
    skipped_list2 = set()
    id_list2 = set()
    with open(ref_file2, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line not in ref_id_list2:
                
                    skipped_list2.add(line)
                    
                    f = open("logs/skipped.csv", "a")
                    f.write(f"{args.widget_name},{term},{line},ref\n")
                    f.close()

                id_list.add(line)

    print(f"Loaded {len(ref_id_list2)} IDs from {ref_file2}.\nSkipped {len(skipped_list2)} IDs not found in {ref_file2}.",
          file=sys.stderr)
      


    for cv_id in sorted(id_list2):
        resource_markdown = None
        if term =='gene':
            if template_name == 'reverse_search_widget':
                resource_markdown = f"::: iframe [**LINCS Chemical Perturbations (via LINCS API):**]({API_ENDPOINT}/#{ref_id_to_name[cv_id]}){{width=\"1200\" height=\"450\" style=\"border: 1px solid black;\" caption-style=\"font-size: 24px;\" caption-link=\"{API_ENDPOINT}/#{ref_id_to_name[cv_id]}\" caption-target=\"_blank\"}} \n:::\n"
            else:
                assert 0
        elif term =='anatomy':
            assert 0
        elif term == 'compound':
            assert 0
        elif term == 'disease':
            assert 0

        assert resource_markdown is not None

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, resource_markdown)


if __name__ == '__main__':
    sys.exit(main())
