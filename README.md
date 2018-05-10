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

#### Running the service

Run the service using the provided script:

```
$ ./start.sh
```

Configuration
-------------

The default configuration can be overridden by either exporting environment variables at the command line prior to launching the application or by adding variable exports to `~/.chs_env/ch.gov.uk/env`.

