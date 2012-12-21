package Catalyst::Model::Tarantool;

use 5.014002;
use strict;
use warnings;

use base 'Catalyst::Model';

use MRO::Compat;
use mro 'c3';
use MR::Tarantool::Box;

our $VERSION = '0.01';


__PACKAGE__->mk_accessors( qw/_handler/ );

sub new {
    my $self = shift->next::method( @_ );
    my ( $c, $config ) = @_;
    $self->{servers} ||= $config->{servers};
    $self->{name} ||= $config->{name};
    $self->{spaces} ||= $config->{spaces};
    $self->{default_space} ||= $config->{default_space};
    $self->{timeout} ||= $config->{timeout};
    
    $self->{retry} ||= $config->{retry};
    $self->{debug_level} ||= $self->{debug};
    $self->{raise} ||= $config->{raise};
    
    $self->{log} = $c->log;
    $self->{debug} = $c->debug;
    
    return $self;
    
}

sub handler{
    my ($self) = @_;
    my $connection = $self->_handler;
    unless ( $connection ) {
        eval {
            my $connection = MR::Tarantool::Box->new({
                servers => $self->{servers},
                name => $self->{name},
                spaces => $self->{spaces},
                default_space => $self->{default_space},
                timeout => $self->{timeout},
                retry => $self->{retry},
                debug => $self->{debug_level},
                raise => $self->{raise}
            });
            $self->_handler( $connection );
        };
        if ($@) {
            $self->{log}->debug( qq/Couldn't connect to the Tarantool via MR::Tarantool::Box "$@"/ )
                if $self->{debug};
        }
    }
    return $connection;
}

1;
__END__

=head1 NAME

Catalyst::Model::Tarantool

=head1 SYNOPSIS

MyApp.pm

    use Catalyst::Model::Tarantool;
    __PACKAGE__->config(
	servers => "127.0.0.1:33013",
	name    => "users",              # mostly used for debug purposes
	spaces => [
	    {
	    indexes => [
		    {
			index_name   => 'id', # num
			keys         => [0],
		    }, {
			index_name   => 'user_name', # str
			keys         => [0],	
		    }, {
			index_name   => 'first_name', # str
			keys         => [0],	
		    }, {
			index_name   => 'last_name', # str
			keys         => [0],	
		    } ],
	    space         => 0,               # space id, as set in Tarantool/Box config
	    name          => "primary",       # self-descriptive space-id
	    format        => "l&&&",         # pack()-compatible, Qq must be supported by perl itself, see perldoc -f pack
					      # & stands for byte-string, $ stands for utf8 string.
	    default_index => 'id',
	    fields        => [qw/ id user_name first_name last_name /], # turn each tuple into hash, field names according to format
	}
    ],
    default_space => "primary",
    timeout   => 1,                   # seconds, not float!
    retry     => 3,
    debug     => 9,                   # output to STDERR some debugging info
    raise     => 1,                   # dont raise an exception in case of error
);
  
MyApp::Controller::Root
    sub index :Path :Args(0) {
	my ( $self, $c ) = @_;
	my $tnt = $c->model('TNT')->handler;
	my $tuple = $tnt->Select( 1 ); # hashref
	$c->stash(tuple => $tuple);
    }

=head1 DESCRIPTION

Tarantool interface for Catalyst based application

=head1 SEE ALSO

Want more? 
L<MR::Tarantool::Box>.

=head1 AUTHOR

Alexey Orlov, E<lt>aorlov@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alexey Orlov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
