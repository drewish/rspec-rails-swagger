require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger::RouteParser do
  subject { described_class.new(controller) }

  describe '#routes' do
    let(:controller) { 'posts' }

    it 'extracts the relevant details' do
      output = subject.routes

      expect(output.keys).to include('/posts', '/posts/{id}')
      expect(output['/posts'][:actions].keys).to include('get', 'post')
      expect(output['/posts'][:actions]['get']).to eq(summary: 'list posts')
      expect(output['/posts'][:actions]['post']).to eq(summary: 'create post')
      expect(output['/posts/{id}'][:actions]['delete']).to eq(summary: 'delete post')
    end
  end
end
