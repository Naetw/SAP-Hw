#!/bin/sh 
ls -ARl | sort -nr -k5,5 | awk 'BEGIN{dir=0;file=0;total=0}{if(/^d/)dir+=1 ; if((/^-.*/) && (NF > 8)){file+=1;total+=$5} ; if(NR < 6) print NR":"$5,$9} END {print "Dir num: " dir"\n""File num: " file"\n""Total: " total}'
