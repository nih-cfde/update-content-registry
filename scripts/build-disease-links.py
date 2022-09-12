#! /usr/bin/env python
import argparse
import sys
import csv
import json
import urllib.parse
import os.path

import cfde_common

##
## this is the function to change to generate different markdown entries.
## it should return a markdown string.
## you can change it to take more arguments, use a database, whatever - but
## please don't change the output filenames or formats :).
##

def make_markdown(cv_id):
    return  f"""**Disease Ontology:** [{cv_id}](https://disease-ontology.org/?id={cv_id})\n**Human Disease:** [{cv_id}](https://bioportal.bioontology.org/ontologies/DOID?p=classes&conceptid={cv_id})\n**Rat Genome Database:** [{cv_id}](https://rgd.mcw.edu/rgdweb/ontology/view.html?acc_id={cv_id})\n**Yeast Genome Database:** [{cv_id}](https://www.yeastgenome.org/disease/{cv_id})\n"""



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

    # now iterate over and make markdown, then save JSON + md.
    for cv_id in id_list:
    
        #print(f"Disease {cv_id}")
    
        md = make_markdown(cv_id)

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, md)

    # summarize written files
    num_json_files =  len(id_list) 
    print(f"Wrote {num_json_files} .json files to {output_dir}.",
          file=sys.stderr)    


if __name__ == '__main__':
    sys.exit(main())
