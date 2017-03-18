#!/usr/bin/perl

use Getopt::Long;

my $input_file;
my $page_file;
my $list_kicad;
my $list_sheets;
my $list_schematics;
my $clean_up;
my $debug;
my $verbose;
my $help;
my %order_hash;
my %schematic_hash;
my @sheet_array;
my $last_page;
my $start_page = 0;

&check_options;
if ($list_sheets || $list_schematics || $list_kicad)
{
  &list_sheet_order($input_file);
  if ($list_schematics && !$list_sheets)
  {
    &print_schematics;
  }
}
else
{
  &read_new_order($page_file);
  &reorder_sheets($input_file);
}

exit;

sub list_sheet_order
{
  my ($SCH_file) = @_;
  my $SHEET;
  my $SHEET_name;
  my $SHEET_active = 0;
  my $SHEET_count = $start_page;

  warn "opening file $SCH_file\n" if ($verbose);
  open ( SCH , "<$SCH_file" ) or &end_program("could not open file $SCH_file");
  while (<SCH>)
  {
    my $NEW_line = $_;
    chomp $NEW_line;
    if ( $NEW_line =~ m/^\$Sheet/)
    {
      $SHEET_active = 1;
      $SHEET_count++;
    }
    elsif ( $NEW_line =~ m/^\$EndSheet/)
    {
      $SHEET_active = 0;
    }
    elsif ( $SHEET_active )
    {
      if ( $NEW_line =~ m/^F0 \"(.*)\"/)
      {
        $SHEET_name = $1;
        print "sheet_only: $SHEET_name,$SHEET_count\n" if ($list_sheets && !$list_schematics && !$hierarchy);
        print "sheet_only: $hierarchy/$SHEET_name,$SHEET_count\n" if ($list_sheets && !$list_schematics && $hierarchy);
      }
      elsif ( $NEW_line =~ m/^F1 \"(.*)\"/)
      {
        my $SCH_name = $1;
	my @added_lines;
	#TODO - need to see how hierarchy is used in the SVG file name... too lazy to do it now:)
        if ($list_kicad)
	{
	  my $SVG_name = $SCH_name;
          $SVG_name =~ s/\.sch//; # remove .sch from the schematic name
	  $SVG_name .= "-" . $SHEET_name . ".svg"; # append the sheet name with hyphen and .svg
          print "$SVG_name\n";
	}
	elsif ($list_sheets && $list_schematics)
	{
          print "sch_and_sheet: $SCH_name,$hierarchy/$SHEET_name,$SHEET_count\n";
	  # run recursively to dive into the schematics
	  @added_lines = qx/$0 -hi "$hierarchy\/$SHEET_name" -li -s -p $SHEET_count -f "$SCH_name"/ if ($hierarchy);
	}
	elsif ($list_sheets && !$list_schematics)
	{
	  @added_lines = qx/$0 -hi "$hierarchy\/$SHEET_name" -li -p $SHEET_count -f  "$SCH_name"/ if ($hierarchy);
	}
	elsif (!$list_sheets && $list_schematics)
	{
	  @added_lines = qx/$0 -hi "$hierarchy\/$SHEET_name" -s -p $SHEET_count -f "$SCH_name"/ if ($hierarchy); 
	}
	foreach my $line (@added_lines)
	{
	  print $line;
          $SHEET_count++;
	}
        warn "$SCH_name,$SHEET_name,$SHEET_count\n" if ($verbose);
        $schematic_hash{$SCH_name} = 1;
      }
    }
  }
  close (SCH);
}

sub print_schematics
{
  # foreach loop to print each schematic once
  foreach my $schematic_name (sort { $a <=> $b } (keys %schematic_hash))
  {
    #print "sch_only: $schematic_name\n";
    print "$schematic_name\n";
  }
  #foreach my $sheet_name (sort { $a <=> $b } (keys %schematic_hash))
  #{
  #  print "$sheet_name = $schematic_hash{$sheet_name}\n";
  #}
}

sub read_new_order
{
  my ($ORDER_file) = @_;
  my $FOUND_CSV_format = 0;
  my $PAGE_NUMBER = 0;
  warn "opening file $ORDER_file\n" if ($verbose);
  open ( ORDER , "<$ORDER_file" ) or &end_program("could not open file $ORDER_file");
  while (<ORDER>)
  {
    my $NEW_line = $_;
    chomp $NEW_line;
    if ( $NEW_line =~ m/^(.*),(\d+)/)
    {
       $SHEET_name = $1,
       $PAGE_number = $2;
       $order_hash{$SHEET_name} = $PAGE_number ;
       warn "--W-- Sheet order $SHEET_name = Page $order_hash{$SHEET_name}\n" if ($debug);
       if ($PAGE_number > $last_page)
       {
         $last_page = $PAGE_number;
       }
       $FOUND_CSV_format = 1;
    }
    elsif ( $NEW_line =~ m/^(.*)$/)
    {
       if ($FOUND_CSV_format)
       {
         &end_program("ERROR - $ORDER_file has mixed format");
       }
       $SHEET_name = $1,
       $PAGE_NUMBER++;
       $order_hash{$SHEET_name} = $PAGE_NUMBER ;
       if ($PAGE_NUMBER > $last_page)
       {
         $last_page = $PAGE_NUMBER;
       }
    }
  }
  close (ORDER);
}

sub reorder_sheets
{
  my ($SCH_file) = @_;
  my $PAGE_X;
  my $PAGE_Y;
  my $SHEET;
  my $SHEET_active = 0;
  my $SHEET_count = $start_page;
  my $LINE_count = 0;
  my @SHEET_array;
  my %page_number_hash;
  my $COMP_active = 0;
  my $total_clean_up_lines = 0;

  warn "opening file $SCH_file\n" if ($verbose);
  open ( SCH , "<$SCH_file" ) or &end_program("could not open file $SCH_file");
  while (<SCH>)
  {
    my $NEW_line = $_;
    chomp $NEW_line;
    if ( $NEW_line =~ m/^\$Sheet/)
    {
      #if a new sheet starts, save the first line and flag to start saving sheet data
      $SHEET_active = 1;
      $SHEET_array[0] = $NEW_line;
    }
    elsif ( $NEW_line =~ m/^\$EndSheet/)
    {
      #if the sheet ends, save the sheet data into an array referenced to the page number
      my $PAGE_number = $order_hash{$SHEET};
      $page_number_hash{$PAGE_number}{X}=$PAGE_X;	#X location for the Page Number Text
      $page_number_hash{$PAGE_number}{Y}=$PAGE_Y;	#Y location for the Page Number Text
      $LINE_count++;
      $SHEET_array[$LINE_count]=$NEW_line;
      for (my $LINE_number = 0; $LINE_number<=$LINE_count; $LINE_number++)
      {
        $sheet_array[$PAGE_number][$LINE_number] = $SHEET_array[$LINE_number];
      }
      $SHEET_active = 0;
      $LINE_count = 0;
    }
    elsif ( $SHEET_active )
    {
      # push each line into an array, once EndSheet is found dump array into a hash
      $LINE_count++;
      if ( $NEW_line =~ m/^F0 \"(.*)\"/)
      {
        $SHEET = $1;
        if ($clean_up)
        {
           $NEW_line = "F0 \"$SHEET\" 50\n";
        }
        warn "--W-- found Sheet $SHEET\n" if ($debug);
      }
      elsif ( $NEW_line =~ m/^F1 \"(.*)\"/)
      {
        $SCHEMATIC = $1;
        $schematic_hash{$SHEET} = $SCHEMATIC;
        if ($clean_up)
        {
           $NEW_line = "F1 \"$SCHEMATIC\" 30\n";
        }
        warn "--W-- found Sheet $SCHEMATIC\n" if ($debug);
      }
      elsif ( $NEW_line =~ m/^S (\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
      {
        my ($X,$Y,$dX,$dY) = ($1,$2,$3,$4);
	$PAGE_X = $X + $dX;			#X location for the Page Number Text
	$PAGE_Y = $Y + $dY + 100;		#Y location for the Page Number Text
      }
      $SHEET_array[$LINE_count]=$NEW_line;
    }

    elsif ( $NEW_line =~ m/^Text Notes/)
    {
      $TEXT_active = 1;
      $LAST_line = $NEW_line;
    }
    elsif ( $TEXT_active )
    {
      $TEXT_active = 0;
      if ($add_page)
      {
        if ( $NEW_line =~ /^PAGE / )
        {
          warn "-- W -- Removing old page number reference: $NEW_line\n";
        }
        else
        {
          print "$LAST_line\n";
          print "$NEW_line\n";
        }
      }
      else
      {
        print "$LAST_line\n";
        print "$NEW_line\n";
      }
    }

    elsif ( $NEW_line =~ m/^\$Comp/)
    {
      print "$NEW_line\n";
      $COMP_active = 1;
    }
    elsif ( $NEW_line =~ m/^\$EndComp/)
    {
      print "$NEW_line\n";
      $COMP_active = 0;
    }
    elsif ( $COMP_active )
    {
      if ( $clean_up )
      {
        if ( $NEW_line =~ m/^F (\d+) \"(.*)\" ([H|V]) (\d+) (\d+) (\d+)  (....) (.) (...) \"(.*)\"/)
        {
          my $FIELD_number = $1;
          my $FIELD_value = $2;
          my $FIELD_visable = $3;
          my $FIELD_x = $4;
          my $FIELD_y = $5;
          my $FIELD_size = $6;
          my $FIELD_orinent = $7;
          my $FIELD_hjustify = $8;
          my $FIELD_vjustify = $9;
          my $FIELD_name = $10;
          my $FIELD_value_org = $FIELD_value;
          $FIELD_value =~ s/^\s+(.*)/$1/e;
          $FIELD_value =~ s/(.*)\s+$/$1/e;
          if ($FIELD_value ne $FIELD_value_org) { $clean_up++ ;}
          print "F $FIELD_number \"$FIELD_value\" $FIELD_visable $FIELD_x $FIELD_y $FIELD_size  $FIELD_orinent $FIELD_hjustify $FIELD_vjustify \"$FIELD_name\"\n";
          $total_clean_up_lines++;
        }
        elsif ( $NEW_line =~ m/^F (\d+) \"(.*)\" ([H|V]) (\d+) (\d+) (\d+)  (....) (.) (...)/)
        {
          my $FIELD_number = $1;
          my $FIELD_value = $2;
          my $FIELD_visable = $3;
          my $FIELD_x = $4;
          my $FIELD_y = $5;
          my $FIELD_size = $6;
          my $FIELD_orinent = $7;
          my $FIELD_hjustify = $8;
          my $FIELD_vjustify = $9;
          my $FIELD_value_org = $FIELD_value;
          $FIELD_value =~ s/^\s+(.*)/$1/e;
          $FIELD_value =~ s/(.*)\s+$/$1/e;
          if ($FIELD_value ne $FIELD_value_org) { $clean_up++ ;}
          print "F $FIELD_number \"$FIELD_value\" $FIELD_visable $FIELD_x $FIELD_y $FIELD_size  $FIELD_orinent $FIELD_hjustify $FIELD_vjustify\n";
          $total_clean_up_lines++;
        }
        else
        {
          print "$NEW_line\n";
        }
      }
      else
      {
        print "$NEW_line\n";
      }
    }
    elsif ( $NEW_line =~ m/^\$EndSCHEMATC/)
    {
      # Print all the sheets in the new order
      if ($add_ledgend)
      {
      #TODO
#        for (my $PAGE = 1; $PAGE<=$last_page; $PAGE++)
#        {
#	  print "Text Notes 1800 8550 0    60   ~ 0
#PAGE #\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n13\n14\n15\n16\n17\n18\n19
#Text Notes 16275 1150 3    100  ~ 0
#CAN and RS485 Communications
#Text Notes 16250 4450 3    100  ~ 0
#
#Wire Notes Line
#	-2050 -50  50   -50 
#Wire Notes Line
#	50   -50  50   3050
#Wire Notes Line
#	50   3050 -2050 3050
#Wire Notes Line
#
#";
#        }
      }
      
      # Print all the sheets in the new order
      for (my $PAGE = 1; $PAGE<=$last_page; $PAGE++)
      {
        warn "page = $PAGE\n" if ($debug);
        if ($add_page)
        {
	  my $physical_page_number;
          if ($start_page)
          {
            $physical_page_number = $PAGE + $start_page - 1;
          }
          else
          {
            $physical_page_number = $PAGE + 1;
          }
          my $X = $page_number_hash{$PAGE}{X};	#X location for the Page Number Text
          my $Y = $page_number_hash{$PAGE}{Y};	#Y location for the Page Number Text
	  print "Text Notes $X $Y 2    70   ~ 0\n";
	  print "PAGE $physical_page_number\n";
        }
        foreach my $LINE_content (@{$sheet_array[$PAGE]})
        {
          warn "line_number = $LINE_content\n" if ($debug);
          print "$LINE_content\n";
        }
      }
      print "$NEW_line\n"; # Print the last line of the file $EndSCHEMATC
    }
    else
    {
      print "$NEW_line\n"; # Print line since it is not modified
    }
  }
  close (SCH);
  if ( $clean_up ) { warn "Clean up option fixed ". ($clean_up-1) . " lines out of $total_clean_up_lines \n"; }
}

# ------------------------------ CLI OPTIONS ---------------------------
sub check_options
{
  my $help;
  GetOptions(
    "help" => \$help,		# flag/boolean (0=false|1=true)
    "file=s" => \$input_file,	# string
    "order=s" => \$page_file,	# string
    "ledgend" => \$add_ledgend,	# flag/boolean (0=false|1=true)
    "page=i" => \$start_page,	# integer
    "kicad" => \$list_kicad,	# flag/boolean (0=false|1=true)
    "list" => \$list_sheets,	# flag/boolean (0=false|1=true)
    "schematics" => \$list_schematics,	# flag/boolean (0=false|1=true)
    "hierarchy=s" => \$hierarchy,	# string
    "add_page" => \$add_page,	# flag/boolean (0=false|1=true)
    "cleanup" => \$clean_up,	# flag/boolean (0=false|1=true)
    "debug=i"   => \$debug,	# integer
    "verbose"  => \$verbose);	# flag/boolean (0=false|1=true)

  $type_file = lc($type_file);

  if ($help) {&print_help}

# Check for empty Required Options file
  if ($input_file eq "")
  {
    warn "ERROR - The option \"file\" is require but empty, please read the help.\n";
    $help = 1;
  }

  if ($page_file eq "")
  {
    if ( !$list_sheets && !$list_schematics && !$list_kicad)
    {
      warn "ERROR - The option \"-kicad\" OR \"-list\" OR \"-schematic\" is require but empty, please read the help.\n";
      $help = 1;
    }
  }

  if ($page_file ne "")
  {
    if ($list_sheets || $list_schematics && !$list_kicad )
    {
      warn "ERROR - The options \"-page\" AND [\"-list\" OR \"-schematics\"] can not be used together, please read the help.\n";
      $help = 1;
    }
    elsif ($list_kicad)
    {
      warn "ERROR - The options \"-page\" AND \"-kicad\" can not be used together, please read the help.\n";
      $help = 1;
    }
  }

  if (($list_sheets || $list_schematics) && $list_kicad )
  {
    warn "ERROR - The options \"-kicad\" AND [\"-list\" OR \"-schematics\"] can not be used together, please read the help.\n";
    $help = 1;
  }

# Check for empty Required Options for NAME and GREP
  if ($verbose)
  {
    warn "VERBOSE - $0 Options sellected are as follows:\n";
    warn "  help = requested\n" if ($help);
    warn "  file = $input_file\n" if ($input_file);
    warn "  order = $page_file\n" if ($page_file);
    warn "  ledgend = TRUE\n" if ($add_ledgend);
    warn "  kicad = TRUE\n" if ($list_kicad);
    warn "  list = TRUE\n" if ($list_sheets);
    warn "  page = $start_page\n" if ($start_page);
    warn "  schematics = TRUE\n" if ($list_schematics);
    warn "  hierarchy = $hierarchy\n" if ($hierarchy);
    warn "  add_page = $add_page\n" if ($add_page);
    warn "  cleanup = TRUE\n" if ($clean_up);
    warn "  debug = $debug\n" if ($debug);
    warn "  verbose = $verbose\n\n" if ($verbose);
  }

  if ($help) {&print_help}
}

sub print_help
{
  warn "\n
This script is used for reordering KiCad Sheets which reorders the page order when printing or plotting.
This script does not modify the original Schematic file and only reorders the Sheets in the given schematic file.

  -help or -he      this message
  -file or -f       KiCad input file .sch format [REQUIRED]
                    *add full path if needed

  -order or -o      CSV input file with the following format:
                    FORMAT>sheet_name,page_number
                      OR
                    FORMAT>sheet_name
                    *add full path if needed
                    *Can not be used with -list or -schematics option(s)

  -kicad            List the Sheets in Page order with the schemactic name.  This will be the same format used to generate SVG files in eeSchema.

  -list or -li      List Sheet(s) in schemtic with page number in the following CSV format:
                    FORMAT>sheet_name,page_number
                    *Can not be used with -order option

  -schematics or -s List schematic(s) linked to sheet(s)
                    FORMAT>schematic_name 
                    *Can not be used with -order option

  -page or -p       Intger value for a starting page number.  Used with the -list or -schemaitc option(s).  This will overide the defalt start page of 1 to a user value.

  -hierarchy -r hi  This is a string to append to the Sheet path. This will go up and down the schematic hierarchy.  Use with the -list and/or -schematics option(s)

  -ledgend or -le   Adds a ledgend with page number, sheet name, and schematic name.  Use with the -order option
  -add_page or -a   Adds a page number to the lower right hand of each sheet
  -cleanup or -c    This option will remove spaces at the begining and end of field values within components
                    Changes the Sheet Name font size to 0.050\" and Sheet Schemtice Name to 0.030\"

  -debug or -d      integer number if things don't go your way (=1) goes to STDERR
  -verbose or -v    flow information with no data and goes to STDERR

EXAMPLE:
\$>$0 -f schematic_filename.sch -l >sheet_number.csv
    edit the sheet_number.csv file and reorder the sheet numbers
\$>$0 -f schematic_filename.sch -p sheet_number.csv >temp.sch
    might want to back up your original file before the next step
\$>mv temp.sch schematic_filename.sch

ALSO SEE: grep_mouser.sh kicad2SW.pl kicad_brd_copy.pl kicad_mod2csv.pl kicad_mod_padgen.pl kicad_svg2pdf.sh kicad_sym_tool.pl
\n";
  exit;
}

sub end_program
{
  my ($error) = @_;
  warn "$error\n";
  &exit_script;
}

sub exit_script
{
  warn "bad things happen to people, even you:)\n";
  exit;
}
