use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use Test::Class::Moose::Load "$Bin/processnamelib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    show_timing      => 0,
    set_process_name => 1,
);

subtest 'test suite' => sub {
    $runner->runtests;
};

done_testing;
