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

          # look for $refs
          if name.respond_to?(:has_key?)
            ref = name.delete(:ref) || name.delete('ref')
            full_param = resolve_document(metadata).resolve_ref(ref)

            validate_parameter! full_param

            param = { '$ref' => ref }
            key = parameter_key(full_param)
          else
            validate_parameter! attributes

            # Path attributes are always required
            attributes[:required] = true if attributes[:in] == :path

            param = { name: name.to_s }.merge(attributes)
            key = parameter_key(param)
          end

          parameters_for_object[key] = param
        end
        private

        # This key ensures uniqueness based on the 'name' and 'in' values.
        def parameter_key parameter
          "#{parameter[:in]}&#{parameter[:name]}"
        end

        def parameters_for_object
          object_key = "swagger_#{metadata[:swagger_object]}".to_sym
          object_data = metadata[object_key] ||= {}
          object_data[:parameters] ||= {}
        end

        def validate_parameter! attributes
          validate_location! attributes[:in]

          if attributes[:in].to_s == 'body'
            unless attributes[:schema].present?
              raise ArgumentError, "Parameter is missing required 'schema' value."
            end
          else
            validate_type! attributes[:type]
          end
        end

        def validate_location! location
          unless location.present?
            raise ArgumentError, "Parameter is missing required 'in' value."
          end

          locations = %q(query header path formData body)
          unless locations.include? location.to_s
            raise ArgumentError, "Parameter has an invalid 'in' value. Try: #{locations}."
          end
        end

        def validate_type! type
          unless type.present?
            raise ArgumentError, "Parameter is missing required 'type' value."
          end

          types = %q(string number integer boolean array file)
          unless types.include? type.to_s
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
          # TODO: It's really inefficient to keep recreating this. It'd be nice
          # if we could cache them some place.
          name = metadata[:swagger_document]
          Document.new(RSpec.configuration.swagger_docs[name])
        end

        def resolve_produces metadata
          document = resolve_document metadata
          metadata[:swagger_operation][:produces] || document[:produces]
        end

        def resolve_consumes metadata
          document = resolve_document metadata
          metadata[:swagger_operation][:consumes] || document[:consumes]
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

          params.keys.map do |key|
            location, name = key.split('&')
            {name: name, in: location.to_sym, value: group_instance.send(name)}
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
