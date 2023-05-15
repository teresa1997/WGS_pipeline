#!/bin/bash

IDs=" idList "

for ID in $IDs
	do
	picard -Xmx8G SamToFastq \
	-I path/ubam/$ID.revertsam.bam \
	-F path/fastq/$ID'_fq1.fastq.gz' \
	-F2 path/fastq/$ID'_fq2.fastq.gz' \
	--TMP_DIR /home/teresa/tmp \
	2> /path/fastq/$ID.fastq.log
	done


