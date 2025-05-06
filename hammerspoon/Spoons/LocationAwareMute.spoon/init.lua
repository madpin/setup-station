--[[
  Revised LocationAwareMute Spoon – Mute Both Mic and Audio Output

  This version listens to a comprehensive set of hs.caffeinate.watcher events so
  that whether you lock your screen, start the screensaver, or the system sleeps,
  your microphone and speakers get muted when you’re at home (via Wi‑Fi check).
  
  For the output device, if setMuted(true) doesn’t seem to work (as can happen with
  some built‑in speakers), the code will fall back to setting the volume to 0.
  On wake/unlock the previous states (or volumes) are restored if restoreState is true.

  Adjust LocationAwareMute.config.homeSSIDs to match your home Wi‑Fi patterns.
--]]
hs.alert.show("init.lua loaded!")

local LocationAwareMute = {}
LocationAwareMute.__index = LocationAwareMute

LocationAwareMute.config = {
  homeSSIDs       = { "^MadFi", "MadFi%-5G" },  -- Update these to match your home network(s).
  restoreState    = true,                      -- Restore original states on wake/unlock.
  debugHotkey     = { "ctrl", "cmd", "shift" },
  debugHotkeyKey  = "M",
}

local logger = hs.logger.new("LocationAwareMute", "debug")
logger.setLogLevel("debug")

local inputDevice = nil           -- For the microphone.
local outputDevice = nil          -- For the speakers.
local originalInputMuteState = false
local originalOutputMuteState = false
local originalOutputVolume = nil  -- For fallback method.
local outputMutedUsingVolume = false

local isAtHome = false
local caffeinateWatcher = nil

-- Helper: Check if 'item' matches any pattern in table 'tbl'.
local function tableContainsPattern(tbl, item)
  logger.d("tableContainsPattern called with table: %s, item: %s", hs.inspect(tbl), item or "nil")
  if not item then return false end
  for _, pattern in pairs(tbl) do
    logger.d("Checking pattern '%s' against item '%s'", pattern, item)
    if item:match(pattern) then
      logger.d("Match found for pattern '%s'", pattern)
      return true
    end
  end
  return false
end

-- Check if we're connected to one of our home Wi‑Fi networks.
local function isHomeWifi()
  local currentSSID = hs.wifi.currentNetwork()
  logger.d("isHomeWifi: current SSID: %s", currentSSID or "nil")
  if currentSSID and tableContainsPattern(LocationAwareMute.config.homeSSIDs, currentSSID) then
    logger.i("Connected to home Wi‑Fi: %s", currentSSID)
    return true
  else
    logger.d("Not connected to home Wi‑Fi")
    return false
  end
end

-- Update the mute/volume states for both input and output devices.
local function updateMuteStateOnSleepWake(isWake)
  logger.d("updateMuteStateOnSleepWake called, isWake: %s", tostring(isWake))
  
  if not inputDevice or not outputDevice then
    logger.e("Audio devices not available!")
    return
  end

  isAtHome = isHomeWifi()
  logger.d("isAtHome: %s", tostring(isAtHome))

  if not isWake then
    -- Lock/sleep: If at home, store the original states and then mute.
    if isAtHome then
      originalInputMuteState  = inputDevice:inputMuted()
      originalOutputMuteState = outputDevice:muted()
      originalOutputVolume    = outputDevice:volume()
      logger.d("Lock/Sleep: Original input mute: %s, output mute: %s, output volume: %s",
               tostring(originalInputMuteState),
               tostring(originalOutputMuteState),
               tostring(originalOutputVolume))

      -- Mute the microphone.
      inputDevice:setInputMuted(true)
      -- Attempt to mute the speakers.
      outputDevice:setMuted(true)
      -- Use a short delay to check if the output device actually reports muted.
      hs.timer.doAfter(0.2, function()
        if not outputDevice:muted() then
          logger.d("Output device did not mute via setMuted; falling back to setting volume to 0")
          outputMutedUsingVolume = true
          outputDevice:setVolume(0)
        else
          outputMutedUsingVolume = false
        end
        logger.i("Lock/Sleep: Mic muted = %s, Output muted = %s, volume = %s",
                 tostring(inputDevice:inputMuted()),
                 tostring(outputDevice:muted()),
                 tostring(outputDevice:volume()))
        hs.alert.show("At Home & Locked/Sleeping – Mic & Audio Out Muted")
      end)
    else
      logger.d("Lock/Sleep: Not at home. No mute action taken.")
      hs.alert.show("Away & Locked/Sleeping – No Change")
    end
  else
    -- Wake/unlock: Restore states if configured and if at home.
    logger.d("Waking/Unlocking")
    if LocationAwareMute.config.restoreState and isAtHome then
      logger.d("Restoring original states: input mute: %s, output mute: %s, volume: %s",
               tostring(originalInputMuteState),
               tostring(originalOutputMuteState),
               tostring(originalOutputVolume))
      inputDevice:setInputMuted(originalInputMuteState)
      if outputMutedUsingVolume then
        outputDevice:setVolume(originalOutputVolume or 50)
      else
        outputDevice:setMuted(originalOutputMuteState)
      end
      hs.alert.show("Home & Awake/Unlocked – Mic & Audio Out Restored (" ..
        (originalInputMuteState and "Muted" or "Unmuted") .. ", " ..
        (originalOutputMuteState and "Muted" or "Unmuted") .. ")")
      logger.i("Audio states restored")
    else
      -- If not restoring, explicitly unmute.
      inputDevice:setInputMuted(false)
      if outputMutedUsingVolume then
        outputDevice:setVolume(originalOutputVolume or 50)
      else
        outputDevice:setMuted(false)
      end
      logger.i("Mic & Audio output unmuted")
      hs.alert.show("Awake/Unlocked – Mic & Audio Out Unmuted")
    end
  end
end

-- Comprehensive handler for caffeinate events.
local function handleCaffeinateEvent(event)
  logger.d("Caffeinate watcher event: %s", event)
  if event == hs.caffeinate.watcher.systemWillSleep or
     event == hs.caffeinate.watcher.screensDidSleep   or
     event == hs.caffeinate.watcher.screensaverDidStart or
     event == hs.caffeinate.watcher.sessionDidResignActive then
    logger.i("Detected lock/sleep event")
    updateMuteStateOnSleepWake(false)
  elseif event == hs.caffeinate.watcher.systemDidWake    or
         event == hs.caffeinate.watcher.screensDidWake    or
         event == hs.caffeinate.watcher.screensaverDidStop  or
         event == hs.caffeinate.watcher.sessionDidBecomeActive then
    logger.i("Detected wake/unlock event")
    updateMuteStateOnSleepWake(true)
  end
end

function LocationAwareMute:start()
  logger.i("Starting LocationAwareMute spoon (muting both mic and audio output)")

  inputDevice  = hs.audiodevice.defaultInputDevice()
  outputDevice = hs.audiodevice.defaultOutputDevice()

  if not inputDevice or not outputDevice then
    logger.e("Could not find default audio devices!")
    return
  end

  logger.d("Input Device: %s, UID: %s", inputDevice:name(), inputDevice:uid())
  logger.d("Output Device: %s, UID: %s", outputDevice:name(), outputDevice:uid())
  hs.alert.show("Audio Devices: " .. inputDevice:name() .. " & " .. outputDevice:name())

  -- Start the caffeinate watcher with our comprehensive event handler.
  caffeinateWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
  local success, err = pcall(function() caffeinateWatcher:start() end)
  if success then
    logger.i("Caffeinate watcher started successfully")
  else
    logger.e("Failed to start caffeinate watcher: %s", err)
  end

  -- Debug hotkey—toggle both mute states manually.
  if LocationAwareMute.config.debugHotkey and #LocationAwareMute.config.debugHotkey > 0 then
    hs.hotkey.bind(LocationAwareMute.config.debugHotkey, LocationAwareMute.config.debugHotkeyKey, function()
      if not inputDevice or not outputDevice then
        logger.w("No audio devices available for hotkey")
        hs.alert.show("No audio devices")
        return
      end
      local currentInputMute  = inputDevice:inputMuted()
      local currentOutputMute = outputDevice:muted()
      inputDevice:setInputMuted(not currentInputMute)
      outputDevice:setMuted(not currentOutputMute)
      hs.alert.show("Debug: Mic Muted: " .. tostring(not currentInputMute) ..
                   ", Audio Out Muted: " .. tostring(not currentOutputMute))
      logger.i("Debug hotkey toggled: Mic is now %s, Output is now %s",
               tostring(inputDevice:inputMuted()), tostring(outputDevice:muted()))
    end)
  end

  -- Initial state assumes the system is awake/unlocked.
  updateMuteStateOnSleepWake(true)
end

function LocationAwareMute:stop()
  logger.i("Stopping LocationAwareMute spoon")
  if caffeinateWatcher then
    caffeinateWatcher:stop()
    caffeinateWatcher = nil
  end
end

return LocationAwareMute