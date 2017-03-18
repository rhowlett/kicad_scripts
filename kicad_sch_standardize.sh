#!/usr/bin/env bash

if [ -s $1.sch ]
then
  echo $1.sch >schematic_list.txt
  kicad_sch_page_order.pl  -schem -file $1.sch >>schematic_list.txt
  extension=$(date +%Y%j%H%M%S)
  for sch in $(cat schematic_list.txt)
  do
    cp $sch $extension.$sch
    echo "backing up orignal file from $sch to $extension.$sch"
    kicad_sch_font_resize.pl -verbose -sheet 50 -sch 50 -pin 50 -glabel 40 -hlabel 50 -wlabel 40 -power 30 -ref 40 -value 40 -footprint 30 -file $sch 1>temp.$sch 2>$sch.log
    mv temp.$sch $sch
  done
else
  print "Error - need a schematic or project name without the (.sch or .pro) extention"
  print "USAGE - $0 <project_name>"
fi
exit
