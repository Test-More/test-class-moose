package Test::Class::Moose::Report::Method;

# ABSTRACT: Reporting on test methods

use strict;
use warnings;
use namespace::autoclean;

use 5.010000;

our $VERSION = '1.00';

use Moose;
use Carp;
use Test::Class::Moose::AttributeRegistry;

with qw(
  Test::Class::Moose::Role::Reporting
);

has test_setup_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_setup_method',
);

has test_teardown_method => (
    is     => 'rw',
    isa    => 'Test::Class::Moose::Report::Method',
    writer => 'set_test_teardown_method',
);

has 'instance' => (
    is       => 'ro',
    isa      => 'Test::Class::Moose::Report::Instance',
    required => 1,
    weak_ref => 1,
);

has 'num_tests_run' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has 'tests_planned' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_plan',
);

sub plan {
    my ( $self, $integer ) = @_;
    $self->tests_planned( ( $self->tests_planned || 0 ) + $integer );
}

sub has_tag {
    my ( $self, $tag ) = @_;
    croak('has_tag(\$tag) requires a tag name') unless defined $tag;
    my $class  = $self->instance->name;
    my $method = $self->name;
    return Test::Class::Moose::AttributeRegistry->method_has_tag(
        $class,
        $method,
        $tag
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for Pod::Coverage plan

=head1 DESCRIPTION

Should be considered experimental and B<read only>.

=head1 IMPLEMENTS

L<Test::Class::Moose::Role::Reporting>.

=head1 ATTRIBUTES

See L<Test::Class::Moose::Role::Reporting> for additional attributes.

=head2 C<instance>

The L<Test::Class::Moose::Report::Instance> for this method.

=head2 C<num_tests_run>

    my $tests_run = $method->num_tests_run;

The number of tests run for this test method.

=head2 C<tests_planned>

    my $tests_planned = $method->tests_planned;

The number of tests planned for this test method. If a plan has not been
explicitly set with C<$report->test_plan>, then this number will always be
equal to the number of tests run.

=head2 C<has_tag>

    my $method = $test->test_report->current_method;
    if ( $method->has_tag('db') ) {
        $test->load_database_fixtures;
    }

Returns true if the current test method has the tag in question.

