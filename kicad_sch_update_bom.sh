#!/usr/bin/env bash
 
extension=$(date +%Y%j%H%M%S)
sch_file=$1.sch
bom_file=$2
tmp_file=backup_$extension/$1.list
log_file=backup_$extension/$1.log


if [ $bom_file != "" ]
then
  echo "Found 2nd argument bom file:$2" 
else
  if [ -e $1.sbom.csv ]
  then
    bom_file=$1.sbom.csv
    echo "Setting BOM file to default file:$bom_file"
  else
    echo "Error - could not find a bom file.  You can specify one as the 2nd argument. Or generate a default called $1.sbom.csv"
    exit 1
  fi
fi
 
if [ -e $sch_file ] && [ -e $bom_file ]
then
  echo "found schematic file: $sch_file"
  echo "found BOM file: $bom_file"
  echo -n "If this is correct [y] to continue or any other key to cancel:"
  read -n 1 branch
  echo

  if [ $branch == "y" ]
  then
    mkdir backup_$extension
    cp $bom_file backup_$extension/.

    echo "For more info look in the log file: $log_file"
    touch $log_file

    #generate a list of all the schematics in the project
    echo "-PS- running kicad_sch_page_order.pl  -sch -hier \"\" -file $sch_file |sort -u >$tmp_file" >>$log_file
    kicad_sch_page_order.pl  -sch -hier "" -file $sch_file |sort -u >$tmp_file 2>>$log_file
    echo $sch_file >>$tmp_file
    echo "-I- Generated schematic list in $tmp_file" >>$log_file

    for sch in $(cat $tmp_file)
    do
      #backup original schematic incase something goes really wrong
      echo "backing up orignal file from $sch to backup_$extension/$sch"
      echo "-BS- backing up orignal file from $sch to backup_$extension/$sch" >>$log_file
      cp $sch backup_$extension/.
      #update each schematic with the new BOM info
      kicad_bom2sch.pl -sch $sch -sbom $bom_file -verbose >/tmp/temp.$sch 2>>$log_file
      mv /tmp/temp.$sch $sch
    done
    echo "finished updating the schematics with the BOM info from $bom_file"
    echo "exiting"
    echo "finished updating the schematics with the BOM info from $bom_file" >>$log_file
    echo "exiting" >>$log_file
  else
    echo "exiting - doning nothing!!!"
    echo "exiting - doning nothing!!!" >>$log_file
  fi
else
  echo "Error - need a schematic or project name without the (.sch or .pro) extention"
  echo "USAGE - $0 <project name> <sbom file name>"
  exit 1
fi
exit 0

