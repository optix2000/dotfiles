FROM debian:testing
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl neovim git zsh rsync golang
RUN useradd -m user
USER user
WORKDIR /home/user

