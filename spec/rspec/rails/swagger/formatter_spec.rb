require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger::Formatter do
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }
  let(:documents) { {'minimal.json' => minimal} }
  # Make this a method to bypass rspec's memoization.
  def minimal
    {
      swagger: '2.0',
      info: {
        version: '0.0.0',
        title: 'Simple API'
      }
    }
  end

  before do
    RSpec.configure {|c| c.swagger_docs = documents }
  end

  describe "#example_finished" do
    let(:example_notification) { double('Notification', example: double('Example', metadata: metadata)) }
    let(:metadata) { {} }

    context "with a single document" do
      let(:metadata) do
        {
          swagger_object: :response,
          swagger_path_item: {path: "/ping"},
          swagger_operation: {method: :put},
          swagger_response:  {status_code: 200, description: "OK"},
        }
      end

      it "copies the requests into the document" do
        formatter.example_finished(example_notification)

        expect(formatter.documents.values.first[:paths]).to eq({
          '/ping' => {
            put: {
              responses: {200 => {description: 'OK'}}
            }
          }
        })
      end
    end

    context "with multiple documents" do
      let(:documents) { {'doc1.json' => minimal, 'doc2.json' => minimal} }
      let(:metadata) do
        {
          swagger_object: :response,
          swagger_document: 'doc2.json',
          swagger_path_item: {path: "/ping"},
          swagger_operation: {method: :put},
          swagger_response:  {status_code: 200, description: "OK"},
        }
      end

      it "puts the response on the right document" do
        formatter.example_finished(example_notification)

        expect(formatter.documents['doc1.json'][:paths]).to be_blank
        expect(formatter.documents['doc2.json'][:paths].length).to eq(1)
      end
    end

    context "with a response examples" do
      let(:metadata_examples) { {'application/json' => JSON.dump({foo: :bar})} }
      let(:metadata) do
        {
            swagger_object: :response,
            swagger_path_item: {path: "/ping"},
            swagger_operation: {method: :put},
            swagger_response:  {status_code: 200, description: "OK", examples: metadata_examples},
        }
      end

      shared_examples 'response example formatter' do
        it "copies the requests into the document" do
          formatter.example_finished(example_notification)
          expected_paths = {
              '/ping' => {
                  put: {
                      responses: {200 => {examples: output_examples, description: 'OK'}}
                  }
              }
          }
          expect(formatter.documents.values.first[:paths]).to eq(expected_paths)
        end
      end

      context "with a default formatter" do
        before(:example) do
          RSpec::Rails::Swagger::ResponseFormatters.register(
              'application/json',
              RSpec::Rails::Swagger::ResponseFormatters::JSON.new
          )
        end

        let(:output_examples) { {'application/json' => {"foo" => "bar"}} }
        include_examples 'response example formatter'
      end

      context "custom application/json formatter" do
        before(:example) do
          RSpec::Rails::Swagger::ResponseFormatters.register('application/json', ->(resp) { resp })
        end

        let(:output_examples) { {'application/json' => JSON.dump({foo: :bar})} }
        include_examples 'response example formatter'
      end
    end
  end

  describe "#close" do
    let(:blank_notification) { double('Notification') }

    context "no relevant examples" do
      it "writes document with no changes" do
        expect(formatter).to receive(:write_json).with(documents.keys.first, documents.values.first)
        formatter.close(blank_notification)
      end
    end

    context "with a relevant example" do
      let(:example_notification) {  double(example: double(metadata: metadata)) }
      let(:metadata) do
        {
          swagger_object: :response,
          swagger_path_item: {path: "/ping"},
          swagger_operation: {method: :get},
          swagger_response:  {status_code: 200, description: 'all good'},
        }
      end

      it "writes a document with the request" do
        formatter.example_finished(example_notification)

        expect(formatter).to receive(:write_json).with(
          documents.keys.first,
          documents.values.first.merge({
            paths: {
              '/ping' => {
                get: {
                  responses: {200 => {description: 'all good'}}
                }
              }
            }
          })
        )

        formatter.close(blank_notification)
      end
    end
  end
end
