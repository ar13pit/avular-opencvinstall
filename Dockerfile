FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq
RUN apt-get upgrade -qq -y

WORKDIR ~

RUN ls -aln

RUN mkdir -p test
RUN pwd
RUN ls -aln

