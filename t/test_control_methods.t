use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/lib";

use Test2::API qw( intercept );
use Test2::V0;
use Test2::Tools::Subtest qw( subtest_streamed );
use Test::Events;

use Test::Class::Moose::Load "$Bin/basiclib";
use Test::Class::Moose::Runner;

my $runner = Test::Class::Moose::Runner->new(
    {   show_timing => 0,
        statistics  => 0,
    }
);

_replace_subclass_method( test_startup => sub { my $test = shift } );
subtest_streamed(
    'events when test_startup does not die or run tests',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 2;
                };
                TestsFor::Basic->expected_test_events;
                TestsFor::Basic::Subclass->expected_test_events;
                end();
            }
        );
    }
);

_replace_subclass_method( test_startup => sub { die 'forced die' } );
subtest_streamed(
    'events when test_startup dies',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 2;
                };
                TestsFor::Basic->expected_test_events;
                event Subtest => sub {
                    call name      => 'TestsFor::Basic::Subclass';
                    call pass      => F();
                    call subevents => array {
                        event Ok => sub {
                            call name =>
                              'TestsFor::Basic::Subclass->test_startup failed';
                            call pass => F();
                        };
                        event Diag => sub {
                            call message => match
                              qr/\QFailed test 'TestsFor::Basic::Subclass->test_startup failed'\E.+/s;
                        };
                        event Diag => sub {
                            call message => match
                              qr{\Qforced die at \E.*\Qtest_control_methods.t\E.+}s;
                        };
                        event Plan => sub {
                            call max => 1;
                        };
                        end();
                    };
                };
                event Diag => sub {
                    call message => match
                      qr/\QFailed test 'TestsFor::Basic::Subclass'\E.+/s;
                };
                end();
            }
        );
    }
);

_replace_subclass_method(
    test_startup => sub {
        pass();
    },
);
subtest_streamed(
    'events when test_startup runs tests',
    sub {
        test_events_is(
            intercept { $runner->runtests },
            array {
                event Plan => sub {
                    call max => 2;
                };
                TestsFor::Basic->expected_test_events;
                event Subtest => sub {
                    call name      => 'TestsFor::Basic::Subclass';
                    call pass      => F();
                    call subevents => array {
                        event Ok => sub {
                            call name => undef;
                            call pass => T();
                        };
                        event Ok => sub {
                            call name =>
                              'TestsFor::Basic::Subclass->test_startup failed';
                            call pass => F();
                        };
                        event Diag => sub {
                            call message => match
                              qr/\QFailed test 'TestsFor::Basic::Subclass->test_startup failed'\E.+/s;
                        };
                        event Diag => sub {
                            call message => match
                              qr/\QTests may not be run in test control methods (test_startup)\E.+/s;
                        };
                        event Plan => sub {
                            call max => 2;
                        };
                        end();
                    };
                };
                event Diag => sub {
                    call message => match
                      qr/\QFailed test 'TestsFor::Basic::Subclass'\E.+/s;
                };
                end();
            }
        );
    }
);

done_testing;

sub _replace_subclass_method {
    my $name   = shift;
    my $method = shift;

    TestsFor::Basic::Subclass->meta->remove_method($name);
    TestsFor::Basic::Subclass->meta->add_method( $name => $method );
}

