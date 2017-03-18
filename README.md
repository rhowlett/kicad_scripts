# kicad_scripts
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
| kicad_sch_standardize.sh      | Example of how you can used kicad_sch_font_resize.pl and kicad_sch_page_order.pl |
| kicad_sch_update_bom.sh       | Example of how you can use kicad_bom2sch.pl |
|	kicad_pcb_change_ref_num.sh   | Changes refence number based on sheetnumber\*100 numbering style |
|	kicad_pcb_rename_references.sh| Same as above but for a range |
|	bom2groupedCsv.xsl            | This is the format for a bom used in kicad_bom2sch.pl |
|	kicad_bom2sch.pl              | Takes the input of a CSV bom file and updates fields in the schematic to match exactly |
| kicad_sch_font_resize.pl      | CLI program using perl to modify the font sizes of a schematic |
|	kicad_sch_page_order.pl       | CLI program to change to order of the pages in a hierarchial schematic |

