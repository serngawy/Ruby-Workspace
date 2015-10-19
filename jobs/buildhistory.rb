require 'csv'
require 'net/http'
require 'json'
require 'openssl'
require File.expand_path('../../lib/jenkins_client', __FILE__)

filter_build = 'build1, build2, build3'#ENV['FILTER_BUILD'].split(',')

SCHEDULER.every '5m', :first_in => 0 do
    jnk = Jenkins_client.new()
    jobs = jnk.GetBuildInfo()
    most_recent_jenkins_status_map = Hash.new

    jobs["jobs"].each do |job|
      job_status_entry = {job["name"] => job["color"]}
      most_recent_jenkins_status_map.merge!(job_status_entry)
    end

    jnk.update_job_status_history_csv_file(most_recent_jenkins_status_map)
    build_status_history_json = jnk.get_build_status_json_from_csv_file()
    #your build history control data-id
    send_event("buildhistory", build_status_history_json)
    filter_build_json = jnk.get_build_status_json_from_csv_file_filter(filter_build)
    #your filter build history control data-id
    send_event("filterbuildhistory", filter_build_json)
end