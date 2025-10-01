-- ***************************************
--				Ethos-lua
-- 		FS Status Display Widget 
-- Display numbers 1 to 6 representing FS1 to FS6
-- ***************************************

local function paint(widget)
	local winW = lcd.getWindowSize()
	local startX = (winW - 224) / 2  -- 224 is approx width for 6 XXL chars with spacing
	
	for i = 0, 5 do
		lcd.color(widget.fsColors[i + 1])
		lcd.font(widget.fsFont[i + 1])
		lcd.drawText(startX + i * 40, widget.fsyPos[i + 1], tostring(i + 1), TEXT_CENTER)
	end
end

local function updateColors(widget)
	local active, inactive
	if widget.ColourDisplay then
		active, inactive = COLOR_GREEN, COLOR_RED
	else
		active = lcd.darkMode() and COLOR_WHITE or COLOR_BLACK
		inactive = COLOR_BLUE
	end
	widget.ActiveColour, widget.InactiveColour = active, inactive
end

local function updateFS(widget, index, isActive)
	if isActive then
		widget.fsColors[index] = widget.ActiveColour
		widget.fsFont[index] = FONT_XXL
		widget.fsyPos[index] = 12
	else
		widget.fsColors[index] = widget.InactiveColour
		widget.fsFont[index] = FONT_L
		widget.fsyPos[index] = 24
	end
end

local function create()
	local widget = {
		ColourDisplay = true,
		ActiveColour = COLOR_GREEN,    -- Initialize color properties
		InactiveColour = COLOR_RED,    -- Initialize color properties
		fsValues = {},
		fsColors = {},
		fsFont = {},
		fsyPos = {},
		lastCheck = 0
	}
	
	-- Initialize arrays with placeholder values - read() will set correct colors
	for i = 1, 6 do
		widget.fsValues[i] = -1  -- Force initial update
		widget.fsColors[i] = widget.InactiveColour  -- Use widget color, not hardcoded
		widget.fsFont[i] = FONT_L
		widget.fsyPos[i] = 24
	end
	
	return widget
end

local function configure(widget)
	local line = form.addLine("Display in Colour")
	form.addBooleanField(line, nil, 
		function() return widget.ColourDisplay end,
		function(v)
			widget.ColourDisplay = v
			updateColors(widget)
			-- Refresh all FS displays
			for i = 1, 6 do
				updateFS(widget, i, widget.fsValues[i] == 100)
			end
			lcd.invalidate()
		end)
end

local function wakeup(widget)
	local currentTime = os.time()
	if currentTime - widget.lastCheck < 0.1 then return end
	
	widget.lastCheck = currentTime
	local needsUpdate = false
	
	for i = 0, 5 do
		local fsValue = system.getSource({category = CATEGORY_FUNCTION_SWITCH, member = i}):value()
		local index = i + 1
		
		if widget.fsValues[index] ~= fsValue then
			widget.fsValues[index] = fsValue
			updateFS(widget, index, fsValue == 100)
			needsUpdate = true
		end
	end
	
	if needsUpdate then lcd.invalidate() end
end

local function read(widget)
	local stored = storage.read("ColourDisplay")
	if stored == nil then
		widget.ColourDisplay = true  -- Default for first run
	else
		widget.ColourDisplay = stored  -- Use stored value (true or false)
	end
	updateColors(widget)
	
	-- Update all colors in the arrays to match the loaded setting
	for i = 1, 6 do
		widget.fsColors[i] = widget.InactiveColour  -- Use the correct inactive color
	end
end

local function write(widget)
	storage.write("ColourDisplay", widget.ColourDisplay)
end

local function event(widget, category, value, x, y)
	-- Handle user interactions if needed
end

local function init()
	system.registerWidget({
		key = "fsstatus",
		name = "FS Status",
		create = create,
		wakeup = wakeup,
		paint = paint,
		configure = configure,
		event = event,
		read = read,
		write = write
	})
end

return {init = init}
