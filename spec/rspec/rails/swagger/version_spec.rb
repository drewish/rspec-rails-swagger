require 'swagger_helper'

RSpec.describe RSpec::Rails::Swagger do
  it "loads" do
    expect(RSpec::Rails::Swagger::Version::STRING).to eq '0.1.0'
  end
end
