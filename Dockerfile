FROM registry.access.redhat.com/ubi10@sha256:be840bb76e74900d39d5e4620c184e89382dcfce09cb05c98b4e1246d55612a5 AS ubi

########################
# PREPARE OUR BASE IMAGE
########################
FROM ubi AS base
RUN dnf -y install \
    --setopt install_weak_deps=0 \
    --nodocs \
    python3.12 && \
    dnf clean all

###############
# BUILD/INSTALL
###############
FROM base AS builder
WORKDIR /src
RUN dnf -y install \
    --setopt install_weak_deps=0 \
    --nodocs \
    gcc \
    python3.12-devel \
    python3.12-pip \
    && dnf clean all

# Install dependencies in a separate layer to maximize layer caching
COPY requirements.txt requirements-build.txt ./
RUN python3.12 -m venv /venv && \
    /venv/bin/pip install -r requirements-build.txt --no-deps --no-cache-dir --require-hashes && \
    /venv/bin/pip install -r requirements.txt --no-deps --no-cache-dir --require-hashes

COPY . .
RUN /venv/bin/pip install --no-cache-dir --no-deps .

##########################
# ASSEMBLE THE FINAL IMAGE
##########################
FROM base
LABEL maintainer="Red Hat"

COPY --from=builder /venv /venv

RUN ln -s /venv/bin/pmt /usr/local/bin/pmt && \
    ln -s /venv/bin/pipeline-migration-tool /usr/local/bin/pipeline-migration-tool

ENTRYPOINT ["/usr/local/bin/pmt"]
