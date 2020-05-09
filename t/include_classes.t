use strict;
use warnings;

use Test2::V0;

use FindBin qw( $Bin );
use Test::Class::Moose::Load "$Bin/basiclib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    show_timing  => 0,
    test_classes => 'TestsFor::Basic',
);

my %methods_for = (
    'TestsFor::Basic' => [
        qw/
          test_me
          test_my_instance_name
          test_reporting
          test_this_baby
          /
    ],
);
my @test_classes = sort $runner->test_classes;
is( \@test_classes,
    [ sort keys %methods_for ],
    'test_classes() should return a sorted list of test classes'
);

foreach my $class (@test_classes) {
    is( [ sort $class->new->test_methods ],
        [ @{ $methods_for{$class} } ],
        "$class should have the correct test methods"
    );
}

done_testing;
