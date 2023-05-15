#!/bin/bash

multiqc path/gatk/collectmultiplemetrics
multiqc path/gatk/collectwgsmetrics
multiqc path/mosdepth
multiqc path/fastqc_fq2bam