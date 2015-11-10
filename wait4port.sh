#! /bin/bash

if [ "$#" -lt "1" ]; then
	echo "Usage: $0 <port> [<command>]"
	exit 1
fi

PORT=$1

dbusRef="$(kdialog --title Wartedialog --progressbar "Warte auf Port ${PORT}..." 10)"

i=0
while netstat -lnt | awk "\$4 ~ /:${PORT}\$/ {exit 1}"; do
	qdbus $dbusRef Set org.kde.kdialog.ProgressDialog value $i > /dev/null || break

	sleep 1
	i=$(( $i + 1 ))
	if [ "$i" == "10" ]; then
		i=0
	fi
done

qdbus $dbusRef close

if [ "$#" -gt "1" ]; then
	exec $2
fi
