-- LocationAwareMute Spoon v0.93 (Corrected Caffeinate Watcher)
local obj = {
    name = "LocationAwareMute",
    version = "0.93",
    author = "Thiago MadPin",
    license = "MIT",
    config = {
        homeLocation = {
            latitude = 53.3433,
            longitude = -6.2761
        },
        distanceThreshold = 100, -- meters
        restoreState = true,
        homeSSIDs = {"^MadFi", "MadFi%-5G"}, -- Regex patterns
        homeIPSubnets = {"^192%.168%.1%."}, -- Regex patterns
        debugHotkeys = {"ctrl", "cmd", "shift"}
    }
}
obj.__index = obj

-- Initialize logger
local logger = hs.logger.new('LocationAw', 'debug')

-- Internal state
local audioDevice = nil
local originalMuteState = false
local isAtHome = false
local caffeinateWatcher = nil
local locationManager = nil
local locationServicesAvailable = false

--[[ Enhanced Network Helpers ]] --
local function tableContainsPattern(tbl, item)
    if not item then
        return false
    end
    for _, pattern in pairs(tbl) do
        if item:match(pattern) then
            return true
        end
    end
    return false
end

local function getEthernetIPs()
    local ethernetIPs = {}
    local interfaces = hs.network.interfaceDetails()
    for _, interface in pairs(interfaces) do
        if interface.interface and interface.interface:match("^en") then
            local ips = {}
            if interface.IPv4 and interface.IPv4.addresses then
                ips = interface.IPv4.addresses
            end
            if #ips > 0 then
                table.insert(ethernetIPs, {
                    interface = interface.interface,
                    ips = ips
                })
            end
        end
    end
    return ethernetIPs
end

local function isHomeEthernet()
    local ethernetIPs = getEthernetIPs()
    for _, eth in ipairs(ethernetIPs) do
        for _, ip in ipairs(eth.ips) do
            if tableContainsPattern(obj.config.homeIPSubnets, ip) then
                logger.d("Home Ethernet detected on %s: %s", eth.interface, ip)
                return true
            end
        end
    end
    return false
end

--[[ Location Check and Mute Logic ]] --

-- Callback needs *three* arguments
function obj:handleLocationResult(ok, lat, lon)
    if ok and lat and lon then
        logger.i("GPS Location: lat %.4f, lon %.4f", lat, lon)
        self:processLocation({
            latitude = lat,
            longitude = lon
        })
    else
        logger.w("Falling back to network detection")
        self:networkFallback() -- Use named fallback function
    end
end

function obj:networkFallback()
    local ssid = hs.wifi.currentNetwork()
    local ethernetIPs = getEthernetIPs()

    logger.df("Network State:\n" .. "  WiFi SSID: %s\n" .. "  Ethernet IPs: %d active", ssid or "nil", #getEthernetIPs())

    local homeViaWiFi = ssid and tableContainsPattern(self.config.homeSSIDs, ssid)
    local homeViaEthernet = isHomeEthernet()

    if homeViaWiFi or homeViaEthernet then
        local detectedVia = homeViaWiFi and "WiFi" or "Ethernet"
        logger.i("Home detected via %s", detectedVia)
        hs.alert.show("Home via " .. detectedVia .. (homeViaWiFi and ": " .. ssid or ""))
        self:processLocation(self.config.homeLocation) -- Treat network as home location
    else
        logger.w("No home network detected")
        self:processLocation(nil)
    end
end

function obj:checkLocation()
    logger.d("Starting location check")
    
    if locationServicesAvailable and locationManager then
        logger.d("Requesting location update")
        -- Try to get location, but with error handling
        local success, err = pcall(function()
            locationManager:getLocation(10, function(ok, lat, lon)
                self:handleLocationResult(ok, lat, lon)
            end)
        end)
        
        if not success then
            logger.e("Error getting location: " .. tostring(err))
            self:networkFallback() -- Fall back to network detection
        end
    else
        logger.w("Location services not available, using network fallback")
        self:networkFallback() -- Directly use network fallback
    end
end

function obj:processLocation(location)
    local newIsAtHome = false

    if location then
        -- Only calculate distance if location services are available
        if hs.location.servicesEnabled() then
            local distance = hs.location.distance(location, self.config.homeLocation)
            newIsAtHome = (distance <= self.config.distanceThreshold)
            logger.d("Distance from home: %.2f meters", distance)
        else
            -- If we have a location but services aren't enabled, we're using network detection
            -- which already determined we're at home
            newIsAtHome = true
        end
    end

    if newIsAtHome ~= isAtHome then
        isAtHome = newIsAtHome
        logger.i("Home status changed: %s", isAtHome and "HOME" or "AWAY")

        if not audioDevice then
            logger.e("Audio device not available!")
            return
        end

        if isAtHome then
            if self.config.restoreState then
                originalMuteState = audioDevice:muted()
            end
            audioDevice:setMuted(false)
            hs.alert.show("At Home - Mic Unmuted")
        else
            audioDevice:setMuted(true)
            hs.alert.show("Away - Mic Muted")
            if self.config.restoreState then
                hs.timer.doAfter(5, function()
                    if audioDevice then -- added check device
                        audioDevice:setMuted(originalMuteState)
                    end
                end)
            end
        end
    end
end

function obj:checkAndSetMuteState()
    self:checkLocation() -- Simplified call
end

--[[ Enhanced Debug Hotkeys ]] --

function obj:initDebugHotkeys()
    logger.i("Initializing debug hotkeys")
    local mods = self.config.debugHotkeys

    hs.hotkey.bind(mods, "L", function()
        logger.d("Location check hotkey pressed")
        self:checkAndSetMuteState()
    end)

    hs.hotkey.bind(mods, "W", function()
        logger.d("Network status hotkey pressed")
        local ssid = hs.wifi.currentNetwork()
        local ethernetIPs = getEthernetIPs()

        local networkInfo = {"WiFi: " .. (ssid or "Not connected"), "Ethernet:"}

        if #ethernetIPs > 0 then
            for _, eth in ipairs(ethernetIPs) do
                table.insert(networkInfo, string.format("  %s: %s", eth.interface, table.concat(eth.ips, ", ")))
            end
        else
            table.insert(networkInfo, "  No active connections")
        end

        hs.alert.show(table.concat(networkInfo, "\n"))
        logger.i("Network Status:\n" .. table.concat(networkInfo, "\n"))
    end)

    hs.hotkey.bind(mods, "M", function()
        logger.d("Toggle Mute hotkey pressed")
        if not audioDevice then
            hs.alert.show("No audio device available")
            return
        end
        local currentMute = audioDevice:muted()
        audioDevice:setMuted(not currentMute)
        hs.alert.show("Mic Muted: " .. tostring(not currentMute))
    end)
end

--[[ Spoon Lifecycle Methods ]] --

function obj:start()
    logger.i("Starting LocationAwareMute")

    -- Initialize audio device
    audioDevice = hs.audiodevice.defaultOutputDevice()
    if not audioDevice then
        logger.e("No audio output device found!")
        return
    end

    -- Initialize location manager with proper error handling
    locationServicesAvailable = false
    
    -- Check if location services are available system-wide
    if hs.location.servicesEnabled() then
        logger.d("Location services are enabled")
        
        -- Try to create the location manager
        local success, result = pcall(function() 
            return hs.location.new()
        end)
        
        if success and result then
            locationManager = result
            
            -- Try to start the location manager
            local startSuccess, startErr = pcall(function() 
                locationManager:start()
            end)
            
            if startSuccess then
                logger.i("Location manager initialized and started successfully")
                locationServicesAvailable = true
            else
                logger.e("Failed to start location manager: " .. tostring(startErr))
            end
        else
            logger.e("Could not create location manager: " .. tostring(result))
        end
    else
        logger.w("Location services are disabled system-wide")
    end
    
    -- Set up caffeinate watcher for wake events
    caffeinateWatcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            logger.i("System woke from sleep, checking location")
            self:checkAndSetMuteState()
        end
    end)

    if caffeinateWatcher then
        caffeinateWatcher:start()
    else
        logger.e("Could not create caffeinate watcher!")
    end

    -- Initial state check
    self:checkAndSetMuteState()

    -- Initialize debug hotkeys if configured
    if self.config.debugHotkeys and #self.config.debugHotkeys > 0 then
        self:initDebugHotkeys()
    end
end

function obj:stop()
    logger.i("Stopping LocationAwareMute")
    
    if caffeinateWatcher then
        caffeinateWatcher:stop()
        caffeinateWatcher = nil
    end
    
    if locationManager and locationServicesAvailable then
        -- Safely stop the location manager
        local success, err = pcall(function() 
            locationManager:stop() 
        end)
        
        if not success then
            logger.e("Error stopping location manager: " .. tostring(err))
        end
    end
    
    locationManager = nil
    locationServicesAvailable = false
end

return obj