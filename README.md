# Litespeed Graphdat Plugin

## Tracks the following metrics for the [litespeed](http://www.litespeedtech.com/) webserver

* Global Stats
  * LITESPEED_HTTP_BYTES_IN - HTTP Bytes In
  * LITESPEED_HTTP_BYTES_OUT - HTTP Bytes Out
  * LITESPEED_HTTPS_BYTES_IN - HTTPS Bytes In
  * LITESPEED_HTTPS_BYTES_OUT - HTTPS Bytes Out
  * LITESPEED_TOTAL_BYTES_IN - HTTP+HTTPS Bytes In
  * LITESPEED_TOTAL_BYTES_OUT - HTTP+HTTPS Bytes Out

  * LITESPEED_HTTP_CONNECTIONS - Current HTTP Connections
  * LITESPEED_HTTP_IDLE_CONNECTIONS - Current Idle HTTP Connections
  * LITESPEED_HTTP_CONNECTION_LIMIT -  HTTP Connections / Max HTTP Connections

  * LITESPEED_HTTPS_CONNECTIONS - Current HTTPS connections
  * LITESPEED_HTTPS_IDLE_CONNECTIONS - Current idle HTTPS connections
  * LITESPEED_HTTPS_CONNECTION_LIMIT - HTTPs Connections / Max HTTPs Connections

* Per VHOST stats
  * LITESPEED_CACHE_HITS - Number of Cache Hits
  * LITESPEED_CACHE_RATIO - Cached Hits / Total Requests
  * LITESPEED_REQUESTS - Requests per Second
  * LITESPEED_REQUESTS_IN_PROCESS - Current number of requests in process

## Pre Reqs

None.  Litespeed write the servers statistics to multiple report file in the /tmp/lshttpd folder.  The number of reports are based on the number of CPUs on your server and the number of CPUs that you have licences for.

### Installation & Configuration

* The Report Path is the location of the Litespeed real time reports.  By default these are in `/tmp/lshttpd`, if you have changed the path, put the new path.
* The Virutal Host list allow you to filter data and only return stats on the Virtual Hosts that you would like to see.  If the virtual host list is empty, the plugin will sum up all of the virtual hosts (using REQ_RATE []), if you add a filter to the list it will instead show stats for each Virtual Host individually.
