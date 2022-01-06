#!/usr/bin/env perl -s
################################################################################
# waship.pl - Utility to "wash" log files (in text format) from sensitive
#             information before sending them to SAP.
#             How to use: waship.pl -h
#
#                                Thomas Engstrom, Cinqore AB, for FM, April 2021
################################################################################
use Socket;
$| = 1; # stdout unbuffered.
$0 =~ s:.*/::; # Name of this script.
$myname = $0; # Save the name.
$dirty_file = $ARGV[0]; # The file to be cleansed.
@addr_parts;  # Matrix for all address parts, subnets.
@fake_parts;  # Matrix for the replacement parts.
%used_part1;  # Hash to keep track of used replacement numbers.
%used_part2;  # Hash to keep track of used replacement numbers.
%used_part3;  # Hash to keep track of used replacement numbers.

# Create 3 pools of subnet numbers, to be used for replacements.
@level_1 = 2..250;
@level_2 = 2..250;
@level_3 = 2..250;

sub usage() {
    print "\nUsage: $myname <option> filename\n";
    print "       options:\n";
    print "       -h   This help.\n";
    print "       -a   Analyze filename and create the file\n";
    print "            replacements.txt which will be used in\n";
    print "            the second run with the -z option.\n";
    print "       -z   Procezz filename and replace IP addresses\n";
    print "            according to the mappings in replacements.txt\n";
    print "            Also replace host names, if any.\n";
    print "            No file is created, output will be on your screen.\n\n";
    exit;
}

sub analyze() {
  print "Working...\n";
  while(<>) {              # Read addresses from input file, one address per row.
      my $line = $_;
      while ($line =~ m/(\d+\.\d+\.\d+\.\d+)/g) { # Find any IP address
        push @addresses, $1 unless $haveseen{$1}; # and save them.
        $haveseen{$1} = 1;                        # And remember them.
      }
  }

  # Now we split the collected addesses into 4 "subnet parts" and loop
  # through them, replacing them with numbers from our replacement pools.
  # It's important to keep track of which number goes where in order to
  # make fake addresses that follows the original addresses subnets.
  my $i = 0;
  foreach $adr (@addresses) {
      ($p0,$p1,$p2,$p3) = split('\.',$adr);
      $addr_parts[$i][0] = $p0;
      $fake_parts[$i][0] = $p0; # We don't fake the first part.

      # The above is for the xxx.-.-.- part of the address
      # now we move on to the -.xxx.-.- part.
      $addr_parts[$i][1] = $p1;
      if (!$used_part1{$p1}) {    # If we haven't used this number yet
          $temp = shift @level_1; # then we pull a new one from the pool.
          $fake_parts[$i][1] = $temp; # Save it in the fake address.
          $used_part1{$p1}   = $temp; # And remember that we have used it.
      } else {
          $fake_parts[$i][1] = $used_part1{$p1}; # If we have used it, we
      }                                          # just reuse it.

      # Now we handle the -.-.xxx.- part the same way.
      $addr_parts[$i][2] = $p2;
      if (!$used_part2{$p2}) {
          $temp = shift @level_2;
          $fake_parts[$i][2] = $temp;
          $used_part2{$p2}   = $temp;
      } else {
          $fake_parts[$i][2] = $used_part2{$p2};
      }

      # Finally the last part -.-.-.xxx
      $addr_parts[$i][3] = $p3;
      if (!$used_part3{$p3}) {
          $temp = shift @level_3;
          $fake_parts[$i][3] = $temp;
          $used_part3{$p3}   = $temp;
      } else {
          $fake_parts[$i][3] = $used_part3{$p3};
      }
      $i++;
  }

  # Loop through the original addresses and print them together with
  # their fake counterparts. Put some delimiter between them for easier
  # handling later on.
  open(REP,'>',"replacements.txt") or die $!;
  print REP "\n*** ATTENTION! Follow these instructions before using this file. ***\n\n";
  print REP "To the left of the ';' character are the original addresses\n";
  print REP "and to the right are the addresses that will replace the originals.\n";
  print REP "There can also be hostnames at the end, without replacements. You must\n";
  print REP "either delete them (then they will not be replaced) or supply them\n";
  print REP "with your own replacements. Do not forget the ';' to separate the names.\n";
  print REP "*** ALSO! Check the file $dirty_file for hostnames that can be missing here! ***\n";
  print REP "Then delete everything that is not a replacement line, such as this text.\n";
  print REP "Finally run the $myname script like before but with the -z option.\n";
  print REP "---\n";
  for $i (0 .. $#addr_parts) {
      # First the original, part by part.
      for $j (0 .. 2) {
        print REP "$addr_parts[$i][$j]."; # The first 3 parts.
      }
      print REP "$addr_parts[$i][3];"; # The 4:th part with the delimiter,
      # Then the fake, part by part.
      for $j (0 .. 2) {
        print REP "$fake_parts[$i][$j]."; # The first 3.
      }
      print REP "$fake_parts[$i][3]\n"; # The last part with a newline.
  }

  foreach $pushed (@addresses) {
    $taddr = inet_aton($pushed);
    $name = gethostbyaddr($taddr, AF_INET);
    print REP "$name\n";
  }
  print "\nThe file replacements.txt have been created, please open it\n";
  print "in an editor and follow the instructions there.\n\n";
  print REP "---\n";
  close REP;
}

sub notok() {
  print "\nThere seems to be something wrong with replacements.txt\n";
  print "Did you follow the instructions there?\n";
  print "Only replacement lines are allowed, that is:\n";
  print "Pairs of IP addresses and/or hostnames, separated by ';'\n";
  print "Blank lines are also forbidden.\n\n";
  exit;
}

sub procezz() {
  my (@originals, @fakes);
  open(ANA,'<',"replacements.txt") or die $!;
  open(ORG,'<',"$dirty_file") or die $!;
  print STDERR "Be patient, this can take some time.\n";
  while(<ANA>) {
    chomp; # Get rid of newlines.
    notok unless (/;/);
    ($from,$to) = split ';';
    push @originals, $from;
    push @fakes, $to;
  }
  close ANA;
  while(<ORG>) {
    chomp;
    $line = $_;
    for $i (0 .. $#originals) {
      $line =~ s/$originals[$i]/$fakes[$i]/g;
    }
    print "$line\n";
  }
}

usage if ($h);
usage unless ($ARGV[0]);
usage if ($ARGV[0] && (!$a && !$z));
analyze if ($a);
procezz if ($z);
