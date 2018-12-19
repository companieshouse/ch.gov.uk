# make sure the correct versions of the following modules
# are resolved upfront by "pre-requiring" them.
# XXX unlike the rest of this file, the order in this
# section is important.

# Pin dependencies for api-enumerations files to be read correctly
requires 'Locale::Messages', '==1.29';
requires 'YAML::XS', '==0.74';
requires 'YAML', '==1.26';

requires 'Mojo::Redis', '==1.02'; # Needs to be before MojoX::Plugin::AnyCache
requires 'Log::Log4perl', '==1.49'; # Needs to be before CH::Perl
requires 'Log::Log4perl::Appender::Fluent', '==0.04'; # Needs to be before CH::Perl
requires 'AnyEvent', '==7.12';
requires 'Mojolicious', '==5.47';
requires 'Moose', '==2.1402';

requires 'CH::MojoX::Administration::Plugin', '==0.35';
requires 'Net::CompaniesHouse::Admin', '==0.36'
requires 'Net::CompaniesHouse', '==0.65';
requires 'CH::MojoX::Plugin::API', '==0.40';
requires 'CH::MojoX::Plugin::Config', '==0.31';
requires 'CH::MojoX::Plugin::Exception', '==0.31';
requires 'CH::MojoX::Plugin::HealthCheck', '==0.11';
requires 'CH::MojoX::Plugin::QueueAPI', '==0.31';
requires 'CH::MojoX::Plugin::Xslate', '==0.34';
requires 'CH::MojoX::SignIn::Plugin', '==0.44';
requires 'CH::Perl', '==0.31';
requires 'Crypt::Rijndael', '==1.12';
requires 'Data::Dumper::Concise', '==2.023';
requires 'Date::Calc', '==6.3';
requires 'DateTime::Format::ISO8601', '==0.08';
requires 'DateTime::Tiny', '==1.04';
requires 'Digest::SHA1', '==2.13';
requires 'JSON::WebEncryption', '==0.06';
requires 'Locale::Simple', '==0.016';
requires 'Log::Declare', '==0.10';
requires 'MojoX::JSON::XS', '==0.30';
requires 'MojoX::Log::Declare', '==0.32';
requires 'MojoX::Plugin::AnyCache', '==0.33';
requires 'MojoX::Plugin::Hook::BeforeRendered', '==0.30';
requires 'MojoX::Plugin::PODRenderer', '==0.30';
requires 'MojoX::Plugin::Statsd', '==0.30';
requires 'MojoX::Renderer::IncludeLater', '==0.30';
requires 'MojoX::Renderer::Xslate', '==0.092';
requires 'MojoX::Security::Session', '==0.38';
requires 'MojoX::URL::Sign', '==0.30';
requires 'MooseX::Model', '==0.31';
requires 'Protocol::Redis::XS', '==0.05';
requires 'Readonly', '==2.00';

test_requires 'CH::Test', '==0.32';
test_requires 'Test::Differences', '==0.63';
test_requires 'Test::Exception', '==0.43';
