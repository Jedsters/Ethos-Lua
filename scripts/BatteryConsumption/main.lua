-- ***************************************
--		Ethos-lua        
-- 	
-- ***************************************
--
-- 1.0 Feb 2026 - Original sensor display
-- 2.0 Feb 2026 - Added daily total across multiple batteries
-- 2.2 Feb 2026 - Cleaned up formatting, touch reset button
-- ***************************************************************
-- ***  Widget LiPoConsumption                                 ***
-- ***  Displays:                                              ***
-- ***    - Flight: mAh used from the current/last battery     ***
-- ***    - Total:  accumulated mAh for the day                ***
-- ***    - Touch reset button (bottom-right, 60x60px)         ***
-- ***                                                         ***
-- ***  HOW THE TOTAL WORKS:                                   ***
-- ***  When the sensor goes inactive (source:state()==false)  ***
-- ***  the battery has been disconnected. The last known      ***
-- ***  reading is banked into the daily total at that point.  ***
-- ***  When the sensor becomes active again it is a new       ***
-- ***  battery, and its consumption adds on top of the total. ***
-- ***  Total = banked mAh from previous batteries             ***
-- ***          + current sensor reading (only when active)    ***
-- ***                                                         ***
-- ***  RESET: touch the reset button (bottom-right corner)    ***
-- ***                                                         ***
-- ***  USE AT YOUR OWN RISK                                   ***
-- ***************************************************************

local titlefont    = FONT_S    -- widget title / source name
local valuefont    = FONT_L   -- Flight: and Total: data rows
local defaulttitle = "LiPoConsumption"

-- Reset button dimensions
local BTN_SIZE = 60

local oldTime = 0

-- Module-level state
local bankedMah       = 0
local savedDate       = ""
local lastMah         = 0
local sensorWasActive = false

-- ---- Helpers ------------------------------------------------

local function getDate()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

-- ---- Reset logic --------------------------------------------

local function doReset(widget)
    bankedMah         = 0
    lastMah           = 0
    sensorWasActive   = false
    widget.bankedMah  = 0
    local today       = getDate()
    widget.savedDate  = today
    -- Persist immediately so a power cycle after reset doesn't restore old values
    storage.write("bankedMah", 0)
    storage.write("savedDate", today)
    lcd.invalidate()
end



local function drawResetButton(widget, bx, by)
    local cx  = bx + BTN_SIZE / 2
    local cy  = by + BTN_SIZE / 2
    local r   = 22
    local asz = 6

    lcd.color(lcd.RGB(40, 40, 40))
    lcd.drawFilledRectangle(bx, by, BTN_SIZE, BTN_SIZE)

    local iconCol
    if widget.btnPressed then
        iconCol = lcd.RGB(0, 210, 0)
    else
        iconCol = lcd.RGB(210, 0, 0)
    end
    lcd.color(iconCol)

    -- ---- Reset button drawing -----------------------------------
    -- Two circular arrows, RED at rest, GREEN when pressed.

    lcd.drawAnnulusSector(cx, cy, r-1, r+1, 290, 70)
    lcd.drawAnnulusSector(cx, cy, r-1, r+1, 110,  240)

    -- Arrowhead at end of top arc (340 deg, tangent ~70 deg)
    do
        local a  = math.rad(340)
        local tx = math.floor(cx + r * math.cos(a) + 0.5)
        local ty = math.floor(cy + r * math.sin(a) + 0.5)
        local ta = math.rad(70)
        lcd.drawFilledTriangle(tx+2,ty+2, tx-7, ty-2, tx+2, ty-8)

    end

    -- Arrowhead at end of bottom arc (160 deg, tangent ~250 deg)
    do
        local a  = math.rad(160)
        local tx = math.floor(cx + r * math.cos(a) + 0.5)
        local ty = math.floor(cy + r * math.sin(a) + 2.5)
        local ta = math.rad(250)
        lcd.drawFilledTriangle(tx-1, ty, tx+1, ty+13, tx+12, ty+2)
    end

    lcd.font(FONT_XS_BOLD)
    lcd.drawText(cx, cy - 5, "RESET", TEXT_CENTERED)
end

-- ---- create -------------------------------------------------
local function create()
    return { btnPressed = false }
end

-- ---- configure ----------------------------------------------
local function configure(widget)
    local line = form.addLine("Sensor")
    form.addSensorField(line, nil,
        function() return widget.source end,
        function(value) widget.source = value end)

    local line1 = form.addLine("Units on Title Line")
    form.addBooleanField(line1, nil,
        function() return widget.titleunits end,
        function(newValue) widget.titleunits = newValue end)
end

-- ---- wakeup (runs ~every second) ----------------------------
local function wakeup(widget)
    if os.time() - oldTime < 1 then return end
    oldTime = os.time()

    local today = getDate()
    if today ~= savedDate then
        bankedMah         = 0
        savedDate         = today
        lastMah           = 0
        sensorWasActive   = false
        widget.bankedMah  = 0
        widget.savedDate  = today
        -- Persist so a power cycle on the new day doesn't restore yesterday's values
        storage.write("bankedMah", 0)
        storage.write("savedDate", today)
    end

    if widget.source then
        local sensorActive = widget.source:state()
        local currentMah   = widget.source:value()

        if sensorActive then
            if currentMah ~= nil then
                lastMah = currentMah
            end
        else
            if sensorWasActive and lastMah > 0 then
                bankedMah        = bankedMah + lastMah
                lastMah          = 0
                local bankDate   = getDate()
                widget.bankedMah = bankedMah
                widget.savedDate = bankDate
                -- Persist immediately — if TX powers off before Ethos calls
                -- write() the banked value would otherwise be lost
                storage.write("bankedMah", bankedMah)
                storage.write("savedDate", bankDate)
            end
        end

        sensorWasActive = sensorActive
    end

    lcd.invalidate()
end

-- ---- event --------------------------------------------------
local function event(widget, category, value, x, y)
    local w, h = lcd.getWindowSize()
    local btnX = w - BTN_SIZE
    local btnY = h - BTN_SIZE

    if category == EVT_TOUCH and value == 16640 then        -- touch start
        if x >= btnX and x <= w and y >= btnY and y <= h then
            widget.btnPressed = true
            lcd.invalidate()
            system.killEvents(value)
            return true
        end

    elseif category == EVT_TOUCH and value == 16641 then    -- touch stop
        if widget.btnPressed then
            widget.btnPressed = false
            -- Only fire reset if finger was released within the button area.
            if x >= btnX and x <= w and y >= btnY and y <= h then
                doReset(widget)
            end
            lcd.invalidate()
            system.killEvents(value)
            return true
        end
    end

    -- Safety net: if the button appears pressed but we receive any other
    -- event (e.g. a touch-move or touch-cancel with an unrecognised value),
    -- clear the pressed state so the icon never stays green indefinitely.
    if widget.btnPressed then
        widget.btnPressed = false
        lcd.invalidate()
    end

    return false
end

-- ---- paint --------------------------------------------------
local function paint(widget)
    local w, h = lcd.getWindowSize()

    -- ---- Title row ------------------------------------------
    -- FONT_S, centred, at the top of the widget
    if lcd.darkMode() then
        lcd.color(WHITE)
    else
        lcd.color(THEME_DEFAULT_COLOR)
    end

    local titleY = 2
    lcd.font(titlefont)
    local _, titleH = lcd.getTextSize("Ay")   -- actual height of title font

    if widget.source then
        local sourcename = widget.source:name()
        if widget.titleunits and widget.source:stringUnit() ~= nil then
            sourcename = sourcename .. " " .. widget.source:stringUnit()
        end
        lcd.drawText(w / 2, titleY, sourcename, TEXT_CENTERED)
    else
        lcd.drawText(w / 2, titleY, defaulttitle, TEXT_CENTERED)
    end

    -- ---- Data rows ------------------------------------------
    -- The space below the title is split into two equal rows.
    -- Each row has:
    --   label ("Flight:" or "Total:") drawn TEXT_LEFT at labelX
    --   number right-justified at numRightX, followed immediately by "mAh"
    --
    -- Layout:
    --   labelX      = small left margin
    --   numRightX   = w - BTN_SIZE - margin  (stays clear of the reset button)
    --                 numbers are TEXT_RIGHT anchored here
    --   "mAh" drawn TEXT_LEFT immediately after numRightX
    --
    -- The reset button occupies bottom-right BTN_SIZE x BTN_SIZE, so the
    -- text area is w - BTN_SIZE wide for the bottom row.

    local dataTop    = titleY + titleH + 4   -- top of data area
    local dataH      = h - dataTop           -- height available for 2 rows
    local rowH       = dataH / 2             -- height of each row

    local labelX     = 10
    -- Measure text dimensions at runtime so layout is correct on any screen scaling.
    -- lcd.getTextSize() returns width, height.
    lcd.font(valuefont)
    local labelW, _  = lcd.getTextSize("Flight: ")   -- "Flight:" is wider than "Total:"
    local numW, _    = lcd.getTextSize("000000")     -- worst-case 6-digit number width
    local _, valueH  = lcd.getTextSize("0")          -- actual height of value font
    -- Vertical centre of each row using measured font height
    local row1Y      = math.floor(dataTop + rowH * 0 + (rowH / 2) - (valueH / 2))
    local row2Y      = math.floor(dataTop + rowH * 1 + (rowH / 2) - (valueH / 2))
    local numRightX  = labelX + labelW + numW
    local mahX       = numRightX + 2                 -- "mAh" sits just right of the number

    if widget.source then
        local sensorActive = widget.source:state()

        -- Value colour
        if not sensorActive then
            lcd.color(RED)
        elseif lcd.darkMode() then
            lcd.color(GREEN)
        else
            lcd.color(THEME_DEFAULT_COLOR)
        end

        -- Current flight mAh (sensor value, or 0 when inactive)
        local currentRaw = 0
        if sensorActive then
            currentRaw = widget.source:value() or 0
        end
        local totalMah = bankedMah + currentRaw

        -- Resolve unit suffix for value rows.
        -- Show units after the number unless the user has chosen to show them
        -- in the title instead (titleunits == true).
        local unitStr = ""
        if not widget.titleunits then
            local u = widget.source:stringUnit()
            if u ~= nil and u ~= "" then
                unitStr = u
            end
        end

        -- Row 1: Flight
        lcd.drawText(labelX,    row1Y, "Flight:", TEXT_LEFT)
        lcd.drawText(numRightX, row1Y, math.floor(currentRaw), TEXT_RIGHT)
        lcd.drawText(mahX,      row1Y, unitStr, TEXT_LEFT)

        -- Row 2: Total
        lcd.drawText(labelX,    row2Y, "Total:", TEXT_LEFT)
        lcd.drawText(numRightX, row2Y, math.floor(totalMah), TEXT_RIGHT)
        lcd.drawText(mahX,      row2Y, unitStr, TEXT_LEFT)

    else
        -- No source configured
        if lcd.darkMode() then
            lcd.color(WHITE)
        else
            lcd.color(THEME_DEFAULT_COLOR)
        end
        lcd.drawText(labelX, row1Y, "No sensor", TEXT_LEFT)
        lcd.drawText(labelX, row2Y, "selected",  TEXT_LEFT)
    end

    -- ---- Reset button (bottom-right) ------------------------
    drawResetButton(widget, w - BTN_SIZE, h - BTN_SIZE)
end

-- ---- read ---------------------------------------------------
local function read(widget)
    widget.source     = storage.read("source")
    widget.titleunits = storage.read("titleunits")
    widget.bankedMah  = storage.read("bankedMah") or 0
    widget.savedDate  = storage.read("savedDate")  or ""

    local today = getDate()
    savedDate = widget.savedDate
    if savedDate == today then
        bankedMah = widget.bankedMah
    else
        bankedMah        = 0
        widget.bankedMah = 0
        widget.savedDate = today
        savedDate        = today
    end

    lastMah         = 0
    sensorWasActive = false
end

-- ---- write --------------------------------------------------
local function write(widget)
    storage.write("source",     widget.source)
    storage.write("titleunits", widget.titleunits)
    storage.write("bankedMah",  widget.bankedMah or bankedMah)
    storage.write("savedDate",  widget.savedDate or getDate())  -- fallback only if nil
end

-- ---- init ---------------------------------------------------
local function init()
    system.registerWidget({
        key       = "LiPoUse",
        name      = "LiPo Consumption",
        create    = create,
        wakeup    = wakeup,
        paint     = paint,
        configure = configure,
        read      = read,
        write     = write,
        event     = event,
        title     = false,
    })
end

return { init = init }
