-- local beta = require("scripts.beta")
-- beta.setupHotkeys()

-- local hotkey = require("hs.hotkey")
-- local caffeinate = require("hs.caffeinate")
-- local alert = require("hs.alert")
-- local osascript = require("hs.osascript")
-- local eventtap = require("hs.eventtap")

-- -- Window management remains the same
-- hotkey.bind({'alt', 'ctrl', 'cmd'}, 'n', function()
--     local win = hs.window.focusedWindow()
--     local screen = win:screen()
--     win:move(win:frame():toUnitRect(screen:frame()), screen:next(), true, 0)
-- end)
-- hotkey.bind({'alt', 'ctrl', 'cmd'}, 't', function()
--     print("test working")
--     local event = eventtap.event
--     event.newSystemKeyEvent("PLAY", true):post()
--     event.newSystemKeyEvent("PLAY", false):post()
-- end)

-- -- Media state tracker (like Zunes' pause in Guardians of the Galaxy)
-- local mediaWasPlaying = false

-- -- Universal play/pause toggle (works across apps like The Matrix works across realities)
-- local function toggleMediaPlayback()
--     local event = eventtap.event
--     event.newSystemKeyEvent("PLAY", true):post()
--     event.newSystemKeyEvent("PLAY", false):post()
-- end

-- -- Media detection script (our own Sherlock Holmes for audio)
-- local function checkMediaPlaying()
--     local script = [[
--     -- Bulletproof media detection (K.I.S.S principle)
--     on isMediaPlaying()
--         tell application "System Events"
--             -- Check native apps first (Obi-Wan's priority)
--             repeat with appName in {"Music", "Spotify", "VLC"}
--                 if exists process appName then
--                     tell process appName
--                         if appName is "VLC" and playing then return true
--                         if player state is playing then return true
--                     end tell
--                 end if
--             end repeat
            
--             -- Browser detection (Like Starlord's mixtape)
--             set browserMediaStates to {¬
--                 {app:"Safari", title:{"YouTube", "▶", "▎▎"}}, ¬
--                 {app:"Google Chrome", title:{"Netflix", "Pause"}}, ¬
--                 {app:"Microsoft Edge", title:{"Prime Video", "⏸"}}, ¬
--                 {app:"Arc", title:{"Disney+", "Playing"}} ¬
--             }
            
--             repeat with browser in browserMediaStates
--                 if exists process (app of browser) then
--                     tell process (app of browser)
--                         repeat with w in windows
--                             repeat with t in tabs of w
--                                 set tabTitle to (title of t) as text
--                                 repeat with kw in (title of browser)
--                                     if tabTitle contains kw then return true
--                                 end repeat
--                             end repeat
--                         end repeat
--                     end tell
--                 end if
--             end repeat
--         end tell
--         return false
--     end on
    
--     isMediaPlaying()
--     ]]

--     local ok, result = osascript.applescript(script)
--     return ok and result
-- end

-- -- Enhanced caffeinate watcher (now with 100% more media control)
-- local function caffeinateCallback(eventType)
--     if eventType == caffeinate.watcher.screensDidLock then
--         mediaWasPlaying = checkMediaPlaying()
--         if mediaWasPlaying then
--             toggleMediaPlayback()
--             alert.show("⏸️ Media Paused", 1)
--         end
--     elseif eventType == caffeinate.watcher.screensDidUnlock then
--         if mediaWasPlaying then
--             toggleMediaPlayback()
--             alert.show("▶️ Media Resumed", 1)
--             mediaWasPlaying = false
--         end
--     end
-- end

-- local caffeinateWatcher = caffeinate.watcher.new(caffeinateCallback)
-- caffeinateWatcher:start()

-- -- Updated test hotkeys (because every good system needs manual override)
-- hotkey.bind({"cmd", "alt"}, "l", function()
--     mediaWasPlaying = checkMediaPlaying()
--     if mediaWasPlaying then
--         toggleMediaPlayback()
--     end
--     alert.show("TEST: " .. (mediaWasPlaying and "⏸️ Paused" or "❌ No media"))
-- end)

-- hotkey.bind({"cmd", "alt"}, "u", function()
--     if mediaWasPlaying then
--         toggleMediaPlayback()
--         mediaWasPlaying = false
--     end
--     alert.show("TEST: " .. (mediaWasPlaying and "▶️ Resumed" or "❌ Nothing to resume"))
-- end)

-- print("Lock/media control active " .. os.date("%Y-%m-%d %H:%M:%S"))
-- alert.show("Media Lock Control Active", 1)

-- TEMPORARY: Load and test the Spoon independently
-- local testSpoon = dofile("/Users/tpinto/setup-station/hammerspoon/Spoons/LocationAwareMute.spoon/init.lua")
-- hs.alert.show("Spoon loaded: " .. tostring(testSpoon ~= nil))
-- if testSpoon then
--   testSpoon:start() --Try calling start.
-- end


local LocationAwareMute = hs.loadSpoon("LocationAwareMute")
LocationAwareMute:start()
-- ... (rest of your init.lua) ...  Leave your existing code in place for now.