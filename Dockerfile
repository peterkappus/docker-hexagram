FROM ruby

RUN apt-get update && apt-get -y install imagemagick git vim
RUN gem install rmagick
RUN gem install bundle
RUN mkdir /app
COPY . /app
WORKDIR /app
RUN bundle
