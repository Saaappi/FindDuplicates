--[[
	These variables are provided to the addon by Blizzard.
		addonName	: This is self explanatory, but it's the name of the addon, in this case, FindDuplicates.
		t			: This is an empty table. This is how the addon can communicate between files or local functions, sort of like traditional classes.
]]--
local addonName, t = ...;

local itemTypes = { -- An integer-indexed array of the item types that should be ignored.
	"Consumable",
	"Miscellaneous",
	"Quest",
	"Reagent",
	"Tradeskill",
	"WoW Token",
};

t.itemTypes = itemTypes; -- Add the itemTypes array to the table, t, to be used in FindDuplicates.lua.