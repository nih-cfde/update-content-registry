##
## Workflow logic to build and then upload content registry information.
##

## 'anatomy', 'compound', 'disease', 'gene', 'protein'


TERM_TYPES = ['anatomy', 'compound', 'disease', 'gene', 'protein']

# dictionary mapping terms to list of valid IDs.
#
# note: could do further magic by just building the URL directly, but this
# is simpler to grok, I think.
VALID_ID_URLS = {
    'anatomy': 'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:anatomy/id@sort(id)?accept=csv',
    'gene': 'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:gene/id@sort(id)?accept=csv',
    'protein': 'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:protein/id@sort(id)?accept=csv',
    'disease': 'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:disease/id@sort(id)?accept=csv',
    'compound': 'https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:compound/id@sort(id)?accept=csv',
    }
    
    

rule all:
    message:
        f"Building content for all {len(TERM_TYPES)} controlled vocab types."
    input:
        expand('upload_json/{t}.json', t=TERM_TYPES)


rule upload:
    message:
        "upload new content to the registry."
    input:
        "upload_json/gene.json",
        "upload_json/anatomy.json",
        "upload_json/compound.json",
        "upload_json/protein.json",
        "upload_json/disease.json",
    shell: """
        export DERIVA_SERVERNAME=app-staging.nih-cfde.org
        python3 -m cfde_deriva.registry upload-resources upload_json/disease.json upload_json/protein.json upload_json/compound.json upload_json/gene.json  upload_json/anatomy.json  
        python3 -m cfde_deriva.release refresh-resources 5e0b5f45-2b99-4026-8d22-d1a642a9e903

    """


rule retrieve: 
    message:
        f"retrieve list of ids in the registry"
    input:
        expand("data/validate/{term}.csv", term=TERM_TYPES)


# use wildcards to pull down the valid IDs file for each term
rule retrieve_term_wc:
    output:
        "data/validate/{term}.csv",
    params:
        # construct url by looking up term in VALID_ID_URLS dynamically
        url = lambda w: VALID_ID_URLS[w.term]
    shell: """
        curl -L "{params.url}" -o {output}
    """
    
    

rule gene_json:
    message:
        "build markdown content for genes."
    input:
        "output_pieces_gene/00-alias",
        "output_pieces_gene/01-appyter",
        "output_pieces_gene/02-appyter-lincs-geo-reverse",
        "output_pieces_gene/03-kg",
        "output_pieces_gene/04-disease",
        "output_pieces_gene/05-MetGene",
        "output_pieces_gene/10-expression",
        "output_pieces_gene/11-reverse-search",
        "output_pieces_gene/20-transcripts",
        "output_pieces_gene/70-ucsc",
    output:
        json = "upload_json/gene.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """


rule anatomy_json:
    message:
        "build markdown content for anatomy terms."
    input:
        "output_pieces_anatomy/01-embl",
        "output_pieces_anatomy/01-kg",
        "output_pieces_anatomy/10-expression",

    output:
        json = "upload_json/anatomy.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """


rule compound_json:
    message:
        "build markdown content for compound terms."
    input:
         "output_pieces_compound/01-pubchem",
         "output_pieces_compound/02-glycan",
         "output_pieces_compound/03-kg",
         "output_pieces_compound/03-appyter-lincs-chemical-sim",
         "output_pieces_compound/04-drugcentral",
    output:
        json = "upload_json/compound.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """


rule disease_json:
    message:
        "build markdown content for disease terms",
    input:
        "output_pieces_disease/00-links",
        "output_pieces_disease/01-genes",
        "output_pieces_disease/02-proteins",
    output:
        json = "upload_json/disease.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """


rule protein_json:
    message:
        "build markdown content for protein terms."
    input:
        "output_pieces_protein/00-refseq",
        "output_pieces_protein/01-disease",
    output:
        json = "upload_json/protein.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """





###

##
## add specific widgets here
## 



rule gene_json_alias_widget:
    message: "build alias widgets for genes"
    input:
        script = "scripts/build-markdown-pieces-gene-translate.py",
        id_list = "data/inputs/gene_IDs_for_alias_tables.txt",
        alias_info = "data/inputs/Homo_sapiens.gene_info_20220304.txt_conv_wNCBI_AC.txt",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_gene/00-alias")
    params:
        widget_name = "00-alias",
    shell: """
        {input.script} gene {input.id_list} {input.alias_info} \
            --widget-name alias_table \
            --output-dir {output}
    """

rule gene_json_appyter_link:
    message: "build gene/appyter links for genes"
    input:
        script = "scripts/build-appyter-gene-links.py",
        id_list = "data/inputs/gene_IDs_for_alias_tables.txt",
    output:
        directory("output_pieces_gene/01-appyter")
    params:
        widget_name = "01-appyter"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """

rule gene_json_appyter_lincs_geo_reverse_link:
    message: "build gene/lincs geo reverse appyter links for genes"
    input:
        script = "scripts/build-appyter-gene-links-lincs-geo-reverse.py",
        id_list = "data/inputs/gene_IDs_for_lincs_reverse_search.txt",
    output:
        directory("output_pieces_gene/02-appyter-lincs-geo-reverse")
    params:
        widget_name = "02-appyter-lincs-geo-reverse"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """

rule gene_json_ucsc_genome_browser_widget:
    message: "build UCSC genome browser iframe-include for genes"
    input:
        script = "scripts/build-markdown-pieces-ucsc-genome-browser-widget.pl",
        id_list = "data/inputs/gene_IDs_for_UCSC_genome_browser_widget.txt",
        coord_info = "data/inputs/homo_sapiens.coords.tsv",
    output:
        directory("output_pieces_gene/70-ucsc")
    params:
        widget_name = "70-ucsc"
    shell: """
        {input.script} \
               {input.id_list} \
        {input.coord_info} \
        {params.widget_name} \
               {output}
    """

rule gene_json_expression_widget:
    message: "build expression widgets for genes"
    input:
        script = "scripts/build-markdown-pieces.py",
        id_list = "data/inputs/gene_IDS_for_gtex.txt",
    output:
        directory("output_pieces_gene/10-expression")
    params:
        widget_name = "10-expression"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name expression_widget \
           --output-dir {output}
    """


rule gene_json_transcript_widget:
    message: "build transcript widgets for genes"
    input:
        script = "scripts/build-markdown-pieces.py",
        id_list = "data/inputs/gene_IDS_for_gtex.txt",
    output:
        directory("output_pieces_gene/20-transcripts")
    params:
        widget_name = "20-transcripts"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name transcripts_widget \
           --output-dir {output}
    """

rule gene_json_lincs_widget:
    message: "build MetGene widgets for genes"
    input:
        script = "scripts/build-markdown-pieces-MetGene.py",
        id_list = "data/inputs/gene_IDs_for_MetGene.txt",
    output:
        directory("output_pieces_gene/05-MetGene")
    params:
        widget_name = "05-MetGene"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """

rule anatomy_link:
    message: "add link to embl ols"
    input:
        script = "scripts/build-anatomy-links.py",
        id_list = "data/inputs/anatomy_IDs_for_embl.txt",
    output:
        directory("output_pieces_anatomy/01-embl")
    params:
        widget_name = "01-embl"
    shell: """
        {input.script} anatomy {input.id_list} \
           --widget-name expression_widget \
           --output-dir {output}
    """    

rule anatomy_json_expression_widget:
    message: "build expression widgets for anatomy terms"
    input:
        script = "scripts/build-markdown-pieces.py",
        id_list = "data/inputs/anatomy_IDs_for_gtex.txt",
    output:
        directory("output_pieces_anatomy/10-expression")
    params:
        widget_name = "10-expression"
    shell: """
        {input.script} anatomy {input.id_list} \
           --widget-name expression_widget \
           --output-dir {output}
    """
    

rule compound_json_glytoucan:
    message: "Building GlyTouCan links"
    input:
        script = "scripts/build-compound-glycan.py",
        id_list = "data/inputs/compound_IDs_GlyTouCan.txt",
        alias_info = "data/inputs/compounds_glygen2pubchem.tsv",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_compound/02-glycan")
    params:
        widget_name = "02-glycan",
    shell: """
        {input.script} compound {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name}  \
            --output-dir {output}
    """         



rule compound_json_kg_widget:
    message: "build kg widgets for compound terms"
    input:
        script = "scripts/build-markdown-pieces-gene-kg.py",
        id_list = "data/inputs/compound_IDs_for_gene_kg.txt",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_compound/03-kg")
    params:
        widget_name = "03-kg"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name kg_widget \
           --output-dir {output}
    """

rule compound_json_appyter_lincs_chemical_sim:
    message: "build compound/lincs chemical similarity appyter links for compounds"
    input:
        script = "scripts/build-appyter-lincs-chemical-sim.py",
        id_list = "data/inputs/compound_IDs_for_lincs_chemical_sim_appyter.txt",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_compound/03-appyter-lincs-chemical-sim")
    params:
        widget_name = "03-appyter-lincs-chemical-sim"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """

rule compound_json_pubchem:
    message: "Building PubChem links"
    input:
        script = "scripts/build-compound-pubchem.py",
        id_list = "data/inputs/compound_IDs_PubChem.txt",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_compound/01-pubchem")
    params:
        widget_name = "01-pubchem",
    shell: """
        {input.script} compound {input.id_list} \
            --widget-name {params.widget_name}  \
            --output-dir {output}
    """


rule compound_json_drugcentral:
    message: "Building Drug Central links"
    input:
        script = "scripts/build-compound-drugcentral.py",
        id_list = "data/inputs/compound_IDs_DrugCentral.txt",
        alias_info = "data/inputs/compounds_pubchem2drugcentral.tsv",
        validate_csv = expand("data/validate/{term}.csv", term=TERM_TYPES),
    output:
        directory("output_pieces_compound/04-drugcentral")
    params:
        widget_name = "04-drugcentral",
    shell: """
        {input.script} compound {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name}  \
            --output-dir {output}
    """    


rule gene_json_reverse_search_widget:
    message: "build reverse search widgets for genes"
    input:
        script = "scripts/build-markdown-pieces-lincs-reverse-search.py",
        id_list = "data/inputs/gene_IDs_for_lincs_reverse_search.txt",
    output:
        directory("output_pieces_gene/11-reverse-search")
    params:
        widget_name = "11-reverse-search"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name reverse_search_widget \
           --output-dir {output}
    """
       

rule gene_json_kg_widget:
    message: "build kg widgets for genes"
    input:
        script = "scripts/build-markdown-pieces-gene-kg.py",
        id_list = "data/inputs/gene_IDs_for_gene_kg.txt",
    output:
        directory("output_pieces_gene/03-kg")
    params:
        widget_name = "03-kg"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name kg_widget \
           --output-dir {output}
    """


rule anatomy_json_kg_widget:
    message: "build kg widgets for anatomy terms"
    input:
        script = "scripts/build-markdown-pieces-gene-kg.py",
        id_list = "data/inputs/anatomy_IDs_for_gene_kg.txt",
    output:
        directory("output_pieces_anatomy/01-kg")
    params:
        widget_name = "01-kg"
    shell: """
        {input.script} anatomy {input.id_list} \
           --widget-name kg_widget \
           --output-dir {output}
    """


rule protein_json_refseq:
    message: "build protein markdown for refseq"
    input:
        script = "scripts/build-protein-refseq.py",
        id_list = "data/inputs/protein_IDs.txt",
        alias_info = "data/validate/protein.tsv",
    output:
        directory("output_pieces_protein/00-refseq")
    params:
        widget_name = "00-refseq",
    shell: """
        {input.script} protein {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """

rule protein_json_disease:
    message: "build protein markdown for diseases"
    input:
        script = "scripts/build-protein-disease.py",
        id_list = "data/inputs/protein_IDs_for_disease.txt",
        disease_name_file = "data/inputs/disease_names.txt",
        alias_info = "data/inputs/protein2disease.txt",
    output:
        directory("output_pieces_protein/01-disease")
    params:
        widget_name = "01-disease",
    shell: """
        {input.script} protein {input.id_list} {input.disease_name_file}  {input.alias_info} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """



rule gene_json_disease:
    message: "build gene markdown for diseases"
    input:
        script = "scripts/build-gene-disease.py",
        id_list = "data/inputs/gene_IDs_withdisease.txt",
        disease_name_file = "data/inputs/disease_names.txt",
        alias_info = "data/inputs/gene2disease.txt",
    output:
        directory("output_pieces_gene/04-disease")
    params:
        widget_name = "04-disease",
    shell: """
        {input.script} gene {input.id_list} {input.disease_name_file} {input.alias_info} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """

rule disease_json_links:
    message: "build links for disease terms"
    input:
        script = "scripts/build-disease-links.py",
        id_list = "data/inputs/disease_IDs.txt",
    output:
        directory("output_pieces_disease/00-links")
    params:
        widget_name = "00-links"
    shell: """
        {input.script} disease {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """ 
  
    
rule disease_json_genes:
    message: "build links to genes associated with diseases"
    input:
        script = "scripts/build-disease-genes.py",
        id_list = "data/inputs/disease_IDs.txt",
        alias_info = "data/inputs/disease2gene.txt",
        gene_name_file = "data/inputs/Homo_sapiens.gene_info_20220304.txt_conv_wNCBI_AC.txt",
    output:
        directory("output_pieces_disease/01-genes")
    params:
        widget_name = "01-genes",
    shell: """
        {input.script} disease {input.id_list} {input.alias_info} {input.gene_name_file} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """    
    
rule disease_json_protein:
    message: "build links to proteins associated with diseases"
    input:
        script = "scripts/build-disease-proteins.py",
        id_list = "data/inputs/disease_IDs.txt",
        alias_info = "data/inputs/disease2protein.txt",
        protein_name_file = "data/inputs/protein_names.txt",
    output:
        directory("output_pieces_disease/02-proteins")
    params:
        widget_name = "02-proteins",
    shell: """
        {input.script} disease {input.id_list} {input.alias_info} {input.protein_name_file} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """        
