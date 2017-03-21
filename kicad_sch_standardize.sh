#!/usr/bin/env bash
temp_file=/tmp/temp_list.txt
rm -f $temp_file

if [ -s $1.sch ]
then
  echo $1.sch >$temp_file
  kicad_sch_page_order.pl  -schem -file $1.sch >>$temp_file

  sort -u $temp_file >$temp_file.1
  mv $temp_file.1 $temp_file
  word_count=$(cat $temp_file |wc -l)
  diff_count=$word_count
  while [ $diff_count -ge 1 ]
  do
    for sch in $(cat $temp_file)
    do
      last_count=$word_count
      kicad_sch_page_order.pl  -schem -file $sch >>$temp_file
      sort -u $temp_file >$temp_file.1
      mv $temp_file.1 $temp_file
      word_count=$(cat $temp_file |wc -l)
      let diff_count=$word_count-$last_count
      #echo "last = $last_count , count = $word_count , diff = $diff_count"
    done
  done
else
  print "Error - need a schematic or project name without the (.sch or .pro) extention"
  print "USAGE - $0 <project_name>"
  exit 1
fi

extension=$(date +%Y%j%H%M%S)
mkdir backup_$extension
for sch in $(cat $temp_file)
do
  cp $sch backup_$extension/.
  echo "backing up orignal file from $sch to backup_$extension/$sch"
  kicad_sch_font_resize.pl -verbose -sheet 50 -sch 50 -pin 50 -glabel 40 -hlabel 50 -wlabel 40 -power 30 -ref 40 -value 40 -footprint 30 -file $sch 1>temp.$sch 2>$sch.log
  mv temp.$sch $sch
done

exit 0
