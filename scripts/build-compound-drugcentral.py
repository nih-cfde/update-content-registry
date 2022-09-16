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

    

    # load in alias file.
    alias_info = {}
    with open(args.alias_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        def isnull(value):
            if not value or value == ' ':
                return True
            return False

        for row in r:
        
            cv_id = row['pubchem_cid']
            
            drugcentral_id = row['drugcentral_id']
            #assert not isnull(drugcentral_id)
            
            drugcentral_url = row['drugcentral_url']
            #assert not isnull(drugcentral_url)
            
            #print(f"{drugcentral_id}") 
            
            alias_md = f"""More information is available on the **DrugCentral** page for  [{drugcentral_id}]({drugcentral_url}).\n![DrugCentral Image](https://drugcentral.org/drug/{drugcentral_id}/image).\n """
            
           
            
            alias_info[cv_id] = alias_md

    # validate ids
    validation_ids = cfde_common.get_validation_ids(term)

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

    id_list2 = set()
    skipped_list2 = set()
    template_name = 'alias_tables'
    for cv_id in sorted(id_list):
        resource_markdown = alias_info.get(cv_id)
        if resource_markdown:
            id_list2.add(cv_id)
            # write out JSON pieces for aggregation & upload
            cfde_common.write_output_pieces(output_dir, args.widget_name,
                                            cv_id, resource_markdown)
        else:
            skipped_list2.add(cv_id)
            
            f = open("logs/skipped.csv", "a")
            f.write(f"{args.widget_name},{term},{line},alias\n")
            f.close()
    
    print(f"Skipped {len(skipped_list2)} IDs not found in alias file.",
    file=sys.stderr)
    
    # summarize output 
    print(f"Wrote {len(id_list2)} .json files to {output_dir}.",
          file=sys.stderr)      

if __name__ == '__main__':
    sys.exit(main())
