#!/usr/bin/perl
##############################################################################################
# javalog.pl - Print a SAP java log, defaulttrace for example, with understandable timestamps.
#
# Usage: javalog.pl <filename> | more
#
#                                        Thomas Engstrom, Colada AB, for Vattenfall 2012-10-05
##############################################################################################
 
use POSIX qw(strftime);
while (<>) {
  if (/^#.+/) {
    @logentry = split(/#/);
    $timestamp = strftime "\n== %Y-%m-%d %H.%M.%S ==\n", localtime(substr $logentry[3],0,10);
    print $timestamp;
  }
  print;
}
