<?php
/**
 * TWiT API Client
 * A client for interacting with the TWiT.tv API
 */
class TwitApiClient {
    private $app_id;
    private $app_key;
    private $base_url;
    private $logger;

    /**
     * Constructor with explicit credentials
     *
     * @param string $app_id The app ID for TWiT API authentication
     * @param string $app_key The app key for TWiT API authentication
     * @param string $base_url The base URL for the TWiT API
     */
    public function __construct($app_id = null, $app_key = null, $base_url = null) {
        if ($app_id !== null && $app_key !== null && $base_url !== null) {
            $this->app_id = $app_id;
            $this->app_key = $app_key;
            $this->base_url = $base_url;
        } else {
            // Load credentials from file
            $credentials = $this->load_credentials_from_file();
            $this->app_id = $credentials['twit_api']['app_id'];
            $this->app_key = $credentials['twit_api']['app_key'];
            $this->base_url = $credentials['twit_api']['base_url'] ?? 'https://twit.tv/api/v1.0';
        }
        
        $this->logger = function($level, $message) {
            $timestamp = date('Y-m-d H:i:s');
            echo "[$timestamp] [$level] $message" . PHP_EOL;
        };
        
        call_user_func($this->logger, 'DEBUG', "Loaded credentials - APP_ID: {$this->app_id}, BASE_URL: {$this->base_url}");
    }

    /**
     * Set a custom logger function
     *
     * @param callable $logger Logger function that accepts level and message parameters
     */
    public function set_logger($logger) {
        $this->logger = $logger;
    }

    /**
     * Get a list of all shows
     *
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_shows($params = []) {
        return $this->make_request('/shows', $params);
    }

    /**
     * Get a specific show by ID
     *
     * @param string $id The show ID
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_show($id, $params = []) {
        return $this->make_request("/shows/$id", $params);
    }

    /**
     * Get a list of all episodes
     *
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_episodes($params = []) {
        return $this->make_request('/episodes', $params);
    }

    /**
     * Get a specific episode by ID
     *
     * @param string $id The episode ID
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_episode($id, $params = []) {
        return $this->make_request("/episodes/$id", $params);
    }

    /**
     * Get live streams information
     *
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_streams($params = []) {
        return $this->make_request('/streams', $params);
    }

    /**
     * Get people information
     *
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    public function get_people($params = []) {
        return $this->make_request('/people', $params);
    }

    /**
     * Make an HTTP request to the TWiT API
     *
     * @param string $endpoint The API endpoint to request
     * @param array $params Optional query parameters
     * @return array JSON response from the API
     */
    private function make_request($endpoint, $params = []) {
        // Build URL with query parameters if any
        $url = $this->base_url . $endpoint;
        if (!empty($params)) {
            $url .= '?' . http_build_query($params);
        }
        
        call_user_func($this->logger, 'DEBUG', "Making request to: $url");
        
        // Using file_get_contents with stream context
        $opts = [
            'http' => [
                'method' => 'GET',
                'header' => [
                    'Accept: application/json',
                    "app-id: {$this->app_id}",
                    "app-key: {$this->app_key}"
                ]
            ]
        ];
        
        $context = stream_context_create($opts);
        
        // Make the request
        $response = @file_get_contents($url, false, $context);
        
        // Get status code from headers
        $status_code = 0;
        if (isset($http_response_header)) {
            foreach ($http_response_header as $header) {
                if (preg_match('/^HTTP\/\d\.\d\s+(\d+)/', $header, $matches)) {
                    $status_code = intval($matches[1]);
                    break;
                }
            }
        }
        
        // Handle response based on status code
        if ($response !== false && $status_code == 200) {
            return json_decode($response, true);
        } elseif ($status_code == 401 || $status_code == 403) {
            call_user_func($this->logger, 'ERROR', "Authentication error: Check your app-id and app-key");
            return [
                'error' => 'Authentication failed',
                'code' => $status_code
            ];
        } elseif ($status_code == 404) {
            call_user_func($this->logger, 'ERROR', "Resource not found: $endpoint");
            return [
                'error' => 'Resource not found',
                'code' => $status_code
            ];
        } elseif ($status_code == 500) {
            if ($response !== false && strpos($response, 'usage limits are exceeded') !== false) {
                call_user_func($this->logger, 'ERROR', "API usage limits exceeded");
                return [
                    'error' => 'API usage limits exceeded',
                    'code' => $status_code
                ];
            } else {
                call_user_func($this->logger, 'ERROR', "Server error: " . ($response ?: "No response body"));
                return [
                    'error' => 'Server error',
                    'code' => $status_code
                ];
            }
        } else {
            call_user_func($this->logger, 'ERROR', "Unexpected response: $status_code - " . ($response ?: "No response body"));
            return [
                'error' => 'Unexpected response',
                'code' => $status_code,
                'body' => $response
            ];
        }
    }

    /**
     * Load credentials from the shared credentials file
     *
     * @return array Credentials as an associative array
     */
    private function load_credentials_from_file() {
        // Find the credentials file (../credentials.yml)
        $credentials_file = dirname(__DIR__) . '/credentials.yml';
        
        if (!file_exists($credentials_file)) {
            throw new Exception("Credentials file not found: $credentials_file. " .
                "Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.");
        }
        
        // Read the YAML file
        $yaml_content = file_get_contents($credentials_file);
        
        // Parse YAML content
        return $this->parse_yaml($yaml_content);
    }
    
    /**
     * Simple YAML parser for credentials file
     * 
     * @param string $yaml_content YAML content to parse
     * @return array Parsed YAML as associative array
     */
    private function parse_yaml($yaml_content) {
        $result = [];
        $current_section = &$result;
        $indent_level = 0;
        $path = [];
        
        // Split content into lines
        $lines = explode("\n", $yaml_content);
        
        foreach ($lines as $line) {
            // Skip empty lines and comments
            if (empty(trim($line)) || substr(trim($line), 0, 1) === '#') {
                continue;
            }
            
            // Calculate indentation
            $indent = strlen($line) - strlen(ltrim($line));
            
            // Extract key and value
            if (strpos($line, ':') !== false) {
                list($key, $value) = array_pad(explode(':', $line, 2), 2, '');
                $key = trim($key);
                
                // Remove inline comments from value
                if (strpos($value, '#') !== false) {
                    $value = explode('#', $value)[0];
                }
                
                $value = trim($value);
                
                // If value is empty, this is a new section
                if (empty($value)) {
                    // Adjust path based on indentation
                    while ($indent_level >= $indent && count($path) > 0) {
                        array_pop($path);
                        $indent_level -= 2; // Assuming 2-space indentation
                    }
                    
                    // Add new section to path
                    $path[] = $key;
                    $indent_level = $indent;
                    
                    // Navigate to the correct nested array
                    $current_section = &$result;
                    foreach ($path as $path_key) {
                        if (!isset($current_section[$path_key])) {
                            $current_section[$path_key] = [];
                        }
                        $current_section = &$current_section[$path_key];
                    }
                } else {
                    // This is a key-value pair
                    $current_section[$key] = $value;
                }
            }
        }
        
        return $result;
    }
}

// If this script is run directly, test the client
if (basename(__FILE__) == basename($_SERVER['PHP_SELF'])) {
    try {
        echo "Testing connection to TWiT API...\n";
        
        $client = new TwitApiClient();
        
        // Test getting shows
        $result = $client->get_shows();
        
        if (isset($result['error'])) {
            echo "Error: {$result['error']}\n";
        } else {
            echo "Connection successful!\n";
            echo "Found {$result['count']} shows\n";
            
            if (isset($result['shows'])) {
                echo "\nFirst few shows:\n";
                $items = $result['shows'];
                for ($i = 0; $i < min(3, count($items)); $i++) {
                    echo "- {$items[$i]['label']} ({$items[$i]['id']})\n";
                }
                
                // Try to get a specific show (using the first show's ID if available)
                $first_show_id = $items[0]['id'];
                echo "\nGetting details for show ID: $first_show_id\n";
                
                $show_details = $client->get_show($first_show_id);
                if (!isset($show_details['error'])) {
                    // For single show, the response has a 'shows' object, not an array
                    if (isset($show_details['shows'])) {
                        $show = $show_details['shows'];
                        echo "Show title: {$show['label']}\n";
                        if (isset($show['description'])) {
                            $description = $show['description'];
                            echo "Description: " . substr($description, 0, 100) . "...\n";
                        }
                    }
                }
            }
            
            // Get streams information
            echo "\nGetting live streams information...\n";
            $streams = $client->get_streams();
            if (!isset($streams['error']) && isset($streams['streams'])) {
                echo "Found {$streams['count']} streams\n";
                $items = $streams['streams'];
                for ($i = 0; $i < min(2, count($items)); $i++) {
                    echo "- {$items[$i]['label']} ({$items[$i]['streamType']})\n";
                }
            }
        }
    } catch (Exception $e) {
        echo "Error: " . $e->getMessage() . "\n";
    }
}
?>
