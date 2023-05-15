#!/bin/bash

IDs=" idList "


for ID in $IDs
	do
    mosdepth -n --fast-mode --by 500 -t 4 $ID path/$ID.fq2bam.bam
    done