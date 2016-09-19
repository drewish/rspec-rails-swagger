module RSpec
  module Swagger
    module Helpers
      # The helpers serve as a DSL.
      def self.add_swagger_type_configurations(config)
        # The filters are used to ensure that the methods are nested correctly
        # and following the Swagger schema.
        config.extend Paths,       type: :request
        config.extend PathItem,    swagger_object: :path_item
        config.extend Parameters,  swagger_object: :path_item
        config.extend Operation,   swagger_object: :operation
        config.extend Parameters,  swagger_object: :operation
        config.extend Response,    swagger_object: :status_code
      end


=begin
paths: (Paths)
  /pets: (Path Item)
    post: (Operation)
      tags:
        - pet
      summary: Add a new pet to the store
      description: ""
      operationId: addPet
      consumes:
        - application/json
        - application/xml
      produces:
        - application/json
        - application/xml
      parameters: (Parameters)
        - in: body
          name: body
          description: Pet object that needs to be added to the store
          required: false
          schema:
            $ref: "#/definitions/Pet"
      responses: (Responses)
        "405": (Response)
          description: Invalid input
=end
      module Paths
        def path template, &block
          #TODO template might be a $ref
          meta = {
            swagger_object: :path_item,
            swagger_data: {path: template}
          }
          describe("path #{template}", meta, &block)
        end
      end

      module PathItem
        def operation verb, desc, &block
          verb = verb.to_s.downcase
          meta = {
            swagger_object: :operation,
            swagger_data: metadata[:swagger_data].merge(operation: verb.to_sym, operation_description: desc)
          }
          describe(verb.to_s, meta, &block)
        end
      end

      module Parameters
        def parameter name, args = {}
          # TODO these should be unique by (name, in) so we should use a hash
          # to store them instead of an array.
          param_key = "#{metadata[:swagger_object]}_params".to_s
          params = metadata[:swagger_data][param_key] ||= []
          params << { name: name }.merge(args)
        end
      end

      module Operation
        def response code, desc, params = {}, headers = {}, &block
          meta = {
            swagger_object: :status_code,
            swagger_data: metadata[:swagger_data].merge(status_code: code, response_description: desc)
          }
          describe("#{code}", meta) do
            self.module_exec(&block) if block_given?

            method = metadata[:swagger_data][:operation]
            path = metadata[:swagger_data][:path]
            args = if ::Rails::VERSION::MAJOR >= 5
              [path, {params: params, headers: headers}]
            else
              [path, params, headers]
            end

            # TODO: this needs a better mechanism
            if metadata[:capture_example]
              example = metadata[:swagger_data][:example] = {}
            end

            meta = {
              swagger_object: :response
              # response: metadata[:swagger_data][:response].merge()
            }
            it("matches", meta) do
              self.send(method, *args)

              if response && example
                example.merge!( body: response.body, content_type: response.content_type.to_s)
              end

              expect(response).to have_http_status(code)
            end
          end
        end
      end

      module Response
        def capture_example
          metadata[:capture_example] = true
        end
      end
    end
  end
end
