require "spec_helper"

RSpec.describe RSpec::Swagger::Formatter do
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
          swagger_data: {
            path: "/ping",
            operation: :put,
            status_code: 200,
            response_description: 'OK',
            example: nil
          }
        }
      end

      it "copies the requests into the document" do
        formatter.example_finished(example_notification)

        expect(formatter.documents.values.first).to eq({
          swagger: '2.0',
          info: {
            version: '0.0.0',
            title: 'Simple API'
          },
          paths: {
            '/ping' => {
              put: {
                responses: {200 => {description: 'OK'}}
              }
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
          swagger_data: {
            document: 'doc2.json',
            path: "/ping",
            operation: :put,
            status_code: 200
          }
        }
      end

      it "puts the response on the right document" do
        formatter.example_finished(example_notification)

        expect(formatter.documents['doc1.json'][:paths]).to be_blank
        expect(formatter.documents['doc2.json'][:paths].length).to eq(1)
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
          swagger_data: {path: '/ping', operation: :get, status_code: 200, response_description: 'all good' }
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
