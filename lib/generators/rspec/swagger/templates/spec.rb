require 'swagger_helper'

RSpec.describe '<%= controller_path %>', type: :request do
<% @routes.each do | template, path_item | %>
  path '<%= template %>' do
<% unless path_item[:params].empty? -%>
    # You'll want to customize the parameter types...
<% path_item[:params].each do |param| -%>
    parameter '<%= param %>', in: :path, type: :string
<% end -%>
    # ...and values used to make the requests.
<% path_item[:params].each do |param| -%>
    let(:<%= param %>) { '123' }
<% end -%>

<% end -%>
<% path_item[:actions].each do | action, details | -%>
    <%= action %>(summary: '<%= details[:summary] %>') do
      response(200, description: 'successful') do
        # You can add before/let blocks here to trigger the response code
      end
    end
<% end -%>
  end
<% end -%>
end
