require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger::RequestBuilder do
  describe '#initialize' do
    it 'stores metadata and instance' do
      metadata = { foo: :bar }
      instance = double
      subject = described_class.new(metadata, instance)

      expect(subject.metadata).to eq metadata
      expect(subject.instance).to eq instance
    end
  end

  describe '#document' do
    subject { described_class.new(metadata, double('instance')) }
    let(:metadata) { { swagger_document: 'example.json' } }

    it 'loads the document' do
      allow(RSpec.configuration.swagger_docs).to receive(:[]).with('example.json').and_return({foo: :bar})

      expect(subject.document[:foo]).to eq :bar
    end
  end

  describe '#method' do
    subject { described_class.new(metadata, double('instance')) }
    let(:metadata) { { swagger_operation: {method: 'get' } } }

    it "returns the operation's method" do
      expect(subject.method).to eq 'get'
    end
  end

  describe '#produces' do
    subject { described_class.new(metadata, double('instance')) }
    let(:document) { double }
    before { allow(subject).to receive(:document) { document } }

    context 'with string in operation' do
      let(:metadata) { { swagger_operation: {produces: 'something' } } }

      it 'converts it to an array' do
        expect(subject.produces).to eq ['something']
      end
    end

    context 'with array in operation' do
      let(:metadata) { { swagger_operation: {produces: 'something' } } }

      it 'uses that value' do
        expect(subject.produces).to eq ['something']
      end
    end

    context 'with no value in operation' do
      let(:metadata) { { swagger_operation: {} } }

      it 'uses the value from the document' do
        expect(document).to receive(:[]).with(:produces) { 'or other' }

        expect(subject.produces).to eq ['or other']
      end
    end
  end

  describe '#consumes' do
    subject { described_class.new(metadata, double('instance')) }
    let(:document) { double }
    before { allow(subject).to receive(:document) { document } }

    context 'with string in operation' do
      let(:metadata) { { swagger_operation: {consumes: 'something' } } }

      it 'converts it to an array' do
        expect(subject.consumes).to eq ['something']
      end
    end

    context 'with array in operation' do
      let(:metadata) { { swagger_operation: {consumes: ['something'] } } }

      it 'uses that value' do
        expect(subject.consumes).to eq ['something']
      end
    end

    context 'with no value in operation' do
      let(:metadata) { { swagger_operation: {} } }

      it 'uses the value from the document' do
        expect(document).to receive(:[]).with(:consumes) { 'or other' }

        expect(subject.consumes).to eq ['or other']
      end
    end
  end

  describe '#parameters' do
    subject { described_class.new(metadata, double('instance')) }
    let(:metadata) { {
      swagger_path_item: { parameters: {
        'path&petId' => { name: 'petId', in: :path, description: 'path' },
        'query&site' => { name: 'site', in: :query }
      } },
      swagger_operation: { parameters: {
        'path&petId' => { name: 'petId', in: :path, description: 'op' }
      } },
    } }

    it 'merges values from the path and operation' do
      expect(subject.parameters).to eq({
        'path&petId' => { name: 'petId', in: :path, description: 'op' },
        'query&site' => { name: 'site', in: :query }
      })
    end
  end

  describe '#headers' do
    subject { described_class.new(double('metadata'), instance) }
    let(:instance) { double('instance') }
    let(:produces) { }
    let(:consumes) { }
    before do
      allow(subject).to receive(:produces) { produces }
      allow(subject).to receive(:consumes) { consumes }
      allow(subject).to receive(:parameters).with(:header) { {} }
    end

    context 'when produces has a single value' do
      let(:produces) { ['foo/bar'] }
      it 'sets the Accept header' do
        expect(subject.headers).to include('HTTP_ACCEPT' => 'foo/bar')
      end
    end

    context 'when produces has multiple values' do
      let(:produces) { ['foo/bar', 'bar/baz'] }
      it 'sets the Accept header to the first' do
        expect(subject.headers).to include('HTTP_ACCEPT' => 'foo/bar')
      end
    end

    context 'when produces is blank' do
      it 'does not set the Accept header' do
        expect(subject.headers.keys).not_to include('HTTP_ACCEPT')
      end
    end

    context 'when consumes has a single value' do
      let(:consumes) { ['bar/baz'] }
      it 'sets the Content-Type header' do
        expect(subject.headers).to include('CONTENT_TYPE' => 'bar/baz')
      end
    end

    context 'when consumes has multiple values' do
      let(:consumes) { ['bar/baz', 'flooz/flop'] }
      it 'sets the Content-Type header to the first' do
        expect(subject.headers).to include('CONTENT_TYPE' => 'bar/baz')
      end
    end

    context 'when consumes is blank' do
      it 'does not set the Content-Type header' do
        expect(subject.headers.keys).not_to include('CONTENT_TYPE')
      end
    end

    context 'with header params' do
      it 'returns them in a string' do
        expect(subject).to receive(:parameters).with(:header) { {
          'header&X-Magic' => { same: :here }
        } }
        expect(instance).to receive('X-Magic'.to_sym) { :pickles }

        expect(subject.headers).to include('X-Magic' => :pickles)
      end
    end
  end

  describe '#path' do
    subject { described_class.new(metadata, instance) }
    let(:instance) { double('instance') }

    context 'when document includes basePath' do
      let(:metadata) { { swagger_path_item: { path: '/path' } } }

      it 'is used as path prefix' do
        allow(subject).to receive(:document) { { basePath: '/base' } }

        expect(subject.path).to eq('/base/path')
      end
    end

    context 'when is templated' do
      let(:metadata) { { swagger_path_item: { path: '/sites/{site_id}/accounts/{accountId}' } } }

      it 'variables are replaced with calls to instance' do
        allow(subject).to receive(:document) { {} }
        expect(instance).to receive(:site_id) { 123 }
        expect(instance).to receive(:accountId) { 456 }

        expect(subject.path).to eq('/sites/123/accounts/456')
      end
    end
  end

  describe '#query' do
    subject { described_class.new(double('metadata'), instance) }
    let(:instance) { double('instance') }

    context 'with no query params' do
      it 'returns nil' do
        expect(subject).to receive(:parameters).with(:query) { {} }

        expect(subject.query).to be_nil
      end
    end

    context 'with query params' do
      it 'returns them in a string' do
        expect(subject).to receive(:parameters).with(:query) { {
          'query&site' => { same: :here }
        } }
        expect(instance).to receive(:site) { :pickles }

        expect(subject.query).to eq('?site=pickles')
      end
    end
  end

  describe '#body' do
    subject { described_class.new(double('metadata'), instance) }
    let(:instance) { double('instance') }

    context 'with no body param' do
      it 'returns nil' do
        expect(subject).to receive(:parameters).with(:body) { {} }

        expect(subject.body).to be_nil
      end
    end

    context 'with a body param' do
      it 'returns a serialized JSON string' do
        expect(subject).to receive(:parameters).with(:body) { {
          'body&site' => { same: :here }
        } }
        expect(instance).to receive(:site) { { name: :pickles, team: :cowboys } }

        expect(subject.body).to eq '{"name":"pickles","team":"cowboys"}'
      end
    end
  end
end
