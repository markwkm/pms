#!/usr/bin/perl

use MIME::Base64;

opendir DH, '.';
foreach $file ( readdir DH ) {
    next unless $file =~ m/dat$/;
    open FH, $file;
    $table = $file;
    $table =~ s/\.dat//;
    my $x = '';
    open OH, ">$table\.sql";
    print "processing $table\n";
    while ( $line_data = <FH> ) {
        if ( !$x ) { $x=1; next; }
        chomp $line_data;
        if ( $table eq 'filters' ) { $line_data = filters( $line_data ); }
        if ( $table eq 'filter_requests' ) { $line_data = filter_requests( $line_data ); }
        if ( $table eq 'filter_types' ) { $line_data = filter_types( $line_data ); }
        if ( $table eq 'patches' ) { $line_data = patches( $line_data ); }
        if ( $table eq 'softwares' ) { $line_data = softwares( $line_data ); }
        if ( $table eq 'sources' ) { $line_data = sources( $line_data ); }
        if ( $table eq 'sources_syncs' ) { $line_data = sources_syncs( $line_data ); }
        if ( $table eq 'users' ) { $line_data = users( $line_data ); }
        $line_data =~ s/\'/\\'/g;
        $line_data =~ s/	/\',\'/g;
        $line_data = "\'" . $line_data . "\'" ;
        $line_data =~ s/0000\-00\-00 00:00:00/NULL/g;
        $line_data =~ s/\'null\'/NULL/gi;
        $sql = 'INSERT INTO ' . $table . ' VALUES(' . $line_data . ')';
        print OH $sql . ";\n";
    }
    close FH;
    close OH;
}

my %filters_hash = ();

sub filters {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    $array[3] = filter_check_id( $array[3] );
    my ( $descriptor ) = $array[4];
    if ( $filters_hash{ $descriptor } ) {
        $filters_hash{ $descriptor } += 1;
        $array[4] = $descriptor . "-" . $filters_hash{ $descriptor };
        print "Renaming filter $array[0] to $array[4]\n";
    }
    else {
        $filters_hash{ $descriptor } = 1;
    }
    $line = join '	', @array;
    return $line;
}

sub filter_check_id {
    $id = shift;
    if ( ( $id == -1 ) or ( $id == 0 ) ) { return 1; }
    return $id;
}

sub filter_requests {
    $line = shift;
    my @array = split'	', $line;
    $array[6] = convert( $array[6] );
    $array[7] = convert( $array[7] );
    $array[9] = get_state( $array[9] );
    $line = join '	', @array;
    return $line;
}

sub get_state {
    $code = shift;
    if ( $code == 1 ) { return 'Queued'; }
    if ( $code == 2 ) { return 'Pending'; }
    if ( $code == 3 ) { return 'Running'; }
    if ( $code == 4 ) { return 'Completed'; }
    if ( $code == 5 ) { return 'Canceled'; }
    if ( $code == 6 ) { return 'Failed'; }
    return NULL;
}

sub filter_types {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    $line = join '	', @array;
    return $line;
}

my %patch_hash = ();

sub patches {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    #@array = insert_value( @array, 5, NULL );
    #$patch = get_patch( $array[0] );
    @array = insert_value( @array, 7, NULL );
    @array = insert_value( @array, 9, NULL );
    my ( $descriptor ) = $array[6];
    if ( $patch_hash{ $descriptor } ) {
        $patch_hash{ $descriptor } += 1;
        $array[6] = $descriptor . "-" . $patch_hash{ $descriptor };
        print "Renaming patch $array[0] to $array[6]\n";
    }
    else {
        $patch_hash{ $descriptor } = 1;
    }
    if ( $array[8] == 5 ) { $array[8] ='15'; }
    $line = join '	', @array;
    return $line;
}

sub get_patch {
    $id = shift;
    if ( -f "./patch/patch-$id.bz2" ) {
        print "Preparing patch: $id\n";
        $patch = `bzcat ./patch/patch-$id.bz2`;
        $encoded_patch = encode_base64( $patch );
        return $patch;
    }
    return NULL;
}

sub softwares {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    @array = insert_value( @array, 5, '1' );
    $line = join '	', @array;
    return $line;
}

sub sources {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = "now()";
    $array[2] = "now()";
    $line = join '	', @array;
    return $line;
}

sub sources_syncs {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    $line = join '	', @array;
    return $line;
}

sub users {
    $line = shift;
    my @array = split'	', $line;
    $array[1] = convert( $array[1] );
    $array[2] = convert( $array[2] );
    @array = insert_value( @array, 4, NULL );
    @array = insert_value( @array, 4, NULL );
    $line = join '	', @array;
    return $line;
}
    
sub convert {
    $epoch = shift;
    if ( $epoch <= 0 ) { return "now()"; }
    ( $seconds, $minutes, $hours, $day_of_month, $month, $year, $wday, $yday, $isdst ) = localtime( $epoch );
    $year = $year + 1900;
    $month = $month + 1;
    if ( length( $month ) == 1 ) { $month = "0$month"; }
    if ( length( $day_of_month == 1 ) ) { $day_of_month = "0$day_of_month"; }
    if ( length( $hours ) == 1 ) { $hours = "0$hours"; }
    if ( length( $minutes ) == 1 ) { $minutes = "0$minutes"; }
    if ( length( $seconds ) == 1 ) { $seconds = "0$seconds"; }
    return "$year-$month-$day_of_month $hours:$minutes:$seconds";
}

sub insert_value {
    my @front;
    my @back;
    $value = pop( @_ );
    $element = pop( @_ );
    my @array = @_;
    for ( $count = 0; $count < $element; $count++ ) {
         $front[$count] = $array[$count];
    }
    $size = @array;
    for ( $count = $element; $count < $size; $count++ ) {
         $back[$count-$element] = $array[$count];
    }
    @array = ();
    @array = @front;
    push( @array, $value );
    push( @array, @back );
    return @array;
}
