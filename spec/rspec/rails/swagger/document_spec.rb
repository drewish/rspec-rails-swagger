require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger::Document do
  subject { described_class.new(data) }
  let(:data) { minimial_example }

  it "stores the data" do
    expect(subject[:swagger]).to eq('2.0')
  end

  describe "#resolve_ref" do
    context 'with nothing to reference' do
      let(:data) { minimial_example }

      it 'errors' do
        expect{ subject.resolve_ref('#/parameters/user-id') }.to raise_exception(ArgumentError)
        expect{ subject.resolve_ref('#/definitions/Tag') }.to raise_exception(ArgumentError)
      end
    end

    context 'with data to reference' do
      let(:data) { instagram_example }

      it "errors on invalid references" do
        expect{ subject.resolve_ref('parameters/user-id') }.to raise_exception(ArgumentError)
        expect{ subject.resolve_ref('definitions/user-id') }.to raise_exception(ArgumentError)
      end

      it "finds parameter references" do
        expect(subject.resolve_ref('#/parameters/user-id')).to eq({
          name: 'user-id',
          in: 'path',
          description: 'The user identifier number',
          type: 'number',
          required: true,
        })
      end

      it "finds valid schema references" do
        expect(subject.resolve_ref('#/definitions/Tag')).to eq({
          type: 'object',
          properties: {
            media_count: {
              type: 'integer',
            },
            name: {
              type: 'string',
            },
          }
        })
      end
    end
  end

  def minimial_example
    YAML.load_file(File.expand_path('../../../../fixtures/files/minimal.yml', __FILE__))
  end

  def instagram_example
    YAML.load_file(File.expand_path('../../../../fixtures/files/instagram.yml', __FILE__))
  end
end
