RSpec::Support.require_rspec_core "formatters/base_text_formatter"
RSpec::Support.require_rspec_core "formatters/console_codes"

require_relative 'formatter'

module RSpec
  module Rails
    module Swagger
      class FormatterOpenApi < RSpec::Rails::Swagger::Formatter
        RSpec::Core::Formatters.register self, :example_group_started,
          :example_passed, :example_pending, :example_failed, :example_finished,
          :close

        def response_for(operation, swagger_response)
          status = swagger_response[:status_code]

          content_type = operation[:consumes] && operation[:consumes][0] || 'application/json'
          operation.delete(:consumes)

          operation[:responses][status] ||= {}
          operation[:responses][status].tap do |response|
            prepare_response_contents(response, swagger_response)
          end
        end

        def prepare_response_contents(response, swagger_response)
          if swagger_response[:examples]
            schema = swagger_response[:schema] || {}
            response[:content] ||= {}
            swagger_response[:examples].each_pair do |format, resp|
              formatted = ResponseFormatters[format].call(resp)
              response[:content][format] ||= {schema: schema.merge(example: formatted)}
            end
          elsif swagger_response[:schema]
            response[:content] = {content_type => {schema: schema}}
          end

          response.merge!(swagger_response.slice(:description, :headers))
        end

        def path_item_for(document, swagger_path_item)
          name = swagger_path_item[:path]

          document[:paths] ||= {}
          document[:paths][name] ||= {}
          if swagger_path_item[:parameters]
            apply_params(document[:paths][name], swagger_path_item[:parameters].dup)
          end
          document[:paths][name]
        end

        def operation_for(path, swagger_operation)
          method = swagger_operation[:method]

          path[method] ||= {responses: {}}
          path[method].tap do |operation|
            if swagger_operation[:parameters]
              apply_params(operation, swagger_operation[:parameters].dup)
            end
            operation.merge!(swagger_operation.slice(
              :tags, :summary, :description, :externalDocs, :operationId,
              :consumes, :produces, :schemes, :deprecated, :security
            ))
          end
        end

        def apply_params(object, parameters)
          body = parameters.delete('body&body')
          if body
            object[:requestBody] = {
              required: body[:required],
              content: {
                'application/json': {
                  schema: body[:schema],
                  examples: body[:examples] || {}
                }
              }
            }
          end

          object[:parameters] = parameters.values.map do |param|
            param.slice(:in, :name, :required, :schema, :description, :style,
                        :explode, :allowEmptyValue, :example, :examples, :deprecated)
          end
        end

      end
    end
  end
end
