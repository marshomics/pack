// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A subworkflow SHOULD import at least two modules

include { PRODIGAL           } from '../../../modules/nf-core/prodigal'
include { GENOMECOLLECTOR    } from '../../local/utils_nfcore_pack_pipeline'
/*
 * Subworkflow: RUN_PRODIGAL
 *
 * Purpose:
 *   Run the PRODIGAL module for gene prediction on input genomes.
 *
 * Inputs:
 *   - genomes:        Channel emitting tuple(meta, genome_fasta)
 *   - output_format:  Value specifying Prodigal output format (e.g. 'gff', 'gbk')
 *
 * Outputs:
 *   - gene annotations (GFF/GBK)
 *   - nucleotide FASTA (.fna)
 *   - amino acid FASTA (.faa)
 *   - full gene annotation table
 *   - versions.yml for provenance
 */

workflow RUN_PRODIGAL {

    /*
     * Inputs coming from the main workflow (or another subworkflow)
     * No params.* should be used here
     */
    take:
    genomes          // tuple: [ meta, genome ]
    output_format    // string: prodigal output format

    /*
     * Main execution block
     * Calls the PRODIGAL module once per genome
     */
    main:

    GENOMECOLLECTOR(genomes,"wrapped")

    PRODIGAL(
        GENOMECOLLECTOR.out.genomes_formatted_for_input,
        output_format
    )

    /*
     * Named outputs exposed to the calling workflow
     * These are accessed as RUN_PRODIGAL.out.<name>
     */
    emit:
    gene_annotations      = PRODIGAL.out.gene_annotations
    nucleotide_fasta      = PRODIGAL.out.nucleotide_fasta
    amino_acid_fasta      = PRODIGAL.out.amino_acid_fasta
    all_gene_annotations  = PRODIGAL.out.all_gene_annotations
    versions              = PRODIGAL.out.versions
}
