require 'rspec/core/rake_task'

desc "Regenerate Swagger docs"
RSpec::Core::RakeTask.new(:swagger) do |t|
  t.verbose = false
  t.rspec_opts = "-f RSpec::Rails::Swagger::Formatter --order defined -t swagger_object"
end

RSpec::Core::RakeTask.new(:swagger_v3) do |t|
  t.verbose = false
  t.rspec_opts = "-f RSpec::Rails::Swagger::Formatter_V3 --order defined -t swagger_object"
end
