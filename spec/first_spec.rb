require 'rspec/swagger'

RSpec.describe RSpec::Swagger do
  it "loads" do
    expect(RSpec::Swagger::Version::STRING).to eq '0.1.0'
  end
end
