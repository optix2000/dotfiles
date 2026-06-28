FROM debian:stable-slim

ARG CHEZMOI_VERSION=2.70.5
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git vim-nox zsh \
  && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/chezmoi.tar.gz "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" \
  && tar -xzf /tmp/chezmoi.tar.gz -C /usr/local/bin chezmoi \
  && rm /tmp/chezmoi.tar.gz
RUN useradd --create-home --shell /bin/zsh user
USER user
WORKDIR /home/user
