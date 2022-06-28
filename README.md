# Scripts and workflows to build and update the CFDE portal content registry

## Dependencies

You'll need a modern Python (3.8+) together with snakemake and
cfde-deriva. If you conda/mamba, you can do that with the below:

```
mamba create -n content-reg -c bioconda -y snakemake-minimal
conda activate content-reg
pip install git+https://github.com/nih-cfde/cfde-deriva.git
```

Alternatively, running
```
pip install git+https://github.com/nih-cfde/cfde-deriva.git snakemake
```
should get you there.

## Quickstart - building


```
make clean
make
```

## Who can contribute?

Anyone who wants to! Please create pull requests from branches within
this repository; you'll need to ask
[the helpdesk](mailto:support@cfde.atlassian.net) to be added to the
[content-registry-contrib team](https://github.com/orgs/nih-cfde/teams/content-registry-contrib).

