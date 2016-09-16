#!/bin/bash

set -x

# export RAILS_VERSION=3.2.0
# export RAILS_VERSION=4.0.0
# export RAILS_VERSION=5.0.0
major=$(echo $RAILS_VERSION | cut -d '.' -f1)

rm Gemfile.lock
bundle install

rm -r spec/testapp
bundle exec rails new spec/testapp --api -d sqlite3 --skip-gemfile --skip-bundle --skip-test-unit --skip-action-mailer --skip-puma --skip-action-cable --skip-sprockets --skip-javascript --skip-spring --skip-listen
cd spec/testapp

bundle exec rails generate scaffold Post title:string body:text
rm -r spec

if [ $major -eq 5 ]
then
  bundle exec rails db:create
  bundle exec rails db:migrate RAILS_ENV=test
else
  bundle exec rake db:create
  bundle exec rake db:migrate RAILS_ENV=test
fi

cd -

bundle exec rspec
