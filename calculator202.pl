#!/usr/bin/perl

$| = 1;
$" = " | ";
$log = 0;
$current_stack = "default";
@{$stacks{$current_stack}} = ();
$filename = "";
$today = localtime();

print "Today is $today";
print "\nperl lazy calculator V2.0.2 Thomas Engstrom/kaITomas IT-konsult 2003,2014,2017\n";
print "Type h for help\n";

sub tidy {
	my $way = shift @_;
	my @valarr = @_;
	my @tmparr = ();
	foreach $stackvalue (@valarr) {
		if ($stackvalue) {
			if ($way eq 'T') {
				if ((($stackvalue =~ /\d/o) || ($stackvalue =~ /[\.,]/)) &&
					(!($stackvalue =~ /\D/o))) {
					push @tmparr, $stackvalue;
				}
			}
			else {
				push @tmparr, $stackvalue;
			}
		}
	}
	@tmparr;
}

#######################################
# Loop forever
INPUT: while (1) {
    $oper = ""; $res = "";
    $numeric = 1; $column = 0;
    if ($log) {
		print "(L)+-*/ ";
    } else {
		print "+-*/ ";
    }
    chomp($oper = <STDIN>);
	# Run system command?
    if ($oper =~ /^!/o) {
		# Is it double-exclam with a number?
	    if ($oper =~ /^![0-9]+!/o) {
	        $oper =~ s/^!([0-9]+)!//o;
			$column = $1;
		}
		# Is it just a double-exclam?
		elsif ($oper =~ /^!!/o) {
	        $oper =~ s/^!!//o;
			$column = 1;
		}
		# Any double-exclam puts us here
		# ANY output from the system command is put on the stack, not
		# just numeric values. This must be allowed since the command
		# can have strange formatting for it's numbers
		if ($column) {
	        open(COD,"$oper|") or warn "Cannot run command $oper : $!\n", next;
			print LOG "\t\t#+@ Collected from command \'$oper\':\n" if ($log);
			while (<COD>) {
				@line = split;
				chomp($line[$column-1]);
				push @{$stacks{$current_stack}}, $line[$column-1];
				print LOG "\t$line[$column-1]\n" if ($log);
				print "$line[$column-1]\n";
			}
			print LOG "\t\t#-@ End of output from command \'$oper\'\n" if ($log);
			close COD;
			print "[@{$stacks{$current_stack}}]\n" if ($d);
		    $oper = "";
			next;
		}
		# A single exclam puts us here. Nothing is put on the stack
		else {
			$oper =~ s/^!//o;
		    system("$oper");
			$oper = "";
	        next;
		}
	}
	# Should we filter the stack?
	if ($oper =~ /^f/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
			print "Stack empty\n";
            next;
        }
		$oper =~ s/^f//o;
		print "$oper\n" if ($d);
		for (@{$stacks{$current_stack}}) {
			eval $oper;
			warn $@ if $@;
		}
		if ($log) {
			print LOG "\t\t#   Stack filtered with expression $oper\n";
			print LOG "\t\t#+\$  resulting stack:\n";
			foreach $foo (@{$stacks{$current_stack}}) {
				printf LOG "$foo\n"; # Not properly formatted, see the reasons
			}                        # explained in the 'tidy' part below.
			print LOG "\t#-\$\n";
		}
		next;
	}
	# Should we apply a function to the values on the stack?
	if ($oper =~ /^F/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
			print "Stack empty\n";
            next;
        }
		$oper =~ s/.*\((.*)\)/$1/o;
		print LOG "\t# $oper (each value on stack)\n" if ($log);
		$tmpvalue = "";
		@tmparr = ();
		foreach $value (@{$stacks{$current_stack}}) {
			$function = "$oper $value";
			$tmpvalue = eval $function;
			warn $@ if $@;
			push @tmparr, $tmpvalue;
		}
		@{$stacks{$current_stack}} = @tmparr;
		next;
	}
	# Make dots of commas, this must come after the above filter/function
	# operations since they might need real commas
	$oper =~ s/,/\./;

	# Find out if this item is numeric, this prohibits entering
	# nonnumeric values (but they can slip through with the !! operator)
	if ($oper == 0 && $oper ne "0") {
		$numeric = 0;
    }
	# This allows us to put comments in the log
    if ($log && $oper =~ /^#/o) {
        print LOG "\t$oper\n";
        next;
    }
	# Find out what time it is and format that nice
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $mon  = "0$mon" if ($mon < 10);
    $hour = "0$hour" if ($hour < 10);
    $min  = "0$min" if ($min < 10);
    $year = 1900 + $year;
    $now  = "$year-$mon-$mday $hour:$min";
	# Should we make a log?
	# The intention of the log is to have it formatted in a way so that
	# it can be "replayed". No functionality for this exists yet, but
	# try to keep everything that can not be used in calculations
	# within comments. When logging actions and debug info, try to
	# mark "blocks" in the log that can be filtered out.
    if ($oper =~ /^l/o) {
		if ($log) {
			print "logging off $now, $filename closed\n";
			print LOG "# Logging off, $filename closed $now\n";
			close LOG;
			$log = 0;
			next;
		}
		else {
			if ($oper =~ /^la/o) {
				if (!open(LOG,">>$filename")) {
					print "cannot open $filename for append\n";
					$log = 0;
				}
				else {
					print LOG "\n# Logfile $filename reopened $now\n\n";
					$log = 1;
				}
				next;
			}
			else {
				if (!(($foo,$filename) = ($oper =~ /^(\S+)\s+(\S+)\s*/o))) {
					print "l requires a filename\n";
					next;
				}
			}
			print "logging to $filename\n";
			$log = 1;
			if (!open(LOG,">$filename")) {
				print "cannot open $filename for writing\n";
				$log = 0;
			} else {
			    print LOG "\n# Logfile $filename created $now\n\n";
	        }
		    next;
		}
	}
	# Add any number to the log
    if ($log && $numeric) {
        printf LOG "\t%15.3f\n",$oper;
    }
	# Is it an operator?
    if ($oper =~ /^[\+\-\*\/xp]/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
            print "Stack empty\n";
            next;
        }
		# Is it plus?
		if ($oper =~ /^[p\+]/o) {
			$res = 0;
			# Make a sum of all values on the stack
			while ($#{$stacks{$current_stack}} >= 0) {
				$res += pop(@{$stacks{$current_stack}});
			}
			print "\t$res\n";
			print LOG "\t$oper\n" if $log;
			print LOG "\t#--------------\n" if $log;
			printf LOG "\t%15.3f\n\n",$res if $log;
			$save = $res;
            next;
		}
		# Is it subtraction?
		if ($oper =~ /^-/o) {
			# Subtract the last value from the next to last
			$op1 = pop(@{$stacks{$current_stack}});
			$op2 = pop(@{$stacks{$current_stack}});
			$res = $op2 - $op1;
			print "\t$res\n";
            print LOG "\t$oper\n" if $log;
            print LOG "\t#--------------\n" if $log;
            printf LOG "\t%15.3f\n\n",$res if $log;
			$save = $res;
            next;
		}
		# Is it multiplication?
		if ($oper =~ /^[x\*]/o) {
			$res = 1;
			# Calculate the faculty of the stack's values
			while ($#{$stacks{$current_stack}} >= 0) {
				$res *= pop(@{$stacks{$current_stack}});
			}
			print "\t$res\n";
            print LOG "\t$oper\n" if $log;
            print LOG "\t#--------------\n" if $log;
            printf LOG "\t%15.3f\n\n",$res if $log;
			$save = $res;
            next;
		}
		# Is it division?
		if ($oper =~ /^\//o) {
			# Divide the next to last value on the stack
			# by the last value
			$namnare = pop(@{$stacks{$current_stack}});
			if ($namnare !~ /[1-9]/) {
				print "Division by zero!\n";
				print LOG "#! /0\n" if $log;
				next;
			}
			$taljare = pop(@{$stacks{$current_stack}});
			$res = $taljare / $namnare;
			print "\t$res\n";
            print LOG "\t$oper\n" if $log;
            print LOG "\t#--------------\n" if $log;
            printf LOG "\t%15.3f\n\n",$res if $log;
			$save = $res;
            next;
		}
    }
	# Should we tidy up the stack?
	if ($oper =~ /^t/o) {
		@{$stacks{$current_stack}} = tidy('t',@{$stacks{$current_stack}});
		if ($log) {
			print LOG "\t\t#   Removed empty values from the stack,\n";
			print LOG "\t\t#+% resulting stack:\n";
			foreach $foo (@{$stacks{$current_stack}}) {
				print LOG "\t$foo\n"; # This is not formatted as %15.3f because
			}                         # I want to use the log for debugging.
			print LOG "\t#-%\n";      # Hence, this part of the log cannot be
		}                             # used for "replay".
		next;
	}
	# Shoud we TIDY up the stack?
	if ($oper =~ /^T/o) {
		@{$stacks{$current_stack}} = tidy('T',@{$stacks{$current_stack}});
		if ($log) {
			print LOG "\t\t#   Removed empty and nonnumeric values from the stack,\n";
			print LOG "\t\t#+%% resulting stack:\n";
			foreach $foo (@{$stacks{$current_stack}}) {
				print LOG "\t$foo\n"; # Maybe this should be formatted as %15.3f ?
			}                         # See the comments in 'tidy' above, and the
			print LOG "\t#-%%\n";     # comments about logging in the beginning of
		}                             # the script.
		next;
	}
	# Is 'Bout asked for?
	if ($oper =~ /^B/o) {
		print "\nperl lazy calculator V1.0 Thomas Engstrom/DataVis Norr AB 1998\n";
		print "                     V1.1, 1.2, 1.3                       1999\n";
		print "                     V1.4            /kaITomas IT-konsult 2001\n";
		print "                     V2.0            /kaITomas IT-konsult 2003\n";
		print "                     V2.0.1          /kaITomas IT-konsult 2014\n";
		print "                     V2.0.2          /kaITomas IT-konsult 2017\n";
		print "\n You may use this code freely, but please keep this 'Bout text\n intact.\n\n";
		print "\n The calculator works with stacks and reverse polish notation.\n";
		print " Perl-expressions are used for filtering and math functions.\n";
		print " The function implementation is primitive (see the help), but\n";
		print " may be enhanced sometime.\n\n";
		next;
	}
	# Is it just a value to put on the stack?
    if ($numeric) {
		push @{$stacks{$current_stack}},$oper;
		if ($d) {
			print "[@{$stacks{$current_stack}}]\n";
		}
		next;
    }
	# Should we clear the stack?
    if ($oper =~ /^c/o) {
		@{$stacks{$current_stack}} = ();
		$save = "";
		if ($d) {
			print "[@{$stacks{$current_stack}}]\n";
		}
        if ($log) {
            print LOG "# Stack cleared--------\n";
        }
		next;
    }
	# Should we recall last result and put on the stack?
    if ($oper =~ /^r/o) {
		if (!$save) {
			print "No result yet\n";
			next;
		}
        printf LOG "\t%15.3f\n",$save if $log;
		push @{$stacks{$current_stack}},$save;
		if ($d) {
			print "[@{$stacks{$current_stack}}]\n";
		} else {
			print "     $save\n";
		}
		next;
    }
	# Should we change sign on the last value on the stack?
	if ($oper =~ /^i/o) {
        if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
            print "Stack empty\n";
            next;
        }
	    ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}] =
		-${$stacks{$current_stack}}[$#{$stacks{$current_stack}}];
		if ($d) {
			print "[@{$stacks{$current_stack}}]\n";
		}
		if ($log) {
			printf LOG "\t%15.3f\t# Sign changed on last operand.\n",
			-${$stacks{$current_stack}}[$#{$stacks{$current_stack}}];
		}
		next;
	}
	# Should we toggle the debug flag?
    if ($oper =~ /^d/o) {
		$d = $d ? 0 : 1;
		if ($d) {
		 print "[@{$stacks{$current_stack}}]\n";
		}
		next;
    }
	# Should we show the help?
    if ($oper =~ /^[h\?]/o) {
	print "
	All commands must start in the first column!

Aname       Add another stack, named 'name', making it the current stack
Nname       Choose stack 'name' as current stack
Rname       Delete a stack named 'name'
Mname       Add a stack to the 'stack of stacks'
Y s1 s2     Copy stack s1 to stack s2, destroying whatever was in s2
V           Show stack inventory, current stack marked with *
            stacks on the 'stack of stacks' marked with M
B           'Bout this software
d           Toggle stack view (and some debug info)
c           Clear the stack and last result
C           Count number of items in current stack
q           Quit
r           Recall last result and put on the stack
p           +
P           Add corresponding items in all stacks. If stacks are of
            different depth, addition will stop when the smallest
            stack is empty
_           (underscore) Subtract the last chosen (with 'M') stack
            from the next-to-last chosen stack
\\           (backslash) Divide the next-to-last chosen (with 'M') stack
            with the last chosen stack
kn          Kill (delete) stack value 'n'
s           Look at the stack once
S           Look at all stacks once
h           This help
x           *
X           Multiply corresponding items in all stacks. If stacks are of
            different depth, multiplication will stop when the smallest
            stack is empty
=           Look at the last result once
i           Change sign on last value that was put on the stack
l filename  Log everything to filename, put comments there with '#'
l           Turn off logging
la          Reopen last logfile for append
!CMD        Run system command CMD
!n!CMD      Run system command CMD and put output on stack,
            output comes from column n, or first column if
            n is null (!!)
o           Sort the stack
t           Tidy up the stack: Remove empty items
T           TIDY up the stack: Remove empty and nonnumeric items
z           'zplit' multi-number-items (whitespace separated)
            to separate items on current stack
f expr      Filter the stack, applies to each value,
            expr must be a valid perl regular expression
F(expr)     Apply a mathematical funtion to each value in the stack,
            expr must be a valid perl expression. The stack values
            will be put at the right end of the expression

TODO:
Add logging to the new stack operations
Explain how to make inline-value-functions like 'sin(value) -1'

Unimplemented:
More stack operations:
	split a stack to more stacks,
Choice of numeric base for input and output

";
	next;
    }
	# Should we split multi-number-items to separate items?
	if ($oper =~ /^z/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
            print "Stack empty\n";
            next;
        }
		$tmparr = ();
		foreach $foo (@{$stacks{$current_stack}}) {
			push @tmparr, split(' ',$foo);
		}
		@{$stacks{$current_stack}} = @tmparr;
		next;
	}
	# Should we sort a stack?
	if ($oper =~ /^o/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
            print "Stack empty\n";
            next;
        }
		@tmparr = sort { $a <=> $b} @{$stacks{$current_stack}};
		@{$stacks{$current_stack}} = @tmparr;
		next;
	}
	# Should we copy a stack to another?
	if ($oper =~ /^Y/o) {
		$oper =~ s/^Y//o;
		($stack_1, $stack_2) = split(' ',$oper);
		if (!$stacks{$stack_1} ||
			!$stacks{$stack_2}) {
			print "No stack: $stack_1 or $stack_2, use 'V' to look\n";
			next;
		}
		@{$stacks{$stack_2}} = ();
		foreach $v (@{$stacks{$stack_1}}) {
			push @{$stacks{$stack_2}}, $v;
		}
		next;
	}
	# Should we add or multiply all stacks together?
	if ($oper =~ s/^([PX]).*/$1/o) {
		if (!@stacklist) {
			print "No stacks defined for operation\n Use 'M' to define stacks\n";
			next;
		}
		foreach $s (@stacklist) {
			$minlen = $#{$stacks{$s}} unless $minlen;
			if ($#{$stacks{$s}} < $minlen) {
				$minlen = $#{$stacks{$s}};
			}
		}
		@resultstack = ();
		if ($oper eq 'X') {
			for ($i=0;$i<=$minlen;$i++) {
				$resultstack[$i] = 1;
			}
		}
		foreach $s (@stacklist) {
			for ($i=0;$i<=$minlen;$i++) {
				$resultstack[$i] += $stacks{$s}[$i] if ($oper eq 'P');
				$resultstack[$i] *= $stacks{$s}[$i] if ($oper eq 'X');
			}
		}
		@{$stacks{'result'}} = @resultstack;
		print "[@{$stacks{'result'}}]\n";
		@stacklist = ();
		next;
	}
	# Should we perform subtraction or division between two stacks?
	if ($oper =~ s/^([_\\]).*/$1/o) {
		if (!@stacklist) {
			print "No stacks defined for operation\n Use 'M' to define stacks\n";
			next;
		}
		$first_stack  = pop(@stacklist);
		$other_stack = pop(@stacklist);
		$minlen = $#{$stacks{$first_stack}};
		if ($#{$stacks{$other_stack}} < $minlen) {
				$minlen = $#{$stacks{$other_stack}};
		}
		@resultstack = ();
		for ($i=0;$i<=$minlen;$i++) {
			if ($oper eq '\\') {
				if ($stacks{$first_stack}[$i] !~ /[1-9]/) {
					print "Division by zero! $first_stack : $stacks{$first_stack}[$i]\n";
					undef @resultstack;
					next INPUT;
				}
				$resultstack[$i] =
					$stacks{$other_stack}[$i] / $stacks{$first_stack}[$i];
			}
			if ($oper eq '_') {
				$resultstack[$i] = $stacks{$first_stack}[$i] - $stacks{$other_stack}[$i];
			}
		}
		@{$stacks{'result'}} = @resultstack;
		print "[@{$stacks{'result'}}]\n";
		next;
	}
	# Should we kill a stack value?
	if ($oper =~ /^k/o) {
		if (! defined ${$stacks{$current_stack}}[$#{$stacks{$current_stack}}]) {
            print "Stack empty\n";
            next;
        }
		$oper =~ s/^k\s*//o;
		if (!($oper > 0)) {
			print "k needs a value > 0\n";
			next;
		}
		$oper--;
		$removed = splice(@{$stacks{$current_stack}},$oper,1);
		print LOG "\t# Deleted the value $removed from stack $current_stack\n"
			if ($log);
		next;
	}
	# Should we prepare for stack operations?
	if ($oper =~ /^M/o) {
		$oper =~ s/^M\s*//o;
		if ($stacks{$oper}) {
			push @stacklist, $oper;
			print LOG "\t# Picked stack $oper for stack operation\n" if ($log);
		}
		else {
			print "No stack $oper, use 'V' to look\n";
		}
		next;
	}
	# Should we delete a stack?
	if ($oper =~ /^R/o) {
		$oper =~ s/^R//o;
		if ($stacks{$oper}) {
			delete $stacks{$oper};
			print LOG "\t# Deleted stack $oper\n" if ($log);
		}
		else {
			print "No stack $oper, use 'V' to look\n";
		}
		if ($oper eq $current_stack) {
			$current_stack = 'default';
		}
		next;
	}
	# Should we add another stack?
	if ($oper =~ /^A/o) {
		$oper =~ s/^A\s*//o;
		$current_stack = $oper;
		@{$stacks{$current_stack}} = ();
		print LOG "\t# Created stack $oper\n" if ($log);
		next;
	}
	# Should we choose another stack?
	if ($oper =~ /^N/o) {
		$oper =~ s/^N\s*//o;
		if ($stacks{$oper}) {
			$current_stack = $oper;
			print LOG "\t# Stack $oper chosen\n" if ($log);
		}
		else {
			print "No stack $oper, use 'V' to look\n";
		}
		next;
	}
	# Should we print stack inventory?
	if ($oper =~ /^V/o) {
		foreach $k (keys %stacks) {
			if ($k eq $current_stack) {
				print "   * $k";
			}
			else {
				print "     $k";
			}
			foreach $s (@stacklist) {
				if ($k eq $s) {
					print " \tM";
				}
			}
			print "\n";
		}
		next;
	}
	# Should we look at all stacks and their content?
	if ($oper =~ /^S/o) {
		foreach $k (keys %stacks) {
			print "$k\t [@{$stacks{$k}}]\n";
		}
		next;
	}
	# Should we print the stack once?
    if ($oper =~ /^s/o) {
		print "[@{$stacks{$current_stack}}]\n";
		next;
    }
	# Should we print the number of items in the stack?
	if ($oper =~ /^C/o) {
		$n_items = $#{$stacks{$current_stack}} + 1;
		print "Items: " . $n_items . "\n";
		next
	}
	# Should we print the last result?
    if ($oper =~ /^=/o) {
		print "<$save>\n";
		next;
    }
	# Should we quit?
    if ($oper =~ /^q/o) {
		print " Really quit? [q=yes, y=yes] ";
		chomp($ans = <STDIN>);
		next unless ($ans =~ /^[qy]/o);
                $timetoleave = localtime();
		print "Bye!  You left at $timetoleave\n";
		print LOG "# Exit from calculator at $timetoleave, log closed.\n" if $log;
		exit;
    }
	# Here we go if operator is unknown
	print " $oper is not implemented\n"
		unless ($oper =~ /^$/ || $oper =~ /^\s*$/);
}
