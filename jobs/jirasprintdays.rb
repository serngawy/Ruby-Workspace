# Displays the board name, sprint name and remaining days for the active sprint for a specific board in Jira Agile

require 'net/http'
require 'json'
require 'time'
require 'uri'
require 'cgi'
require 'openssl'
require 'csv'
require File.expand_path('../../lib/jira_client', __FILE__)

# your view ID from JIRA
view_mapping = {
  'view' => { :view_id => 0 },
}

SCHEDULER.every '2h', :first_in => 0 do
  view_mapping.each do |view, view_id|
    jiraClient = Jira_client.new()
    view_name = ""
    sprint_name = ""
    days = ""
    view_json = jiraClient.get_view_for_viewid(view_id[:view_id])
    if (view_json)
      view_name = view_json['name']
      sprint_json = jiraClient.get_active_sprint_for_view(view_json['id'])
      if (sprint_json)
        sprint_name = sprint_json['name']
        days_json = jiraClient.get_remaining_days(view_json['id'], sprint_json['id'])
        days = days_json['days']
      end
    end
    # for more views we will need to add switch case for the view_id
    send_event("JiraSprintDays", {
      viewName: view_name,
      sprintName: sprint_name,
      daysRemaining: days
    })
  end
end
