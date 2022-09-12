all:
	snakemake -j 1

retrieve:
	snakemake -j 1 retrieve

upload:
	snakemake -j 1 upload

update: upload

clean:
	rm -fr output_pieces_* upload_json logs/*.csv
	touch logs/skipped.csv
	touch logs/chunks.csv
