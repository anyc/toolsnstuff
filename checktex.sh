#! /bin/sh

# Written 2012 by Mario Kicherer ( http://kicherer.org )

for f in *.tex; do
	echo $f
	aspell -c $f
	cat $f | grep --color " a [aeiouAIEOU]."
	cat $f | grep --color " an [^aeiouAEIOU]."
done
