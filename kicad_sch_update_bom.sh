#!/usr/bin/env bash
 
sch_file=$1.sch
bom_file=$2
 
if [ -s $2 ]
then
  print "Found 2nd argument bom file:$bom_file"
else
  if [ -s $1.sbom.csv ]
  then
    bom_file=$1.sbom.csv
    print "Found default bom file:$bom_file"
  else
    print "Error - could not find a bom file.  You can specify one as the 2nd argument. Or generate a default called $1.sbom.csv"
    exit 1
  fi
fi
 
if [ -s $1.sch ]
then
  echo $1.sch >schematic_list.txt
  kicad_sch_page_order.pl  -schem -file $1 >>schematic_list.txt
  extension=$(date +%Y%j%H%M%S)
  for sch in $(cat schematic_list.txt)
  do
    cp $sch $extension.$sch
    echo "backing up orignal file from $sch to $extension.$sch"
    kicad_bom2sch.pl -sch $sch -sbom $1.sbom.csv >temp.$sch
    mv temp.$sch $sch
  done
else
  print "Error - need a schematic or project name without the (.sch or .pro) extention"
  print "Error - need a schematic or project name without the (.sch or .pro) extention"
  print "USAGE - $0 <project_name>"
  exit 1
fi
exit
