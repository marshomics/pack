// Subworkflow: CLASSIFY_WITH_GTDBTK

include { GTDBTK_CLASSIFYWF } from '../../../modules/nf-core/gtdbtk/classifywf'
include { GTDBDATABASEDOWNLOAD } from '../../../modules/local/gtdbdatabasedownload' // You must create this module
include { GENOMECOLLECTOR } from '../../local/utils_nfcore_pack_pipeline'

workflow CLASSIFY_WITH_GTDBTK {

    take:
    bins        // Channel: [meta, bin_path]
    db_path     // Path to GTDB database (optional)

    main:
    // Decide whether to download or use provided DB
    db_channel = db_path ? Channel.of(["gtdbtk_db", file(db_path)]) : GTDBDATABASEDOWNLOAD()

    // Merge bins into one directory for classify_wf
    // STEP 2: Collect all genome files into one merged list with shared metadata
// Step 2: Merge bins per genome
    GENOMECOLLECTOR(bins, "wrapped")

    // Step 3: Group bins together by sample
    GENOMECOLLECTOR.out.genomes_formatted_for_input
        .map { meta, bin -> [meta, bin] }
        .groupTuple()
        .map { meta, bins -> 
            def bin_dir = file("bins")
            """
            mkdir -p bins
            ${bins.collect{ "ln -s ${it} bins/" }.join('\n')}
            """
            tuple(meta, bin_dir)
        }
        .set { ch_binned_genomes }
    // ch_bins_dir = bins.collect()
    // .map { paths ->
    //     def meta = [ id: 'all_genomes' ]
    //     tuple(meta, 'bins')
    // }
    GTDBTK_CLASSIFYWF(
        ch_binned_genomes,
        db_channel,
        false,       // use_pplacer_scratch_dir (optional)
        []           // mash_db optional empty
    )

    emit:
    summary = GTDBTK_CLASSIFYWF.out.summary
    tree    = GTDBTK_CLASSIFYWF.out.tree
    markers = GTDBTK_CLASSIFYWF.out.markers
    msa     = GTDBTK_CLASSIFYWF.out.msa
    user_msa = GTDBTK_CLASSIFYWF.out.user_msa
    filtered = GTDBTK_CLASSIFYWF.out.filtered
    failed  = GTDBTK_CLASSIFYWF.out.failed
    //log     = GTDBTK_CLASSIFYWF.out.log
    warnings = GTDBTK_CLASSIFYWF.out.warnings
    versions = GTDBTK_CLASSIFYWF.out.versions
}
