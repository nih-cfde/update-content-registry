#! /usr/bin/env perl

use strict;

use URI::Escape;

$| = 1;

################################################################################
# ARGUMENTS
################################################################################

my $idList = shift;

my $widgetName = shift;

my $outDir = shift;

if ( $outDir eq '' ) {
	
	die("Usage: $0 <term ID list> <widget name> <output directory>\n");
}

if ( not -e $idList ) {
	
	die("FATAL: Can't open specified term ID list \"$idList\"; aborting.\n");
}

if ( not -d $outDir ) {
	
	system("mkdir -p $outDir");
}

################################################################################
# PARAMETERS
################################################################################

my $validationMatrix = 'data/validate/ensembl_genes.tsv';

################################################################################
# EXECUTION
################################################################################

################################################################################
# Preload valid Ensembl IDs.

my $validIDs = {};

open IN, "<$validationMatrix" or die("Can't open $validationMatrix for reading.\n");

my $header = <IN>;

while ( chomp( my $line = <IN> ) ) {
	
	my ( $termID, @theRest ) = split(/\t/, $line);

	$validIDs->{$termID} = 1;
}

close IN;

################################################################################
# Load target Ensembl IDs and ensure all are valid.

my $targetIDs = {};

open IN, "<$idList" or die("Can't open $idList for reading.\n");

while ( chomp( my $id = <IN> ) ) {
	
	if ( not $validIDs->{$id} ) {
		
		die("FATAL: Target Ensembl gene ID \"$id\" not found in C2M2 reference list. Please check your sources and try again.\n");
	}

	$targetIDs->{$id} = 1;
}

close IN;

################################################################################
# Attempt to establish a custom browser URL for each target Ensembl ID.

my $targetURLs = {};

foreach my $termID ( keys %$targetIDs ) {
	
	my $result = `curl "https://genome.ucsc.edu/cgi-bin/hgTracks?hgtgroup_map_close=0&hgtgroup_genes_close=0&hgtgroup_phenDis_close=0&hgtgroup_covid_close=0&hgtgroup_singleCell_close=0&hgtgroup_rna_close=0&hgtgroup_expression_close=0&hgtgroup_regulation_close=0&hgtgroup_compGeno_close=0&hgtgroup_varRep_close=0&hgtgroup_rep_close=0&hgsid=1391249855_Daatab52zi7CTH5N3y6APpNkUwRe&position=$termID&hgt.positionInput=$termID&goButton=go&hgt.suggestTrack=knownGene&db=hg38&c=chrX&l=100627107&r=100636806&pix=950&dinkL=2.0&dinkR=2.0"`;

	my $url = '';

	my $recording = 0;

	my $found = 0;

	FOUND_LINK: foreach my $line ( split(/\n/, $result) ) {
		
		if ( $line =~ /hgFindResults/ ) {
			
			$recording = 1;

		} elsif ( $recording ) {
			
			if ( $line =~ /A HREF=\"([^"]+)\"/ ) {
				
				$url = $1;

				$url =~ s/^\.\./https:\/\/genome.ucsc.edu/;

				$found = 1;

				last FOUND_LINK;
			}
		}
	}

	if ( not $found ) {
		
		print STDERR "WARNING: No URL was findable for target Ensembl ID \"$termID\"; skipping, will not process this term for this widget.\n";

	} else {
		
		$targetURLs->{$termID} = $url;
	}
}

################################################################################
# Save UCSC Genome Browser URLs for all successfully-processed Ensembl IDs.

foreach my $targetID ( sort { $a cmp $b } keys %$targetURLs ) {
	
	my $outFile = "$outDir/" . uri_escape("${widgetName}_${targetID}.json");

	open OUT, ">$outFile" or die("Can't open $outFile for writing.\n");

	print OUT '{"id": "' . $targetID . '", "resource_markdown": "::: iframe [**Context view (via UCSC Genome Browser):**](' . $targetURLs->{$targetID} . '){width=\"1200\" height=\"900\" style=\"border: 1px solid black;\" caption-style=\"font-size: 24px;\" caption-link=\"' . $targetURLs->{$targetID} . '\" caption-target=\"_blank\"} \n:::\n"}';

	close OUT;
}


