#!/bin/bash

bundle check || bundle install

rm -f /app/tmp/pids/server.pid

bundle exec rails db:migrate

./bin/webpack

bundle exec rails s -p 3000 -b '0.0.0.0'