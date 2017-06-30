#!/usr/bin/perl

use Getopt::Long;
use lib "$ENV{HOME}/Dropbox/bin/perl";
use svg_gen;

my $input_file;
my $output_file;
my $debug;
my $verbose;
my $help;
my $SVG_TEXT;
my $SVG_LINES;
my @cords;
my %SVG_HASH;
my %XFORM_HASH;
my %FILL_HASH;

&check_options;
&build_SVG_HASH;
my ($Xoff,$Yoff,$Xmax,$Ymax) = &find_limits($input_file,"20");
&gen_symbols($input_file,$output_file) if ($output_file);
exit;

sub build_SVG_HASH
{
	$SVG_HASH{title} = $0;
	$SVG_HASH{id} = "group_id";
	$SVG_HASH{link} = "http://www.nilar.com/wp-content/themes/nilar/images/logo-nilar.png";
	$SVG_HASH{text} = "text to display";
	$SVG_HASH{align} = "center";
	$SVG_HASH{rotate} = 0;
	$SVG_HASH{font} = "courier"; #default is Sans
	$SVG_HASH{font_size} = 10; #note need to fix the px fixed size
	$SVG_HASH{font_color} = "#000000";
	$SVG_HASH{shape_size} = 10;
	$SVG_HASH{fill_color} = "#555500";
	$SVG_HASH{line_color} = "#000000";
	$SVG_HASH{line_width} = 1; #always in px
	$SVG_HASH{stroke_opacity} = 1;
	$SVG_HASH{cords} = 0;  #where @array = [x0 y0;x1 y1;x2 y2]
	$SVG_HASH{transparent} = 0;
	$SVG_HASH{height} = 11;
	$SVG_HASH{width} = 8.5;
	$SVG_HASH{x} = 0;
	$SVG_HASH{x1} = 0;
	$SVG_HASH{x2} = 0;
	$SVG_HASH{y} = 0;
	$SVG_HASH{y1} = 0;
	$SVG_HASH{y2} = 0;
	$SVG_HASH{units} = "px";

	$XFORM_HASH{L}="left";
	$XFORM_HASH{R}="right";
	$XFORM_HASH{C}="center";
	$XFORM_HASH{H}=0;
	$XFORM_HASH{V}=90;

	$FILL_HASH{Y}="#CC00CC";
	$FILL_HASH{N}="none";
	$FILL_HASH{B}="#CCCC00";
	$FILL_HASH{F}="#888888";

	$OPACITY_HASH{Y}=1;
	$OPACITY_HASH{N}=0;
}

sub find_limits
{
  my ($sym_file,$pad) = @_;
  my $DEF;
  my $DEF_active = 0;
  my $DRAW_active = 0;
  my $FPLIST_active = 0;

  warn "opening file $sym_file\n" if ($verbose);
  open ( SYM , "<$sym_file" ) or &end_program("could not open file $sym_file");
  while (<SYM>)
  {
    my $new_line = $_;
    chomp $new_line;
    if ( $new_line =~ m/^DEF (.*)/)
    {
      (undef, undef, undef, $text_offset, $draw_pinnumber, $draw_pinname, undef, undef, undef) = split(/\s+/,$1);
      $DEF_active = 1;
    }
    elsif ( $new_line =~ m/^ENDDEF/)      { $DEF_active = 0;}
    elsif ( $new_line =~ m/^DRAW/)        { $DRAW_active = 1;}
    elsif ( $new_line =~ m/^ENDDRAW/)     { $DRAW_active = 0;}
    elsif ( $new_line =~ m/^\$FPLIST/)    { $FPLIST_active = 1;}
    elsif ( $new_line =~ m/^\$ENDFPLIST/) { $FPLIST_active = 0;}
    elsif ($DEF_active or $DRAW_active and (!$FPLIST_active))
    {
      if ( $new_line =~ m/^F1 (.*)/ )
      {
        my ($reference, $posx, $posy, $text_size, $text_orient, $visibility, $htext_justify, $vtext_justify) = split(/\s+/,$1);
	$reference =~ s/\"//g;
	($posx);
	($posy)+$text_size;
	my $len_of_text = length($reference)*$text_size*.7;

	if ($text_orient eq "V")
	{
		if ($htext_justify eq "L")
		{
			$max_y = &find_max($max_y,$posy);
			$min_y = &find_min($min_y,$posy-$len_of_text);
		}
		elsif ($htext_justify eq "R")
		{
			$max_y = &find_max($max_y,$posy+$len_of_text);
			$min_y = &find_min($min_y,$posy);
		}
		elsif ($htext_justify eq "C")
		{
			$max_y = &find_max($max_y,$posy+$len_of_text/2);
			$min_y = &find_min($min_y,$posy-$len_of_text/2);
		}

		if ($vtext_justify eq "T") # x=x-text_size & x=x
		{
			$max_x = &find_max($max_x,$posx+$text_size);
			$min_x = &find_min($min_x,$posx);
		}
		elsif ($vtext_justify eq "B") #x=x+text_size & x=x
		{
			$max_x = &find_max($max_x,$posx);
			$min_x = &find_min($min_x,$posx-$text_size);
		}
		elsif ($vtext_justify eq "C")	# x=1/2 y=1/2
		{
			$max_x = &find_max($max_x,$posx+$text_size/2);
			$min_x = &find_min($min_x,$posx-$text_size/2);
		}
	}
	elsif ($text_orient eq "H") 	# x=text_size*num_of_char y=text_size
	{
		if ($htext_justify eq "L")
		{
			$max_x = &find_max($max_x,$posx+$len_of_text);
			$min_x = &find_min($min_x,$posx);
		}
		elsif ($htext_justify eq "R")
		{
			$max_x = &find_max($max_x,$posx);
			$min_x = &find_min($min_x,$posx-$len_of_text);
		}
		elsif ($htext_justify eq "C")	# x=1/2 y=1/2
		{
			$max_x = &find_max($max_x,$posx+$len_of_text/2);
			$min_x = &find_min($min_x,$posx-$len_of_text/2);
		}

		if ($vtext_justify eq "T")
		{
			$max_y = &find_max($max_y,$posy+$text_size);
			$min_y = &find_min($min_y,$posy);
		}
		elsif ($vtext_justify eq "B")
		{
			$max_y = &find_max($max_y,$posy);
			$min_y = &find_min($min_y,$posy-$text_size);
		}
		elsif ($vtext_justify eq "C")	# x=1/2 y=1/2
		{
			$max_y = &find_max($max_y,$posy+$text_size/2);
			$min_y = &find_min($min_y,$posy-$text_size/2);
		}
	}
      }
      if ( $new_line =~ m/^A (.*)/ ) #A=Arc
      {
        my ($posx, $posy, $radius, undef, undef, undef, undef, undef, undef, $startx, $starty, $endx, $endy) = split(/\s+/,$1);
	$max_x = &find_max($max_x,$startx);
	$max_y = &find_max($max_y,$starty);
	$max_x = &find_max($max_x,$endx);
	$max_y = &find_max($max_y,$endy);
	$min_x = &find_min($min_x,$startx);
	$min_y = &find_min($min_y,$starty);
	$min_x = &find_min($min_x,$endx);
	$min_y = &find_min($min_y,$endy);
      }
      elsif ( $new_line =~ m/^C (.*)/ ) #C=Circle
      {
        my ($posx, $posy, $radius, undef, undef, undef, undef) = split(/\s+/,$1);
	$max_x = &find_max($max_x,$posx+$radius);
	$max_y = &find_max($max_y,$posy+$radius);
	$min_x = &find_max($min_x,$posx-$radius);
	$min_y = &find_max($min_y,$posy-$radius);
      }
      elsif ( $new_line =~ m/^P (\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)\s+(\S+)/ ) #P=Polyline
      {
        my (@cords) = split(/\s+/,$5); # Note there are 2 spaces between x,y pairs
	my $count = 1;
	foreach my $xy_pair (@cords)
	{
	  if ($count % 2)
	  {
          	$max_y = &find_max($max_y,$xy_pair);
          	$min_y = &find_max($min_y,$xy_pair);
	  }
	  else
	  {
          	$max_x = &find_max($max_x,$xy_pair);
          	$min_x = &find_max($min_x,$xy_pair);
	  }
	  $count++;
	}
      }
      elsif ( $new_line =~ m/^S (.*)/ ) #S=Rectangle
      {
        my ($startx, $starty, $endx, $endy, undef, undef, undef, undef) = split(/\s+/,$1);
	$max_x = &find_max($max_x,$startx);
	$max_y = &find_max($max_y,$starty);
	$max_x = &find_max($max_x,$endx);
	$max_y = &find_max($max_y,$endy);
	$min_x = &find_min($min_x,$startx);
	$min_y = &find_min($min_y,$starty);
	$min_x = &find_min($min_x,$endx);
	$min_y = &find_min($min_y,$endy);
      }
      elsif ( $new_line =~ m/^X (.*)/ ) #X=Pin
      {
        my (undef, undef, $posx, $posy, $length, $direction, undef, undef, undef, undef, undef, undef) = split(/\s+/,$1);
	
	if    ($direction eq "U") {$max_y = &find_max($max_y,$posy + $length);}
	elsif ($direction eq "D") {$min_y = &find_min($min_y,$posy - $length);}
	elsif ($direction eq "L") {$max_x = &find_max($max_x,$posx + $length);}
	elsif ($direction eq "R") {$min_x = &find_min($min_x,$posx + $length);}
	$max_x = &find_max($max_x,$posx);
	$max_y = &find_max($max_y,$posy);
	$min_x = &find_min($min_x,$posx);
	$min_y = &find_min($min_y,$posy);
      }
    }
  }
  close (SYM);
  warn "$min_x,$min_y .. $max_x,$max_y\n" if ($debug);

  my $Xoff = -$min_x;
  my $Yoff = -$min_y;
  my $Xmax = $max_x + $Xoff;
  my $Ymax = $max_y + $Yoff;
  if ($pad =~ m/(\S+)%/)
  {
    my $percent = $1/100;
    my $padx = $percent*($Xmax - $Xoff)/2;
    my $pady = $percent*($Ymax - $Yoff)/2;
    if ($padx > $pady)
    {
      $pad = $padx;
    }
    else
    {
      $pad = $pady;
    }
  }
  return ($Xoff+$pad,$Yoff+$pad,$Xmax+$pad*2,$Ymax+$pad*2);
}

sub gen_symbols
{
  my ($sym_file,$svg_file) = @_;
  my $DEF;
  my $DEF_active = 0;
  my $DRAW_active = 0;
  my $FPLIST_active = 0;
  my $EESchema;
  my ($PART, $TEXT_OFF, $DRAW_NUM, $DRAW_NAME);
  print "($Xoff,$Yoff,$Xmax,$Ymax)";
  my $ratio = ($Xmax-$Xoff)/($Ymax-$Yoff);
  $SVG_HASH{width} = $ratio;
  $SVG_HASH{height} = 1;
  $SVG_HASH{units} = "in";
  $SVG_HASH{x1vb} = 0;
  $SVG_HASH{y1vb} = 0;
  $SVG_HASH{x2vb} = $Xmax;
  $SVG_HASH{y2vb} = $Ymax;
  my $svg_header  = &svg_gen::svg_header(\%SVG_HASH);
  $SVG_HASH{units} = "";

  warn "opening file $sym_file\n" if ($verbose);
  open ( SYM , "<$sym_file" ) or &end_program("could not open file $sym_file");
  while (<SYM>)
  {
    my $new_line = $_;
    chomp $new_line;
    if ( $new_line =~ m/^EESchema.*/)
    {
       if (!$EESchema)
       {
          $EESchema = $new_line;
       }
    }
    elsif ( $new_line =~ m/^DEF (.*)/)
    {
      ($PART, undef, undef, $TEXT_OFF, $DRAW_NUM, $DRAW_NAME, undef, undef, undef) = split(/\s+/,$1);
      $DEF_active = 1;
      #push info to an array or hash
    }
    elsif ( $new_line =~ m/^ENDDEF/)
    {
      # pop info out of array or hash and generatre SVG file
      my $svg_output = $svg_header . $SVG_TEXT . $SVG_LINES . &svg_gen::svg_footer();
      warn "Creating file $svg_file\n" if ($verbose);
      open  (SVG , ">$svg_file" ) or &end_program("could not open file $svg_file");
      print SVG $svg_output;
      close (SVG);
      $DEF_active = 0;
    }
    # we really don't care about some of the information in the files so we will only parse what is needed
    # F0 reference posx posy text_size text_orient visibility htext_justify vtext_justify
    # F1 name posx posy text_size text_orient visibility htext_justify vtext_justify
    # Ignore FPLIST to ENDFPLIST
    # DRAW - this flags the important stuff!
    #  A posx posy radius start_angle end_angle unit convert thickness fill startx starty endx endy
    #  C posx posy radius unit convert thickness fill
    #  P point_count unit convert thickness (posx posy)* fill
    #  S startx starty endx endy unit convert thickness fill
    #  T direction posx posy text_size text_type unit convert text text_italic text_hjustify text_vjustify
    #  X name num posx posy length direction name_text_size num_text_size unit convert electrical_type pin_type
    # ENDDRAW - this flags the important stuff!
    # push info to an array or hash
    elsif ( $new_line =~ m/^DRAW/)        { $DRAW_active = 1;}
    elsif ( $new_line =~ m/^ENDDRAW/)     { $DRAW_active = 0;}
    elsif ( $new_line =~ m/^\$FPLIST/)    { $FPLIST_active = 1;}
    elsif ( $new_line =~ m/^\$ENDFPLIST/) { $FPLIST_active = 0;}
    elsif ($DEF_active or $DRAW_active and (!$FPLIST_active))
    {
      if ( $new_line =~ m/^F1 (.*)/ )
      {
        my ($reference, $posx, $posy, $text_size, $text_orient, $visibility, $htext_justify, $vtext_justify) = split(/\s+/,$1);
	$reference =~ s/\"//g;
	$SVG_HASH{x} = &xform_x($posx);
	$SVG_HASH{y} = &xform_y($posy)+$text_size;
	if ($vtext_justify eq "T" and $text_orient eq "H")
	{
		$SVG_HASH{y} = &xform_y($posy);
	}
	elsif ($vtext_justify eq "C" and $text_orient eq "H")
	{
		$SVG_HASH{y} = &xform_y($posy)+$text_size/2;
	}
	elsif ($vtext_justify eq "B" and $text_orient eq "V")
	{
		$SVG_HASH{x} = &xform_x($posx)+$text_size;
	}
	elsif ($vtext_justify eq "C" and $text_orient eq "V")
	{
		$SVG_HASH{x} = &xform_x($posx)+$text_size/2;
	}
	$SVG_HASH{align} = $XFORM_HASH{$htext_justify};
	$SVG_HASH{rotate} = $XFORM_HASH{$text_orient};
	$SVG_HASH{font_size} = $text_size;
	$SVG_HASH{text} = $reference;
	$SVG_TEXT .= &svg_gen::svg_text(\%SVG_HASH);
      }
      #elsif ( $new_line =~ m/^F1 (.*)/ ) { my ($name, $posx, $posy, $text_size, $text_orient, $visibility, $htext_justify, $vtext_justify) = split(/\s+/,$1); }
      elsif ( $new_line =~ m/^A (.*)/ ) #A=Arc
      {
	#TODO  might need to look at xpos and ypos in ref to start and end to determine if x1,y1 and x2,y2 should be swapped
        my ($xpos, $ypos, $radius, undef, undef, undef, undef, $thickness, $fill, $startx, $starty, $endx, $endy) = split(/\s+/,$1);
	$SVG_HASH{x2} = &xform_x($startx);
	$SVG_HASH{y2} = &xform_y($starty);
	$SVG_HASH{x1} = &xform_x($endx);
	$SVG_HASH{y1} = &xform_y($endy);
	$SVG_HASH{radius} = $radius;
	$SVG_HASH{line_width} = &set_width($thickness);
	$SVG_HASH{fill_color} = $FILL_HASH{$fill};
	$SVG_HASH{fill_opacity} = $OPACITY_HASH{$fill};
	$SVG_LINES .= &svg_gen::svg_arc(\%SVG_HASH);
      }
      elsif ( $new_line =~ m/^C (.*)/ ) #C=Circle
      {
        my ($posx, $posy, $radius, undef, undef, $thickness, $fill) = split(/\s+/,$1);
	$SVG_HASH{x2} = &xform_x($posx);
	$SVG_HASH{y2} = &xform_y($posy);
	$SVG_HASH{shape_size} = $radius;
	$SVG_HASH{fill_color} = $FILL_HASH{$fill};
	$SVG_HASH{fill_opacity} = $OPACITY_HASH{$fill};
	$SVG_HASH{line_width} = &set_width($thickness);
	$SVG_LINES .= &svg_gen::svg_circle(\%SVG_HASH);
      }
      elsif ( $new_line =~ m/^P (\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*)\s+(\S+)/ ) #P=Polyline
      {
        my ($thickness) = $4;
        my ($cords) = $5;
        my ($fill) = $6;
	my $points;
	my (@temp_array) = split(/\s+/,$cords);
	my $count = 1;
	foreach my $xy_pair (@temp_array)
	{
	  if ($count % 2)
	  {
		$xy_pair = &xform_x($xy_pair);
		$points .= "$xy_pair,";
	  }
	  else
	  {
		$xy_pair = &xform_y($xy_pair);
		$points .= "$xy_pair ";
	  }
	  $count++;
	}
	$points =~ s/ $//;
	$SVG_HASH{cords} = $points;
	$SVG_HASH{fill_color}=$FILL_HASH{$fill};
	$SVG_HASH{line_width} = &set_width($thickness);
	$SVG_LINES .= &svg_gen::svg_polyline(\%SVG_HASH);
      }
      elsif ( $new_line =~ m/^S (.*)/ ) #S=Rectangle
      {
        my ($startx, $starty, $endx, $endy, undef, undef, $thickness, $fill) = split(/\s+/,$1);
	$SVG_HASH{x1} = &xform_x($startx);
	$SVG_HASH{y1} = &xform_y($starty);
	$SVG_HASH{x2} = &xform_x($endx);
	$SVG_HASH{y2} = &xform_y($endy);
	$SVG_HASH{line_width} = &set_width($thickness);
	$SVG_HASH{fill_color}=$FILL_HASH{$fill};
	
	$SVG_LINES .= &svg_gen::svg_rectangle(\%SVG_HASH);
      }
      elsif ( $new_line =~ m/^T (.*)/ ) #T=Text
      {
        my ($direction, $posx, $posy, $text_size, $text_type, $unit, $convert, $text, $text_italic, $text_hjustify, $text_vjustify) = split(/\s+/,$1);
	$text =~ s/\"//g;
	$SVG_HASH{x} = &xform_x($posx);
	$SVG_HASH{y} = &xform_y($posy);
	$SVG_HASH{align} = $XFORM_HASH{$text_hjustify};
	$SVG_HASH{rotate} = $direction/10;
	$SVG_HASH{font_size} = $text_size;
	$SVG_HASH{text} = $text;
	
	$SVG_TEXT .= &svg_gen::svg_text(\%SVG_HASH);
      }
      elsif ( $new_line =~ m/^X (.*)/ ) #X=Pin
      {
        my ($name, $num, $posx, $posy, $length, $direction, $name_text_size, $num_text_size, $unit, undef, undef, $pin_type) = split(/\s+/,$1);
	if ($unit == 1)
        {
          $name =~ s/\"//g;
          $num =~ s/\"//g;
          $SVG_HASH{x} = &xform_x($posx);
          $SVG_HASH{y} = &xform_y($posy);
          $SVG_HASH{x1} = $SVG_HASH{x};
          $SVG_HASH{y1} = $SVG_HASH{y};
          $SVG_HASH{x2} = $SVG_HASH{x};
          $SVG_HASH{y2} = $SVG_HASH{y};
          $SVG_HASH{align} = $XFORM_HASH{$text_hjustify};
          $SVG_HASH{shape_size} = 6;
          $SVG_HASH{line_width} = 1;
          $SVG_HASH{fill_color} = "#FF0000";
          $SVG_HASH{font_color} = "#000000";
          #my $add_buble = undef;
          
          if ($pin_type eq "N") # N=Not Visible
          {
          	$SVG_HASH{line_color} = "#000000";
          	$SVG_HASH{font_color} = "#888888";
          	$SVG_HASH{fill_color} = "#888888";
          }
          #elsif ($pin_type eq "I") # I=Invert (hollow circle)
          #{
          	#$add_buble = 1;
          #}
          #elsif ($pin_type eq "C") # C=Clock
          #elsif ($pin_type eq "IC") # IC=Inverted Clock
          #elsif ($pin_type eq "L") # L=Low In (IEEE)
          #elsif ($pin_type eq "CL") # CL=Clock Low
          #elsif ($pin_type eq "V") # V=Low Out (IEEE)
          #elsif ($pin_type eq "F") # F=Falling Edge
          #elsif ($pin_type eq "NX") # NX=Non Logic
          #elsif (!$pin_type) # Optional (when not specified uses Line graphic style).
          
          
          $SVG_LINES .= &svg_gen::svg_circle(\%SVG_HASH);
          if ($pin_type ne "N")
          {
          	if    ($direction eq "U") 
          	{
          		$SVG_HASH{align}="right";
          		$SVG_HASH{rotate} = 90;
          		$SVG_HASH{y1} = $SVG_HASH{y} - $SVG_HASH{shape_size};
          		$SVG_HASH{y2} = $SVG_HASH{y} - $length;
          		$SVG_LINES .= &svg_gen::svg_line(\%SVG_HASH);
          		#if bubble input
          		#if clock input
          		#if falling input
          		#if rising input
          	}
          	elsif ($direction eq "D") 
          	{
          		$SVG_HASH{align}="left";
          		$SVG_HASH{rotate} = 90;
          		$SVG_HASH{y1} = $SVG_HASH{y} + $SVG_HASH{shape_size};
          		$SVG_HASH{y2} = $SVG_HASH{y} + $length;
          		$SVG_LINES .= &svg_gen::svg_line(\%SVG_HASH);
          	}
          	elsif ($direction eq "L") 
          	{
          		$SVG_HASH{align}="right";
          		$SVG_HASH{rotate} = 0;
          		$SVG_HASH{x1} = $SVG_HASH{x} - $SVG_HASH{shape_size};
          		$SVG_HASH{x2} = $SVG_HASH{x} - $length;
          		$SVG_LINES .= &svg_gen::svg_line(\%SVG_HASH);
          	}
          	elsif ($direction eq "R") 
          	{
          		$SVG_HASH{align}="left";
          		$SVG_HASH{rotate} = 0;
          		$SVG_HASH{x1} = $SVG_HASH{x} + $SVG_HASH{shape_size};
          		$SVG_HASH{x2} = $SVG_HASH{x} + $length;
          		$SVG_LINES .= &svg_gen::svg_line(\%SVG_HASH);
          	}
          }
          
          
          if ($DRAW_NAME eq "Y") # ----------------- Draw Pin Name
          {
          	if ($name ne "~")
          	{
          		if ($name =~ m/~/)
          		{
          			#add a bar over the name;
          			$name =~ s/~//g;
          		}
          		$SVG_HASH{font_size} = $name_text_size;
          		$SVG_HASH{text} = $name;
          
          		if    ($direction eq "U" or $direction eq "D") 
          		{ 	
          			if ($TEXT_OFF)
          			{
          				$SVG_HASH{x} = $SVG_HASH{x} - ($num_text_size/3);
          				$SVG_HASH{y} = $SVG_HASH{y2} - $TEXT_OFF if ($direction eq "U");
          				$SVG_HASH{y} = $SVG_HASH{y2} + $TEXT_OFF if ($direction eq "D");
          				$SVG_HASH{align}="right" if ($direction eq "U");
          				$SVG_HASH{align}="left" if ($direction eq "D");
          			}
          			else
          			{
          				$SVG_HASH{x} = $SVG_HASH{x} + 3;
          				$SVG_HASH{align}="center";
          			}
          		}
          		elsif ($direction eq "L" or $direction eq "R") 
          		{
          			if ($TEXT_OFF) # if there is an offset, then the name is at the end of the pin
          			{
          				$SVG_HASH{y} = $SVG_HASH{y2} + $name_text_size/3; # this puts it in the middle
          				$SVG_HASH{x} = $SVG_HASH{x2} - ($TEXT_OFF) if ($direction eq "L");
          				$SVG_HASH{x} = $SVG_HASH{x2} + ($TEXT_OFF) if ($direction eq "R");
          				$SVG_HASH{align}="left" if ($direction eq "R");
          				$SVG_HASH{align}="right" if ($direction eq "L");
          			}
          			else
          			{
          				$SVG_HASH{align}="center";
          				$SVG_HASH{y} = $SVG_HASH{y} - 3;
          			}
          		}
          		$SVG_TEXT .= &svg_gen::svg_text(\%SVG_HASH);
          	}
          }
          
          if ($DRAW_NUM eq "Y") # ----------------- Draw Pin Number
          {
          	$SVG_HASH{font_size} = $num_text_size;
          	$SVG_HASH{text} = $num;
          	$SVG_HASH{x} = &xform_x($posx);
          	$SVG_HASH{y} = &xform_y($posy);
          	$SVG_HASH{align}="center";
          	if    ($direction eq "U" or $direction eq "D") 
          	{
          		$SVG_HASH{y} = $SVG_HASH{y} - $length/2 if ($direction eq "U");
          		$SVG_HASH{y} = $SVG_HASH{y} + $length/2 if ($direction eq "D");
          		if ($TEXT_OFF) # if there is an offset, then the name is at the end of the pin
          		{
          			$SVG_HASH{x} = $SVG_HASH{x} + 3;# if ($direction eq "D");
          		}
          		else
          		{
          			$SVG_HASH{x} = $SVG_HASH{x} - ($num_text_size);# if ($direction eq "U");
          		}
          	}
          	elsif ($direction eq "L" or $direction eq "R")
          	{
          		$SVG_HASH{x} = $SVG_HASH{x} - $length/2 if ($direction eq "L");
          		$SVG_HASH{x} = $SVG_HASH{x} + $length/2 if ($direction eq "R");
          		if ($TEXT_OFF) # if there is an offset, then the name is at the end of the pin
          		{
          			$SVG_HASH{y} = $SVG_HASH{y} - 3;
          		}
          		else
          		{
          			$SVG_HASH{y} = $SVG_HASH{y} + $num_text_size;
          		}
          	}
          	#my ($tx,$ty) = ($SVG_HASH{x2},$SVG_HASH{y2});
          	#$SVG_HASH{x2} = $SVG_HASH{x};
          	#$SVG_HASH{y2} = $SVG_HASH{y};
          	#$SVG_LINES .= &svg_gen::svg_circle(\%SVG_HASH);
          	#($SVG_HASH{x2},$SVG_HASH{y2}) = ($tx,$ty);
          	$SVG_TEXT .= &svg_gen::svg_text(\%SVG_HASH);
          }
        }
      }
    }
  }
  close (SYM);
}

# -------------- House Keeping ----------------------

sub check_options
{
  my $help;
  GetOptions(
    "help" => \$help,		# flag/boolean (0=false|1=true)
    "file=s" => \$input_file,	# string
    "svg=s" => \$output_file,	# string
    "scale=f" => \$scale,	# float
    "xdim=s" => \$xdim,		# float + string
    "ydim=s" => \$ydim,		# float + string
    "debug=i"   => \$debug,	# integer
    "verbose"  => \$verbose);	# flag/boolean (0=false|1=true)

  if ($help) {&print_help}

  if ($input_file eq "")
  {
    warn "ERROR - The option file is require but empty, please read the help.\n\n";
    $help = 1;
  }

  if ($output_file eq "")
  {
    warn "ERROR - The option svg is require but empty, please read the help.\n\n";
    $help = 1;
  }

  if ($scale and ($xdim or $ydim))
  {
    warn "ERROR - The option scale, xdim, and ydim can not be used together, please read the help.\n\n";
    $help = 1;
  }
  elsif ($xdim and $ydim)
  {
    warn "ERROR - The option xdim and ydim can not be used together, please read the help.\n\n";
    $help = 1;
  }
  
  if ($verbose)
  {
    warn "VERBOSE - $0 Options sellected are as follows:\n";
    warn "  help = requested\n" if ($help);
    warn "  file = $input_file\n" if ($input_file);
    warn "  svg = $output_file\n" if ($output_file);
    warn "  scale = $scale\n" if ($scale);
    warn "  xdim = $xdim\n" if ($xdim);
    warn "  ydim = $ydim\n" if ($ydim);
    warn "  debug = $debug\n" if ($debug);
    warn "  verbose = $verbose\n\n" if ($verbose);
  }
  if ($help) {&print_help}
}

sub print_help
{
  warn "
USAGE:
$0 -file <filename.sym> -svg <filename.svg> OPTIONS

OPTIONS:

    -help or -h      this message
    -file or -f      KiCad symbol input file .sym format (may require a full path)
    -svg             SVG output file (may require a full path)

  Only one of the following options can be used at a time
    -scale           Ratio to scale SVG Symbols (note values in sym file are in mils, 200mils = 0.2 inches)
    -xdim            This will scale the SVG in the X dimention to xdim (include mm,px,in)
    -ydim            This will scale the SVG in the Y dimention to ydim (include mm,px,in)

  Extras if things dont seem to be working correctly...
    -debug or -d     integer number if things don't go your way (=1) goes to STDERR
    -verbose or -v   flow information with no data and goes to STDERR\n";
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

sub print_sym_format
{
  print "
    DEF name reference unused text_offset draw_pinnumber draw_pinname unit_count units_locked option_flag
	name = component name in library (74LS02 ...)
	reference = Reference ( U, R, IC .., which become U3, U8, R1, R45, IC4...)
	unused = 0 (reserved)
	text_offset = offset for pin name position
	draw_pinnumber = Y (display pin number) or N (do not display pin number).
	draw_pinname = Y (display pin name) or N (do not display pin name).
	unit_count = Number of part ( or section) in a component package. Limit is 26 (shown as chars form A to Z).
	units_locked = = L (units are not identical and cannot be swapped) or F (units are identical and therefore can be swapped) (Used only if unit_count > 1)
	option_flag = N (normal) or P (component type power)
    F0 reference posx posy text_size text_orient visibility htext_justify vtext_justify
    F1 name posx posy text_size text_orient visibility htext_justify vtext_justify
    F2 .*
    F3 .*
	reference = Reference ( U, R, IC .., which become U3, U8, R1, R45, IC4...)
	name = component name in library (74LS02 ...)
	posx, posy = position of the text label
	text_size = Size of the displayed text
	text_orient = Displayed text orientation 
		V=Vertical
		H=Horizontal(default)
	visible = Is label displayed 
		I=Invisible
		V=Visible(default)
	htext_justify = Horizontal text justify 
		L=Left
		R=Right
		C=Centre(default)
	vtext_justify = Vertical text justify 
		T=Top
		B=Bottom
		C=Centre(default)
    ALIAS name1 name2 name3 fields list
    DRAW
    	A=Arc
    	C=Circle
    	P=Polyline
    	S=Rectangle
    	T=Text
    	X=Pin
    
    A posx posy radius start_angle end_angle unit convert thickness fill startx starty endx endy
    	posx, posy = centre of the circle part of which is the arc
    	radius = radius of the lost arc
    	start_angle = start angle of the arc in tenths of degrees
    	end_angle = end angle of the arc in tenths of degrees
    	startx, starty = coordiantes of the start of the arc
    	endx, endy = coordinates of the end of the arc
    C posx posy radius unit convert thickness fill
    	posx, posy = centre of the circle
    	radius = radius of the circle
	thickness = line thickness
    
    The polyline has a series of points. It need not described a closed shape i.e. a polygon. To do this make the first pair the same as the last pair.
    
    P point_count unit convert thickness (posx posy)* fill
    	point_count = no. of coordinate pairs. posx and posy are repaeated these many times.
	posx posy groups are seperated by 2 spaces, where posx and posy are seperatred by only one space
                     x  xx  x  xx  x
		EX x1 y1  x2 y2  x3 y3
	thickness = line thickness
	fill = fill the area
		N = No fill
		F = Forground fill (line color)
		B = Background fill
    
    S startx starty endx endy unit convert thickness fill
    	startx, starty = Starting corner of the rectangle
    	endx, endy = End corner of the rectangle
	thickness = line thickness
    
    T direction posx posy text_size text_type unit convert text text_italic text_hjustify text_vjustify
    	direction = Direction of text(0=Horizintal, 900=Vertical(default))
    	text_size = Size of the text
    	text_type = ???
    	text = Text to be displayed. All ~ characters are replaced with spaces.
    	text_italic = Italic or Normal
    	text_bold = 0 to normal 1 to bold
    	text_hjustify
    		C=Center
    		L=Left
    		R=Right
    	text_vjustify
    		C=Center
    		B=Bottom
    		T=Top
    X name num posx posy length direction name_text_size num_text_size unit convert electrical_type pin_type
    	name = name displayed on the pin
    	num = pin no. displayed on the pin
    	posx = Position X same units as the length
    	posy = Position Y same units as the length
    	length = length of pin
    	direction 
    		R for Right
    		L for left
    		U for Up
    		D for Down
    	name_text_size = Text size for the pin name
    	num_text_size = Text size for the pin number
      	convert = In case of variations in shape for units, each variation has a number. 
    		0 indicates no variations. 
    		For example, an inverter may have two variations - one with the bubble on the input and one on the output.
    	electrical_type = Elec. Type of pin 
    		I=Input
    		O=Output
    		B=Bidi
    		T=tristate
    		P=Passive
    		U=Unspecified
    		W=Power In
    		w=Power Out
    		C=Open Collector
    		E=Open Emitter
    		N=Not Connected
    	pin_type = Type of pin or Graphic Style 
    		N=Not Visible
    		I=Invert (hollow circle)
    		C=Clock
    		IC=Inverted Clock
    		L=Low In (IEEE)
    		CL=Clock Low
    		V=Low Out (IEEE)
    		F=Falling Edge
    		NX=Non Logic
    		Optional (when not specified uses Line graphic style).
    ENDDRAW
    ENDDEF
    
    Sub definitions:
      posx, posy = Position of the graphic element
      unit = unit no. in case of multiple units
      convert = In case of variations in shape for units, each variation has a number. 
    	0 indicates no variations. 
    	For example, an inverter may have two variations - one with the bubble on the input and one on the output.
      thickness = line thickness
      fill = fill colour (F=filled with foreground colour, f=filled with background colour, N=Not filled(default))
    ";
}

sub set_width
{
	my ($thickness) = @_;
 	if ($thickness)
	{
		return $thickness;
	}
	else
	{
		return 1;
	}
}

sub xform_x
{
	my ($x) = @_;
	glob 
	return ($x + $Xoff);
}

sub xform_y
{
	my ($y) = @_;
	return $Ymax - ($y + $Yoff);
}

sub find_max
{
	my ($old,$new) = @_;
	if ($old > $new)
	{
		return $old;
	}
	else
	{
		return $new;
	}
}
sub find_min
{
	my ($old,$new) = @_;
	if ($old < $new)
	{
		return $old;
	}
	else
	{
		return $new;
	}
}
