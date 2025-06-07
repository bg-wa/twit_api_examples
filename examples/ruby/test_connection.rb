#!/usr/bin/env ruby
# TWiT API Connection Test Script
# This script tests the connection to the TWiT.tv API

require 'net/http'
require 'uri'
require 'json'
require 'yaml'

# Load credentials from shared credentials file
credentials_file = File.join(File.dirname(__FILE__), '..', 'credentials.yml')

if File.exist?(credentials_file)
  begin
    puts "Loading credentials from: #{credentials_file}"
    credentials_content = File.read(credentials_file)
    puts "Credentials file content (first line): #{credentials_content.lines.first.strip}"

    credentials = YAML.load_file(credentials_file)
    puts "Parsed YAML structure: #{credentials.inspect}"

    APP_ID = credentials['twit_api']['app_id']
    APP_KEY = credentials['twit_api']['app_key']
    API_BASE_URL = credentials['twit_api']['base_url'] || 'https://twit.tv/api/v1.0'

    puts "Using APP_ID: #{APP_ID}"
    puts "Using APP_KEY: #{APP_KEY.gsub(/./, '*')}" # Mask the actual key for security
  rescue => e
    puts "Error loading credentials: #{e.message}"
    puts "Please make sure your credentials.yml file is properly formatted."
    puts "You can copy credentials.yml.sample to credentials.yml and update with your actual credentials."
    exit 1
  end
else
  puts "Credentials file not found: #{credentials_file}"
  puts "Please copy credentials.yml.sample to credentials.yml and update with your actual credentials."
  exit 1
end

# Test endpoint - shows is a simple endpoint to test
endpoint = '/shows'
url = URI.parse("#{API_BASE_URL}#{endpoint}")

# Create HTTP request
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true

# Create request with headers
request = Net::HTTP::Get.new(url.request_uri)
request['Accept'] = 'application/json'
request['app-id'] = APP_ID
request['app-key'] = APP_KEY

puts "\nTesting connection to TWiT API..."
puts "Endpoint: #{url}"
puts "Headers: app-id=#{APP_ID}, app-key=#{APP_KEY}"

begin
  # Send request
  response = http.request(request)

  # Parse and display response
  if response.code == '200'
    puts "Connection successful! (HTTP #{response.code})"

    # Parse JSON response
    result = JSON.parse(response.body)

    # Display some basic info about the response
    if result['count']
      puts "Found #{result['count']} shows"
    end

    # Display first few items if available
    if result['shows'] && !result['shows'].empty?
      puts "\nFirst few shows:"
      result['shows'].take(3).each do |show|
        puts "- #{show['label']} (#{show['id']})"
      end
    end
  else
    puts "Connection failed with HTTP status: #{response.code}"
    puts "Response body: #{response.body}"

    # Check for specific error messages
    if response.code == '500' && response.body.include?('usage limits are exceeded')
      puts "Error: API usage limits exceeded. Check your plan limits."
    elsif response.code == '401' || response.code == '403'
      puts "Error: Authentication failed. Check your APP_ID and APP_KEY."
    end
  end
rescue => e
  puts "Error connecting to API: #{e.message}"
  puts e.backtrace.join("\n")
end
