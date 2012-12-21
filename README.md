# NAME

Test::Class::Moose - Test::Class + Moose

# VERSION

0.01

# SYNOPSIS

    package TestsFor::Some::Class;
    use Test::Class::Moose;

    sub test_me {
        my $test  = shift;
        my $class = $test->this_class;
        ok 1, "test_me() ran ($class)";
        ok 2, "this is another test ($class)";
    }

    sub test_this_baby {
        my $test  = shift;
        my $class = $test->this_class;
        is 2, 2, "whee! ($class)";
    }

    Test::Class::Moose->new->runtests;

    1;

# DESCRIPTION

This is __ALPHA__ code. It is not production ready, but the basics seem to work
well.

This is a tiny proof of concept for writing Test::Class-style tests with
Moose. Better docs will come later. You should already know how to use Moose
and Test::Class.

# BASICS

## Inheriting from Test::Class::Moose

Just `use Test::Class::Moose`. That's all. You'll get all [Test::Most](http://search.cpan.org/perldoc?Test::Most) test
functions, too, along with `strict` and `warnings`. You can use all [Moose](http://search.cpan.org/perldoc?Moose)
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

## Plans

No plans needed. The test suite declares a plan of the number of test classes.

Each test class is a subtest declaring a plan of the number of test methods.

Each test method relies on an implicit `done_testing` call.

## Inheriting from another Test::Class::Moose class

List it as the `extends` (or `parent`) in the import list.

    package TestsFor::Some::Class::Subclass;
    use Test::Class::Moose extends => 'TestsFor::Some::Class';

    sub test_me {
        my $test  = shift;
        my $class = $test->this_class;
        ok 1, "I overrode my parent! ($class)";
    }

    before 'test_this_baby' => sub {
        my $test  = shift;
        my $class = $test->this_class;
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

Do not run tests in test control methods. They are not needed and in the
future, will cause test failures. If a test control method fails, the
class/method should fail. Currently we do not trap exceptions, so your entire
test suite will break. Yes, this is a bug and will be fixed later.

These are:

- `test_startup`

Runs at the start of each test class

- `test_setup`

Runs at the start of each test method

- `test_teardown`

Runs at the end of each test method

- `test_shutdown`

Runs at the end of each test class

To override a test control method, just remember that this is OO:

    sub test_setup {
        my $test = shift;
        $test->next::method; # optional to call parent test_setup
        # more setup code here
    }

# RUNNING THE TEST SUITE

We have a constructor now:

    use Test::Class::Moose::Load 't/lib';
    Test::Class::Moose->new->runtests

Attributes to it:

- `show_timing`

Boolean. Will display verbose information on the amount of time it takes each
test class/test method to run.

- `statistics`

Boolean. Will display number of classes, test methods and tests run.

- `randomize`

Boolean. Will run tests methods in a random order. Ensures test methods are isolated

# ATTRIBUTES

## `builder`

    my $builder = $test->builder;

Returns the Test::Builder object.

## `this_class`

    my $class = $test->this_class;

Returns the name for this class. Useful if you rebless an object (such as
applying a role at runtime) and lose the original class name.

# METHODS

## `get_test_classes`

You may override this in a subclass. Currently returns a sorted list of all
loaded classes that inherit directly or indirectly through
`Test::Class::Moose`

## `get_test_methods`

You may override this in a subclass. Currently returns all methods in a test
class that start with `test_` (except for the test control methods).

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

# TODO

- Add `Test::Class::Moose::Reporting`

Gather up the reporting in one module rather than doing it on an ad-hoc basis.

- Test method filtering

    Test::Class::Moose->new({
        include => qr/customer/,
        exclude => qr/database/,
    })->runtests;
- Load classes

    Test::Class::Moose->new({
       load => sub {
           my $test  = shift;
           my $class = $test->this_class;
           $class    =~ s/^TestsFor:://;
           return $class;
       },
    })->runtests;
    

If present, takes a sub that returns a classname we'll attempt to
automatically load. Completely optional, of course. And then in your test:

    sub test_something {
        my $test   = shift;
        my $class  = $test->class_to_test;
        my $object = $class->new;
        ok ...
    }

Because it's an attribute, you can merely declare it in a subclass, if you
prefer, or override it in a subclass (in other words, this is OO code and you,
the developer, will have full control over it).

- Pass class/methd names to test control methods
- Make it easy to skip an entire class

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

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

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2012 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
