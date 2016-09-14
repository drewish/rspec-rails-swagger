#!/bin/bash

set -x

# export RAILS_VERSION=3.2.0
export RAILS_VERSION=4.0.0
# export RAILS_VERSION=5.0.0
major=$(echo $RAILS_VERSION | cut -d '.' -f1)

rm Gemfile.lock
bundle install

bundle exec rails new sandbox --skip-gemfile --api -d sqlite3 --skip-bundle --skip-action-mailer --skip-puma --skip-action-cable --skip-sprockets --skip-javascript --skip-spring --skip-listen
cd sandbox

bundle exec rails generate scaffold Post title:string body:text

if [ $major -eq 5 ]
then
  bundle exec rails db:create
  bundle exec rails db:migrate
else
  bundle exec rake db:create
  bundle exec rake db:migrate
fi

bundle exec rails server
