module RSpec
  module Swagger
    class RequestBuilder
      attr_reader :metadata, :instance

      def initialize(metadata, instance)
        @metadata, @instance = metadata, instance
      end

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
        metadata[:swagger_operation][:produces] || document[:produces]
      end

      def consumes
        metadata[:swagger_operation][:consumes] || document[:consumes]
      end

      def parameters
        path_item = metadata[:swagger_path_item] || {}
        operation = metadata[:swagger_operation] || {}
        path_item.fetch(:parameters, {}).merge(operation.fetch(:parameters, {}))
      end

      def headers
        headers = {}

        # Match the names that Rails uses internally
        headers['HTTP_ACCEPT'] = produces.join(';') if produces.present?
        headers['CONTENT_TYPE'] = consumes.first if consumes.present?

        # TODO needs to pull in parameters with in: :header set.
        headers
      end

      def path
        base_path = document[:basePath] || ''
        # Find params in the path and replace them with values defined in
        # in the example group.
        path = base_path + metadata[:swagger_path_item][:path].gsub(/(\{.*?\})/) do |match|
          # QUESTION: Should check that the parameter is actually defined in
          # `parameters` before fetch a value?
          instance.send(match[1...-1])
        end
      end

      def query
        # Don't bother looking at the full parameter bodies since all we need
        # are location and name which are the key.
        query_params = parameters.keys.map{ |k| k.split('&')}
          .select{ |location, name| location == 'query' }
          .map{ |location, name| [name, instance.send(name)] }

        '?' + Hash[query_params].to_query unless query_params.empty?
      end

      def body
        # And here all we need is the first half of the key to find the body
        # parameter and its name to fetch a value.
        if key = parameters.keys.find{ |k| k.starts_with? 'body&' }
          instance.send(key.split('&').last).to_json
        end
      end
    end
  end
end
