# Boundary Litespeed Plugin

Collects metrics from LiteSpeed HTTP Web-Server.

## Prerequisites

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |    -    |    v    |  v   |

- **OS**: Tested to work on **Debian-based Linux distributions** (although any Linux-based OS should work).
- Requires access to "/tmp/lshttpd" (LiteSpeed real-time reporting folder).

### **Meter V4.0 or greater**

To get the new meter:

    curl -fsS \
        -d "{\"token\":\"<your API token here>\"}" \
        -H "Content-Type: application/json" \
        "https://meter.boundary.com/setup_meter" > setup_meter.sh
    chmod +x setup_meter.sh
    ./setup_meter.sh

| Runtime  | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |         |        |      |

### Meter less than V4.0

| Runtime  | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |    v    |        |      |

- [How to install node.js?](https://help.boundary.com/hc/articles/202360701)

## Plugin Setup
None required.

### Plugin Configuration Fields
Litespeed writes server statistics to multiple report files in the /tmp/lshttpd folder by default, check your configuration to ensure that the path is correct.  The number of reports are based on the number of CPUs on your server and the number of CPUs that you have licences for.

|Field Name     |Identifier   |Type          |Description                                                                       |
|:--------------|:------------|--------------|:---------------------------------------------------------------------------------|
|Report Path    |reportPath   |string        |The path to the LiteSpeed '.rtreport' file(s) to watch (default: '/tmp/lshttpd'). |
|Virtual Hosts  |virtualHosts |array[string] |Include individual VHosts in your graphs.                                         |
|Poll Interval  |pollInterval |integer       |How often (in milliseconds) to poll the metrics file(s) (default: 5000).          |

### Metrics Collected
Tracks the following metrics for the [LiteSpeed](http://www.litespeedtech.com/) HTTP Web-Server.

|Metric Name                      |Description                                   |
|:--------------------------------|:---------------------------------------------|
|Litespeed HTTP Connection limit  |The ratio of connections to the Max Limit.    |
|Litespeed Http Conns             |The number of current HTTP connections.       |
|Litespeed Idle Http Conns        |The number of current idle HTTP connections.  |
|Litespeed HTTPS Connection limit |The ratio of connections to the Max Limit.    |
|Litespeed Https Conns            |The number of current HTTPS connections.      |
|Litespeed Idle Https Conns       |The number of current idle HTTPS connections. |
|Litespeed Http Bytes In          |The amount of inbound data over HTTP.         |
|Litespeed Http Bytes Out         |The amount of outbound data over HTTP.        |
|Litespeed Https Bytes In         |The amount of inbound data over HTTPS.        |
|Litespeed Https Bytes Out        |The amount of outbound data over HTTPS.       |
|Litespeed Total Bytes In         |The total amount of inbound data.             |
|Litespeed Total Bytes Out        |The total amount of outbound data.            |
|Litespeed Cache Hits             |The number of cache hits.                     |
|Litespeed Cache Hit Ratio        |The ratio of cache hits to overall requests.  |
|Litespeed Requests in Process    |The number of requests in process.            |
|Litespeed Requests               |The number of requests.                       |
