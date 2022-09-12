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
    p.add_argument('protein_name_file')
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

    # print length of input list
    with open(args.id_list, 'r') as fp:
        x = len(fp.readlines())
    print(f"Loaded {x} IDs from {args.id_list}.", file=sys.stderr)


    # validate ids
    validation_ids = cfde_common.get_validation_ids(term)

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

    # load protein names.

    protein_name = {}

    with open(args.protein_name_file, 'r') as PROTEIN_FILE:
        
        reader = csv.DictReader(PROTEIN_FILE, delimiter='\t')

        for row in reader:
            
            cv_id = row['id']
            name = row['name']
            
            if ( cv_id != '' and name != '' ):
                
                protein_name[cv_id] = name            


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
            UNIPROT_ACs = row['UNIPROT_ACs']
            
            if not isnull(UNIPROT_ACs):
                UNIPROT_ACs = UNIPROT_ACs.split('|')
            else:
                UNIPROT_ACs = [] 
            
            UNIPROT_ACs_string = ""
            if UNIPROT_ACs:
                x = []
                for UNIPROT_AC in UNIPROT_ACs: 
                    x.append(f"[{protein_name[UNIPROT_AC]} ({UNIPROT_AC})](https://app.nih-cfde.org/chaise/record/#1/CFDE:protein/id={UNIPROT_AC})")

                
                UNIPROT_ACs_string = ", ".join(x)
        
                    
            alias_md = f"""**Associated Proteins**: {UNIPROT_ACs_string}\n"""
                       
            alias_info[cv_id] = alias_md


          

    template_name = 'alias_tables'
    skipped_list2 = set()
    for cv_id in sorted(id_list):
        resource_markdown = alias_info.get(cv_id)
        if resource_markdown:
            # write out JSON pieces for aggregation & upload
            cfde_common.write_output_pieces(output_dir, args.widget_name,
                                            cv_id, resource_markdown)
        else:
            skipped_list2.add(cv_id)
            
            f = open("logs/skipped.csv", "a")
            f.write(f"{args.widget_name},{term},{cv_id},alias\n")
            f.close()

    # summarize written files
    num_json_files =  len(id_list) 
    print(f"Wrote {num_json_files} .json files to {output_dir}.",
          file=sys.stderr) 

if __name__ == '__main__':
    sys.exit(main())