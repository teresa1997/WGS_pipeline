#!/usr/bin/env nextflow

// Path Declaration
tmp_path = params.tmp_path
in_path_fastq = params.in_path_fastq
in_path_bam = params.in_path_bam
out_path = params.out_path
ref_path = params.ref_path

//input_run_folder = params.input_run_folder

log.info """\
 WGS - N F   P I P E L I N E
 ===================================
 reference      : ${params.ref_path}
 outdir         : ${params.out_path}
 """


// Reference 
fasta_ref = file( params.fasta_ref )
fasta_ref_fai = file( params.fasta_ref + '.fai' )
fasta_ref_alt = file( params.fasta_ref + '.64.alt' )
fasta_ref_amb = file( params.fasta_ref + '.64.amb' )
fasta_ref_ann = file( params.fasta_ref + '.64.ann' )
fasta_ref_bwt = file( params.fasta_ref + '.64.bwt' )
fasta_ref_pac = file( params.fasta_ref + '.64.pac' )
fasta_ref_sa = file( params.fasta_ref + '.64.sa' )
fasta_ref_dict = file( params.fasta_ref.replace( ".fasta" , ".dict" ))

reference_known_indel = file( params.knwind + 'gz' )
reference_known_indel_idx = file( params.knwind + 'gz.tbi' )

// Channel fastq
fastq_pairs_for_fq2bam = Channel.fromFilePairs( params.in_path_fastq + '/*_{fq1,fq2}.fastq.gz', flat: true )
fastq_pairs_for_fastqc = Channel.fromFilePairs( params.in_path_fastq + '/*_{fq1,fq2}.fastq.gz', flat: true )

// Channel recalibrated bam
recalibrated_bam_svaba = Channel.fromPath( params.in_path_bam + '/*.bam')
recalibrated_bai_svaba = Channel.fromPath( params.in_path_bam + '/*.bai')

// Generate read metrics of fastq file using FastQC 

process FastQC {
    clusterOptions '--ntasks=1'
    time '24h'
    cpus '30'
    memory '8 GB'
    queue 'clara-cpu'

    module 'FastQC/0.11.9-Java-11'

    input:
        tuple val(tup_sample_id), file(fastq_r1_input), file(fastq_r2_input) from fastq_pairs_for_fastqc

    output:
        file "${tup_sample_id}_{fq1,fq2}_fastqc.{html,zip}" into fastqc_for_fastq

    publishDir "${out_path}/WGS_fastqc/", mode: 'copy', overwrite: false

    script:
    """
    fastqc -t 2 "${fastq_r1_input}" "${fastq_r2_input}" -o ./
    """
}


// Generate bam recalibrated file from fastq with parabricks fq2bam
process fq_bam {
    clusterOptions '--ntasks=1'
    clusterOptions '--gres=gpu:v100:2'
    time '24h'
    cpus '30'
    memory '200 GB'
    queue 'clara-job'

    module 'parabricks/3.6.1'

    input:
        file fasta_ref
        file fasta_ref_fai
        file reference_known_indel
        file reference_known_indel_idx
        tuple val(tup_sample_id), file(fastq_r1_input), file(fastq_r2_input) from fastq_pairs_for_fq2bam

    output:
        file "${tup_sample_id}.fq2bam.bam" into recalibrated_bam_cnvkit, recalibrated_bam_gridss, recalibrated_bam_svaba
        //recalibrated_bam_lumpy, recalibrated_bam_pindel, recalibrated_bam_smoove, recalibrated_bam_whamg
        file "${tup_sample_id}.fq2bam.recal.txt"
        file "${tup_sample_id}.fq2bam.bam.bai" into recalibrated_bai_cnvkit, recalibrated_bai_gridss, recalibrated_bai_manta, recalibrated_bai_svaba
        //recalibrated_bai_lumpy, recalibrated_bai_pindel, recalibrated_bai_smoove, recalibrated_bai_whamg
        file "${tup_sample_id}.fq2bam_chrs.txt" 

    publishDir "${out_path}/WGS_recal/", mode: 'copy', overwrite: true

    """
    pbrun fq2bam \
    --ref $fasta_ref \
    --in-fq $fastq_r1_input $fastq_r2_input \
    --knownSites $reference_known_indel \
    --out-bam "${tup_sample_id}.fq2bam.bam" \
    --out-recal-file "${tup_sample_id}.fq2bam.recal.txt" \
    --tmp-dir $tmp_path
    """
}


// Generate read metrics of recalibrated bam file using FastQC 
process FastQC_recalibrated_bam {
    clusterOptions '--ntasks=1'
    time '24h'
    cpus '10'
    //memory '50 GB'
    queue 'clara-cpu'

    memory { 50.GB * task.attempt }
    maxRetries = { task.exitStatus == 140 ? 4 : 1 }
    errorStrategy = { sleep(task.attempt * 200); return 'retry' }

    module 'FastQC/0.11.9-Java-11'

    input:
        file recal_bam from recalibrated_bam_fastqc

    output:
        file "${recal_bam.simpleName}.{html,zip}" into fastqc_for_recalibrated_bam

    publishDir "${out_path}/WGS_fastqc/", mode: 'copy', overwrite: true

    script:
    """
    fastqc "${recal_bam}" -o ./
    """
}



//SVcaller

process svaba {
    clusterOptions '--ntasks=1'
	time '24h'
    cpus '30'
    memory '50 GB'
    queue 'clara-cpu'

    module 'svaba/1.1.0-foss-2020b'
	
	input:
		file fasta_ref	
		file fasta_ref_fai
        file fasta_ref_alt
		file fasta_ref_amb
		file fasta_ref_ann
		file fasta_ref_bwt
		file fasta_ref_pac
		file fasta_ref_sa
        file fasta_ref_dict
		file recal_bam from recalibrated_bam_svaba
		file recal_bam_bai from recalibrated_bai_svaba

	output: 
		file "${recal_bam.simpleName}.alignments.txt.gz" 
		file "${recal_bam.simpleName}.bps.txt.gz" 
		file "${recal_bam.simpleName}.contigs.bam" 
		file "${recal_bam.simpleName}.discordant.txt.gz" 
		file "${recal_bam.simpleName}.svaba.indel.vcf"
		file "${recal_bam.simpleName}.svaba.sv.vcf"
		file "${recal_bam.simpleName}.svaba.unfiltered.indel.vcf"
		file "${recal_bam.simpleName}.svaba.unfiltered.sv.vcf"
		file "${recal_bam.simpleName}.log"
		
	publishDir "${out_path}/svaba/WGS_output/${recal_bam.simpleName}", mode: 'copy', overwrite: false
	
	"""
	svaba run \
        -p 24 \
		-t $recal_bam \
		-L 6 \
		-I -a ${recal_bam.simpleName} \
		-G $fasta_ref
	"""
}





//Manta
process manta {
    clusterOptions '--ntasks=1'
    time '24h'
    cpus '10'
    //memory '5 GB'
    queue 'clara-cpu'

    memory { 5.GB * task.attempt }
    maxRetries = { task.exitStatus == 140 ? 4 : 1 }
    errorStrategy = { sleep(task.attempt * 200); return 'retry' }

    module 'manta/1.6.0-GCC-10.2.0-Python-2.7.18'
    
	input:
		file fasta_ref
        file fasta_ref_fai
        file recal_bai from recalibrated_bai_manta
		file recal_bam from recalibrated_bam_manta
		
	
	publishDir "${out_path}/manta/", mode: 'copy', overwrite: true

    """
    configManta.py \
        --bam $recal_bam \
        --referenceFasta $fasta_ref \
        --runDir "${out_path}/manta/" | "${out_path}/manta/"runWorkflow.py
    """
}


process smoove {
    clusterOptions '--ntasks=1'
    time '1h'
    cpus '10'
    memory '50 GB'
    queue 'clara-cpu'

    module 'smoove/0.2.6-foss-2020b-Python-2.7.18'

    input:
        file fasta_ref
        file fasta_ref_fai
        file recal_bam from recalibrated_bam_smoove
        file recal_bai from recalibrated_bai_smoove

    output:
        file "${recal_bam.simpleName}-lumpy-cmd.sh" into output_smoove_sh
        file "${recal_bam.simpleName}-smoove.genotyped.vcf" into output_smoove_vcf
        file "${recal_bam.simpleName}-smoove.genotyped.vcf.gz.csi" into output_smoove_vcf_csi
        file "${recal_bam.simpleName}-smoove.genotyped.vcf.gz.tbi" into output_smoove_vcf_tbi
        file "${recal_bam.simpleName}.disc.bam" into output_smoove_disc_bam
        file "${recal_bam.simpleName}.disc.bam.csi" into output_smoove_disc_bam_csi
        file "${recal_bam.simpleName}.disc.bam.orig.bam" into output_smoove_disc_orig_bam
        file "${recal_bam.simpleName}.histo" into output_smoove_histo
        file "${recal_bam.simpleName}.split.bam" into output_smoove_split_bam
        file "${recal_bam.simpleName}.split.bam.csi" into output_smoove_split_bam_csi
        file "${recal_bam.simpleName}.split.bam.orig.bam" into output_smoove_split_orig_bam

    publishDir "${out_path}/smoove/", mode: 'copy', overwrite: true

    """
    smoove call \
        -x \
        -p 24 \
        --fasta $fasta_ref \
        --genotype $recal_bam \
        --name ${recal_bam.simpleName}
    """
}

process whamg {
    clusterOptions '--ntasks=1'
    time '1h'
    cpus '2'
    memory '2 GB'
    queue 'clara-cpu'

    module 'wham/1.8.0-GCC-10.2.0'
    
	input:
		file fasta_ref
        file fasta_ref_fai
		file recal_bai from recalibrated_bai_whamg
        file recal_bam from recalibrated_bam_whamg
		
	output:
		file "${recal_bam.simpleName}.whamg.vcf" into output_whamg_vcf
	
	publishDir "${out_path}/whamg/${recal_bam.simpleName}", mode: 'copy', overwrite: false

	"""
	whamg \
		-x 16 \
		-a '${fasta_ref}' \
		-f '${recal_bam}' \
		> '${recal_bam.simpleName}.whamg.vcf'
	"""
}

