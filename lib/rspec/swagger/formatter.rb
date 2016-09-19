require 'rspec/core/formatters/base_text_formatter'

module RSpec
  module Swagger
    class Formatter < RSpec::Core::Formatters::BaseTextFormatter
      RSpec::Core::Formatters.register self, :example_finished, :close

      def initialize(output)
        super
      end

      def documents
        # We don't try to load the docs in `initalize` because when running
        # `rspec -f RSpec::Swagger::Formatter` RSpec initalized this class
        # before `swagger_helper` has run.
        @documents ||= ::RSpec.configuration.swagger_docs
      end

      def example_finished(notification)
        return unless notification.example.metadata[:swagger_object] == :response

        data = notification.example.metadata[:swagger_data]
        document = document_for(nil)
        path = path_for(document, data[:path])
        operation = operation_for(path, data[:operation])
        response = response_for(operation, data[:status_code])
        response[:description] = data[:response_description] if data[:response_description]
        response[:examples] = prepare_example(data[:example]) if data[:example]

        # notification.example.metadata.each do |k, v|
        #   puts "#{k}\t#{v}" if k.to_s.starts_with?("swagger")
        # end
      end

      def close(_notification)
        documents.each{|k, v| write_json(k, v)}
      end

      def write_json(name, document)
        pp document
      end

      def document_for doc_name = nil
        if doc_name
          documents.fetch(doc_name)
        else
          documents.values.first
        end
      end

      def path_for document, path_name
        document[:paths] ||= {}
        document[:paths][path_name] ||= {}
      end

      def operation_for path, operation_name
        path[operation_name] ||= {responses: {}}
      end

      def response_for operation, status_code
        operation[:responses][status_code] ||= {}
      end


      def prepare_example example
        mime_type = example[:content_type]
        body = example[:body]
        if mime_type == 'application/json'
          begin
            body = JSON.parse(body)
          rescue JSON::ParserError => e
          end
        end
        { mime_type => body }
      end
    end
  end
end
