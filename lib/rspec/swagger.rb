require 'rspec/core'
require 'rspec/swagger/configuration'
require 'rspec/swagger/formatter'
require 'rspec/swagger/helpers'
require 'rspec/swagger/version'

module RSpec
  module Swagger
    initialize_configuration RSpec.configuration
  end
end

