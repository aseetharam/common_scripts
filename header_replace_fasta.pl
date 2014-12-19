use strict;
use warnings;

open(my $in1, '<', $ARGV[0])
    or die "Can't read from multifasta file '$ARGV[0]': $!";
my @multifasta = <$in1>;
close $in1;

open(my $in2, '<', $ARGV[1])
    or die "Can't read from header replacement file '$ARGV[1]': $!";
my %headers;

while (<$in2>)
{
    my ($orig, $new) = split;
    warn "Duplicate replacement: $orig --> $new\n" if exists $headers{$orig};
    $headers{$orig}  = $new;
}

close $in2;

my $destination = $ARGV[0] . '_headers-replaced.fasta';
open (my $out, '>', $destination)
    or die "Can't write to file '$destination': $!"; 

foreach my $line (@multifasta)
{
    if ($line =~ /^\>/)  # it is a header
    {
        foreach my $key (keys %headers)
        {
            if ($line =~ /$key/)
            {
                $line =~ s/$key/$headers{$key}/;
                last;
            }
        }
    }

    print $out $line;
}

close $out;
