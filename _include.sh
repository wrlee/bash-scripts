## This file is intended to be included by other scripts to do common stuff.
## If the script should be stand-alone, this these contents can just be copied there.

## Set colors when in "interactive" mode.
##
## echo "${t_cyan} ...string... ${t_reset}"
##
## Sets multiple display attribute settings:
##	<ESC>[{attr1};...;{attrn}m
##
##  Attribute	      Colours	Foreground	Background
##   0	Reset all     Black		30	40
##   1	Bright        Red		31	41
##   2	Dim           Green		32	42
##   4	Underscorer   Yellow	33	43
##   5	Blink         Blue		34	44
##    	              Magenta	35	45
##   7	Reverse       Cyan		36	46
##   8	Hidden        White		37	47
##
if [ -t 1 ]; then
	## Must use \033 rather than \e: bug in macOS bash v 3 does not respect \e
	## https://superuser.com/a/1057637
	t_reset=$'\e[0m'
	t_blink=$'\e[5m'
	t_bold=$'\e[1m'
	t_red=$'\e[31m'
	t_green=$'\e[32m'
	t_yellow=$'\e[33m'
	t_blue=$'\e[34m'
	t_magenta=$'\e[35m'
	t_cyan=$'\e[36m'
#	t_brightCyan=$'\e[1;36m'
	t_white=$'\e[37m'
fi

## Output variable # of tabs based on size of field to output. This can be used
## to pad fields for nice column alignment.
##
## string=String
## echo -n "$string"
## echo_tabs_align 5 "$string"
## echo "last column string"
##
## @param int $1: max tabs
## @param string $2: string to eval
function echo_tabs_align() {
 	local iter=$(($1 - ${#2} / 8 ))
 	[ $iter -gt 0 ] && for ((iter; iter; iter--)); do
 		echo -en "\t"
 	done
}
## Output string padded with tabs to create a fixed width "column".
##
## echo_align_column 5 "string"
## echo "last column string"
##
## @param int $1: max tabs
## @param string $2: string to eval
## @see echo_tabs_align()
function echo_align_column()
{
	echo -n "$2"
	echo_tabs_align "$@"
}

 ## A silent (and consistent way) to determine if the specified command is accessible.
 ##
 ## @param string $1: Command name to test
function is_command()
{
	type "$@" >/dev/null 2>&1
	return $?
}

## To allow double-dashed values, aka long options, include `-:` in the getopts
## options-template. if the template starts with that, put `--` before it. Or,
## start the template with `:` and handle errors in the case statement.
##
## @param List of long options that require a value (to support values separated by blanks)
getoptsLongOptions() {
  if [ "$OPTION" = - -a -z "$OPTARG" ]; then
      echo "${t_red}'-' missing ':' in getopts, used in `basename $0` script${t_reset}"
      exit
  fi
  if [ $OPTION = - ]; then
    ## Setup long option handling to look like normal getopts setup
    ## option name, excluding any value part, if it exists
    ## option value is anything after any `=` or `:`
    OPTION="${OPTARG%%[=:]*}"
    OPTARG="${OPTARG#$OPTION}"
    OPTARG="${OPTARG#[:=]}"
		[ -z "$OPTARG" ] && for i in "$@"; do
			if [ "$OPTION" = "$i" ]; then
				local optarg=$(($BASH_ARGC - $OPTIND))
				if [ $optarg -lt 0 ]; then
					echo "Option requires an argument -- --${OPTION}"
          exit
				else
					OPTARG="${BASH_ARGV[$(($BASH_ARGC - $OPTIND))]}"
					OPTIND+=1
				fi
				break
			fi
		done
  fi
}