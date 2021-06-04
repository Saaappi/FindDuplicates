--[[
	The purpose of the addon is to 'quickly' identify duplicate items in the player's inventory, personal bank, and guild bank.
	Never deviate from this vision!
]]--

--[[ TODO
	- Fix the bug that doesn't mark all duped items..
]]--

--[[
	These variables are provided to the addon by Blizzard.
		addonName	: This is self explanatory, but it's the name of the addon, in this case, FindDuplicates.
		t			: This is an empty table. This is how the addon can communicate between files or local functions, sort of like traditional classes.
]]--
local addonName, t = ...;
local e = CreateFrame("Frame"); -- This is the invisible frame that will listen for registered events.
local glowTimer = 5; -- The duration in seconds to make the slot glow.
local GUILD_BANK_MAX_TABS = 8;
local GUILD_BANK_MAX_SLOTS = 98;
local VOID_STORAGE_MAX_TABS = 2;
local bags = {};
local frames = {
	[-1] = "BankFrameItem",
	[0] = "ContainerFrame1Item",
	[1] = "ContainerFrame2Item",
	[2] = "ContainerFrame3Item",
	[3] = "ContainerFrame4Item",
	[4] = "ContainerFrame5Item",
	[5] = "ContainerFrame6Item",
	[6] = "ContainerFrame7Item",
	[7] = "ContainerFrame8Item",
	[8] = "ContainerFrame9Item",
	[9] = "ContainerFrame10Item",
	[10] = "ContainerFrame11Item",
	[11] = "ContainerFrame12Item",
};
local bagConfigurationTable = {};

-- Loop over the t.events array from the Events.lua file and register each event to the ScriptHandler.
for _, event in ipairs(t.events) do
	e:RegisterEvent(event);
end

-- Functions
local function FindDuplicates(tbl)
	for i, bagData in ipairs(tbl) do
		for j, value in pairs(bagData) do
			if j == "itemID" then
				t.duplicatedItems[value] = { bag = value["bag"], slot = value["slot"] };
			end
		end
	end
	return t.duplicatedItems;
end

local function Contains(set, value) -- Check if the provided table contains the provided value.
	for i, j in ipairs(set) do
		if value == j then
			return true;
		end
	end
end

local function ContainsReturnValue(set, value) -- Check if the provided table contains the provided value.
	for i, j in pairs(set) do
		if value == i then
			return j;
		end
	end
end

local function FindFrameSlotID(set, bag, slot)
	for i = 1, #set, 1 do
		if set[i]["bag"] == bag and set[i]["slot"] == slot then
			return set[i]["frame"];
		end
	end
end

local function BuildBagTable()
	for bag = 0, 11, 1 do
		local numContainerSlots = GetContainerNumSlots(bag);
		for i = 1, numContainerSlots, 1 do
			for j = numContainerSlots, 1, -1 do
				table.insert(bags, { bag = bag, slot = i, frame = j});
				numContainerSlots = numContainerSlots - 1;
				break
			end
		end
	end
	FindDuplicatesPerCharacterDatabase = bags;
end

-- Slash commands
SLASH_FindDuplicates1 = "/fd";
SLASH_FindDuplicates2 = "/findduplicates";
SlashCmdList["FindDuplicates"] = function(command, editbox)
	local _, _, command, arguments = string.find(command, "%s?(%w+)%s?(.*)"); -- Using pattern matching the addon will be able to interpret subcommands.
	if not command or command == "" then
		-- Player Inventory / Bank
		if BankSlotsFrame:IsVisible() then -- The player's personal bank is open.
			for bag = -1, -1, 1 do -- The main bank window has a bag ID of -1.
				for slot = 28, 1, -1 do -- The main bank window can only have 28 slots.
					local itemID = GetContainerItemID(bag, slot);
					local _, _, _, itemQuality = GetContainerItemInfo(bag, slot);
					if itemID ~= nil and itemQuality > 0 then -- If itemID isn't nil and the item's quality is higher than Poor.
						local _, _, _, _, _, itemType = GetItemInfo(itemID);
						if not Contains(t.itemTypes, itemType) then -- Only add the item information if the item type isn't in the ignored item type list.
							table.insert(t.items, { itemID = itemID, bag = bag, slot = slot }); -- Insert the itemID into a table for review.
						end
					end
				end
			end
		end
		for bag = 0, 11, 1 do -- A player can have their inventory, 4 extra bags for their inventory, and then up to 7 bank slots.
			for slot = GetContainerNumSlots(bag), 1, -1 do -- Start at the last slot in the bag and work backward to the first slot. The decrementer is -1.
				local itemID = GetContainerItemID(bag, slot);
				local _, _, _, itemQuality = GetContainerItemInfo(bag, slot);
				if itemID ~= nil and itemQuality > 0 then -- If itemID isn't nil and the item's quality is higher than Poor.
					local _, _, _, _, _, itemType = GetItemInfo(itemID); -- We want the itemType to ignore Tradeskill items (cloth, leather, etc...)
					if not Contains(t.itemTypes, itemType) then -- Only add the item information if the item type isn't in the ignored item type list.
						table.insert(t.items, { itemID = itemID, bag = bag, slot = slot }); -- Insert the itemID into a table for review.
					end
				end
			end
		end
		-- Guild Bank
		for tab = 1, GUILD_BANK_MAX_TABS, 1 do
			for slot = GUILD_BANK_MAX_SLOTS, 1, -1 do
				local _, _, _, _, itemQuality = GetGuildBankItemInfo(tab, slot);
				local itemLink = GetGuildBankItemLink(tab, slot);
				if itemLink ~= nil and itemQuality > 0 then
					local itemID, itemType = GetItemInfoInstant(itemLink);
					if itemID ~= nil then
						if not Contains(t.itemTypes, itemType) then
							table.insert(t.items, { itemID = itemID, bag = tab, slot = slot }); -- Insert the itemID into a table for review.
						end
					end
				end
			end
		end
		for key, value in pairs(FindDuplicates(t.items)) do
			for k, _ in pairs(value) do
				local frame = ContainsReturnValue(frames, value["bag"]);
				if frame then
					if value["bag"] == -1 then -- This is the player's bank.
						ActionButton_ShowOverlayGlow(_G[frame..value["slot"]]);
						C_Timer.After(0, function()
							C_Timer.After(glowTimer, function()
								ActionButton_HideOverlayGlow(_G[frame..value["slot"]]);
							end);
						end);
					elseif value["bag"] >= 0 then -- These are all the extra bags they can have in their bank.
						local frameSlotID = FindFrameSlotID(bags, value["bag"], value["slot"]);
						ActionButton_ShowOverlayGlow(_G[frame..frameSlotID]);
						C_Timer.After(0, function()
							C_Timer.After(glowTimer, function()
								ActionButton_HideOverlayGlow(_G[frame..frameSlotID]);
							end);
						end);
					end
				end
			end
		end
		-- Wipe all of the tables.
		t.items = {};
		t.duplicatedItems = {};
	elseif command == "build" then
		BuildBagTable();
	end
end

e:SetScript("OnEvent", function(self, event, ...) -- This adds an 'OnEvent' ScriptHandler to the frame to listen for events, and then call a function.
	if event == "ADDON_LOADED" then
		local name = ...; -- The name of the addon loaded. This won't necessarily be our addon.
		if name == addonName then -- Check to see if the currently loaded addon is ours.
			local items = {}; -- Empty table to hold item IDs.
			local duplicatedItems = {}; -- Empty table to hold duplicated item IDs.
			t.items = items; -- Add the items array to the table, t.
			t.duplicatedItems = duplicatedItems; -- Add the duplicatedItems array to the table, t.

			if FindDuplicatesPerCharacterDatabase == nil then -- To fix the nil error on login for new characters.
				FindDuplicatesPerCharacterDatabase = {};
			end
			
			if next(FindDuplicatesPerCharacterDatabase) == nil then
				print(addonName .. ": Please run /fd build to make your bag table. This should be executed with your bank open.");
			else
				bags = FindDuplicatesPerCharacterDatabase;
			end
		end
	end
end);