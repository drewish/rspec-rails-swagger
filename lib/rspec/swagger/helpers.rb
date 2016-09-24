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

        def resolve_document metadata
          # TODO: It's really inefficient to keep recreating this. It'd be nice
          # if we could cache them some place.
          name = metadata[:swagger_document]
          Document.new(RSpec.configuration.swagger_docs[name])
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

            # TODO: describe the wacky ness to get the metadata and access to let() defined values...
            before do |example|
              builder = RequestBuilder.new(example.metadata, self)
              method = builder.method
              path = builder.path + builder.query
              headers = builder.headers
              params = resolve_params(example.metadata, self)

              # Run the request
              if ::Rails::VERSION::MAJOR >= 5
                self.send(method, path, {params: params, headers: headers})
              else
                self.send(method, path, params, headers)
              end

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
    end
  end
end
