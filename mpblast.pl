#!/usr/bin/perl -w
#BEGIN{require 5.6.0}
#use warnings;
use strict;
use sigtrap;
use constant e => 2.718281828;
use BPlite;
use FAlite;
use Getopt::Std;
use vars qw($opt_h $opt_w $opt_s $opt_n $opt_m $opt_l $opt_t $opt_b);
#our ($opt_h, $opt_w, $opt_s, $opt_n, $opt_m, $opt_b);


#############################################
# usage and commandline argument processing #
#############################################
my $usage = '

MPBLAST - multiplex-BLAST

usage: mpblast [options] <blast commandline except query is fasta database>
options:
  -h        prints documentation
  
            TYPE_OF_BLAST - will guess if these are not chosen
  -w        WU-BLAST
  -n        NCBI-BLAST
  
            MPBLAST SPECIFICS - change only if necessary
  -l <int>  length of spacer (not -s, default 100)
  -s        use WU_BLAST segmentation optimizations (implies -w)
  -m <int>  maximum length of multiplex (default 100,000)
  
            OUTPUT OPTION - default is table
  -t <char> table output separator
  -b        blast-style output format (blastn only)

';
getopts('hwsnm:l:t:b');
if ($opt_h) {system("pod2text $0"); exit}
die $usage unless @ARGV;
my $LARGE_NUMBER = 1e7; # hspmax
my $PLEX = $opt_m ? $opt_m : 100000;
my $BLAST_OUTPUT = $opt_b;
my $WU_BLAST = $opt_w;
my $NCBI_BLAST = $opt_n;
my $SEGMENTING = $opt_s;
my $TABLE_SEPARATOR = $opt_t ? $opt_t : " ";
my $SPACER_LENGTH = $opt_l ? $opt_l : 100;
$WU_BLAST = 1 if $SEGMENTING;
if (not $WU_BLAST and not $NCBI_BLAST) {
	if ($ARGV[0] =~ /blastall/) {
		$NCBI_BLAST = 1;
		print STDERR "MPBLAST: assuming NCBI-BLAST\n";
	}
	else {
		$WU_BLAST = 1;
		print STDERR "MPBLAST: assuming WU-BLAST\n";
	}
}
my $Segnum = 0; # for blast output


#####################################
# WU-BLAST and NCBI-BLAST specifics #
#####################################
my $FH; # filehandle for file or stdin
my ($Program, $Database, $Query, $Dash, @BLAST_OPTIONS);
my ($SEGMENT_SEPARATOR, $SEGLEN);

if ($WU_BLAST) {
	# WU-BLAST command specifics
	$Dash = '-'; # used to signify stdin
	($Program, $Database, $Query, @BLAST_OPTIONS) = @ARGV;
	$Database = "\"$Database\""; # for virtual database
	die $usage unless defined $Query;
	if ($Query eq '-') {$FH = \*STDIN}
	else {
		open(QUERY, $Query)
			or die "MPBLAST ERROR query file ($Query) not found\n";
		$FH = \*QUERY;
	}
	
	# WU-BLAST multiplex specifics
	push @BLAST_OPTIONS, "V=0 B=10000000 hspmax=$LARGE_NUMBER";
	if ($SEGMENTING) {
		$SEGMENT_SEPARATOR = '-';
		push @BLAST_OPTIONS, "kap";
	}
	else {
		$SEGMENT_SEPARATOR = '-' x $SPACER_LENGTH;
		#push @BLAST_OPTIONS, "hspsepqmax=1 gapsepqmax=1"; # not faster...
	}
}
elsif ($NCBI_BLAST) {
	# NCBI-BLAST command specifics
	$Dash = ''; # no dash used to signify stdin
	my ($prog, %arg) = @ARGV; # not guaranteed to parse commandline correctly
	die "no program specified\n" unless defined $arg{-p};
	$arg{-d} = "nr" unless defined $arg{-d};
	$Program = "$prog -p $arg{-p}";
	$Database = "-d $arg{-d}";
	if (not defined $arg{-i}) {$FH = \*STDIN}
	else {
		open(QUERY, $arg{-i})
			or die "MPBLAST ERROR query file ($arg{-i}) not found\n";
		$FH = \*QUERY;
	}
	
	# NCBI-BLAST multiplex specifics
	delete $arg{-p};
	delete $arg{-d} if defined $arg{-d};
	delete $arg{-i} if defined $arg{-i};
	delete $arg{-b} if defined $arg{-b};
	delete $arg{-m} if defined $arg{-m};
	$arg{-b} = $LARGE_NUMBER;
	$arg{-F} = "\"$arg{-F}\"" if $arg{-F}; # thanks Joey Bedell
	push @BLAST_OPTIONS, %arg;
	$SEGMENT_SEPARATOR = 'N' x $SPACER_LENGTH;
}
$SEGLEN = length($SEGMENT_SEPARATOR);


#############################################
# temp file - better than pipe in this case #
#############################################
my $TEMP_FILE = "/tmp/mpblast.$$.tmp";
END{system "rm $TEMP_FILE" if defined $TEMP_FILE and -e $TEMP_FILE}


#####################
# main program loop #
#####################
my $fasta = new FAlite($FH);
my $length = 0;
my @pool; # pool of fasta files
while (my $entry = $fasta->nextEntry) {
	$length += length($entry->seq);
	push @pool, $entry;
	if ($length >= $PLEX) {
		executeMultiplex(\@pool);
		$length = 0;
		@pool = ();
	}
}
executeMultiplex(\@pool) if @pool;
exit(0);


###############################################################################
#                             subroutines below                               #
###############################################################################

#################### 1. creates a lookup of segments
# executeMultiplex # 2. executes blast with multiplex
#################### 3. sends results to ouput routine
sub executeMultiplex {
	my ($pool) = @_;
	my $numseq = @$pool;
	#print STDERR "MPBLAST segment size:$numseq\n";

	# concatenate sequences and deflines and make a coordinate lookup
	my (@def, @seq);    # will contain concatenated defs and seqs
	my @segment;        # segment info stored here
	my @bucket;         # bucket sort for coordinate lookup
	my $minlen = $PLEX; # minimum sequence length
	my ($sum, $lookup) = (0, 0);
	foreach my $entry (@$pool) {
		push @def, $entry->def;
		push @seq, $entry->seq;
		my ($name) = $entry->def =~ /^>(\S+)/;
		my $length = length($entry->seq);
		for(my $i=$sum;$i<($length+$sum);$i++) {$bucket[$i+1] = $lookup}
		$sum += $length + $SEGLEN;
		push @segment, {
			length => $length,
			sum    => $sum,
			name   => $name,
			def    => $entry->def};
		$lookup++;
		$minlen = $length if $length < $minlen;
	}
	
	# set the query size (search space size) for the smallest query
	my $Y = $WU_BLAST ? "Y=$minlen" : ""; # WU-BLAST only
	
	# pipe sequence to blast process
	open(TEMP, "| $Program $Database $Dash @BLAST_OPTIONS $Y > $TEMP_FILE")
		or die "MPBLAST ERROR running blast ($Program)\n";
	@def = (">mpblast.$$"); # long deflines screw up NCBI-BLAST
	print TEMP join(" : ", @def), "\n";
	print TEMP join($SEGMENT_SEPARATOR, @seq), "\n";
	close TEMP;
	
	my ($output) = readBlast(\@segment, \@bucket);
	output(\@segment, $output);
}

#############
# readBlast # reads the BLAST report and returns the output
#############
sub readBlast {
	my ($seg, $bucket) = @_;
	open(BLAST, $TEMP_FILE) or die;
	my @output; # used for sorted output
	my $handle;
	my $blast = new BPlite(\*BLAST);
	while (my $sbjct = $blast->nextSbjct) {
		my ($def) = $sbjct->name;# =~ /^>(\S+)/;
		while (my $hsp = $sbjct->nextHSP) {
			my ($begin, $end) = ($hsp->qb, $hsp->qe); 

			# begin and end should be in the same segment
			my $handle    = $bucket->[$begin];
			my $handle2   = $bucket->[$end];
			
			#################################################################
			# error if begin and end are not defined or not in same segment #
			#################################################################
			if (not defined $handle or not defined $handle2 or
				$handle != $handle2) {
				#system("cp $TEMP_FILE ./error_at_$begin");
				#print "Begin:$handle\nEnd:$handle2\n$hsp\n";
				#use DataBrowser; browse($bucket);
				die "MPBLAST FATAL ERROR\n",
					"Alignments are crossing the multiplex spacer.\n",
					"Try setting -l or changing parameters\n";
			}
			
			# remap the coordinates of the segment
			my $segment   = $seg->[$handle];
			my $extra     = $segment->{sum} - $segment->{length};
			my $new_begin = $begin - $extra + $SEGLEN;
			my $new_end   = $end   - $extra + $SEGLEN;
			
			$hsp->{QB} = $new_begin;
			$hsp->{QE} = $new_end;
			$hsp->{QUERY_NAME} = $seg->[$handle]{name};
			$hsp->{SBJCT_NAME} = $def;
			$hsp->{SBJCT_LENGTH} = $sbjct->length;
			
			unless ($BLAST_OUTPUT) {
				delete $hsp->{QL};
				delete $hsp->{SL};
				delete $hsp->{AS};
				($hsp->{SBJCT_NAME}) = $hsp->{SBJCT_NAME} =~ /^>(\S+)/;
			}
			push @{$output[$handle]{$def}}, $hsp;
		}
	}
	close BLAST;
	return \@output;
}

#################
# displayOutput # display the results
#################
sub output {
	my ($segment, $output) = @_;
	
	# need to get header and footer from temp file
	# footer for Karlin-Altschul parameters
	# header and footer for BLAST output
	open(HF, $TEMP_FILE) or die;
	my (@header, @footer);
	while(<HF>) {last if /^Query=/; push @header, $_;}
	while(<HF>) {last if /^Parameters|^\s+Database:/}
	push @footer, $_;
	while(<HF>) {push @footer, $_}
	
	# Karlin-Altschul stats
	my ($L, $K, $H, $D) = KAstats(\@footer); # K-A stats
	for (my $i=0;$i<@$segment;$i++) {
		
		my $M = $segment->[$i]{length}; # length of query
		
		foreach my $sbjct (keys %{$output->[$i]}) {
			foreach my $hsp (@{$output->[$i]{$sbjct}}) {
				
				my $S = $hsp->score;
				my $N = $hsp->{SBJCT_LENGTH}; # length of sbjct
				
				# edge correction for M and N
				my $edge_correction = $L * $S / $H;
				
				my $m_prime = $M - $edge_correction;
				my $n_prime = $N - $edge_correction;
				$m_prime = 1 if $m_prime < 1;
				$n_prime = 1 if $n_prime < 1;
				
				# calculation of E and P
				my $E = $K * $m_prime * $n_prime * e ** -($L * $S);
				$E = $E * $D / $N; # edge corrected E
				my $P = ($E < 0.01) ? $E : 1 - e ** -$E;
				
				# store the values
				$hsp->{E} = reformat($E);
				$hsp->{P} = reformat($P);
			}
		}
	}
		
	if ($BLAST_OUTPUT) {			
		for (my $i=0;$i<@$segment;$i++) {
			$Segnum++;
			print "MPBLAST SEGMENT $Segnum START\n\n";
			#print "MPBLAST SEGMENT $Segnum ($segment->[$i]{name}) START\n\n";
			print @header;
			print wrap("Query=  " . substr($segment->[$i]{def}, 1) .
				" ($segment->[$i]{length} letters)"), "\n";
			print "Database:  $Database\n\n\n";
			foreach my $sbjct (keys %{$output->[$i]}) {
				my $n = $output->[$i]{$sbjct}[0]{SBJCT_LENGTH};
				print wrap($sbjct), "            Length = $n\n\n";
				foreach my $hsp (@{$output->[$i]{$sbjct}}) {
					displayBLAST($hsp);
				}
			}
			print "\n";
			print @footer;
			print "\nMPBLAST SEGMENT $Segnum END\n\n";
		}
	}
	else {
		for (my $i=0;$i<@$segment;$i++) {
			my $count = 0;
			foreach my $sbjct (keys %{$output->[$i]}) {
				foreach my $hsp (@{$output->[$i]{$sbjct}}) {
					print join(" ", $hsp->qb, $hsp->qe, $hsp->{QUERY_NAME},
						$hsp->sb, $hsp->se, $hsp->{SBJCT_NAME},  $hsp->score,
						$hsp->bits, $hsp->{E}, $hsp->{P}, $hsp->percent,
						$hsp->match, $hsp->positive, $hsp->length,
						$segment->[$i]{length}, $hsp->{SBJCT_LENGTH}, $hsp->qg,
						$hsp->sg), "\n";
					$count++;
				}
			}
			print "\n" if $count;
		}
	}
}

############
# reformat # just changes the P and E values to something less precise
############
sub reformat {
	my ($V) = @_;
	if (length($V) > 7) {
		if ($V =~ /^(\d)\.(\d+)(e[\+\-]?\d+)/) {
			$V = $1 . "." . substr($2, 0, 2) . $3;
		}
		elsif ($V < 1) {
			$V = substr($V, 0, 7);
		}
		else {
			$V = substr($V, 0, index($V, "."));
		}
	}
	return $V;
}

###########
# KAstats # retrieves K-A stats from footer
###########
sub KAstats {
	my ($footer) = @_;
	my ($L, $K, $H, $N);
	for(my $i=0;$i<@$footer;$i++) {
		if ($footer->[$i] =~ /As Used/) {
			my @f = split(/\s+/, $footer->[$i+3]);
			($L, $K, $H) = ($f[4], $f[5], $f[6]); # WU-BLAST
			#print $footer->[$i+3], "\n";
			#print $L, "\n";
			#die;
		}
		elsif ($footer->[$i] =~ /^Gapped/ and $footer->[$i+1] =~ /^Lambda/) {
			my ($foo, $lambda, $k, $h) = split(/\s+/, $footer->[$i+2]);
			($L, $K, $H) = ($lambda, $k, $h); # NCBI-BLAST
		}
		elsif ($footer->[$i] =~ /letters in database:\s+(\S+)/) {
			$N = $1; # works for both
			$N =~ s/,//g;
		}
	}
	return($L, $K, $H, $N);
}

################
# displayBLAST # blast-like output (not identical though)
################
sub displayBLAST {
	my ($hsp) = @_;
	my $similar = int(1000*$hsp->positive/$hsp->length)/10;
	
	print " Score = ", $hsp->score, " (", $hsp->bits, " bits), Expect = ",
		$hsp->{E}, ", P = ", $hsp->{P}, "\n", " Identities = ", $hsp->match,
		"/", $hsp->length, " (", $hsp->percent, "%), ", "Positives = ",
		$hsp->positive, "/", $hsp->length, " (", $similar, "%)\n\n";

	my $size = 60;
	my $qgaps = 0;
	my $sgaps = 0;
	my ($QB, $QE, $SB, $SE) =
			($hsp->qb, $hsp->qe, $hsp->sb, $hsp->se);
	for (my $i=0;$i<length($hsp->{QL});$i+=$size) {
		my $qchunk = substr($hsp->{QL}, $i, $size);
		my $schunk = substr($hsp->{SL}, $i, $size);
		my $achunk = substr($hsp->{AS}, $i, $size);
		
		my $qgf = $qchunk =~ tr/-/-/;
		my $sgf = $schunk =~ tr/-/-/;
		
		my ($qb, $qe, $sb, $se);
		if ($QB < $QE) {
			$qb = $QB + $i - $qgaps;
			$qe = $qb + length($qchunk) - $qgf - 1;
		}
		else {
			$qb = $QB - $i + $qgaps;
			$qe = $qb - length($qchunk) + $qgf + 1;
		}
		if ($SB < $SE) {
			$sb = $SB + $i - $sgaps;
			$se = $sb + length($schunk) - $sgf - 1;
		}
		else {
			$sb = $SB - $i + $sgaps;
			$se = $sb - length($schunk) + $sgf + 1;
		}
		
		$qgaps += $qgf;
		$sgaps += $sgf;
		
		my $qspace = length($qb);
		my $sspace = length($sb);
		my $longest = $qspace >= $sspace ? $qspace : $sspace;
		
		$qspace = ' ' x ($longest - $qspace);
		$sspace = ' ' x ($longest - $sspace);
		my $aspace = ' ' x ($longest + 8);
		
		print 
			"Query: $qspace$qb $qchunk $qe\n",
			     $aspace, $achunk, "\n",
			"Sbjct: $sspace$sb $schunk $se\n\n";
	}
}

########
# wrap # for wrapping long lines in the blast output
########
sub wrap {
	my ($line) = @_;
	my @output;
	my @word = split(/\s+/, $line);
	my $linelen = 0;
	my $firstline = 1;
	for(my $i=0; $i<@word; $i++) {
		if ($i == @word -1) {
			push @output, "$word[$i]";
		}
		elsif ($linelen + length($word[$i]) + length($word[$i+1]) < 80) {
			push @output, "$word[$i] ";
			$linelen += length($word[$i]) + 1;
		}
		else {
			$firstline = 0;
			push @output, "$word[$i]\n";
			push @output, (" " x 12);
			$linelen = 12;
		}
	}
	push @output, "\n";
	return join("", @output);
}


__END__

=head1 NAME

MPBLAST - multiplex BLAST

=head1 SYNOPSIS
 
 mpblast [hwsnmltb] <blast command line>

=head1 DESCRIPTION

MPBLAST improves the performance of BLAST searches by combining short querries
into one multiplex query. For example, instead of executing BLASTN 100 times
with 500 bp querries, you execute BLAST once on a multiplexed 50,000 bp query.
The optimal size of a multiplex query is about 100,000 characters. Therefore if
you execute MPBLAST with 10,000 500 bp querries, it would break this up into 50
separate searches of 100,000 bp each. The size of each multiplex is a
commandline option should you wish to change it. Each version of BLASTN has its
own optimal multiplex size, so you may want to experiment and find the optimal
size for your use.

=head1 COMMANDLINE OPTIONS

=head2 -w -n

Sets the type of BLAST to either WU-BLAST or NCBI-BLAST. If one of these flags
are not set, MPBLAST will guess based on the program name.

=head2 -l -s

The length of the segment separator can be set with the -l option. The
separator is used to prevent alignments from crossing the single-sequence
boundaries in the multiplex query. The default is to use 100 -'s for WU-BLAST
and 100 N's for NCBI-BLAST.

If using WU-BLAST, you can use the -s option to make the multiplex segmentation
more efficient. -s makes each segment separator into a single '-' instead of
100 char string.

=head2 -m

The default length of multiplexes is 100,000 bp. Empirically, this value works
well. The optimal length is determined by various factors though, and there may
be applications where smaller or larger values are more suitable. For example,
on machines with little RAM, -m should be set smaller (also see -b below). I
have noticed on some platforms that the optimial multipliex size for NCBI-BLAST
is more than 200,000 bp.

=head2 -t -b

The default output format is space-delimited fields (see below). You can change
the delimiter with the -s option.

The -b option makes the output look like a BLAST report.

=head1 OUTPUT FORMATS

MPBLAST has 2 output formats. The default is tabular. You may set the record
separator with the -t option. The default is a single space.

The column definitions are as follows:

  1: query begin
  2: query end
  3: query name
  4: sbjct begin
  5: sbjct end
  6: sbjct name
  7: raw score
  8: bits (normalized score)
  9: E-value
 10: P-value
 11: percent identity
 12: number of matches
 13: number of positive scores (similarities)
 14: length of alignment
 15: length of query
 16: length of sbjct
 17: number of gaps in query alignment
 18: number of gaps in sbjct alignment
						
Each row of the table corresponds to an alignment. Blank lines separate query
sequences.

The other format looks like concatenated WU-BLAST reports. Between each report
are tags that identify each segment of the multiplex.

 MPBLAST SEGMENT 0 START
 :
 : (the blast report)
 :
 MPBLAST SEGMENT 0 END
 
 MPBLAST SEGMENT 1 START
 :
 MPBLAST SEGMENT 1 END

The -b switch turns on BLAST-style output. Note that this takes more memory.


=head1 PERFORMANCE

The peformance improvement is typically around 10x, but this depends on several
factors. These include the size of each sequence in the multiplex, the size of
the multiplex, the size of the database relative to RAM (caching or thrashing),
the similarity between the sequences in the multiplex, and the version of
BLAST. In my tests, WU-BLAST is faster than NCBI-BLAST, but NCBI-BLAST benefits
more from multiplexing.

=head1 LIMITATIONS

Various BLAST commandline options are not supported or do not behave in the
expected manner. For example, -V and -B (-v and -b in NCBI-BLAST) are disabled.
Combining HSPs with Sum or Poisson statistics is not supported.

=head1 SEE ALSO

 WU-BLAST (http://blast.wustl.edu)
 NCBI-BLAST (http://www.ncbi.nlm.nih.gov)

=head1 AUTHORS

 Ian Korf (http://sapiens.wustl.edu/~ikorf)

=head1 ACKNOWLEDGEMENTS

This software was developed at the Genome Sequencing Center at Washington
Univeristy, St. Louis, MO.

=head1 COPYRIGHT

Copyright (C) 2000 Ian Korf. All Rights Reserved.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind. This software
may not be redistributed without permission of the authors.

=cut
