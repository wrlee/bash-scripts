## Dedup paths for the specified pathname. Source this file:
##
##  $0 [pathvarname]
##
## where:
##  pathvarname is the name of the path variable to dedup paths; default PATH
##
_dedupPath() {
  local _pathname=${1##/*}
  _pathname=${_pathname:-PATH}
  local IFS=:
  local _path=(${!_pathname})
  unset IFS
  local idx=(${!_path[@]})

  for i in ${!_path[@]}; do
    if [ -n "${_path[$i]}" ]; then
      for j in ${idx[@]:(($i+1))}; do
        [ "${_path[$i]}" = "${_path[$j]}" ] && unset _path[$j]
      done
    fi
  done
  IFS=:
  export ${_pathname}="${_path[*]}"
}
_dedupPath "$@"
unset -f _dedupPath