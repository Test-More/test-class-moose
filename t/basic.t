use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test2::API qw( intercept );
use Test2::V0;
use Test2::Tools::Subtest qw( subtest_streamed );
use Test::Events;
use Test::Reporting qw( test_report );

use Test::Class::Moose::Load "$Bin/basiclib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new( show_timing => 0 );

my %methods_for = (
    'TestsFor::Basic' => [
        qw/
          test_me
          test_my_instance_name
          test_reporting
          test_this_baby
          /
    ],
    'TestsFor::Basic::Subclass' => [
        qw/
          test_me
          test_my_instance_name
          test_reporting
          test_this_baby
          test_this_should_be_run
          /
    ],
);
my @test_classes = sort $runner->test_classes;
is \@test_classes, [ sort keys %methods_for ],
  'test_classes() should return a sorted list of test classes';

foreach my $class (@test_classes) {
    is [ sort $class->new->test_methods ], $methods_for{$class},
      "$class should have the correct test methods";
}

subtest_streamed(
    'events from runner',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max   => 2;
                    call trace => object {
                        call package => 'Test::Class::Moose::Role::Executor';
                        call subname =>
                          'Test::Class::Moose::Util::context_do';
                    };
                };
                TestsFor::Basic->expected_test_events;
                TestsFor::Basic::Subclass->expected_test_events;
                end();
            }
        );
    }
);

my %expect = (
    num_tests_run      => 27,
    num_test_instances => 2,
    num_test_methods   => 9,
    classes            => {
        TestsFor::Basic->expected_report,
        TestsFor::Basic::Subclass->expected_report,
    },
);

test_report( $runner->test_report, \%expect );

TestsFor::Basic::Subclass->meta->add_method(
    'test_this_will_die' => sub { die 'forced die' },
);

subtest_streamed(
    'events from runner when a test dies',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 2;
                };
                TestsFor::Basic->expected_test_events;
                event Note => sub {
                    call message => 'Subtest: TestsFor::Basic::Subclass';
                };
                event Subtest => sub {
                    call name      => 'Subtest: TestsFor::Basic::Subclass';
                    call pass      => F();
                    call subevents => array {
                        event Plan => sub {
                            call max => 6;
                        };
                        event Note => sub {
                            call message => 'Subtest: test_me';
                        };
                        event Subtest => sub {
                            call name      => 'Subtest: test_me';
                            call pass      => T();
                            call subevents => array {
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'I overrode my parent! (TestsFor::Basic::Subclass)';
                                };
                                event Plan => sub {
                                    call max => 1;
                                };
                                end();
                            };
                        };
                        event Note => sub {
                            call message => 'Subtest: test_my_instance_name';
                        };
                        event Subtest => sub {
                            call name => 'Subtest: test_my_instance_name';
                            call pass => T();
                            call subevents => array {
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'test_instance_name matches class name';
                                };
                                event Plan => sub {
                                    call max => 1;
                                };
                                end();
                            };
                        };
                        event Note => sub {
                            call message => 'Subtest: test_reporting';
                        };
                        event Subtest => sub {
                            call name      => 'Subtest: test_reporting';
                            call pass      => T();
                            call subevents => array {
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'current_instance() should report the correct class name';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      '... and we should also be able to get the current method name';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'test_setup() should know our current class name';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      '... and our current method name';
                                };
                                event Plan => sub {
                                    call max => 4;
                                };
                                end();
                            };
                        };
                        event Note => sub {
                            call message => 'Subtest: test_this_baby';
                        };
                        event Subtest => sub {
                            call name      => 'Subtest: test_this_baby';
                            call pass      => T();
                            call subevents => array {
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This should run before my parent method (TestsFor::Basic::Subclass)';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'whee! (TestsFor::Basic::Subclass)';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'test_setup() should know our current class name';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      '... and our current method name';
                                };
                                event Plan => sub {
                                    call max => 4;
                                };
                                end();
                            };
                        };
                        event Note => sub {
                            call message =>
                              'Subtest: test_this_should_be_run';
                        };
                        event Subtest => sub {
                            call name => 'Subtest: test_this_should_be_run';
                            call pass => T();
                            call subevents => array {
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This is test number 1 in this method';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This is test number 2 in this method';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This is test number 3 in this method';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This is test number 4 in this method';
                                };
                                event Ok => sub {
                                    call pass => T();
                                    call name =>
                                      'This is test number 5 in this method';
                                };
                                event Plan => sub {
                                    call max => 5;
                                };
                                end();
                            };
                        };
                        event Note => sub {
                            call message => 'Subtest: test_this_will_die';
                        };
                        event Subtest => sub {
                            call name      => 'Subtest: test_this_will_die';
                            call pass      => F();
                            call subevents => array {
                                end();
                            };
                        };
                        event Diag => sub {
                            call message => match qr{^\n?Failed test};
                        };
                        event Diag => sub {
                            call message => match
                              qr{\Qforced die at \E.*\Qbasic.t\E.+}s;
                        };
                        end();
                    };
                };
                event Diag => sub {
                    call message => match qr{^\n?Failed test};
                };
                end();
            }
        );
    }
);

done_testing;
