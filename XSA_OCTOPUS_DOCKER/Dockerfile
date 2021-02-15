FROM buildpack-deps:stretch-curl

ARG OCTOPUSZIP
ENV VERSION 0.1
ENV OCTOPUS=/octopus/
ENV PATH=$PATH:${OCTOPUS}/

COPY ${OCTOPUSZIP} /tmp/${OCTOPUSZIP}


# ps needs to be available to be able to be used in docker.inside, see https://issues.jenkins-ci.org/browse/JENKINS-40101.
RUN apt-get update && \
    apt-get install --yes --no-install-recommends procps unzip && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup -gid 1000 piper && \
    useradd piper --uid 1000 --gid 1000 --shell /bin/bash --create-home && \
    mkdir --parents ${OCTOPUS} && \
    unzip -d ${OCTOPUS} /tmp/${OCTOPUSZIP} && \
    rm --recursive --force /tmp/${OCTOPUSZIP} && \
    chown --recursive piper:piper ${OCTOPUS} && \
    chmod --recursive 777 ${OCTOPUS}

USER piper
WORKDIR ${OCTOPUS}