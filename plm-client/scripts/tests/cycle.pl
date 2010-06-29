#!/usr/bin/perl -w 

while ( 1 ) {

    $date = localtime( time() );
    @res  = `./master.pl`;

    print "$date  ";

    for ( @res ) {
        chomp;
        if ( /total\s+fail/i ) {
            print "$_\n";
        }
    }

    for ( @res ) {
        chomp;
        if ( /total\s+fail/i ) {next}
        if ( /(\S+).*FAIL/ )   {
            print "$1\n";
        }
    }

}    # End of loop
