#! /usr/bin/env python
import argparse
import sys
import csv
import json
import urllib.parse
import os.path
from collections import defaultdict

import cfde_common


def main():
    p = argparse.ArgumentParser()
    p.add_argument('term')
    p.add_argument('id_list')
    p.add_argument('alias_file')
    p.add_argument('gene_name_file')
    p.add_argument('--output-dir', '-o',
                   help="output directory, defaults to 'output_pieces_{termtype}")
    p.add_argument('--widget-name', default="widget",
                   help="widget name, used to set the output filename(s)")
    args = p.parse_args()

    # validate term
    term = args.term
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

    ref_file = cfde_common.ID_FILES.get(term)
    if ref_file is None:
        print(f"ERROR: no ref file for term. Dying terribly.", file=sys.stderr)
        sys.exit(-1)

    # print length of input list
    with open(args.id_list, 'r') as fp:
        x = len(fp.readlines())
    print(f"Loaded {x} IDs from {args.id_list}.", file=sys.stderr)


    # validate ids
    validation_ids = cfde_common.get_validation_ids(term)

          
          
          
    # load gene names.

    gene_name = {}

    with open(args.gene_name_file, 'r') as GENE_NAME_FILE:
        
        reader = csv.DictReader(GENE_NAME_FILE, delimiter='\t')

        for row in reader:
            
            current_id = row['ENSEMBL']
            current_name = row['SYMBOL']

            if ( current_id != '' and current_name != '' ):
                
                gene_name[current_id] = current_name


    # load in alias file.
    alias_info = {}
    with open(args.alias_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        def isnull(value):
            if not value or value == ' ':
                return True
            return False

        for row in r:
        
            cv_id = row['DO_ID']

                             	
            ENSEMBL_IDs = row['ENSEMBL_IDs']
            if not isnull(ENSEMBL_IDs):
                ENSEMBL_IDs = ENSEMBL_IDs.split('|')
            else:
                ENSEMBL_IDs = [] 
            
            ENSEMBL_IDs_string = ""
            if ENSEMBL_IDs:
                x = []
                for ENSEMBL_ID in ENSEMBL_IDs: 
                
                	if ( ENSEMBL_ID in gene_name ):
                	    x.append(f"[{gene_name[ENSEMBL_ID]} ({ENSEMBL_ID})](https://app.nih-cfde.org/chaise/record/#1/CFDE:gene/id={ENSEMBL_ID})")
                	else:     x.append(f"[{ENSEMBL_ID}](https://app.nih-cfde.org/chaise/record/#1/CFDE:gene/id={ENSEMBL_ID})")
                
                ENSEMBL_IDs_string = ", ".join(x)
        
                    
            alias_md = f"""**Associated Genes**: {ENSEMBL_IDs_string}\n"""
                       
            alias_info[cv_id] = alias_md

    # load in id list
    skipped_list = set()
    id_list = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line in validation_ids:
                    id_list.add(line)

                if line not in validation_ids:
                
                    skipped_list.add(line)
                    
                    f = open("logs/skipped.csv", "a")
                    f.write(f"{args.widget_name},{term},{line},ref\n")
                    f.close()

    print(f"Validated {len(id_list)} IDs from {args.id_list}.\nSkipped {len(skipped_list)} IDs not found in validation file.",
          file=sys.stderr)


    template_name = 'alias_tables'
    for cv_id in sorted(id_list):
        resource_markdown = alias_info.get(cv_id)
        if resource_markdown:
            # write out JSON pieces for aggregation & upload
            cfde_common.write_output_pieces(output_dir, args.widget_name,
                                            cv_id, resource_markdown)
       # else:
       #     print(f"WARNING: missing alias information for identifier {cv_id}")

    # summarize written files
    num_json_files =  len(id_list) 
    print(f"Wrote {num_json_files} .json files to {output_dir}.",
          file=sys.stderr)   
          
          
if __name__ == '__main__':
    sys.exit(main())