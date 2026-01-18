local addonName, LSaber = ...
LSaber = LSaber or {}
LSaber.AddonName = LSaber.AddonName or addonName or "LightsaberCrit"

if not LSaber.After then
    if C_Timer and C_Timer.After then
        LSaber.After = C_Timer.After
    else
        local timers = {}
        local frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function(_, elapsed)
            for i = #timers, 1, -1 do
                local timer = timers[i]
                timer.remaining = timer.remaining - elapsed
                if timer.remaining <= 0 then
                    table.remove(timers, i)
                    timer.func()
                end
            end
        end)
        LSaber.After = function(delay, func)
            if type(func) ~= "function" then return end
            timers[#timers + 1] = { remaining = delay or 0, func = func }
        end
    end
end

if not LSaber.Atan2 then
    function LSaber.Atan2(y, x)
        if type(math.atan2) == "function" then
            return math.atan2(y, x)
        end
        if x == 0 then
            if y > 0 then
                return math.pi / 2
            elseif y < 0 then
                return -math.pi / 2
            end
            return 0
        end
        local angle = math.atan(y / x)
        if x < 0 then
            if y >= 0 then
                angle = angle + math.pi
            else
                angle = angle - math.pi
            end
        end
        return angle
    end
end
