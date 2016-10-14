module RSpec
  module Rails
    module Swagger
      class RequestBuilder
        attr_reader :metadata, :instance

        ##
        # Creates a new RequestBuilder from the Example class's +metadata+ hash
        # and a test +instance+ that we can use to populate the parameter
        # values.
        def initialize(metadata, instance)
          @metadata, @instance = metadata, instance
        end

        ##
        # Finds the Document associated with this request so things like schema
        # and parameter references can be resolved.
        def document
          @document ||= begin
            name = metadata[:swagger_document]
            Document.new(RSpec.configuration.swagger_docs[name])
          end
        end

        def method
          metadata[:swagger_operation][:method]
        end

        def produces
          Array(metadata[:swagger_operation][:produces]).presence || Array(document[:produces])
        end

        def consumes
          Array(metadata[:swagger_operation][:consumes]).presence || Array(document[:consumes])
        end

        ##
        # Returns parameters defined in the operation and path item. Providing
        # a +location+ will filter the parameters to those with a matching +in+
        # value.
        def parameters location = nil
          path_item = metadata[:swagger_path_item] || {}
          operation = metadata[:swagger_operation] || {}
          params = path_item.fetch(:parameters, {}).merge(operation.fetch(:parameters, {}))
          if location.present?
            params.select{ |k, _| k.starts_with? "#{location}&" }
          else
            params
          end
        end

        def parameter_values location
          values = parameters(location).
            map{ |_, p| p['$ref'] ? document.resolve_ref(p['$ref']) : p }.
            select{ |p| p[:required] || instance.respond_to?(p[:name]) }.
            map{ |p| [p[:name], instance.send(p[:name])] }
          Hash[values]
        end

        def headers
          headers = {}

          # Match the names that Rails uses internally
          headers['HTTP_ACCEPT'] = produces.first if produces.present?
          headers['CONTENT_TYPE'] = consumes.first if consumes.present?

          # TODO: do we need to do some capitalization to match the rack
          # conventions?
          parameter_values(:header).each { |k, v| headers[k] = v }

          headers
        end

        ##
        # If +instance+ defines an +env+ method this will return those values
        # for inclusion in the Rack env hash.
        def env
          return {} unless instance.respond_to? :env

          instance.env
        end

        def path
          base_path = document[:basePath] || ''
          # Find params in the path and replace them with values defined in
          # in the example group.
          base_path + metadata[:swagger_path_item][:path].gsub(/(\{.*?\})/) do |match|
            # QUESTION: Should check that the parameter is actually defined in
            # `parameters` before fetch a value?
            instance.send(match[1...-1])
          end
        end

        def query
          query_params = parameter_values(:query).to_query
          "?#{query_params}" unless query_params.blank?
        end

        def body
          # And here all we need is the first half of the key to find the body
          # parameter and its name to fetch a value.
          if key = parameters(:body).keys.first
            instance.send(key.split('&').last).to_json
          end
        end
      end
    end
  end
end
