require 'rspec/core/rake_task'

desc "Regenerate Swagger docs"
RSpec::Core::RakeTask.new(:swagger) do |t|
  t.verbose = false
  t.rspec_opts = "-f RSpec::Rails::Swagger::Formatter --order defined -t swagger_object"
end
