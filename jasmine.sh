#!/bin/bash

IDs=" idList "

for ID in $IDs
    do  
    jasmine \
    file_list=path/$ID.tool.txt \
    out_file=path/$ID.vcf \
    genome_file=path/Homo_sapiens_assembly38.fasta \
    bam_list=path/$ID.bam.txt \
    max_dist_linear=1.0 \
    threads=16 \
    min_overlap=0.75 \
    min_support=2 \
    --normalize_type \
    --ignore_strand \
    2>path/err/$ID.err
    done
