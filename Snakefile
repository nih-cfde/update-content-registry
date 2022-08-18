##
## Workflow logic to build and then upload content registry information.
##


TERM_TYPES = ['anatomy', 'disease', 'gene']

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
       # "upload_json/anatomy.json",
    shell: """
        export DERIVA_SERVERNAME=app-dev.nih-cfde.org
        python3 -m cfde_deriva.registry upload-resources upload_json/gene.json 
        #upload_json/anatomy.json
        #python3 -m cfde_deriva.release refresh-resources 3b297b75-d7de-4f4b-876c-0233f68580ed
    """


rule gene_json:
    message:
        "build markdown content for genes."
    input:
        "output_pieces_gene/00-alias",
        "output_pieces_gene/01-appyter",
        "output_pieces_gene/02-MetGene",
        "output_pieces_gene/02-appyter-lincs-geo-reverse",
        "output_pieces_gene/10-expression",
        "output_pieces_gene/11-reverse-search",
        "output_pieces_gene/20-transcripts",
        "output_pieces_gene/30-kg",
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
        #"output_pieces_compound/01-compound",
        #"output_pieces_compound/02-compound",
        #"output_pieces_compound/03-appyter-lincs-chemical-sim",
        "output_pieces_compound/30-kg",
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





###

##
## add specific widgets here
## 



rule gene_json_alias_widget:
    message: "build alias widgets for genes"
    input:
        script = "scripts/build-markdown-pieces-gene-translate.py",
        id_list = "data/inputs/gene_IDs_for_expression_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_expression_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_lincs_geo_reverse_appyter.txt",
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
        id_list = "data/inputs/gene_IDs_for_expression_widget.txt",
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
        id_list = "data/inputs/gene_IDs_for_expression_widget.txt",
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
        directory("output_pieces_gene/02-MetGene")
    params:
        widget_name = "metgene_widget"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
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
        directory("output_pieces_gene/30-kg")
    params:
        widget_name = "30-kg"
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

rule compound_json_kg_widget:
    message: "build kg widgets for compound terms"
    input:
        script = "scripts/build-markdown-pieces-gene-kg.py",
        id_list = "data/inputs/compound_IDs_for_gene_kg.txt",
    output:
        directory("output_pieces_compound/30-kg")
    params:
        widget_name = "30-kg"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name kg_widget \
           --output-dir {output}
    """
