require 'rails/generators'

module Rspec
  module Generators
    class SwaggerInstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def copy_swagger_helper
        template 'spec/swagger_helper.rb'
      end
    end
  end
end
