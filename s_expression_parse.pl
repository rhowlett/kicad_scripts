#!/usr/bin/env perl
use strict;
use warnings;

# Main function to parse an S-expression
sub parse_sexpr 
{
    my ($expr) = @_;
    my @tokens = tokenize($expr);
    return parse_list(\@tokens);
}

# Tokenize the input (split by spaces, parentheses, and handle quotes)
sub tokenize 
{
    my ($input) = @_;
    my @tokens = ();
    while ($input =~ /\S+/g) 
    {
        my $token = $&;
        push @tokens, $token;
    }
    return @tokens;
}

# Parse the tokens recursively
sub parse_list 
{
    my ($tokens_ref) = @_;
    my @list;
    
    while (@$tokens_ref) 
    {
        my $token = shift @$tokens_ref;

        if ($token eq '(') 
        {
            # Start a new list, recursively parse the inner part
            push @list, parse_list($tokens_ref);
        }
        elsif ($token eq ')') 
        {
            # End of the current list, return the current list
            return \@list;
        }
        else 
        {
            # Atom (a symbol or number)
            push @list, $token;
        }
    }
    return \@list;
}

# Test the script with an example input string
my $sexpr_input = "(define (factorial n) (if (= n 0) 1 (* n (factorial (- n 1)))))";
my $parsed_sexpr = parse_sexpr($sexpr_input);
print "Parsed S-expression: \n";
print_sexpr($parsed_sexpr, 0);

# Pretty-print the parsed S-expression
sub print_sexpr 
{
    my ($expr, $indent_level) = @_;
warn "($expr, $indent_level)\n";
    if (ref $expr eq 'ARRAY') 
    {
        print ' ' x $indent_level . "(\n";
        foreach my $e (@$expr) 
        {
            print_sexpr($e, $indent_level + 2);
        }
        print ' ' x $indent_level . ")\n";
    } 
    else 
    {
        print ' ' x $indent_level . "$expr\n";
    }
}
