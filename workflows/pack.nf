/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_pack_pipeline'
include { QUALITY_CHECK_BY_CHECKM2 } from '../subworkflows/local/quality_check_by_checkm2'
include { ANNOTATE_WITH_PROKKA } from '../subworkflows/local/annotate_with_prokka'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PACK {
    take:
    genomes

    main:

    // Track versions
    ch_versions = Channel.empty()
    // Run a subworkflow that:
    // - Downloads CheckM2 DB (once)
    // - Collects genome files into a merged input
    // - Runs CheckM2 on all genomes together
    if( !params.skip_checkm2 ) {
        QUALITY_CHECK_BY_CHECKM2(
            genomes,
            params.checkm2_zenodo_id
        )

        // Merge version info from CheckM2-related processes
        ch_versions = ch_versions.mix(QUALITY_CHECK_BY_CHECKM2.out.versions)
    }
    // - Runs prokka on all genomes together
    // if file exists, pass it; else use null (handled cleanly)
    if( !params.skip_prokka ) {
        /*
        ================================================================================
        OPTIONAL INPUT HANDLING: Protein reference (--proteins) and prodigal_tf (--prodigal_tf)
        If not supplied, pass empty lists instead of null to avoid breaking the module.
        ================================================================================
        */


        // ch_proteins    = get_optional_input(params.proteins)
        // ch_prodigal_tf = get_optional_input(params.prodigal_tf)
        // Convert optional params to a channel that emits [] for every genome
        ch_proteins = params.proteins ? Channel.fromPath(params.proteins, checkIfExists: true) : genomes.map { [] }
        ch_prodigal_tf = params.prodigal_tf ? Channel.fromPath(params.prodigal_tf, checkIfExists: true) : genomes.map { [] }
        // ch_proteins = params.proteins ? Channel.fromPath(params.proteins).map { [it] }.broadcast() : genomes.map { [] }
        // ch_prodigal_tf = params.prodigal_tf ? Channel.fromPath(params.prodigal_tf).map { [it] }.broadcast() : genomes.map { [] }

        
        /*
        ================================================================================
        ANNOTATION: Run genome annotation using Prokka
        ================================================================================
        */
        ANNOTATE_WITH_PROKKA(
            genomes,
            ch_proteins,
            ch_prodigal_tf,
        )

        // Merge version info from Prokka
        ch_versions = ch_versions.mix(ANNOTATE_WITH_PROKKA.out.versions)
    }
    // Optional: View version info for debugging
    // ch_versions.view()
    // // Step 1: Download CheckM2 database
    // CHECKM2_DATABASEDOWNLOAD(params.checkm2_zenodo_id)
    // ch_checkm2_db = CHECKM2_DATABASEDOWNLOAD.out.database
    // ch_versions = ch_versions.mix(CHECKM2_DATABASEDOWNLOAD.out.versions)
    // ch_versions.view()
    // genomes.view()
    // GENOMECOLLECTOR(
    //      genomes
    //     )
    
    // ch_wrapped_genomes = genomes.map { file ->
    //     def sample_id = file.getBaseName().replaceAll(/\.(fna|fa|fasta)(\.gz)?$/, "")
    //     return [ [ id: sample_id ], file ]
    // }
    // ch_wrapped_genomes.view()
    // Step 2: Run CheckM2 predict
    // CHECKM2_PREDICT(
    //     // GENOMECOLLECTOR.out.wrapped_genomes,
    //     GENOMECOLLECTOR.out.merged_genomes,        
    //     ch_checkm2_db
    // )
    // ch_versions = ch_versions.mix(CHECKM2_PREDICT.out.versions)

    // Save software versions to YAML
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'software_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    emit:
    versions = ch_collated_versions
    // take:
    // ch_samplesheet // channel: samplesheet read in from --input
    // main:

    // ch_versions = Channel.empty()
    // ch_multiqc_files = Channel.empty()
    // //
    // // MODULE: Run FastQC
    // //
    // FASTQC (
    //     ch_samplesheet
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
    // ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    // //
    // // Collate and save software versions
    // //
    // softwareVersionsToYAML(ch_versions)
    //     .collectFile(
    //         storeDir: "${params.outdir}/pipeline_info",
    //         name:  'pack_software_'  + 'mqc_'  + 'versions.yml',
    //         sort: true,
    //         newLine: true
    //     ).set { ch_collated_versions }


    // //
    // // MODULE: MultiQC
    // //
    // ch_multiqc_config        = Channel.fromPath(
    //     "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    // ch_multiqc_custom_config = params.multiqc_config ?
    //     Channel.fromPath(params.multiqc_config, checkIfExists: true) :
    //     Channel.empty()
    // ch_multiqc_logo          = params.multiqc_logo ?
    //     Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
    //     Channel.empty()

    // summary_params      = paramsSummaryMap(
    //     workflow, parameters_schema: "nextflow_schema.json")
    // ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
    //     file(params.multiqc_methods_description, checkIfExists: true) :
    //     file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    // ch_methods_description                = Channel.value(
    //     methodsDescriptionText(ch_multiqc_custom_methods_description))

    // ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    // ch_multiqc_files = ch_multiqc_files.mix(
    //     ch_methods_description.collectFile(
    //         name: 'methods_description_mqc.yaml',
    //         sort: true
    //     )
    // )

    // MULTIQC (
    //     ch_multiqc_files.collect(),
    //     ch_multiqc_config.toList(),
    //     ch_multiqc_custom_config.toList(),
    //     ch_multiqc_logo.toList(),
    //     [],
    //     []
    // )

    // emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    // versions       = ch_versions                 // channel: [ path(versions.yml) ]

}
    // def get_optional_input(path_str) {
    //     return path_str ? Channel.fromPath(path_str, checkIfExists: true) : []
    // }
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
