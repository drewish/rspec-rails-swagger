require 'swagger_helper'

RSpec.describe "Requestsing", type: :request do
  # path "/ping" do
  #   operation :put do
  #     response(200, {description: 'OK'})
  #     puts "in here"
  #   end
  # end

  path '/posts' do
    operation "GET", summary:"fetch list" do
      produces 'application/json'

      response(200, {description: "successful"}, {})
    end

    operation "POST",summary: "create" do
      produces 'application/json'
      consumes 'application/json'

      parameter "body", in: :body, schema: { foo: :bar}
      let(:body) { { post: { title: 'asdf', body: "blah" } } }

# TODO: it should pull the body from the params
      response(201, {description: "successfully created"}, { post: { title: 'asdf', body: "blah" } }.to_json) do
        it "uses the body we passed in" do
          post = JSON.parse(response.body)
          expect(post["title"]).to eq('asdf')
          expect(post["body"]).to eq('blah')
        end
        capture_example
      end
    end
  end

  path '/posts/{post_id}' do
    parameter "post_id", {in: :path, type: :integer}
    let(:post_id) { 1 }

    operation "GET", summary: "fetch item" do
      produces 'application/json'

      before { Post.new.save }
      response(200, {description: "success"}, {}) do
        capture_example
      end
    end
  end
end
