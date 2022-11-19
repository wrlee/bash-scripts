## fswatch -0 -e '.git' `pwd`|xargs -0 -I {} fswatch_cmd.sh {}
##
## Requires:
## - macOS/Darwin: fswatch (HomeBrew)
## - Linux: inotify-tools (apt)
## - Cygwin: inotify-win (github)
##
## TODO: Process file deletions
## TODO: Filter directory removals
## TODO: Support multiple file patterns
## TODO: Add -d, -u options to specify command to execute (all cases, delete, update)
## TODO: Consider using fswatch, only, since it was designed to be an OS-independent abstraction. https://github.com/emcrisostomo/fswatch
## WIP: -c for command

_help() {
  cat <<HELP
  $0 [options]

  This invokes fswatch to monitor file changes in the current directory tree.

  -f is the file pattern, e.g., "*.rb" to watch only Ruby files.
  -t is the target, e.g., clouddesk:workplace/project, the root of the target.
HELP
  exit
}

# echo "CLI: "; for i in "$@"; do echo "   '$i'"; done; fi
# echo "CLI($#): $@"

_CMD=cmdScp

while getopts ":hc:f:t:v" OPTNAME "$@"; do
  # [ -n "$verbose" ] && echo OPTNAME=$OPTNAME OPTARG=$OPTARG OPTIND=$OPTIND
  case "$OPTNAME" in
    f) patterns=${patterns}${patterns:+|}$OPTARG
     ;;
    c) _CMD=$OPTARG ;;
    t) target=$OPTARG ;;
    v) verbose=1 ;;
    h) _help ;;
    \?)  ## Invalid option
      if [ -n "$OPTARG" -a "$OPTARG" != '?' ]; then
        echo -e "${t_red}Unexpected option -$OPTARG${t_reset}".
        exit
      else
        _help
      fi
      ;;
    *) ## Unhandled, "valid" option
      echo -e "${t_red}Unprocessed option -$OPTNAME${t_reset}".
      ;;
  esac
done
shift $(($OPTIND-1))

## Copy file path to corresponding path under target
##
## @param $file
## @param $target
cmdScp() {
  local tpath=$(dirname "$file")
  [ -n "$tpath" ] && tpath="/$tpath"
  echo "$(date '+%H:%M:%S') $file —>${target}${tpath}"
  scp -r $file "${target}${tpath}"
}

## Linux case: watch or handle watch triggers
linux() {
  # echo $0: $# "$@"
  if [ $# -eq 0 ]; then
    if ! type inotifywait >/dev/null; then
      echo "'inotifywait' is not available. Need to install 'inotifytools'"
      return 1
    fi
    echo Watching `pwd -P`...
    [ -n "$verbose" ] && local verbose=${verbose:+-v}
    [ -n "$patterns" ] && local patterns=(${patterns:+-f} "${patterns}")
    [ -n "$target" ] && local target=(${target:+-t} "${target}")
    [ -n "$_CMD" ] && local cmd=(${_CMD:+-c} "${_CMD}")
    # echo "inotifywait -mqr --exclude '.*\.swp' --format='%w%f :%e' $(pwd) TO xargs -I '{}' $0 "${verbose}" "${patterns[@]}" "${target[@]}" "${cmd[@]}" {}"
    inotifywait -mqr --exclude '.*\.swp' --exclude '.*\.git' --exclude '^(env|build|json|coverage|node_modules|logs|release-info)$' --format='%w%f :%e' `pwd`|xargs -I '{}' $0 $verbose "${patterns[@]}" "${target[@]}" "${cmd[@]}" {}

  elif [ -n "$_CMD" -a "$_CMD" != "cmdScp" ]; then
    local event=${@##* :}
    local file="${@%% :*}"
    file="${file##$(pwd -P)/}"

    [ -z "$patterns" ] && local patterns='*'
    ## filename wildcards for regex wildcards
    local patterns="${patterns//\./\\.}"
    patterns="${patterns//\?/.}"
    patterns="${patterns//\*/.*}"
    patterns="${patterns//\|/$|}\$"

    case " ${event//,/ } " in
    *" ISDIR "*)
      [ -n "$verbose" ] && echo "$(date '+%H:%M:%S') Ignore dir $file $event"
      true;
      ;;
    *" CREATE "*|*" MODIFY "*)
      if [[ "$file" =~ $patterns ]]; then
        echo "$(date '+%H:%M:%S') Update $file $event"
        ${_CMD}
      else
        [ -n "$verbose" ] && echo "$(date '+%H:%M:%S') Filter $file $event"
      fi
      ;;
    *)
      [ -n "$verbose" ] && echo "$(date '+%H:%M:%S') Ignore event $event $file"
    esac

  elif [ -n "$target" -o -r `pwd`/.remote-sync.json ]; then
    if [ -z "$target" ]; then
      target="clouddesk:"
      target+=`sed -E '/"target":/!d; s/^ *"target":[^"]*"([^"]*)".*/\1/' $(pwd)/.remote-sync.json`
    fi
    [ -z "$patterns" ] && patterns="*"

    local event=${@##* :}
    local file=${@%% :*}
    file="${file##$(pwd -P)/}"
    # echo $event
    case "$event" in
      *ISDIR)
        echo "$(date '+%H:%M:%S') Ignore directory $file (no action)"
        ;;
      *MOVED_FROM|DELETE*)
        echo "$(date '+%H:%M:%S') Deleted $file $event (no action)"
        ;;
      *MODIFY|MOVED_TO|CREATE*)
        case "$file" in
        .git/*|*.sw[xp]|*~)
          echo "Ignore $file $event"
          ;;
        $patterns)
          $_CMD
          ;;
        esac
        ;;
      *)
        echo "$(date '+%H:%M:%S') unexpected $file, $event"
        ;;
    esac
  fi
}

darwin() {
  if [ $# -eq 0 ]; then
    if ! type fswatch >/dev/null; then
      echo "'fswatch' is not available. Need to install via Brew"
      return 1
    fi
    echo Watching `pwd -P`...
    [ -n "$verbose" ] && local verbose=${verbose:+-v}
    [ -n "$patterns" ] && local patterns=(${patterns:+-f} "${patterns}")
    [ -n "$target" ] && local target=(${target:+-t} "${target}")
    [ -n "$_CMD" ] && local cmd=(${_CMD:+-c} "${_CMD}")
    # --event Created Updated Renamed (MovedFrom) MovedTo IsFile (IsSymLink) (Link) --event 2+4+16+(128)+256+512+(2048)+(4096)
    fswatch -0 -e '/\.git' -Ee '/(env|build|coverage|node_modules|logs|release-info)/' `pwd` |xargs -0 -I {} $SHELL $0 $verbose "${patterns[@]}" "${target[@]}" "${cmd[@]}" {}
    exit

  elif [ -n "$_CMD" -a "$_CMD" != "cmdScp" ]; then
    local file="${@}"
    # file="${file##$(pwd -P)/}"

    [ -z "$patterns" ] && local patterns='*'
    ## filename wildcards for regex wildcards
    local patterns="${patterns//\./\\.}"
    patterns="${patterns//\?/.}"
    patterns="${patterns//\*/.*}"
    patterns="${patterns//\|/$|}\$"

    if [ -d "$file" ]; then
      [ -n "$verbose" ] && echo "$(date '+%H:%M:%S') Ignore dir $file"
    elif [ ! -e "$file" ]; then
      # [ -n "$verbose" ] && \
      echo "$(date '+%H:%M:%S') Missing $file"
    elif [[ "$file" =~ $patterns ]]; then
      echo "$(date '+%H:%M:%S') Update $file"
      ${_CMD}
    else
      [ -n "$verbose" ] && echo "$(date '+%H:%M:%S') Filter $file"
    fi

  elif [ -n "$target" -o -r `pwd`/.remote-sync.json ]; then
    if [ -z "$target" ]; then
      target="clouddesk:"
      target+=`sed -E '/"target":/!d; s/^ *"target":[^"]*"([^"]*)".*/\1/' $(pwd)/.remote-sync.json`
    fi
    [ -z "$patterns" ] && local patterns="*"

    local file="$@"
    file="${file##$(pwd -P)/}"
    case "$file" in
    coverage/*|.git/*|*.sw[xp]|*~|*/.DS_Store|.DS_Store)
      echo "$(date '+%H:%M:%S') Ignore $file"
      ;;
    $patterns)
      if [ -e "$file" ]; then
        $_CMD
      else
        echo "Deleted $file"
      fi
      ;;
    esac
  fi
}

case "$OSTYPE" in
  linux*)
    linux "$@"
    ;;
  darwin*)
    darwin "$@"
    ;;
  *)
    echo FS monitoring not supported under $OSTYPE
    ;;
esac
unset _CMD
