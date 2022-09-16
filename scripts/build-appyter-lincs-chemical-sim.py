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

INPUT_COMPOUND_ID_LIST = os.path.join('data', 'inputs', 'compound_IDs_for_lincs_chemical_sim_appyter.txt')

def make_markdown(cv_id, drugname):
    return f"""The **LINCS Chemical Similarity Appyter** for [{drugname} (CID:{cv_id})](https://appyters.maayanlab.cloud/LINCS_Chemical_Similarity_Appyter/#?args.drug={drugname}&submit) provides information about small molecules profiled by the LINCS program. Specifically, users can retrieve similar small molecules based on Tanimoto structural similarity and similarity based on L1000 gene expression.\n"""

def build_id_list():
    ''' Usage:
    cd scripts && python -c 'import importlib; importlib.import_module("build-appyter-lincs-chemical-sim").build_id_list()'
    '''
    import os
    import urllib.request
    os.chdir(__root__)

    # get available cids
    ref_file = cfde_common.REF_FILES.get('compound')
    ref_ids = set()
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_ids.add(row['id'])

    # get compounds from appyter
    with urllib.request.urlopen('https://appyters.maayanlab.cloud/storage/DODGE-Chemical-Similarity/L1000_signature_similarity_scores.json') as fr:
        L1000_signature_similarity_scores = json.load(fr)
    compounds = set(L1000_signature_similarity_scores.keys())
    del L1000_signature_similarity_scores

    # get compound -> cid mappings
    compound_cids = set()
    with urllib.request.urlopen('https://maayanlab.cloud/L1000FWD/download/Drugs_metadata.csv') as fp:
        r = csv.DictReader(map(bytes.decode, fp))
        for row in r:
            if row['pert_id'] in compounds:
                compound_cids.add(row['pubchem_cid'])

    intersecting_cids = compound_cids & ref_ids
    # construct input id list
    with open(INPUT_COMPOUND_ID_LIST, 'w') as fw:
        for cv_id in intersecting_cids:
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
        
    # print length of input list
    with open(args.id_list, 'r') as fp:
        x = len(fp.readlines())
    print(f"Loaded {x} IDs from {args.id_list}.", file=sys.stderr)

        
    
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

    # load in id list
    id_list = set()
    skipped_list = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line in ref_id_list:
                    id_list.add(line)
                if line not in ref_id_list:
                    skipped_list.add(line)
                    
                    f = open("logs/skipped.csv", "a")
                    f.write(f"{args.widget_name},{term},{line},alias\n")
                    f.close()

        
    print(f"Skipped {len(skipped_list)} IDs not found in {ref_file}.",  file=sys.stderr)
          

    # validate ids
    validation_ids = cfde_common.get_validation_ids(term)

    skipped_list2 = set()
    id_list2 = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line in validation_ids:
                    id_list2.add(line)

                if line not in validation_ids:
                
                    skipped_list.add(line)
                    
                    f = open("logs/skipped.csv", "a")
                    f.write(f"{args.widget_name},{term},{line},ref\n")
                    f.close()

    print(f"Validated {len(id_list)} IDs from {args.id_list}.\nSkipped {len(skipped_list)} IDs not found in validation file.",
          file=sys.stderr)



    # now iterate over and make markdown, then save JSON + md.
    for cv_id in id_list:
        md = make_markdown(cv_id, ref_id_to_name[cv_id])

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, md)

    # summarize output 
    print(f"Wrote {len(id_list2)} .json files to {output_dir}.",
          file=sys.stderr)  
          
if __name__ == '__main__':
    sys.exit(main())
