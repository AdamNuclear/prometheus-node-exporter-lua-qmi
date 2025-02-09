local io = require("io")
local json = require("dkjson")

local function scrape()
    local metric_modem_connected = metric("uqmi_modem_connected", "gauge")
    local metric_signal_rssi = metric("uqmi_signal_rssi", "gauge")
    local metric_signal_rsrq = metric("uqmi_signal_rsrq", "gauge")
    local metric_signal_rsrp = metric("uqmi_signal_rsrp", "gauge")
    local metric_signal_snr = metric("uqmi_signal_snr", "gauge")

    local function get_uqmi_signal_info()
        local handle = io.popen("uqmi -d /dev/cdc-wdm0 --get-signal-info 2>/dev/null")
        if not handle then return nil end
        local result = handle:read("*a")
        handle:close()
        if not result or result == "" then return nil end
        local signal_info, _, err = json.decode(result)
        if err then return nil end
        return signal_info
    end

    local function is_modem_connected()
        local handle = io.popen("uqmi -d /dev/cdc-wdm0 --get-data-status 2>/dev/null")
        if not handle then return false end
        local result = handle:read("*a"):gsub("\n", ""):lower()
        handle:close()
        return result == "connected"
    end

    local modem_connected = is_modem_connected() and 1 or 0
    metric_modem_connected({}, modem_connected)

    local signal_info = get_uqmi_signal_info()
    if signal_info then
        metric_signal_rssi({}, signal_info.rssi or 0)
        metric_signal_rsrq({}, signal_info.rsrq or 0)
        metric_signal_rsrp({}, signal_info.rsrp or 0)
        metric_signal_snr({}, signal_info.snr or 0)
    end
end

return { scrape = scrape }
