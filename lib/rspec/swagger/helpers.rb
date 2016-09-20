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
        config.include Common,     :swagger_object
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
          raise ArgumentError, "Path must start with a /" unless template.starts_with?('/')

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
          # TODO, check verbs against a whitelist

          verb = verb.to_s.downcase
          meta = {
            swagger_object: :operation,
            swagger_data: metadata[:swagger_data].merge(operation: verb.to_sym, operation_description: desc)
          }
          describe(verb.to_s, meta, &block)
        end
      end

      module Parameters
        def parameter name, attributes = {}
          attributes.symbolize_keys!

          raise ArgumentError, "Missing 'in' parameter" unless attributes[:in]
          locations = [:query, :header, :path, :formData, :body]
          unless locations.include? attributes[:in]
            raise ArgumentError, "Invalid 'in' parameter, must be one of #{locations}"
          end

          # Path attributes are always required
          attributes[:required] = true if attributes[:in] == :path

          # if name.respond_to?(:has_key?)
          #   param = { '$ref' => name.delete(:ref) || name.delete('ref') }
          # end

          params = metadata[:swagger_data][:params] ||= {}

          param = { name: name.to_s }.merge(attributes)
          # Params should be unique based on the 'name' and 'in' values.
          param_key = "#{param[:in]}&#{param[:name]}"
          params[param_key] = param
        end
      end

      module Operation
        def response status_code, desc, params = {}, headers = {}, &block
          unless status_code == :default || (100..599).cover?(status_code)
            raise ArgumentError, "status_code must be an integer 100 to 599, or :default"
          end
          meta = {
            swagger_object: :status_code,
            swagger_data: metadata[:swagger_data].merge(status_code: status_code, response_description: desc)
          }
          describe("#{status_code}", meta) do
            self.module_exec(&block) if block_given?

            # TODO: this needs a better mechanism
            if metadata[:capture_example]
              example = metadata[:swagger_data][:example] = {}
            end

            before do |example|
              method = example.metadata[:swagger_data][:operation]
              path = resolve_path(example.metadata[:swagger_data][:path], self)
              args = if ::Rails::VERSION::MAJOR >= 5
                [path, {params: params, headers: headers}]
              else
                [path, params, headers]
              end

              self.send(method, *args)

# TODO fix the naming collision
              # if example
              #   example.merge!(body: response.body, content_type: response.content_type.to_s)
              # end
            end

            it("matches", { swagger_object: :response }) do
              expect(response).to have_http_status(status_code)
            end
          end
        end
      end

      module Response
        def capture_example
          metadata[:capture_example] = true
        end
      end

      module Common
        def resolve_params swagger_data, group_instance
          # TODO resolve $refs
          # TODO there should only be one body param
          # TODO there should not be both body and formData params
          swagger_data[:params].values.map do |p|
            p.slice(:name, :in).merge(value: group_instance.send(p[:name]))
          end
        end

        def resolve_path template, group_instance
          template.gsub(/(\{.*?\})/){|match| group_instance.send(match[1...-1]) }
        end
      end
    end
  end
end
