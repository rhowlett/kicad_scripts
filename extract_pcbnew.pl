#!/usr/bin/perl

# NOTE: main program is at the end of this file

use Getopt::Long;
use Text::Balanced qw(extract_delimited extract_bracketed);

my $usage = "
NAME
       $0 - modifies a KiCad PCB file and prints the results to <STDOUT>

SYNOPSIS
       $0 [OPTION]... -f [FILE]...

DESCRIPTION
       This program reads a KiCad BRD file and modifies the contents to generate a new BRD file.

       Mandatory arguments to long options are mandatory for short options too.

  -help 	   this message

  -file <file>	   KiCad input file .kicad_pcb format [REQUIRED]
                   (add full path if needed)
  
       PCB components locations 

  -aux_axis        This will move the Auxiary Axis to either the new (nx,ny) location OR offset the
                   the axis by (ox,oy).

  -nx <val>        Moves the PCB X cordinates, based on the Auxiray Axis
  -ny <val>        Moves the PCB Y cordinates, based on the Auxiray Axis
                   NOTE: Can not be used with coresponding ox AND/OR oy options

  -ox <val>        This will offset the PCB in the X direction by this ammount in mm
  -oy <val>        This will offset the PCB in the Y direction by this ammount in mm
                   NOTE: Can not be used with coresponding nx AND/OR ny options

  -layer or -l     This option will swap two layers between the top and bottom layers
                   1..14 are the valid layers
                   EX: to swap layer 2 with 3 the option will look as follows
                     -layer 2,3

       Reference Modifications

  -base		  This is the base reference number.  
                  EX: R1001, R1002, R1003 have a base of 1000
                  thus -base 1000

  -reference      This will modify the base reference to a new reference.
                  EX: R1001, R1002, R1003 
                  Thus: -base 1000 -reference 2100
                  Renames to: R2101, R2102, R2103 

  -cat		  This will remove all section and main wrapper so that multiple PCB files can be concatenated together to generatre a single PCB file

  -sz_drawings    This will re-size the line width
  -sz_pcb_outline This will re-size the line width
  -sz_dimensions  This will re-size the line width
  -sz_text    	  This will re-size the text

  -rm_drawings
  -rm_tracks
  -rm_zones
  -rm_fill
  -rm_text
  -rm_pcb_outline
  -rm_dimensions

  -3dshapes
  
  -debug or -d     integer number if things don't go your way (=1) goes to STDERR
  -verbose or -v   flow information with no data and goes to STDERR

EXAMPLE: 
\$>$0 -n 18 -r 19 -f -x 500 filename.kicad_pcb 
  Will create a file called filename_19.kicad_pcb and offset the modules, wires, and text by 0.5 inches
In Pcbnew File-> Append Board -> filename_19.kicad_pcb to master design 
"; 

my %option_hash;
my %pcbnew_hash;
my %remove_hash;
my %change_hash;
my %values_hash;
   $values_hash{offset}{X} = 0;
   $values_hash{offset}{Y} = 0;
my @breadcrum;
my $dubug = 1;

$option_hash{aux_axis} = 1; #
$option_hash{nx} = 25.4; #
$option_hash{ny} = 25.4; #
$option_hash{ox} = 0; #default = no offset in the x direction
$option_hash{oy} = 0; #default = no offset in the y direction

sub check_options()
{
  GetOptions(\%option_hash,
    "help",		# flag/boolean (0=false|1=true)
    "nx=f",
    "ox=f",
    "ny=f",
    "oy=f",
    "layer=s",
    "base=s",
    "reference=i",
    "cat",
    "sz_drawings",	# TBD
    "sz_pcb_outline",	# TBD
    "sz_dimensions",	# TBD
    "sz_text",		# TBD
    "rm_drawings",	# TBD
    "rm_tracks",	# TBD
    "rm_zones",		# TBD
    "rm_fill",		# TBD
    "rm_text",		# TBD
    "rm_pcb_outline",	# TBD
    "rm_dimensions",	# TBD
    "3dshapes",		# TBD
    "file=s",
    "aux_axis=f",
    "debug=i",		# integer
    "verbose");		# flag/boolean (0=false|1=true)

  # BEGIN Checking Options
  if ($option_hash{"verbose"})
  {
    warn "Checking Options for $0\n";
    warn "-I- Options sellected are as follows:\n";
    foreach my $key (keys %option_hash)
    {
      warn "  $key = $option_hash{$key}\n";
    }
    warn "-I- End of sellected options.\n";
  }

  if ( !$option_hash{file} )
  {
    warn "-E- options file is not set\n";
    $option_hash{help} = 1;
  }
  if ( $option_hash{nx} )
  {
    if ($option_hash{ox} != 0)
    {
      warn "-E- options nx and ox both can not be set\n";
      $option_hash{help} = 1;
    }
    elsif ($option_hash{aux_axis})
    {
      warn "-W- Setting options aux_axis will move aux_axis(X) to $option_hash{nx}\n";
    }
  }
  elsif ( $option_hash{ox} != 0 )
  {
    if ($option_hash{aux_axis})
    {
      warn "-W- Setting options aux_axis will offset aux_axis(X) to $option_hash{ox}\n";
    }
  }
  
  if ( $option_hash{ny} )
  {
    if ($option_hash{oy} != 0)
    {
      warn "-E- options ny and oy both can not be set\n";
      $option_hash{help} = 1;
    }
    elsif ($option_hash{aux_axis})
    {
      warn "-W- Setting options aux_axis will move aux_axis(Y) to $option_hash{ny}\n";
    }
  }
  elsif ( $option_hash{oy} != 0 )
  {
    if ($option_hash{aux_axis})
    {
      warn "-W- Setting options aux_axis will offset aux_axis(Y) to $option_hash{oy}\n";
    }
  }
  if ($option_hash{help})
  {
    warn $usage;
    exit(1);
  }
  # END Checking Options
}


$option{base} = 100; #
$option{reference} = 200; #
 
$remove_hash{section}{version}   = "false";
$remove_hash{section}{host} 	 = "false";
$remove_hash{section}{general}   = "false";
$remove_hash{section}{page} 	 = "false";
$remove_hash{section}{layers}    = "false";
$remove_hash{section}{setup} 	 = "false";
$remove_hash{section}{net} 	 = "false";
$remove_hash{section}{net_class} = "false";
$remove_hash{section}{module}    = "false";
$remove_hash{section}{segment}   = "true";
$remove_hash{section}{dimension} = "true";
$remove_hash{section}{gr_arc}	 = "true";
$remove_hash{section}{gr_circle} = "true";
$remove_hash{section}{gr_line}   = "true";
$remove_hash{section}{gr_text}   = "true";
$remove_hash{section}{target}	 = "true";
$remove_hash{section}{zone}	 = "true";

$change_hash{setup}{aux_axis_origin} = 2;
$change_hash{setup}{grid_origin} = 2;
$change_hash{module}{at} = 2;

sub pad_white_space
{
  my ($level) = @_;
  print "\n";
  for (my $space = 0; $space <= $level; $space++)
  {
    print " ";
  }
}

sub parse_S_expression
{
  my ($txt,$key,$level) = @_; #pass s-expression data into $txt and some formatting spaces
  my ($element);
  # test if this is the first time to parse, first element sould be $element=kicad
  if ($level == 0)
  {
    $first_element = 1;
  }
  else
  {
    $first_element = 0;
  }
  $level++;

  $txt =~ s/^\s+//s; #remove white space from the begining
  $txt =~ s/\s+$//s; #remove white space from the end
  $txt =~ /^\((.*)\)$/s or die "Not an s-expression: <<<$txt>>>"; #test that this has matching parens
  $txt = $1; #put the info found between the parens into $txt

  #note, when you enter this while loop this will be the name of a section, it might be a good idea to pass the name of the section coming from
  while ($txt ne '') #while the $txt string has a char within it
  {
    my $c = substr $txt,0,1; #put the first char into $c
    if ($c eq '(') #if the first char is a paren ( then run this section
    {
      ($element, $txt) = extract_bracketed($txt, '()'); #find everything between the (.*) and put it into $element, this will also remove from $txt
      $element =~ s/^\((\S+)\s+/(/ and $key = $1; #remove the value from the begining of $element and place it into $count
      my $entry_modified = &modify_key_entry($element,$key,$level);
      if (!$entry_modified)
      {
        # format with leading spaces
        &pad_white_space($level);
        print "( $key";
        push (@breadcrum,$key);
        &parse_S_expression($element,$key,$level); #recursive loop
      }
    } 
    elsif ($c eq '"') #if the first char is a quote " then run this section
    {
      ($element, $txt) = extract_delimited($txt, '"');
      #$element =~ s/^"(.*)"/$1/; #put everything between the quotes into $element
      print " $element";
    }
    else 
    {
      $txt =~ s/^(\S+)// and $element = $1; #remove the value from the begining of $txt and place it into $element
      # sanity check to make sure you are parsing a kicad_pcb file
      if ( $first_element and lc($element) ne "kicad_pcb" )
      {
          warn "Error - this is not a kicad_pcb file\n";
          exit 1;
      }
      print " $element";
    }
    $txt =~ s/^\s+//s; #remove the trailing whith space
  }
  my $key = pop(@breadcrum);
  if ($key eq "setup") { &move_axis; }
  print " )";
  return;
}
 
sub modify_key_entry
{
  ($element,$key,$level) = @_;

  #if ($change_hash{$breadcurm[0]}{$key} eq $level); #should think about somehing clever...

  #SWITCH: for 
  if    ($breadcrum[0] eq "setup")  { return &parse_setup($element,$key,$level);}
  elsif ($breadcrum[0] eq "module") { return &parse_module($element,$key,$level);}
  else { return 0; }
}

sub move_axis
{
  #my @AXIS;
  if ($option_hash{nx} || $option_hash{ny} || $option_hash{ox} || $option_hash{oy}) 
  {
     #calculate global offsets
    if ($option_hash{nx}) { $values_hash{offset}{X}=$option_hash{nx}-$values_hash{setup}{aux_axis_origin}{X}; }
    if ($option_hash{ny}) { $values_hash{offset}{Y}=$option_hash{ny}-$values_hash{setup}{aux_axis_origin}{Y}; }
    if ($option_hash{ox} != 0) { $values_hash{offset}{X}=$option_hash{ox}; }
    if ($option_hash{oy} != 0) { $values_hash{offset}{Y}=$option_hash{oy}; }
  }

  if ( $option_hash{aux_axis} )
  {
    my $AUX_X_NEW = $values_hash{setup}{aux_axis_origin}{X};
    my $AUX_Y_NEW = $values_hash{setup}{aux_axis_origin}{Y};
    my $GRID_X_OFF = $values_hash{setup}{grid_origin}{X} - $values_hash{setup}{aux_axis_origin}{X};
    my $GRID_Y_OFF = $values_hash{setup}{grid_origin}{Y} - $values_hash{setup}{aux_axis_origin}{Y};

    # move to new locations
    if ($option_hash{nx}) 
    { 
      $AUX_X_NEW = $option_hash{nx}; 
      $GRID_X_NEW = $AUX_X_NEW +$GRID_X_OFF; 
    }
    if ($option_hash{ny}) 
    { 
      $AUX_Y_NEW = $option_hash{ny}; 
      $GRID_Y_NEW = $AUX_Y_NEW +$GRID_Y_OFF; 
    }

    # offset to new locations
    if ($option_hash{ox} != 0) 
    { 
      $AUX_X_NEW = $option_hash{ox} + $values_hash{setup}{aux_axis_origin}{X};  
      $GRID_X_NEW = $AUX_X_NEW + $GRID_X_OFF; 
    }
    if ($option_hash{oy} != 0) 
    { 
      $AUX_Y_NEW = $option_hash{oy} + $values_hash{setup}{aux_axis_origin}{Y};  
      $GRID_Y_NEW = $AUX_Y_NEW + $GRID_Y_OFF; 
    }

    if ( $remove_hash{section}{setup} eq "false" )
    {
      print "\n";
      print "  ( aux_axis_origin $AUX_X_NEW $AUX_Y_NEW )\n";
      print "  ( grid_origin $GRID_X_NEW $GRID_Y_NEW )\n";
    }
  }
}

sub parse_setup
{
  my ($element,$key,$level) = @_;
  my $line_replaced = 0;
  #print "-- $key.$level --";
  if ($change_hash{setup}{$key} eq $level )
  {
    $change_hash{setup}{$key} = $element;
    if (($key eq "aux_axis_origin") or ($key eq "grid_origin"))
    {
      if ($element =~ m/\((\S+)\s+(\S+)\)/ ) # remove the parenthesis from $elecment to make a it 
      {
        $values_hash{$breadcrum[0]}{$key}{X}=$1;
        $values_hash{$breadcrum[0]}{$key}{Y}=$2;
        if ($option_hash{aux_axis})
        {
          # New grid origin will be generated at the end of this section, so don't print this line
          $line_replaced = 1;
        }
      }
    }
  }
  if ((lc($remove_hash{section}{$breadcrum[0]}) eq "true") ) 
  { 
   # test if we can skip printing elements in this section
    $line_replaced = 1; 
  }
  return $line_replaced;
}

sub parse_module
{
  my ($element,$key,$level) = @_;
  # test if module location X and Y
  if (($level == 2) and ($key eq "at"))
  {
    if ($element =~ m/\((\S+)\s+(\S+)\s?(\S+)?\)/) # $element="($X $Y $R)"
    { 
       my $X=$1 + $values_hash{offset}{X};
       my $Y=$2 + $values_hash{offset}{Y};
       my $R=$3;
       # modify the X,Y and R based on user inputs
       if ($R)
       {
         &pad_white_space($level);
         print "( at $X $Y $R )";
       }
       else
       {
         &pad_white_space($level);
         print "( at $X $Y )";
       }
       return 1;
    }
    else
    {
       warn "\n------->Format ERROR<-------\n";
       exit;
    }
  }
  elsif (($level == 2) and ($key eq "fp_text"))
  {
     $element =~ s/^\(reference\s+(\S?)(\d+)/(/ and $ref = $1 and $val = $2; #remove the value from the begining of $element and place it into $count
     if ( $option{base} && $option{reference} )
     {
       $val = ($val - $option{base}) + $option{reference};
     }
     print "\n   ( $key reference $ref$val";
     &parse_S_expression($element,$key,$level); #recursive loop
     return 1;
  }
  else
  {
    return 0;
  }
}

# ------ Begine Program ------
&check_options();
my $text;
open ( BRD, "<$option_hash{file}") or die("$usage \n-E- ha ha could not open \'$option_hash{file}\', exiting is a bad way...");

while (<BRD>)
{
  my $new_line = $_;
  chomp;
  $text = "$text $new_line";
}
close (BRD);

print "(";
&parse_S_expression($text,"filename",0);
print "\n)";
