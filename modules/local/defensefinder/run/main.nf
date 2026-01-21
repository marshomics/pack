process DEFENSEFINDER_RUN {

    tag { meta.id ?: fasta.baseName }
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/defense-finder:2.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/defense-finder:2.0.1--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    // models produced by DEFENSEFINDER_UPDATE (or user-provided dir that you normalized to "models")
    path models_dir

    output:
    tuple val(meta), path("defense_finder"), emit: results
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    // If input fasta is in a read-only location, macsyfinder may need index files elsewhere.
    // Putting them in workdir is safe; we pass --index-dir.
    """
    set -euo pipefail
    export HOME="$PWD"
    mkdir -p defense_finder
    mkdir -p macsy_index

    echo "Running DefenseFinder on: ${fasta}"
    echo "Using models dir: ${models_dir}"

    # Basic validation (optional but helpful for clearer error messages)
    if [ ! -d "${models_dir}" ]; then
        echo "ERROR: models_dir not found: ${models_dir}"
        exit 1
    fi

    defense-finder run \\
        ${args} \\
        --models-dir "${models_dir}" \\
        --index-dir macsy_index \\
        -o defense_finder \\
        "${fasta}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        defense-finder: "\$(defense-finder --version 2>&1 | head -n 1)"
    END_VERSIONS
    """

    stub:
    """
    mkdir -p defense_finder
    touch defense_finder/defense_finder_systems.tsv
    touch defense_finder/defense_finder_genes.tsv
    touch defense_finder/defense_finder_hmmer.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        defense-finder: "stub"
    END_VERSIONS
    """
}
