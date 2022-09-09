#!/bin/bash


if [ ! -f data/validate/anatomy.csv ]
then
    echo "Downloading csv of ids for anatomy."
    curl -L "https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:anatomy/id@sort(id)?accept=csv" -o data/validate/anatomy.csv
else
    echo "csv with ids found for anatomy."
fi


if [ ! -f data/validate/gene.csv ]
then
    echo "Downloading csv of ids for gene."
    curl -L "https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:gene/id@sort(id)?accept=csv" -o data/validate/gene.csv
else
    echo "csv with ids found for gene."
fi


if [ ! -f data/validate/protein.csv ]
then
    echo "Downloading csv of ids for protein."
    curl -L "https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:protein/id@sort(id)?accept=csv" -o data/validate/protein.csv
else
    echo "csv with ids found for protein."
fi


if [ ! -f data/validate/disease.csv ]
then
    echo "Downloading csv of ids for disease."
    curl -L "https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:disease/id@sort(id)?accept=csv" -o data/validate/disease.csv
else
    echo "csv with ids found for disease."
fi


if [ ! -f data/validate/compound.csv ]
then
    echo "Downloading csv of ids for compound."
    curl -L "https://app.nih-cfde.org/ermrest/catalog/1/attribute/CFDE:compound/id@sort(id)?accept=csv" -o data/validate/compound.csv
else
    echo "csv with ids found for compound."
fi