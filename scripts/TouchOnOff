-- Simple two-button On/Off touch widget for FrSky Ethos
-- Displays an ON button and an OFF button inside the widget area.
-- The Widget title and button text can be changed in the Widget 
-- configuration dialog.
-- Touching ON outputs +100% (1024) at the lua source 
-- Touching OFF outputs -100% (-1024) at the lua source
--
-- Registers a number (MAX_WIDGETS) of sources, which enables up to this
-- number of instances of this widget to be used on this model,
-- each being given their own source with the name of the source being 
-- displayed in the widget configuration and beside the widget title,
-- e.g. OnOff1, OnOff2 etc.. 
-- This is done to reduce chances of a single source being used more
-- than once by accident. 
-- You will need to enable this source via Models->Lua before it can be used.
-- Once source has been enabled, the widget is ready to be used.
--
-- This can be used to output values to an rx, e.g. 
-- Mixes, Free Mix, Source e.g. OnOff1, Channel Output nn 
-- after which the specified channel will have a value of 0,
-- 100% while On is touched or -100% while off is being touched. 
-- N.B. There is currently a quirk in that if you touch a button it momentarily 
-- becomes true, however if you drag the button then it remains true. To 
-- stop this simply touch either button again.  
--
-- Alternatively you can use the source in LS comparing the source value to 
-- 1024 (On) or -1024 (Off) which then enables use of things like confirmation
-- before in/active and sticky values. 
--
-- You may consider it safest to use an LS with confirmation to reduce the 
-- chances of anything untoward happening by accident.
-- You may also want to use min duration so that an LS only activates if
-- the button is pressed for more than a certain interval, e.g. to prevent
-- turning off by accident. Here changing e.g. the Off button text to Off 3sec 
-- may be desirable as a reminder.  
--
-- Output values:
--   ON  button : +100%  (value  1024 internally)
--   OFF button : -100%  (value -1024 internally)

local TITLE_FONT = FONT_S
local BUTTON_FONT = FONT_STD
local DEFAULT_TITLE = "On/Off"
local BUTTON_GAP = 10
local BUTTON_MARGIN = 10

-- Track widget instances and their sources
local widgetSources = {}
local widgetCounters = {}  -- Track counters per model
local MAX_WIDGETS = 10  -- Support up to 10 widget instances

local function getModelCounter()
    local modelId = model.name()  -- Get current model name as ID
    if not widgetCounters[modelId] then
        widgetCounters[modelId] = 0
    end
    return widgetCounters[modelId]
end

local function setModelCounter(value)
    local modelId = model.name()
    widgetCounters[modelId] = value
end

local function create()
    local term = {
        "Source",       -- 1: source field label
        "ON",           -- 2: ON button label
        "OFF"           -- 3: OFF button label
    }

    -- Use placeholder instance ID - will be corrected by read() for existing widgets
    -- Only increment for truly new widgets (read() won't find stored instanceId)
    local instanceId = 0  -- Placeholder
    
    return {
        instanceId = instanceId,
        sourceName = "OnOff0",  -- Placeholder
        sourceValue = 0,    -- Current output value
        active = 0,         -- 0 = nothing pressed, 1 = ON pressed, 2 = OFF pressed
        term = term,
        buttons = {},       -- Will store button dimensions
        title = DEFAULT_TITLE    -- Widget title
    }
end

local function calculateButtonLayout(widget)
    local w, h = lcd.getWindowSize()
    
    -- Calculate title area
    lcd.font(TITLE_FONT)
    local _, titleH = lcd.getTextSize("Ay")
    local titleY = 2
    
    -- Calculate button dimensions
    local buttonsTop = titleY + titleH + BUTTON_MARGIN
    local btnW = (w - (2 * BUTTON_MARGIN) - BUTTON_GAP) / 2
    local btnH = h - buttonsTop - BUTTON_MARGIN
    
    -- Store button positions (only calculate once)
    widget.buttons = {
        titleY = titleY,
        titleH = titleH,
        on = {
            x = BUTTON_MARGIN,
            y = buttonsTop,
            w = btnW,
            h = btnH
        },
        off = {
            x = BUTTON_MARGIN + btnW + BUTTON_GAP,
            y = buttonsTop,
            w = btnW,
            h = btnH
        }
    }
end

local function paint(widget)
    -- Lazy initialization if read() hasn't set instanceId yet
    if widget.instanceId == 0 then
        local counter = getModelCounter() + 1
        if counter > MAX_WIDGETS then
            -- Show warning instead of normal display
            local w, h = lcd.getWindowSize()
            lcd.color(lcd.RGB(255, 0, 0))
            lcd.drawFilledRectangle(0, 0, w, h)
            lcd.color(lcd.RGB(255, 255, 255))
            lcd.font(FONT_STD)
            lcd.drawText(w/2, h/2, "MAX WIDGETS (" .. MAX_WIDGETS .. ") EXCEEDED!", TEXT_CENTERED)
            return
        end
        setModelCounter(counter)
        widget.instanceId = counter
        widget.sourceName = "OnOff" .. counter
    end
    
    local w, h = lcd.getWindowSize()
    
    -- Calculate layout if not done or if window size changed
    if not widget.buttons.on or widget.lastW ~= w or widget.lastH ~= h then
        calculateButtonLayout(widget)
        widget.lastW = w
        widget.lastH = h
    end
    
    local btn = widget.buttons
    
    -- Draw title with source name
    if lcd.darkMode() then
        lcd.color(WHITE)
    else
        lcd.color(THEME_DEFAULT_COLOR)
    end
    lcd.font(TITLE_FONT)
    
    -- Draw title and source name on same line
    local titleText = widget.title .. "     (Source: " .. widget.sourceName .. ")"
    lcd.drawText(w / 2, btn.titleY, titleText, TEXT_CENTERED)
    
    -- Draw ON button
    if widget.active == 1 then
        lcd.color(lcd.RGB(0, 210, 0))       -- bright green when pressed
    else
        lcd.color(lcd.RGB(0, 140, 0))       -- darker green when idle
    end
    lcd.drawFilledRectangle(btn.on.x, btn.on.y, btn.on.w, btn.on.h)
    
    -- ON button label
    lcd.font(BUTTON_FONT)
    lcd.color(lcd.RGB(255, 255, 255))
    local _, txtH = lcd.getTextSize("Ay")
    lcd.drawText(
        btn.on.x + btn.on.w / 2, 
        btn.on.y + btn.on.h / 2 - txtH / 2, 
        widget.term[2], 
        TEXT_CENTERED
    )
    
    -- Draw OFF button
    if widget.active == 2 then
        lcd.color(lcd.RGB(210, 0, 0))       -- bright red when pressed
    else
        lcd.color(lcd.RGB(140, 0, 0))       -- darker red when idle
    end
    lcd.drawFilledRectangle(btn.off.x, btn.off.y, btn.off.w, btn.off.h)
    
    -- OFF button label
    lcd.color(lcd.RGB(255, 255, 255))
    lcd.drawText(
        btn.off.x + btn.off.w / 2, 
        btn.off.y + btn.off.h / 2 - txtH / 2, 
        widget.term[3], 
        TEXT_CENTERED
    )
end

local function isTouchInButton(x, y, button)
    return x >= button.x and 
           x <= (button.x + button.w) and 
           y >= button.y and 
           y <= (button.y + button.h)
end

local function event(widget, category, value, x, y)
    if category == EVT_TOUCH then
        if value == TOUCH_START then    -- Touch Start
            -- Ensure button layout is calculated
            if not widget.buttons.on then
                calculateButtonLayout(widget)
            end
            
            local btn = widget.buttons
            
            -- Check if ON button was touched
            if isTouchInButton(x, y, btn.on) then
                widget.active = 1
                widget.sourceValue = 1024
                widgetSources[widget.instanceId] = 1024
                system.killEvents(value)
                lcd.invalidate()
                return true
                
            -- Check if OFF button was touched
            elseif isTouchInButton(x, y, btn.off) then
                widget.active = 2
                widget.sourceValue = -1024
                widgetSources[widget.instanceId] = -1024
                system.killEvents(value)
                lcd.invalidate()
                return true
            end
            
        elseif value == TOUCH_END then    -- Touch Stop
            widget.active = 0
            widget.sourceValue = 0
            widgetSources[widget.instanceId] = 0
            lcd.invalidate()
            return true
        end
    end
    
    return false
end

local function configure(widget)
    -- Lazy initialization if read() hasn't set instanceId yet
    if widget.instanceId == 0 then
        local counter = getModelCounter() + 1
        if counter > MAX_WIDGETS then
            form.addLine("ERROR: MAX WIDGETS (" .. MAX_WIDGETS .. ") EXCEEDED!")
            return
        end
        setModelCounter(counter)
        widget.instanceId = counter
        widget.sourceName = "OnOff" .. counter
    end
    
    -- Show which source this widget uses
    form.addLine("Enable source " .. widget.sourceName .. " in Model → Lua")
    -- form.addLine("Enable in Model → Lua")
    
    -- Title input
    local line = form.addLine("Title")
    form.addTextField(line, nil, function()
        return widget.title
    end, function(newValue)
        widget.title = newValue
    end)
    
    -- ON button label input
    line = form.addLine("ON Button Text")
    form.addTextField(line, nil, function()
        return widget.term[2]
    end, function(newValue)
        widget.term[2] = string.sub(newValue, 1, 10)  -- Limit to 10 chars
    end)
    
    -- OFF button label input
    line = form.addLine("OFF Button Text")
    form.addTextField(line, nil, function()
        return widget.term[3]
    end, function(newValue)
        widget.term[3] = string.sub(newValue, 1, 10)  -- Limit to 10 chars
    end)
end

local function write(widget)
    storage.write("instanceId", widget.instanceId)
    storage.write("title", widget.title)
    storage.write("onButton", widget.term[2])
    storage.write("offButton", widget.term[3])
end

local function read(widget)
    local temp = storage.read("instanceId")
    if temp then
        -- Existing widget being restored
        widget.instanceId = temp
        widget.sourceName = "OnOff" .. temp
        -- Rebuild the counter from existing widgets
        if temp > getModelCounter() then
            setModelCounter(temp)
        end
    else
        -- New widget - assign next instance ID
        local counter = getModelCounter() + 1
        if counter > MAX_WIDGETS then
            counter = MAX_WIDGETS  -- Cap it but configure/paint will show error
        end
        setModelCounter(counter)
        widget.instanceId = counter
        widget.sourceName = "OnOff" .. counter
    end
    
    temp = storage.read("title")
    if temp then
        widget.title = temp
    end
    
    temp = storage.read("onButton")
    if temp then
        widget.term[2] = temp
    end
    
    temp = storage.read("offButton")
    if temp then
        widget.term[3] = temp
    end
end

local function init()
    -- Register the widget
    system.registerWidget({
        key = "ONOFF",
        name = "On/Off Switch",
        create = create,
        paint = paint,
        event = event,
        configure = configure,
        read = read,
        write = write,
        title = false
    })
    
    -- Pre-register a pool of sources that widgets can use
    for i = 1, MAX_WIDGETS do
        system.registerSource({
            key = "onoff" .. i,
            name = "OnOff" .. i,
            wakeup = function(source)
                local val = widgetSources[i] or 0
                source:value(val)
                return val
            end
        })
    end
end

return {init = init}
