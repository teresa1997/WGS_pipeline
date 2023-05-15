#!/bin/bash

IDs=" idList "

for ID in $IDs
	do
    perl /home/teresa/envs_teresa/envs/knotannotsv/knotAnnotSV/knotAnnotSV.pl \
    --configFile path/knotAnnotSV/config_AnnotSV.yaml \
    --annotSVfile path/annotsv/$ID.annotsv.tsv \
    --genomeBuild GRCh38 \
    --outDir path/ \
    --outPrefix knotannotsv.
    done
