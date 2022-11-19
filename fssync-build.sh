
## Delay between change detection and build (to allow more than one change to be submitted)
OMIT_DIRS=( ./json ./build ./coverage ./node_modules ./dist )
BUILD_FILES=( "*.jinja" "*.py" "*.java" "*.y*ml" "*.[tj]s*" SAMToolkit.devenv )
OMIT_FILES=( package-lock.json )
DELAY=3

while getopts ":d:h" OPTNAME "$@"; do
#	echo OPTNAME=$OPTNAME OPTARG=$OPTARG OPTIND=$OPTIND
	case "$OPTNAME" in
    d) DELAY=$OPTARG
			;;
		\?)	## Invalid option
			if [ -n "$OPTARG" -a "$OPTARG" != '?' ]; then
				echo -e "${t_red}Unexpected option -$OPTARG${t_reset}"
			 	exit
			fi
			;;
	  *) ## Unhandled, "valid" option
		 	echo -e "${t_red}Unprocessed option -$OPTNAME${t_reset}"
#		 	break
		 	;;
	esac
done
shift $(($OPTIND-1))

## build_find_list arr_name find_option list...
build_find_list() {
  # local -n list=$1 <--bash-4.3+: `-n` allows nameref rather than eval $list
  local list=$1
  local opt=$2
  shift 2
  eval $list'=( $opt "$1" )'
  if [ ${#} -gt 1 ]; then
    for i in "${@:2}"; do
      eval $list'+=( -o $opt "$i" )'
    done
  fi
}
## Build find expression of dir and file sets: -path ... -o -path ...
build_find_list omit_dirs -path "${OMIT_DIRS[@]}"
# echo ${#omit_dirs} ${omit_dirs[@]}
build_find_list build_files -name "${BUILD_FILES[@]}"
build_find_list omit_files -name "${OMIT_FILES[@]}"

## File used to "hold" date to compare "changed" files' dates against (via find command)
tag=/tmp/`basename $PWD`.watchtag
if [ ! -e "$tag" ]; then
  echo create new $tag file
  touch "$tag"
fi
echo find . \( "${omit_dirs[@]}" \) -prune -false -o -type f \( "${build_files[@]}" \) -a ! \( "${omit_files[@]}" \) -newer $tag
while sleep 1; do
  # if [ -n "$(find . -not -path "./node_modules/*" -type f \( -name "*.ts*" -o -name "*.py" -o -name SAMToolkit.devenv -o -name "*.yml" -o \( -name "*.json" -a ! -name "package-lock.json" \) \) -newer /tmp/$(basename "$PWD"))" ]; then
  # if [ -n "$(find . \( -path ./json -o -path ./build -o -path ./coverage -o -path ./node_modules \) -prune -false -o -type f \( -name "*.jinja" -o \( -name "*.[tj]s*" -a ! -name package-lock.json \) -o -name "*.py" -o -name "*.java" -o -name SAMToolkit.devenv -o -name "*.yml" \) -newer $tag)" ]; then
  if [ -n "$(find . \( "${omit_dirs[@]}" \) -prune -false -o -type f \( "${build_files[@]}" \) -a ! \( "${omit_files[@]}" \) -newer $tag)" ]; then
    echo ">> $(date):  Starting... in $DELAY seconds"
    if [ $DELAY -a $DELAY -gt 0 ]; then
      sleep $DELAY
    fi
    find . \( "${omit_dirs[@]}" \) -prune -false -o -type f \( "${build_files[@]}" \) -a ! \( "${omit_files[@]}" \) -newer $tag
    touch "$tag"
    ## BEGIN Command
    if brazil-build release; then
      [ -e ./sam ] && ./sam package && ./sam deploy
      if [ -e ./cdk.json ]; then
        output=`jq '.output' ./cdk.json|tr -d '"'`
        stack=( "${output}"/*dev-stack.template.json )
        if [ "${#stack[@]}" -gt 0 ]; then
          stack=`basename "${stack[0]}"`
          stack=${stack%.template.json}
          echo -e "\n>> brazil-build deploy:assets ${stack} && brazil-build cdk deploy ${stack}\n"
          brazil-build deploy:assets "${stack}" && brazil-build cdk deploy "${stack}"
        fi
      fi
    fi
    ## END Command
    echo ">> $(date):  DONE"
  fi
done
