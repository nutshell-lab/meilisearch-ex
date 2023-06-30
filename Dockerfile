FROM elixir:1.14.4-alpine

RUN apk add bash curl && \
    mix local.hex --force && \
    mix local.rebar --force

ENV APP_HOME /package

WORKDIR $APP_HOME
