require "spec_helper"

RSpec.describe RSpec::Swagger::Formatter do
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }

  let(:group_notification) { double(group: group) }
  let(:group) { double(metadata: metadata) }
  let(:metadata) { {} }

  describe "#example_group_started" do
    context "groups with no type" do
      let(:metadata) { {} }

      it "ignores" do
        formatter.example_group_started(group_notification)

        expect(formatter).not_to be_watching
      end
    end

    context "groups with type request" do
      let(:metadata) { {type: :request} }

      it "watches" do
        formatter.example_group_started(group_notification)

        expect(formatter).to be_watching
      end
    end
  end

  describe "#example_group_finished" do
    let(:metadata) { {} }

    it "resets to watching" do
      formatter.example_group_started(group_notification)
      expect(formatter).not_to be_watching

      formatter.example_group_finished(group_notification)
      expect(formatter).to be_watching
    end
  end
end
