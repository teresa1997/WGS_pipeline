IDs=" idList "

for ID in $IDs
	do
    svtyper-sso \
    -i path/$ID.whamg.vcf \
    -o path/$ID.whamg.svtyper.vcf \
    -B path/$ID.fq2bam.bam \
    -T path/references/Homo_sapiens_assembly38.fasta
    done