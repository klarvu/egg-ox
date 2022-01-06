#!/usr/bin/perl
$filename = $ARGV[0];
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
    $atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);

print("$filename\t$mtime (mtime)
  \t$ctime (ctime)
  \t$atime (atime)\n");
 
