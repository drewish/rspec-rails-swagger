require 'rspec/core'
require 'rspec/rails/swagger/configuration'
require 'rspec/rails/swagger/document'
require 'rspec/rails/swagger/formatter'
require 'rspec/rails/swagger/helpers'
require 'rspec/rails/swagger/request_builder'
require 'rspec/rails/swagger/version'

module RSpec
  module Rails
    module Swagger
      initialize_configuration RSpec.configuration

      if defined?(::Rails)
        class Railtie < ::Rails::Railtie
          rake_tasks do
            load 'rspec/rails/swagger/tasks/swagger.rake'
          end
        end
      end
    end
  end
end

