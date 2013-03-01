require 'net/http'
require 'uri'
require 'json'

methods = ['post'].freeze

method = ARGV[0]

unless methods.include?(method)
  puts "Not found method: #{method}"
  exit
end

path = 'http://127.0.0.1:3000/events'
uri = URI.parse(path)

headers = {
  'Content-Type' =>'application/json',
  'X-NOTIFICATION-ID' => 'system',
  'X-MESSAGE-TYPE' => 'alert_port'
}

messages = {
  'instance_id' => 'i-abcdefgh',
  'instance_name' => 'test',
  'instance_ip' => '127.0.0.1',
  'account_id' => 'a-abcdefgh',
  'event_datetime' => Time.now,
  'message' => 'Alert!!!!'
}

request = Net::HTTP::Post.new(uri.request_uri, headers)
request.body = messages.to_json

http = Net::HTTP.new(uri.host, uri.port)
http.set_debug_output $stderr
http.start do |h|
  response = h.request(request)
puts response.body
end
