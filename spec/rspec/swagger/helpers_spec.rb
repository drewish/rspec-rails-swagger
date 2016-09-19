require "spec_helper"

RSpec.describe RSpec::Swagger::Helpers::Parameters do
  let(:klass) do
    Class.new do
      include RSpec::Swagger::Helpers::Parameters
      attr_accessor :metadata
    end
  end
  subject { klass.new }

  describe "#parameter" do
    before { subject.metadata = {swagger_object: :path_item, swagger_data: {}} }

    it "requires 'in' parameter" do
      expect{ subject.parameter "name", foo: :bar }.to raise_exception(ArgumentError)
    end

    it "validates 'in' parameter" do
      expect{ subject.parameter "name", in: :form_data }.to raise_exception(ArgumentError)
      expect{ subject.parameter "name", in: "formData" }.to raise_exception(ArgumentError)
      expect{ subject.parameter "name", in: :formData }.not_to raise_exception
    end

    context "on a path_item" do
      before { subject.metadata = {swagger_object: :path_item, swagger_data: {}} }

      it "keeps parameters unique by name and in" do
        subject.parameter('foo', in: :path)
        subject.parameter('foo', in: :path)
        subject.parameter('bar', in: :query)
        subject.parameter('baz', in: :query)

        expect(subject.metadata[:swagger_data][:path_item_params].length).to eq 3
      end
    end

    context "on an operation" do
      before { subject.metadata = {swagger_object: :operation, swagger_data: {}} }

      it "keeps parameters unique by name and in" do
        subject.parameter('foo', in: :path)
        subject.parameter('foo', in: :path)
        subject.parameter('bar', in: :query)
        subject.parameter('baz', in: :query)

        expect(subject.metadata[:swagger_data][:operation_params].length).to eq 3
      end
    end
  end
end


RSpec.describe RSpec::Swagger::Helpers::Operation do
  let(:klass) do
    Class.new do
      include RSpec::Swagger::Helpers::Operation
      attr_accessor :metadata
    end
  end
  subject { klass.new }

  describe "#response" do
    before { subject.metadata = {swagger_object: :operation, swagger_data: {}} }

    it "requires code be an integer 100...600 or :default" do
      expect{ subject.response 1, "description" }.to raise_exception(ArgumentError)
      expect{ subject.response 99, "description" }.to raise_exception(ArgumentError)
      expect{ subject.response 600, "description" }.to raise_exception(ArgumentError)
      expect{ subject.response '404', "description" }.to raise_exception(ArgumentError)
      expect{ subject.response 'default', "description" }.to raise_exception(ArgumentError)

      # expect{ subject.response 100, "description" }.not_to raise_exception
      # expect{ subject.response 599, "description" }.not_to raise_exception
      # expect{ subject.response :default, "description" }.not_to raise_exception
    end
  end
end
