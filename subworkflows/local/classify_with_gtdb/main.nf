// Subworkflow: CLASSIFY_WITH_GTDBTK

include { GTDBTK_CLASSIFYWF } from '../../../modules/nf-core/gtdbtk/classifywf'
include { GTDBDATABASEDOWNLOAD } from '../../../modules/local/gtdbdatabasedownload' // You must create this module

workflow CLASSIFY_WITH_GTDBTK {

    take:
    bins        // Channel: [meta, bin_path]
    db_path     // Path to GTDB database (optional)

    main:
    // Decide whether to download or use provided DB
    db_channel = db_path ? Channel.fromPath(db_path, checkIfExists: true) : GTDBDATABASEDOWNLOAD()

    // Merge bins into one directory for classify_wf
    bins.collectFile(name: "bins.tar.gz", storeDir: "bins")
        .ifEmpty { error "No genome bins found." }
        .unpack()
        .map { path ->
            def meta = [id: "all_bins"]
            tuple(meta, path)
        }
        .set { ch_bins }

    GTDBTK_CLASSIFYWF(
        ch_bins,
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
    log     = GTDBTK_CLASSIFYWF.out.log
    warnings = GTDBTK_CLASSIFYWF.out.warnings
    versions = GTDBTK_CLASSIFYWF.out.versions
}
