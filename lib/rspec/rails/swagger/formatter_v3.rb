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

      end
    end
  end
end
