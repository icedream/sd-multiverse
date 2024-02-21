# Stable Diffusion Multiverse

A private project of mine to try and find a common way to launch any version or
fork of Stable Diffusion and their web interfaces. All the steps are basically
trimmed down to switching into the app directory and running a single launch
script.

## Requirements

Since this script is made to be as quick and common of an entrypoint as possible
you only need basic tools. I recommend whatever version of them your operating
system's package manager serves you with.

- micromamba or curl+tar+bzip2 (which will download micromamba for you)
- lspci from pciutils (to detect GPU)

Also make sure to install any requirements needed by the python app you want to
run itself (usually includes correct GPU drivers and some additional files to
generate anything with).

Debian/Ubuntu: `apt install --no-install-recommends -y ca-certificates git tar bzip2 pciutils curl`

## How to use

1.  (optional:) Clone/download your own version or fork of SD-UI that you want to
    use. You can skip this if you want to use one of the [tested apps](#tested-apps).
2.  Clone this repository via `git clone https://github.com/icedream/sd-multiverse.git`.
    You do *not* need to use `--recursive` if that's something you do by default.
3.  Run `./run.sh <path to your app>` in your terminal.

## Tested apps

This repository includes some git submodules that point to known to work
versions of stable-diffusion-ui. If you use the run script they will be
automatically checked out when you run the app for the first time and haven't
done so yet yourself.

You can tell `run.sh` to use these known app versions:

- for AUTOMATIC1111's stable-diffusion-webui: `./run.sh apps/AUTOMATIC1111/stable-diffusion-webui`
- for Illyasviel's stable-diffusion-webui-forge: `./run.sh apps/Illyasviel/stable-diffusion-webui-forge`
- for lshqqytiger's stable-diffusion-webui-directml: `./run.sh apps/lshqqytiger/stable-diffusion-webui-directml`
- for easydiffusion: `./run.sh apps/easydiffusion/easydiffusion`

## What happens behind the scenes

1.  `run.sh` checks whether the app you passed is a submodule of this repo. If
    it is, it will automatically run a submodule checkout on it.
2.  `run.sh` then invokes `scripts/setup-venv.sh` with the app path as the working directory.
3.  `setup-venv.sh` does some basic sanity checks and then installs needed
    native dependencies via micromamba. It will set up the environment in the
    `install` directory, and each app gets its own isolated environment.
4.  `setup-venv.sh` checks the `requirements.txt` of the app and modifies it
    if needed to make better or any use of GPU features. That includes installing xformers or other versions of torch/torchvision.
5.  `setup-venv.sh` also modifies the environment variables for the app, once
    again to make sure it runs properly on your GPU.
6.  `setup-env.sh` runs pip with the modified requirements to install them.
7.  `setup-env.sh` runs your app.
