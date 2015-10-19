require 'jira'
require File.expand_path('../../lib/jira_client', __FILE__)

# your view ID from JIRA
view_mapping = {
  'view' => { :view_id => 0 },
}

SCHEDULER.every '2h', :first_in => 0 do
  view_mapping.each do |view, view_id|
    jiraClient = Jira_client.new()
    total_points = 0
    closed_points = 0
    view_json = jiraClient.get_view_for_viewid(view_id[:view_id])
    if (view_json)
      sprint_json = jiraClient.get_active_sprint_for_view(view_json['id'])
      if (sprint_json)
        sprint_name = sprint_json['name']
        sprintreport_json = jiraClient.get_sprint_report(view_json['id'], sprint_json['id'])
        closed_points = sprintreport_json["contents"]["completedIssues"].length
        total_points = sprintreport_json["contents"]["incompletedIssues"].length + closed_points
      end
    end

    if total_points == 0
      percentage = 0
      moreinfo = "No sprint currently in progress"
    else
      percentage = ((closed_points/total_points)*100).to_i
      moreinfo = "#{closed_points.to_i} / #{total_points.to_i}"
    end

    # for more views we will need to add switch case for view_id
    send_event('sprintprogress', { title: "#{sprint_name}", progress: "Sprint Progress", min: 0, value: percentage, max: 100, moreinfo: moreinfo })
  end
end