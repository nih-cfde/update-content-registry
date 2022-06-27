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
    shell: """
        python3 -m cfde_deriva.registry upload-resources upload_json/gene.json upload_json/anatomy.json
    """


rule gene_json:
    message:
        "build markdown content for genes."
    input:
        "output_pieces_gene/00-appyter",
        "output_pieces_gene/10-expression",
    output:
        json = "upload_json/gene.json",
    shell: """
        #./scripts/build-markdown-pieces.py gene ../markdown_automation/003_term_lists_for_markdown_attachment/gene_IDs_for_transcripts_widget.txt transcripts_widget
        #./scripts/build-markdown-pieces-gene-translate.py gene ../markdown_automation/003_term_lists_for_markdown_attachment/gene_IDs_for_transcripts_widget.txt ../markdown_automation/001_data_sources/gene_alias_file_from_Mano/Homo_sapiens.gene_info_20220304.txt_conv_wNCBI_AC.txt

        ##
        ## add new script calls above this line.
        ##
    
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


# nothing here yet.
rule disease_json:
    output:
        "upload_json/disease.json"
    shell: """
        touch {output}
    """

# nothing here yet.
rule compound_json:
    output:
        "upload_json/compound.json"
    shell: """
        touch {output}
    """


###

##
## add specific widgets here
## 


rule gene_json_appyter_link:
    message: "build gene/appyter links for genes"
    input:
        script = "scripts/build-appyter-gene-links.py",
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
    output:
        directory("output_pieces_gene/00-appyter")
    params:
        widget_name = "00-appyter"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
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
