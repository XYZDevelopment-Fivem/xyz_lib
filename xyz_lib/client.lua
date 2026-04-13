local activeProgress = false
local activeProgressId = 0
local progressCancelled = false

local textUiVisible = false
local textUiData = nil
local textUiPressed = false

local keyMap = {
    E = 38,
    G = 47,
    H = 74,
    F = 23,
    X = 73,
    Y = 246,
    K = 311,
    L = 182,
    BACKSPACE = 177,
    ENTER = 191
}

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function normalizeNotifyInput(data, notifyType, duration)
    if type(data) == 'string' then
        return {
            title = 'NOTIFY',
            description = data,
            type = notifyType or 'info',
            duration = duration or 4000
        }
    end

    data = data or {}
    data.type = data.type or notifyType or 'info'
    data.duration = data.duration or duration or 4000
    data.title = data.title or 'NOTIFY'
    data.description = data.description or data.message or ''
    return data
end

local function notify(data, notifyType, duration)
    local payload = normalizeNotifyInput(data, notifyType, duration)
    payload.id = GetGameTimer() + math.random(1111, 9999)

    SendNUIMessage({
        action = 'notify',
        data = payload
    })
end

exports('Notify', function(data, notifyType, duration)
    notify(data, notifyType, duration)
end)

exports('Success', function(data, duration)
    notify(data, 'success', duration)
end)

exports('Error', function(data, duration)
    notify(data, 'error', duration)
end)

exports('Info', function(data, duration)
    notify(data, 'info', duration)
end)

exports('Warning', function(data, duration)
    notify(data, 'warning', duration)
end)

local function disableControls(opts)
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)

    if opts.disableMovement then
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 32, true)
        DisableControlAction(0, 33, true)
        DisableControlAction(0, 34, true)
        DisableControlAction(0, 35, true)
        DisableControlAction(0, 36, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
    end

    if opts.disableCarMovement then
        DisableControlAction(0, 59, true)
        DisableControlAction(0, 60, true)
        DisableControlAction(0, 61, true)
        DisableControlAction(0, 62, true)
        DisableControlAction(0, 63, true)
        DisableControlAction(0, 64, true)
        DisableControlAction(0, 71, true)
        DisableControlAction(0, 72, true)
        DisableControlAction(0, 75, true)
        DisableControlAction(0, 76, true)
    end

    if opts.disableMouse then
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 3, true)
        DisableControlAction(0, 4, true)
        DisableControlAction(0, 5, true)
        DisableControlAction(0, 6, true)
        DisableControlAction(0, 7, true)
    end

    if opts.disableCombat then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 37, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 45, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(0, 143, true)
        DisableControlAction(0, 257, true)
        DisableControlAction(0, 263, true)
        DisableControlAction(0, 264, true)
    end
end

local function startProgress(data)
    if activeProgress then
        return false
    end

    data = data or {}

    local duration = tonumber(data.duration) or 3000
    duration = math.max(duration, 1)

    local label = data.label or 'Working...'
    local title = data.title or 'PROGRESS'
    local canCancel = data.canCancel == true

    local opts = {
        disableMovement = data.disableMovement == true,
        disableCarMovement = data.disableCarMovement == true,
        disableMouse = data.disableMouse == true,
        disableCombat = data.disableCombat == true
    }

    activeProgress = true
    progressCancelled = false
    activeProgressId = activeProgressId + 1

    local thisId = activeProgressId
    local startTime = GetGameTimer()
    local endTime = startTime + duration

    SendNUIMessage({
        action = 'progressStart',
        data = {
            id = thisId,
            title = title,
            label = label,
            duration = duration,
            canCancel = canCancel
        }
    })

    local promiseObj = promise.new()

    CreateThread(function()
        local lastUiUpdate = 0

        while activeProgress and activeProgressId == thisId do
            local now = GetGameTimer()
            local remaining = endTime - now
            local percent = clamp(((now - startTime) / duration) * 100.0, 0.0, 100.0)

            if now - lastUiUpdate >= 50 or now >= endTime then
                lastUiUpdate = now

                SendNUIMessage({
                    action = 'progressUpdate',
                    data = {
                        id = thisId,
                        percent = percent,
                        remaining = remaining > 0 and remaining or 0,
                        label = label,
                        title = title
                    }
                })
            end

            disableControls(opts)

            if canCancel then
                if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 73) then
                    progressCancelled = true
                    activeProgress = false
                    break
                end
            end

            if now >= endTime then
                activeProgress = false
                break
            end

            Wait(0)
        end

        local cancelled = progressCancelled

        SendNUIMessage({
            action = 'progressStop',
            data = {
                id = thisId,
                cancelled = cancelled
            }
        })

        progressCancelled = false
        promiseObj:resolve(not cancelled)
    end)

    return Citizen.Await(promiseObj)
end

exports('Progress', function(data)
    return startProgress(data)
end)

exports('IsProgressActive', function()
    return activeProgress
end)

exports('CancelProgress', function()
    if not activeProgress then
        return false
    end

    progressCancelled = true
    activeProgress = false
    return true
end)

local function normalizeTextUiData(data)
    data = data or {}

    local key = tostring(data.key or 'E'):upper()
    local position = tostring(data.position or 'right'):lower()
    local icon = data.icon or nil
    local text = data.text or data.label or 'Interact'
    local subtext = data.subtext or ''
    local accent = data.accent or '#8a2bff'

    if position ~= 'left' and position ~= 'right' and position ~= 'top' then
        position = 'right'
    end

    return {
        key = key,
        control = keyMap[key] or 38,
        text = text,
        subtext = subtext,
        position = position,
        accent = accent,
        icon = icon
    }
end

local function showTextUi(data)
    local payload = normalizeTextUiData(data)

    textUiVisible = true
    textUiPressed = false
    textUiData = payload

    SendNUIMessage({
        action = 'textuiShow',
        data = {
            key = payload.key,
            text = payload.text,
            subtext = payload.subtext,
            position = payload.position,
            accent = payload.accent,
            icon = payload.icon
        }
    })

    return true
end

local function updateTextUi(data)
    if not textUiVisible then
        return showTextUi(data)
    end

    local payload = normalizeTextUiData(data)

    textUiPressed = false
    textUiData = payload

    SendNUIMessage({
        action = 'textuiUpdate',
        data = {
            key = payload.key,
            text = payload.text,
            subtext = payload.subtext,
            position = payload.position,
            accent = payload.accent,
            icon = payload.icon
        }
    })

    return true
end

local function hideTextUi()
    if not textUiVisible then
        return false
    end

    textUiVisible = false
    textUiPressed = false
    textUiData = nil

    SendNUIMessage({
        action = 'textuiHide'
    })

    return true
end

exports('ShowTextUI', function(data)
    return showTextUi(data)
end)

exports('UpdateTextUI', function(data)
    return updateTextUi(data)
end)

exports('HideTextUI', function()
    return hideTextUi()
end)

exports('IsTextUIVisible', function()
    return textUiVisible
end)

exports('WasTextUIPressed', function()
    if textUiPressed then
        textUiPressed = false
        return true
    end

    return false
end)

CreateThread(function()
    while true do
        if textUiVisible and textUiData then
            local control = textUiData.control or 38

            if IsControlJustPressed(0, control) then
                textUiPressed = true
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

RegisterCommand('xyz_notify_test', function()
    exports['xyz_lib']:Notify({
        title = 'XYZ LIB',
        description = 'This is a clean standalone notify.',
        type = 'info',
        duration = 4000
    })
end, false)

RegisterCommand('xyz_progress_test', function()
    CreateThread(function()
        local finished = exports['xyz_lib']:Progress({
            title = 'XYZ LIB',
            label = 'Loading something clean...',
            duration = 5000,
            canCancel = true,
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = false
        })

        if finished then
            exports['xyz_lib']:Success({
                title = 'DONE',
                description = 'Progress finished successfully.',
                duration = 3000
            })
        else
            exports['xyz_lib']:Error({
                title = 'CANCELLED',
                description = 'Progress was cancelled.',
                duration = 3000
            })
        end
    end)
end, false)

RegisterCommand('xyz_textui_test', function()
    CreateThread(function()
        exports['xyz_lib']:ShowTextUI({
            key = 'E',
            text = 'Open storage',
            subtext = 'Press to interact',
            position = 'right'
        })

        local timeout = GetGameTimer() + 10000

        while GetGameTimer() < timeout do
            if exports['xyz_lib']:WasTextUIPressed() then
                exports['xyz_lib']:HideTextUI()
                exports['xyz_lib']:Success({
                    title = 'INTERACT',
                    description = 'You pressed E.',
                    duration = 2500
                })
                return
            end
            Wait(0)
        end

        exports['xyz_lib']:HideTextUI()
    end)
end, false)