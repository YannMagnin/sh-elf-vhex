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

function utils_archive_download()
{
  url=$1
  output=$2
  cached=$3
  archive="/tmp/sh-elf-vhex/$(basename "$url")"

  if [[ -d "$output/archive" ]]
  then
    echo "$TAG Found archive, skipping download"
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

  mkdir -p "$output/archive" && pushd "$output/archive" > /dev/null || exit 1
  unxz -c < "$archive" | tar --strip-components 1 -xf -
  popd > /dev/null || exit 1

  if [[ "$cached" != 'true' ]]
  then
    echo "$TAG Removing $archive..."
    rm -f "$archive"
  fi
}
