#!/usr/bin/perl

use warnings;
use strict;
no indirect;
no autovivification;
use List::Util qw/uniq/;
use Carp::Assert;

#========================================================================#

=pod

=head1 NAME

build-wiki-table - create a wiki formatted table of results

=head1 OPTIONS

B<build-wiki-table>

=head1 SYNOPSIS

Loads the results from the files matching *-nolibc-nolibgcc-nolibm.csv and
writes a wiki formatted table to stdout.  This script should be run after
'grab-results.sh' is run.

=cut

#========================================================================#

my $files = { riscv => "riscv-nolibc-nolibgcc-nolibm.csv",
              arc => "arc-nolibc-nolibgcc-nolibm.csv",
              arm => "arm-nolibc-nolibgcc-nolibm.csv" };

#========================================================================#

# Load all of the data from all of the files.
my $results = {};
foreach my $arch (keys %{$files})
{
  $results->{$arch} = load_data ($files->{$arch});
}

# Build a list of all known benchmark names.
my @all_benchmarks = ();
foreach my $arch (keys %{$results})
{
  @all_benchmarks = (@all_benchmarks, keys %{$results->{$arch}});
}
@all_benchmarks = uniq (sort (@all_benchmarks));

#========================================================================#

print <<EOF
{| class="wikitable sortable"
|-
!
! colspan=3| ARM
! colspan=3| ARC
! colspan=3| RISC-V
! colspan=3| % Increase ARM to RISC-V
! colspan=3| % Increase ARC to RISC-V
|-
! Benchmark
! Text
! Data
! Bss
! Text
! Data
! Bss
! Text
! Data
! Bss
! Text
! Data
! Bss
! Text
! Data
! Bss
|-
EOF
  ;

foreach my $bm (@all_benchmarks)
{
  print "| $bm\n";

  foreach my $arch (qw/arm arc riscv/)
  {
    assert (exists ($results->{$arch}));
    assert (exists ($results->{$arch}->{$bm}));

    foreach my $type (qw/text data bss/)
    {
      print "| ".$results->{$arch}->{$bm}->{$type}."\n";
    }
  }

  foreach my $arch (qw/arm arc/)
  {
    foreach my $type (qw/text data bss/)
    {
      my $base = $results->{$arch}->{$bm}->{$type};
      my $now = $results->{riscv}->{$bm}->{$type};

      my $inc;
      if (($base == 0) and ($now == 0))
      {
        $inc = 0;
      }
      elsif ($base == 0)
      {
        $base = 1;
        $inc = 100.0 * ($now - $base) / $base;
      }
      else
      {
        $inc = 100.0 * ($now - $base) / $base;
      }

      printf "| %.2f\n", $inc;
    }
  }

  print "|-\n";
}

print "|}\n";

#========================================================================#

=pod

=head1 METHODS

The following methods are defined in this script.

=over 4

=cut

#========================================================================#

=pod

=item B<load_data>

Takes a filename, loads the contents of the file, and returns a hash
reference for a hash containing the loaded results.

Format of loaded results is:

    { <BENCHMARK-NAME> => { text => <TEXT-SIZE>,
                            data => <DATA-SIZE>,
                            bss => <BSS-SIZE> } }

=cut

sub load_data {
  my $filename = shift;

  my $results = {};

  open my $in, $filename or
    die "Failed to open '$filename': $!";

  while (<$in>)
  {
    chomp;		# Remove trailing newline.
    $_=~s/"//g;		# Remove all of the quote characters.
    my ($bm, $text, $data, $bss) = split /,/, $_;	# Split up line.
    assert (not (exists ($results->{$bm})));
    $results->{$bm} = { text => $text, data => $data, bss => $bss };
  }

  close $in or
    die "Failed to close '$filename': $!";

  return $results;
}

#========================================================================#

=pod

=back

=head1 AUTHOR

Andrew Burgess, 08 Feb 2019

=cut
