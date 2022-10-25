all:
	snakemake -j 1

upload:
	snakemake -j 1 upload

update: upload

clean:
	rm -fr output_pieces_* upload_json logs/*txt
	
log:
	for file in output_pieces*/*/; do  echo $$file; echo $$file >> logs/chunks.txt; find $$file -maxdepth 1 -name "*md" | wc -l >> logs/chunks.txt; done
	for file in upload_json/*json; do echo $$file >> logs/aggregated.txt; grep -o '{"id":' $$file | wc -l >> logs/aggregated.txt; done
