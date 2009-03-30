#!/usr/bin/perl -- -*-cperl-*-

package PMS;

use Getopt::Long;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;
File::Temp->safe_level( File::Temp::MEDIUM);
use Cwd;

use vars qw/%opt $PSQL/;

GetOptions( 
		"help",
		"VERBOSE",
		"dbuser|u=s@",
		"dbname|db=s@",
		"host|H=s@",
		"port=s@",
		"PSQL=s",
);

$VERBOSE = $opt{VERBOSE} || 2;

$PSQL = $opt{PSQL} || '/Users/markwkm/local/bin/psql';
$opt{dbuser} = $opt{dbuser} || ['selena'];

if (!$opt{db}) {
  $opt{db} = $opt{dbname} || ['pms-devel'];
}

## Everything from here on out needs psql, so find and verify a working version:
if ($NO_PSQL_OPTION) {
    delete $opt{PSQL};
}

if (! defined $PSQL or ! length $PSQL) {
    if (exists $opt{PSQL}) {
        $PSQL = $opt{PSQL};
        $PSQL =~ m{^/[\w\d\/]*psql$} or die qq{Invalid psql argument: must be full path to a file named psql\n};
        -e $PSQL or die qq{Cannot find given psql executable: $PSQL\n};
    }
    else {
        chomp($PSQL = qx{which psql});
        $PSQL or die qq{Could not find a suitable psql executable\n};
    }
}
-x $PSQL or die qq{The file "$PSQL" does not appear to be executable\n};
$res = qx{$PSQL --version};
$res =~ /^psql \(PostgreSQL\) (\d+\.\d+)/ or die qq{Could not determine psql version\n};
our $psql_version = $1;

$VERBOSE >= 1 and warn qq{psql=$PSQL version=$psql_version\n};

$opt{defaultdb} = $psql_version >= 7.4 ? 'postgres' : 'template1';

####


exit;

sub verify_sources {
	## Verify ALL sources related to search param
	## Hand off individual sources to verify_source() for checking
	my $SQL = 'SELECT ';
}

sub verify_source {

	## ?? source needs to be treated the same as patches
	## Look in sources.url -
	## verify that source_type exists
	## match whatever we find against source_filters
	## grab source filters based on sources.id
	##  - no source filters: case -- if HEAD from repo, then OK, 
	##    otherwise: raise error that no source filter is defined 
	## if found, then apply filter to directory contents 
	## create an entry in the patches table for every new item found return 


}

sub default_actions {

	## Set up default actions for a new source

}

sub alter_actions {
	## Change actions for a particular source

}

sub assign_patches {
	## Assign a set of patches to a source
}

sub run {
	## Kick off a build based on Source X and patchset Y
}

sub fetch_source {
	## Grab sources based on URL in sources table
	## wget vs. curl (which one is installed?)o
	## Configuration param for each
	## Default is curl
}

sub fetch_with_wget {
}
sub fetch_with_curl {
}

######

sub run_command {

    ## Run a command string against each of our databases using psql
    ## Optional args in a hashref:
    ## "failok" - don't report if we failed
    ## "target" - use this targetlist instead of generating one
    ## "timeout" - change the timeout from the default of $opt{timeout}
    ## "regex" - the query must match this or we throw an error
    ## "emptyok" - it's okay to not match any rows at all
    ## "version" - alternate versions for different versions
    ## "dbnumber" - connect with an alternate set of params, e.g. port2 dbname2

    my $string = shift || '';
    my $arg = shift || {};
    my $info = { command => $string, db => [], hosts => 0 };

    $VERBOSE >= 3 and warn qq{Starting run_command with "$string"\n};

    my (%host,$passfile,$passfh,$tempdir,$tempfile,$tempfh,$errorfile,$errfh);
    my $offset = -1;

    ## Build a list of all databases to connect to.
    ## Number is determined by host, port, and db arguments
    ## Multi-args are grouped together: host, port, dbuser, dbpass
    ## Grouped are kept together for first pass
    ## The final arg in a group is passed on
    ##
    ## Examples:
    ## --host=a,b --port=5433 --db=c
    ## Connects twice to port 5433, using database c, to hosts a and b
    ## a-5433-c b-5433-c
    ##
    ## --host=a,b --port=5433 --db=c,d
    ## Connects four times: a-5433-c a-5433-d b-5433-c b-5433-d
    ##
    ## --host=a,b --host=foo --port=1234 --port=5433 --db=e,f
    ## Connects six times: a-1234-e a-1234-f b-1234-e b-1234-f foo-5433-e foo-5433-f
    ##
    ## --host=a,b --host=x --port=5432,5433 --dbuser=alice --dbuser=bob -db=baz
    ## Connects three times: a-5432-alice-baz b-5433-alice-baz x-5433-bob-baz

    ## The final list of targets:
    my @target;

    ## Default connection options
    my $conn =
        {
         host   => ['<none>'],
         port   => [5432],
         dbname => [$opt{defaultdb}],
         dbuser => [$opt{defaultuser}],
         dbpass => [''],
         inputfile => [''],
         };

    my $gbin = 0;
  GROUP: {
        ## This level controls a "group" of targets

        ## If we were passed in a target, use that and move on
        if (exists $arg->{target}) {
            push @target, $arg->{target};
            last GROUP;
        }

        my %group;
        my $foundgroup = 0;
        for my $v (keys %$conn) {
            my $vname = $v;
            ## Something new?
            if ($arg->{dbnumber}) {
                $v .= "$arg->{dbnumber}";
            }
            if (defined $opt{$v}->[$gbin]) {
                my $new = $opt{$v}->[$gbin];
                $new =~ s/\s+//g;
                ## Set this as the new default
                $conn->{$vname} = [split /,/ => $new];
                $foundgroup = 1;
            }
            $group{$vname} = $conn->{$vname};
        }

        if (!$foundgroup) { ## Nothing new, so we bail
            last GROUP;
        }
        $gbin++;

        ## Now break the newly created group into individual targets
        my $tbin = 0;
      TARGET: {
            my $foundtarget = 0;
            ## We know th
            my %temptarget;
            for my $g (keys %group) {
                if (defined $group{$g}->[$tbin]) {
                    $conn->{$g} = [$group{$g}->[$tbin]];
                    $foundtarget = 1;
                }
                $temptarget{$g} = $conn->{$g}[0];
            }

            ## Leave if nothing new
            last TARGET if ! $foundtarget;

            ## Add to our master list
            push @target, \%temptarget;

            $tbin++;
            redo;
        } ## end TARGET

        redo;
    } ## end GROUP

    if (! @target) {
        die qq{No target databases found\n};
    }

    ## Create a temp file to store our results
    $tempdir = tempdir(CLEANUP => 1);
    ($tempfh,$tempfile) = tempfile('nagios_psql.XXXXXXX', SUFFIX => '.tmp', DIR => $tempdir);

    ## Create another one to catch any errors
    ($errfh,$errorfile) = tempfile('nagios_psql_stderr.XXXXXXX', SUFFIX => '.tmp', DIR => $tempdir);

    for $db (@target) {

        ## Just to keep things clean:
        truncate $tempfh, 0;
        truncate $errfh, 0;

        ## Store this target in the global target list
        push @{$info->{db}}, $db;

        $db->{pname} = "port=$db->{port} host=$db->{host} db=$db->{dbname} user=$db->{dbuser}";
        my @args = ('-q', '-U', "$db->{dbuser}", '-d', $db->{dbname}, '-t');
        if ($db->{host} ne '<none>') {
            push @args => '-h', $db->{host};
            $host{$db->{host}}++; ## For the overall count
        }
        push @args => '-p', $db->{port};

        if (defined $db->{dbpass} and length $db->{dbpass}) {
            ## Make a custom PGPASSFILE. Far better to simply use your own .pgpass of course
            ($passfh,$passfile) = tempfile('nagios.XXXXXXXX', SUFFIX => '.tmp', DIR => $tempdir);
            $VERBOSE >= 3 and warn "Created temporary pgpass file $passfile\n";
            $ENV{PGPASSFILE} = $passfile;
            printf $passfh "%s:%s:%s:%s:%s\n",
                $db->{host} eq '<none>' ? '*' : $db->{host},
                $db->{port},   $db->{dbname},
                $db->{dbuser}, $db->{dbpass};
            close $passfh or die qq{Could not close $passfile: $!\n};
        }


        push @args, '-o', $tempfile;

        ## If we've got different SQL, use this first run to simply grab the version
        ## Then we'll use that info to pick the real query
        if ($arg->{version}) {
            $arg->{oldstring} = $string;
            $string = 'SELECT version()';
        }

        if (defined $db->{inputfile} and length $db->{inputfile}) {
            push @args, '-f', $db->{inputfile};
        } else { 
            push @args, '-c', $string;
        }

        $VERBOSE >= 3 and warn Dumper \@args;

        local $SIG{ALRM} = sub { die 'Timed out' };
        my $timeout = $arg->{timeout} || $opt{timeout};
        alarm 0;

        my $start = $opt{showtime} ? [gettimeofday()] : 0;
        open my $oldstderr, '>&', STDERR or die "Could not dupe STDERR\n";
        open STDERR, '>', $errorfile or die qq{Could not open STDERR?!\n};
        eval {
            alarm $timeout;
            $res = system $PSQL => @args;
        };
        my $err = $@;
        alarm 0;
        open STDERR, '>&', $oldstderr or die "Could not recreate STDERR\n";
        close $oldstderr or die qq{Could not close STDERR copy: $!\n};
        if ($err) {
            if ($err =~ /Timed out/) {
                die qq{Command: "$string" timed out! Consider boosting --timeout higher than $timeout\n};
            }
            else {
                die q{Unknown error inside of the "run_command" function};
            }
        }

        $db->{totaltime} = sprintf '%.2f', $opt{showtime} ? tv_interval($start) : 0;

        if ($res) {
            $res >>= 8;
            $db->{fail} = $res;
            $VERBOSE >= 3 and !$arg->{failok} and warn qq{System call failed with a $res\n};
            seek $errfh, 0, 0;
            {
                local $/;
                $db->{error} = <$errfh> || '';
                $db->{error} =~ s/\s*$//;
                $db->{error} =~ s/^psql: //;
                $ERROR = $db->{error};
            }
            if (!$db->{ok} and !$arg->{failok}) {
                die "Query failed: $string\n";
            }
        }
        else {
            seek $tempfh, 0, 0;
            {
                local $/;
                $db->{slurp} = <$tempfh>;
            }
            $db->{ok} = 1;

            ## Allow an empty query (no matching rows) if requested
            if ($arg->{emptyok} and $db->{slurp} =~ /^\s*$/o) {
            }
            ## If we were provided with a regex, check and bail if it fails
            elsif ($arg->{regex}) {
                if ($db->{slurp} !~ $arg->{regex}) {
                    die "Regex failed for query: $string\n";
                }
            }

        }

        ## If we are running different queries based on the version, 
        ## find the version we are using, replace the string as needed, 
        ## then re-run the command to this connection.
        if ($arg->{version}) {
            if ($db->{error}) {
                die $db->{error};
            }
            if ($db->{slurp} !~ /PostgreSQL (\d+\.\d+)/) {
                die qq{Could not determine version of Postgres!\n};
            }
            $db->{version} = $1;
            $string = $arg->{version}{$db->{version}} || $arg->{oldstring};
            delete $arg->{version};
            redo;
        }
    } ## end each database

    close $errfh or die qq{Could not close $errorfile: $!\n};
    close $tempfh or die qq{Could not close $tempfile: $!\n};

    $info->{hosts} = keys %host;

    $VERBOSE >= 3 and warn Dumper $info;

    return $info;


} ## end of run_command

1;
