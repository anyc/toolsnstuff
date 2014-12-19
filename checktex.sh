#! /bin/sh

# Written 2012 by Mario Kicherer ( http://kicherer.org )

if [ "$1" == "-r" ]; then
	FILES=$(find . -iname "*.tex")
else
	FILES=$(ls *.tex)
fi

for f in ${FILES}; do
	echo $f
	aspell -c $f
	cat $f | grep --color " a [aeiouAIEOU]."
	cat $f | grep --color " an [^aeiouAEIOU]."
done
