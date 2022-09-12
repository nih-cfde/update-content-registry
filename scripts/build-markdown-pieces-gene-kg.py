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

API_ENDPOINT = 'https://maayanlab.cloud/gene-kg'

TEMPLATES = set([('gene', 'kg_widget'),
                 ('anatomy', 'kg_widget'),
                 ('compound', 'kg_widget'),
                 ])

def kg_widget(cv_id, display, **kwargs):
    ''' The knowledge graph, kwargs are mapped to query params on the site.
    '''
    return f"""\nThe **CFDE Gene Centric Knowledge Graph** for [{display}]({API_ENDPOINT}?{urllib.parse.urlencode(kwargs)}) provides an interface for exploring cross-dcc knowledge about genes and their associations.
\n
"""

INPUT_GENE_ID_LIST = os.path.join('data', 'inputs', 'gene_IDs_for_gene_kg.txt')
INPUT_ANATOMY_ID_LIST = os.path.join('data', 'inputs', 'anatomy_IDs_for_gene_kg.txt')
INPUT_COMPOUND_ID_LIST = os.path.join('data', 'inputs', 'compound_IDs_for_gene_kg.txt')

def build_id_lists():
    ''' Usage:
    cd scripts && python -c 'import importlib; importlib.import_module("build-markdown-pieces-gene-kg").build_id_lists()'
    '''
    import os
    import urllib.request
    os.chdir(__root__)

    # GENE
    # get reverse name => gencode gene mappings
    ref_file = cfde_common.REF_FILES.get('gene')
    ref_name_to_id = {}
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_name_to_id[row['name']] = row['id']

    # get supported genes from API
    with urllib.request.urlopen(f"{API_ENDPOINT}/api/knowledge_graph/Gene") as fr:
        genes = json.load(fr)

    # construct input id list
    with open(INPUT_GENE_ID_LIST, 'w') as fw:
        for gene in genes.keys():
            cv_id = ref_name_to_id.get(gene)
            if cv_id:
                fw.write(cv_id + '\n')

    # ANATOMY
    ref_file = cfde_common.REF_FILES.get('anatomy')
    ref_ids = set()
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_ids.add(row['id'])

    # get supported anatomy from API
    with urllib.request.urlopen(f"{API_ENDPOINT}/api/knowledge_graph/{urllib.parse.quote('`Cell or Tissue (HuBMAP)`')}") as fr:
        anatomies = json.load(fr)

    # construct input id list
    with open(INPUT_ANATOMY_ID_LIST, 'w') as fw:
        for anatomy in anatomies.values():
            if anatomy['id'].startswith('UBERON_'):
                _, _, uberon_id = anatomy['id'].partition('_') # our anatomies are UBERON_123 but CFDE's are UBERON:123
                cv_id = f"UBERON:{uberon_id}"
                if cv_id in ref_ids:
                    fw.write(cv_id + '\n')

    # COMPOUND
    # get cfde supported compound ids
    ref_file = cfde_common.REF_FILES.get('compound')
    ref_ids = set()
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            ref_ids.add(row['id'])

    # get supported drugs from API
    with urllib.request.urlopen(f"{API_ENDPOINT}/api/knowledge_graph/Drug") as fr:
        compounds = json.load(fr)

    # construct input id list
    with open(INPUT_COMPOUND_ID_LIST, 'w') as fw:
        for compound in compounds.values():
            _, _, cv_id = compound['id'].partition(':') # our compounds are CID:123 but CFDE's are just 123
            if cv_id in ref_ids:
                fw.write(cv_id + '\n')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('term')
    p.add_argument('id_list')
    p.add_argument('--widget-name', default="widget",
                   help="widget name, used to set the output filename(s)")
    p.add_argument('--output-dir', '-o')
    args = p.parse_args()

    # validate term
    term = args.term
    if term not in cfde_common.REF_FILES:
        print(f"ERROR: unknown term type '{term}'", file=sys.stderr)
        sys.exit(-1)

    # validate template_name
    tup = (term, args.widget_name)
    if tup not in TEMPLATES:
        print(f"ERROR: unknown term/template pair {tup}", file=sys.stderr)
        sys.exit(-1)
    template_name = args.widget_name

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


    ref_file = cfde_common.REF_FILES.get(term)
    if ref_file is None:
        print(f"ERROR: no ref file for term. Dying terribly.", file=sys.stderr)
        sys.exit(-1)
     
           
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


    # load in ref file; ID is first column
    ref_id_list = set()
    skipped_list = set()
    ref_id_to_name = {}
    with open(ref_file, 'r', newline='') as fp:
        r = csv.DictReader(fp, delimiter='\t')
        for row in r:
            cv_id = row['id']
            if cv_id in id_list:
                ref_id = row['id']
                ref_id_to_name[ref_id] = row['name']
                ref_id_list.add(ref_id)
            if cv_id not in id_list:
                skipped_list.add(cv_id)
                f = open("logs/skipped.csv", "a")
                f.write(f"{args.widget_name},{term},{cv_id}\n")
                f.close()


    for cv_id in sorted(ref_id_list):
        resource_markdown = None
        if term =='gene':
            if template_name == 'kg_widget':
                resource_markdown = kg_widget(
                    cv_id, f"{ref_id_to_name[cv_id]} ({cv_id})",
                    start='Gene',
                    start_field='label',
                    start_term=ref_id_to_name[cv_id], # gencode => gene sym
                )
            else:
                assert 0
        elif term =='anatomy':
            if template_name == 'kg_widget':
                resource_markdown = kg_widget(
                    cv_id, f"{ref_id_to_name[cv_id]} ({cv_id})",
                    start='Cell or Tissue (HuBMAP)',
                    start_field='id',
                    start_term=cv_id.replace(':', '_'), # UBERON:123 => UBERON_123
                )
            else:
                assert 0
        elif term == 'compound':
            if template_name == 'kg_widget':
                resource_markdown = kg_widget(
                    cv_id, f"{ref_id_to_name[cv_id]} (CID:{cv_id})",
                    start='Drug',
                    start_field='id',
                    start_term=f"CID:{cv_id}", # 123 => CID:123
                )
            else:
                assert 0
        elif term == 'disease':
            assert 0

        assert resource_markdown is not None

        # write out JSON pieces for aggregation & upload
        cfde_common.write_output_pieces(output_dir, args.widget_name,
                                        cv_id, resource_markdown)

    # summarize output
    num_json_files =   len(id_list)   
    print(f"Wrote {num_json_files} .json files to {output_dir}.",
          file=sys.stderr)    

if __name__ == '__main__':
    sys.exit(main())
