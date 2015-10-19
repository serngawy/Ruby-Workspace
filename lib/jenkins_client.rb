require 'csv'
require 'net/http'
require 'json'
require 'openssl'

class Jenkins_client

  JOB_STATUS_HISTORY_FILENAME = 'job_status_history.csv'
  JENKINS_URL = ''#ENV['JENKINS_URL']
  USERNAME = ''#ENV['JENKINS_USERNAME']
  PWD = ''#ENV['JENKINS_PASSWORD']
  NUMBER_SAMPLES_IN_HISTORY = 100
  MAX_FILENAME_LENGTH = 30
  FILENAME_TAIL_LENGTH = 20
  JENKINS_BUILD_STATUS_HISTORY_URI = URI.parse(JENKINS_URL)

  def get_response(path)
    http = Net::HTTP.new(JENKINS_BUILD_STATUS_HISTORY_URI.host, JENKINS_BUILD_STATUS_HISTORY_URI.port)
    http.use_ssl = JENKINS_BUILD_STATUS_HISTORY_URI.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
    request = Net::HTTP::Get.new(path)
    request.basic_auth(USERNAME, PWD)
    return http.request(request)
  end

  def GetBuildInfo()
    print "Fetch job status info from Jenkins (full job list)\n"
    response = get_response("/api/json?tree=jobs[name,color]")
    build_info = JSON.parse(response.body)
    return build_info
  end

  def trim_filename(filename)
    filename_length = filename.length
    if filename_length > MAX_FILENAME_LENGTH
      filename = filename.to_s[0..MAX_FILENAME_LENGTH] + '...' + filename.to_s[(filename_length - FILENAME_TAIL_LENGTH)..filename_length]
    end
    return filename
  end

  def update_job_status_history_csv_file(latest_jenkins_job_status_map)
    job_status_history = Array.new
    if (File.file?(JOB_STATUS_HISTORY_FILENAME))
      job_status_history = CSV.read(JOB_STATUS_HISTORY_FILENAME)
      File.delete(JOB_STATUS_HISTORY_FILENAME)
      job_status_history.each do |job_status_history_row|
        job_name = job_status_history_row[0]
        if (latest_jenkins_job_status_map.key?(job_name))
          if (job_status_history_row.size > NUMBER_SAMPLES_IN_HISTORY)
            job_status_history_row.delete_at(1)
            job_status_history_row << latest_jenkins_job_status_map[job_name]
          else
            job_status_history_row << latest_jenkins_job_status_map[job_name] 
          end
        else
          job_status_history.delete(job_status_history_row)
        end
      end
    else
      job_status_history = latest_jenkins_job_status_map.map
    end

    out_file = File.new(JOB_STATUS_HISTORY_FILENAME, "a")
    job_status_history.each do |job_status_history_row|
      element_index = 1
      job_status_history_row.each do |element|
        out_file << element 
        if (element_index == job_status_history_row.length)
          out_file << "\n"
        else
          out_file << ","
        end
        element_index = element_index + 1
      end
    end
    out_file.close
  end

  def get_build_status_json_from_csv_file()
    build_status_history = Hash.new
    jenkins_job_entries = Array.new

    CSV.foreach(JOB_STATUS_HISTORY_FILENAME) do |job_status_history_row|
      job_name = job_status_history_row[0]
      job_history_entry = Hash.new
      job_history_entry["job_name"] = trim_filename(job_name)
      job_status_entries = Array.new

      for status_index in 1 ... job_status_history_row.size
        job_status_item = job_status_history_row[status_index]
        job_status_entries << {"status" => job_status_item}
      end

      job_history_entry.merge!("build_status" => job_status_entries)
      jenkins_job_entries << job_history_entry
    end

    build_status_history.merge!("jenkins_jobs" => jenkins_job_entries)
  end

  def get_build_status_json_from_csv_file_filter(build_filter)
    build_status_history = Hash.new
    jenkins_job_entries = Array.new

    CSV.foreach(JOB_STATUS_HISTORY_FILENAME) do |job_status_history_row|
      job_name = job_status_history_row[0]
      build_filter.each do | f_build |
        if job_name == f_build
          job_history_entry = Hash.new
          job_history_entry["job_name"] = trim_filename(job_name)
          job_status_entries = Array.new

          for status_index in 1 ... job_status_history_row.size
            job_status_item = job_status_history_row[status_index]
            job_status_entries << {"status" => job_status_item}
          end

          job_history_entry.merge!("build_status" => job_status_entries)
          jenkins_job_entries << job_history_entry
        end
      end
    end

    build_status_history.merge!("jenkins_jobs" => jenkins_job_entries)
  end

end