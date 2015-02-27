--
-- [boundary.com] Couchbase Lua Plugin
-- [author] Valeriu Paloş <me@vpalos.com>
--

--
-- Imports.
--
local fs    = require('fs')
local json  = require('json')
local http  = require('http')
local os    = require('os')
local path  = require('path')
local timer = require('timer')
local tools = require('tools')
local url   = require('url')

--
-- Initialize.
--
local _buckets      = {}
local _parameters   = json.parse(fs.readFileSync('param.json')) or {}

local _reportPath   = _parameters.reportPath or '/tmp/lshttpd'
local _virtualHosts = _parameters.virtualHosts or {}
local _pollInterval = tools.fence(tonumber(_parameters.pollInterval) or 5000, 100, 1000 * 60 * 60 * 24)

local _ignoredLines = { '^VERSION', '^UPTIME', '^BLOCKED_IP', '^EOF' }

--
-- Metrics source.
--
local _source =
  (type(_parameters.source) == 'string' and _parameters.source:gsub('%s+', '') ~= '' and _parameters.source) or
   os.hostname()

--
-- Scan paths.
--
local reports = {}
local file = path.join(_reportPath, '.rtreport')
if fs.existsSync(file) then
  table.insert(reports, file)
end
for i = 0, #os.cpus() do
  local file = path.join(_reportPath, '.rtreport' .. i)
  if fs.existsSync(file) then
    table.insert(reports, file)
  end
end

--
-- Scan virtual hosts.
--
local virtualHosts = {}
if #_parameters.virtualHosts == 0 then
  table.insert(_parameters.virtualHosts, '')
end
for _, item in ipairs(_parameters.virtualHosts) do
  if item then
    local vhost = item:match('^([^|]*)')
    local alias = item:match('|(.*)$')

    if virtualHosts[vhost] then
      error(("The virtual host '%s' is defined twice and hosts must be distinct!"):format(vhost))
    end

    virtualHosts[vhost] = _source .. '-' .. tools.trim(alias or vhost)
  end
end

--
-- Calculus utility functions.
--
function sum(a, b)
  return (a and b and math.max(a + b, 0)) or a or b
end
function delta(a, b)
  local na, nb = tonumber(a), tonumber(b)
  return (na and nb and math.max(na - nb, 0)) or 0
end
function parseFloat(x)
  return tonumber(x) or 0
end
function parseKeyValues(data)
  local result = {}
  for key, value in data:gmatch("([%w_]+):%s*(%d+)") do
    result[key:upper()] = parseFloat(value)
  end
  return result
end

--
-- Schedule poll.
--
function schedule()
  timer.setTimeout(_pollInterval, poll)
end

--
-- Print a metric.
--
function metric(stamp, id, value, source)
  print(string.format('%s %s %s %d', id, value, source or _source, stamp))
end

--
-- Parse a report file.
--
function parseReport(file, callback)

  -- Sample Report:
  --
  -- VERSION: LiteSpeed Web Server/Standard/4.2.21
  -- UPTIME: 02:38:00
  -- BPS_IN: 0, BPS_OUT: 0, SSL_BPS_IN: 0, SSL_BPS_OUT: 0
  -- MAXCONN: 150, MAXSSL_CONN: 150, PLAINCONN: 0, AVAILCONN: 150, IDLECONN: 0, SSLCONN: 0, AVAILSSL: 150
  -- REQ_RATE []: REQ_PROCESSING: 0, REQ_PER_SEC: 0.0, TOT_REQS: 0, CACHE_HITS_PER_SEC: 0.0, TOTAL_CACHE_HITS: 0
  -- REQ_RATE [Example]: REQ_PROCESSING: 0, REQ_PER_SEC: 0.0, TOT_REQS: 0, CACHE_HITS_PER_SEC: 0.0, TOTAL_CACHE_HITS: 0
  -- REQ_RATE [_AdminVHost]: REQ_PROCESSING: 0, REQ_PER_SEC: 0.0, TOT_REQS: 0, CACHE_HITS_PER_SEC: 0.0, TOTAL_CACHE_HITS: 0
  -- BLOCKED_IP:
  -- EOF
  --
  fs.readFile(file, function(failure, data)

    -- Safety check.
    if failure or not data then
      print("ERROR: " .. failure)
      return callback({})
    end

    -- Walk through lines.
    local results = { ['virtualHosts'] = {} }
    for line in tools.lines(data) do

      -- Catch ignored lines.
      local valid = true
      for _, ignored in ipairs(_ignoredLines) do
        if line:find(ignored) then
          valid = false
          break
        end
      end

      -- Parse valid lines.
      if valid then
        local sink = results
        local data = line

        -- General metrics or virtual-host specifc?
        local vhost, metrics = line:match('^REQ_RATE %[(.-)%]:(.*)')
        if vhost then
          data = ''

          if virtualHosts[vhost] then
            results.virtualHosts[vhost] = results.virtualHosts[vhost] or {}
            sink = results.virtualHosts[vhost]
            data = metrics
          end
        end

        -- Parse metrics.
        for key, value in pairs(parseKeyValues(data)) do
          sink[key] = (sink[key] or 0) + value
        end
      end

    end

    callback(results)
  end)
end

--
-- Collect and aggregate reports.
--
function collectReports(callback)
  local sets = {}
  local remaining = #reports

  -- Add results to the stack.
  function aggregate(values)
    table.insert(sets, values)
    if remaining == 0 then

      -- Aggregate if all reports are parsed.
      local store = { ['virtualHosts'] = {} }
      for _, metrics in ipairs(sets) do

        -- Walk generic values.
        for name, value in pairs(metrics) do
          if name ~= 'virtualHosts' then
            store[name] = (store[name] or 0) + value
          end
        end

        -- Walk virtual-host-specific values.
        for vhost, vhMetrics in pairs(metrics.virtualHosts) do
          store.virtualHosts[vhost] = store.virtualHosts[vhost] or {}
          for name, value in pairs(vhMetrics) do
            store.virtualHosts[vhost][name] = (store.virtualHosts[vhost][name] or 0) + value
          end
        end

      end

      callback(store)
    end
  end

  -- Trigger asynchronous parsing of report files.
  for _, report in ipairs(reports) do
    parseReport(report, function(values)
      remaining = remaining - 1
      aggregate(values)
    end)
  end

end

--
-- Produce metrics.
--
function poll()
  local stamp = os.time()

  -- Trigger one collection.
  collectReports(function(metrics)
    local httpConnLimit  = (metrics.MAXCONN     == 0 and 0) or (metrics.PLAINCONN / metrics.MAXCONN)
    local httpsConnLimit = (metrics.MAXSSL_CONN == 0 and 0) or (metrics.SSLCONN   / metrics.MAXSSL_CONN)

    metrics.BPS_IN      = metrics.BPS_IN      * 1024;
    metrics.BPS_OUT     = metrics.BPS_OUT     * 1024;
    metrics.SSL_BPS_IN  = metrics.SSL_BPS_IN  * 1024;
    metrics.SSL_BPS_OUT = metrics.SSL_BPS_OUT * 1024;

    -- Generic metrics.
    metric(stamp, 'LITESPEED_HTTP_CONNECTION_LIMIT',  httpConnLimit)
    metric(stamp, 'LITESPEED_HTTP_CONNECTIONS',       metrics.PLAINCONN)
    metric(stamp, 'LITESPEED_HTTP_IDLE_CONNECTIONS',  metrics.IDLECONN)
    metric(stamp, 'LITESPEED_HTTPS_CONNECTION_LIMIT', httpsConnLimit)
    metric(stamp, 'LITESPEED_HTTPS_CONNECTIONS',      metrics.SSLCONN)
    metric(stamp, 'LITESPEED_HTTPS_IDLE_CONNECTIONS', delta(metrics.AVAILSSL, metrics.SSLCONN))
    metric(stamp, 'LITESPEED_HTTP_BYTES_IN',          metrics.BPS_IN)
    metric(stamp, 'LITESPEED_HTTP_BYTES_OUT',         metrics.BPS_OUT)
    metric(stamp, 'LITESPEED_HTTPS_BYTES_IN',         metrics.SSL_BPS_IN)
    metric(stamp, 'LITESPEED_HTTPS_BYTES_OUT',        metrics.SSL_BPS_OUT)
    metric(stamp, 'LITESPEED_TOTAL_BYTES_IN',         sum(metrics.BPS_IN, metrics.SSL_BPS_IN))
    metric(stamp, 'LITESPEED_TOTAL_BYTES_OUT',        sum(metrics.BPS_OUT, metrics.SSL_BPS_OUT))

    -- Virtual-host specific metrics.
    for vhost, vhMetrics in pairs(metrics.virtualHosts) do
      local virtualHost = metrics.virtualHosts[vhost];
      local virtualName = virtualHosts[vhost];

      local cacheHits         = virtualHost.CACHE_HITS_PER_SEC or 0;
      local requests          = virtualHost.REQ_PER_SEC;
      local requestsInProcess = virtualHost.REQ_PROCESSING or 0;
      local cacheRatio        = (requests == 0 and 0) or (cacheHits / requests);

      metric(stamp, 'LITESPEED_CACHE_HITS',           cacheHits,          virtualName)
      metric(stamp, 'LITESPEED_CACHE_RATIO',          cacheRatio,         virtualName)
      metric(stamp, 'LITESPEED_REQUESTS',             requests,           virtualName)
      metric(stamp, 'LITESPEED_REQUESTS_IN_PROCESS',  requestsInProcess,  virtualName)
    end

    -- Reschedule.
    schedule()
  end)
end

-- Trigger polling.
poll()