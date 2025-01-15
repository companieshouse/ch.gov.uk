FROM 169942020521.dkr.ecr.eu-west-2.amazonaws.com/local/ch.gov.uk:latest

ENV MOJO_LISTEN=http://*:2000

RUN plenv install-cpanm
RUN plenv exec cpanm --notest Mojolicious
#RUN plenv exec cpanm --notest MojoX::Log::Declare

COPY . /app

EXPOSE 2000
