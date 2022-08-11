##
## Workflow logic to build and then upload content registry information.
##

TERM_TYPES = ['anatomy', 'compound', 'disease', 'gene']

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
    shell: """
        export DERIVA_SERVERNAME=app-dev.nih-cfde.org
        python3 -m cfde_deriva.registry upload-resources upload_json/gene.json upload_json/anatomy.json upload_json/compound.json 
    """


rule gene_json:
    message:
        "build markdown content for genes."
    input:
        "output_pieces_gene/00-alias",
        "output_pieces_gene/01-appyter",
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
         "output_pieces_compound/02-compound",
         "output_pieces_compound/03-compound",
         "output_pieces_compound/04-compound",
         "output_pieces_compound/05-compound",
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
        id_list = "data/inputs/compound_IDs-test.txt",
    output:
        directory("output_pieces_compound/04-compound")
    params:
        widget_name = "04-compound"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """    
    
rule compound_json_glytoucan_image:
    message: "Adding GlyTouCan images"
    input:
        script = "scripts/build-compound-image.py",
        id_list = "data/inputs/compound_IDs_GlyTouCan-test.txt",
    output:
        directory("output_pieces_compound/02-compound")
    params:
        widget_name = "02-compound"
    shell: """
        {input.script} compound {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """        

rule compound_json_alias_widget:
    message: "build alias widgets for compounds"
    input:
        script = "scripts/build-compound-alias.py",
        id_list = "data/inputs/compound_IDs-test.txt",
        alias_info = "data/inputs/compound_glycan.txt",
    output:
        directory("output_pieces_compound/03-compound")
    params:
        widget_name = "03-compound",
    shell: """
        {input.script} compound {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name}  \
            --output-dir {output}
    """

rule compound_json_drugcentral_widget:
    message: "build links for drug central"
    input:
        script = "scripts/build-compound-drugcentral.py",
        id_list = "data/inputs/compound_IDs-test.txt",
        alias_info = "data/inputs/compounds_pubchem2drugcentral.tsv",
    output:
        directory("output_pieces_compound/05-compound")
    params:
        widget_name = "05-compound",
    shell: """
        {input.script} compound {input.id_list} {input.alias_info} \
            --widget-name {params.widget_name}  \
            --output-dir {output}
    """    
