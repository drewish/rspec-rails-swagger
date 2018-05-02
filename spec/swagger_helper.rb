require 'rspec/rails/swagger'
require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  config.swagger_root = Rails.root.to_s + '/swagger'

  # Define one or more Swagger documents and global metadata for each.
  #
  # When you run the "swagger" rake task, the complete Swagger will be
  # generated at the provided relative path under `swagger_root`
  #
  # If the file name ends with .yml or .yaml the contents will be YAML,
  # otherwise the file will be JSON.
  #
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a `swagger_doc` tag
  # to the the root example_group in your specs, e.g.
  #
  #   describe '...', swagger_doc: 'v2/swagger.json'
  #
  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'API V1',
        version: 'v1'
      }
    }
  }
end

