#!perl
requires 'parent'                => 0;
requires 'Scalar::Util'          => '1.19';
requires 'Class::Accessor::Lite' => '0.05';
requires 'Carp'                  => 0;
requires 'JSON'                  => '2.53';
requires 'List::MoreUtils'       => 0;
requires 'Furl::HTTP'            => '0.42';
requires 'MIME::Base64'          => 0;
requires 'Data::Util'            => '0.59';
requires 'Module::Load'          => 0;

on 'configure' => sub {
    requires 'Module::Build'    => '>= 0.38';
    requires 'Module::CPANfile' => 0;
};

on 'build' => sub {
};

on 'test' => sub {
    requires 'Test::More'        => '0.98';
    requires 'Test::More'        => '0.98';
    requires 'App::Prove'        => 0;
    requires 'Test::Fatal'       => '0.008';
    requires 'Test::Deep'        => 0;
    requires 'Test::TCP'         => 0;
    requires 'Test::Mock::Guard' => 0;
    requires 'File::Temp'        => 0;
};

on 'develop' => sub {
    requires '';
};
