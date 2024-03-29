#!/bin/bash

IDs=" idList "

for ID in $IDs
	do
    picard -Xmx8G RevertSam \
    INPUT= path/bam/$ID.bam \
    OUTPUT= path/ubam/$ID.revertsam.bam \
    SANITIZE=true \
    MAX_DISCARD_FRACTION=0.005 \
    ATTRIBUTE_TO_CLEAR=XT \
    ATTRIBUTE_TO_CLEAR=XN \
    ATTRIBUTE_TO_CLEAR=AS \
    ATTRIBUTE_TO_CLEAR=OC \
    ATTRIBUTE_TO_CLEAR=OP \
    SORT_ORDER=queryname \
    RESTORE_ORIGINAL_QUALITIES=true \
    REMOVE_DUPLICATE_INFORMATION=true \
    REMOVE_ALIGNMENT_INFORMATION=true \
    TMP_DIR=/home/teresa/tmp \
    2> path/ubam/$ID.revertsam.log
    done


