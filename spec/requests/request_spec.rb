require 'swagger_helper'

RSpec.describe "Requestsing", type: :request do
  path '/posts' do
    operation "GET", "fetch list" do
      produces 'application/json'

      # params
      response(200, "successful", {})
    end

    operation "POST", "create" do
      produces 'application/json'
      consumes 'application/json'

      parameter "body", in: :body
      let(:body) { { post: { title: 'asdf', body: "blah" } } }

# TODO: it should pull the body from the params
      response(201, "successfully created", { post: { title: 'asdf', body: "blah" } }.to_json) do
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
    parameter "post_id", {in: :path}
    let(:post_id) { 1 }

    operation "GET", "fetch item" do
      produces 'application/json'

      before { Post.new.save }
      parameter "op-param", {in: :query}
      response(200, "success", {}) do
        capture_example
      end
    end
  end
end
