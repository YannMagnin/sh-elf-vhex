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
  local _version

  _version=$(find "$1/" -maxdepth 1 -type d,l)
  _version=$(echo "$_version" | sort -r )
  _version=$(echo "$_version" | head -n 1)
  _version=$(basename "$_version")
  echo "$_version"
}

function utils_callcmd()
{
  if [[ "$VERBOSE" == '1' ]]
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

function utils_warn_callcmd()
{
  if [[ "$VERBOSE" == '1' ]]
    then
      echo "$@"
      if ! "$@"; then
        echo "$TAG warning: command failed, skipped"
        return 1
      fi
    return 0
  else
    out='shelfvhex_crash.txt'
    if ! "$@" >"$out" 2>&1; then
      echo "$TAG warning: command failed, please check $(pwd)/$out" >&2
      echo "$@" >&2
      return 1
    fi
    rm -f "$out"
    return 0
  fi
}

function utils_makecmd()
{
  local cores

  [[ "$(uname -s)" == 'OpenBSD' || "$(uname -s)" == 'Darwin' ]] \
      && cores=$(sysctl -n hw.ncpu) \
      || cores=$(nproc)
  [[ $(command -v gmake >/dev/null 2>&1) ]] \
      && make_cmd='gmake' \
      || make_cmd='make'
  utils_callcmd "$make_cmd" "-j$cores" "$@"
}

function utils_archive_download()
{
  pushd '.' > /dev/null || exit 1
  local url
  local output
  local cached
  local src

  url=$1
  output=$2
  cached=$3
  src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
  archive="$src/../_cache/$(basename "$url")"

  if [[ -d "$output/archive" ]]
  then
    echo "$TAG Archive found, skipping download"
    exit 0
  fi

  if ! test -f "$archive"
  then
    echo "$TAG Downloading $url..."
    mkdir -p "$(dirname "$archive")"
    if command -v curl >/dev/null 2>&1
    then
      curl "$url" -o "$archive"
    elif command -v wget >/dev/null 2>&1
    then
      wget -q --show-progress "$url" -O "$archive"
    else
      echo \
        "$TAG error: no curl or wget; install one or download " \
        "archive yourself at '$archive'" >&2
      exit 1
    fi
  fi

  echo "$TAG Extracting $archive..."

  mkdir -p "$output/archive" && cd "$output/archive" || exit 1
  unxz -c < "$archive" | tar --strip-components 1 -xf -

  if [[ "$cached" != 'true' ]]
  then
    echo "$TAG Removing $archive..."
    rm -f "$archive"
  fi

  popd > /dev/null || exit 1
}
