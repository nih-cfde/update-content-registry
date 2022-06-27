# workflow2 - a reimplementation in Python

## Dependencies

You'll need Python and snakemake minimal:

```
mamba create -n content-reg2 -c bioconda -y snakemake-minimal
conda activate content-reg
pip install git+https://github.com/nih-cfde/cfde-deriva.git
```

## Quickstart


```
make clean
make
make upload
```
