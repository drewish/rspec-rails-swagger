# Contributing

## Running tests

The `make_site.sh` script will create a test site for a specific version of
Rails and run the tests:
```
RAILS_VERSION=4.2.0
./make_site.sh
```

Once the test site is created you can just re-run the tests:
```
bundle exec rspec
```
