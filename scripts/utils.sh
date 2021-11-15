
# select the appropriate quiet primitive
quiet='run_normaly'
[[ "$verbose" == "false" ]] && quiet='run_quietly giteapc-build.log'

# Number of processor cores
[[ $(uname) == "OpenBSD" ]] && cores=$(sysctl -n hw.ncpu) || cores=$(nproc)

# selecte make utility
[[ $(command -v gmake >/dev/null 2>&1) ]] && make_cmd=gmake || make_cmd=make

## functions privided

run_normaly() {
  bash -c "$@"
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
    echo "$TAG error: command failed, please check $(pwd)/$out o(x_x)o"
    exit 1
  fi
}
