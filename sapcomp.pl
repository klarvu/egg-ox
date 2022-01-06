#!/usr/bin/perl
################################################################################
# sapcomp.pl - Get names and addresses from the SAP host agent, This can be of
#              good use to see if the agent has the same opinion as other tools
#              like netstat, nslookup etcetera. Use it for troubleshooting.
#
# THIS SCRIPT WILL BREAK WHEN SAP CHANGES THE OUTPUT OF saphostctrl !!!
#
#                           /Thomas Engstrom, Cinqore AB for Volvo IT 2015-09-14
################################################################################
if ($< != 0) {
  print "\n !!! Must be run as root !!!\n\n";
  exit;
}
 
print "\n\tInfo from the SAP host agent:\n";
 
foreach ( qx{/usr/sap/hostctrl/exe/saphostctrl -function GetComputerSystem} ) {
  if (/ Name , String , /) {
    ($foo1,$foo2,$name) = split /,/;
    print "\nHostname: $name\n";
  }
  if (/ Hostnames , String/) {
    ($foo1,$mak,$hostString) = split /,/;
    ($foo1,$sep) = split /=/, $mak;
    chop $sep;
    @hostnames = split /\Q$sep\E/, $hostString;
    print "Logical names:\n";
    foreach $name (@hostnames) {
      print "\t$name\n";
    }
  }
  if (/ IPAdresses , String/) {
    ($foo1,$mak,$addressString) = split /,/;
    ($foo1,$sep) = split /=/, $mak;
    chop $sep;
    @ipaddresses = split /\Q$sep\E/, $addressString;
    print "IP addresses:\n";
    foreach $addr (@ipaddresses) {
      print "\t$addr\n";
    }
  exit;
  }
}
