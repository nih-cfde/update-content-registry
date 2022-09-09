"""
Utility code common to content registry foo.
"""

import os.path
import urllib.parse
import json
from urllib.request import urlopen
import pandas as pd


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


def get_portal_page_ids(term):
    # get list of ids with portal pages from json
    url = f'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:{term}/id@sort(id)' 
    response = urlopen(url)
    data_json = json.loads(response.read())
    df = pd.json_normalize(data_json)    
    ids = df["id"].to_numpy()
    
    print(f"Loaded {len(ids)} {term} IDs in the CFDE Portal from {url}")
    
    return(ids)
    
