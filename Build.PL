use strict;
use warnings FATAL => 'all';
use Module::Build;
use Module::CPANfile;

my $file   = Module::CPANfile->load("cpanfile");
my $prereq = $file->prereq_specs;

my $class = Module::Build->subclass( code => <<'END_OF_CODE' );
sub ACTION_test {
    my $self = shift;
    require App::Prove;
    my $prove = App::Prove->new();
    my @args = qw(--lib -Pt::lib::Prove::Plugin::StartArangoDB);
    $prove->process_args(@args, @{$self->{properties}{test_files}});
    $prove->run();
}
END_OF_CODE

$class->new(
    name                 => 'ArangoDB',
    module_name          => 'ArangoDB',
    dist_author          => 'Hideaki Ohno<hide.o.j55@gmail.com>',
    license              => 'perl',
    recursive_test_files => 1,
    dynamic_config       => 0,
    build_requires       => {
        $prereq->{build} ? %{ $prereq->{build}->{requires} } : (),
        $prereq->{test}  ? %{ $prereq->{test}->{requires} }  : (),
    },
    configure_requires => $prereq->{configure}->{requires},
    requires           => $prereq->{runtime}->{requires},
    recommends         => { 'Data::Clone' => 0, },
    no_index           => { 'directory' => [ 't', 'xt', 'inc', 'eg' ] },
    test_files => ( -d '.git' || $ENV{RELEASE_TESTING} ) ? [qw(t/ xt/)] : ['t/'],
    create_readme  => 1,
    add_to_cleanup => ['ArangoDB-*'],
    meta_merge     => {
        keywords  => [qw/arngodb database/],
        resources => {
            repository => 'git://github.com/hideo55/p5-ArangoDB.git',
            bugtracker => 'https://github.com/hideo55/p5-ArangoDB/issues',
        },
    },
)->create_build_script();
