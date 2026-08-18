-- GFonts - kills duplicate font creation on clients
-- ** WARNING: dont rename this file (!!!!!0_gfonts.lua), it has to load first! **

if SERVER then return end -- Dont let server load it

-- Prevent double loading or lua refresh
if _G.__GFonts_Loaded then return end
_G.__GFonts_Loaded = true

-- Merges sizes that are close together, less fonts but text can end up a pixel
-- or two off. -1 = off, 0 = tiered (exact under 16, 2px to 40, 4px above),
-- anything above 0 = snap to that step
local SNAP = -1

-- Only build a font when something first draws with it instead of at load.
-- Huge if your addons make sizes they never use, but anything that reaches the
-- engine without going through our hooks will error. if anything errors, set to LAZY = false
local LAZY = true

local _CreateFont, _SetFont = surface.CreateFont, surface.SetFont
local format, floor = string.format, math.floor

local function snapSize(s)
	if SNAP > 0 then return SNAP * floor(s / SNAP + 0.5) end
	if s < 16 then return floor(s + 0.5) end
	if s <= 40 then return 2 * floor(s / 2 + 0.5) end
	return 4 * floor(s / 4 + 0.5)
end

local resolve = {} -- font name -> the font it really uses
local owner   = {} -- properties -> the font holding them
local waiting = LAZY and {} or nil -- fonts we havent built yet
local private = 0

-- Works out what font to actually use, and builds it now if we put it off.
-- The waiting check is free with LAZY off, its just a nil upvalue
local function use(name)
	local real = resolve[name] or name

	if waiting then
		local data = waiting[real]

		if data then
			waiting[real] = nil
			_CreateFont(real, data)
		end
	end

	return real
end

local function keyOf(d)
	local size = tonumber(d.size) or 13
	if SNAP >= 0 then size = snapSize(size) end

	return format("%s|%s|%s|%s|%s|%d%d%d%d%d%d%d%d%d%d",
		d.font or "Arial", size, tonumber(d.weight) or 500,
		tonumber(d.blursize) or 0, tonumber(d.scanlines) or 0,
		(d.antialias == nil or d.antialias) and 1 or 0, -- this one defaults true
		d.extended and 1 or 0, d.underline and 1 or 0, d.italic  and 1 or 0,
		d.strikeout and 1 or 0, d.symbol and 1 or 0, d.rotary  and 1 or 0,
		d.shadow and 1 or 0, d.additive and 1 or 0, d.outline and 1 or 0)
end

function surface.CreateFont(name, data)
	if type(name) ~= "string" or type(data) ~= "table" then
		return _CreateFont(name, data) -- let the engine complain about it
	end

	local key = keyOf(data)
	local real = owner[key]

	if not real then
		if resolve[name] then
			private = private + 1
			real = "gfonts::" .. private
		else
			real = name
		end

		owner[key] = real

		if waiting then
			-- Our own copy, addons love reusing the same table
			local mine = {}
			for k, v in pairs(data) do mine[k] = v end
			waiting[real] = mine
		else
			_CreateFont(real, data)
		end
	end

	resolve[name] = real
end

function surface.SetFont(name)
	return _SetFont(use(name))
end

-- DLabel:SetFont, RichText and the rest of the friends all end up here
local function hookPanels()
	local meta = FindMetaTable("Panel")
	if not meta or not meta.SetFontInternal then return false end

	local _SetFontInternal = meta.SetFontInternal

	function meta:SetFontInternal(name, ...)
		return _SetFontInternal(self, use(name), ...)
	end

	return true
end

if not hookPanels() then
	hook.Add("Initialize", "GFonts", function() hookPanels() end)
end

concommand.Add("gfonts_status", function()
	local names, real = table.Count(resolve), table.Count(owner)
	local held = waiting and table.Count(waiting) or 0

	MsgN(format("[GFonts] %d names, %d fonts (%d built, %d not needed yet), %d saved",
		names, real, real - held, held, names - real))
end)
