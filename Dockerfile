FROM ruby:2.5
WORKDIR /app
COPY Gemfile Gemfile.lock /app/
RUN bundle install

COPY . /app/

ENV PORT=5000
#ENV X32_IP
#ENV X32_PORT

EXPOSE 5000

# Configure the main process to run when running the image
CMD ["foreman", "start"]
