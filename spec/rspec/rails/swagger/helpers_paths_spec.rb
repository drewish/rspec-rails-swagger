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

  describe 'swagger_doc' do
    context 'with value specified in parent context' do
      before { subject.metadata = {swagger_doc: 'default.json'} }

      it "defaults to the parent value" do
        expect(subject).to receive(:describe).with("/ping", {
          swagger_object: :path_item,
          swagger_doc: 'default.json',
          swagger_path_item: {path: '/ping'}
        })

        subject.path('/ping')
      end

      it "uses the argument when provided" do
        expect(subject).to receive(:describe).with("/ping", {
          swagger_object: :path_item,
          swagger_doc: 'overridden.json',
          swagger_path_item: {path: '/ping'}
        })

        subject.path('/ping', swagger_doc: 'overridden.json')
      end
    end

    context 'without a parent swagger_doc' do
      it "defaults to the first swagger document" do
        expect(subject).to receive(:describe).with("/ping", {
          swagger_object: :path_item,
          swagger_doc: RSpec.configuration.swagger_docs.keys.first,
          swagger_path_item: {path: '/ping'}
        })

        subject.path('/ping')
      end

      it "uses the argument when provided" do
        expect(subject).to receive(:describe).with("/ping", {
          swagger_object: :path_item,
          swagger_doc: 'overridden.json',
          swagger_path_item: {path: '/ping'}
        })

        subject.path('/ping', swagger_doc: 'overridden.json')
      end
    end
  end

  it "passes tags through to the metadata" do
    expect(subject).to receive(:describe).with("/ping", {
      swagger_object: :path_item,
      swagger_doc: RSpec.configuration.swagger_docs.keys.first,
      swagger_path_item: {path: '/ping'},
      tags: ['tag1']
    })

    subject.path('/ping', tags: ['tag1'])
  end
end
