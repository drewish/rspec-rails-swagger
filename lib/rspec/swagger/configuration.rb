module RSpec
  module Swagger
    # Fake class to document RSpec Swagger configuration options.
    class Configuration
    end

    def self.initialize_configuration(config)
      config.add_setting :swagger_root
      config.add_setting :swagger_docs, default: {}

      Helpers.add_swagger_type_configurations(config)
    end
  end
end
