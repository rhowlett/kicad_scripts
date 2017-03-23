#!/usr/bin/env bash

datestamp=$(date +%Y%j%H%M%S)
revision=$1
project=$2
pcb_file=$2.kicad_pcb
revision_dir="./Revision/$revision/$project"
USAGE="USAGE - $0 <revision> <project name>\n
    ARG_1 = revision\n
    ARG_2 = project name without .pro extention\n"

if [ -z "$1" ]
then
  echo "Agument 1 is missing and should be revision"
  echo -e $USAGE
  exit 1
fi

if [ -z "$2" ]
then
  echo "Agument 2 is missing and should be the project name"
  echo -e $USAGE
  exit 2
fi

echo "Starting:"
echo "  Project:$project"
echo "  Revision:$revision"

if [ -s $pcb_file ]
then
  if [ -d $revision_dir ]
  then
    echo "Starting - Creating Plot Files!!!"
  else
    echo "Warning - missing revision Directory - Creating it for you, lazy"
    kicad_create_revision_dirs.sh $revision $project
    echo "Starting - Creating Plot Files!!!"
  fi
else
  echo "Error - couldn't find $pcb_file need a kicad_pcb file for the project name"
  echo -e $USAGE
  exit 3
fi

plot_back_pdfs.py $project $revision
plot_front_pdfs.py $project $revision
plot_gerber.py $project $revision
plot_protel.py $project $revision
plot_drill.py $project $revision

exit 0
