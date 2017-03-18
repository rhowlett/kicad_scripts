#!/usr/bin/env bash

usage="USAGE:

> $0 <file> <old_ref> <new_ref>

where:
  file    = the kicad_pcb JIG file
  old_ref = the refence number in the kicad_pcb JIG file
  new_ref = the the new reference number to replace the old number

The PCB jig that will be replicated should be called temp.kicad_pcb
This will generate a new temp_<ref>/kicad_pcb that can be appended in pcbnew
"

# get comand line arguments
args=("$@")

if [ $# -ne 3 ] 
then
  echo "$usage"
  exit 1
fi

main_file=${args[0]}
old_ref=${args[1]}
new_ref=${args[2]}

if [ -s $main_file ]
then
  temp_file="/tmp/rename_reference.temp"
  echo "-- Starting $new_ref"

  echo "  * Removing User defined Trace Widths"
  grep -v "user_trace_width" $main_file>$temp_file

  for reference in JP Rf Rg RV SW R C D W Q F U P X Z
  do
    echo "  + exchanging $reference.$old_ref to $reference.$new_ref"
    mv $temp_file /tmp/temp_$new_ref
    cat /tmp/temp_$new_ref |sed "s/ $reference$old_ref\(..\) / $reference$new_ref\1 /" >$temp_file
  done

  echo "-- Cleaning Up $new_ref"
  rm /tmp/temp_$new_ref
  mv $temp_file temp_$new_ref.kicad_pcb
else
  echo "Error - can't find or open $main_file"
  echo $usage 
  exit 1
fi
exit 0
