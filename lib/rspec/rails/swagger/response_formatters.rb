module RSpec
  module Rails
    module Swagger
      class ResponseFormatters

        class JSON
          def call(resp)
            if resp.kind_of? String
              ::JSON.parse(resp)
            else
              resp
            end
          rescue ::JSON::ParserError
            resp
          end
        end

        @formatters = {
            :none              => ->(resp) { resp },
            'application/json' => JSON.new
        }

        class << self

          def register(format, callable)
            @formatters[format] = callable
          end

          def [](key)
            @formatters[key] || @formatters[:none]
          end
        end

      end
    end
  end
end
