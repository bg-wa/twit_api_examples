#!/usr/bin/env ruby
# TWiT API Client
# A more comprehensive client for interacting with the TWiT.tv API

require 'net/http'
require 'uri'
require 'json'
require 'logger'
require 'yaml'

class TwitApiClient
  attr_reader :logger

  def initialize(app_id = nil, app_key = nil, base_url = nil)
    # Try to load credentials from file if not provided
    if app_id.nil? || app_key.nil?
      load_credentials_from_file
    else
      @app_id = app_id
      @app_key = app_key
      @base_url = base_url || 'https://twit.tv/api/v1.0'
    end
    
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  # Get a list of all shows
  def get_shows(params = {})
    make_request('/shows', params)
  end

  # Get a specific show by ID
  def get_show(id, params = {})
    make_request("/shows/#{id}", params)
  end

  # Get a list of all episodes
  def get_episodes(params = {})
    make_request('/episodes', params)
  end

  # Get a specific episode by ID
  def get_episode(id, params = {})
    make_request("/episodes/#{id}", params)
  end

  # Get live streams information
  def get_streams(params = {})
    make_request('/streams', params)
  end

  # Get people information
  def get_people(params = {})
    make_request('/people', params)
  end

  private

  # Load credentials from the shared credentials file
  def load_credentials_from_file
    credentials_file = File.join(File.dirname(__FILE__), '..', 'credentials.yml')
    
    if File.exist?(credentials_file)
      begin
        credentials = YAML.load_file(credentials_file)
        @app_id = credentials['twit_api']['app_id']
        @app_key = credentials['twit_api']['app_key']
        @base_url = credentials['twit_api']['base_url'] || 'https://twit.tv/api/v1.0'
      rescue => e
        @logger.error("Error loading credentials: #{e.message}")
        raise "Failed to load credentials: #{e.message}. Please make sure your credentials.yml file is properly formatted."
      end
    else
      raise "Credentials file not found: #{credentials_file}. Please copy credentials.yml.sample to credentials.yml and update with your actual credentials."
    end
  end

  # Make an HTTP request to the TWiT API
  def make_request(endpoint, params = {})
    # Build URL with query parameters if any
    query_string = URI.encode_www_form(params) unless params.empty?
    url_string = "#{@base_url}#{endpoint}"
    url_string += "?#{query_string}" if query_string
    
    url = URI.parse(url_string)
    
    # Create HTTP client
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    
    # Create request with headers
    request = Net::HTTP::Get.new(url.request_uri)
    request['Accept'] = 'application/json'
    request['app-id'] = @app_id
    request['app-key'] = @app_key
    
    @logger.debug("Making request to: #{url_string}")
    
    begin
      response = http.request(request)
      
      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 401, 403
        @logger.error("Authentication error: Check your app-id and app-key")
        { "error" => "Authentication failed", "code" => response.code }
      when 404
        @logger.error("Resource not found: #{endpoint}")
        { "error" => "Resource not found", "code" => response.code }
      when 500
        if response.body.include?('usage limits are exceeded')
          @logger.error("API usage limits exceeded")
          { "error" => "API usage limits exceeded", "code" => response.code }
        else
          @logger.error("Server error: #{response.body}")
          { "error" => "Server error", "code" => response.code }
        end
      else
        @logger.error("Unexpected response: #{response.code} - #{response.body}")
        { "error" => "Unexpected response", "code" => response.code, "body" => response.body }
      end
    rescue => e
      @logger.error("Request failed: #{e.message}")
      { "error" => e.message }
    end
  end
end

# Example usage
if __FILE__ == $0
  begin
    client = TwitApiClient.new
    
    puts "Testing connection to TWiT API..."
    
    # Test getting shows
    result = client.get_shows
    
    if result["error"]
      puts "Error: #{result["error"]}"
    else
      puts "Connection successful!"
      puts "Found #{result['count']} shows"
      
      if result['shows'] && !result['shows'].empty?
        puts "\nFirst few shows:"
        result['shows'].take(3).each do |show|
          puts "- #{show['label']} (#{show['id']})"
        end
      end
      
      # Try to get a specific show (using the first show's ID if available)
      if result['shows'] && !result['shows'].empty?
        first_show_id = result['shows'].first['id']
        puts "\nGetting details for show ID: #{first_show_id}"
        
        show_details = client.get_show(first_show_id)
        if !show_details["error"]
          puts "Show title: #{show_details['label']}"
          puts "Description: #{show_details['description'][0..100]}..." if show_details['description']
        end
      end
      
      # Get streams information
      puts "\nGetting live streams information..."
      streams = client.get_streams
      if !streams["error"] && streams['streams']
        puts "Found #{streams['count']} streams"
        streams['streams'].take(2).each do |stream|
          puts "- #{stream['label']} (#{stream['streamType']})"
        end
      end
    end
  rescue => e
    puts "Error: #{e.message}"
  end
end
