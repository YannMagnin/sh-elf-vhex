run_quietly() {
  out="$1"
  shift 1
  "$@" >$out 2>&1
  if [[ "$?" != 0 ]]; then
    echo "$TAG error: build failed, please check $(pwd)/$out o(x_x)o"
    exit 1
  fi
}
