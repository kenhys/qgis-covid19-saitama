#!/bin/bash

for f in covid19-jokyo/*.csv; do
    utf8=${f%.csv}.utf8.csv
    case $f in
	*utf8*)
	    :
	    ;;
	*)
	    if [ ! -f ${utf8} ]; then
		echo "$f to $utf8"
		nkf -w8 $f > ${utf8}
	    fi
    esac
done
