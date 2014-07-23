
## Wrapper for curl command.
## @param 
## @returns int < 128: curl return code 
## @returns int >= 120: encoded HTTP response code. Decode via decode_http()
function kurl()
{
	local kurlcmd result rc
	kurlcmd='curl -s -w \n%{http_code}\n -g'
	## If show curl call is in effect:
	[ -n "$SHOW_CURL" ] && echo $kurlcmd "$@"
	result=$($kurlcmd "$@")
	rc=$?
#echo -n "$result"
	if [ $((`echo "$result"|wc -l` + 0)) -gt 1 ]; then 
		encode_http $(($(echo "$result"|tail -1) + 0))
		rc=$?
		echo -n "$result"|head -1
	fi
	return $rc
}
## @param int Curl error or HTTP response
## Allows codes 0-127, 200-231, 300-331, 400-431, 500-530
## @returns byte Encoded value. Decode via decode_http()
function encode_http()
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
## @param byte-int Encoded curl RC or HTTP encoded value
## @returns int-string echoed value of decoded value.
function decode_http()
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
