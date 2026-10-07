#!/usr/bin/env bash
# WSL launcher for the Windows IPhreeqcCOM workflows in this checkout.
# Usage: bash run_matlab_h2sim.sh "results = profilePhreeqcWorkflows;"
# Override MATLAB_BIN to select another Windows MATLAB installation.
set -euo pipefail
if [[ $# -ne 1 || "$1" == --help ]]; then
    echo 'Usage: bash run_matlab_h2sim.sh "MATLAB statements"'
    [[ $# -eq 1 && "$1" == --help ]] && exit 0
    exit 2
fi
h2sim_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
matlab_executable="${MATLAB_BIN:-/mnt/c/Program Files/MATLAB/R2026a/bin/matlab.exe}"
if [[ ! -x "$matlab_executable" ]]; then
    echo "Windows MATLAB not found: $matlab_executable. Set MATLAB_BIN to its WSL path." >&2
    exit 1
fi
matlab_root="$(wslpath -w "$h2sim_root")"
matlab_root="${matlab_root//\'/\'\'}"
# Initialize this checkout from MATLAB's standard path, avoiding other MRST
# installations and Octave shims left on the user's saved MATLAB path.
exec "$matlab_executable" -batch "cd(tempdir); restoredefaultpath; cd('$matlab_root'); startupH2sim; $1"
