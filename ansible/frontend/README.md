### `Dockerfile`

This Dockerfile is used to build a Docker image for the frontend application. It sets up a PHP environment with Apache and configures the application using environment variables.

-   **Base Image:** `php:8.4-apache` is used as the base image, providing a PHP 8.4 environment with Apache.
-   **Environment Configuration:** The `APP_CONFIG` environment variable is set to a JSON string that configures the application's connection to Elasticsearch, the index to use, the fields to display, and the default sorting field. This configuration is then written to Apache's environment configuration.
-   **Application Files:** The contents of the `./public-html/` directory (which should contain `index.php`) are copied into the `/var/www/html/` directory, which is the document root for Apache.

### `Index.php`

# index.php Description

This PHP file serves as a frontend application that interacts with Elasticsearch to display search results. It provides a user interface with search functionality, sorting options, and pagination.

## Key Features

-   **HTML Structure:**
    -   Uses Bootstrap 5 for styling to create a responsive and visually appealing layout.
    -   Includes a search input field, sort order selection, a search button, a results table, and pagination controls.
    -   Applies a dark theme for better user experience.
-   **JavaScript Functionality:**
    -   Dynamically builds the table header based on predefined fields.
    -   Performs search queries against Elasticsearch using the Fetch API.
    -   Renders search results in the table, handling cases with no results.
    -   Implements pagination controls to navigate through search results.
    -   Updates pagination controls based on the current page and total hits.
    -   Handles user interactions through event listeners for the search button and pagination controls.
-   **Dynamic Configuration:**
    -   Retrieves configuration settings from the `APP_CONFIG` environment variable using `$_SERVER['APP_CONFIG']`.
    -   Passes the configuration as a JSON object to the JavaScript code, allowing for dynamic adjustments of Elasticsearch connection details, index name, predefined fields, default sorting, and results per page.
    -   The PHP code uses `json_encode(json_decode($_SERVER['APP_CONFIG'], true))` to correctly parse JSON from the environment variable into javascript.
-   **Elasticsearch Integration:**
    -   Connects to Elasticsearch using the URL specified in the configuration.
    -   Executes search queries with optional search text, sort order, and pagination parameters.
    -   Displays search results in a table format.

## Configuration

The application's behavior is controlled by a JavaScript `config` object, which is populated with data from the `APP_CONFIG` environment variable. This object defines:

-   `esUrl`: The Elasticsearch endpoint URL.
-   `index`: The Elasticsearch index to query.
-   `predefinedFields`: An array of fields to search and display.
-   `defaultSortField`: The field used for sorting.
-   `resultsPerPage`: The number of results displayed per page.

## Usage

This file should be served by a PHP-enabled web server. The `APP_CONFIG` environment variable needs to be set with the appropriate Elasticsearch configuration. The JavaScript code will then dynamically fetch and display search results from Elasticsearch based on user input.