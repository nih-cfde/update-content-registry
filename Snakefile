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
        "output_pieces_gene/00appyter"
    output:
        json = "upload_json/gene.json",
    shell: """
        #./scripts/build-markdown-pieces.py gene ../markdown_automation/003_term_lists_for_markdown_attachment/gene_IDs_for_expression_widget.txt expression_widget
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
    output:
        json = "upload_json/anatomy.json",
        pieces_dir = directory('output_pieces_anatomy'),
    shell: """
        ./scripts/build-markdown-pieces.py anatomy ../markdown_automation/003_term_lists_for_markdown_attachment/anatomy_IDs_for_expression_widget.txt expression_widget
        ./scripts/xaggregate-markdown-pieces.py {output.pieces_dir} -o {output.json}
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
    input:
        script = "scripts/build-appyter-gene-links.py",
        id_list = "data/inputs/gene_IDs_for_transcripts_widget.txt",
    output:
        directory("output_pieces_gene/00appyter")
    params:
        widget_name = "00appyter"
    shell: """
        {input.script} gene {input.id_list} \
           --widget-name {params.widget_name} \
           --output-dir {output}
    """
