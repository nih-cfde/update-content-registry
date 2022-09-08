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
    p.add_argument('disease_name_file')
    p.add_argument('alias_file')
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

    ref_file = cfde_common.REF_FILES.get(term)
    if ref_file is None:
        print(f"ERROR: no ref file for term. Dying terribly.", file=sys.stderr)
        sys.exit(-1)

    # load in ref file; ID is first column
    ref_id_list = set()
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_id = row['id']
            ref_id_list.add(ref_id)

    print(f"Loaded {len(ref_id_list)} reference IDs from {ref_file}",
          file=sys.stderr)
          
    # load disease names.

    disease_name = {}

    with open(args.disease_name_file, 'r') as DISEASE_NAME_FILE:
        
        reader = csv.DictReader(DISEASE_NAME_FILE, delimiter='\t')

        for row in reader:
            
            current_id = row['DO_ID']
            current_name = row['NAME']

            if ( current_id != '' and current_name != '' ):
                
                disease_name[current_id] = current_name
                
                
    # load in alias file.
    alias_info = {}
    with open(args.alias_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        def isnull(value):
            if not value or value == ' ':
                return True
            return False

        for row in r:
        
            cv_id = row['UNIPROT_AC']
                                 
            DO_IDs = row['DO_ID']
            if not isnull(DO_IDs):
                DO_IDs = DO_IDs.split('|')
            else:
                DO_IDs = [] 
            
            DO_IDs_string = ""
            if DO_IDs:
                x = []
                for DO_ID in DO_IDs: 
                
                    DO_ID_URL = DO_ID.replace(':', '%3A')
                    
                    if ( DO_ID in disease_name ):
                    
                        x.append(f"[{disease_name[DO_ID]} ({DO_ID})](https://app.nih-cfde.org/chaise/record/#1/CFDE:disease/id={DO_ID_URL})")
                    else:
                                            x.append(f"[{DO_ID}](https://app.nih-cfde.org/chaise/record/#1/CFDE:disease/id={DO_ID_URL})")

                    DO_IDs_string = ", ".join(x)
                    alias_md = f"""**Associated Diseases**: {DO_IDs_string} \n"""
                    
            alias_info[cv_id] = alias_md


    # load in id list
    id_list = set()
    with open(args.id_list, 'rt') as fp:
        for line in fp:
            line = line.strip()
            if line:
                if line not in ref_id_list:
                    print(f"ERROR: requested input id {line} not found in ref_id_list", file=sys.stderr)
                    sys.exit(-1)

                id_list.add(line)

    print(f"Loaded {len(id_list)} IDs from {args.id_list}",
          file=sys.stderr)

    # filter by ids with a page in the portal
    id_pages = cfde_common.get_portal_page_ids(term)
    id_list_filtered = [value for value in id_list if value in id_pages]        
    print(f"Using  {len(id_list_filtered)} {term} IDs.")


    template_name = 'alias_tables'
    for cv_id in sorted(id_list_filtered):
        resource_markdown = alias_info.get(cv_id)
        if resource_markdown:
            # write out JSON pieces for aggregation & upload
            cfde_common.write_output_pieces(output_dir, args.widget_name,
                                            cv_id, resource_markdown)
        else:
            print(f"WARNING: missing markdown for identifier {cv_id}")

if __name__ == '__main__':
    sys.exit(main())