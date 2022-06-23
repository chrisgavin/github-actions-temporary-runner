FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
	apt-get install --yes curl software-properties-common build-essential libssl-dev sudo && \
	add-apt-repository ppa:git-core/ppa && \
	apt-get install --yes git && \
	useradd --create-home user
COPY ./root/ /
USER user
WORKDIR /home/user/
ARG runner_url
RUN curl --fail --location --output actions-runner.tar.gz "${runner_url}" && \
	tar -xf actions-runner.tar.gz && \
	rm actions-runner.tar.gz
USER root
ENTRYPOINT ["/usr/bin/entrypoint"]
