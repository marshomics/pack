process DEFENSEFINDER_UPDATE {

    tag "defensefinder_models"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/defense-finder:2.0.1--pyhdfd78af_0' :
        'quay.io/biocontainers/defense-finder:2.0.1--pyhdfd78af_0' }"

    /*
     * Optional input:
     *  - If the workflow passes [] then user did not supply models
     *  - If it passes a directory, we use it
     *
     * This is the nf-core workaround for "optional inputs".
     */
    input:
    // ✅ If not provided, pass [] from workflow (see below)
    // ✅ If provided, it will be staged as ./user_models (no name collision with output)
    path user_models, stageAs: 'user_models'

    output:
    path "models"      , emit: models
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    set -euo pipefail

    # Ensure DefenseFinder/macsydata can write user files
    export HOME="\$PWD"

    # Always emit a stable directory name for downstream modules
    mkdir -p models

    if [ -n "${user_models}" ] && [ "${user_models}" != "[]" ] && [ -e "${user_models}" ]; then
        echo "Using user-provided DefenseFinder models directory: ${user_models}"

        # Basic validation: check for the two expected folders you observed
        if [ ! -d "${user_models}/CasFinder" ] || [ ! -d "${user_models}/defense-finder-models" ]; then
            echo "ERROR: Provided models directory does not look like a DefenseFinder models dir."
            echo "Expected subfolders: CasFinder and defense-finder-models"
            echo "Got:"
            ls -la "${user_models}" || true
            exit 1
        fi

        # Copy into workdir so Nextflow can cache and publish reliably.
        # (Symlinks can be ok too, but copy is the safest across filesystems.)
        cp -R "${user_models}/CasFinder" models/
        cp -R "${user_models}/defense-finder-models" models/

    else
        echo "No user models provided -> installing pinned models with macsydata"
        mkdir -p models_tmp

        # defense-finder update \\
        #     ${args} \\
        #     --models-dir models_tmp

        # Install versions compatible with DefenseFinder 2.0.1
        macsydata install --target models_tmp  --org mdmparis defense-finder-models==2.0.2
        macsydata install --target models_tmp CasFinder==3.1.0

        # Normalize to output name
        rm -rf models
        mv models_tmp models
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        defense-finder: "\$(defense-finder --version 2>&1 | head -n 1)"
    END_VERSIONS
    """
    stub:
    """
    mkdir -p models/CasFinder
    mkdir -p models/defense-finder-models
    touch models/.stub_models

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        defense-finder: "stub"
    END_VERSIONS
    """
}
