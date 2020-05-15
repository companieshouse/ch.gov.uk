FROM 169942020521.dkr.ecr.eu-west-1.amazonaws.com/ci-perl-build:latest

WORKDIR /app

COPY . ./

CMD ["/app/docker-entrypoint.sh"]
