RSpec::Support.require_rspec_core "formatters/base_text_formatter"
RSpec::Support.require_rspec_core "formatters/console_codes"

require_relative 'formatter'

module RSpec
  module Rails
    module Swagger
      class Formatter_V3 < RSpec::Rails::Swagger::Formatter
        RSpec::Core::Formatters.register self, :example_group_started,
          :example_passed, :example_pending, :example_failed, :example_finished,
          :close

        def response_for(operation, swagger_response)
          status = swagger_response[:status_code]

          operation[:responses][status] ||= {}
          operation[:responses][status].tap do |response|

            if swagger_response[:examples]
              schema = swagger_response[:schema] || {}
              response[:content] ||= {}
              swagger_response[:examples].each_pair do |format, resp|
                formatted = ResponseFormatters[format].call(resp)
                response[:content][format] ||= {schema: schema.merge(example: formatted)}
              end
            elsif swagger_response[:schema]
              response[:content] = {'application/json' => {schema: schema}}
            end

            response.merge!(swagger_response.slice(:description, :headers))
          end
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
                  examples: body[:examples]
                }
              }
            }
          end
          object[:parameters] = prepare_parameters(parameters)
        end

      end
    end
  end
end
