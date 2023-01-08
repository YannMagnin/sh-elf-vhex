# module used to provide common variable / functions

# select the appropriate quiet primitive
quiet='run_normaly'
[[ "$verbose" == "false" ]] && quiet='run_quietly vxsdk-build.log'

# Number of processor cores
[[ $(uname) == "OpenBSD" ]] && cores=$(sysctl -n hw.ncpu) || cores=$(nproc)

# Selecte make utility
[[ $(command -v gmake >/dev/null 2>&1) ]] && make_cmd=gmake || make_cmd=make

#
# Functions privided
#

run_normaly() {
  echo "$@"
  "$@"
  if [[ "$?" != 0 ]]; then
    echo "$TAG error: command failed, abord"
    exit 1
  fi
}

run_quietly() {
  out="$1"
  shift 1
  "$@" >$out 2>&1
  if [[ "$?" != 0 ]]; then
    >&2 echo "$TAG error: command failed, please check $(pwd)/$out o(x_x)o"
    >&2 echo "$@"
    exit 1
  fi
  rm -f "$out"
}

get_sysroot() {
  if [ -z $VXSDK_PREFIX_SYSROOT ]; then
    >2& echo "error: are you sure to use the vxSDK ?"
    >2& echo " Missing sysroot information, abord"
    exit 1
  fi
  SYSROOT="${VXSDK_PREFIX_SYSROOT/#\~/$HOME}"
  mkdir -p "$SYSROOT"
  echo "$SYSROOT"
}
