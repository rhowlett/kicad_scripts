#!/usr/bin/perl

use Getopt::Long;

sub print_help { warn "\n
USAGE: $0 -file <filename> [OPTION VALUE]
This script is used resize all fonts for a given attribute.  
Font changes are applied globally for every instances of the given option(s).
This script does not modify the original Schematic file. 
This scripts generates a new file and sends it to STDOUT

OPTIONS:
  -help		this message
  -file		KiCad input file .sch format [REQUIRED]
			*add full path if needed

  -sheet	Change the text size of all Sheet Name(s)
  -sch		Change the text size of all sheet's Schematic Name(s)
  -pin		Change the text size of all sheet's Port/Pin Name(s)

  -glabel	Change the text size of all Global Label(s)
  -hlabel	Change the text size of all Hierachial Label(s)
  -wlabel	Change the text size of all Wire Label(s)
  -note		Change the text size of all Note(s)

  -power	Change the text size on all Power symbol(s)

  -ref		Change the text size of all symbol Reference Name(s)
  -value	Change the text size of all symbol Value Name(s)
  -footprint	Change the text size of all symbol Footprint Name(s)
  -doc		Change the text size of all symbol Document Name(s)

  -debug	integer number if things don't go your way (=1) goes to STDERR
  -verbose	flow information with no data and goes to STDERR

EXAMPLE:
  \$>$0 -file filename.sch -hlabel=50 > temp.sch
  \$>eeschem temp.sch

If this file looks correct then:
  \$>mv temp.sch filename.sch

ALSO SEE: tbd
\n";
  exit;
}

# --- Start Program ---
my %OPTIONS = &check_options;
&update_schematic(%OPTIONS);
exit;
# --- End Program ---

# --- Local Functions/Subroutines ---
sub update_schematic
{
  my (%OPTIONS) = @_;
  my $ACTIVE = "";
  my $START = 0;

  warn "opening file $OPTIONS{file}\n" if ($OPTIONS{verbose});
  open ( SCH , "<$OPTIONS{file}" ) or &end_program("could not open file $OPTIONS{file}");
  while (<SCH>)
  {
    my $NEW_line = $_;
    chomp $NEW_line;
    $print_line = 1;
    if    ( $NEW_line =~ m/^\$EndDescr/) { $START = 1; }
    elsif ( $NEW_line =~ m/^\$EndSCHEMATC/) { $START = 0; }
    elsif ( $NEW_line =~ m/^\$Sheet/) { $ACTIVE = "SHEET"; }
    elsif ( $NEW_line =~ m/^\$Comp/) { $ACTIVE = "COMPONENT"; }
    elsif ( $NEW_line =~ m/^\$End/) { $ACTIVE = "";}
    elsif ( $ACTIVE eq "SHEET" )
    {
      #Format:
      #Fn “text” forms side posx posy dimension
      #Where:
      #  n = sequence number (0..x).
      #  n = 0: name of the corresponding schematic file.
      #  n = 1: name of the sheet of hierarchy.
      #  form = I (input) O (output) B (BiDi) T (tri state) U (unspecified)
      #  side = R (right) , L (left)., T (tpo) , B (bottom)
      if ( $NEW_line =~ m/^F0\s+\"(.*)\"\s+(\d+)/)
      {
        my $Sheet = $1; 
        my $FontSize = $2;
        warn "-D- Found Sheet name $Sheet\n" if ($OPTIONS{debug});
        if ( $OPTIONS{sheet} )# != $FontSize )
        {
          warn "-I- changeing Sheet:$Sheet from:$FontSize to:$OPTIONS{sheet}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "F0 \"$Sheet\" $OPTIONS{sheet}";
        }
      }
      elsif ( $NEW_line =~ m/^F1\s+\"(.*)\"\s+(\d+)/)
      {
        my $Schematic = $1;
        my $FontSize = $2;
        warn "-D- Found Schematic name $Schematic\n" if ($OPTIONS{debug});
        if ( $OPTIONS{sch} )# != $FontSize )
        {
          warn "-I- changeing Schematic:$Schematic from:$FontSize to:$OPTIONS{sch}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "F1 \"$Schematic\" $OPTIONS{sch}";
        }
      }
      elsif ( $NEW_line =~ m/^F(\d+)\s+\"(.*)\"\s+(\S)\s+(\S)\s+(\d+)\s+(\d+)\s+(\d+)/)
      {
        my $FieldNumber = $1;
        my $PinName = $2;
        my $Forms = $3;
        my $Side = $4;
        my $PosX = $5;
        my $PosY = $6;
        my $FontSize = $7;
        warn "-D- Found Sheet Pin name $PinName\n" if ($OPTIONS{debug});
        if ( $OPTIONS{pin} )# != $FontSize )
        {
          warn "-I- changeing Sheet Pin:$PinName from:$FontSize to:$OPTIONS{pin}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "F$FieldNumber \"$PinName\" $Forms $Side $PosX $PosY $OPTIONS{pin}";
        }
      }
    }
    elsif ( $ACTIVE eq "COMPONENT" )
    {
      #Format:
      #F n “text” orientation posx posy dimension flags hjustify vjustify/italic/bold “name”
      #Where:
      #  n = field number :
      #    reference = 0.
      #    value = 1.
      #    Pcb FootPrint = 2.
      #    User doc link = 3.
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
      #Format:             F   Field     Text       OR     PosX    PosY    FontS   Other
      if ( $NEW_line =~ m/^F\s+(\S+)\s+\"(.*)\"\s+([HV])\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)/)#\s+(\S+)\s+([LRCBT])\s+([LRCBTIN]+)\s?(.*?)/)
      { 
        my $FieldNumber = $1;
        my $Text = $2;
        my $Orientation  = $3;
        my $PosX  = $4;
        my $PosY  = $5;
        my $FontSize  = $6;
        my $Other = $7;
        # Determine if this is a virtual part or a real part (power symbols/Flags vs components)
        if ( $FieldNumber eq "0" ) # this is the reference field
        {
          if ( $Text =~ m/^#/ ) { $virtual_part = 1; }
          else { $virtual_part = 0; }

          if ( !$virtual_part && $OPTIONS{ref} )# != $FontSize )
          {
            warn "-I- changeing Ref:$text from:$FontSize to:$OPTIONS{ref}\n" if ( $OPTIONS{verbose} );
            $NEW_line = "F $FieldNumber \"$Text\" $Orientation $PosX $PosY $OPTIONS{ref} $Other";
          }  
          #elsif ( $virtual_part && $OPTIONS{power} )# != $FontSize )
          #{
            #warn "-I- changeing Ref:$Text from:$FontSize to:$OPTIONS{power}\n" if ( $OPTIONS{verbose} );
            #$NEW_line = "F $FieldNumber \"$Text\" $Orientation $PosX $PosY $OPTIONS{power} $Other";
          #}
        }  
        elsif ( $FieldNumber eq "1" )
        {
          if ( !$virtual_part && $OPTIONS{value} )# != $FontSize )
          {
            warn "-I- changeing Value:$Text from:$FontSize to:$OPTIONS{value}\n" if ( $OPTIONS{verbose} );
            $NEW_line = "F $FieldNumber \"$Text\" $Orientation $PosX $PosY $OPTIONS{value} $Other";
          }
          elsif ( $virtual_part && $OPTIONS{power} )# != $FontSize )
          {
            warn "-I- changeing Value:$Text from:$FontSize to:$OPTIONS{power}\n" if ( $OPTIONS{verbose} );
            $NEW_line = "F $FieldNumber \"$Text\" $Orientation $PosX $PosY $OPTIONS{power} $Other";
          }
        }
        elsif ( $FieldNumber eq "2" && $OPTIONS{footprint} )# != $FontSize )
        {
          warn "-I- changeing Footprint:$Text from:$FontSize to:$OPTIONS{footprint}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "F $FieldNumber \"$Text\" $Orientation $PosX $PosY $OPTIONS{footprint} $Other";
        }
        elsif ( $FieldNumber eq "3" && $OPTIONS{doc} )# != $FontSize )
        {
          warn "-I- changeing Document:$text from:$FontSize to:$OPTIONS{doc}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "F $FieldNumber \"$text\" $orientation $posX $posY $OPTIONS{doc} $other";
        }
        else #this is everything else
        {
        }
      }
    }
    elsif ($ACTIVE eq "") # Note: should not be in any section for Text
    {
      #Format:                Text   TYPE    posx    posy    orien   dim     other
      #                       Text   Notes   1650    3050    0       40      ~ 0
      #                       Text   GLabel  1600    1150    2       50      BiDi ~ 0
      #                       Text   Label   9100    800     0       40      ~ 0
      if ( $NEW_line =~ m/^Text\s+(\S+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\d+)\s+(.*)/ )
      {
        #Format: 
        #Text Notes posx posy orientation dimension ~
        #Text GLabel posx posy orientation dimension shape
        #Text HLabel posx posy orientation dimension shape
        #Text Label posx posy orientation dimension ~
        #<the line after Text contains the text to display>
        my $LabelType = $1;
        my $PosX = $2;
        my $PosY = $3;
        my $Orientation = $4;
        my $FontSize = $5;
        my $Other = $6;
        if ($LabelType eq "Label" && $OPTIONS{wlabel} )# != $FontSize)
        {
          warn "-I- changeing Wire Label from:$FontSize to:$OPTIONS{wlabel}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "Text $LabelType $PosX $PosY $Orientation $OPTIONS{wlabel} $Other";
        }
        elsif ($LabelType eq "HLabel" && $OPTIONS{hlabel} )# != $FontSize)
        {
          warn "-I- changeing Hierarchial Label from:$FontSize to:$OPTIONS{hlabel}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "Text $LabelType $PosX $PosY $Orientation $OPTIONS{hlabel} $Other";
        }
        elsif ($LabelType eq "GLabel" && $OPTIONS{glabel} )# != $FontSize)
        {
          warn "-I- changeing Global Label from:$FontSize to:$OPTIONS{glabel}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "Text $LabelType $PosX $PosY $Orientation $OPTIONS{glabel} $Other";
        }
        elsif ($LabelType eq "Notes" && $OPTIONS{note} )# != $FontSize)
        {
          warn "-I- changeing Note Text from:$FontSize to:$OPTIONS{note}\n" if ( $OPTIONS{verbose} );
          $NEW_line = "Text $LabelType $PosX $PosY $Orientation $OPTIONS{note} $Other";
        }
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
    "file=s",		# string
    "sch=i",		# integer
    "sheet=i",		# integer
    "pin=i",		# integer
    "glabel=i",		# integer
    "hlabel=i",		# integer
    "wlabel=i",		# integer
    "note=i",		# integer
    "power=i",		# integer
    "ref=i",		# integer
    "value=i",		# integer
    "footprint=i",	# integer
    "doc=i",		# integer
    "debug=i",		# integer
    "verbose");		# flag/boolean (0=false|1=true)

  &show_options(\%OPTIONS) if ($OPTIONS{debug} > 0 || $OPTIONS{verbose}); #this will print to stderr the option
  if ($OPTIONS{help}) {&print_help}
  if (!$OPTIONS{file}) 
  {
    warn "-E- Did not find option -file.  Option -file is required.  Please read help.\n";
    &print_help
  }
  return(%OPTIONS);
}

# NOTE: this is the format to make this work
# my %option_H;
#  GetOptions( \%option_H,
#    "help"   => ,	# flag/boolean (0=false|1=true)
#    "file=s" => ,	# string
#    "name=s" => ,	# string
#    "grep=s" => ,	# string
#    "debug=i"=> ,	# integer
#    "verbose"=> );	# flag/boolean (0=false|1=true)
# &show_options(\%option_H);

sub show_options
{
  my ($hash_ref) = shift;
  my %option_H = %$hash_ref;
  if ($option_H{"verbose"})
  {
    warn "Checking Options for $0\n";
    warn "VERBOSE - Options sellected are as follows:\n";
    foreach my $KEY (keys %option_H)
    {
      warn "  $KEY = $option_H{$KEY}\n";
    }
  }
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
