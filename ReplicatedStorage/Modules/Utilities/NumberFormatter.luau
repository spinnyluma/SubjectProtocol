--[[
    NumberFormatter Module v2.0
    
    A utility module for automatically converting large numerical values into 
    compact, readable formats across your game with improved performance and flexibility.
]]

local NumberFormatter = {}
NumberFormatter.__index = NumberFormatter

-- Configuration
local DEFAULT_CONFIG = {
    suffixes = {
        [1] = "",
        [2] = "K",
        [3] = "M",
        [4] = "B",
        [5] = "T",
        [6] = "Qa",
        [7] = "Qi",
        [8] = "Sx",
        [9] = "Sp",
        [10] = "Oc",
        [11] = "No",
        [12] = "Dc",
    },
    decimalPlaces = 1,
    useCommas = false,
    formatThreshold = 1000,
    liveUpdate = true,
    updateInterval = 0.5,
    -- New configuration options
    localization = "US", -- "US" uses commas, "EU" uses periods
    whitelistedTags = {}, -- Tags for UI elements that should be formatted
    blacklistedTags = {}, -- Tags for UI elements that should NOT be formatted
    includeTextBox = false, -- Whether to format TextBox elements
    throttlePlayerUpdates = true, -- Enable throttling for player updates
    playerUpdateChunkSize = 5, -- Number of players to update per interval when throttling
    customFormatFunc = nil, -- Custom formatting function (number) -> string
}

-- Private functions
local function roundToDecimalPlace(num, decimalPlaces)
    local mult = 10 ^ decimalPlaces
    return math.floor(num * mult + 0.5) / mult
end

local function addCommas(numString, localization)
    local formatted = numString
    local k = 0

    if localization == "US" then
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
            if k == 0 then
                break
            end
        end
    elseif localization == "EU" then
        -- Replace decimal point with temporary marker
        formatted = string.gsub(formatted, "%.", "##DECIMAL##")

        -- Add thousand separators (periods)
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1.%2")
            if k == 0 then
                break
            end
        end

        -- Restore decimal point (comma)
        formatted = string.gsub(formatted, "##DECIMAL##", ",")
    end

    return formatted
end

local function isNumber(str)
    return tonumber(str) ~= nil
end

local function shouldProcessElement(element, config)
    -- Skip if element doesn't match the required types
    local validTypes = {
        ["TextLabel"] = true,
        ["TextButton"] = true,
    }

    if config.includeTextBox then
        validTypes["TextBox"] = true
    end

    if not validTypes[element.ClassName] then
        return false
    end

    -- Check for blacklisted tags
    for _, tag in ipairs(config.blacklistedTags) do
        if element:HasTag(tag) then
            return false
        end
    end

    -- If whitelist exists, only process elements with those tags
    if #config.whitelistedTags > 0 then
        for _, tag in ipairs(config.whitelistedTags) do
            if element:HasTag(tag) then
                return true
            end
        end
        return false
    end

    return true
end

-- Format a single number based on the config
function NumberFormatter:formatNumber(number)
    -- Custom formatting function takes precedence if provided
    if self.config.customFormatFunc and type(self.config.customFormatFunc) == "function" then
        local success, result = pcall(self.config.customFormatFunc, number)
        if success then
            return result
        end
        -- If custom function fails, fall back to default formatting
        warn("Custom format function failed. Falling back to default formatting.")
    end

    if type(number) ~= "number" then
        if type(number) == "string" and isNumber(number) then
            number = tonumber(number)
        else
            return number
        end
    end

    -- Handle special cases
    if number ~= number then -- NaN check
        return "NaN"
    elseif number == math.huge then
        return "∞"
    elseif number == -math.huge then
        return "-∞"
    end

    -- Don't format small numbers below threshold
    if math.abs(number) < self.config.formatThreshold then
        if self.config.useCommas then
            return addCommas(tostring(number), self.config.localization)
        end
        return tostring(number)
    end

    local negative = number < 0
    number = math.abs(number)

    local suffixIndex = 1
    while number >= 1000 and suffixIndex < #self.config.suffixes do
        suffixIndex = suffixIndex + 1
        number = number / 1000
    end

    local formatted = roundToDecimalPlace(number, self.config.decimalPlaces)

    local formattedStr = tostring(formatted)
    if self.config.decimalPlaces > 0 then
        formattedStr = string.gsub(formattedStr, "%.0+$", "")
    end

    formattedStr = formattedStr .. self.config.suffixes[suffixIndex]

    if negative then
        formattedStr = "-" .. formattedStr
    end

    return formattedStr
end

-- Process UI elements to format their text
function NumberFormatter:processUIElement(element)
    if not shouldProcessElement(element, self.config) then
        return
    end

    -- Use pcall to prevent errors from breaking the formatter
    local success, _ = pcall(function()
        local text = element.Text
        if isNumber(text) then
            element.Text = self:formatNumber(tonumber(text))
        end
    end)

    if not success then
        -- Silent failure - don't disrupt the game if an element can't be processed
    end
end

-- Process all UI elements in a given parent
function NumberFormatter:processUIContainer(parent)
    local descendants = parent:GetDescendants()

    -- Process in chunks to avoid frame drops in large UIs
    local chunkSize = 50
    for i = 1, #descendants, chunkSize do
        local endIndex = math.min(i + chunkSize - 1, #descendants)

        for j = i, endIndex do
            self:processUIElement(descendants[j])
        end

        -- Yield to prevent freezing
        if endIndex < #descendants then
            task.wait()
        end
    end
end

-- Process leaderstats for a player
function NumberFormatter:processLeaderstats(player)
    if not player or not player:IsA("Player") then
        return
    end

    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        return
    end

    for _, stat in ipairs(leaderstats:GetChildren()) do
        if stat:IsA("IntValue") or stat:IsA("NumberValue") then
            local textLabel = stat:FindFirstChild("FormattedValue")
            if not textLabel then
                textLabel = Instance.new("StringValue")
                textLabel.Name = "FormattedValue"
                textLabel.Parent = stat
            end
            textLabel.Value = self:formatNumber(stat.Value)
        end
    end
end

-- Throttled player processing
function NumberFormatter:processPlayersThrottled()
    local players = game.Players:GetPlayers()
    local chunkSize = self.config.playerUpdateChunkSize

    -- Process players in chunks
    for i = 1, #players, chunkSize do
        local endIndex = math.min(i + chunkSize - 1, #players)

        for j = i, endIndex do
            self:processLeaderstats(players[j])
        end

        -- Only yield if there are more players to process
        if endIndex < #players and chunkSize < #players then
            task.wait(0.03) -- Small delay between chunks
        end
    end
end

-- Start live updating for UI elements
function NumberFormatter:startLiveUpdate(parent)
    if not self.config.liveUpdate then
        return
    end

    if self._updateConnection then
        self._updateConnection:Disconnect()
    end

    -- Cache active GUIs to improve performance
    self._activeGuis = {}

    -- Track when we last updated players
    self._lastPlayerUpdate = 0

    self._updateConnection = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
        self._timeSinceLastUpdate = (self._timeSinceLastUpdate or 0) + deltaTime
        self._lastPlayerUpdate = self._lastPlayerUpdate + deltaTime

        if self._timeSinceLastUpdate >= self.config.updateInterval then
            self._timeSinceLastUpdate = 0

            -- If specific parent is provided, only update that
            if parent then
                self:processUIContainer(parent)
            else
                -- Update player GUIs if they exist
                for player, gui in pairs(self._activeGuis) do
                    if player.Parent and gui.Parent then
                        self:processUIContainer(gui)
                    else
                        -- Clean up disconnected players/GUIs
                        self._activeGuis[player] = nil
                    end
                end
            end

            -- Process players less frequently if throttling is enabled
            if self.config.throttlePlayerUpdates then
                -- Only update players every 3 intervals
                if self._lastPlayerUpdate >= (self.config.updateInterval * 3) then
                    self._lastPlayerUpdate = 0
                    self:processPlayersThrottled()
                end
            else
                -- Update all players every interval
                for _, player in ipairs(game.Players:GetPlayers()) do
                    self:processLeaderstats(player)
                end
            end
        end
    end)

    -- Track player GUI additions
    self._playerGuiAddedConnection = game.Players.PlayerAdded:Connect(function(player)
        -- Wait for PlayerGui to be available
        player:WaitForChild("PlayerGui", 5)
        if player.PlayerGui then
            self._activeGuis[player] = player.PlayerGui
        end
    end)

    -- Initialize active GUIs
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.PlayerGui then
            self._activeGuis[player] = player.PlayerGui
        end
    end
end

-- Stop live updating
function NumberFormatter:stopLiveUpdate()
    if self._updateConnection then
        self._updateConnection:Disconnect()
        self._updateConnection = nil
    end

    if self._playerGuiAddedConnection then
        self._playerGuiAddedConnection:Disconnect()
        self._playerGuiAddedConnection = nil
    end

    self._activeGuis = {}
end

-- Tag a UI element for formatting
function NumberFormatter:tagForFormatting(element, tag)
    if not tag then
        tag = "NumberFormat"
    end

    element:AddTag(tag)

    -- Add tag to whitelist if not already present
    local found = false
    for _, existingTag in ipairs(self.config.whitelistedTags) do
        if existingTag == tag then
            found = true
            break
        end
    end

    if not found then
        table.insert(self.config.whitelistedTags, tag)
    end

    -- Process the element immediately
    self:processUIElement(element)

    return element
end

-- Initialize the module with custom config
function NumberFormatter.new(customConfig)
    local self = setmetatable({}, NumberFormatter)

    -- Merge default config with custom config
    self.config = table.clone(DEFAULT_CONFIG)
    if customConfig then
        for key, value in pairs(customConfig) do
            self.config[key] = value
        end
    end

    -- Initialize live updates if enabled
    if self.config.liveUpdate then
        self:startLiveUpdate()
    end

    -- Cache for debouncing UI updates
    self._updateCache = {}
    self._activeGuis = {}

    return self
end

-- Apply formatting to the entire game UI with optimizations
function NumberFormatter:applyToGame()
    -- Format UI elements for new players
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            self:processLeaderstats(player)
        end)

        -- Wait for PlayerGui to be available
        player:WaitForChild("PlayerGui", 5)
        if player.PlayerGui then
            self._activeGuis[player] = player.PlayerGui

            -- Process initial UI
            self:processUIContainer(player.PlayerGui)

            -- Set up efficient descendant tracking
            local debounce = false
            player.PlayerGui.DescendantAdded:Connect(function(descendant)
                -- Use debounce to batch process UI changes
                if not debounce then
                    debounce = true
                    task.delay(0.1, function()
                        debounce = false
                        -- Only process elements that should be formatted
                        if shouldProcessElement(descendant, self.config) then
                            self:processUIElement(descendant)
                        end
                    end)
                end
            end)
        end

        -- Handle player removal
        player.AncestryChanged:Connect(function(_, parent)
            if not parent then
                self._activeGuis[player] = nil
            end
        end)
    end)

    -- Format existing players
    for _, player in ipairs(game.Players:GetPlayers()) do
        self:processLeaderstats(player)

        if player.PlayerGui then
            self._activeGuis[player] = player.PlayerGui
            self:processUIContainer(player.PlayerGui)

            -- Set up efficient descendant tracking
            local debounce = false
            player.PlayerGui.DescendantAdded:Connect(function(descendant)
                if not debounce then
                    debounce = true
                    task.delay(0.1, function()
                        debounce = false
                        if shouldProcessElement(descendant, self.config) then
                            self:processUIElement(descendant)
                        end
                    end)
                end
            end)
        end
    end

    -- Start live updates if enabled
    if self.config.liveUpdate then
        self:startLiveUpdate()
    end
end

return NumberFormatter