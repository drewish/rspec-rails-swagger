require "spec_helper"

RSpec.describe RSpec::Swagger::Helpers::Paths do
  let(:klass) do
    Class.new do
      include RSpec::Swagger::Helpers::Paths
      attr_accessor :metadata
      def describe *args ; end
    end
  end
  subject { klass.new }

  it "requires the path start with a /" do
    expect{ subject.path("foo") }.to raise_exception(ArgumentError)
    expect{ subject.path("/foo") }.not_to raise_exception
  end
end

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
      expect{ subject.parameter("name", foo: :bar) }.to raise_exception(ArgumentError)
    end

    it "validates 'in' parameter" do
      expect{ subject.parameter("name", in: :form_data) }.to raise_exception(ArgumentError)
      expect{ subject.parameter("name", in: "formData") }.to raise_exception(ArgumentError)
      expect{ subject.parameter("name", in: :formData) }.not_to raise_exception
    end

    it "marks path parameters as required" do
      subject.parameter("name", in: :path)

      expect(subject.metadata[:swagger_data][:params].values.first).to include(required: true)
    end

    it "keeps parameters unique by name and location" do
      subject.parameter('foo', in: :path)
      subject.parameter('foo', in: :path)
      subject.parameter('bar', in: :query)
      subject.parameter('baz', in: :query)

      expect(subject.metadata[:swagger_data][:params].length).to eq 3
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


RSpec.describe RSpec::Swagger::Helpers::Common do
  # Tthis helper is an include rather than an extend we can get it pulled into
  # the test just by matching the filter metadata.
  describe("#resolve_params", swagger_object: :something) do
    let(:swagger_data) { { params: params } }

    describe "with a missing value" do
      let(:params) { {"path&post_id" => {name: "post_id", in: :path}} }

      # TODO best thing would be to lazily evaulate the params so we'd only
      # hit this if something was trying to use it.
      it "raises an error" do
        expect{resolve_params(swagger_data, self)}.to raise_exception(NoMethodError)
      end
    end

    describe "with a valid value" do
      let(:params) { {"path&post_id" => {name: "post_id", in: :path, description: "long"}} }
      let(:post_id) { 123 }

      it "returns it" do
        expect(resolve_params(swagger_data, self)).to eq([{name: "post_id", in: :path, value: 123}])
      end
    end
  end

  describe("#resolve_params", swagger_object: :something) do
    describe "with a missing value" do
      it "raises an error" do
        expect{ resolve_path('/sites/{site_id}', self) }.to raise_exception(NoMethodError)
      end
    end

    describe "with values" do
      let(:site_id) { 1001 }
      let(:accountId) { "pickles" }

      it "substitutes them into the path" do
        expect(resolve_path('/sites/{site_id}/accounts/{accountId}', self)).to eq('/sites/1001/accounts/pickles')
      end
    end

    describe "with a base path" do
      xit "prefixes the path" do

      end
    end
  end
end
