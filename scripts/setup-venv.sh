#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# our script root dir
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

root_path="$(readlink -f "${SCRIPT_DIR}/..")"
out_of_tree_install_path="${root_path}/install"
micromamba_install_path="${out_of_tree_install_path}/micromamba"
micromamba_version="1.5.6-0"
micromamba_version_main="${micromamba_version%-*}"
models_path="$root_path/models"
env_install_root_path="${out_of_tree_install_path}/env"
env_name="$(basename "$(pwd)")"
env_install_path="${env_install_root_path}/${env_name}"

export PATH="${env_install_path}/bin:${micromamba_install_path}/bin:${PATH}"

###################
# MICROMAMBA/CONDA

micromamba_version_matches_wanted_version() {
    if ! command -v micromamba >/dev/null; then
        return 1
    fi
    if [ "$(micromamba --version)" != "${micromamba_version_main}" ]; then
        return 1
    fi
    return 0
}
install_micromamba() {
    # check that tools required exist on the system PATH
    if ! command -v curl >/dev/null; then
        echo "ERROR: curl not in PATH, make sure you have curl installed." >&2
        exit 1
    fi
    if ! command -v tar >/dev/null; then
        echo "ERROR: tar not in PATH, make sure you have tar installed." >&2
        exit 1
    fi
    if ! command -v bzip2 >/dev/null; then
        echo "ERROR: bzip2 not in PATH, make sure you have bzip2 installed." >&2
        exit 1
    fi

    mkdir -p "${out_of_tree_install_path}"
    # local archive_url archive_signature_url
    local binary_url binary_signature_url
    case "$(uname -s).$(uname -m)" in
    Linux.x86_64)
        binary_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-64"
        binary_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-64.sha256"
        # archive_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-64.tar.bz2"
        # archive_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-64.tar.bz2.sha256"
        ;;
    Linux.aarch64)
        binary_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-aarch64"
        binary_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-aarch64.sha256"
        # archive_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-aarch64.tar.bz2"
        # archive_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-aarch64.tar.bz2.sha256"
        ;;
    Linux.ppc64le)
        binary_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-ppc64le"
        binary_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-ppc64le.sha256"
        # archive_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-ppc64le.tar.bz2"
        # archive_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-linux-ppc64le.tar.bz2.sha256"
        ;;
    Darwin.x86_64)
        binary_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-64"
        binary_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-64.sha256"
        # archive_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-64.tar.bz2"
        # archive_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-64.tar.bz2.sha256"
        ;;
    Darwin.arm*)
        binary_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-arm64"
        binary_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-arm64.sha256"
        # archive_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-arm64.tar.bz2"
        # archive_signature_url="https://github.com/mamba-org/micromamba-releases/releases/download/${micromamba_version}/micromamba-osx-arm64.tar.bz2.sha256"
        ;;
    *)
        echo "ERROR: Unsupported platform ($(uname -s) $(uname -m))." >&2
        ;;
    esac
    # echo "Downloading micromamba.tar.bz2..." >&2
    # curl -#fL -o "micromamba.tar.bz2" "$archive_url"
    # echo "Downloading micromamba.tar.bz2.sha256..." >&2
    # curl -#fL -o "micromamba.tar.bz2.sha256" "$archive_signature_url"
    echo "Downloading micromamba..." >&2
    curl -#fL -o "micromamba" "$binary_url"
    echo "Downloading micromamba.sha256..." >&2
    curl -#fL -o "micromamba.sha256" "$binary_signature_url"
    # hash=$(sha256sum "micromamba.tar.bz2" | awk '{print $1}' | head -n1)
    # expectedhash=$(cat "micromamba.tar.bz2.sha256" | awk '{print $1}' | head -n1)
    # if [ "$hash" != "$expectedhash" ]; then
    #     echo "ERROR: Downloaded micromamba archive failed signature check ($hash != $expectedhash)." >&2
    #     return 1
    # fi
    hash=$(sha256sum "micromamba" | awk '{print $1}' | head -n1)
    expectedhash=$(cat "micromamba.sha256" | awk '{print $1}' | head -n1)
    if [ "$hash" != "$expectedhash" ]; then
        echo "ERROR: Downloaded micromamba failed signature check ($hash != $expectedhash)." >&2
        return 1
    fi
    mkdir -p "${micromamba_install_path}/bin"
    # tar -xjf "micromamba.tar.bz2" -C "${micromamba_install_path}"
    # rm -f "micromamba.tar.bz2.sha256" "micromamba.tar.bz2"
    mv "micromamba" "${micromamba_install_path}/bin"
    chmod u+x "${micromamba_install_path}/bin/micromamba"
    rm -f "micromamba.sha256"
}
if ! micromamba_version_matches_wanted_version; then
    install_micromamba
fi
micromamba_install_packages=()

# set up env prefix
if [ ! -e "$env_install_path" ]; then
    micromamba create -y --prefix "$env_install_path" || (
        echo "ERROR: unable to create the install environment"
        exit 1
    )
fi

# check git
wanted_git_version="2.45.0"
git_is_at_expected_version() {
    local raw_version git_version
    if ! command -v git >/dev/null; then
        return 1
    fi
    raw_version=$(git --version)
    git_version="${raw_version#git version }"
    [ "$git_version" != "$wanted_git_version" ]
}
if ! git_is_at_expected_version; then
    echo "Going to install git $wanted_git_version" >&2
    micromamba_install_packages+=("git=$wanted_git_version")
fi

# check python3
# TODO - figure out most suitable python version for SD app
wanted_python_version="3.10.13"
python_is_at_expected_version() {
    local raw_version python_version
    if ! command -v python3 >/dev/null; then
        return 1
    fi
    raw_version=$(python3 --version)
    python_version="${raw_version#Python }"
    [ "$python_version" = "$wanted_python_version" ]
}
if ! python_is_at_expected_version; then
    echo "Going to install python $wanted_python_version" >&2
    micromamba_install_packages+=("python=$wanted_python_version")
fi

# check conda
wanted_conda_version="24.4.0"
conda_is_at_expected_version() {
    local raw_version conda_version
    if ! command -v conda >/dev/null; then
        return 1
    fi
    raw_version=$(conda --version)
    conda_version="${raw_version#conda }"
    [ "$conda_version" = "$wanted_conda_version" ]
}
if ! conda_is_at_expected_version; then
    echo "Going to install conda $wanted_conda_version" >&2
    micromamba_install_packages+=("conda=$wanted_conda_version")
fi

# check rust
# 1.74.0+ required by clap_derive v4.5.0
wanted_rust_version="1.74.0"
rust_is_at_expected_version() {
    local raw_version rust_version
    if ! command -v rustc >/dev/null; then
        return 1
    fi
    raw_version=$(rustc --version)
    rust_version="${raw_version#rustc }"
    rust_version="${rust_version%% *}"
    [ "$rust_version" = "$wanted_rust_version" ]
}
if ! rust_is_at_expected_version; then
    echo "Going to install rust $wanted_rust_version" >&2
    micromamba_install_packages+=("rust=$wanted_rust_version")
fi

# install missing dependencies
if [ "${#micromamba_install_packages[@]}" -gt 0 ]; then
    micromamba install -y --prefix "$env_install_path" -c conda-forge "${micromamba_install_packages[@]}" || (
        echo "ERROR: installation of packages via micromamba failed:" "${micromamba_install_packages[@]}" >&2
        exit 1
    )
fi

#eval $(micromamba shell hook --shell="$(basename $SHELL)")
#micromamba activate "$env_install_path"
export PYTHONNOUSERSITE=y
export PYTHONPATH=$(micromamba run --prefix "$env_install_path" python -c 'import site; print(":".join(site.getsitepackages()))')
echo "PYTHONPATH: $PYTHONPATH" >&2

# activate the installer env
CONDA_BASEPATH=$(conda info --base)
echo "CONDA_BASEPATH: $CONDA_BASEPATH" >&2
source "$CONDA_BASEPATH/etc/profile.d/conda.sh" # avoids the 'shell not initialized' error
conda activate

################
# SANITY CHECKS

# install dependencies
if [ -f requirements.txt ]; then
    # standard python requirements list
    requirements_txt=$(cat requirements.txt)
elif [ -f requirements_versions.txt ]; then
    # https://github.com/lllyasviel/stable-diffusion-webui-forge/commit/b57573c8da9e23fe8245f7dbb5e3f5e445aa65b2#diff-2284b86f286dc7e0ea4bd09a0ec20c78fbb17d6724d7f0053e78428d0715bbb1
    requirements_txt=$(cat requirements_versions.txt)
else
    echo "ERROR: No requirements.txt or requirements_versions.txt found." >&2
    exit 1
fi
override_requirement() {
    local name version_req requirements_txt_old
    name="$1"
    version_req="${2:-}"
    requirements_txt_old="$requirements_txt"
    if [ "$version_req" = "remove" ]; then
        echo "Removing requirement $name" >&2
        requirements_txt=$(grep -vE "^${name}\b" <<<"$requirements_txt")
    else
        if [ -z "$version_req" ]; then
            echo "Overriding requirement $name with latest compatible version" >&2
        else
            echo "Overriding requirement $name with version $version_req" >&2
        fi
        requirements_txt=$(
            grep -vE "^${name}\b" <<<"$requirements_txt"
            echo "$name$version_req"
        )
        fi
    if command -v diff >/dev/null; then
        diff -U0 <(echo "$requirements_txt_old") <(echo "$requirements_txt") || true
    fi
}
add_index() {
    requirements_txt=$(echo "$requirements_txt" && echo "--extra-index-url $1")
}
launch_args=(
    --skip-install
    # do not set this as it will skip cloning git repos that are hardcoded into the app
    #
    # stable_diffusion_repo = os.environ.get('STABLE_DIFFUSION_REPO', "https://github.com/Stability-AI/stablediffusion.git")
    # stable_diffusion_xl_repo = os.environ.get('STABLE_DIFFUSION_XL_REPO', "https://github.com/Stability-AI/generative-models.git")
    # k_diffusion_repo = os.environ.get('K_DIFFUSION_REPO', 'https://github.com/crowsonkb/k-diffusion.git')
    # codeformer_repo = os.environ.get('CODEFORMER_REPO', 'https://github.com/sczhou/CodeFormer.git')
    # blip_repo = os.environ.get('BLIP_REPO', 'https://github.com/salesforce/BLIP.git')
    #
    # stable_diffusion_commit_hash = os.environ.get('STABLE_DIFFUSION_COMMIT_HASH', "cf1d67a6fd5ea1aa600c4df58e5b47da45f6bdbf")
    # stable_diffusion_xl_commit_hash = os.environ.get('STABLE_DIFFUSION_XL_COMMIT_HASH', "45c443b316737a4ab6e40413d7794a7f5657c19f")
    # k_diffusion_commit_hash = os.environ.get('K_DIFFUSION_COMMIT_HASH', "ab527a9a6d347f364e3d185ba6d714e22d80cb3c")
    # codeformer_commit_hash = os.environ.get('CODEFORMER_COMMIT_HASH', "c5b4593074ba6214284d6acd5f1719b6c5d739af")
    # blip_commit_hash = os.environ.get('BLIP_COMMIT_HASH', "48211a1594f1321b00f14c9f7a5b4813144b2fb9")
    #
    #--skip-prepare-environment
    --no-half-vae
    --listen
    "$@"
)

# Load an up to date version of PCI IDs to compare GPUs against.
pci_ids_file=""
update_pci_ids() {
    pci_ids_url="https://pci-ids.ucw.cz/v2.2/pci.ids.bz2"
    echo "Downloading latest PCI ID database..." >&2
    mkdir -p "$out_of_tree_install_path"
    curl -#fL -o "$out_of_tree_install_path/pci.ids.bz2" "${pci_ids_url}"
    bzcat "$out_of_tree_install_path/pci.ids.bz2" > "$out_of_tree_install_path/pci.ids"
    rm -f "$out_of_tree_install_path/pci.ids.bz2"
}
lookup_pci_dev_name() {
    awk -v vendor="$1" -v device="$2" '
BEGIN { vendor_found = 0; device_found = 0; }
/^$/ { next; }
/^[0-9a-f]{4}  / {
  if ($1 == vendor) {
    vendor_found = 1;
    vendor_name = substr($0, index($0,$2));
  } else {
    vendor_found = 0;
  }
}
vendor_found && /^[[:space:]]+[0-9a-f]{4}  / {
  if ($1 == device) {
    device_found = 1;
    device_name = substr($0, index($0,$2));
    exit;
  }
}
END {
  if (device_found) {
    print vendor_name " - " device_name;
  }
}' "${pci_ids_file}"
}
for known_pci_ids_file in \
    /usr/share/hwdata/pci.ids \
    /usr/share/misc/pci.ids \
    ; do
    if [ -f "$known_pci_ids_file" ]; then
        for expected_desc in "Navi 1" "Navi 2" "Navi 3" "Renoir" "AMD" "NVIDIA" "Intel Arc"; do
            if ! grep -q "$expected_desc" "$known_pci_ids_file"; then
                break
            fi
        done
        if [ $? -eq 0 ]; then
            pci_ids_file="$known_pci_ids_file"
            break
        else
            echo "WARNING: PCI ID database $known_pci_ids_file does not contain $expected_desc IDs, relying on a more up to date one instead. Make sure your system is up to date." >&2
        fi
    fi
done
if [ -z "$pci_ids_file" ]; then
    pci_ids_file="$out_of_tree_install_path/pci.ids"
    if [ ! -f "$pci_ids_file" ] || [ $(( $(date '+%s') - $(stat -c %Y "pci.ids") )) -gt 864000 ]; then
        # last update was 10 days ago, an update shouldn't hurt now
        update_pci_ids
    fi
fi

# Check and modify prerequisites/env according to GPU.
i=0
used_major_gfx_card=""
while read -r devslot devid _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ driver _; do
    case "$driver" in
    nvidia|amdgpu|i915)
        # graphics driver
        ;;
    *)
        # not a graphics driver
        continue
        ;;
    esac
    vid=$(cut -c 1-4 <<<"$devid")
    did=$(cut -c 5-8 <<<"$devid")
    gpu_info=$(lookup_pci_dev_name "$vid" "$did")
    case "$gpu_info" in
        *"Navi 1"*)
            used_major_gfx_card="$gpu_info"
            export HIP_VISIBLE_DEVICES=$i
            export HSA_OVERRIDE_GFX_VERSION="10.3.0"
            export FORCE_FULL_PRECISION=yes
            override_requirement torch '==1.13.1+rocm5.2'
            override_requirement torchvision '==0.14.1+rocm5.2'
            override_requirement torchaudio '==0.13.1+rocm5.2'
            add_index 'https://download.pytorch.org/whl/rocm5.2'
            pip uninstall -y xformers
        ;;
        *"Navi 2"*)
            used_major_gfx_card="$gpu_info"
            export HIP_VISIBLE_DEVICES=$i
            export HSA_OVERRIDE_GFX_VERSION="10.3.0"
            override_requirement torch '==2.0.1+rocm5.4.2'
            override_requirement torchvision '==0.15.2+rocm5.4.2'
            override_requirement torchaudio '==2.0.1+rocm5.4.2'
            add_index 'https://download.pytorch.org/whl/rocm5.4.2'
            pip uninstall -y xformers
        ;;
        *"Navi 3"*)
            # Navi 3 needs at least 5.5
            used_major_gfx_card="$gpu_info"
            export HIP_VISIBLE_DEVICES=$i
            export HSA_OVERRIDE_GFX_VERSION="11.0.0"
            override_requirement torch '==2.3.0+rocm6.0'
            override_requirement torchvision '==0.18.0+rocm6.0'
            override_requirement torchaudio '==2.3.0+rocm6.0'
            add_index 'https://download.pytorch.org/whl/rocm6.0'
            pip uninstall -y xformers
        ;;
        *"Renoir"*)
            export HSA_OVERRIDE_GFX_VERSION="9.0.0"
            used_major_gfx_card="$gpu_info"
            override_requirement torch '==2.0.1+rocm5.4.2'
            override_requirement torchvision '==0.15.2+rocm5.4.2'
            override_requirement torchaudio '==2.0.1+rocm5.4.2'
            add_index 'https://download.pytorch.org/whl/rocm5.4.2'
            # printf "Experimental support for Renoir: make sure to have at least 4GB of VRAM and 10GB of RAM or enable cpu mode: --use-cpu all --no-half"
            pip uninstall -y xformers
        ;;
        *"AMD"*)
            if [ "$used_major_gfx_card" ]; then
                echo "Ignoring graphics card ($gpu_info) as we already have a major graphics card ($used_major_gfx_card)." >&2
                continue
            fi
            # all other AMD cards (e.g. integrated or non-consumer ones)
            override_requirement torch '==2.0.1+rocm5.4.2'
            override_requirement torchvision '==0.15.2+rocm5.4.2'
            override_requirement torchaudio '==2.0.2+rocm5.4.2'
            add_index 'https://download.pytorch.org/whl/rocm5.4.2'
            pip uninstall -y xformers
        ;;
        *"NVIDIA"*)
            launch_args+=(--xformers)
            # install xformers from pypi
            override_requirement xformers '==0.0.24'
        ;;
        *"Intel Arc"*)
            used_major_gfx_card="$gpu_info"
        ;;
        *)
            echo "GPU is probably not supported, ignoring: $gpu_info ($vid:$did) " >&2
        ;;
    esac
done < /proc/bus/pci/devices

echo "Major graphics card: $used_major_gfx_card" >&2
echo "Overrides:" >&2
env | grep -E '^(HSA_|HIP_|FORCE_FULL_PRECISION)' || true >&2

if [ -f launch.py ]; then
    # stable-diffusion-ui

    # replace outdated pytorch_lightning reference with pytorch-lightning
    override_requirement pytorch_lightning remove
    override_requirement pytorch-lightning '==1.9.5'

    # HACK - do not install clip from pypi as that's the wrong one
    override_requirement clip remove
    override_requirement 'git+https://github.com/openai/CLIP.git' '@a1d071733d7111c9c014f024669f959182114e33'

    # HACK - https://github.com/AUTOMATIC1111/stable-diffusion-webui/issues/11853
    override_requirement pydantic '==1.10.11'

    # HACK - missing dependency for repositories
    override_requirement gdown

    echo -e "Requirements:\n\n$requirements_txt\n\n" >&2
    pip install --upgrade-strategy only-if-needed -r <(echo "$requirements_txt")

    # replace models directory with symlink to our shared one
    if [ ! -L models ] && [ -d models ]; then
        rm -rf models
        ln -s "$models_path" models
    fi

    # gdb --args 
    TORCH_COMMAND="true" python -u launch.py "${launch_args[@]}"
elif [ -f main.py ]; then
    # comfyUI

    echo -e "Requirements:\n\n$requirements_txt\n\n" >&2
    pip install --upgrade-strategy only-if-needed -r <(echo "$requirements_txt")

    # set up search path
    #if [ ! -f extra_model_paths.yaml ]; then
    #    cp extra_model_paths.yaml.example extra_model_paths.yaml
    #fi
    cat >extra_model_paths.yaml <<EOF
#config for a1111 ui
#all you have to do is change the base_path to where yours is installed
a111:
    #base_path: path/to/stable-diffusion-webui/

    checkpoints: ${models_path}/stable-diffusion
    configs: ${models_path}/stable-diffusion
    vae: ${models_path}/vae
    loras: |
         ${models_path}/lore
         ${models_path}/lycoris
    upscale_models: |
                  ${models_path}/esrgan
                  ${models_path}/realesrgan
                  ${models_path}/swinir
    embeddings: ${models_path}/embeddings
    hypernetworks: ${models_path}/hypernetworks
    controlnet: ${models_path}/ControlNet

#config for comfyui
#your base path should be either an existing comfy install or a central folder where you store all of your models, loras, etc.

comfyui:
     base_path: ${root_path}
     checkpoints: models/stable-diffusion/
     clip: models/clip/
     clip_vision: models/clip_vision/
     configs: models/configs/
     controlnet: models/controlnet/
     embeddings: models/embeddings/
     loras: models/lora/
     upscale_models: models/upscale_models/
     vae: models/vae/

other_ui:
#    base_path: path/to/ui
    checkpoints: ${models_path}/stable-diffusion
#    gligen: models/gligen
#    custom_nodes: path/custom_nodes
EOF
    TORCH_COMMAND="true" python -u main.py "$@"
elif [ -f scripts/start.sh ]; then
    # easydiffusion
    
    echo "ERROR: Running easydiffusion is not supported yet. Use the AUR package or install directly." >&2
    exit 1
else
    echo "ERROR: Unable to detect stable-diffusion-ui or easydiffusion in this repository." >&2
    exit 1
fi
