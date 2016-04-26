## These functions perform curl command calls, returning HTTP response 
## data and the http response code. 
##
## Since bash has a 1 byte size for return/exit values, there are 
## encode/decode functions to pack http response codes into the 1-byte.
## If the HTTP response code must be used, then it is best to unpack
## the byte value into its HTTP value for familiar use. 
## 
## Include by sourcing in script file in which it will be used:
##   source thisfile.sh
## Functions:
## 	kurl 				Curl function
## 	kurl_decode_http 	Decode exit code from kurl back to HTTP response value
## 	kurl_encode_http	Encode exit code or HTTP code into unsigned byte value
##
## Bill Lee github@evolutedesign.com 

function _echo()
{
	for i in "$@"; do
		if [ "${i:0:1}" = "-" ]
			then echo -n $i
			else echo -n \'$i\'
		fi
		echo -n ' '
	done
	echo
}

## Wrapper for curl command. 
## @param $@ curl command parameters
## @returns int < 128: curl return code 
## @returns int >= 128: encoded HTTP response code. Decode via kurl_decode_http()
## @see kurl_encode_http() and kurl_decode_http()
function kurl()
{
	local kurlcmd result rc
	kurlcmd='curl -s -w \n%{http_code}\n -g'
	## If show curl call is in effect:
	[ -n "$SHOW_CURL" ] && _echo $kurlcmd "$@" >&2
	result=$($kurlcmd "$@")
	rc=$?
#echo -n "$result"
	if [ $((`echo "$result"|wc -l` + 0)) -gt 1 ]; then 
		kurl_encode_http $(($(echo "$result"|tail -1) + 0))
		rc=$?
		echo "$result"|sed \$d
	fi
	return $rc
}
## Pack most of the range of useful HTTP response codes into 
## an unsigned byte integer suitable as a command-line exit code.
## @param int Curl error or HTTP response
## Allows codes 0-127, 200-231, 300-331, 400-431, 500-530
## @returns byte Encoded value. Decode via decode_http()
## @see kurl_decode_http()
function kurl_encode_http()
{
	local rc http=$(($1 + 0))
	local class=$(( $http / 100 ))
	case $class in
	0)
		rc=$http
		;;
	[2-5])
		if [ $(( $http % 100)) -lt 32 ]
			then rc=$(( ($class - 1 + 3) * 32 + ($http % 100) ))
			else rc=255
		fi
		;;
	*)
		rc=255
		;;
	esac

	return $rc
}

## Return the HTTP response code corresponding to the byte value
## passed in. 
## @param byte-int Encoded curl RC or HTTP encoded value
## @returns int-string echoed value of decoded value.
## @see kurl_encode_http()
function kurl_decode_http()
{
	local rc=$1 class
	if [ $rc -eq 255 ]; then
		rc=255
	elif [ $rc -ge 128 ]; then
		class=$(( $rc / 32 ))
		rc=$(( $rc - $class * 32 + ($class - 2) * 100 ))
	fi
	echo $rc
}

## Invoke these functions from the command-line
if [ $# -gt 0 -a "`find ${PATH//:/ } -maxdepth 1 -name \"$(basename $0)\" -print -quit`" = "$BASH_SOURCE" -a "`type -t $1`" = 'function' ]; then
	"$@"
	rc=$?
	echo
#	echo rc=$rc $(kurl_decode_http $rc)
	exit $rc
fi
