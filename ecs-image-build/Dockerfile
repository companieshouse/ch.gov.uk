# - TODO Replace with ci-perl-build-ecs base image after merging PR #8 --------

FROM amazonlinux:2023

ARG gopan_version=0.12
ARG gopan_tag_version=v${gopan_version}

# Update system packages and install build tooling
RUN dnf update && \
    dnf upgrade -y && \
    dnf install -y \
        cmake \
        gcc-c++ \
        gzip \
        openssl \
        openssl-devel \
        perl-deprecate \
        perl-Dumpvalue \
        perl-ExtUtils-MakeMaker \
        perl-English \
        perl-Env \
        perl-FindBin \
        perl-Hash-Util-FieldHash \
        perl-Module-Loaded \
        perl-Module-CoreList \
        perl-Safe \
        perl-Sys-Hostname \
        perl-threads \
        perl-Unicode-Normalize \
        tar \
        zlib-devel && \
    dnf clean all && \
    rm -rf /var/cache/dnf /tmp/*

# Install GoPAN for dependency resolution
ADD https://github.com/companieshouse/gopan/releases/download/${gopan_tag_version}/gopan-${gopan_version}-linux_amd64.tar.gz /gopan-${gopan_version}-linux_amd64.tar.gz
RUN tar -C /usr/local/bin -xzf /gopan-${gopan_version}-linux_amd64.tar.gz && \
    rm -f /gopan-${gopan_version}-linux_amd64.tar.gz

# Install App::cpanminus
RUN curl -L https://cpanmin.us | perl - App::cpanminus

# Set local time zone
RUN unlink /etc/localtime && ln -s /usr/share/zoneinfo/Europe/London /etc/localtime

# -----------------------------------------------------------------------------

WORKDIR /opt/ch.gov.uk
COPY /app .
COPY docker_start.sh .

CMD ["./docker_start.sh"]
