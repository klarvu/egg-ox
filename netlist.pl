#!/usr/bin/perl
######################################################################
# netlist.pl - List interfaces, addresses and names of a Linux system.
#                 /Thomas Engstrom, Cinqore AB for Volvo IT 2015-05-28
######################################################################
use Socket;
 
foreach ( qx{/sbin/ip addr show} ) {
  undef $ipaddr; undef $taddr; undef $name;
  $iface  = $1 if /^\d:\s+(\S+?):?\s/;
  next if ($iface =~ /lo/);
  $ipaddr = $1 if /inet (\d+\.\d+\.\d+\.\d+)/i;
  next unless $ipaddr;
  $taddr = inet_aton($ipaddr);
  $name = gethostbyaddr($taddr, AF_INET) || "NXDOMAIN";
  print "$iface\t$ipaddr\t$name\n";
}
