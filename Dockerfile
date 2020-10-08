FROM 169942020521.dkr.ecr.eu-west-1.amazonaws.com/base/perl:5.18-centos

ENV MOJO_LISTEN=http://*:2000

EXPOSE 2000
