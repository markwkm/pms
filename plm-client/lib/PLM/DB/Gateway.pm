package PLM::DB::Gateway;

use strict;
use Exporter;

use PLM::DB::Handle;
use PLM::Util;

our( @ISA, @EXPORT );

@ISA = qw( Exporter );

@EXPORT = qw( gatewayInit
  getGatewayID
  getGatewayDBH
  getGatewayTable
  getGatewayField );

my $cfg       = undef;
my $log       = undef;
my @gw        = undef;
my $init_flag = 0;

sub gatewayInit {
    if ( $cfg && $log && @gw ) {
        $log->msg( 0, "Clearing and re-reading INIT" );
        $cfg = $log = @gw = undef;
    }

    $init_flag = 1;
    if ( !$cfg ) { $cfg = PLM::Util::getConfig() }
    if ( !$log ) { $log = PLM::Util::getLog( "DB::Gateway" ) }
    if ( !$gw[ 0 ] ) { loadGatewayConfig() }

    $log->msg( 2, "INIT DONE" );
}

sub loadGatewayConfig {
    $log->msg( 2, "loadGatewayConfig()" );

    for ( my $driver = 1; readDriverOpt( $driver, "dsn" ); $driver++ ) {
        $log->msg( 1, "Loading config for driver: $driver" );

        $gw[ $driver ]{ dsn }  = readDriverOpt( $driver, "dsn" )  || "";
        $gw[ $driver ]{ user } = readDriverOpt( $driver, "user" ) || "";
        $gw[ $driver ]{ pass } = readDriverOpt( $driver, "pass" ) || "";

        unless ( $gw[ $driver ]{ dsn }
                 && $gw[ $driver ]{ user }
                 && $gw[ $driver ]{ pass } )
        {
            $log->msg( 0, "ERROR loading gateway config #$driver" );
            next;
        }

        $log->msg( 1, "Gateway[$driver] ( dsn: $gw[ $driver ]{ dsn } user: ",
                   $gw[ $driver ]{ user } . " )" );

        $gw[ $driver ]{ dbh } = new PLM::DB::Handle(
            {
                dsn  => $gw[ $driver ]{ dsn },
                user => $gw[ $driver ]{ user },
                pass => $gw[ $driver ]{ pass }
            }
        );

        $gw[ $driver ]{ route } = {};
        for ( my $route = 1; readRouteOpt( $driver, $route ); $route++ ) {
            my $data = readRouteOpt( $driver, $route );
            unless ( $data =~ /^\w+\:\w+\:\w+\:\w+$/ ) {
                $log->msg( 0, "Bad route map: '$data'" );
                next;
            }

            my @info = split /\:/, $data;

            $gw[ $driver ]{ route }{ $route } = {};
            $gw[ $driver ]{ route }{ $route }{ local_table }  = $info[ 0 ];
            $gw[ $driver ]{ route }{ $route }{ local_field }  = $info[ 1 ];
            $gw[ $driver ]{ route }{ $route }{ remote_table } = $info[ 2 ];
            $gw[ $driver ]{ route }{ $route }{ remote_field } = $info[ 3 ];

            $log->msg( 0, "Loaded map: '@info'" );
        }
    }
}

sub readDriverOpt {
    my ( $driver, $key ) = @_;

    return $cfg->get( "GW:" . $driver . ":driver:" . $key );
}

sub readRouteOpt {
    my ( $driver, $route ) = @_;

    return $cfg->get( "GW:" . $driver . ":map:" . $route );
}

sub getGatewayID {
    unless ( $init_flag ) { gatewayInit() }

    my ( $table, $field ) = @_;

    for ( my $driver = 1; defined $gw[ $driver ]; $driver++ ) {
        for ( my $route = 1; defined $gw[ $driver ]{ route }{ $route };
              $route++
          )
        {
            if ( $gw[ $driver ]{ route }{ $route }{ local_table } eq $table
                 && $gw[ $driver ]{ route }{ $route }{ local_field } eq $field )
            {
                $log->msg( 4, "Match: [ driver:$driver / route:$route ]" );
                return $driver;
            }
        }
    }

    return 0;    # No valid GW redirects found
}

sub getGatewayDBH {
    my $driver = shift;

    return $gw[ $driver ]{ dbh };
}

sub getGatewayTable {
    my ( $driver, $table ) = @_;

    for ( my $route = 1; defined $gw[ $driver ]{ route }{ $route }; $route++ ) {
        if ( $gw[ $driver ]{ route }{ $route }{ local_table } eq $table ) {
            my $res = $gw[ $driver ]{ route }{ $route }{ remote_table };
            $log->msg( 2, "getGatewayTable( $driver, $table ) = $res" );
            return $res;
        }
    }

    $log->msg( 1, "No route found for driver[$driver] table[$table]" );

    return $table;
}

sub getGatewayField {
    my ( $driver, $field ) = @_;

    for ( my $route = 1; defined $gw[ $driver ]{ route }{ $route }; $route++ ) {
        if ( $gw[ $driver ]{ route }{ $route }{ local_field } eq $field ) {
            my $res = $gw[ $driver ]{ route }{ $route }{ remote_field };
            $log->msg( 2, "getGatewayField( $driver, $field ) = $res" );
            return $res;
        }
    }

    $log->msg( 1, "No route found for driver[$driver] field[$field]" );

    return $field;
}

1;
