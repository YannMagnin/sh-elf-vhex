# module used to provide common variable / functions

## workaround to trick the linter
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  verbose=false
fi

#---
# Exposed vars
#---

# select the appropriate quiet primitive
quiet='run_normaly'
[[ "$verbose" == "false" ]] && quiet='run_quietly vxsdk-build.log'
export quiet

# Number of processor cores
[[ $(uname) == "OpenBSD" ]] && cores=$(sysctl -n hw.ncpu) || cores=$(nproc)
export cores

# Select make utility
make_cmd='make'
[[ $(command -v gmake >/dev/null 2>&1) ]] && make_cmd='gmake'
export make_cmd

#---
# Functions provided
#---

function run_normaly() {
  echo "$@"
  if ! "$@"; then
    echo "$TAG error: command failed, abord"
    exit 1
  fi
}

function run_quietly() {
  out="$1"
  shift 1
  if ! "$@" >"$out" 2>&1; then
    >&2 echo "$TAG error: command failed, please check $(pwd)/$out o(x_x)o"
    >&2 echo "$@"
    exit 1
  fi
  rm -f "$out"
}

function utils_find_last_version() {
  _version=$(find "$1/" -maxdepth 1 -type d,l)
  _version=$(echo "$_version" | sort -r )
  _version=$(echo "$_version" | head -n 1)
  _version=$(basename "$_version")
  echo "$_version"
}

function get_sysroot() {
  if [ -z "${VHEX_PREFIX_SYSROOT}" ]; then
    echo 'error: are you sure to use the bootstrap script ?' >&2
    echo ' Missing sysroot information, abord' >&2
    exit 1
  fi
  SYSROOT="${VHEX_PREFIX_SYSROOT/#\~/$HOME}"
  mkdir -p "$SYSROOT"
  echo "SYSROOT"
}
