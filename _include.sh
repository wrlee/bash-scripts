## This file is intended to be included by other scripts to do common stuff.
## If the script should be stand-alone, this these contents can just be copied there.

## Set colors when in "interactive" mode.
##
## echo -e ${t_cyan} ...string... ${t_reset}
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
##   7	Reverse       Cyan		36	46
##   8	Hidden        White		37	47
##
if [ -t 1 ]; then
	t_reset='\033[0m'
	t_bold='\033[1m'
	t_red='\033[31m'
	t_yellow='\e[33m'
	t_cyan='\033[36m'
#	t_brightCyan='\e[01;36m'
	t_green='\033[32m'
	t_white='\033[37m'
fi

## Print variable # of tabs based on size of field to output. This can be used
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
## Print string an tabs to create a fixed width "column". 
##
## echo_align_column 5 "string"
## echo "last column string"
##
## @param int $1: max tabs
## @param string $2: string to eval
function echo_align_column()
{
	echo -n "$2"
	echo_tabs_align "$@"
}

function is_command()
{
	type "$@" >/dev/null 2>&1
	return $?
}
