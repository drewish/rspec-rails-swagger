require 'swagger_helper'

RSpec.describe "Requestsing", type: :request do
  path '/posts' do
    operation "GET", "fetch list" do
      # params
      response(200, "successful", {}, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'})
    end

    operation "POST", "create" do
      # params
      response(201, "successfully created", { post: { title: 'asdf', body: "blah" } }.to_json, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'}) do
        capture_example
      end
    end
  end

  path '/posts/{post_id}' do
    parameter "post_id", {in: :path}
    let(:post_id) { 1 }

    operation "GET", "fetch item" do
      before { Post.new.save }
      parameter "op-param", {in: :query}
      response(200, "success", {}, {'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json'}) do
        capture_example
      end
    end
  end
end
