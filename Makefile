all:
	snakemake -j 1 --use-conda

upload:
	snakemake -j 1 --use-conda upload

update: upload

clean:
	rm -fr output_pieces_* upload_json
