"""
Utility code common to content registry foo.
"""
import os.path
import urllib.parse
import json


REF_FILES = {
    'anatomy': 'data/validate/anatomy.tsv',
    'compound': 'data/validate/compound.tsv',
    'disease': 'data/validate/disease.tsv',
    'gene': 'data/validate/ensembl_genes.tsv',
    'protein': 'data/validate/protein.tsv',
    }

ID_FILES = {
    'anatomy': 'data/validate/anatomy.csv',
    'compound': 'data/validate/compound.csv',
    'disease': 'data/validate/disease.csv',
    'gene': 'data/validate/gene.csv',
    'protein': 'data/validate/protein.csv',
    }    


def write_output_pieces(output_dir, widget_name, cv_id, md, *, verbose=False):
    output_filename = f"{widget_name}_{urllib.parse.quote(cv_id)}.json"
    output_filename = os.path.join(output_dir, output_filename)

    with open(output_filename, 'wt') as fp:
        d = dict(id=cv_id, resource_markdown=md)
        json.dump(d, fp)

    if verbose:
        print(f"Wrote JSON to {output_filename}")

    # write markdown - it's not used anywhere, but is available for inspection.
    output_filename = f"{widget_name}_{urllib.parse.quote(cv_id)}.md"
    output_filename = os.path.join(output_dir, output_filename)

    with open(output_filename, 'wt') as fp:
        fp.write(md)

    if verbose:
        print(f"Wrote markdown to {output_filename}")

def get_validation_ids(term):
    # get list of validation retrieved form portal pages
    validation_file = ID_FILES.get(term)
    if validation_file is None:
        print(f"ERROR: no validation file. Run `make retrieve`.", file=sys.stderr)
        sys.exit(-1)
        
    # load validation; ID is first column
    validation_ids = set()
    with open(validation_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter=',')
        for row in r:
            validation_id = row['id']
            validation_ids.add(validation_id)

    print(f"Loaded {len(validation_ids)} IDs from {validation_file}.",
          file=sys.stderr)
          
    return(validation_ids)      