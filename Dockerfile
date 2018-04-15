# Build intermediate image to build relase
FROM bitwalker/alpine-elixir-phoenix:latest as builder

ARG name=chat
ENV name=${name} MIX_ENV=prod PORT=4000

ADD . .

# If there's assets, install yarn and build them
RUN if [ -d assets ]; then \
      apk add --update --no-cache yarn && \
      mix deps.get && \
      cd assets && yarn install && yarn build && cd .. && \
      mix phx.digest; \
    fi

# Build the release
RUN mix release --env=$MIX_ENV

# Build the actual release image
FROM bitwalker/alpine-erlang:latest

ARG name=chat

ENV name=${name} PORT=4000 MIX_ENV=prod REPLACE_OS_VARS=true SHELL=/bin/sh
EXPOSE $PORT
CMD /opt/app/bin/$name foreground

COPY --from=builder /opt/app/_build/prod/rel/$name .
