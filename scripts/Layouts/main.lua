-- ***************************************
--              Ethos-lua
-- Display 1 to 4 values in different formats
-- 1: Display 1 value, normal display for completeness
-- 2: Display 2 values, two rows, one on top of the other
-- 3: Display 2 values, two columns, left and right
-- 4: Display 3 values, one on the top row and two below
-- 5: Display 3 values, one on the left, two on the right
-- 6: Display 4 values one in each quadrant
-- 7: Display 2 values to left in two rows, titles to right 
--
-- Sources are numbered as one would read this text!
-- The script will look at the size of the fonts used and use that as 
-- a basis for placing the various titles and values within the space available, 
-- i.e. if 2 values are displayed left and right and the 1st value is
-- XXL while the second value is S then more space will be allocated
-- for the first value etc.
-- In the Widget setup you have options to select the layout, 
-- each source and the font size for it and the font for the  titles
-- A title size of OFF removes all titles. 
-- There is also an option for Units on Title Line, with this OFF
-- then the units are concatenated to the values, e.g. a voltage
-- may be displayed as 8.0V alternatively with this on and when 
-- a title is not turned off then the units will be displayed as 
-- part of the title, e.g. the title may read Main Voltage V
-- This may be desirable if any of the values displayed are long and there
-- is insufficient width for them, displaying the units as part of the title
-- gives a bit more space for the values. 
-- Any sources which don't have anything assigned to them are displayed
-- as ---  Colours are also assigned to the sources showing their status
-- If source name for the 2nd, 3rd or 4th values starts the same as the 
-- first source then that part of it will not be displayed, 
-- e.g. if source1 is Altitude, source 2 is Altitude Max, then the title
-- for source2 is simply displayed as Max. 
-- This may produce minor oddities, e.g. if Source1 is RSSI and 
-- Source2 is RSSI 900M then source2 will simply be dislpayed as 900M 
-- this doesn't seem unreasonable so has been left as a feature!  
-- The wakeup function has been set to run at 1Hz to reduce the load on 
-- refreshing the screen. 
-- ***************************************

-- Function to determine title color based on dark mode
local function getTitleColor()
    if lcd.darkMode() then
        return lcd.RGB(176,176,176)
    else
        return lcd.RGB(96,96,96)
    end
end

-- Function to set widget colors based on ColourDisplay setting
local function updateWidgetColors(widget)
    if widget.ColourDisplay then 
        widget.ActiveColour = COLOR_GREEN
        widget.InactiveColour = COLOR_RED
    else
        if lcd.darkMode() then
            widget.ActiveColour = COLOR_WHITE
            widget.InactiveColour = COLOR_BLUE
        else
            widget.ActiveColour = COLOR_BLACK
            widget.InactiveColour = COLOR_BLUE
        end
    end
end

-- Function to trim common prefixes from source names
local function trimSourceNames(sourceTexts)
    if not sourceTexts or #sourceTexts < 2 then return sourceTexts end
    
    local trimmed = {}
    local reference = sourceTexts[1] -- Use first source as reference
    
    for i, text in ipairs(sourceTexts) do
        if i == 1 or not text or text == "" or text == "---" then
            trimmed[i] = text
        else
            -- Check if current source starts with reference source name
            if reference and reference ~= "" and reference ~= "---" then
                local refPattern = "^" .. reference:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                local remainder = text:gsub(refPattern, "")
                
                -- If we found a match and there's remaining text, use the remainder
                if remainder ~= text and remainder ~= "" then
                    -- Remove leading whitespace from remainder
                    remainder = remainder:gsub("^%s+", "")
                    trimmed[i] = remainder ~= "" and remainder or text
                else
                    trimmed[i] = text
                end
            else
                trimmed[i] = text
            end
        end
    end
    
    return trimmed
end

-- Font height lookup, return the approx pixel height for each font so we can allocate space for it
local fontHeights = {
    [FONT_XXS] = 10, [FONT_XS] = 12, [FONT_S] = 12, [FONT_STD] = 18, [FONT_L] = 22,
    [FONT_XL] = 26, [FONT_XXL] = 36, [FONT_XS_BOLD] = 10,
    [FONT_S_BOLD] = 14, [FONT_L_BOLD] = 24, [-1] = 0
}

local function getFontHeight(fontsize)
    return fontHeights[fontsize] or 38
end

local function setFont(fontsize)
    if fontsize == -1 then return 0 end
    lcd.font(fontsize)
    return getFontHeight(fontsize)
end

local function checkSourcesMatch(strings)
    local reference, foundValid, allSame = nil, false, true
    for _, str in ipairs(strings) do
        if str and str ~= "" and str ~= "---" then
            foundValid = true
            if not reference then reference = str
            elseif reference ~= str then allSame = false end
        end
    end
    return allSame, foundValid, reference
end

-- Pre-compute multiline positions (replaces the runtime getMultilinePositions function)
local function precomputeMultilinePositions(text, titleHeight, sourceHeight)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    if #words <= 1 then
        return {{text = text, offsetX = 0, offsetY = 0}}
    end
    
    local totalTextHeight = #words * titleHeight
    local startOffsetY = -(totalTextHeight - titleHeight) / 2
    
    local positions = {}
    for i, word in ipairs(words) do
        table.insert(positions, {
            text = word,
            offsetX = 0,  -- Will be added to base X position
            offsetY = startOffsetY + (i - 1) * titleHeight
        })
    end
    
    return positions
end

-- Cache title display data for the current layout only
local function cacheTitleDisplayData(widget)
    widget.titleCache = {}
    
    -- Cache title color (this rarely changes but we'll update it in wakeup if needed)
    widget.titleCache.titleColor = getTitleColor()
    
    -- Get source count for current layout
    local layout = widget.layout
    local sourceCount
    if layout == 0 then sourceCount = 1
    elseif layout == 1 or layout == 2 or layout == 6 then sourceCount = 2
    elseif layout == 3 or layout == 4 then sourceCount = 3
    else sourceCount = 4 end
    
    -- Build active sources for current layout
    local activeSources, activeUnits = {}, {}
    for i = 1, sourceCount do
        if widget.cachedSources and widget.cachedSources[i] then
            activeSources[i] = widget.cachedSourceTexts[i]
            activeUnits[i] = widget.cachedUnits[i]
        end
    end
    
    local allSameNames, foundValidNames, refName = checkSourcesMatch(activeSources)
    local allSameUnits, foundValidUnits, refUnit = checkSourcesMatch(activeUnits)
    
    -- Cache title display logic for current layout
    widget.titleCache.data = {
        sourceCount = sourceCount,
        activeSources = activeSources,
        activeUnits = activeUnits,
        allSameNames = allSameNames,
        foundValidNames = foundValidNames,
        refName = refName,
        allSameUnits = allSameUnits,
        foundValidUnits = foundValidUnits,
        refUnit = refUnit,
        showUnifiedTitle = foundValidNames and allSameNames and layout ~= 6,
        showIndividualTitles = foundValidNames and (not allSameNames or layout == 6)
    }
    
    -- Pre-compute display texts for individual titles with units
    local displaySourceTexts = {}
    for i = 1, 4 do
        displaySourceTexts[i] = widget.cachedSourceTexts[i]
    end
    
    -- Cache version with units appended to titles
    local displaySourceTextsWithUnits = {}
    for i = 1, sourceCount do
        if widget.cachedSources and widget.cachedSources[i] then 
            displaySourceTextsWithUnits[i] = widget.cachedSourceTexts[i] .. " " .. widget.cachedUnits[i]
        else
            displaySourceTextsWithUnits[i] = displaySourceTexts[i]
        end
    end
    
    widget.titleCache.data.displaySourceTexts = displaySourceTexts
    widget.titleCache.data.displaySourceTextsWithUnits = displaySourceTextsWithUnits
    
    -- Pre-compute unified title variations
    if widget.titleCache.data.showUnifiedTitle then
        widget.titleCache.data.unifiedTitle = refName
        widget.titleCache.data.unifiedTitleWithUnits = refName .. " " .. (refUnit or "")
    end
    
    -- Pre-compute multiline positions for layout 6 if needed
    if layout == 6 and widget.titleCache.data.showIndividualTitles then
        widget.titleCache.data.multilinePositions = {}
        for i = 1, sourceCount do
            local titleHeight = getFontHeight(widget.titlefont or FONT_S)
            local sourceHeight = getFontHeight(widget["font"..i] or FONT_L)
            
            -- Pre-compute multiline positions for each source text
            local sourceText = widget.cachedSourceTexts[i]
            local sourceTextWithUnits = widget.cachedSourceTexts[i] .. " " .. widget.cachedUnits[i]
            
            widget.titleCache.data.multilinePositions[i] = {
                normal = precomputeMultilinePositions(sourceText, titleHeight, sourceHeight),
                withUnits = precomputeMultilinePositions(sourceTextWithUnits, titleHeight, sourceHeight)
            }
        end
    end
    
    -- Mark the cached layout to detect layout changes
    widget.titleCache.cachedLayout = layout
end

-- Pre-processes title display data for current layout only
local function cacheSourceData(widget)
    widget.cachedSources = {}
    widget.cachedSourceTexts = {}
    widget.cachedUnits = {}
    widget.cachedDecimals = {}
    
    for i = 1, 4 do
        local source = widget["source"..i]
        widget.cachedSources[i] = source
        
        if source then
            widget.cachedSourceTexts[i] = source:name() or "---"
            widget.cachedUnits[i] = source:stringUnit() or ""
            widget.cachedDecimals[i] = source:decimals() or 0
        else
            widget.cachedSourceTexts[i] = "---"
            widget.cachedUnits[i] = ""
            widget.cachedDecimals[i] = 0
        end
    end
    
    -- Apply source name trimming at cache time
    widget.cachedSourceTexts = trimSourceNames(widget.cachedSourceTexts)
    
    -- Cache title display data for current layout only
    cacheTitleDisplayData(widget)
end

-- ************************************************
-- ***   Calculate layout positions              ***
-- ************************************************
local function calculateLayoutPositions(widget, showIndividualTitles)
    local WinW, WinH = lcd.getWindowSize()
    
    -- Calculate font heights internally
    local fontHeightsList = {}
    for i = 1, 4 do
        fontHeightsList[i] = getFontHeight(widget["font"..i] or FONT_L)
    end
    
    -- Calculate title font height internally
    local titleFontHeight = (widget.titlefont ~= -1) and getFontHeight(widget.titlefont or FONT_S) or 0
    local titleHeight = getFontHeight(widget.titlefont or FONT_S)
    
    -- Calculate buffer line internally
    local titleBufferLine = titleFontHeight == 0 and 0 or 0

    -- ************************************************
    -- ***   Top/Bottom Split Layout Helper          ***
    -- ************************************************
    local function topbottomsplit(topSourceH, botSourceH)
        local TotalTitleHeight = showIndividualTitles and (titleHeight + titleBufferLine*2) or 0
        local TopHeight = TotalTitleHeight + topSourceH 
        local BotHeight = TotalTitleHeight + botSourceH 
        local totalHeight = TopHeight + BotHeight
        local TopHeightPart = TopHeight / totalHeight   
        local BotHeightPart = BotHeight / totalHeight  
        
        local topTitleY, topSourceY, botTitleY, botSourceY
        
        if TopHeightPart + BotHeightPart <= 1 and totalHeight <= WinH then -- it should all fit
            -- lets divide the screen up proportionally
            TopHeightPart = TopHeightPart * WinH
            BotHeightPart = BotHeightPart * WinH
            
            topTitleY = titleBufferLine
            topSourceY = TotalTitleHeight + (TopHeightPart - TotalTitleHeight - topSourceH)/2
            botTitleY = TopHeightPart + titleBufferLine
            botSourceY = TopHeightPart + TotalTitleHeight + (BotHeightPart - TotalTitleHeight - botSourceH)/2
        else  -- it won't fit so place tightly
            topTitleY = 0
            topSourceY = titleHeight   -- No room for space above or below title, just the title
            botTitleY = titleHeight + topSourceH + 2  -- Just a gap between sections 
            botSourceY = botTitleY + titleHeight
        end 
        
        return topTitleY, topSourceY, botTitleY, botSourceY
    end

    -- ************************************************
    -- ***   Left / Right Split Layout Helper          ***
    -- ************************************************    
    local function leftrightsplit(leftSourceH, rightSourceH)
        local LRTitle = showIndividualTitles and titleHeight or 0
        local maxLeftSource = math.max(leftSourceH, LRTitle)
        local maxRightSource = math.max(rightSourceH, LRTitle)
        local total = maxLeftSource + maxRightSource
        local leftpartW = maxLeftSource * WinW / total
        local rightpartW = maxRightSource * WinW / total
        
        -- lets set some sensible limits to ensure titles should fit
        if leftpartW < WinW / 3 then
            leftpartW = WinW / 3
            rightpartW = WinW * 2/3
        elseif leftpartW > WinW * 2/3 then
            leftpartW = WinW * 2/3
            rightpartW = WinW / 3
        end
        
        local leftpartC = leftpartW / 2 -- set the midpoint for centre alignment
        local rightpartC = leftpartW + rightpartW / 2 -- set the midpoint for centre alignment
        return leftpartC, rightpartC 
    end

    local positions = {}
    local f1, f2, f3, f4 = fontHeightsList[1], fontHeightsList[2], fontHeightsList[3], fontHeightsList[4]

    if widget.layout == 0 then -- 1 value
        positions.value1 = {x = WinW/2, y = (WinH - f1 + 2 + titleFontHeight)/2, align = TEXT_CENTERED}
        
    elseif widget.layout == 1 then -- 2 values in 2 rows
        local topRowMaxHeight = f1
        local bottomRowMaxHeight = f2
        local y1, y2, y3, y4 = topbottomsplit(topRowMaxHeight, bottomRowMaxHeight)
        positions = {
            value1 = {x = WinW/2, y = y2, align = TEXT_CENTERED},  
            value2 = {x = WinW/2, y = y4, align = TEXT_CENTERED}
        }
        
        if showIndividualTitles then
            positions.title1 = {x = WinW/2, y = y1, align = TEXT_CENTERED}
            positions.title2 = {x = WinW/2, y = y3, align = TEXT_CENTERED}
        end
        
    elseif widget.layout == 2 then -- 2 values in 2 cols
        local x1, x2 = leftrightsplit(f1, f2)        
        local y2 = titleBufferLine + titleHeight + (WinH - titleBufferLine - titleHeight - f1) / 2
        local y4 = titleBufferLine + titleHeight + (WinH - titleBufferLine - titleHeight - f2) / 2  
  
        positions = {
            value1 = {x = x1, y = y2, align = TEXT_CENTERED},
            value2 = {x = x2, y = y4, align = TEXT_CENTERED}
        }

        if showIndividualTitles then
            positions.title1 = {x = x1, y = titleBufferLine, align = TEXT_CENTERED}
            positions.title2 = {x = x2, y = titleBufferLine, align = TEXT_CENTERED}
        end

    elseif widget.layout == 3 then -- 3 values in 2 rows (1 top center, 2 bottom)
        local x1, x2 = leftrightsplit(f2, f3)
        local topRowMaxHeight = f1
        local bottomRowMaxHeight = math.max(f2, f3)        
        local y1, y2, y3, y4 = topbottomsplit(topRowMaxHeight, bottomRowMaxHeight)
        
        positions = {
            value1 = {x = WinW/2, y = y2, align = TEXT_CENTERED},
            value2 = {x = x1, y = y4, align = TEXT_CENTERED},
            value3 = {x = x2, y = y4, align = TEXT_CENTERED}
        }
        
        if showIndividualTitles then
            positions.title1 = {x = WinW/2, y = y1, align = TEXT_CENTERED}
            positions.title2 = {x = x1, y = y3, align = TEXT_CENTERED}
            positions.title3 = {x = x2, y = y3, align = TEXT_CENTERED}
        end
        
    elseif widget.layout == 4 then -- 3 values in 2 cols (1 left, 2 right stacked)
        local x1, x2 = leftrightsplit(f1, math.max(f2,f3))
        local topRowMaxHeight = f2
        local bottomRowMaxHeight = f3
        local leftY = titleBufferLine + titleHeight + (WinH - titleBufferLine - titleHeight - f1) / 2        
        -- Right column uses topbottomsplit for the 2 stacked values
        local y1, y2, y3, y4 = topbottomsplit(topRowMaxHeight, bottomRowMaxHeight)
        
        positions = {
            value1 = {x = x1, y = leftY, align = TEXT_CENTERED},
            value2 = {x = x2, y = y2, align = TEXT_CENTERED},
            value3 = {x = x2, y = y4, align = TEXT_CENTERED}
        }
        
        if showIndividualTitles then
            positions.title1 = {x = x1, y = titleBufferLine, align = TEXT_CENTERED}
            positions.title2 = {x = x2, y = y1, align = TEXT_CENTERED}
            positions.title3 = {x = x2, y = y3, align = TEXT_CENTERED}
        end
        
    elseif widget.layout == 5 then -- 4 values (2x2 grid)
        local x1, x2 = leftrightsplit(math.max(f1, f3), math.max(f2, f4))
        local topRowMaxHeight = math.max(f1, f2)
        local bottomRowMaxHeight = math.max(f3, f4)
        local y1, y2, y3, y4 = topbottomsplit(topRowMaxHeight, bottomRowMaxHeight)
        
        positions = {
            value1 = {x = x1, y = y2, align = TEXT_CENTERED},
            value2 = {x = x2, y = y2, align = TEXT_CENTERED},
            value3 = {x = x1, y = y4, align = TEXT_CENTERED},
            value4 = {x = x2, y = y4, align = TEXT_CENTERED}
        }
        
        if showIndividualTitles then
            positions.title1 = {x = x1, y = y1, align = TEXT_CENTERED}
            positions.title2 = {x = x2, y = y1, align = TEXT_CENTERED}
            positions.title3 = {x = x1, y = y3, align = TEXT_CENTERED}
            positions.title4 = {x = x2, y = y3, align = TEXT_CENTERED}
        end

    elseif widget.layout == 6 then -- 2 values to left 2 rows titles to right
        local topRowMaxHeight = math.max(titleHeight,f1)
        local bottomRowMaxHeight = math.max(titleHeight,f2)
        local temptitleHeight = titleHeight  -- save it for a minute
        titleHeight = 0 -- not used in this calculation unless titles are larger than font, as titles are to right
        local y1, y2, y3, y4 = topbottomsplit(topRowMaxHeight, bottomRowMaxHeight)  -- y1, y3 currently meaningless
        titleHeight = temptitleHeight -- reassign
        -- calculate the vertical offset between value and titles so we can centre each correctly
        y1 = y2 + (f1 - titleHeight) /2 -- Assume font is larger than title so shift titles down a bit
        if titleHeight > f1 then y1, y2 = y2, y1 end  -- if titles larger than font then swap the offsets
        y3 = y4 + (f2 - titleHeight) /2 -- Assume font is larger than title so shift titles down a bit
        if titleHeight > f2 then y3, y4 = y4, y3 end  -- if titles larger than font then swap the offsets

        positions = {
            value1 = {x = WinW *3/8, y = y2, align = TEXT_CENTERED},  
            value2 = {x = WinW *3/8, y = y4, align = TEXT_CENTERED}
        }
        
        if showIndividualTitles then
            positions.title1 = {x = WinW *3/4, y = y1, align = TEXT_LEFT, multiline = true, sourceIndex = 1}
            positions.title2 = {x = WinW *3/4, y = y3, align = TEXT_LEFT, multiline = true, sourceIndex = 2}
        end
        
    end
    
    return positions
end

-- Helper function to recalculate layout for current window size
local function recalculateLayout(widget)
    local WinW, WinH = lcd.getWindowSize()
    
    -- Determine title display logic
    local showTitles = widget.titlefont ~= -1
    local titleFontHeight = showTitles and getFontHeight(widget.titlefont or FONT_S) or 0
    
    -- For now, assume individual titles for layout calculation (will be refined in paint)
    local showIndividualTitles = showTitles
    
    widget.layoutCache = {
        positions = calculateLayoutPositions(widget, showIndividualTitles),
        titleFontHeight = titleFontHeight,
        showTitles = showTitles,
        lastWinW = WinW,
        lastWinH = WinH,
        validCache = true
    }
end

-- ************************************************
-- ***        Configure widget                   ***
-- ************************************************
local function configure(widget)
    -- Set up color configuration
    updateWidgetColors(widget)
    
    local function invalidateAndRecalc() 
        widget.layoutCache.validCache = false
        widget.dataCache.validCache = false  -- Also invalidate data cache
        -- Recalculate immediately when configuration changes
        cacheSourceData(widget) -- This now includes title caching
        recalculateLayout(widget)
    end

    local line = form.addLine("Units on Title Line")
    form.addBooleanField(line, nil, function() return widget.titleunits end, 
        function(v) widget.titleunits = v; invalidateAndRecalc() end)

    local line = form.addLine("Display in Colour")
    form.addBooleanField(line, nil, function() return widget.ColourDisplay end, 
        function(v) 
            widget.ColourDisplay = v
            -- Update colors when ColourDisplay setting changes
            updateWidgetColors(widget)
            invalidateAndRecalc() 
        end)

    line = form.addLine("Select Layout")
    form.addChoiceField(line, nil, {
        {'1 value', 0}, {'2 values in 2 rows', 1}, {'2 values in 2 columns', 2},
        {'3 values in 2 rows', 3}, {'3 values in 2 columns', 4}, {'4 values', 5}, {'2 values to left', 6}
    }, function() return widget.layout end, function(v) widget.layout = v; invalidateAndRecalc() end)

    local titleFontChoices = {
        {'OFF', -1}, {'L', FONT_L}, {'STD', FONT_STD}, {'S', FONT_S}, {'XS', FONT_XS}, {'XXS', FONT_XXS},
        {'L_BOLD', FONT_L_BOLD}, {'S_BOLD', FONT_S_BOLD}, {'XS_BOLD', FONT_XS_BOLD}
    }
    local valueFontChoices = {
        {'XXL', FONT_XXL}, {'XL', FONT_XL}, {'L', FONT_L}, {'STD', FONT_STD}, {'S', FONT_S},
        {'XS', FONT_XS}, {'XXS', FONT_XXS}, {'L_BOLD', FONT_L_BOLD}, 
        {'S_BOLD', FONT_S_BOLD}, {'XS_BOLD', FONT_XS_BOLD}
    }

    line = form.addLine("Font size for Title")
    form.addChoiceField(line, nil, titleFontChoices,
        function() return widget.titlefont end, function(v) widget.titlefont = v; invalidateAndRecalc() end)

    for i = 1, 4 do  -- Display source and font selection for up to 4 sources
        line = form.addLine("Source"..i)
        form.addSourceField(line, nil,
            function() return widget["source"..i] end,
            function(v) 
                widget["source"..i] = v 
                cacheSourceData(widget) -- Cache when source changes
                widget.dataCache.validCache = false  -- Invalidate data cache too
            end)
        
        line = form.addLine("Font size for Source"..i)
        form.addChoiceField(line, nil, valueFontChoices,
            function() return widget["font"..i] end,
            function(v) widget["font"..i] = v; invalidateAndRecalc() end)
    end
    
    -- Initial caching and layout calculation
    cacheSourceData(widget)
    recalculateLayout(widget)
end

-- ************************************************
-- ***          Startup handler                  ***
-- ************************************************
local function create()
    local widget = { 
        layoutCache = { validCache = false },
        dataCache = { validCache = false },  -- New data cache
        layout = 0,  -- Default to 1-value layout
        titlefont = FONT_S,  -- Default title font
        titleunits = false,  -- Default units behavior
        ColourDisplay = false,  -- Default color display setting
        oldTime = 0,
        font1 = FONT_L, font2 = FONT_L, font3 = FONT_L, font4 = FONT_L  -- Default value fonts
    }
    -- Set initial colors
    updateWidgetColors(widget)
    -- Initialize cache immediately to prevent nil access
    cacheSourceData(widget)
    return widget
end

-- ************************************************
-- ***   Time formatting functions               ***
-- ************************************************
local function formatTime(seconds)
    if not seconds or seconds < 0 then return "---" end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    return string.format("%d:%02d:%02d", hours, mins, secs)
end

local function formatClock()
    local t = os.date("*t")
    return t and string.format("%02d:%02d:%02d", t.hour or 0, t.min or 0, t.sec or 0) or "00:00:00"
end

local function isTimeSource(source)
    if not source then return false end
    local name = string.lower(source:name() or "")
    if string.find(name, "clock") or string.find(name, "time") then return "clock" end
    if source:category() == CATEGORY_TIMER then return "timer" end
    return false
end

-- ************************************************
-- ***   Get source values                      ***
-- ************************************************
local function getsourcevalues(source, decimals, widget)
    if not source then return "---", widget.InactiveColour end
    
    local value = source:value()
    local state = source:state()

    local timeType = isTimeSource(source)
    if timeType == "clock" then
        value = formatClock()
    elseif timeType == "timer" and value then
        value = formatTime(value)
        state = true  -- force to be true as Ethos marks it as false
    else
        if value and decimals and decimals >= 0 then
            value = string.format("%."..decimals.."f", value)
        else
            value = value and tostring(value) or "---"
        end
    end

    return tostring(value or "---"), state == false and widget.InactiveColour or widget.ActiveColour
end

-- Simplified processDisplayData function - just gets values and uses cached title data
local function processDisplayData(widget)
    local WinW, WinH = lcd.getWindowSize()
    
    -- Only recalculate layout if window size changed
    if not widget.layoutCache.validCache or 
       widget.layoutCache.lastWinW ~= WinW or 
       widget.layoutCache.lastWinH ~= WinH then
        recalculateLayout(widget)
    end
    
    -- Update title color if dark mode changed
    local currentTitleColor = getTitleColor()
    if widget.titleCache and widget.titleCache.titleColor ~= currentTitleColor then
        widget.titleCache.titleColor = currentTitleColor
    end
    
    -- Update widget colors if dark mode changed (for non-ColourDisplay mode)
    if not widget.ColourDisplay then
        local expectedActiveColor = lcd.darkMode() and COLOR_WHITE or COLOR_BLACK
        if widget.ActiveColour ~= expectedActiveColor then
            updateWidgetColors(widget)
        end
    end
    
    -- Check if layout changed and recache title data if needed
    if widget.titleCache and widget.titleCache.cachedLayout ~= widget.layout then
        cacheTitleDisplayData(widget)
    end
    
    -- Get dynamic values (this is the only part that changes frequently)
    local values = {}
    local colors = {}
    
    for i = 1, 4 do
        if widget.cachedSources and widget.cachedSources[i] then
            values[i], colors[i] = getsourcevalues(widget.cachedSources[i], widget.cachedDecimals[i], widget)
        else
            values[i] = "---"
            colors[i] = widget.InactiveColour
        end
    end
    
    -- Get cached title data for current layout
    local titleData = widget.titleCache and widget.titleCache.data
    if not titleData then return end -- Safety check
    
    -- Handle unit display using cached data
    local function appendUnits(value, unit)
        return (value ~= "---" and unit and unit ~= "") and (value .. unit) or value
    end
    
    -- Use pre-computed title display texts
    local displaySourceTexts
    if titleData.showUnifiedTitle then
        displaySourceTexts = titleData.displaySourceTexts
        if not (widget.titleunits and titleData.allSameUnits) then
            for i = 1, titleData.sourceCount do 
                values[i] = appendUnits(values[i], widget.cachedUnits[i]) 
            end
        end
    elseif titleData.showIndividualTitles then
        if widget.titleunits then
            displaySourceTexts = titleData.displaySourceTextsWithUnits
        else
            displaySourceTexts = titleData.displaySourceTexts
            for i = 1, titleData.sourceCount do 
                values[i] = appendUnits(values[i], widget.cachedUnits[i]) 
            end
        end
    else
        displaySourceTexts = titleData.displaySourceTexts
        for i = 1, titleData.sourceCount do 
            values[i] = appendUnits(values[i], widget.cachedUnits[i]) 
        end
    end
    
    -- Cache all processed display data with pre-computed title information
    widget.dataCache = {
        validCache = true,
        values = values,
        colors = colors,
        -- Use cached title data
        titleData = titleData,
        displaySourceTexts = displaySourceTexts,
        positions = widget.layoutCache.positions,
        -- Pre-select multiline positions for layout 6
        multilinePositions = (widget.layout == 6 and titleData.multilinePositions) and 
            (function()
                local positions = {}
                for i = 1, titleData.sourceCount do
                    positions[i] = widget.titleunits and 
                        titleData.multilinePositions[i].withUnits or 
                        titleData.multilinePositions[i].normal
                end
                return positions
            end)() or nil
    }
end

-- Ultra-simplified paint function using cached title data
local function paint(widget)
    if not widget.dataCache or not widget.dataCache.validCache then return end
    
    local cache = widget.dataCache
    local titleData = cache.titleData
    local WinW, WinH = lcd.getWindowSize()

    
    -- Draw unified title using cached data
    if titleData.showUnifiedTitle and widget.layoutCache.showTitles then
        local titleText = widget.titleunits and titleData.allSameUnits and 
                         titleData.unifiedTitleWithUnits or titleData.unifiedTitle
        lcd.color(widget.titleCache.titleColor)
        setFont(widget.titlefont or FONT_S)
        lcd.drawText(WinW / 2, 2, titleText, TEXT_CENTERED)
    elseif not titleData.foundValidNames and widget.layoutCache.showTitles then
        lcd.color(widget.titleCache.titleColor)
        setFont(widget.titlefont or FONT_S)
        lcd.drawText(WinW / 2, 2, "No Source Defined", TEXT_CENTERED)
    end

    -- Draw values and individual titles using cached data 
    for i = 1, titleData.sourceCount do
        -- Individual titles - ensure grey color is set for each title
        if cache.positions["title"..i] and titleData.showIndividualTitles then
            local titlePos = cache.positions["title"..i]
            lcd.color(widget.titleCache.titleColor)  -- One colour for all titles in loop
            if titlePos.multiline and widget.layout == 6 and cache.multilinePositions then
                -- Use pre-computed multiline positions - no calculation needed!
                local precomputedLines = cache.multilinePositions[i]
                for _, lineData in ipairs(precomputedLines) do
                    setFont(widget.titlefont or FONT_S)
                    lcd.drawText(titlePos.x + lineData.offsetX, titlePos.y + lineData.offsetY, 
                               lineData.text, titlePos.align)
                end
            else
                setFont(widget.titlefont or FONT_S)
                lcd.drawText(titlePos.x, titlePos.y, cache.displaySourceTexts[i], titlePos.align)
            end
        end
        
        -- Values - these use source colors
        if cache.positions["value"..i] then
            lcd.color(cache.colors[i])
            setFont(widget["font"..i] or FONT_L)
            lcd.drawText(cache.positions["value"..i].x, cache.positions["value"..i].y, cache.values[i], cache.positions["value"..i].align)
        end
    end
end

-- ************************************************
-- ***         Storage functions                 ***
-- ************************************************
local function read(widget)
    widget.source1 = storage.read("source1")
    widget.source2 = storage.read("source2")
    widget.source3 = storage.read("source3")
    widget.source4 = storage.read("source4")
    widget.font1 = storage.read("font1") or FONT_L
    widget.font2 = storage.read("font2") or FONT_L
    widget.font3 = storage.read("font3") or FONT_L
    widget.font4 = storage.read("font4") or FONT_L
    widget.titlefont = storage.read("titlefont") or FONT_S
    widget.titleunits = storage.read("titleunits")
    widget.layout = storage.read("layout") or 0
    widget.ColourDisplay = storage.read("ColourDisplay") or false
    widget.layoutCache = { validCache = false }
    widget.dataCache = { validCache = false }
    
    -- Set colors based on stored ColourDisplay setting
    updateWidgetColors(widget)
    
    -- Initialize all cached data
    cacheSourceData(widget)
end

local function write(widget)
    local keys = {"source1", "source2", "source3", "source4", "font1", "font2", "font3", "font4", "titlefont", "titleunits", "layout", "ColourDisplay"}
    for _, key in ipairs(keys) do storage.write(key, widget[key]) end
end

-- ************************************************
-- ***		     "background loop" (enhanced)	*** 
-- ************************************************
-- Process all data here, only refresh at ~1Hz to reduce load

local function wakeup(widget)
    if os.time() - widget.oldTime > 0.9 then  
        widget.oldTime = os.time()
        -- Process all display data 
        processDisplayData(widget)        
        -- Set the screen for updating
        lcd.invalidate()   
    end
end

local function event(widget, category, value, x, y) end

local function init()
    system.registerWidget({
        key = "layouts", name = "Widget Layouts", create = create, wakeup = wakeup,
        paint = paint, configure = configure, read = read, write = write,
        event = event, title = false
    })
end

return { init = init }
