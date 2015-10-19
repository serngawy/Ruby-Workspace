require 'websocket-eventmachine-client'
require 'cgi'
EM.epoll

SCHEDULER.every '30m', :first_in => 0 do |job|
  last_Flow = ""
  last_netFlow = ""
  last_OpenFlow = ""
  host = ''#ENV['WebSocket_URL']
  ws = WebSocket::EventMachine::Client.connect(:uri => "#{host}")

  ws.onopen do
    puts "Web Socket connected"
    ws.send("Netconf")
    ws.send("OpenFlow")
    ws.send("Flow")
  end

  ws.onmessage do |msg, type|
    puts "Received #{msg} \n"
    if msg.include? "METRIC_NETCONF"
      idx = msg.index(":")
      netflow = msg[idx+1,msg.length]
      # trim the value
      netflow = (netflow.delete('E').to_f * 10).round
      # your text control data-id
      send_event("netflow", { current: netflow, last: last_netFlow })
      last_netFlow = netflow
    elsif msg.include? "METRIC_FLOW"
      idx = msg.index(":")
      flow = msg[idx+1,msg.length]
      # trim the value
      flow = (flow.delete('E').to_f * 10).round
      # your text control data-id
      send_event("flow", { current: flow, last: last_Flow })
      last_Flow = flow
    elsif msg.include? "METRIC_OPENFLOW"
      idx = msg.index(":")
      openflow = msg[idx+1,msg.length]
      # trim the value
      openflow = (openflow.delete('E').to_f * 10).round
      # your text control data-id
      send_event("openflow", { current: openflow, last: last_OpenFlow })
      last_OpenFlow = openflow
    end
  end

  ws.onclose do |code, reason|
      puts "Disconnected with status code: #{code}"
  end
end