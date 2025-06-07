package tv.twit.api;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.json.JSONObject;
import org.yaml.snakeyaml.Yaml;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * TWiT API Client
 * A client for interacting with the TWiT.tv API
 */
public class TwitApiClient {
    private final String appId;
    private final String appKey;
    private final String baseUrl;
    private final Logger logger;
    private final HttpClient httpClient;

    /**
     * Constructor with explicit credentials
     *
     * @param appId   The app ID for TWiT API authentication
     * @param appKey  The app key for TWiT API authentication
     * @param baseUrl The base URL for the TWiT API
     */
    public TwitApiClient(String appId, String appKey, String baseUrl) {
        this.appId = appId;
        this.appKey = appKey;
        this.baseUrl = baseUrl;
        this.logger = Logger.getLogger(TwitApiClient.class.getName());
        this.httpClient = HttpClients.createDefault();
    }

    /**
     * Default constructor that loads credentials from file
     */
    public TwitApiClient() {
        Map<String, Object> credentials = loadCredentialsFromFile();
        Map<String, Object> twitApi = (Map<String, Object>) credentials.get("twit_api");
        
        this.appId = (String) twitApi.get("app_id");
        this.appKey = (String) twitApi.get("app_key");
        this.baseUrl = twitApi.containsKey("base_url") ? (String) twitApi.get("base_url") : "https://twit.tv/api/v1.0";
        this.logger = Logger.getLogger(TwitApiClient.class.getName());
        this.httpClient = HttpClients.createDefault();
        
        logger.info("Loaded credentials - APP_ID: " + appId + ", BASE_URL: " + baseUrl);
    }

    /**
     * Get the base URL for the API
     *
     * @return The base URL
     */
    public String getBaseUrl() {
        return baseUrl;
    }

    /**
     * Get a list of all shows
     *
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getShows(Map<String, String> params) {
        return makeRequest("/shows", params);
    }

    /**
     * Get a list of all shows with default parameters
     *
     * @return JSON response from the API
     */
    public JSONObject getShows() {
        return getShows(new HashMap<>());
    }

    /**
     * Get a specific show by ID
     *
     * @param id     The show ID
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getShow(String id, Map<String, String> params) {
        return makeRequest("/shows/" + id, params);
    }

    /**
     * Get a specific show by ID with default parameters
     *
     * @param id The show ID
     * @return JSON response from the API
     */
    public JSONObject getShow(String id) {
        return getShow(id, new HashMap<>());
    }

    /**
     * Get a list of all episodes
     *
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getEpisodes(Map<String, String> params) {
        return makeRequest("/episodes", params);
    }

    /**
     * Get a list of all episodes with default parameters
     *
     * @return JSON response from the API
     */
    public JSONObject getEpisodes() {
        return getEpisodes(new HashMap<>());
    }

    /**
     * Get a specific episode by ID
     *
     * @param id     The episode ID
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getEpisode(String id, Map<String, String> params) {
        return makeRequest("/episodes/" + id, params);
    }

    /**
     * Get a specific episode by ID with default parameters
     *
     * @param id The episode ID
     * @return JSON response from the API
     */
    public JSONObject getEpisode(String id) {
        return getEpisode(id, new HashMap<>());
    }

    /**
     * Get live streams information
     *
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getStreams(Map<String, String> params) {
        return makeRequest("/streams", params);
    }

    /**
     * Get live streams information with default parameters
     *
     * @return JSON response from the API
     */
    public JSONObject getStreams() {
        return getStreams(new HashMap<>());
    }

    /**
     * Get people information
     *
     * @param params Optional query parameters
     * @return JSON response from the API
     */
    public JSONObject getPeople(Map<String, String> params) {
        return makeRequest("/people", params);
    }

    /**
     * Get people information with default parameters
     *
     * @return JSON response from the API
     */
    public JSONObject getPeople() {
        return getPeople(new HashMap<>());
    }

    /**
     * Make an HTTP request to the TWiT API
     *
     * @param endpoint The API endpoint to request
     * @param params   Optional query parameters
     * @return JSON response from the API
     */
    private JSONObject makeRequest(String endpoint, Map<String, String> params) {
        try {
            // Build URL with query parameters if any
            StringBuilder urlBuilder = new StringBuilder(baseUrl + endpoint);
            
            if (!params.isEmpty()) {
                urlBuilder.append("?");
                boolean first = true;
                for (Map.Entry<String, String> entry : params.entrySet()) {
                    if (!first) {
                        urlBuilder.append("&");
                    }
                    urlBuilder.append(entry.getKey()).append("=").append(entry.getValue());
                    first = false;
                }
            }
            
            String url = urlBuilder.toString();
            logger.fine("Making request to: " + url);
            
            HttpGet request = new HttpGet();
            request.setURI(new URI(url));
            request.setHeader("Accept", "application/json");
            request.setHeader("app-id", appId);
            request.setHeader("app-key", appKey);
            
            HttpResponse response = httpClient.execute(request);
            int statusCode = response.getStatusLine().getStatusCode();
            HttpEntity entity = response.getEntity();
            String responseBody = entity != null ? EntityUtils.toString(entity) : "";
            
            if (statusCode == 200) {
                return new JSONObject(responseBody);
            } else if (statusCode == 401 || statusCode == 403) {
                logger.severe("Authentication error: Check your app-id and app-key");
                JSONObject error = new JSONObject();
                error.put("error", "Authentication failed");
                error.put("code", statusCode);
                return error;
            } else if (statusCode == 404) {
                logger.severe("Resource not found: " + endpoint);
                JSONObject error = new JSONObject();
                error.put("error", "Resource not found. Check that the API endpoint is correct.");
                error.put("code", statusCode);
                return error;
            } else if (statusCode == 500) {
                if (responseBody.contains("usage limits are exceeded")) {
                    logger.severe("API usage limits exceeded");
                    JSONObject error = new JSONObject();
                    error.put("error", "API usage limits exceeded");
                    error.put("code", statusCode);
                    return error;
                } else {
                    logger.severe("Server error: " + responseBody);
                    JSONObject error = new JSONObject();
                    error.put("error", "Server error");
                    error.put("code", statusCode);
                    return error;
                }
            } else {
                logger.severe("Unexpected response: " + statusCode + " - " + responseBody);
                JSONObject error = new JSONObject();
                error.put("error", "Unexpected response");
                error.put("code", statusCode);
                error.put("body", responseBody);
                return error;
            }
        } catch (IOException | URISyntaxException e) {
            logger.log(Level.SEVERE, "Request failed", e);
            JSONObject error = new JSONObject();
            error.put("error", e.getMessage());
            return error;
        }
    }

    /**
     * Load credentials from the shared credentials file
     *
     * @return Map containing the credentials
     */
    private Map<String, Object> loadCredentialsFromFile() {
        try {
            // Find the credentials file (../credentials.yml)
            String currentDir = System.getProperty("user.dir");
            File credentialsFile = Paths.get(currentDir, "..", "credentials.yml").toFile();
            
            if (!credentialsFile.exists()) {
                throw new IOException("Credentials file not found: " + credentialsFile.getAbsolutePath() + 
                        ". Please copy credentials.yml.sample to credentials.yml and update with your actual credentials.");
            }
            
            // Load and parse the YAML file
            Yaml yaml = new Yaml();
            try (FileInputStream inputStream = new FileInputStream(credentialsFile)) {
                return yaml.load(inputStream);
            }
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Error loading credentials", e);
            throw new RuntimeException("Failed to load credentials: " + e.getMessage() + 
                    ". Please make sure your credentials.yml file is properly formatted.");
        }
    }

    /**
     * Main method for testing the client directly
     */
    public static void main(String[] args) {
        try {
            TwitApiClient client = new TwitApiClient();
            
            System.out.println("Testing connection to TWiT API...");
            
            // Test getting shows
            JSONObject result = client.getShows();
            
            if (result.has("error")) {
                System.out.println("Error: " + result.getString("error"));
            } else {
                System.out.println("Connection successful!");
                System.out.println("Found " + result.getInt("count") + " shows");
                
                if (result.has("shows")) {
                    System.out.println("\nFirst few shows:");
                    for (int i = 0; i < Math.min(3, result.getJSONArray("shows").length()); i++) {
                        JSONObject show = result.getJSONArray("shows").getJSONObject(i);
                        System.out.println("- " + show.getString("label") + " (" + show.getString("id") + ")");
                    }
                    
                    // Try to get a specific show (using the first show's ID if available)
                    String firstShowId = result.getJSONArray("shows").getJSONObject(0).getString("id");
                    System.out.println("\nGetting details for show ID: " + firstShowId);
                    
                    JSONObject showDetails = client.getShow(firstShowId);
                    if (!showDetails.has("error")) {
                        // For single show, the response has a 'shows' object, not an array
                        if (showDetails.has("shows")) {
                            JSONObject show = showDetails.getJSONObject("shows");
                            System.out.println("Show title: " + show.getString("label"));
                            if (show.has("description")) {
                                String description = show.getString("description");
                                System.out.println("Description: " + description.substring(0, Math.min(100, description.length())) + "...");
                            }
                        }
                    }
                }
                
                // Get streams information
                System.out.println("\nGetting live streams information...");
                JSONObject streams = client.getStreams();
                if (!streams.has("error") && streams.has("streams")) {
                    System.out.println("Found " + streams.getInt("count") + " streams");
                    for (int i = 0; i < Math.min(2, streams.getJSONArray("streams").length()); i++) {
                        JSONObject stream = streams.getJSONArray("streams").getJSONObject(i);
                        System.out.println("- " + stream.getString("label") + " (" + stream.getString("streamType") + ")");
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
