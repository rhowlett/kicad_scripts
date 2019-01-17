# kicad_scripts
Note to the reader.  I generally write CLI scripts in bash, python, perl, C, and C++.  This is some really old stuff I just wanted to document and it gave me an excuse to learn a little about git.
---
* This is a number of **CLI** scripts written in various languages like **_c, bash, perl, and python_.**
 These scripts are workarounds for things that are not easy to do or take a long time to do in the kicad GUI.
* Most of the script **modifies** either the **_sch or kicad_pcb_** files directly.  Thus modifing the source code to eeschema or pcbnew require closing the program and relaunching...
* As questions come up regarding how to run programs I will write a quick **HOW TO** or post the **_program.pl -help_** :)
* Also, very interested in hearing what other people would like to see
---

| File                          | What it does                                               |
| ----------------------------- |------------------------------------------------------------|
| README.md                     | The file you are reading |
| extract_pcbnew.pl             | CLI program using perl to modify Kicad pcbnew files (just wanted to write a s-expression parser) |
| kicad_sch_standardize.sh      | Example of how you can used kicad_sch_font_resize.pl and kicad_sch_page_order.pl |
| kicad_sch_update_bom.sh       | Example of how you can use kicad_bom2sch.pl |
|	kicad_pcb_change_ref_num.sh   | Changes refence number based on sheetnumber\*100 numbering style |
|	kicad_pcb_rename_references.sh| Same as above but for a range |
|	bom2groupedCsv.xsl            | This is the format for a bom used in kicad_bom2sch.pl |
|	kicad_bom2sch.pl              | Takes the input of a CSV bom file and updates fields in the schematic to match exactly |
| kicad_sch_font_resize.pl      | CLI program using perl to modify the font sizes of a schematic |
|	kicad_sch_page_order.pl       | CLI program to change to order of the pages in a hierarchial schematic |

## extract_pcbnew.pl
I think it worked... It's been too long since I played with this.  This was written before most of this stuff could be done in python. Just a nice reference to a S-Expression parse and modification (technique can be used for other things too.)

## kicad_sch_standardize.sh
<dl>
<dt>NAME</dt>
<dd>kicad_sch_standardize.sh - Kicad Project schematic global font standardizer</dd>
<dt>SYNOPSIS</dt>
<dd>kicad_sch_standardize.sh project_name</dd>
<dt>DESCRIPTION</dt>
<dd>This tool is designed to take the top level of a schematic in Kicad and find all assoiated schematics and run kicad_sch_font_resize.pl on each of the schematics.  Line 40 of this script can be modified to fit your needs.  This line holds a few of the fonts that can be changed in your project schematics.  For full documentation of what fonts can be changed run help on: kicad_sch_font_resize.pl -help</dd>
<dt>OPTIONS</dt>
<dd>none</dd>
<dt>FILES</dt>
<dd>none</dd>
<dt>ENVIRONMENT</dt>
<dd>Requires perl and kicad_sch_page_order.pl to be in you path</dd>
<dt>DIAGNOSTICS</dt>
<dd>none</dd>
<dt>BUGS</dt>
<dd>Sure there might be some, I'm not perfect, just hacking my way on</dd>
<dt>AUTHOR</dt>
<dd>Richard Howlett @ I get too much email</dd>
<dt>SEE ALSO</dt>
<dd>kicad_sch_font_resize.pl, kicad_sch_update_bom.sh, kicad_pcb_change_ref_num.sh, kicad_pcb_rename_references.sh</dd>
</dl>

## kicad_sch_font_resize.pl
<dl>
<dt>NAME</dt>
<dd>kicad_sch_font_resize.pl - Kicad Schematic global font modifier</dd>
<dt>SYNOPSIS</dt>
<dd>kicad_sch_font_resize.pl -file schematic_name.sch [OPTION VALUE]</dd>
<dt>DESCRIPTION</dt>
<dd>This script is used resize all fonts for a given attribute for the given schmatic file.  This only works on the file give, it does not modify child schematics.  Font changes are applied globally for every instances of the given option(s). This script does not modify the original Schematic file. This scripts generates a new file and sends it to STDOUT
</dd>
<dt>OPTIONS</dt>

  | Option    | Value     | Description |
  |-----------|-----------|-------------|
  | -help     |           | this message |
  | -file     | file_name | KiCad input file .sch format [REQUIRED] (add full path if needed) |
  | -sheet    | int       | Change the text size of all Sheet Name(s)|
  | -sch	     | int       | Change the text size of all sheet's Schematic Name(s)|
  |-pin       |	int       | Change the text size of all sheet's Port/Pin Name(s)|
  | __Text Lables__ |
  |-glabel    |	int       | Change the text size of all Global Label(s)|
  |-hlabel    |	int       | Change the text size of all Hierachial Label(s)|
  |-wlabel    |	int       | Change the text size of all Wire Label(s)|
  |-note      | int       | Change the text size of all Note(s)|
  | __Power Symbols__ |
  |-power     | int       | Change the text size on all Power symbol(s)|
  | __Schematic Symbols Attributes__ |
  |-ref	      | int       | Change the text size of all symbol Reference Name(s)|
  |-value     | int       | Change the text size of all symbol Value Name(s)|
  |-footprint |	int       | Change the text size of all symbol Footprint Name(s)|
  | -doc	     | int       | Change the text size of all symbol Document Name(s)|
  | __Debugging__ |
  | -debug    | int       | If things don't go your way (=1) goes to STDERR|
  | -verbose	 |           | Flow information with no data and goes to STDERR|   

<dt>FILES</dt>
<dd>-file requires a Kicad schematics file.  Full path might be required.</dd>
<dt>ENVIRONMENT</dt>
<dd>Requires perl</dd>
<dt>DIAGNOSTICS</dt>
<dd>-debug and -verbose options should send info the STDERR</dd>
<dt>BUGS</dt>
<dd>Sure there might be some, I'm not perfect, just hacking my way on</dd>
<dt>AUTHOR</dt>
<dd>Richard Howlett @ I get too much email</dd>
<dt>SEE ALSO</dt>
<dd>TBD</dd>
<dt>EXAMPLE</dt>
<dd><pre>
$>(path to script)/kicad_sch_font_resize.pl -file filename.sch -hlabel=50 > temp.sch
$>eeschem temp.sch

If this file looks correct then:
$>mv temp.sch filename.sch
</pre></dd>
</dl>
