FROM nginx:alpine
MAINTAINER Alex Wei <alexpacer@gmail.com>

ENV BUILD_PACKAGES bash curl curl-dev ruby-dev build-base vim
ENV RUBY_PACKAGES ruby ruby-bundler ruby-rdoc ruby-io-console ruby-irb

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    apk add supervisor

RUN apk --update add --virtual build-dependencies build-base ruby-dev openssl-dev libxml2-dev libxslt-dev \
    postgresql-dev libc-dev linux-headers nodejs tzdata && \
    bundle config build.nokogiri --use-system-libraries

COPY ./supervisord.conf /etc/supervisord.conf

# Cleanup
RUN rm -rf /var/cache/apk/*

CMD supervisord -c /etc/supervisord.conf
