require 'rails_helper'

module SwaggerPath
  def path template, &block
    describe "path #{template}", {swagger_path: template}, &block
  end
end

module SwaggerOperation
  def operation verb, &block
    verb = verb.to_s.downcase
    describe verb.to_s, {swagger_operation: verb.to_sym}, &block
  end
end

module SwaggerRequest
  def test_request code, params = {}, headers = {}
    path = metadata[:swagger_path]
    method = metadata[:swagger_operation]

    # binding.pry
    args = if Rails::VERSION::MAJOR >= 5
      [path, { params: params, headers: headers }]
    else
      [path, params, headers]
    end

    it "does stuff" do
      # binding.pry
      self.send(method, *args)
      expect(response).to have_http_status(code)
    end
  end
end

RSpec.configure do |c|
  c.extend SwaggerPath, type: :request
  c.extend SwaggerOperation, :swagger_path
  c.extend SwaggerRequest, :swagger_operation
end


RSpec.describe "Requestsing", type: :request do
  path '/posts' do
    operation "GET" do
      test_request(200, {}, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'})
    end

    operation "POST" do
      test_request(201, { post: { title: 'asdf', body: "blah" } }.to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'})
    end
  end
end
