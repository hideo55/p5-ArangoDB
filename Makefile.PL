use inc::Module::Install;
name 'ArangoDB';
all_from 'lib/ArangoDB.pm';

requires 'parent';
requires 'Class::Accessor::Lite';
requires 'Carp';
requires 'JSON';
requires 'Scalar::Util';
requires 'List::MoreUtils';
requires 'Furl';
requires 'MIME::Base64';
requires 'Data::Util';

recommends 'Data::Clone';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Fatal';
test_requires 'Test::TCP';
test_requires 'File::Temp';
test_requires 'Test::Mock::Guard';

auto_set_repository;
auto_include;
WriteAll;

sub MY::test_via_harness {"\tprove --lib -Pt::lib::Prove::Plugin::StartArangoDB t\n"}
