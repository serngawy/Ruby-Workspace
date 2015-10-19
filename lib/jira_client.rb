require 'net/http'
require 'json'
require 'time'
require 'uri'
require 'cgi'
require 'openssl'
require 'csv'

class Jira_client

JIRA_URI  = ''#URI.parse(ENV['JIRA_WEBSITE'])
UserName = ''#ENV['JIRA_USERNAME']
Passwd = ''#ENV['JIRA_PASSWORD']

# create HTTP
  def create_http()
    http = Net::HTTP.new(JIRA_URI.host, JIRA_URI.port)
    if ('https' == JIRA_URI.scheme)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    return http
  end

  # create HTTP request for given path
  def create_request(path)
    request = Net::HTTP::Get.new(JIRA_URI.path + path)
    request.basic_auth(UserName, Passwd)
    return request
  end

  # gets the view for a given view id
  def get_view_for_viewid(view_id)
    http = create_http()
    request = create_request("/rest/greenhopper/1.0/rapidviews/list")
    response = http.request(request)
    views = JSON.parse(response.body)["views"]
    views.each do |view|
      if view['id'] == view_id
        return view
      end
    end
    return nil
  end
  
  # gets the active sprint for the view
  def get_active_sprint_for_view(view_id)
    http = create_http()
    request = create_request("/rest/greenhopper/1.0/sprintquery/#{view_id}")
    response = http.request(request)
    sprints = JSON.parse(response.body)['sprints']
    sprints.each do |sprint|
      if sprint['state'] == 'ACTIVE'
        return sprint
      end
    end
  end
  
  # gets the remaining days for the sprint
  def get_remaining_days(view_id, sprint_id)
    http = create_http()
    request = create_request("/rest/greenhopper/1.0/gadgets/sprints/remainingdays?rapidViewId=#{view_id}&sprintId=#{sprint_id}")
    response = http.request(request)
    return JSON.parse(response.body)
  end
  
  # gets the sprint report data
  def get_sprint_report(view_id, sprint_id)
    http = create_http()
    request = create_request("/rest/greenhopper/1.0/rapid/charts/sprintreport?rapidViewId=#{view_id}&sprintId=#{sprint_id}")
    response = http.request(request)
    return JSON.parse(response.body)
  end
  
end