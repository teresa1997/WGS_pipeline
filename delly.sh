#!/bin/bash

IDs=" idList "

for ID in $IDs
    do  
    /home/teresa/envs_teresa/envs/delly/delly call \
    -g path/reference/hg38/Homo_sapiens_assembly38.fasta \
    -o pathdelly/$ID/$ID.delly.sv.bcf \
    path/$ID.fq2bam.bam \
    2> path/delly/$ID/$ID.log

    bcftools view path/delly/$ID/$ID.delly.sv.bcf > path/delly/$ID/$ID.delly.sv.vcf 
    done
