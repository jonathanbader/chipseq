def SOFTWARE = 'multiqc'

// Has the run name been specified by the user?
// this has the bonus effect of catching both -name and --name
custom_runName = params.name
if (!(workflow.runName ==~ /[a-z]+_[a-z]+/)) {
    custom_runName = workflow.runName
}

process MULTIQC {
    publishDir "${params.outdir}/multiqc", mode: params.publish_dir_mode

    container "quay.io/biocontainers/multiqc:1.9--pyh9f0ad1d_0"
    //container "https://depot.galaxyproject.org/singularity/multiqc:1.9--pyh9f0ad1d_0"

    conda (params.conda ? "bioconda::multiqc=1.9" : null)

    input:
    path (multiqc_config) from ch_multiqc_config
    path (mqc_custom_config) from ch_multiqc_custom_config.collect().ifEmpty([])
    // TODO nf-core: Add in log files from your new processes for MultiQC to find!
    path ('fastqc/*') from ch_fastqc_results.collect().ifEmpty([])
    path ('software_versions/*') from ch_software_versions_yaml.collect()
    path workflow_summary from ch_workflow_summary.collectFile(name: "workflow_summary_mqc.yaml")

    output:
    path "*multiqc_report.html"
    path "*_data"
    path "multiqc_plots"

    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    custom_config_file = params.multiqc_config ? "--config $mqc_custom_config" : ''
    // TODO nf-core: Specify which MultiQC modules to use with -m for a faster run time
    """
    multiqc -f $rtitle $rfilename $custom_config_file .
    multiqc --version | sed -e "s/multiqc, version //g" > ${SOFTWARE}.version.txt
    """
}