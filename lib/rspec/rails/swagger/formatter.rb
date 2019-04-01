RSpec::Support.require_rspec_core "formatters/base_text_formatter"
RSpec::Support.require_rspec_core "formatters/console_codes"

module RSpec
  module Rails
    module Swagger
      class Formatter < RSpec::Core::Formatters::BaseTextFormatter
        RSpec::Core::Formatters.register self, :example_group_started,
          :example_passed, :example_pending, :example_failed, :example_finished,
          :close

        def documents
          # We don't try to load the docs in `initalize` because when running
          # `rspec -f RSpec::Swagger::Formatter` RSpec initalized this class
          # before `swagger_helper` has run.
          @documents ||= ::RSpec.configuration.swagger_docs
        end

        def example_group_started(notification)
          output.print(*group_output(notification))
        end

        def example_passed(notification)
          output.print(RSpec::Core::Formatters::ConsoleCodes.wrap(example_output(notification), :success))
        end

        def example_pending(notification)
          output.print(RSpec::Core::Formatters::ConsoleCodes.wrap(example_output(notification), :pending))
        end

        def example_failed(notification)
          output.print(RSpec::Core::Formatters::ConsoleCodes.wrap(example_output(notification), :failure))
        end

        def example_finished(notification)
          metadata = notification.example.metadata
          return unless metadata[:swagger_object] == :response

          # Then add everything to the document
          document  = document_for(metadata[:swagger_doc])
          path_item = path_item_for(document, metadata[:swagger_path_item])
          operation = operation_for(path_item, metadata[:swagger_operation])
          response  = response_for(operation, metadata[:swagger_response])
        end

        def close(_notification)
          documents.each{|k, v| write_file(k, v)}

          self
        end

        private

        def group_output(notification)
          metadata = notification.group.metadata

          # This is a little odd because I didn't want to split the logic across
          # a start and end method. Instead we just start a new line for each
          # path and operation and just let the status codes pile up on the end.
          # There's probably a better way that doesn't have the initial newline.
          case metadata[:swagger_object]
          when :path_item
            ["\n", metadata[:swagger_path_item][:path]]
          when :operation
            ["\n  ", "%-8s" % metadata[:swagger_operation][:method]]
          end
        end

        def example_output(notification)
          " #{notification.example.metadata[:swagger_response][:status_code]}"
        end

        def write_file(name, document)
          output =
            if %w(.yaml .yml).include? File.extname(name)
              YAML.dump(deep_stringify(document))
            else
              JSON.pretty_generate(document) + "\n"
            end

          # It would be good to at least warn if the name includes some '../' that
          # takes it out of root directory.
          target = Pathname(name).expand_path(::RSpec.configuration.swagger_root)
          target.dirname.mkpath
          target.write(output)
        end

        # Converts hash keys and symbolic values into strings.
        #
        # Based on ActiveSupport's Hash _deep_transform_keys_in_object
        def deep_stringify(object)
          case object
          when Hash
            object.each_with_object({}) do |(key, value), result|
              result[key.to_s] = deep_stringify(value)
            end
          when Array
            object.map { |e| deep_stringify(e) }
          when Symbol
            object.to_s
          else
            object
          end
        end

        def document_for(doc_name = nil)
          if doc_name
            documents.fetch(doc_name)
          else
            documents.values.first
          end
        end

        def path_item_for(document, swagger_path_item)
          name = swagger_path_item[:path]

          document[:paths] ||= {}
          document[:paths][name] ||= {}
          if swagger_path_item[:parameters]
            document[:paths][name][:parameters] = prepare_parameters(swagger_path_item[:parameters])
          end
          document[:paths][name]
        end

        def operation_for(path, swagger_operation)
          method = swagger_operation[:method]

          path[method] ||= {responses: {}}
          path[method].tap do |operation|
            if swagger_operation[:parameters]
              operation[:parameters] = prepare_parameters(swagger_operation[:parameters])
            end
            operation.merge!(swagger_operation.slice(
              :tags, :summary, :description, :externalDocs, :operationId,
              :consumes, :produces, :schemes, :deprecated, :security
            ))
          end
        end

        def response_for(operation, swagger_response)
          status = swagger_response[:status_code]

          operation[:responses][status] ||= {}
          operation[:responses][status].tap do |response|
            if swagger_response[:examples]
              response[:examples] = prepare_examples(swagger_response[:examples])
            end
            response.merge!(swagger_response.slice(:description, :schema, :headers))
          end
        end

        def prepare_parameters(params)
          params.values
        end

        def prepare_examples(examples)
          examples.each_pair do |format, resp|
            examples[format] = ResponseFormatters[format].call(resp)
          end

          examples
        end
      end
    end
  end
end
