include { DNAMETHYLASEFINDER_DOWNLOAD } from '../../../modules/local/dnamethylasefinder/download'
// include { DNAMETHYLASEFINDER_RUN      } from '../../../modules/local/dnamethylasefinder/run'
// include { GENOMECOLLECTOR             } from '../../local/utils_nfcore_pack_pipeline'

workflow DNAMETHYLASEFINDER_PIPELINE {

  take:
  // genomes   // channel of paths (from input dir) -- uncomment when adding RUN
  user_db      // either path to an extracted DB dir OR [] if not provided

  main:

  /*
   * 1) Get the database (user-provided OR download from GitHub release)
   * Output: path("dna_methylase_finder_db")
   */
  download_ch = DNAMETHYLASEFINDER_DOWNLOAD(user_db)
  db_dir_ch   = download_ch.db

  /*
   * 2) Run DNA methylase finder per genome  -- TODO: add later
   *
   * genomes_wrapped_ch = GENOMECOLLECTOR(genomes, 'wrapped').genomes_formatted_for_input
   * run_ch = DNAMETHYLASEFINDER_RUN(genomes_wrapped_ch, db_dir_ch)
   */

  emit:
  db_dir      = db_dir_ch
  db_versions = download_ch.versions
  // results     = run_ch.results        // TODO: uncomment when RUN is added
  // run_versions = run_ch.versions       // TODO: uncomment when RUN is added
}