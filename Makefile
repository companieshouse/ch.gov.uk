SERVICE_NAME         ?= ch.gov.uk

PERL_DEPS_SERVER_URL ?= s3://release.ch.gov.uk/$(SERVICE_NAME)-deps
PERL_DEPS_VERSION    ?= 1.0.0
PERL_DEPS_PACKAGE    ?= $(SERVICE_NAME)-deps-$(PERL_DEPS_VERSION).zip
PERL_DEPS_URL        ?= $(PERL_DEPS_SERVER_URL)/$(PERL_DEPS_PACKAGE)

LOCAL           ?= ./local

SMARTPAN_URL    ?= http://darkpan.ch.gov.uk:7050

GETPAN_CPUS     ?= -cpus 1 # Setting to null enables getpan to use all cores
GETPAN_LOGLEVEL ?= INFO
GETPAN_CACHEDIR ?= ./.gopancache
GETPAN_ARGS     ?= $(GETPAN_CPUS) -cachedir=$(GETPAN_CACHEDIR) -smart $(SMARTPAN_URL) -loglevel=$(GETPAN_LOGLEVEL) -nodepdump -nocpan -nobackpan -metacpan

CHS_ENV_HOME?=$(HOME)/.chs_env
CHS_ENVS=$(CHS_ENV_HOME)/global_env $(CHS_ENV_HOME)/$(SERVICE_NAME)/env
SOURCE_ENV=for chs_env in $(CHS_ENVS); do test -f $$chs_env && . $$chs_env; done

PROVE_CMD       ?= $(LOCAL)/bin/prove
PROVE_ARGS      ?= -It/lib -Ilib -I$(LOCAL)/lib/perl5 -lr

TEST_UNIT_ENV   ?= COOKIE_SECRET=abcdef123456 URL_SIGNING_SALT=abcdef123456

all: dist

submodules: api-enumerations/.git

api-enumerations/.git:
	git submodule init
	git submodule update

deps:
	test -d $(CURDIR)/local || { aws s3 cp $(PERL_DEPS_URL) .; unzip $(PERL_DEPS_PACKAGE) -d $(CURDIR)/local; }
	test -f $(PERL_DEPS_PACKAGE) && rm -f $(PERL_DEPS_PACKAGE)

getpan:
	getpan $(GETPAN_ARGS)

clean:
	rm -rf $(LOCAL)
	rm -rf $(GETPAN_CACHEDIR)

test-unit:
	$(TEST_UNIT_ENV) $(PROVE_CMD) $(PROVE_ARGS) t/unit

test-int:
	$(SOURCE_ENV); $(PROVE_CMD) $(PROVE_ARGS) t/integration

test: test-unit test-int

build: submodules getpan

package:
	$(eval commit := $(shell git rev-parse --short HEAD))
	$(eval tag := $(shell git tag -l 'v*-rc*' --points-at HEAD))
	$(eval VERSION := $(shell if [[ -n "$(tag)" ]]; then echo $(tag) | sed 's/^v//'; else echo $(commit); fi))
	$(eval tmpdir:=$(shell mktemp -d build-XXXXXXXXXX))
	cp -r $(LOCAL) $(tmpdir)
	cp -r ./lib $(tmpdir)
	cp -r ./script $(tmpdir)
	cp -r ./templates $(tmpdir)
	cp -r ./api-enumerations $(tmpdir)
	cp -r ./t $(tmpdir)
	cp ./appconfig.yml $(tmpdir)
	cp ./routes.yaml $(tmpdir)
	cp ./errors.yml $(tmpdir)
	cp ./log4perl.production.conf $(tmpdir)
	cp ./cpanfile $(tmpdir)
	cp ./start.sh $(tmpdir)
	cd $(tmpdir); zip -r ../$(SERVICE_NAME)-$(VERSION).zip *
	rm -rf $(tmpdir)

dist: build package

.PHONY: all build clean dist package getpan test test-unit test-int deps
