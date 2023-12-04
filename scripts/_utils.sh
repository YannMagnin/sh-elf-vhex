# module used to provide common variables / functions
# this file must not be manually invoked

#---
# Internals
#---

# workaround used to self-kill the current process if an error is detected
# in function
trap 'exit 1' TERM
export TOP_PID=$$

#---
# Public
#---

export TAG='<sh-elf-vhex>'

function utils_find_last_version()
{
  _version=$(find "$1/" -maxdepth 1 -type d,l)
  _version=$(echo "$_version" | sort -r )
  _version=$(echo "$_version" | head -n 1)
  _version=$(basename "$_version")
  echo "$_version"
}

function utils_callcmd()
{
  if [[ -v 'VERBOSE' && "$VERBOSE" == '1' ]]
    then
      echo "$@"
      if ! "$@"; then
        echo "$TAG error: command failed, abort"
        kill -s TERM $TOP_PID
      fi
  else
    out='shelfvhex_crash.txt'
    if ! "$@" >"$out" 2>&1; then
      echo "$TAG error: command failed, please check $(pwd)/$out o(x_x)o" >&2
      echo "$@" >&2
      kill -s TERM $TOP_PID
    fi
    rm -f "$out"
  fi
}

function utils_makecmd()
{
  [[ $(uname) == "OpenBSD" ]] \
      && cores=$(sysctl -n hw.ncpu) \
      || cores=$(nproc)
  [[ $(command -v gmake >/dev/null 2>&1) ]] \
      && make_cmd='gmake' \
      || make_cmd='make'
  utils_callcmd "$make_cmd" "-j$cores" "$@"
}
