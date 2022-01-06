#!/usr/bin/perl
####################################################################
# aixnet.pl - List interfaces, addresses and names of an AIX system.
#                      /ThomasEngstrom, Cinqore AB for FM 2017-10-24
####################################################################
$index = 1;
foreach ( qx{/usr/bin/netstat -in} ) {
  next if /^Name/;
  next if /^lo0/;
  next if /link/;
  @iline = split;
  $res[$index] = "$iline[0]\t\t$iline[3]\t\t";
  $index++;
}
$index = 1;
foreach ( qx{/usr/bin/netstat -i} ) {
  next if /^Name/;
  next if /^lo0/;
  next if /link/;
  @iline = split;
  $res[$index] = "$res[$index]$iline[3]\n";
  $index++;
}
print "Interface\tAddress\t\t\tName\n";
foreach $line ( @res ) {
  print $line;
}
