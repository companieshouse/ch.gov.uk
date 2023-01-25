ch.gov.uk
=========

The Companies House [public beta service](https://beta.companieshouse.gov.uk/) core web application.

Requirements
------------

In order to build this service you need:

- GNU Make
- [GetPAN](https://github.com/ian-kent/gopan/tree/master/getpan) for dependency resolution

In order to run this service you need:

- [Perl](https://www.perl.org/) >=5.18.2

Getting started
---------------

#### Building the service

Clone this repository:

```
$ git clone https://github.com/companieshouse/ch.gov.uk.git
```

Initialise the submodule:
```
$ git submodule init
$ git submodule update
```

Resolve project dependencies by 'building' the service:

```
$ make build
```

If a build error is encountered during the 'test' phase, running the following command may fix it:

```
$ aws s3 cp s3://release.ch.gov.uk/ch.gov.uk-deps/ch.gov.uk-deps-1.1.5.zip . && unzip ch.gov.uk-deps-1.1.5.zip -d <<PATH-TO-DOCKER-CHS-DEVELOPMENT-REPO>>/repositories/ch-gov-uk/local;
```

#### Running the service

Run the service using the provided script:

```
$ ./start.sh
```

Configuration
-------------

The default configuration can be overridden by either exporting environment variables at the command line prior to launching the application or by adding variable exports to `~/.chs_env/ch.gov.uk/env`.

Docker support
-------------

Pull image from private CH registry by running `docker pull 169942020521.dkr.ecr.eu-west-1.amazonaws.com/local/ch.gov.uk:latest` command or run the following steps to build image locally:

1. `make` (only once to clone submodules and pull dependencies)
2. `DOCKER_BUILDKIT=0 docker build -t 169942020521.dkr.ecr.eu-west-1.amazonaws.com/local/ch.gov.uk:latest .`
