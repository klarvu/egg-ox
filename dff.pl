#!/usr/bin/perl
################################################################################
# dff.pl - Simple, easy to read, display of 'df' output for AIX.
#
#                            /Thomas Engstrom, Cinqore AB. For FM, december 2018
################################################################################
print "\n";
foreach ( qx:/usr/bin/df: ) {     # Spawn a df command and loop over the output.
  @df = split;                                  # Split each line into an array.
  next if ($df[3] =~ /-/);             # Don't bother with special file systems.
  $filesys{$df[6]} = $df[3];              # Save the filesys name and its usage%
}
# Now sort everything according to usage% and print the result.
for my $key (sort { $filesys{$a} <=> $filesys{$b} } keys %filesys) {
  print " $filesys{$key}\t$key\n";
}
print "\n";
