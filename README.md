# NAME

Test::Class::Moose - Serious testing for serious Perl

# VERSION

version 0.58

# SYNOPSIS

    package TestsFor::DateTime;
    use Test::Class::Moose;
    use DateTime;

    # methods that begin with test_ are test methods.
    sub test_constructor {
        my $test = shift;
        $test->test_report->plan(3);    # strictly optional

        can_ok 'DateTime', 'new';
        my %args = (
            year  => 1967,
            month => 6,
            day   => 20,
        );
        isa_ok my $date = DateTime->new(%args), 'DateTime';
        is $date->year, $args{year}, '... and the year should be correct';
    }

    1;

# DESCRIPTION

See the [Test::Class::Moose home page](http://ovid.github.io/test-class-moose/) for
a summary.

`Test::Class::Moose` is a powerful testing framework for Perl. Out of the box
you get:

- Reporting
- Extensibility
- Tagging tests
- Parallel testing
- Test inheritance
- Write your tests using Moose
- All the testing functions and behavior from Test::Most
- Event handlers for startup, setup, teardown, and shutdown of test classes

Better docs will come later. You should already know how to use Moose and
[Test::Class](https://metacpan.org/pod/Test::Class).

# BASICS

## Inheriting from Test::Class::Moose

Just `use Test::Class::Moose`. That's all. You'll get all [Test::Most](https://metacpan.org/pod/Test::Most) test
functions, too, along with `strict` and `warnings`. You can use all [Moose](https://metacpan.org/pod/Moose)
behavior, too.

## Declare a test method

All method names that begin with `test_` are test methods. Methods that do
not are not test methods.

    sub test_this_is_a_method {
        my $test = shift;

        $test->this_is_not_a_test_method;
        ok 1, 'whee!';
    }

    sub this_is_not_a_test_method {
       my $test = shift;
       # but you can, of course, call it like normal
    }

You may specify `Test` and `Tests` method attributes, just like in
[Test::Class](https://metacpan.org/pod/Test::Class) and the method will automatically be a test method, even if
does not start with `test_`:

    sub this_is_a_test : Test {
        pass 'we have a single test';
    }

    sub another_test_method : Tests { # like "no_plan"
        # a bunch of tests
    }

    sub yet_another_test_method : Tests(7) { # sets plan to 7 tests
        ...
    }

__Note__: Prior to version 0.51, this feature only worked if you had the
optional `Sub::Attribute` installed.

## Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit `done_testing` call.

If you prefer, you can declare a plan in a test method:

    sub test_something {
        my $test = shift;
        $test->test_report->plan($num_tests);
        ...
    }

Or with a `Tests` attribute:

    sub test_something : Tests(3) {
        my $test = shift;
        ...
    }

You may call `plan()` multiple times for a given test method. Each call to
`plan()` will add that number of tests to the plan.  For example, with a
method modifier:

    before 'test_something' => sub {
        my $test = shift;
        $test->test_report->plan($num_extra_tests);

        # more tests
    };

Please note that if you call `plan`, the plan will still show up at the end
of the subtest run, but you'll get the desired failure if the number of tests
run does not match the plan.

## Inheriting from another Test::Class::Moose class

List it as the `extends` in the import list.

    package TestsFor::Some::Class::Subclass;
    use Test::Class::Moose extends => 'TestsFor::Some::Class';

    sub test_me {
        my $test  = shift;
        my $class = $test->test_class;
        ok 1, "I overrode my parent! ($class)";
    }

    before 'test_this_baby' => sub {
        my $test  = shift;
        my $class = $test->test_class;
        pass "This should run before my parent method ($class)";
    };

    sub this_should_not_run {
        my $test = shift;
        fail "We should never see this test";
    }

    sub test_this_should_be_run {
        for ( 1 .. 5 ) {
            pass "This is test number $_ in this method";
        }
    }

    1;

# TEST CONTROL METHODS

Do not run tests in test control methods. This will cause the test control
method to fail (this is a feature, not a bug).  If a test control method
fails, the class/method will fail and testing for that class should stop.

__Every__ test control method will be called as a method. The invocant is the
instance of your test class

The available test control methods are:

## `test_startup`

    sub test_startup {
       my $test = shift;
       $test->next::method;
       # more startup
    }

Runs at the start of each test class. If you need to know the name of the
class you're running this in (though usually you shouldn't), use
`$test->test_class`, or you can do this:

    sub test_startup {
        my $test                 = shift;
        my $report               = $test->test_report;
        my $class                = $report->current_class->name;
        my $upcoming_test_method = $report->current_method->name;
        ...
    }

The `$test->test_report` object is a [Test::Class::Moose::Report::Instance](https://metacpan.org/pod/Test::Class::Moose::Report::Instance)
object.

## `test_setup`

    sub test_setup {
       my $test = shift;
       $test->next::method;
       # more setup
    }

Runs at the start of each test method. If you must know the name of the test
you're about to run, you can do this:

    sub test_setup {
       my $test = shift;
       $test->next::method;
       my $test_method = $test->test_report->current_method->name;
       # do something with it
    }

## `test_teardown`

    sub test_teardown {
       my $test = shift;
       # more teardown
       $test->next::method;
    }

Runs at the end of each test method.

## `test_shutdown`

    sub test_shutdown {
        my $test = shift;
        # more teardown
        $test->next::method;
    }

Runs at the end of each test class.

## Overriding Test Control Methods

To override a test control method, just remember that this is OO:

    sub test_setup {
        my $test = shift;
        $test->next::method; # optional to call parent test_setup
        # more setup code here
    }

# TEST CLASS INSTANCES

__This feature is still considered experimental.__

By default, each test class you create will be instantiated once. However, you
can tell the [Test::Class::Moose::Runner](https://metacpan.org/pod/Test::Class::Moose::Runner) to create multiple instances of a
test class.

To do this, simply consume the
[Test::Class::Moose::Role::ParameterizedInstances](https://metacpan.org/pod/Test::Class::Moose::Role::ParameterizedInstances) role in your test
class. This role requires you to implement a `_constructor_parameter_sets`
method in your test class. That method will be called as a _class method_. It
is expected to return a list of key/value pairs. The keys are the name of the
instance and the values are hashrefs of attributes to be passed to your test
class's constructor. Here's a really dumb example:

    package TestsFor::PlainAndFancy;
    use Test::Class::Moose;
    with 'Test::Class::Moose::Role::ParameterizedInstances';

    has is_fancy => (
        is       => 'ro',
        isa      => 'Bool',
        required => 1,
    );

    sub _constructor_parameter_sets {
        my $class = shift;
        return (
            "$class - plain" => { is_fancy => 0 },
            "$class - fancy" => { is_fancy => 1 },
        );
    }

    sub test_something { ... }

The test runner will run all the test methods in your class _once per
instance_, and each instance will be run in its own subtest.

Note that this feature has great potential for abuse, so use it
cautiously. That said, there are cases where this feature can greatly simplify
your test code.

# RUNNING THE TEST SUITE

See the docs for [Test::Class::Moose::Runner](https://metacpan.org/pod/Test::Class::Moose::Runner) for details on running your
test suite. If you'd like to get up and running quickly, here's a very simple
test file you can use:

    use Test::Class::Moose::Load 't/lib';
    use Test::Class::Moose::Runner;
    Test::Class::Moose::Runner->new->runtests;

Put this in a file like `t/run-test-class.t`. When you run it with prove it
will load all the test classes defined in `t/lib` and run them sequentially.

## Skipping Classes and Methods

If you wish to skip a class, set the reason in the `test_startup` method.

    sub test_startup {
        my $test = shift;
        $test->test_skip("I don't want to run this class");
    }

If you wish to skip an individual method, do so in the `test_setup` method.

    sub test_setup {
        my $test = shift;
        my $test_method = $test->test_report->current_method;

        if ( 'test_time_travel' eq $test_method->name ) {
            $test->test_skip("Time travel not yet available");
        }
    }

## The "Tests" and "Test" Attributes

If you're comfortable with [Test::Class](https://metacpan.org/pod/Test::Class), you know that test methods methods are
declared in [Test::Class](https://metacpan.org/pod/Test::Class) with `Test` (for a method with a single test) or
`Tests`, for a method with multiple tests. This also works for
`Test::Class::Moose`. Test methods declared this way do not need to start
with `test_`.

    sub something_we_want_to_check : Test {
        # this method may have only one test
    }

    sub something_else_to_check : Tests {
        # this method may have multiple tests
    }

    sub another_test_method : Tests(3) {
        # this method must have exactly 3 tests
    }

If a test method overrides a parent test method and calls it, their plans will
be added together:

    package TestsFor::Parent;

    use Test::Class::Moose;

    sub some_test : Tests(3) {
        # three tests
    }

And later:

    package TestsFor::Child;

    use Test::Class::Moose extends => 'TestsFor::Parent';

    sub some_test : Tests(2) {
        my $test = shift;
        $test->next::method;
        # 2 tests here
    }

In the above example, `TestsFor::Parent::some_test` will run three tests, but
`TestsFor::Child::some_test` will run _five_ tests (two tests, plus the
three from the parent).

Note that if a plan is explicitly declared, any modifiers or overriding
methods calling the original method will also have to assert the number of
tests to ensure the plan is correct. The above `TestsFor::Parent` and
`TestsFor::Child` code would fail if the child's `some_test` method
attribute was `Tests` without the number of tests asserted.

Do not use `Test` or `Tests` with test control methods because you don't run
tests in those.

## Tagging Methods

Sometimes you want to be able to assign metadata to help you better manage
your test suite. You can do this with tags:

    sub test_save_poll_data : Tags(api network) {
        ...
    }

Tags are strictly optional and you can provide one or more tags for each test
method with a space separated list of tags. You can use this to filter your
tests suite, if desired. For example, if your network goes down and all tests
which rely on a network are tagged with `network`, you can skip those tests
with this:

    Test::Class::Moose::Runner->new( exclude_tags => 'network' )->runtests;

Or maybe you want to run all `api` and `database` tests, but skip those
marked `deprecated`:

    Test::Class::Moose::Runner->new(
        include_tags => [qw/api database/],
        exclude_tags => 'deprecated',
    )->runtests;

You can also inspect tags withing your test classes:

    sub test_setup {
        my $test          = shift;
        my $method_to_run = $test->test_report->current_method;
        if ( $method_to_run->has_tag('db') ) {
            $test->load_database_fixtures;
        }
    }

Tagging support relies on [Sub::Attribute](https://metacpan.org/pod/Sub::Attribute). If this module is not available,
`include_tags` and `exclude_tags` will be ignored, but a warning will be
issued if those are seen. Prior to version 0.51, `Sub::Attribute` was
optional. Now it's mandatory, so those features should always work.

# THINGS YOU CAN OVERRIDE

... but probably shouldn't.

As a general rule, methods beginning with `/^test_/` are reserved for
[Test::Class::Moose](https://metacpan.org/pod/Test::Class::Moose). This makes it easier to remember what you can and
cannot override. However, any test with `Test` or `Tests` are test methods
regardless of their names.

## `test_report`

    my $report = $test->test_report;

Returns the [Test::Class::Moose::Report](https://metacpan.org/pod/Test::Class::Moose::Report) object. Useful if you want to do
your own reporting and not rely on the default output provided with the
`statistics` boolean option.

You can also call it in test classes (most useful in the `test_setup()` method):

    sub test_setup {
        my $test = shift;
        $self->next::method;
        my $report= $test->test_report;
        my $class = $test->current_class;
        my $method = $test->current_method; # the test method we're about to run
        if ( $method->name =~ /customer/ ) {
            $test->load_customer_fixture;
        }
        # or better still
        if ( $method->has_tag('customer') ) {
            $test->load_customer_fixture;
        }
    }

## `test_class`

    my $class = $test->test_class;

Returns the name for this test class. Useful if you rebless an object (such as
applying a role at runtime) and don't want to lose the original class name.

## `test_methods`

You may override this in a subclass. Currently returns all methods in a test
class that start with `test_` (except for the test control methods).

Please note that the behavior for `include` and `exclude` is also contained
in this method. If you override it, you will need to account for those
yourself.

## `import`

Sadly, we have an `import` method. This is used to automatically provide you
with all of the [Test::Most](https://metacpan.org/pod/Test::Most) behavior.

# SAMPLE TAP OUTPUT

We use nested tests (subtests) at each level:

    1..2
    #
    # Executing tests for TestsFor::Basic::Subclass
    #
        1..3
        # TestsFor::Basic::Subclass->test_me()
            ok 1 - I overrode my parent! (TestsFor::Basic::Subclass)
            1..1
        ok 1 - test_me
        # TestsFor::Basic::Subclass->test_this_baby()
            ok 1 - This should run before my parent method (TestsFor::Basic::Subclass)
            ok 2 - whee! (TestsFor::Basic::Subclass)
            1..2
        ok 2 - test_this_baby
        # TestsFor::Basic::Subclass->test_this_should_be_run()
            ok 1 - This is test number 1 in this method
            ok 2 - This is test number 2 in this method
            ok 3 - This is test number 3 in this method
            ok 4 - This is test number 4 in this method
            ok 5 - This is test number 5 in this method
            1..5
        ok 3 - test_this_should_be_run
    ok 1 - TestsFor::Basic::Subclass
    #
    # Executing tests for TestsFor::Basic
    #
        1..2
        # TestsFor::Basic->test_me()
            ok 1 - test_me() ran (TestsFor::Basic)
            ok 2 - this is another test (TestsFor::Basic)
            1..2
        ok 1 - test_me
        # TestsFor::Basic->test_this_baby()
            ok 1 - whee! (TestsFor::Basic)
            1..1
        ok 2 - test_this_baby
    ok 2 - TestsFor::Basic
    # Test classes:    2
    # Test methods:    5
    # Total tests run: 11
    ok
    All tests successful.
    Files=1, Tests=2,  2 wallclock secs ( 0.03 usr  0.00 sys +  0.27 cusr  0.01 csys =  0.31 CPU)
    Result: PASS

# REPORTING

See [Test::Class::Moose::Report](https://metacpan.org/pod/Test::Class::Moose::Report) for more detailed information on reporting.

Reporting features are subject to change.

Sometimes you want more information about your test classes, it's time to do
some reporting. Maybe you even want some tests for your reporting. If you do
that, run the test suite in a subtest (because the plans will otherwise be
wrong).

    #!/usr/bin/env perl
    use lib 'lib';
    use Test::Most;
    use Test::Class::Moose::Load qw(t/lib);
    use Test::Class::Moose::Runner;

    my $test_suite = Test::Class::Moose::Runner->new;

    subtest 'run the test suite' => sub {
        $test_suite->runtests;
    };
    my $report = $test_suite->test_report;

    foreach my $class ( $report->all_test_instances ) {
        my $class_name = $class->name;
        ok !$class->is_skipped, "$class_name was not skipped";
        ok $class->passed, "$class_name passed";

        subtest "$class_name methods" => sub {
            foreach my $method ( $class->all_test_methods ) {
                my $method_name = $method->name;
                ok $method->passed, "$method_name passed";

                ok !$method->is_skipped, "$method_name was not skipped";
                cmp_ok $method->num_tests, '>', 0,
                  '... and some tests should have been run';
                diag "Run time for $method_name: ".$method->time->duration;
            }
        };
        my $time   = $class->time;
        diag "Run time for $class_name: ".$class->time->duration;

        my $real   = $time->real;
        my $user   = $time->user;
        my $system = $time->system;
        # do with these as you will
    }
    diag "Number of test instances: " . $report->num_test_instances;
    diag "Number of test methods: "   . $report->num_test_methods;
    diag "Number of tests:        "   . $report->num_tests;

    done_testing;

If you just want to output reporting information, you do not need to run the
test suite in a subtest:

    my $test_suite = Test::Class::Moose::Runner->new->runtests;
    my $report     = $test_suite->test_report;
    ...

Or even shorter:

    my $report = Test::Class::Moose::Runner->new->runtests->test_report;

# EXTRAS

If you would like [Test::Class::Moose](https://metacpan.org/pod/Test::Class::Moose) to take care of loading your classes
for you, see [Test::Class::Moose::Role::AutoUse](https://metacpan.org/pod/Test::Class::Moose::Role::AutoUse) in this distribution.

# DEPRECATIONS

## Version 0.55

- Running tests with Test::Class::Moose is deprecated - use [Test::Class::Moose::Runner](https://metacpan.org/pod/Test::Class::Moose::Runner)

    As of version 0.55, running tests and being a test class have been
    separated. Your test classes should continue to `use Test::Class::Moose`, but
    your test runner script should use [Test::Class::Moose::Runner](https://metacpan.org/pod/Test::Class::Moose::Runner):

        use Test::Class::Moose::Load 't/lib';
        use Test::Class::Moose::Runner;
        Test::Class::Moose::Runner->new->runtests;

    Calling `Test::Class::Moose->new->runtests` still works, but is
    deprecated and will issue a warning.

- Parallel testing is totally different

    The `Test::Class::Moose::Role::Parallel` role won't do anything other than
    issue a warning. See the [Test::Class::Moose::Runner](https://metacpan.org/pod/Test::Class::Moose::Runner) docs for details on
    running tests in parallel.

- The [Test::Class::Moose::Report](https://metacpan.org/pod/Test::Class::Moose::Report) `all_test_classes` method is deprecated

    This has been replaced with the `all_test_instances` method. The
    `all_test_classes` method is still present for backwards compatibility, but
    it simply calls `all_test_instances` under the hood.

- The `Test::Class::Moose::Report::Class` class is gone

    It has been replaced by the `Test::Class::Moose::Report::Instance` class,
    which has the same API.

- The `Test::Class::Moose::Report::Method` `class_report` method has been renamed

    This is now called `instance_report`.

## Version 0.40

- `test_reporting`

    As of version 0.40, the long deprecated method `test_reporting` has now been
    removed.

- `$report` argument to methods deprecated

    Prior to version 0.40, you used to have a second argument to all test methods
    and test control methods:

        sub test_something {
            my ( $test, $report ) = @_;
            ...
        }

    This was annoying. It was doubly annoying in test control methods in case you
    forgot it:

        sub test_setup {
            my ( $test, $report ) = @_;
            $test->next::method; # oops, needed $report
            ...
        }

    That second argument is still passed, but it's deprecated. It's now
    recommended that you call the `$test->test_report` method to get that.
    Instead of this:

        sub test_froblinator {
            my ( $test, $report ) = @_;
            $report->plan(7);
            ...
        }

    You write this:

        sub test_froblinator {
            my $test = shift;
            $test->test_report->plan(7);
            ...
        }

# TODO

- Callbacks for tags (for example, 'critical' tags could bailout)
- New test phases - start and end suite, not just start and end class/method

# BUGS

Please report any bugs or feature requests to `bug-test-class-moose at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Class-Moose).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Class::Moose

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Class-Moose)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Test-Class-Moose](http://annocpan.org/dist/Test-Class-Moose)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Test-Class-Moose](http://cpanratings.perl.org/d/Test-Class-Moose)

- Search CPAN

    [http://search.cpan.org/dist/Test-Class-Moose/](http://search.cpan.org/dist/Test-Class-Moose/)

# SEE ALSO

- [Test::Routine](https://metacpan.org/pod/Test::Routine)

    I always pointed people to this when they would ask about [Test::Class](https://metacpan.org/pod/Test::Class) +
    [Moose](https://metacpan.org/pod/Moose), but I would always hear "that's not quite what I'm looking for".
    I don't quite understand what the reasoning was, but I strongly encourage you
    to take a look at [Test::Routine](https://metacpan.org/pod/Test::Routine).

- [Test::Roo](https://metacpan.org/pod/Test::Roo)

    [Test::Routine](https://metacpan.org/pod/Test::Routine), but with [Moo](https://metacpan.org/pod/Moo) instead of [Moose](https://metacpan.org/pod/Moose).

- [Test::Class](https://metacpan.org/pod/Test::Class)

    xUnit-style testing in Perl.

- [Test::Class::Most](https://metacpan.org/pod/Test::Class::Most)

    [Test::Class](https://metacpan.org/pod/Test::Class) + [Test::Most](https://metacpan.org/pod/Test::Most).

# CONTRIBUTORS

- Dave Rolsky <autarch@urth.org>
- Doug Bell <doug.bell@baml.com>
- Gregory Oschwald <goschwald@maxmind.com>
- Jonathan C. Otsuka <djgoku@gmail.com>
- Neil Bowers <neil@bowers.com>
- Olaf Alders <olaf@wundersolutions.com>
- Ovid <curtis\\\_ovid\\\_poe@yahoo.com>
- Paul Boyd <pboyd@dev3l.net>
- Petrea Corneliu Stefan <stefan@garage-coding.com>
- Stuckdownawell <stuckdownawell@gmail.com>
- Tom Beresford <tom.beresford@bskyb.com>
- Tom Heady <tom@punch.net>
- Udo Oji <Velti@signor.com>

# AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
