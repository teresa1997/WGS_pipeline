#!/bin/bash
 
IDs=" idList "

for ID in $IDs
	do
    /home/teresa/envs_teresa/envs/annotsv/AnnotSV/bin/AnnotSV \
    -SVinputfile path/$ID.vcf \
    -genomeBuild GRCh38 \
    -outputFile path/annotsv/$ID.annotsv
    done
