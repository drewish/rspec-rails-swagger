require 'rails_helper'

def build path, params = {}, headers = {}
  if Rails::VERSION::MAJOR >= 5
    [path, { params: params, headers: headers }]
  else
    [path, params, headers]
  end
end

RSpec.describe "Requestsing", type: :request do
  describe "GET /posts" do
    it "works! (now write some real specs)" do
      get(*build('/posts', {}, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'}))
      expect(response).to have_http_status(200)
    end
  end

  describe "POST /posts" do
    it "works! (now write some real specs)" do
      post(*build('/posts', { post: { title: 'asdf', body: "blah" } }.to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'}))
      expect(response).to have_http_status(201)
    end
  end

end
