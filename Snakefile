##
## Workflow logic to build and then upload content registry information.
##

TERM_TYPES = ['anatomy', 'compound', 'disease', 'gene', 'protein']

rule all:
    message:
        f"Building content for all {len(TERM_TYPES)} controlled vocab types."
    input:
        expand('upload_json/{t}.json', t=TERM_TYPES)


rule upload:
    message:
        "upload new content to the registry."
    input:
        #"upload_json/gene.json",
        #"upload_json/anatomy.json",
        #"upload_json/compound.json",
        "upload_json/protein.json",
    shell: """
        export DERIVA_SERVERNAME=app-staging.nih-cfde.org
        python3 -m cfde_deriva.registry upload-resources upload_json/protein.json 
        #upload_json/anatomy.json upload_json/compound.json 
    """


rule gene_json:
    message:
        "build markdown content for genes."
    input:
        "output_pieces_gene/00-alias",
        "output_pieces_gene/01-appyter",
        "output_pieces_gene/02-appyter-lincs-geo-reverse",
        "output_pieces_gene/10-expression",
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
        "output_pieces_anatomy/10-expression"
    output:
        json = "upload_json/anatomy.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """

rule compound_json:
    message:
        "build markdown content for compound terms."
    input:
        "output_pieces_compound/01-compound",
        "output_pieces_compound/02-compound",
        "output_pieces_compound/03-appyter-lincs-chemical-sim",
    output:
        json = "upload_json/compound.json",
    shell: """
        ./scripts/aggregate-markdown-pieces.py {input} -o {output.json}
    """


# nothing here yet.
rule disease_json:
    output:
        "upload_json/disease.json"
    shell: """
        touch {output}
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
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
        alias_info = "data/inputs/Homo_sapiens.gene_info_20220304.txt_conv_wNCBI_AC.txt",
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
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_expression_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
    output:
        directory("output_pieces_gene/20-transcripts")
    params:
        widget_name = "20-transcripts"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name transcripts_widget \
           --output-dir {output}
    """



rule anatomy_json_expression_widget:
    message: "build expression widgets for anatomy terms"
    input:
        script = "scripts/build-markdown-pieces.py",
        id_list = "data/inputs/anatomy_IDs_for_expression_widget.txt",
    output:
        directory("output_pieces_anatomy/10-expression")
    params:
        widget_name = "10-expression"
    shell: """
        {input.script} anatomy {input.id_list} \
           --widget-name expression_widget \
           --output-dir {output}
    """


rule compound_json_links:
    message: "build links for compound terms"
    input:
        script = "scripts/build-compound-links.py",
        id_list = "data/inputs/compound_IDs_test.txt",
    output:
        directory("output_pieces_compound/01-compound")
    params:
        widget_name = "01-compound"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """    
    
rule compound_json_glytoucan_image:
    message: "Adding GlyTouCan images"
    input:
        script = "scripts/build-compound-image.py",
        id_list = "data/inputs/compound_IDs_test.txt",
    output:
        directory("output_pieces_compound/02-compound")
    params:
        widget_name = "02-compound"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """        


rule compound_json_appyter_lincs_chemical_sim:
    message: "build compound/lincs chemical similarity appyter links for compounds"
    input:
        script = "scripts/build-appyter-lincs-chemical-sim.py",
        id_list = "data/inputs/compound_IDs_test.txt",
    output:
        directory("output_pieces_compound/03-appyter-lincs-chemical-sim")
    params:
        widget_name = "03-appyter-lincs-chemical-sim"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
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
        id_list = "data/inputs/proteins_IDs_withdisease.txt",
        alias_info = "data/inputs/proteins2disease2genes.txt",
    output:
        directory("output_pieces_protein/01-disease")
    params:
        widget_name = "01-disease",
    shell: """
        {input.script} protein {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name} \
            --output-dir {output}
    """
