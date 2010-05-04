require 'rubygems'
require 'restclient'
require 'nokogiri'
require 'open-uri'

sites = [{:name=>'rightscale', :url=>'http://www.rightscale.com'},
         {:name=>'heroku', :url=>'http://heroku.com'}]

def process_rightscale(doc, file)
  launched = doc.css('div#serversLaunched p').first.text.gsub(/,/,'').to_i
  File.open(file, 'a') do |f|
    f.write("#{Time.now.to_s},#{launched}\n")
  end
end

def process_heroku(doc, file)
  launched = 0
  offset = 0
  doc.css('div.apps img').reverse.each_with_index do |img, index|
    digit_match = /\/images\/v3\/(.*)\.png$/.match(img.attributes['src'].value)
    if digit_match
      digit = digit_match.captures.first
      if digit.eql?('comma')
        offset = 1
        next
      end
      launched += digit.to_i*10**(index - offset)
    end
  end
  File.open(file, 'a') do |f|
    f.write("#{Time.now.to_s},#{launched}\n")
  end
end

while true do
  sites.each do |site|
    doc = RestClient.get site[:url]
    send("process_#{site[:name]}", Nokogiri::HTML.parse(doc), "#{site[:name]}.csv")
    puts "COLLECTED #{Time.now}:#{site[:name]}"
  end
  sleep(3600)
end
