FROM 416670754337.dkr.ecr.eu-west-2.amazonaws.com/ch.gov.uk:latest

COPY . .

ENV MOJO_LISTEN=http://*:10000

EXPOSE 10000
