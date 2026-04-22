// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { CHECKM2_DATABASEDOWNLOAD } from '../../../modules/nf-core/checkm2/databasedownload/main'
include { CHECKM2_PREDICT } from '../../../modules/nf-core/checkm2/predict/main'
include { GENOMECOLLECTOR } from '../../local/utils_nfcore_pack_pipeline'

/*
========================================================================================
  QUALITY_CHECK_BY_CHECKM2
  - Downloads CheckM2 database (only if not already present)
  - Collects genome files as a merged set
  - Runs CheckM2 prediction across all genomes together
  - Emits results and software version info
========================================================================================
*/

workflow QUALITY_CHECK_BY_CHECKM2 {

    take:
    genomes             // Channel of genome files (paths)
    checkm2_zenodo_id   // Zenodo ID for the CheckM2 database to be downloaded

    main:

    // STEP 1: Download CheckM2 database (if not already downloaded)
    CHECKM2_DATABASEDOWNLOAD(checkm2_zenodo_id)
    ch_checkm2_db = CHECKM2_DATABASEDOWNLOAD.out.database
    ch_versions   = CHECKM2_DATABASEDOWNLOAD.out.versions

    // STEP 2: Collect all genome files into one merged list with shared metadata
    GENOMECOLLECTOR(genomes,"merged")

    // STEP 3: Run CheckM2 predict using all merged genomes
    CHECKM2_PREDICT(
        GENOMECOLLECTOR.out.genomes_formatted_for_input,
        ch_checkm2_db
    )

    // STEP 4: Merge software version information from database download + CheckM2
    ch_versions = ch_versions.mix(CHECKM2_PREDICT.out.versions)

    emit:
    checkm2_output = CHECKM2_PREDICT.out.checkm2_output  // Output directory with prediction files
    checkm2_tsv    = CHECKM2_PREDICT.out.checkm2_tsv     // Final quality_report.tsv file
    versions       = ch_versions                         // Combined software versions
}
