<?php
/**
 * TWiT API Connection Test Script
 * This script tests the connection to the TWiT.tv API
 */

// Function to parse YAML credentials file
function parse_yaml_file($file_path) {
    if (!file_exists($file_path)) {
        throw new Exception("Credentials file not found: $file_path");
    }
    
    echo "Loading credentials from: $file_path\n";
    $first_line = trim(file($file_path)[0]);
    echo "Credentials file content (first line): $first_line\n";
    
    $yaml_content = file_get_contents($file_path);
    $result = [];
    $current_section = null;
    $current_indent = 0;
    
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
            
            // If value is empty and key is twit_api, this is our section
            if ($key === 'twit_api' && empty($value)) {
                $current_section = 'twit_api';
                $current_indent = $indent;
                $result[$current_section] = [];
            } 
            // If we're in the twit_api section and indentation is greater
            elseif ($current_section === 'twit_api' && $indent > $current_indent) {
                $result[$current_section][$key] = $value;
            }
            // If indentation is less or equal to the section indentation, we're out of the section
            elseif ($current_section && $indent <= $current_indent) {
                $current_section = null;
            }
        }
    }
    
    echo "Parsed YAML structure: " . json_encode($result) . "\n";
    return $result;
}

// Function to mask sensitive information
function mask_string($input) {
    if (empty($input) || strlen($input) <= 8) {
        return "********";
    }
    return substr($input, 0, 4) . "********************************";
}

try {
    // Find and parse the credentials file
    $credentials_file = dirname(__DIR__) . '/credentials.yml';
    $credentials = parse_yaml_file($credentials_file);
    
    if (!isset($credentials['twit_api']) || 
        !isset($credentials['twit_api']['app_id']) || 
        !isset($credentials['twit_api']['app_key'])) {
        throw new Exception("Invalid credentials format in $credentials_file");
    }
    
    $app_id = $credentials['twit_api']['app_id'];
    $app_key = $credentials['twit_api']['app_key'];
    $base_url = $credentials['twit_api']['base_url'] ?? 'https://twit.tv/api/v1.0';
    
    echo "Using APP_ID: $app_id\n";
    echo "Using APP_KEY: " . mask_string($app_key) . "\n";
    echo "Using BASE_URL: $base_url\n";
    
    echo "\nTesting connection to TWiT API...\n";
    
    // Test endpoint
    $endpoint = "/shows";
    $url = $base_url . $endpoint;
    
    echo "Endpoint: $url\n";
    echo "Headers: app-id=$app_id, app-key=" . mask_string($app_key) . "\n";
    
    // Using file_get_contents with stream context instead of cURL
    $opts = [
        'http' => [
            'method' => 'GET',
            'header' => [
                'Accept: application/json',
                "app-id: $app_id",
                "app-key: $app_key"
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
    
    if ($response !== false && $status_code == 200) {
        echo "Connection successful with HTTP status: $status_code\n";
        
        // Parse JSON response
        $data = json_decode($response, true);
        
        if (isset($data['count'])) {
            echo "Found {$data['count']} shows\n";
        }
        
        // Display first few items if available
        if (isset($data['shows'])) {
            echo "\nFirst few shows:\n";
            $items = $data['shows'];
            for ($i = 0; $i < min(3, count($items)); $i++) {
                echo "- {$items[$i]['label']} ({$items[$i]['id']})\n";
            }
        }
    } else {
        echo "Connection failed with HTTP status: $status_code\n";
        echo "Response body: " . ($response ?: "No response received") . "\n";
        
        // Provide guidance based on status code
        if ($status_code == 401 || $status_code == 403) {
            echo "Authentication failed. Check your APP_ID and APP_KEY.\n";
        } else if ($status_code == 404) {
            echo "Resource not found. Check that the API endpoint is correct.\n";
        } else if ($status_code == 500) {
            echo "Server error. If the message contains 'application is not active', " .
                 "you need to activate your API credentials in the TWiT.tv 3Scale portal.\n";
        }
    }
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
?>
