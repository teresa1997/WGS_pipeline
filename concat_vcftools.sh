#!/bin/bash

IDs=" idList "

for ID in $IDs
	do
	vcf-concat path/svaba/$ID/$ID.svaba.indel.vcf path/svaba/$ID/$ID.svaba.sv.vcf \
    > path/svaba/$ID/$ID.svaba.concat_vcftools.vcf
	done
