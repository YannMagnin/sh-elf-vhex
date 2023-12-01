# module used to provide common variable / functions
# this file must not be manually invoked
#
# @note
# - workaround to trick the linter
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  verbose=$VHEX_VERBOSE
fi

#---
# Exposed vars
#---

# select the appropriate quiet primitive
quiet='utils_run_normaly'
[[ "$verbose" == "false" ]] && quiet='utils_run_quietly vxsdk-build.log'
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

function utils_run_normaly() {
  echo "$@"
  if ! "$@"; then
    echo "$TAG error: command failed, abord"
    exit 1
  fi
}

function utils_run_quietly() {
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

function utils_get_env() {
  if [ -v "$1" ]
  then
    echo 'error: are you sure to use the bootstrap script ?' >&2
    echo " Missing $2 information, abord" >&2
    exit 1
  fi
  echo "${!1/#\~/$HOME}"
}
