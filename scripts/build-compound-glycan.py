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

    # load in alias file.
    alias_info = {}
    with open(args.alias_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        def isnull(value):
            if not value or value == ' ':
                return True
            return False

        for row in r:
        
            cv_id = row['CV_ID']
            GLYTOUCAN_ID = row['GLYTOUCAN_ID']
            PUBCHEM_CID = row['PUBCHEM_CID']
            
            MASS = row['MASS']
            
            if ( MASS == 'NA' ):
            	MASS_str = f""
            else:
            	MASS_str = f"**Monoisotopic Mass**: {MASS}\n"
            
            
            COMPOSITION = row['COMPOSITION']
            
            if ( COMPOSITION == 'NA' ):
            	COMPOSITION_str = f""
            else:
            	COMPOSITION_str = f"**Composition**: {COMPOSITION}\n"
            
            PUBCHEM_CID = row['PUBCHEM_CID']
            IMAGE_URL = row['IMAGE_URL']
            LINK_OUT_URL = row['LINK_OUT_URL']
            
            #print(f"{glytoucan_ac}") 
            
            alias_md = f"""## Glycan Details\n![Image]({IMAGE_URL})\n**GlyTouCan Accession**: [{GLYTOUCAN_ID}]({LINK_OUT_URL})\n**PubChem CID**: {PUBCHEM_CID}\n{MASS_str}{COMPOSITION_str}\nMore information for glycan [{GLYTOUCAN_ID}]({LINK_OUT_URL}) is available on GlyGen.\n"""

           
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

    template_name = 'alias_tables'
    for cv_id in sorted(id_list):
        resource_markdown = alias_info.get(cv_id)
        if resource_markdown:
            # write out JSON pieces for aggregation & upload
            cfde_common.write_output_pieces(output_dir, args.widget_name,
                                            cv_id, resource_markdown)
        else:
            print(f"WARNING: missing markdown for identifier {cv_id}")


if __name__ == '__main__':
    sys.exit(main())
