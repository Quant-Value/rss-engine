## `graber_cloud.sh` Description

This Bash script automates the download and processing of a file from S3, and then sends the processed data to a server via Docker. It also handles the creation of an index in Elasticsearch and manages errors with a backoff algorithm.This script is executed in SW_server

### Detailed Description

1.  **Configuration Variables:**
    * `bucket_url`: Defines the URL of the file in S3 to be downloaded.
    * `source .env`: Loads environment variables from a `.env` file, including `ES_PASSWORD`.
    * `archivo_comprimido`: Defines the name of the compressed file to be downloaded.
    * `ES_USERNAME`: Defines the username for Elasticsearch.
    * `INDEX_NAME`: Defines the name of the Elasticsearch index.
    * `SW_SERVER`: Defines the address of the SW_SERVER.

2.  **Elasticsearch Index Creation:**
    * Uses `curl` to send a PUT request to Elasticsearch and create an index named `feed-items-demo`.
    * Defines the index settings, including the number of shards and replicas, and the mapping of the `url` and `fecha` fields.

3.  **S3 File Download and Processing with Backoff:**
    * Implements a backoff algorithm to handle errors during file download and processing.
    * `max_attempts`: Defines the maximum number of attempts.
    * `attempt`: Attempt counter.
    * `backoff_time`: Initial wait time between attempts.
    * Uses a `while` loop to attempt download and processing up to the maximum number of attempts.
    * `aws s3 cp`: Downloads the file from S3.
    * `gunzip -c`: Uncompresses the file.
    * `xargs -I {} -P 20`: Executes commands in parallel using the uncompressed file content.
    * `docker exec -i myserver_add`: Executes a command inside a Docker container named `myserver_add`.
    * `./app-bluengo-worker add`: Executes the `app-bluengo-worker` script with the `add` command.
    * `-server http://${SW_SERVER}:8080`: Specifies the server address.
    * `-cmd "bash -c \"cd scripts && ./job.sh {}\""`: Executes the `job.sh` script with the arguments from the uncompressed file.
    * `-timeout 500`: Sets a timeout for the command.
    * If the download and processing are successful, it exits the loop.
    * If there's an error, it waits `backoff_time` seconds, doubles the wait time, and retries.
    * If the maximum number of attempts is reached, it displays an error message and exits the script.

4.  **Completion Message:**
    * Displays a message indicating that the process is completed.

The following scripts are executed in SW_workers

## `job.sh` Script Description

This Bash script is used to process URLs from WARC.WAT files, extracting RSS URLs and sending them to another script for further processing.

### Detailed Description

1.  **Argument Verification:**
    * Checks if a URL is provided as an argument (`$1`). If not, it displays an error message and exits the script with error code 1.

2.  **S3 URL Construction:**
    * Defines the base S3 URL as `s3://commoncrawl/`.
    * Concatenates the base URL with the provided argument (`$1`) to form the complete WARC.WAT file URL.

3.  **File Download and Processing:**
    * Displays a message indicating that the file is being downloaded and processed from the constructed URL.
    * Creates a temporary file (`archivo_temp`) using `mktemp`.
    * Downloads the file from S3 using `aws s3 cp`, decompresses it with `gunzip`, filters lines containing `"\{\"Container"` using `grep`, extracts RSS URLs using `jq`, and selects only URLs of type `application/rss+xml` using `grep` and `jq -r`.
    * Saves the extracted URLs in the temporary file `archivo_temp`.

4.  **JSON URL Generation:**
    * Reads the content of the temporary file `archivo_temp`, filters URLs containing "http\*" using `grep`, and uses `jq` to format them as a JSON object with the key `urls`.
    * Saves the resulting JSON in the `urls_json` variable.
    * (Commented out) Optionally, a similar JSON can be generated with the first 10 URLs and saved to `output.json`.

5.  **Temporary File Removal:**
    * Deletes the temporary file `archivo_temp`.

6.  **Processing Script Call:**
    * Creates a second temporary file (`archivo_temp2`) using `mktemp`.
    * Writes the URL JSON into `archivo_temp2`.
    * Executes the `process_rss_batch.sh` script, passing `archivo_temp2` as an argument.

7.  **Completion Message:**
    * Displays a message indicating that the process is completed.

## `metrics_rss.sh` Script Description

This Bash script is used to process and send metrics in JSON format to a specified URL. The metrics include information about URL processing and execution time.

### Detailed Description

1.  **Configuration Variables:**
    * `source .env`: Loads environment variables from a `.env` file, including `METRICS_URL`.

2.  **Argument Verification:**
    * Checks if an argument (the metrics JSON) is provided. If not, it displays an error message and exits the script with error code 1.

3.  **Extraction of Metrics from Input JSON:**
    * Uses `jq` to extract the values of `total_urls`, `failed_urls`, `successful_urls`, `total_items`, and `elapsed_time` from the JSON passed as an argument.

4.  **Timestamp Generation:**
    * Uses `date` to get the current timestamp in nanoseconds and stores it in the `timestamp` variable.

5.  **Definition of Base Metrics JSON Structure:**
    * Defines a JSON template (`JSON_TEMPLATE`) that contains the base structure for the metrics to be sent. This structure includes information about the service (`job-crawler`), the scope (`feed-processing`), and the specific metrics (total URLs, failed URLs, successful URLs, total items, and elapsed time).

6.  **Creation of JSON with Metrics and Dynamic Values:**
    * Uses `jq` to modify the JSON template with the values extracted from the input JSON and the current timestamp.
    * The `total_urls`, `failed_urls`, `successful_urls`, and `total_items` metrics are updated in the `sum.dataPoints` section.
    * The `elapsed_time` metric is updated in the `gauge.dataPoints` section.
    * The resulting JSON is stored in the `JSON` variable.

7.  **Saving Metrics to a JSON File:**
    * Writes the generated JSON to a file named `metrics_output.json`.

8.  **Sending Metrics to the URL:**
    * Uses `curl` to send a POST request to the URL specified in `METRICS_URL`, with the metrics JSON as data.
    * Sets the `Content-Type: application/json` header.
    * Displays a message indicating that the metrics have been sent.

## `process_rss_batch.sh` Script Description

This Bash script processes a batch of RSS feed URLs from a JSON file, extracts relevant information from each feed, sends it to Elasticsearch, and generates metrics about the processing.

### Detailed Description

1.  **Configuration Variables:**
    * `ES_USERNAME`: Defines the username for Elasticsearch.
    * `source .env`: Loads environment variables from a `.env` file, including `AWS_ELASTICSEARCH_ALB_DNS` and `ES_PASSWORD`.
    * `INDEX_DEST`: Defines the destination index name in Elasticsearch.

2.  **Argument Verification:**
    * Checks if an argument (the JSON file name) is provided. If not, it displays an error message and exits the script with error code 1.

3.  **Reading and Parsing the JSON File:**
    * Reads the content of the JSON file provided as an argument.
    * Uses `jq` to extract the URLs from the `urls` array and stores them in the Bash array `URLS`.

4.  **Metrics Initialization:**
    * Initializes metric variables: `total_urls`, `failed_urls`, `total_items`, `failed_processing`, `successful_urls`, and `start_time`.

5.  **URL Processing:**
    * Iterates over each URL in the `URLS` array.
    * Increments the `total_urls` counter.
    * Downloads the content of the RSS feed using `curl` and saves it to a temporary file (`temp_file`).
    * Checks if the temporary file contains data. If it's empty, increments `failed_urls`, deletes the temporary file, and skips to the next URL.
    * Uses `xq` and `jq` to extract relevant information from the RSS feed (feed source URL, feed type, item GUID, item title, item URL, item description) and formats it as a JSON object.
    * If the resulting JSON (`items_data`) is not empty, it sends it to Elasticsearch using `curl` and the `_bulk` endpoint.
    * Increments `successful_urls` and `total_items`.
    * If the JSON is empty, increments `failed_processing`.
    * Deletes the temporary file `temp_file`.

6.  **Execution Time Calculation:**
    * Calculates the execution time (`elapsed_time`) by subtracting `start_time` from `end_time`.

7.  **Metrics JSON Generation:**
    * Creates a JSON object with the calculated metrics.

8.  **Metrics Sending to `metrics_rss.sh`:**
    * Calls the `metrics_rss.sh` script, passing the metrics JSON as an argument.

9.  **Completion Message:**
    * Displays a message indicating that the process is completed.

10. **Input JSON File Removal:**
    * Deletes the input JSON file.

### Purpose

The main purpose of this script is to process a batch of RSS feed URLs, extract relevant information, send it to Elasticsearch, and generate metrics about the processing. This script is useful for automating the ingestion and analysis of RSS feed data.




