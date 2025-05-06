local LocationAwareMute = hs.loadSpoon("LocationAwareMute")
LocationAwareMute:start()

hs.hotkey.bind({"cmd", "ctrl", "shift"}, "b", function()
    local location = hs.location.get()
    if location then
        hs.alert.show(string.format("Location: %.4f, %.4f", location.latitude, location.longitude))
        print(string.format("Location: %.4f, %.4f", location.latitude, location.longitude))
    else
        hs.alert.show("Location services not available")

        print(string.format("Location services status: %s", location and "available" or "not available"))
        

    end
end)
