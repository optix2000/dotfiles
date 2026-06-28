FROM debian:latest
ENV DEBIAN_FRONTEND=noninteractive
ARG CHEZMOI_VERSION=2.70.5
RUN apt-get update && apt-get install -y ca-certificates curl vim-nox git zsh
RUN curl -fsSL -o /tmp/chezmoi.tar.gz "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" \
  && tar -xzf /tmp/chezmoi.tar.gz -C /usr/local/bin chezmoi \
  && rm /tmp/chezmoi.tar.gz
RUN useradd -m user
USER user
WORKDIR /home/user
