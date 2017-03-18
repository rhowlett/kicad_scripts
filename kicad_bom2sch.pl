#!/usr/bin/perl

use Getopt::Long;
use lib "$ENV{HOME}/Dropbox/bin/perl";
use lib "$ENV{HOME}/Dropbox/bin/kicad_scripts";
use show_options;
use Text::CSV_PP;

sub print_help { warn "\n
USAGE: $0 -sch <filename.sch> -bom <filename> [OPTION VALUE]
This script takes BOM file values and update a schemtic in kicad
The BOM file is generated using the xsltproc -o \"%O.sbom.csv\" \"<path to script>bom2groupedCsv.xsl\" \"%I\"
Then the BOM can be modified using a spreadsheet tool and saved back into a CSV format (unix file format)
Once the modified BOM is saved, then this tool is run to make the changes to individual schematic files.

Note: this tool works on only one file, it does not traverse the heirarchy.  Use kicad_sch_page_order.pl to generate a list of schematics within a project.  Using a simple for loop in a bash script can achive full heirarchy updates if desired.

OPTIONS:
  -help		this message
  -sch		KiCad input file .sch format [REQUIRED]
			*add full path if needed
  -sbom		Bill of Material file in Comma Seperated Variable format, generated using xsltproc script
  -refs		TODO:Ignore file with a list of references that will be skipped, thus all the original fields for a reference are unchaged
  -values 	TODO:Ignore file with a list of values that will be skipped, thus all the original fields for a value are unchanged
  -parts 	TODO:Ignore file with a list of values that will be skipped, thus all the original fields for a value are unchanged

  -debug	integer number if things don't go your way (=1) goes to STDERR
                1 = this will print to STDOUT the reference hash as it will be used to populate the schematic fields
                2 = this will print to STDOUT the bom as it was parsed with each value quoted

  -verbose	flow information with no data and goes to STDERR

EXAMPLE:
  \$>$0 -sch schfilename.sch -sbom bomfilename.csv >temp.sch
  \$>eeschem temp.sch

If this file looks correct then:
  \$>mv temp.sch filename.sch

ALSO SEE: tbd
\n";
  exit;
}

# --- Start Program ---
my %OPTIONS = &check_options;
my ($REF_Reference_H,$REF_Part_H) = &read_sbomfile(\%OPTIONS);
$OPTIONS{reference_hash} = $REF_Reference_H;
$OPTIONS{part_hash} = $REF_Part_H;
&print_schematic(\%OPTIONS);
exit;
# --- End Program ---

# --- Local Functions/Subroutines ---
#------------------------------------------------------------------------------
# parse_CSV_line($csv_text)
# returns the parsed csv text in an array
#
# I started to go down the path of re-inventing the wheel but came accross this 
#   http://www.perlmonks.org/?node_id=552969
#   by ruzam on Jun 01, 2006 at 02:54 UTC at http://www.perlmonks.org/?node_id=552969
# Modified it to fit my needs:)
#------------------------------------------------------------------------------
sub parse_CSV_line
{
  my $text = shift;
  my @values = ();
  push(@values, $+) while $text =~ m{ \s*(
      # groups the phrase inside double quotes
      "([^\"\\]*(?:\\.[^\"\\]*)*)"\s*,?
      # groups the phrase inside single quotes
      | '([^\'\\]*(?:\\.[^\'\\]*)*)'\s*,?
      # trims leading/trailing space from phrase
      | ([^,\s]+(?:\s+[^,\s]+)*)\s*,?
      # just to grab empty phrases
      | (),
      )\s*}gx;
  push(@values, "") if $text =~ m/,\s*$/;
  return (@values);
}

#------------------------------------------------------------------------------
# print_CSV_values(@csv_array_values)
# prints the values in a value quoted and comma delimited string with a \n
#------------------------------------------------------------------------------
sub print_CSV_values
{
  my (@values) = @_;
  my $count=0;
  foreach (@values) 
  {
    if ($count == 0 )
    {
      print "\"$values[$count]\"";
    }
    else
    {
      print ",\"$values[$count]\"";
    }
      $count++;
  }
  print "\n";
}

#------------------------------------------------------------------------------
# read_sbomfile(%option_hash)
# takes the filename associated with the key "sbom" in the optinos_hash and
# parses the contents of the bom file into two new hashes %BOM_REF_HASH and %BOM_PART_HASH
# that are returned by reference since they can be somewhat large
#------------------------------------------------------------------------------
sub read_sbomfile($) #wanted to see if this really works, with the ($) and it does, how cool is that?
{
  #my (%OPTIONS) = @_;
  #my ($REF_OPTIONS_H) = shift;
  my ($REF_OPTIONS_H) = $_[0];
  my (%OPTIONS) = %{$REF_OPTIONS_H};
  my %BOM_REF_HASH;
  my $FOUND_HEADER = 0;
  my @HEADER_ARRAY;
  my $PART_INDEX;
  my $REF_INDEX;
  my $QUANT_INDEX;

  warn "--S-- read_PART_file START\n" if ($OPTIONS{verbose});

  open ( SBOM , "<$OPTIONS{sbom}" ) or &end_program("ERROR opening the bom file $OPTIONS{sbom}, please check the name or generate a new file using xxx");

  while (<SBOM>)
  {
    #read next line in the file and put it into var $NEW_LINE
    my $NEW_LINE = $_; 

    #remove CR from the end of $NEW_LINE
    chomp $NEW_LINE; 
    # Put the first line of the PART file and map the column names to the pre defined hash
    # this will allow for out of order column to still work
    if (!$FOUND_HEADER) 
    {
      # flag that the header was found so you do this only once
      $FOUND_HEADER = 1; 
      $NEW_LINE =~ s/"//g; #remove all the quote from the line
      @HEADER_ARRAY = split(/,/,$NEW_LINE); #remove quotes and commas between fields and place in an array
      &print_CSV_values(@HEADER_ARRAY) if ($OPTIONS{debug} == 2);
      my $INDEX = 0;
      foreach my $ColumnName (@HEADER_ARRAY)
      {
        if ($ColumnName eq "Reference") # this should always be the first column
        {
          $REF_INDEX = $INDEX;
          $OPTIONS{bom_field_order} = $ColumnName; #Note this will only be in the local subrutine
          $REF_OPTIONS_H->{'bom_field_order'} = $ColumnName; #Note this will put in the orignal hash
        }
        elsif ($ColumnName eq "Quantity") # Note this is not a field, just an indicator of the number of parts
        {
          $QUANT_INDEX = $INDEX;
        }
        elsif ($ColumnName eq "Value")
        {
          $VALUE_INDEX = $INDEX;
          $OPTIONS{bom_field_order} .= ",$ColumnName";
          $REF_OPTIONS_H->{'bom_field_order'} .= ",$ColumnName"; #Note this will put in the orignal hash
        }
        elsif ($ColumnName eq "Footprint")
        {
          $FOOTPRINT_INDEX = $INDEX;
          $OPTIONS{bom_field_order} .= ",$ColumnName";
          $REF_OPTIONS_H->{'bom_field_order'} .= ",$ColumnName"; #Note this will put in the orignal hash
        }
        elsif ($ColumnName eq "Part Number") # Note this is a non-standard field
        {
          $PART_INDEX = $INDEX;
          $OPTIONS{bom_field_order} .= ",$ColumnName";
          $REF_OPTIONS_H->{'bom_field_order'} .= ",$ColumnName"; #Note this will put in the orignal hash
        }
        else
        {
          $OPTIONS{bom_field_order} .= ",$ColumnName";
          $REF_OPTIONS_H->{'bom_field_order'} .= ",$ColumnName"; #Note this will put in the orignal hash
        }
        $INDEX++;
      }
    }
    else # Look at remaining lines for data, now that the first line is maped, 
    {
      # Each line is in a commam seperated format, read the first entry as the Reference for the hash
      #Change (\d+) to ([0-9]+\.?[0-9]*)
      #$NEW_LINE =~ s/",([0-9]+\.?[0-9]*)/","$1/g; #
      #$NEW_LINE =~ s/([0-9]+\.?[0-9]*),"/$1","/g; #
      #$NEW_LINE =~ s/","([0-9]+\.?[0-9]*),([0-9]+\.?[0-9]*)",/","$1","$2",/g; #
      #$NEW_LINE =~ s/^"//; #remove the first quote at the beginning of the line
      #$NEW_LINE =~ s/"$//; #remove the last quote at the end of the line
      #my @FIELDS = split(/","/,$NEW_LINE); #remove quotes and commas between fields and place in an array
      my @FIELDS = &parse_CSV_line($NEW_LINE); # I think this covers all the crazy differences I was seeing...
      &print_CSV_values(@FIELDS) if ($OPTIONS{debug} == 2);
      my @REFS = split(/ /,$FIELDS[$REF_INDEX]);
      my $PART_VALUE = $FIELDS[$VALUE_INDEX];
      my $PART_FOOTPRINT = $FIELDS[$FOOTPRINT_INDEX];
      my $SHORT_FOOTPRINT = $PART_FOOTPRINT;
      $SHORT_FOOTPRINT =~ s/Custom://;
      $SHORT_FOOTPRINT =~ s/://;
      $PART_VALUE =~ s/\s+/-/g;
      my $PART_NUMBER = $FIELDS[$PART_INDEX];
      my $REF_PREFIX;

      foreach my $REFERENCE (@REFS)
      {
        my $INDEX = 0;
        $OPTIONS{'reference_list'} .= "$REFERENCE,"; #Note this will put in the local hash
        $REF_OPTIONS_H->{'reference_list'} .= "$REFERENCE,"; #Note this will put in the orignal hash
        
        # -TEST_PART_NAME:Start- test the name of the part name to determine if it is the DEFAULT value
        # If the part has the default "Value" then set the part to the RefPrefix:Value_Footprint
        $REF_PREFIX = $REFERENCE;
        $REF_PREFIX =~ s/\d+//;
        if ($PART_NUMBER eq "Value" or $PART_NUMBER eq "")
        {
          $PART_NUMBER = $REF_PREFIX . ":" . $PART_VALUE . "_" . $SHORT_FOOTPRINT;
          warn " -INFO- Changing part name from \"$FIELDS[$PART_INDEX]\" to $PART_NUMBER\n" if $OPTIONS{verbose};
          $FIELDS[$PART_INDEX] = $PART_NUMBER; # likely don't need to do this since $PART_NUMBER is what is used, but you never know...
        }
        # -TEST_PART_NAME:End- test the name of the part name to determine if it is the DEFAULT value

        foreach my $FIELD_VAL (@FIELDS)
        {
          if ($INDEX == $REF_INDEX ) # REFERENCES
          {
            $BOM_REF_HASH{$REFERENCE}{$HEADER_ARRAY[$INDEX]}=$FIELD_VAL;
            $BOM_PART_HASH{$PART_NUMBER}{$HEADER_ARRAY[$INDEX]} = $BOM_PART_HASH{$PART_NUMBER}{$HEADER_ARRAY[$INDEX]} . " $REFERENCE"; #to parse, split on white space
          }
          elsif ($INDEX == $QUANT_INDEX ) #This is info not a field, skip and do not add to hash
          {
            if (!$BOM_PART_HASH{$PART_NUMBER}{$HEADER_ARRAY[$VALUE_INDEX]})
            {
              warn " -INFO- There are $FIELD_VAL $PART_NUMBER parts.\n" if $OPTIONS{verbose};
            }
          }
          else # Everything else
          {
            $BOM_REF_HASH{$REFERENCE}{$HEADER_ARRAY[$INDEX]}=$FIELD_VAL;

            if (!$BOM_PART_HASH{$PART_NUMBER}{$HEADER_ARRAY[$INDEX]})
            {
              $BOM_PART_HASH{$PART_NUMBER}{$HEADER_ARRAY[$INDEX]}=$FIELD_VAL;
            }
          }
          $INDEX++;
        }
      }
    }
  }
  close (SBOM);


  if ($OPTIONS{debug} == 1)
  {
    my @REFERENCE_ARRAY = split(/,/,$OPTIONS{reference_list});
    my @FIELD_ARRAY = split(/,/,$OPTIONS{bom_field_order});
    print "-D- The following section is a hash dump for the bom file\n";
    foreach my $REFERENCE (sort (@REFERENCE_ARRAY))
    {
      print " -I- Reference:$REFERENCE\n";
      my $FIELD_INDEX = 0;
      foreach (@FIELD_ARRAY)
      {
        my $FIELD = $FIELD_ARRAY[$FIELD_INDEX];  
        print " -I- Field #$FIELD_INDEX = $FIELD, Field Value=$BOM_REF_HASH{$REFERENCE}{$FIELD}\n";
        $FIELD_INDEX++;
      }
    }
    exit;
  }
  elsif($OPTIONS{debug} == 2)
  {
    exit;
  }

  return (\%BOM_REF_HASH,\%BOM_PART_HASH); # CONSIDER: could stuff this into the OPTION hash here, rather than return them...
}

sub print_schematic
{
  #my (%OPTIONS) = @_;
  my ($REF_OPTIONS_H) = shift;
  my (%OPTIONS) = %$REF_OPTIONS_H;
  my $REF_BOM_HASH = $OPTIONS{reference_hash};
  my %REFERENCE_HASH = %$REF_BOM_HASH;
  my $ACTIVE = "";
  my $START = 0;
  my @COMP_ARRAY;
  my $print_line = 1;
  my $virtual_part;
  my $Reference;
  my $Value;
  my @HEADER_ARRAY = split(/,/,$OPTIONS{bom_field_order});
  my $TOTAL_FIELDS = scalar @HEADER_ARRAY;
  my $LAST_FIELD_NUMBER;
  my $LAST_FIELD_OTHER;

  warn "opening file $OPTIONS{sch}\n" if ($OPTIONS{verbose});
  open ( SCH , "<$OPTIONS{sch}" ) or &end_program("could not open file $OPTIONS{sch}");
  while (<SCH>)
  {
    my $NEW_line = $_;
    chomp $NEW_line;
    if    ( $NEW_line =~ m/^\$EndDescr/) { $START = 1; }
    elsif ( $NEW_line =~ m/^\$EndSCHEMATC/) { $START = 0; }
    elsif ( $NEW_line =~ m/^\$Comp/) 
    { 
      $ACTIVE = "COMPONENT"; # this is where all the field info is for components/parts/symbols
      $LAST_FIELD = 0;
      $print_line = 0; # stop printing lines and start storing component info
      $virtual_part = 0;
      push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
    }
    elsif ( $NEW_line =~ m/^\$EndComp/) 
    { 
      $ACTIVE = ""; #this concludes all the info for this componenet, time to print
      foreach (@COMP_ARRAY) { print "$_\n";} #print the contents of the new component
      @COMP_ARRAY =(); # clear the array for the next component
      $print_line = 1; # start printing lines again, incuding this one since the line was not pushed onto the COMP_ARRAY
    }
    elsif ( $ACTIVE eq "COMPONENT" )
    {
      #Field Format:
      #F n “text” orientation posx posy dimension flags hjustify vjustify/italic/bold “name”
      #Where:
      #  n = field number :
      #    Reference = 0.
      #    Value = 1.
      #    Pcb Footprint = 2.
      #    User Doc link = 3.
      #  text (delimited by double quotes)
      #  orientation = H (horizontal) or V (vertical).
      #  position X and Y
      #  dimension (default = 50) aka Font Size
      #  Flags: visibility = 0 (visible) or 1 (invisible)
      #  hjustify vjustify = L R C B or T
      #    L= left
      #    R = Right
      #    C = centre
      #    B = bottom
      #    T = Top
      #  Style: Italic = I or N
      #  Style Bold = B or N
      #  Name of the field (delimited by double quotes) (only if it is not the default name)
      #Note: vjustify, Italic and Bold are in the same 3 chars word.
      # - REFERENCE - Header Column Name is Reference
      if ( $NEW_line =~ m/^F\s+0\s+\"(.*)\"\s+(.*)/) 
      { 
        $Reference = $1;
        my $Other = $2;
        # Determine if this is a virtual part or a real part (power symbols/Flags vs components)
        if ( $Reference =~ m/^\#/ ) { $virtual_part = 1; } # should not be in the BOM file
        else                  { $virtual_part = 0; } # should be in the BOM file

        if ( $virtual_part )
        {
          warn "-I- found Virtual Part $Reference\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
        }  
        else
        {
          warn "-I- found Reference $Reference\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
        }  
      }
      # - VALUE - Header Column Name is Value
      elsif ( $virtual_part )
      {
        push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
      }
      elsif ( $NEW_line =~ m/^F\s+1\s+\"(.*)\"\s+(.*)/) 
      { 
        $Value = $1;
        my $Other = $2;
        if ($Value eq $REFERENCE_HASH{$Reference}{Value})
        {
          warn "  -I- Same Value:$Value\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
        }
        else
        {
          warn "  -I- Change Value:$Value changing to $REFERENCE_HASH{$Reference}{Value}\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, "F 1 \"$REFERENCE_HASH{$Reference}{Value}\" $Other"; # start pushing conponent info onto the COMP_ARRAY 
        }
      }
      # - FOOTPRINT - Header Column Name is Footprint
      elsif ( $NEW_line =~ m/^F\s+2\s+\"(.*)\"\s+(.*)/) 
      { 
        $Footprint = $1;
        my $Other = $2;
        if ($Footprint eq $REFERENCE_HASH{$Reference}{Footprint})
        {
          warn "  -I- Same Footprint:$Footprint\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
        }
        else
        {
          warn "  -I- Change Footprint:$Footprint changing to $REFERENCE_HASH{$Reference}{Footprint}\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, "F 2 \"$REFERENCE_HASH{$Reference}{Footprint}\" $Other"; # start pushing conponent info onto the COMP_ARRAY 
        }
      }
      # - DOCUMENT - Header Column Name is Datasheet
      elsif ( $NEW_line =~ m/^F\s+3\s+\"(.*)\"\s+(.*)/) 
      { 
        $Datasheet = $1;
        my $Other = $2;
        if ($Datasheet eq $REFERENCE_HASH{$Reference}{Datasheet})
        {
          warn "  -I- Same Document:$Datasheet\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
        }
        else
        {
          warn "  -I- Change Document:$Datasheet changing to $REFERENCE_HASH{$Reference}{Datasheet}\n" if ( $OPTIONS{verbose} );
          push @COMP_ARRAY, "F 3 \"$REFERENCE_HASH{$Reference}{Datasheet}\" $Other"; # start pushing conponent info onto the COMP_ARRAY 
        }
      }
      # - FIELD N -
      elsif ( $NEW_line =~ m/^F\s+(\S+)\s+\"(.*)\"\s+(.*)\s+\"(.*)\"/) 
      { 
        my $Fieldnumber = $1;
        my $Fieldvalue = $2;
        my $Other = $3;
        my $Fieldname = $4;
        my $HeaderColumnName = $HEADER_ARRAY[$Fieldnumber];
        $LAST_FIELD_NUMBER = $Fieldnumber;
        $LAST_FIELD_OTHER = $Other;
        $LAST_FIELD = 1;
        if ( $Fieldnumber <= $TOTAL_FIELDS )
        {
          if ( ($Fieldname eq $HeaderColumnName) and ($Fieldvalue eq $REFERENCE_HASH{$Reference}{$HeaderColumnName}) )
          {
            warn "  -I- Same F $Fieldnumber with Value:$FieldValue and Field Name :$Fieldname\n" if ( $OPTIONS{verbose} );
            push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
          }
          else
          {
            warn "  -W- Change F $Fieldnumber with Value:$FieldValue to $REFERENCE_HASH{$Reference}{$HeaderColumnName} and Field Name:$Fieldname to $HeaderColumnName\n" if ( $OPTIONS{verbose} );
            push @COMP_ARRAY, "F $Fieldnumber \"$REFERENCE_HASH{$Reference}{$HeaderColumnName}\" $Other \"$HeaderColumnName\""; # start pushing conponent info onto the COMP_ARRAY 
          }
        }
        else
        {
          warn "  -W- Removing F $Fieldnumber with Value:$FieldValue and Field Name :$Fieldname\n" if ( $OPTIONS{verbose} );
        }
      }
      elsif ($LAST_FIELD)
      {
        if ( $LAST_FIELD_NUMBER < $TOTAL_FIELDS )
        {
          for (my $Fieldnumber = $LAST_FIELD_NUMBER+1; $Fieldnumber < $TOTAL_FIELDS; $Fieldnumber++)
          {
            my $HeaderColumnName = $HEADER_ARRAY[$Fieldnumber];
            warn "  -W- Creating F $Fieldnumber with Value:NA and Field Name :$HeaderColumnName\n" if ( $OPTIONS{verbose} );
            push @COMP_ARRAY, "F $Fieldnumber \"NA\" $Other \"$HeaderColumnName\""; # start pushing conponent info onto the COMP_ARRAY 
          }
        }
        $LAST_FIELD = 0;
        push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
      }
      # everything else
      else 
      {
        push @COMP_ARRAY, $NEW_line; # start pushing conponent info onto the COMP_ARRAY 
      }
    }
    if ($print_line) {print "$NEW_line\n"};
  }
  close (SCH);
}

# ------------------------------ CLI OPTIONS ---------------------------
sub check_options
{
  my $help;
  my %OPTIONS;
  GetOptions(\%OPTIONS,
    "help",		# flag/boolean (0=false|1=true)
    "sch=s",		# string
    "sbom=s",		# string
    "debug=i",		# integer
    "verbose");		# flag/boolean (0=false|1=true)

  &show_options(\%OPTIONS) if ($OPTIONS{debug} > 0 || $OPTIONS{verbose}); #this will print to stderr the option
  #test options
  if (!$OPTIONS{sch})
  {
    warn "-E- missing option for schematic file, please read help\n";
    $OPTIONS{help} = 1;
  }
  if (!$OPTIONS{sbom})
  {
    warn "-E- missing option for sbom file, please read help\n";
    $OPTIONS{help} = 1;
  }

  if ($OPTIONS{help}) {&print_help} # this will exit the program
  return(%OPTIONS);
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
