# Documentation Update Hook

A Git hook plugin for GitFlow that automatically manages API documentation and Postman collections based on your commits.

## Features

* Automatic API documentation updates
* Postman collection management
* Endpoint versioning
* Intelligent diff processing
* Multiple retry attempts for reliability
* Server health checks
* Proper error handling and logging

## Prerequisites

* Git >= 2.34.1
* Python >= 3.8.0
* curl >= 7.0.0
* Access to documentation update endpoint

## Installation

```bash
# Install the hook in your repository
gitflow --install-hook doc-update-hook

# Configure the hook
gitflow --config
```

## Configuration

The hook requires the following configuration:

```yaml
# Required Settings
endpoint_url: "https://your-doc-api.com/update"  # Documentation update endpoint
collections_dir: "postman_collections"            # Directory for Postman collections

# Optional Settings
timeout: 60          # API request timeout in seconds
retry_attempts: 3    # Number of retry attempts for failed requests
retry_delay: 2       # Delay between retries in seconds
```

## Directory Structure

```
repo/
├── .git/
│   └── hooks/
│       └── post-commit      # Installed hook script
└── postman_collections/    # Default collections directory
    ├── collection_metadata.json
    ├── repo_name_api_reference.json
    └── items/             # Individual endpoint files
        └── item_timestamp_endpoint_name.json
```

## How It Works

1. **Post-Commit Processing**:
   * Captures commit information
   * Analyzes changed files
   * Generates diff data
   * Extracts API endpoints

2. **Documentation Update**:
   * Normalizes endpoint URLs
   * Updates collection metadata
   * Manages individual endpoint files
   * Updates main collection

3. **API Integration**:
   * Checks server availability
   * Sends documentation payload
   * Handles retries on failure
   * Processes server response

## File Management

The hook manages several types of files:

1. **Main Collection**:
   * Central Postman collection file
   * Contains all endpoints
   * Updated on each commit

2. **Individual Items**:
   * Separate files for each endpoint
   * Timestamped and versioned
   * Easy to track changes

3. **Metadata**:
   * Tracks endpoint versions
   * Stores last update times
   * Maintains endpoint statistics

## URL Normalization

The hook normalizes URLs to ensure consistency:

```python
Input:  /api/v1/users/profile?id=123
Output: /users/profile

Input:  https://api.example.com/api/v1/users
Output: /users
```

## Error Handling

The hook handles various error scenarios:

1. **Configuration Errors**:
   * Missing required settings
   * Invalid configuration values
   * Missing dependencies

2. **Network Errors**:
   * Server unavailable
   * Request timeouts
   * Connection failures

3. **Processing Errors**:
   * Invalid JSON responses
   * File system errors
   * Git operation failures

## Logging

The hook provides detailed logging:

* ✅ Success messages in green
* ❌ Error messages in red
* ℹ️ Info messages in blue
* ⚠️ Warning messages in yellow

## Development

To modify or extend this hook:

1. Hook files are located in:
   ```
   doc-update-hook/
   ├── events/
   │   └── post-commit/
   │       └── script.sh
   ├── lib/
   │   ├── functions.sh
   │   ├── git_utils.sh
   │   └── postman_utils.py
   └── config/
       ├── defaults.yaml
       └── schema.json
   ```

2. Key files:
   * `functions.sh`: Core hook functions
   * `git_utils.sh`: Git operations
   * `postman_utils.py`: Documentation processing

## Troubleshooting

1. **Documentation Not Updating**
   * Check endpoint URL configuration
   * Verify server status
   * Check network connectivity
   * Review hook logs

2. **Missing Collections**
   * Verify collections directory exists
   * Check file permissions
   * Ensure hook is properly installed

3. **API Errors**
   * Check endpoint URL
   * Verify payload format
   * Review server response
   * Check retry settings

## Common Issues

1. **Hook Takes Too Long**
   * Adjust timeout settings
   * Check server response time
   * Optimize diff processing

2. **Missing Endpoints**
   * Check URL normalization
   * Review endpoint extraction
   * Verify file changes

3. **Duplicated Endpoints**
   * Check URL normalization
   * Review endpoint matching
   * Clear cached metadata

## License

MIT License

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request