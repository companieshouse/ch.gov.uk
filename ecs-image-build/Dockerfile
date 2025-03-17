ARG IMAGE_VERSION="latest"
FROM 416670754337.dkr.ecr.eu-west-2.amazonaws.com/ci-perl-build-ecs:${IMAGE_VERSION}

WORKDIR /opt/ch.gov.uk
COPY /app .
COPY docker_start.sh .

CMD ["./docker_start.sh"]
