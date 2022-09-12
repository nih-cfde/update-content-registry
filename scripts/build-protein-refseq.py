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

    ref_file = cfde_common.ID_FILES.get(term)
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
        
            cv_id = row['id']

        
            REFSEQ_ID = row['REFSEQ_ID']
            
            if ( REFSEQ_ID == 'NA' ):
            	REFSEQ_ID_str = f"**REFSEQ_ID**: No RefSeq ID available.\n"
            else:
            	REFSEQ_ID_str = f"**REFSEQ_ID**: [{REFSEQ_ID}](https://www.ncbi.nlm.nih.gov/protein/{REFSEQ_ID})\n"
            	
 
            	
            REFSEQ_NAME = row['REFSEQ_NAME']
            
            if ( REFSEQ_NAME == 'NA' ):
            	REFSEQ_NAME_str = f""
            else:
            	REFSEQ_NAME_str = f"**RefSeq Name**: {REFSEQ_NAME}\n"
            	
            	
            ENSEMBL_ID = row['ENSEMBL_ID']
            
            
            if ( ENSEMBL_ID == 'NA' ):
            	ENSEMBL_ID_str = f""
            else:
            	ENSEMBL_ID_str = f"**Ensembl Gene ID**: {ENSEMBL_ID}\n"                 
            
            GENE_NAME = row['GENE_NAME']	
            	
            if ( GENE_NAME == 'NA' ):
            	GENE_NAME_str = f""
            else:
            	GENE_NAME_str = f"**Gene Name**: _{GENE_NAME}_\n"     
            
            GLYCOSYLATION = row['GLYCOSYLATION']
            
            if ( GLYCOSYLATION == 'NA' ):
            	GLYCOSYLATION_str = f""
            else:
            	GLYCOSYLATION_str = f"**Glycosylation Summary:**: {GLYCOSYLATION}\n" 
            	
            	
            GENE_LOCATION = row['GENE_LOCATION']
            
            if ( GENE_LOCATION == 'NA' ):
            	GENE_LOCATION_str = f""
            else:
            	GENE_LOCATION_str = f"**Gene Location:**: {GENE_LOCATION}\n" 	    
   
   
            
            #print(f"{cv_id}") 
            
            alias_md = f"""**GlyGen Accession**: [{cv_id}](https://www.glygen.org/protein/{cv_id}))\n**UniProtKB Accession**: [{cv_id}](https://www.uniprot.org/uniprotkb/{cv_id}/entry)\n {REFSEQ_NAME_str}{ENSEMBL_ID_str}{GENE_NAME_str}{GLYCOSYLATION_str}{GENE_LOCATION_str}\n\nMore information for protein [{cv_id}](https://www.glygen.org/protein/{cv_id}) is available on GlyGen.\n"""

           
            alias_info[cv_id] = alias_md


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
                    f.write(f"{args.widget_name},{term},{line},ref\n")
                    f.close()

                id_list.add(line)

    print(f"Loaded {len(id_list)} IDs from {args.id_list}.\nSkipped {len(skipped_list)} IDs not found in {ref_file}.",
          file=sys.stderr)


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

    print(f"Skipped {len(skipped_list2)} IDs not found in {args.alias_file}.",
          file=sys.stderr)
          
          
if __name__ == '__main__':
    sys.exit(main())