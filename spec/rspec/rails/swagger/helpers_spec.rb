require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger::Helpers::Paths do
  let(:klass) do
    Class.new do
      include RSpec::Rails::Swagger::Helpers::Paths
      attr_accessor :metadata
      def describe *args ; end
    end
  end
  subject { klass.new }

  it "requires the path start with a /" do
    expect{ subject.path("foo") }.to raise_exception(ArgumentError)
    expect{ subject.path("/foo") }.not_to raise_exception
  end

  it "defaults to the first swagger document if not specified" do
    expect(subject).to receive(:describe).with("/ping", {
      swagger_object: :path_item,
      swagger_document: RSpec.configuration.swagger_docs.keys.first,
      swagger_path_item: {path: '/ping'}
    })

    subject.path('/ping')
  end

  it "accepts specified swagger document name" do
    expect(subject).to receive(:describe).with("/ping", {
      swagger_object: :path_item,
      swagger_document: 'hello_swagger.json',
      swagger_path_item: {path: '/ping'}
    })

    subject.path('/ping', swagger_document: 'hello_swagger.json')
  end
end

RSpec.describe RSpec::Rails::Swagger::Helpers::PathItem do
  let(:klass) do
    Class.new do
      include RSpec::Rails::Swagger::Helpers::PathItem
      attr_accessor :metadata
      def describe *args ; end
    end
  end
  subject { klass.new }

  describe "#operation" do
    it "requires a verb" do
      expect(subject).to receive(:describe).with('get', {
        swagger_object: :operation,
        swagger_operation: {method: :get}
      })

      subject.operation('GET')
    end

    it 'validates the verb' do
      expect{ subject.operation('foo') }.to raise_exception(ArgumentError)
      expect{ subject.operation(:foo) }.to raise_exception(ArgumentError)

      expect{ subject.operation(:head) }.not_to raise_exception
      expect{ subject.operation('patch') }.not_to raise_exception
    end

    it 'accepts additional options' do
      expect(subject).to receive(:describe).with('head', {
        swagger_object: :operation,
        swagger_operation: {
          method: :head, tags: ['pet'], summary: 'Updates',
          description: 'Updates a pet in the store with form data',
          operationId: 'updatePetWithForm'
        }
      })

      subject.operation('head',
        tags: ['pet'],
        summary: 'Updates',
        description: 'Updates a pet in the store with form data',
        operationId: 'updatePetWithForm'
      )
    end
  end

  described_class::METHODS.each do |method|
    describe "##{method}" do
      it 'calls #operation' do
        expect(subject).to receive(:describe).with(method.to_s, {
          swagger_object: :operation,
          swagger_operation: { method: method.to_sym }
        })

        subject.send(method)
      end
    end
  end
end

RSpec.describe RSpec::Rails::Swagger::Helpers::Parameters do
  let(:klass) do
    Class.new do
      include RSpec::Rails::Swagger::Helpers::Parameters
      attr_accessor :metadata
      def describe *args ; end
      def resolve_document *args ; end
    end
  end
  subject { klass.new }

  describe "#parameter" do
    before { subject.metadata = {swagger_object: :path_item} }

    context "with parameters passed in" do
      it "requires 'in' parameter" do
        expect{ subject.parameter("name", foo: :bar) }.to raise_exception(ArgumentError)
      end

      it "validates 'in' parameter" do
        expect{ subject.parameter("name", in: :form_data, type: :string) }.to raise_exception(ArgumentError)
        expect{ subject.parameter("name", in: :pickles, type: :string) }.to raise_exception(ArgumentError)

        expect{ subject.parameter("name", in: :formData, type: :string) }.not_to raise_exception
      end

      it "requies a schema for body params" do
        expect{ subject.parameter(:name, in: :body) }.to raise_exception(ArgumentError)
        expect{ subject.parameter(:name, in: :body, schema: {ref: '#/definitions/foo'}) }.not_to raise_exception
      end

      it "requires a type for non-body params" do
        expect{ subject.parameter(:name, in: :path) }.to raise_exception(ArgumentError)
        expect{ subject.parameter(:name, in: :path, type: :number) }.not_to raise_exception
      end

      it "validates types" do
        %i(string number integer boolean array file).each do |type|
          expect{ subject.parameter(:name, in: :path, type: type) }.not_to raise_exception
        end
        [100, :pickles, "stuff"].each do |type|
          expect{ subject.parameter(:name, in: :path, type: type) }.to raise_exception(ArgumentError)
        end
      end

      it "marks path parameters as required" do
        subject.parameter("name", in: :path, type: :boolean)

        expect(subject.metadata[:swagger_path_item][:parameters].values.first).to include(required: true)
      end

      it "keeps parameters unique by name and location" do
        subject.parameter('foo', in: :path, type: :integer)
        subject.parameter('foo', in: :path, type: :integer)
        subject.parameter('bar', in: :query, type: :integer)
        subject.parameter('baz', in: :query, type: :integer)

        expect(subject.metadata[:swagger_path_item][:parameters].length).to eq 3
      end
    end

    context "with references" do
      it "stores them" do
        expect(subject).to receive(:resolve_document) do
          double(resolve_ref: {in: 'path', name: 'petId', description: 'ID of pet',
            required: true, type: 'string'})
        end

        subject.parameter(ref: '#/parameters/Pet')

        expect(subject.metadata[:swagger_path_item][:parameters]).to eq({
          'path&petId' => {'$ref' => '#/parameters/Pet'}
        })
      end
    end
  end
end


RSpec.describe RSpec::Rails::Swagger::Helpers::Operation do
  let(:klass) do
    Class.new do
      include RSpec::Rails::Swagger::Helpers::Operation
      attr_accessor :metadata
      def describe *args ; end
    end
  end
  subject { klass.new }

  describe '#response' do
    before { subject.metadata = {swagger_object: :operation} }

    it "requires code be an integer 100...600 or :default" do
      expect{ subject.response 99, description: "too low" }.to raise_exception(ArgumentError)
      expect{ subject.response 600, description: "too high" }.to raise_exception(ArgumentError)
      expect{ subject.response '404', description: "string" }.to raise_exception(ArgumentError)
      expect{ subject.response 'default', description: "string" }.to raise_exception(ArgumentError)

      expect{ subject.response 100, description: "low" }.not_to raise_exception
      expect{ subject.response 599, description: "high" }.not_to raise_exception
      expect{ subject.response :default, description: "symbol" }.not_to raise_exception
    end

    it "requires a description" do
      expect{ subject.response 100 }.to raise_exception(ArgumentError)
      expect{ subject.response 100, description: "low" }.not_to raise_exception
    end
  end
end

RSpec.describe RSpec::Rails::Swagger::Helpers::Response do
  let(:klass) do
    Class.new do
      include RSpec::Rails::Swagger::Helpers::Response
      attr_accessor :metadata
      def describe *args ; end
    end
  end
  subject { klass.new }

  before { subject.metadata = { swagger_object: :response, swagger_response: {} } }

  describe '#capture_example' do
    it "sets the capture metadata" do
      expect{ subject.capture_example }
        .to change{ subject.metadata[:capture_examples] }.to(true)
    end
  end

  describe '#schema' do
    it 'stores the schema' do
      subject.schema({
        type: :object, properties: { title: { type: 'string' } }
      })

      expect(subject.metadata[:swagger_response]).to include(schema: {
        type: :object, properties: { title: { type: 'string' } }
      })
    end

    it 'supports refs' do
      subject.schema ref: '#/definitions/Pet'

      expect(subject.metadata[:swagger_response]).to include(schema: { '$ref' => '#/definitions/Pet' })
    end
  end
end
