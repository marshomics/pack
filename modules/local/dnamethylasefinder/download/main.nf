process DNAMETHYLASEFINDER_DOWNLOAD {

    tag "dna_methylase_finder_db"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gnu-wget:1.18--h5bf99c6_5' :
        'biocontainers/gnu-wget:1.18--h5bf99c6_5' }"

    /*
     * Optional input (same pattern as DEFENSEFINDER_UPDATE):
     *  - If the workflow passes [] then user did not supply a DB -> download it
     *  - If it passes a directory, validate and use it
     */
    input:
    path user_db, stageAs: 'user_db'

    output:
    path "dna_methylase_finder_db", emit: db
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args   ?: ''
    // URL of the DB tarball on your GitHub release. Override in conf/modules.config via ext.args2.
    def db_url = task.ext.args2 ?: 'https://zenodo.org/record/6647341/files/DNA_methylase_finder_DBS_v1.0.tar.gz'
    // The six subdirectories every valid methylase DB must contain
    def expected = 'cdd_plus_hmms methylase_hmms motif_protein_blastp restriction_enzyme_hmms specificity_subunit_hmms subtype_hmms'
    """
    set -euo pipefail

    # Always emit a stable directory name for downstream modules
    mkdir -p dna_methylase_finder_db

    if [ -n "${user_db}" ] && [ "${user_db}" != "[]" ] && [ -e "${user_db}" ]; then
        echo "Using user-provided DNA methylase finder DB directory: ${user_db}"

        # Validate: every expected subfolder must be present
        for d in ${expected}; do
            if [ ! -d "${user_db}/\$d" ]; then
                echo "ERROR: Provided DB directory does not look like a DNA_methylase_finder DB."
                echo "Missing expected subfolder: \$d"
                echo "Got:"
                ls -la "${user_db}" || true
                exit 1
            fi
        done

        # Copy each expected subfolder into the stable output dir
        for d in ${expected}; do
            cp -R "${user_db}/\$d" dna_methylase_finder_db/
        done

    else
        echo "No user DB provided -> downloading from GitHub release"

        wget ${args} -O DNA_methylase_finder_DBS.tar.gz "${db_url}"

        # Tarball has NO top-level wrapper folder: the six dirs sit at the archive root.
        # Extract straight into dna_methylase_finder_db/
        tar -xzf DNA_methylase_finder_DBS.tar.gz -C dna_methylase_finder_db
        rm DNA_methylase_finder_DBS.tar.gz

        # Sanity check the extraction
        for d in ${expected}; do
            if [ ! -d "dna_methylase_finder_db/\$d" ]; then
                echo "ERROR: Download extracted but expected subfolder missing: \$d"
                ls -la dna_methylase_finder_db || true
                exit 1
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(wget --version | head -n1 | sed 's/GNU Wget //; s/ .*//')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p dna_methylase_finder_db/cdd_plus_hmms dna_methylase_finder_db/methylase_hmms dna_methylase_finder_db/motif_protein_blastp
    mkdir -p dna_methylase_finder_db/restriction_enzyme_hmms dna_methylase_finder_db/specificity_subunit_hmms dna_methylase_finder_db/subtype_hmms
    touch dna_methylase_finder_db/.stub_db

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: "stub"
    END_VERSIONS
    """
}