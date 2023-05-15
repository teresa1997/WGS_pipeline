#!/bin/bash

IDs=" idList "


for ID in $IDs
	do
    gatk CollectWgsMetrics \
    I=path/$ID.fq2bam.bam \
    O=path/collectwgsmetrics/$ID.collect_wgs_metrics.txt \
    R=path/reference/hg38/Homo_sapiens_assembly38.fasta
    done