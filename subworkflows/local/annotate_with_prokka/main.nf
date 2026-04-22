// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { PROKKA          } from '../../../modules/nf-core/prokka'
include { GENOMECOLLECTOR } from '../../local/utils_nfcore_pack_pipeline'

/*
========================================================================================
  ANNOTATE_WITH_PROKKA
  - Subworkflow to run genome annotation using Prokka
  - Takes individual genome FASTA files with metadata (wrapped_genomes)
  - Optionally accepts:
      - a protein FASTA file to use for annotation (--proteins)
      - a Prodigal translation table file (--prodigaltf)
  - Emits selected Prokka output files and version information
========================================================================================
*/

workflow ANNOTATE_WITH_PROKKA {

    take:
    genomes  // Channel of tuples: [meta, fasta] → one per genome
    proteins         // Optional protein FASTA (for reference annotation)
    prodigal_tf      // Optional Prodigal translation table

    main:
    // Run the PROKKA module with all provided inputs

    // STEP 2: Collect all genome files into one merged list with shared metadata
    GENOMECOLLECTOR(genomes,"wrapped")
    //GENOMECOLLECTOR.out.genomes_formatted_for_input.view()
    PROKKA(
        GENOMECOLLECTOR.out.genomes_formatted_for_input,
        proteins,
        prodigal_tf
    )

    emit:
    gff      = PROKKA.out.gff       // GFF annotation files
    gbk      = PROKKA.out.gbk       // GenBank format files
    faa      = PROKKA.out.faa       // Predicted proteins
    versions = PROKKA.out.versions  // Software version tracking
}
