#!/usr/bin/perl -w

use strict;

#use Bio::Root::IO;
use Bio::SeqFeature::Tools::IDHandler;
use Bio::Tools::GFF;
use Bio::Seq;

use Getopt::Long;

our $USAGE = 'validate_gff_via_ontology.pl [-help] [-trace|t] [-type_only] [-mapping|m MYTYPE=REALTYPE] GFF-FILE ONTOLOGY-FILE';


eval { 
    require "GO/Parser.pm";
};
if ($@) {
    print <<EOM

Currently you need go-perl to run this; available from

 http://www.godatabase.org/dev

or CPAN

 perl -MCPAN -e shell
 install go-perl

EOM
}

# -- pre-declare --
sub trace;
sub uniquify;
# --

my $trace;
my $help;
my $types_only;
my $type_mapping = {};
GetOptions("help|h"=>\$help,
           "trace|t"=>\$trace,
           "types_only"=>\$types_only,
           "mapping|m=s%"=>$type_mapping,
          );

if ($help) {
   exec('perldoc', $0);
   exit 0;
}

if (@ARGV != 2) {
    print $USAGE, "\n";
    exit 1;
}

# -- parse GFF3 --
my $ffn = shift @ARGV;
trace("parsing $ffn");
my $seq = Bio::Seq->new;
my $io = Bio::Tools::GFF->new(-file => $ffn, -gff_version=>3);
my @features = ();
while (my $feature = $io->next_feature) {
    push(@features, $feature);
    $seq->add_SeqFeature($feature);
}

my @topfeatures =
  Bio::SeqFeature::Tools::IDHandler->create_hierarchy_from_ParentIDs($seq);

trace("got %d features (%d top)", scalar(@features), scalar(@topfeatures));


# -- parse ontology --
my $fn = shift @ARGV;

trace("parsing ontology file: $fn");
my $p = GO::Parser->new({handler=>'obj'});
$p->parse($fn);
my $graph = $p->handler->graph;
# --

# -- initialize report variables --
my @bad_types = ();
my @good_types = ();
my @missing_partofs = ();
my @bad_partofs = ();
my @sugg = ();

# -- validate --
trace("validating...");
foreach my $f (@topfeatures) {
    validate_feature($f);
}
@bad_types = uniquify(@bad_types);
@good_types = uniquify(@good_types);
@missing_partofs = uniquify(@missing_partofs);
@bad_partofs = uniquify(@bad_partofs);
@sugg = uniquify(@sugg);

# -- Report --
print "REPORT ON: $ffn\n";
print "OK_TYPES : @good_types\n";
print "BAD_TYPES : @bad_types\n" if @bad_types;

print "MISSING_PART_OFs: @missing_partofs\n" if @missing_partofs;
print "INVALID_PART_OFs: @bad_partofs\n" if @bad_partofs;
print "SUGGESTED_CHANGES: @sugg\n" if @sugg;
# --

# -- Exit --
my $exit_code = 0;
if (@bad_types || @bad_partofs) {
    $exit_code = 1;
}
exit $exit_code;
# --

# -- validate_feature subrtoutine --
sub validate_feature {
    my $f = shift;
    my $parentf = shift;
    
    # supplied feature type
    my $primary_tag = $f->primary_tag;

    # corresponding SO term?
    my $term = $graph->get_term_by_name($primary_tag);
    if (!$term) {
        push(@bad_types, $primary_tag);
    }
    else {
        push(@good_types, sprintf("%s [%s]", $term->name, $term->acc));
    }

    # child features (as defined by Parent tag)
    my @subfs = $f->sub_SeqFeature;

    # recursive validation on subfeatures
    foreach my $subf (@subfs) {
        validate_feature($subf, $f);
    }
    if ($types_only) {
        return;
    }
    
    # let's check if the parent relationships conform to PART-OFs in SO
    if ($term) {
        
        # any instance of term T is implicitly an instance of T'
        # where T' is a superclass (is_a parent) of T
        my $type_rt_list = 
          $graph->get_reflexive_parent_terms_by_type($term->acc,
                                                     'is_a');
        if (!$parentf) {
            # $f has no Parent tag in GFF3 -- check if it needs a parent
            
            foreach my $term (@$type_rt_list) {
                my $part_of_parents =
                  $graph->get_parent_terms_by_type($term->acc,
                                                   'part_of');
                # the current feature is a root feature,
                # yet SO says it is part_of some other feature type
                foreach (@$part_of_parents) {
                    push(@missing_partofs,
                         sprintf("[%s PART_OF %s]",
                                 $primary_tag,
                                 $_->name));
                }
            }
        }

        foreach my $subf (@subfs) {
            my $ok = 0;

            # supplied child feature type
            my $subf_primary_tag = $subf->primary_tag;

            # corresponding SO type?
            my $subf_term = $graph->get_term_by_name($subf_primary_tag);

            trace "checking $subf_primary_tag PART_OF $primary_tag";
            if (!$subf_term) {
                trace "Can't check subfeature as type %s is not in ontology\n",
                  $subf_primary_tag;
                next;
            }

            #
            # we fetch the reflexive transitive closure of both
            # child and parent feature type terms (this includes the
            # specified type as well as recursive parents)

            my $child_type_rt_list = 
              $graph->get_reflexive_parent_terms_by_type($subf_term->acc,
                                                         'is_a');

            # if F1 is a child feature of F2, then there must be
            # a corresponding part_of relationship in SO over the types
            # T1 and T2
          XP:
            foreach my $c (@$child_type_rt_list) {
                foreach my $p (@$type_rt_list) {
                    trace "   [subtype*] checking if %s is-part_of %s...",
                      $c->name, $p->name;
                    my $rels =
                      $graph->get_relationships_between_terms($p->acc, $c->acc);
                    trace "   R:@$rels\n";
                    # HARDCODE alert: the relationship in SO must be 
                    # part_of
                    # TODO: allow for subtypes of relationship types
                    my @po = grep {$_->type eq 'part_of'} @$rels;
                    if (@po) {
                        trace "   YES!";
                        $ok = 1;
                        last XP;
                    }
                    else {
                        trace "   NO!";
                    }
                }
            }
            if ($ok) {
                trace "**OK**\n";
            }
            else {
                trace "**NOT VALID**\n";

                # track invalid relationships
                push(@bad_partofs, sprintf("[%s PART_OF %s]",
                                           $subf_term->name,
                                           $primary_tag));
                
                # $subf is not allowed to be a child of $f according to SO;
                # find suggested replacements
                my $suggested_fterms =
                  $graph->get_parent_terms_by_type($subf_term->acc, 'part_of');
                foreach (@$suggested_fterms) {
                    trace "SUGGESTION: how about making %s [now a %s] a %s\n",
                      $f->primary_id || '?', $primary_tag, $_->name;
                    push(@sugg, 
                         sprintf("[change %s (now %s) to a %s]",
                                 $f->primary_id || '?', $primary_tag, $_->name));
                }         
                my $suggested_subfterms =
                  $graph->get_parent_terms_by_type($term->acc, 'part_of');
                foreach (@$suggested_subfterms) {
                    trace "SUGGESTION: how about making %s [now a %s] a %s\n",
                      $subf->primary_id || '?', $subf_term->name, $_->name;
                    push(@sugg, 
                         sprintf("[change %s (now %s) to a %s]",
                                 $subf->primary_id || '?', $subf_term->name, $_->name));
                }
            }
        }
    }
    return;
}
# --

# -- uniquify a list --
sub uniquify {
    my %h = ();
    grep {
        my $done = $h{$_};
        $h{$_} = 1;
        !$done;
    } @_;
}

# -- logging --
sub trace {
    if ($trace) {
        my $fmt = shift;
        printf($fmt, @_);
        print "\n";
    }
}


__END__

=head1 NAME

  validate_features.pl

=head1 SYNOPSIS

  validate_features.pl -trace -m cds=coding_sequence MyFeatures.gff so.obo

=head1 DESCRIPTION

This script will validate a GFF (version3 is best) file against an
ontology of sequence features.

The validation is in two parts:

first of all the types in the GFF file are checked vs the terms in the
ontology. An identifier (which will be a SO accession if the SO/SOFA
ontology is used) is assigned if it exists (case insensitive matching
is used). If the type used in the GFF file does not exist in the
ontology file the script will notify you with a message like:

  BAD_TYPE:  locus transcrpt geme

The second part of the validation checks to see if the 'subfeature'
relationships specified in the GFF (using Parent and ID attributes in
GFF3) are valid. For instance, making 'transcript' a subfeature of
'repeat' is obviously silly, and it is banned because there is no
'part-of' restriction between transcript and repeat in the canonical
SOFA ontology. The rules are a bit more subtle than this, as we also
have to traverse the subsumption hierarchy.

If a feature/subfeature containment is not allowed, you will get a
message like:

  INVALID_PART_OF: [coding_start PART_OF exon]

To get a full explanation of why the part_of link is bad, run with the
trace switch [-trace]

=head2 REQUIREMENTS

=over

=item An ontology file

You can obtain the SO or SOFA ontology here:

 http://song.sf.net/

Download the obo formatted file

=item go-perl

This is required for parsing the obo file

See
http://www.godatabase.org/dev

or download from CPAN

http://search.cpan.org/perldoc?go-perl

=item

Some files in GFF format!

=back

=head2 RULES

B<NOTE> this needs updating - this documentation was based on a much
older version of SO

a subfeature can only be part of a superfeature
if there is a direct part-of link for the relevant feature types
OR such a link can be obtained by traversing either of the
two graphs upwards.

the part-of links must be direct; we do not use the closure of the
part-of relationship. This means that you can *not* make an exon a
subfeature of gene, you need the intermediate object (of some kind of
transcripty type, eg mRNA).

=head2 EXAMPLES

(these depend on an imaginary version of a SO-style ontology):

=head3 Example 1

  can I make a 'mRNA' feature a subfeature of noncoding gene ('nc_gene')?

YES! 'mRNA' is a subclass of 'processed_transcript' is a subclass of 'transcript'
     'nc_gene' is a subclass of 'gene'
     'mRNA' is a part of 'gene' ** RESOLVED **


=head2 SPECIFICATION

 notes: R* is the reflexive transitive closure of R
 notes: R+ is the transitive closure of R

(reflexive includes the relationship x R x)

  IF
    ChildFeat part-of ParentFeat

  THEN

  THIS MUST BE SATISFIED FOR SOME POSSIBLE BINDING OF THE VARIABLES BELOW
  (if it starts with a capital it is an unbound variable):
  
  ChildFeat has-feature-type ChildType
  ParentFeat has-feature-type ParentType

  ChildType is-a* ChildTypeAllPossible
  ParentType is-a* ParentTypeAllPossible

  # don't allow nonreflexive transitive closure on part-of
  # we *could* allow ChildTypeAllPossible part-of+ ParentTypeAllPossible
  # which would mean we could attach exons directly to genes

  ChildTypeAllPossible part-of ParentTypeAllPossible


=head1 AUTHOR - Chris Mungall

Email cjm AT fruitfly DOT org

=cut
