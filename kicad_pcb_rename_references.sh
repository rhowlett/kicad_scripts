#!/usr/bin/env bash

usage="USAGE:

> $0 <pcb_ref> <start_ref> <end_ref>

where:
  pcb_ref   = the reference in the PCB Jig layout
  start_ref = the starting reference in the schematics
  end_ref   = the ending reference in the schematics

The PCB jig that will be replicated should be called temp.kicad_pcb
This will generate a new temp_<ref>/kicad_pcb that can be appended in pcbnew
"

# get comand line arguments
args=("$@")

if [ $# -ne 3 ] 
then
  echo "$usage"
  exit
fi

pcb_ref=${args[0]}
pcb_start_ref=${args[1]}
pcb_end_ref=${args[2]}

main_file=temp.kicad_pcb
temp_file="/tmp/rename_reference.temp"
#for i in {5..10}
for i in $(seq $pcb_start_ref $pcb_end_ref)
do
  echo "-- Starting $i"

  echo "  * Removing User defined Trace Widths"
  grep -v "user_trace_width" $main_file>$temp_file

  for reference in JP Rf Rg RV SW R C D W Q F U P X Z
  do
    echo "  + exchanging $reference.$pcb_ref to $reference.$i"
    mv $temp_file /tmp/temp_$i
    cat /tmp/temp_$i |sed "s/ $reference$pcb_ref\(..\) / $reference$i\1 /" >$temp_file
  done
  echo "-- Cleaning Up $i"
  rm /tmp/temp_$i
  mv $temp_file temp_$i.kicad_pcb
done
