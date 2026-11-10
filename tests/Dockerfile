FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/usr/bin/zsh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends \
       zsh git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://mise.run | sh

ENV PATH="/root/.local/share/mise/shims:/root/.local/bin:${PATH}"

WORKDIR /dotfiles
COPY . .

RUN git submodule update --init --recursive zsh/plugins \
    && ./install.sh --skip-brew \
    && bash scripts/doctor.sh --manifest config/target-state.docker.sh
