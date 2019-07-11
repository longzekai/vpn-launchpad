#!/bin/bash

usage() { echo "Usage: $0 [-d <duckdns domain name>] [-t <duckdns token>] [-f <fake domain>] [-p <port numbert>] [-w <password>]" 1>&2; exit 1; }
while getopts ":d:f:p:t:w:" o; do
	case "${o}" in
		d)
			DUCKDOMAIN=${OPTARG}
			;;
		f)
			FAKEDOMAIN=${OPTARG}
			;;
		p)
			PORT=${OPTARG}
			;;
		t)
			DUCKTOKEN=${OPTARG}
			;;
		w)
			PASSWORD=${OPTARG}
			;;
		*)
		       	usage;
	esac
done
shift $((OPTIND-1))

if [ -z "${PORT}" ] || [ -z "${PASSWORD}" ] || [ -z "${DUCKDOMAIN}" ] || [ -z "${DUCKTOKEN}" ]|| [ -z "${FAKEDOMAIN}" ]; then
	usage
fi

cat /trojan/examples/server.json-example  \
	| jq " .\"local_port\" |= $PORT " \
	| jq " .\"remote_addr\" |= \"$FAKEDOMAIN\" " \
	| jq " .\"password\"[0] |= \"$PASSWORD\" " \
	| jq " .\"ssl\".\"cert\" |= \"/config/etc/letsencrypt/archive/$DUCKDOMAIN.duckdns.org/fullchain1.pem\" " \
	| jq " .\"ssl\".\"key\" |= \"/config/etc/letsencrypt/archive/$DUCKDOMAIN.duckdns.org/privkey1.pem\" " \
	>/config/server.json

exec /trojan/trojan /config/server.json