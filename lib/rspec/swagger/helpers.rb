module RSpec
  module Swagger
    module Helpers
      # paths: (Paths)
      #   /pets: (Path Item)
      #     post: (Operation)
      #       tags:
      #         - pet
      #       summary: Add a new pet to the store
      #       description: ""
      #       operationId: addPet
      #       consumes:
      #         - application/json
      #       produces:
      #         - application/json
      #       parameters: (Parameters)
      #         - in: body
      #           name: body
      #           description: Pet object that needs to be added to the store
      #           required: false
      #           schema:
      #             $ref: "#/definitions/Pet"
      #       responses: (Responses)
      #         "405": (Response)
      #           description: Invalid input

      # The helpers serve as a DSL.
      def self.add_swagger_type_configurations(config)
        # The filters are used to ensure that the methods are nested correctly
        # and following the Swagger schema.
        config.extend Paths,       type: :request
        config.extend PathItem,    swagger_object: :path_item
        config.extend Parameters,  swagger_object: :path_item
        config.extend Operation,   swagger_object: :operation
        config.extend Parameters,  swagger_object: :operation
        config.extend Response,    swagger_object: :response
        config.include Resolver,   :swagger_object
      end

      module Paths
        def path template, attributes = {}, &block
          attributes.symbolize_keys!

          raise ArgumentError, "Path must start with a /" unless template.starts_with?('/')

          #TODO template might be a $ref
          meta = {
            swagger_object: :path_item,
            swagger_document: attributes[:swagger_document] || RSpec.configuration.swagger_docs.keys.first,
            swagger_path_item: {path: template}
          }
          describe(template, meta, &block)
        end
      end

      module PathItem
        def operation verb, attributes = {}, &block
          attributes.symbolize_keys!

          # TODO, check verbs against a whitelist

          verb = verb.to_s.downcase
          meta = {
            swagger_object: :operation,
            swagger_operation: attributes.merge(method: verb.to_sym).reject{ |v| v.nil? }
          }
          describe(verb.to_s, meta, &block)
        end
      end

      module Parameters
        def parameter name, attributes = {}
          attributes.symbolize_keys!

          validate_location! attributes[:in]

          # TODO validate there is only be one body param
          # TODO validate there are not both body and formData params
          if attributes[:in] == :body
            unless attributes[:schema].present?
              raise ArgumentError, "Parameter is missing required 'schema' value."
            end
          else
            validate_type! attributes[:type]
          end

          # Path attributes are always required
          attributes[:required] = true if attributes[:in] == :path

          # if name.respond_to?(:has_key?)
          #   param = { '$ref' => name.delete(:ref) || name.delete('ref') }
          # end

          object_key = "swagger_#{metadata[:swagger_object]}".to_sym
          object_data = metadata[object_key] ||= {}

          params = object_data[:parameters] ||= {}
          param = { name: name.to_s }.merge(attributes)

          # This key ensures uniqueness based on the 'name' and 'in' values.
          param_key = "#{param[:in]}&#{param[:name]}"
          params[param_key] = param
        end

        private

        def validate_location! location
          unless location.present?
            raise ArgumentError, "Parameter is missing required 'in' value."
          end

          locations = %i(query header path formData body)
          unless locations.include? location
            raise ArgumentError, "Parameter has an invalid 'in' value. Try: #{locations}."
          end
        end

        def validate_type! type
          unless type.present?
            raise ArgumentError, "Parameter is missing required 'type' value."
          end

          types = %i(string number integer boolean array file)
          unless types.include?(type)
            raise ArgumentError, "Parameter has an invalid 'type' value. Try: #{types}."
          end
        end
      end

      module Operation
        def consumes *mime_types
          metadata[:swagger_operation][:consumes] = mime_types
        end

        def produces *mime_types
          metadata[:swagger_operation][:produces] = mime_types
        end

        def response status_code, attributes = {}, params = {}, &block
          attributes.symbolize_keys!

          validate_status_code! status_code
          validate_description! attributes[:description]

          meta = {
            swagger_object: :response,
            swagger_response: attributes.merge(status_code: status_code)
          }
          describe(status_code, meta) do
            self.module_exec(&block) if block_given?

            before do |example|
              method = example.metadata[:swagger_operation][:method]
              path = resolve_path(example.metadata, self)
              headers = resolve_headers(example.metadata)

              # Run the request
              args = if ::Rails::VERSION::MAJOR >= 5
                [path, {params: params, headers: headers}]
              else
                [path, params, headers]
              end
              self.send(method, *args)

              if example.metadata[:capture_example]
                examples = example.metadata[:swagger_response][:examples] ||= {}
                examples[response.content_type.to_s] = response.body
              end
            end

            it("returns the correct status code") do
              expect(response).to have_http_status(status_code)
            end
          end
        end

        private

        def validate_status_code! status_code
          unless status_code == :default || (100..599).cover?(status_code)
            raise ArgumentError, "status_code must be an integer 100 to 599, or :default"
          end
        end

        def validate_description! description
          unless description.present?
            raise ArgumentError, "Response is missing required 'description' value."
          end
        end
      end

      module Response
        def capture_example
          metadata[:capture_example] = true
        end
      end

      module Resolver
        def resolve_document metadata
          name = metadata[:swagger_document]
          Document.new(RSpec.configuration.swagger_docs[name])
        end

        def resolve_produces metadata
          metadata[:swagger_operation][:produces]
        end

        def resolve_consumes metadata
          metadata[:swagger_operation][:consumes]
        end

        def resolve_headers metadata
          headers = {}
          # Match the names that Rails uses internally
          if produces = resolve_produces(metadata)
            headers['HTTP_ACCEPT'] = produces.join(';')
          end
          if consumes = resolve_consumes(metadata)
            headers['CONTENT_TYPE'] = consumes.first
          end
          headers
        end

        def resolve_params metadata, group_instance
          path_item = metadata[:swagger_path_item] || {}
          operation = metadata[:swagger_operation] || {}
          params = path_item.fetch(:parameters, {}).merge(operation.fetch(:parameters, {}))

          # TODO resolve $refs
          params.values.map do |p|
            p.slice(:name, :in).merge(value: group_instance.send(p[:name]))
          end
        end

        def resolve_path metadata, group_instance
          document = resolve_document metadata
          base_path = document[:basePath] || ''
          # Find params in the path and replace them with values defined in
          # in the example group.
          path = metadata[:swagger_path_item][:path].gsub(/(\{.*?\})/) do |match|
            # QUESTION: Should check that the parameter is actually defined in
            # `metadata[:swagger_*][:parameters]` before fetch a value?
            group_instance.send(match[1...-1])
          end
          base_path + path
        end
      end
    end
  end
end
