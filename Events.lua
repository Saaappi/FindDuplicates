--[[
	These variables are provided to the addon by Blizzard.
		addonName	: This is self explanatory, but it's the name of the addon, in this case, FindDuplicates.
		t			: This is an empty table. This is how the addon can communicate between files or local functions, sort of like traditional classes.
]]--
local addonName, t = ...;

local events = { -- An integer-indexed array of the events that should be registered to the addon's ScriptHandler.
	"ADDON_LOADED",
};

t.events = events; -- Add the events array to the table, t, to be used in FindDuplicates.lua.