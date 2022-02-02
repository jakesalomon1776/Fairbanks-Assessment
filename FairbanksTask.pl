#!/usr/bin/perl -w #-d

use strict;
use warnings;
use Data::Dumper;
use Math::Combinatorics;

my $in_file = shift;    # Get the name of the file from command line
open (my $in_file_fh, "<", $in_file)
  or die "Error <$!>\nUnable to open file <$in_file> for read";

my $target_price = <$in_file_fh>;
chomp $target_price;    # Lose line terminator
$target_price =~ s/\$//g;           # Lose the $ sign from price

# Rest of file is comma-separated data
#
my %item_price = ();  # Prepare a hash to hold components if price-list

while (my $in_line = <$in_file_fh>)
{
  chomp($in_line);
  my @pair = split(",", $in_line);      # Item, price (with $ to lose)
  $item_price{$pair[0]} = $pair[1];
  $item_price{$pair[0]} =~ s/\$//g;
  $item_price{$pair[0]} += 0.0;         # Make sure Perl sees this as numeric
}
close($in_file_fh);

my @combo_prices = ();                  # Tally combinations and total cost here
my @item_list = keys(%item_price);      #
my %combo_totals = ();                  # Add up totals in here
my %exact_match = ();                   # Keep a separate hash in case I match
my $item_count = scalar(@item_list);    # How many items are in the list
my $exact_count = 0;                    # Tally this iff we have a target match

for (my $lc = 1; $lc <= $item_count; $lc++)
{ # Run combinatorics on increasing number of item from item list
  #
 #print "Combinations by <$lc> items\n";
  my $combo_obj = Math::Combinatorics->new(count => $lc,
                                           data  => [@item_list]);
  while (my @combo = $combo_obj->next_combination())
  {
    @combo = sort @combo;               #(To watch for unlikely duplicates)
    my $combo_total = 0;                # This will be the value
    foreach my $combo_item (@combo)
    {
      $combo_total += $item_price{$combo_item};
    }
    my $combo_join = join("|", @combo); # Use as key in hash %combo_total
    $combo_totals{$combo_join} = $combo_total  # Total value of this combo
      unless ($combo_total > $target_price);   # but skip if exceeded price
    if ($combo_total == $target_price)         # This is really my goal: 
    {                                          # a combo that matches target
      $exact_match{$combo_join} = $combo_total; # Tell world what it is
      $exact_count++;                          # provided this ever goes up
    }
  }
}
# This is mainly a debugging step: Sort all the combos in increasing order
# of price total.
#
#-my @sorted_combos = sort {$combo_totals{$a} <=> $combo_totals{$b}}
#-                          keys(%combo_totals);
#-foreach my $one_combo (@sorted_combos)
#-{
#-  printf("%-55s => %6.2f\n", $one_combo, $combo_totals{$one_combo});
#-}

if ($exact_count > 0)   # If any combo matched the target price
{
  print("The following combinations of items matched the target price:\n");
  print Dumper(\%exact_match);
}
else
{
  print("No combination of items matched the target price\n");
}

exit 0;
