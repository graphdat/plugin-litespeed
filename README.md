Boundary Litespeed Plugin
-------------------------

Collects metrics from Litespeed HTTP Server instance.

### Platforms
- Linux
- OS X
- SmartO

### Prerequisites
- node version 0.8.0 or later
- npm version 1.4.21 or later

### Plugin Setup
None

### Plugin Configuration Fields

Litespeed writes server statistics to multiple report files in the /tmp/lshttpd folder by default, check your configuration to ensure that the path is correct.  The number of reports are based on the number of CPUs on your server and the number of CPUs that you have licences for.

|Field Name   |Description                             |
|:------------|:---------------------------------------|
|Report path  |The path to the lshttp .rtreport files  |
|Virtual Hosts|Include individual VHosts in your graphs|


### Metrics Collected

Tracks the following metrics for the [litespeed](http://www.litespeedtech.com/) webserver.

|Metric Name                     |Description                                 |
|:-------------------------------|:-------------------------------------------|
|Litespeed HTTP Connection limit |The ratio of connections to the Max Limit   |
|Litespeed Http Conns            |The number of current HTTP connections      |
|Litespeed Idle Http Conns       |The number of current idle HTTP connections |
|Litespeed HTTPS Connection limit|The ratio of connections to the Max Limit   |
|Litespeed Https Conns           |The number of current HTTPS connections     |
|Litespeed Idle Https Conns      |The number of current idle HTTPS connections|
|Litespeed Http Bytes In         |The amount of inbound data over HTTP        |
|Litespeed Http Bytes Out        |The amount of outbound data over HTTP       |
|Litespeed Https Bytes In        |The amount of inbound data over HTTPS       |
|Litespeed Https Bytes Out       |The amount of outbound data over HTTPS      |
|Litespeed Total Bytes In        |The total amount of inbound data            |
|Litespeed Total Bytes Out       |The total amount of outbound data           |
|Litespeed Cache Hits            |The number of cache hits                    |
|Litespeed Cache Hit Ratio       |The ratio of cache hits to overall requests |
|Litespeed Requests in Process   |The number of requests in process           |
|Litespeed Requests              |The number of requests                      |

