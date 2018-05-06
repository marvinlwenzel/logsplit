#!/bin/bash
X="$(echo $0 | rev | cut -f1 -d/ | rev)"
read -r -d '' HELP << EOM
       $X - Tool to split MySQL general log.
Usage: $X <MYSQL_LOG>

Creates multiple files of the format q<N>.<MYSQL_LOG>,
where <N> is the number of the query connection.
EOM
if [[ "$1" = "-h" ]]; then
	echo "$HELP"
	exit 0
fi

if [[ "$1" = "--help" ]]; then
	echo "$HELP"
	exit 0
fi

FILE=$1
if [ ! -f $FILE ]; then
		>&2 echo "File '$FILE' does not exist. Exit."
		exit 1;
fi
if [ ! -r $FILE ]; then
		>&2 echo "File '$FILE' is not readable. Exit."
		exit 1;
fi

reg='^[12]'
LASTLINE=$(wc -l $FILE | cut -d$' ' -f1)
querynums=$(grep -P "Z\t[ ]*[0-9]*" $FILE | cut -f2 -d$'\t' | sed 's/^ *//;s/ *$//' | cut -f1 -d$' ' | sort | uniq)

while read -r querynum; do
	OUTFILE="q$querynum.$FILE"
	lineNumbersStartingForQuery=$(grep -P "Z\t[ ]*$querynum" -n $FILE | cut -d: -f1)
	while read -r startLineNum; do
		sed "$startLineNum!d" $FILE >> $OUTFILE
		i=$(( $startLineNum + 1))
		line=$(sed "$i!d" $FILE)
		while [[ ! $line =~ $reg ]]; do
			echo "$line" >> $OUTFILE
			i=$(( $i + 1))
			if [[ $i -gt $LASTLINE ]]; then
					i=$startLineNum
			fi
			line=$(sed "$i!d" $FILE)
		done
	done <<< "$lineNumbersStartingForQuery"
done <<< "$querynums"
