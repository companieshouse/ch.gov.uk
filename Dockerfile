FROM 169942020521.dkr.ecr.eu-west-1.amazonaws.com/base/perl:5.18-centos

ENV MOJO_LISTEN=http://*:10000

EXPOSE 10000
