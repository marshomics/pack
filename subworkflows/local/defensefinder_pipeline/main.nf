include { DEFENSEFINDER_UPDATE   } from '../../../modules/local/defensefinder/update'
include { DEFENSEFINDER_RUN      } from '../../../modules/local/defensefinder/run'
include { GENOMECOLLECTOR        } from '../../local/utils_nfcore_pack_pipeline'

workflow DEFENSEFINDER_PIPELINE {

  take:
  genomes    // channel of paths (from input dir)
  user_models     // either path to models dir OR [] if not provided

  main:

  /*
   * 1) Format genomes for per-genome tools (wrapped mode)
   * Output: tuple(meta), path(fasta)
   */
  genomes_wrapped_ch = GENOMECOLLECTOR(genomes, 'wrapped').genomes_formatted_for_input

  /*
   * 2) Get models (user-provided OR download/update)
   * Output: path("models")
   */
  update_ch      = DEFENSEFINDER_UPDATE(user_models)
  models_dir_ch  = update_ch.models

  /*
   * 3) Run DefenseFinder per genome
   */
  run_ch = DEFENSEFINDER_RUN(genomes_wrapped_ch, models_dir_ch)

  emit:
  results        = run_ch.results
  df_versions    = run_ch.versions
  model_versions = update_ch.versions
  models_dir     = models_dir_ch
  genomes_wrapped = genomes_wrapped_ch
}
