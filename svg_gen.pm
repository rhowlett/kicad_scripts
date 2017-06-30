#!/usr/bin/perl

#-------------------------------------------------------------------------------
# Created by Richard Howlett
# 2016/03/11
# simple SVG graphics generator
# Usage: 
#	use lib "$ENV{HOME}/Dropbox/bin/perl";
#	use svg_gen;
#	my %SVG_HASH;
#	$SVG_HASH{title} = "<svg title>";
#	$SVG_HASH{id} = "<group_id>";
#	$SVG_HASH{link} = "<path to image>";
#	$SVG_HASH{text} = "<text to display>";
#	$SVG_HASH{align} = "<left|start|center|middle|right|end>";
#	$SVG_HASH{rotate} = <float betwenn 0 and 360>;
#	$SVG_HASH{font} = <font name>; #default is Sans
#	$SVG_HASH{font_size} = <float>; #note need to fix the px fixed size
#	$SVG_HASH{font_color} = "<#000000 .. #FFFFFF>; #note need to fix the px fixed size
#	$SVG_HASH{shape_size} = <float>;
#	$SVG_HASH{fill_color} = "<#000000 .. #FFFFFF>";
#	$SVG_HASH{line_color} = "<#000000 .. #FFFFFF>";
#	$SVG_HASH{line_width} = <float>; #always in px
#	$SVG_HASH{cords} = @array;  #where @array = [x0 y0;x1 y1;x2 y2]
#	$SVG_HASH{transparent} = <float 0..1>;
#	$SVG_HASH{height} = <float>;
#	$SVG_HASH{width} = <float>;
#	$SVG_HASH{x1vb} = <integer>; # viewbox X1
#	$SVG_HASH{y1vb} = <integer>; # viewbox Y1
#	$SVG_HASH{x2vb} = <integer>; # viewbox X2
#	$SVG_HASH{y2vb} = <integer>; # viewbox Y2
#	$SVG_HASH{x} = <float>;
#	$SVG_HASH{x1} = <float>;
#	$SVG_HASH{x2} = <float>;
#	$SVG_HASH{y} = <float>;
#	$SVG_HASH{y1} = <float>;
#	$SVG_HASH{y2} = <float>;
#	$SVG_HASH{units} = "<mm|in|px>";
#
# 	$svg_text = svg_gen::svg_header(\%SVG_HASH);
#	$svg_text = svg_gen::svg_footer();
#	$svg_text = svg_gen::svg_text(\%SVG_HASH);
#	$svg_text = svg_gen::svg_image(\%SVG_HASH);
#	$svg_text = svg_gen::svg_rectangle(\%SVG_HASH);
#	$svg_text = svg_gen::svg_line(\%SVG_HASH);
#	$svg_text = svg_gen::svg_dotted_line(\%SVG_HASH);
#	$svg_text = svg_gen::svg_polyline(\%SVG_HASH);
#	$svg_text = svg_gen::svg_group_start(\%SVG_HASH);
#	$svg_text = svg_gen::svg_group_end();
#-------------------------------------------------------------------------------

package svg_gen;
use Exporter;

our @ISA= qw( Exporter );

# these can be exported.
our @EXPORT_OK = qw(svg_header,
	svg_footer,
	svg_text,
	svg_image,
	svg_rectangle,
	svg_line,
	svg_dotted_line,
	svg_polyline,
	svg_group_start,
	svg_group_end);

# these are exported by default.
our @EXPORT = qw(svg_header,
	svg_footer,
	svg_text,
	svg_image,
	svg_rectangle,
	svg_line,
	svg_dotted_line,
	svg_polyline,
	svg_group_start,
	svg_group_end);


sub svg_group_start 
{ 
	#my ($id) =@_ ;
	my $params = shift;
	my %H = %$params;
	my $svg = "<g id=\"$H{id}\">\n";
	return $svg;
}

sub svg_group_end 
{ 
	my $svg = "</g>\n";
	return $svg;
}

sub svg_header
{
	#my ($width,$height,$units) = @_;
	my $params = shift;
	my %H = %$params;
	#my $svg = "
#<?xml version=\"1.0\" standalone=\"no\"?>
#
#<svg width="190px" height="160px" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">\n";
#
	my $svg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>
<!-- Created with $0 -->

<svg
	xmlns:dc=\"http://purl.org/dc/elements/1.1/\"
	xmlns:cc=\"http://creativecommons.org/ns#\"
	xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"
	xmlns:svg=\"http://www.w3.org/2000/svg\"
	xmlns=\"http://www.w3.org/2000/svg\"
	version=\"1.2\"";
	#width=\"$H{width}" . "$H{units}\" 
	#height=\"$H{height}" . "$H{units}\"";
	$svg .= "
	viewbox=\"$H{x1vb} $H{y1vb} $H{x2vb} $H{y2vb}\"" if ($H{x2vb} and $H{y2vb});
	$svg .="
	id=\"svg\">
	<defs/>
	<metadata>
 		<rdf:RDF>
    			<cc:Work rdf:about=\"\">
     				<dc:format>image/svg+xml</dc:format>
      				<dc:type rdf:resource=\"http://purl.org/dc/dcmitype/StillImage\" />
      				<dc:title>$H{title}</dc:title>
    			</cc:Work>
  		</rdf:RDF>
	</metadata>\n";
	return $svg;
}

sub svg_footer 
{
	my $svg = "</svg>\n"; 
	return $svg;
}

sub svg_text
{
	#my ($x,$y,$units,$rotate,$text,$font_size,$align) = @_;
	my $params = shift;
	my %H = %$params;
	my ($tx,$ty);
	if (!$H{font}) { $H{font} = "Sans"; } #my $font = "Verdana";

	if    ($H{align} eq "left")   {$H{align} = "start";}
	elsif ($H{align} eq "center") {$H{align} = "middle";}
	elsif ($H{align} eq "right")  {$H{align} = "end";}

	# sub in ASCII value for restrited charaters
	$H{text} =~ s/&/\&#38;/g;
	$H{text} =~ s/%%/\&#44;/g;
	$H{text} =~ s/,/\&#44;/g;
	$H{text} =~ s/"/\&#34;/g;

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $svg = "<text\n";
	$svg .= "\t x=\"$H{x}" . $H{units} . "\"\n";
	$svg .= "\t y=\"$H{y}" . $H{units} . "\"\n";
	$svg .= "\t transform=\"rotate($H{rotate} $H{x},$H{y})\"\n" if ($H{rotate});
	#$svg .= "\t transform=\"rotate($H{rotate} $x,$y)\"\n" if ($H{rotate});
	$svg .= "\t font-size=\"$H{font_size}"."$H{units}\"\n";
	$svg .= "\t stroke=\"$H{font_color}\"\n";
	$svg .= "\t fill=\"$H{font_color}\"\n";
	$svg .= "\t style=\"letter-spacing:0px;\n";
	$svg .= "\t\tword-spacing:0px;\n";
	$svg .= "\t\ttext-anchor:$H{align};\n";
	#$svg .= "\t\tfill-opacity:$H{transparent};\n";
	$svg .= "\t\tfont-family:$H{font}\n";
	$svg .= "\t\">$H{text}</text>\n";
	return $svg;
}

sub svg_image
{
	#my ($link,$x1,$y1,$x2,$y2,$id) = @_;
	my $params = shift;
	my %H = %$params;
	if ($H{link} =~ m/(.*)\r?\n?/) { $H{link} = $1; } # Remove DOS CR

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $svg = "<image\n";
	$svg .= "\txlink:href=\"$H{link}\"\n";
	$svg .= "\tx=\"$x1\"\n";
	$svg .= "\ty=\"$y1\"\n";
	$svg .= "\twidth=\"" . ($x2-$x1) . "\"\n";
	$svg .= "\theight=\"" . ($y2-$y1) . "\"\n";
	$svg .= "\tid=\"image_$H{id}\" />\n";
	return $svg;
}

sub svg_rectangle
{
	#my ($x1,$y1,$x2,$y2,$fill_color,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	my ($x1,$y1) = &convert2px($H{x1},$H{y1},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $svg = "<path d=\"M $x1 $y1 L $x2 $y1 L $x2 $y2 L $x1 $y2 z\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tfill-opacity=\"$H{transparent}\" />\n";
	return $svg;
}

sub svg_square
{
	#my ($x,$y,$shape_size,$fill_color,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	if ($H{shape_size})
	{
		$H{x1} = $H{x}-$H{shape_size};
		$H{y1} = $H{y}-$H{shape_size};
		$H{x2} = $H{x}+$H{shape_size};
		$H{y2} = $H{y}+$H{shape_size};
	}

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $svg = "<path d=\"M $x1 $y1 L $x2 $y1 L $x2 $y2 L $x1 $y2 z\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tfill-opacity=\"$H{transparent}\" />\n";
	return $svg;
}
sub svg_triangle
{
	#my ($x,$y,$shape_size,$fill_color,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;
	if ($H{shape_size})
	{
		$H{x1} = $H{x}-$H{shape_size};
		$H{y1} = $H{y}-$H{shape_size};
		$H{x2} = $H{x}+$H{shape_size};
		$H{y2} = $H{y}+$H{shape_size};
	}

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});
	my $xh = ($x2 - $x1)/2 + $x1;

	my $svg = "<path d=\"M $x1 $y1 L $x2 $y1 L $xh $y2 z\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tfill-opacity=\"$H{transparent}\" />\n";
	return $svg;
}

sub svg_diamond
{
	#my ($x,$y,$shape_size,$fill_color,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;
	if ($H{shape_size})
	{
		$H{x1} = $H{x}-$H{shape_size};
		$H{y1} = $H{y}-$H{shape_size};
		$H{x2} = $H{x}+$H{shape_size};
		$H{y2} = $H{y}+$H{shape_size};
	}

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});
	my $xh = ($x2 - $x1)/2 + $x1;
	my $yh = ($y2 - $y1)/2 + $y1;

	my $svg = "<path d=\"M $x1 $yh L $xh $y1 L $x2 $yh L $xh $y2 z\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tfill-opacity=\"$H{transparent}\" />\n";
	return $svg;
}
sub svg_X
{
	#my ($x,$y,$shape_size,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	$H{x1} = $H{x}+$H{shape_size};
	$H{y1} = $H{y}+$H{shape_size};
	$H{x2} = $H{x}-$H{shape_size};
	$H{y2} = $H{y}-$H{shape_size};
	my $svg = &svg_line(\%H);

	$H{x1} = $H{x}+$H{shape_size};
	$H{y1} = $H{y}-$H{shape_size};
	$H{x2} = $H{x}-$H{shape_size};
	$H{y2} = $H{y}+$H{shape_size};
	$svg .= &svg_line(\%H);

	return $svg;
}
sub svg_plus
{
	#my ($x,$y,$shape_size,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	$H{x1} = $x+$shape_size;
	$H{y1} = $y;
	$H{x2} = $x-$shape_size;
	$H{y2} = $y;
	my $svg = &svg_line(\%H);

	$H{x1} = $x;
	$H{y1} = $y-$shape_size;
	$H{x2} = $x;
	$H{y2} = $y+$shape_size;
	$svg .= &svg_line(\%H);

	return $svg;
}

sub svg_astric
{
	#my ($x,$y,$shape_size,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	$H{x1} = $x+$shape_size;
	$H{y1} = $y+$shape_size;
	$H{x2} = $x-$shape_size;
	$H{y2} = $y-$shape_size;
	my $svg = &svg_line(\%H);

	$H{x1} = $x+$shape_size;
	$H{y1} = $y-$shape_size;
	$H{x2} = $x-$shape_size;
	$H{y2} = $y+$shape_size;
	$svg .= &svg_line(\%H);

	$H{x1} = $x;
	$H{y1} = $y-$shape_size;
	$H{x2} = $x;
	$H{y2} = $y+$shape_size;
	$svg .= &svg_line(\%H);

	$H{x1} = $x+$shape_size;
	$H{y1} = $y;
	$H{x2} = $x-$shape_size;
	$H{y2} = $y;
	$svg .= &svg_line(\%H);

	return $svg;
}

sub svg_line
{
	#my ($x1,$y1,$x2,$y2,$line_color,$width,$transparent) = @_;
  	#my (%H) = @_; make a copy of the hash...
	my $params = shift;
	my %H = %$params;

	my ($x1,$y1) = &convert2px($H{x1},$H{y1},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $svg = "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tstroke-opacity=\"$H{stroke_opacity}\"\n" if ($H{stroke_opacity});
	$svg .= "/>\n";
	return $svg;
}

sub svg_dotted_line
{
	#my ($x1,$y1,$x2,$y2,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});

	my $dash=3;
	my $space=2;
	my $svg = "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tstroke-opacity=\"$H{stroke_opacity}\"\n" if ($H{stroke_opacity});
	$svg .= "\tstroke-dasharray=\"$dash $space\"/>\n";
	return $svg;
}

sub svg_arc
{
	my $params = shift;
	my %H = %$params;

	$svg = "<path d=\"M$H{x1} $H{y1} A$H{radius} $H{radius} 0.0 0 0 $H{x2} $H{y2}\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n" if ($H{fill_color});
	if ($H{fill_opacity} eq "none")
	{
		$svg .= "\tfill-opacity=\"0\"\n" 
	}
	elsif ($H{fill_opacity})
	{
		$svg .= "\tfill-opacity=\"$H{fill_opacity}\"\n" 
	}
	$svg .= "/>\n";
	return $svg;
}
sub svg_polyline
{
	my $params = shift;
	my %H = %$params;

	my $svg = "<polyline points=\"$H{cords}\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n" if ($H{fill_color});
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tstroke-linecap=\"round\"\n";
	$svg .= "\tstroke-opacity=\"$H{stroke_opacity}\"\n" if ($H{stroke_opacity});
	$svg .= "/>\n";
	return $svg;
}

sub svg_circle
{
	#my ($x,$y,$shape_size,$fill_color,$line_color,$width,$transparent) = @_;
	my $params = shift;
	my %H = %$params;

	my $radius = $H{shape_size};
	my ($x,$y) = &convert2px($H{x2},$H{y2},$H{unit});
	#my ($x1,$y1) = &convert2px($H{x2},$H{y2},$H{unit});
	#my ($x2,$y2) = &convert2px($H{x2},$H{y2},$H{unit});
	if ($H{unit} eq "in")    {$radius = &in2px($radius);}
	elsif ($H{unit} eq "mm") {$radius = &mm2px($radius);}

	my $svg = "<circle cx=\"$x\" cy=\"$y\" r=\"$radius\"\n";
	$svg .= "\tstroke=\"$H{line_color}\"\n";
	$svg .= "\tstroke-width=\"$H{line_width}\"\n";
	$svg .= "\tfill=\"$H{fill_color}\"\n";
	#$svg .= "\tfill-opacity=\"$H{transparent}\"\n";
	$svg .= "/>\n";
	return $svg;
}

sub in2px
{
	my $in = @_;
	my $px = $in*90;
	return $px;
}

sub mm2px
{
	my $mm = @_;
	my $px = $mm*3.77952;
	return $px;
}

sub convert2px
{
	#my $params = shift;
	#my %H = %$params;
	my ($x,$y,$units) = @_;
	my ($tx,$ty);

	if ($units eq "in")
	{
		$tx = &in2px($x);
		$ty = &in2px($y);
	}
	elsif ($units eq "mm")
	{
		$tx = &mm2px($x);
		$ty = &mm2px($y);
	}
	else
	{
		$tx = $x;
		$ty = $y;
	}
	return ($tx,$ty);
}
1;
