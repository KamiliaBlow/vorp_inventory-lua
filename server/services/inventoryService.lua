---@diagnostic disable: undefined-global
InventoryService = {}
ItemPickUps = {}
MoneyPickUps = {}
GoldPickUps = {}
Core = {}

local newchar = {} -- new
local timer = 120  -- in minutes


Citizen.CreateThread(function()
	TriggerEvent("getCore", function(core)
		Core = core;
	end)
end)


RegisterServerEvent("syn:stopscene")
AddEventHandler("syn:stopscene", function(x) -- new
	local _source = source
	TriggerClientEvent("inv:dropstatus", _source, x)
end)

AddEventHandler('vorp_NewCharacter', function(source) -- new
	local _source = source
	local Character = Core.getUser(_source).getUsedCharacter
	local charid = Character.charIdentifier
	table.insert(newchar, charid)
	Wait(timer * 60000) -- waiting time is in minutes so 120 minutes = 2 hours until player can give or drop
	for k, v in pairs(newchar) do
		if v == charid then
			table.remove(newchar, k)
		end
	end
end)

contains = function(table, element) -- new
	for k, v in pairs(table) do
		if v == element then
			return true
		end
	end
	return false
end

InventoryService.UseItem = function(itemName, itemId, args)
	local _source = source

	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = UsersInventories["default"][identifier]

	if type(itemName) ~= "string" then
		print("[^2UseItem^7] ^1Error^7: Item name is not a string.")
		return
	end

	local svItem = svItems[itemName]

	if not svItem then
		print("[^2UseItem^7] ^1Error^7: Item [^3" .. tostring(itemName) .. "^7] does not exist in DB.")
		return
	end

	if UsableItemsFunctions[itemName] and userInventory[itemId] then
		local item = userInventory[itemId]
		if item then
			local itemArgs = json.decode(json.encode(svItem))
			itemArgs.metadata = item:getMetadata()
			itemArgs.mainid = itemId
			local arguments = {
				source = _source,
				item = itemArgs,
				args = args
			}

			UsableItemsFunctions[tostring(itemName)](arguments)
		end
	end
	return false
end

InventoryService.DropMoney = function(amount)
	local _source = source
	if not SvUtils.InProcessing(_source) then
		SvUtils.ProcessUser(_source)
		local userCharacter = Core.getUser(_source).getUsedCharacter
		local userMoney = userCharacter.money
		local charid = userCharacter.charIdentifier -- new line
		local charname = userCharacter.firstname .. ' ' .. userCharacter.lastname

		if Config.NewPlayers then
			if contains(newchar, charid) then                                             -- new line
				TriggerClientEvent("vorp:TipRight", _source, "Cant Drop Money as a new player", 5000) -- new line
				SvUtils.Trem(_source)                                                     -- new line
				return                                                                    -- new line
			end                                                                           -- new line
		end

		if amount <= 0 then
			TriggerClientEvent("vorp:TipRight", _source, T.TryExploits, 3000)
		elseif userMoney < amount then
			TriggerClientEvent("vorp:TipRight", _source, T.NotEnoughMoney, 3000)
		else
			userCharacter.removeCurrency(0, amount)
			if not Config.DeleteOnlyDontDrop then
				TriggerClientEvent("vorpInventory:createMoneyPickup", _source, amount)
			end
			local title = T.drop
			local description = "**Money** `" .. amount .. "`" .. "\n **Playername** `" .. charname .. "`\n"
			Core.AddWebhook(title, Config.webhook, description, color, "ID:" .. _source, logo, footerlogo, avatar)
		end
		SvUtils.Trem(_source)
	end
end

InventoryService.DropAllMoney = function()
	local _source = source
	if not SvUtils.InProcessing(_source) then
		SvUtils.ProcessUser(_source)
		local userCharacter = Core.getUser(_source).getUsedCharacter
		local userMoney = userCharacter.money
		local charid = userCharacter.charIdentifier -- new line

		if Config.NewPlayers then
			if contains(newchar, charid) then                                             -- new line
				TriggerClientEvent("vorp:TipRight", _source, "Cant Drop Money as a new player", 5000) -- new line
				SvUtils.Trem(_source)                                                     -- new line
				return                                                                    -- new line
			end                                                                           -- new line
		end

		if userMoney > 0 then
			userCharacter.removeCurrency(0, userMoney)
			TriggerClientEvent("vorpInventory:createMoneyPickup", _source, userMoney)
		end
		SvUtils.Trem(_source)
	end
end

InventoryService.DropPartMoney = function()
	local _source = source
	local userCharacter = Core.getUser(_source).getUsedCharacter
	local userMoney = userCharacter.money
	local userPartMoney = userMoney - (userMoney * Config.DropOnRespawn.PartPercentage / 100)
	local userMoneyDef = userMoney - userPartMoney
	local charid = userCharacter.charIdentifier -- new line

	if Config.NewPlayers then
		if contains(newchar, charid) then                                                -- new line
			TriggerClientEvent("vorp:TipRight", _source, "Cant Drop Money as a new player", 5000) -- new line
			SvUtils.Trem(_source)                                                        -- new line
			return                                                                       -- new line
		end                                                                              -- new line
	end

	if userMoney > 0 then
		userCharacter.removeCurrency(0, userMoneyDef)

		TriggerClientEvent("vorpInventory:createMoneyPickup", _source, userMoneyDef)
	end
end

InventoryService.giveMoneyToPlayer = function(target, amount)
	local _source = source
	if not SvUtils.InProcessing(_source) then
		SvUtils.ProcessUser(_source)
		local _target = target
		if Core.getUser(_source) == nil or Core.getUser(_target) == nil then
			SvUtils.Trem(_source)
			TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
			return
		end
		local sourceCharacter = Core.getUser(_source).getUsedCharacter
		local targetCharacter = Core.getUser(_target).getUsedCharacter
		local sourceMoney = sourceCharacter.money
		local charid = sourceCharacter.charIdentifier -- new line
		local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
		if Config.NewPlayers then
			if contains(newchar, charid) then                                             -- new line
				TriggerClientEvent("vorp:TipRight", _source, "Cant Give Money as a new player", 5000) -- new line
				SvUtils.Trem(_source)                                                     -- new line
				TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
				return                                                                    -- new line
			end                                                                           -- new line
		end

		if amount <= 0 then
			TriggerClientEvent("vorp:TipRight", _source, T.TryExploits, 3000)
			Wait(3000)
			TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		elseif sourceMoney < amount then
			TriggerClientEvent("vorp:TipRight", _source, T.NotEnoughMoney, 3000)
			Wait(3000)
			TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		else
			sourceCharacter.removeCurrency(0, amount)
			targetCharacter.addCurrency(0, amount)
			TriggerClientEvent("vorp:TipRight", _source, T.YouPaid .. amount .. " ID: " .. _target, 3000)
			TriggerClientEvent("vorp:TipRight", _target, T.YouReceived .. amount .. " ID: " .. _source, 3000)
			Wait(3000)
			TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
			local title = T.gaveMoney
			local description = "**Money** `" .. amount .. "`" .. "\n **Playername** `" .. charname .. "`\n"
			Core.AddWebhook(title, Config.webhook, description, color, "ID:" .. _source, logo, footerlogo, avatar)
		end
		SvUtils.Trem(_source)
	end
end

InventoryService.DropGold = function(amount)
	local _source = source
	if SvUtils.InProcessing(_source) then
		return
	end

	SvUtils.ProcessUser(_source)
	local userCharacter = Core.getUser(_source).getUsedCharacter
	local userGold = userCharacter.gold

	if amount <= 0 then
		TriggerClientEvent("vorp:TipRight", _source, T.TryExploits, 3000)
	elseif userGold < amount then
		TriggerClientEvent("vorp:TipRight", _source, T.NotEnoughGold, 3000)
	else
		userCharacter.removeCurrency(1, amount)
		if not Config.DeleteOnlyDontDrop then
			TriggerClientEvent("vorpInventory:createGoldPickup", _source, amount)
		end
	end
	SvUtils.Trem(_source)
end

InventoryService.DropAllGold = function()
	local _source = source
	if SvUtils.InProcessing(_source) then
		return
	end

	SvUtils.ProcessUser(_source)
	local userCharacter = Core.getUser(_source).getUsedCharacter
	local userGold = userCharacter.gold

	if userGold > 0 then
		userCharacter.removeCurrency(1, userGold)

		TriggerClientEvent("vorpInventory:createGoldPickup", _source, userGold)
	end
	SvUtils.Trem(_source, false)
end

InventoryService.giveGoldToPlayer = function(target, amount)
	local _source = source
	if SvUtils.InProcessing(_source) then
		return
	end

	if Core.getUser(_source) == nil or Core.getUser(target) == nil then
		return
	end

	SvUtils.ProcessUser(_source)
	local _target = target
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local targetCharacter = Core.getUser(_target).getUsedCharacter
	local sourceGold = sourceCharacter.gold

	if amount <= 0 then
		TriggerClientEvent("vorp:TipRight", _source, T.TryExploits, 3000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		Wait(3000)
	elseif sourceGold < amount then
		TriggerClientEvent("vorp:TipRight", _source, T.NotEnoughGold, 3000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		Wait(3000)
	else
		sourceCharacter.removeCurrency(1, amount)
		targetCharacter.addCurrency(1, amount)

		TriggerClientEvent("vorp:TipRight", _source, T.YouPaid .. amount .. "ID: " .. _target, 3000)
		TriggerClientEvent("vorp:TipRight", _target, T.YouReceived .. amount .. "ID: " .. _source, 3000)
		TriggerClientEvent("vorp_inventory:ProcessingReady", _source)
		Wait(3000)
	end
	SvUtils.Trem(_source)
end

InventoryService.setWeaponBullets = function(weaponId, type, amount)
	local userWeapons = UsersWeapons["default"]

	if userWeapons[weaponId] ~= nil then
		userWeapons[weaponId]:setAmmo(type, amount)
	end
end

InventoryService.usedWeapon = function(id, _used, _used2)
	local used = 0
	local used2 = 0

	if _used then used = 1 end
	if _used2 then used2 = 1 end

	MySQL.update('UPDATE loadout SET used = @used, used2 = @used2 WHERE id = @id', {
		['used'] = used,
		['used2'] = used2,
		['id'] = id
	}, function()
	end)
end

InventoryService.subItem = function(target, invId, itemId, amount)
	local _source = target
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local userInventory = nil

	if CustomInventoryInfos[invId].shared then
		userInventory = UsersInventories[invId]
	else
		userInventory = UsersInventories[invId][identifier]
	end

	if userInventory ~= nil then
		if userInventory[itemId] ~= nil then
			local item = userInventory[itemId]
			if item ~= nil then
				if amount <= item:getCount() then
					item:quitCount(amount)
				end

				if item:getCount() == 0 then
					userInventory[itemId] = nil
					DbService.DeleteItem(item:getOwner(), itemId)
				else
					DbService.SetItemAmount(item:getOwner(), itemId, item:getCount())
				end
			end
		end
	end
end

InventoryService.addItem = function(target, invId, name, amount, metadata, cb)
	local _source = target
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charIdentifier = sourceCharacter.charIdentifier
	local svItem = svItems[name]

	if svItem == nil then
		print("[^2AddItem^7] ^1Error^7: Item [^3" .. tostring(name) .. "^7] does not exist in DB.")
		cb(nil)
		return
	end

	metadata = SharedUtils.MergeTables(svItem.metadata, metadata or {})
	local userInventory = nil

	if CustomInventoryInfos[invId].shared then
		userInventory = UsersInventories[invId]
	else
		userInventory = UsersInventories[invId][identifier]
	end

	if userInventory ~= nil then
		local item = SvUtils.FindItemByNameAndMetadata(invId, identifier, name, metadata)
		if item ~= nil then
			if amount > 0 then
				item:addCount(amount, CustomInventoryInfos[invId].ignoreItemStackLimit)
				DbService.SetItemAmount(item:getOwner(), item:getId(), item:getCount())
				cb(item)
				return
			end
			cb(nil)
			return
		else
			DbService.CreateItem(charIdentifier, svItem:getId(), amount, metadata, function(craftedItem)
				item = Item:New({
					id = craftedItem.id,
					count = amount,
					limit = svItem:getLimit(),
					label = svItem:getLabel(),
					metadata = SharedUtils.MergeTables(svItem.metadata, metadata),
					name = name,
					type = "item_standard",
					canUse = svItem:getCanUse(),
					canRemove = svItem:getCanRemove(),
					owner = charIdentifier,
					desc = svItem:getDesc()
				})
				userInventory[craftedItem.id] = item
				cb(item)
			end, invId)
			return
		end
	end

	cb(nil)
end

InventoryService.addWeapon = function(target, weaponId)
	local _source = target
	local userWeapons = UsersWeapons["default"]
	local weaponcomps
	local result = MySQL.query.await('SELECT comps FROM loadout WHERE id = @id ', { ['id'] = weaponId })

	if result[1] ~= nil then
		weaponcomps = json.decode(result[1].comps)
	else
		weaponcomps = {}
	end

	local weaponname = userWeapons[weaponId]:getName()
	local ammo = { ["nothing"] = 0 }
	local components = { ["nothing"] = 0 }
	InventoryAPI.registerWeapon(_source, weaponname, ammo, components, weaponcomps)
	InventoryAPI.deletegun(_source, weaponId)
end

InventoryService.subWeapon = function(target, weaponId)
	local _source = target
	local User = Core.getUser(_source)

	if not User then
		return Log.error("User not found")
	end

	local sourceCharacter = User.getUsedCharacter
	local charId = sourceCharacter.charIdentifier
	local userWeapons = UsersWeapons["default"]

	if weaponId and userWeapons[weaponId] then
		userWeapons[weaponId]:setPropietary('')


		MySQL.update("UPDATE loadout SET identifier = '', dropped = @dropped, charidentifier = @charId WHERE id = @id", {
			['charId'] = charId,
			['id'] = weaponId,
			['dropped'] = 1
		}, function()
		end)
	end
end

InventoryService.onPickup = function(obj)
	local _source = source

	if SvUtils.InProcessing(_source) then
		return
	end

	SvUtils.ProcessUser(_source)
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local identifier = sourceCharacter.identifier
	local charId = sourceCharacter.charIdentifier
	local job = sourceCharacter.job
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	local userInventory = UsersInventories["default"][identifier]
	local userWeapons = UsersWeapons["default"]

	if ItemPickUps[obj] ~= nil then
		local name = ItemPickUps[obj].name
		local amount = ItemPickUps[obj].amount
		local metadata = ItemPickUps[obj].metadata
		if ItemPickUps[obj].weaponid == 1 then
			if userInventory ~= nil then
				InventoryAPI.canCarryItem(_source, name, amount, function(canAdd)
					if canAdd then
						InventoryService.addItem(_source, "default", name, amount, metadata, function(item)
							if item ~= nil then
								local title = T.itempickup
								local description = "**Amount** `" ..
									amount ..
									"`\n **Item** `" .. name .. "`" .. "\n **Playername** `" .. charname .. "`\n"
								Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo,
									avatar)
								TriggerClientEvent("vorpInventory:sharePickupClient", -1, name, ItemPickUps[obj].obj,
									amount, metadata,
									ItemPickUps[obj].coords, 2)
								TriggerClientEvent("vorpInventory:removePickupClient", -1, ItemPickUps[obj].obj)
								TriggerClientEvent("vorpInventory:receiveItem", _source, name, item:getId(), amount,
									metadata)
								TriggerClientEvent("vorpInventory:playerAnim", _source, obj)
								ItemPickUps[obj] = nil
							end
						end)
					else
						TriggerClientEvent("vorp:TipRight", _source, T.fullInventory, 2000)
						SvUtils.Trem(_source, false)
					end
				end)
			end
		else
			-- weapons
			local notListed = false
			local sourceInventoryWeaponCount = 0
			local DefaultAmount = Config.MaxItemsInInventory.Weapons
			local weaponId = ItemPickUps[obj].weaponid
			local weapon = userWeapons[weaponId]
			local wepname = weapon:getName()

			if Config.JobsAllowed[job] then
				DefaultAmount = Config.JobsAllowed[job]
			end

			if DefaultAmount ~= 0 then
				if wepname then
					if SharedUtils.IsValueInArray(string.upper(wepname), Config.notweapons) then
						notListed = true
					end
				end
				if not notListed then
					sourceInventoryWeaponCount = InventoryAPI.getUserTotalCountWeapons(identifier, charId) + 1
				end
				if sourceInventoryWeaponCount <= DefaultAmount then
					local weaponObj = ItemPickUps[obj].obj
					weapon:setDropped(0)
					local title = T.weppickup
					local description = "**Weapon** `" ..
						wepname .. "`" .. "\n **Playername** `" .. charname .. "`\n"
					Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
					TriggerClientEvent("vorpInventory:sharePickupClient", -1, name, weaponObj, 1, metadata,
						ItemPickUps[obj].coords, 2,
						weaponId)
					TriggerClientEvent("vorpInventory:removePickupClient", -1, weaponObj)
					TriggerClientEvent("vorpInventory:playerAnim", _source, obj)
					InventoryService.addWeapon(_source, weaponId)
					ItemPickUps[obj] = nil
				end
			else
				TriggerClientEvent("vorp:TipRight", _source, T.fullInventoryWeapon, 2000)
			end
		end
	end
	SvUtils.Trem(_source, false)
end

InventoryService.onPickupMoney = function(obj)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	if not SvUtils.InProcessing(_source) then
		if MoneyPickUps[obj] ~= nil then
			SvUtils.ProcessUser(_source)
			local moneyObj = MoneyPickUps[obj].obj
			local moneyAmount = MoneyPickUps[obj].amount
			local moneyCoords = MoneyPickUps[obj].coords
			local title = T.itempickup
			local description = "**Money** `" .. moneyAmount .. " $`" .. "\n **Playername** `" .. charname .. "`\n"
			Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
			TriggerClientEvent("vorpInventory:shareMoneyPickupClient", -1, moneyObj, moneyAmount, moneyCoords, 2)
			TriggerClientEvent("vorpInventory:removePickupClient", -1, moneyObj)
			TriggerClientEvent("vorpInventory:playerAnim", _source, moneyObj)
			TriggerEvent("vorp:addMoney", _source, 0, moneyAmount)
			MoneyPickUps[obj] = nil
			SvUtils.Trem(_source, false)
		end
	end
end

InventoryService.onPickupGold = function(obj)
	local _source = source
	if not SvUtils.InProcessing(_source) then
		if GoldPickUps[obj] ~= nil then
			SvUtils.ProcessUser(_source)
			local goldObj = GoldPickUps[obj].obj
			local goldAmount = GoldPickUps[obj].amount
			local goldCoords = GoldPickUps[obj].coords

			TriggerClientEvent("vorpInventory:shareGoldPickupClient", -1, goldObj, goldAmount, goldCoords, 2)
			TriggerClientEvent("vorpInventory:removePickupClient", -1, goldObj)
			TriggerClientEvent("vorpInventory:playerAnim", _source, goldObj)
			TriggerEvent("vorp:addMoney", _source, 1, goldAmount)
			GoldPickUps[obj] = nil
			SvUtils.Trem(_source, false)
		end
	end
end

InventoryService.sharePickupServer = function(name, obj, amount, metadata, position, weaponId)
	TriggerClientEvent("vorpInventory:sharePickupClient", -1, name, obj, amount, metadata, position, 1, weaponId)

	ItemPickUps[obj] = {
		name = name,
		obj = obj,
		amount = amount,
		metadata = metadata,
		weaponid = weaponId,
		inRange = false,
		coords = position
	}
end

InventoryService.shareMoneyPickupServer = function(obj, amount, position)
	TriggerClientEvent("vorpInventory:shareMoneyPickupClient", -1, obj, amount, position, 1)

	MoneyPickUps[obj] = {
		name = T.inventorymoneylabel,
		obj = obj,
		amount = amount,
		inRange = false,
		coords = position
	}
end

InventoryService.shareGoldPickupServer = function(obj, amount, position)
	TriggerClientEvent("vorpInventory:shareGoldPickupClient", -1, obj, amount, position, 1)

	GoldPickUps[obj] = {
		name = T.inventorygoldlabel,
		obj = obj,
		amount = amount,
		inRange = false,
		coords = position
	}
end

InventoryService.DropWeapon = function(weaponId)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	if not SvUtils.InProcessing(_source) then
		SvUtils.ProcessUser(_source)
		InventoryService.subWeapon(_source, weaponId)
		UsersWeapons["default"][weaponId]:setDropped(1)

		local title = T.drop
		local description = "**Weapon** `" ..
			UsersWeapons["default"][weaponId]:getName() .. "`" .. "\n **Playername** `" .. charname .. "`\n"
		Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
		if not Config.DeleteOnlyDontDrop then
			TriggerClientEvent("vorpInventory:createPickup", _source, UsersWeapons["default"][weaponId]:getName(), 1, {},
				weaponId)
		end
		SvUtils.Trem(_source)
	end
end

InventoryService.DropItem = function(itemName, itemId, amount, metadata)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	if not SvUtils.InProcessing(_source) then
		SvUtils.ProcessUser(_source)
		InventoryService.subItem(_source, "default", itemId, amount)
		local title = T.drop
		local description = "**Amount** `" ..
			amount .. "`\n **Item** `" .. itemName .. "`" .. "\n **Playername** `" .. charname .. "`\n"

		Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
		if not Config.DeleteOnlyDontDrop then
			TriggerClientEvent("vorpInventory:createPickup", _source, itemName, amount, metadata, 1)
		end
		SvUtils.Trem(_source)
	end
end

InventoryService.GiveWeapon = function(weaponId, target)
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local charid = sourceCharacter.charIdentifier
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	if Config.NewPlayers then
		if contains(newchar, charid) then                                               -- new line
			TriggerClientEvent("vorp:TipRight", _source, "Cant Give Item as a new player", 5000) -- new line
			TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
			SvUtils.Trem(_source)                                                       -- new line
			return                                                                      -- new line
		end                                                                             -- new line
	end
	if not SvUtils.InProcessing(_source) then
		TriggerClientEvent("vorp_inventory:transactionStarted", _source)
		SvUtils.ProcessUser(_source)
		local _target = target

		if UsersWeapons["default"][weaponId] ~= nil then
			InventoryAPI.giveWeapon2(_target, weaponId, _source)
		end
		local title = T.drop
		local description = "**Amount** `" ..
			1 .. "`\n **Weapon id** `" .. weaponId .. "`" .. "\n **Playername** `" .. charname .. "`\n"

		Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
		TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
		SvUtils.Trem(_source)
	end
end


InventoryService.GiveItem = function(itemId, amount, target)
	local _source = source

	if SvUtils.InProcessing(_source) then
		return
	end
	TriggerClientEvent("vorp_inventory:transactionStarted", _source)
	SvUtils.ProcessUser(_source)
	local _target = target
	if Core.getUser(_source) == nil or Core.getUser(_target) == nil then
		TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
		SvUtils.Trem(_source)
		return
	end
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local targetCharacter = Core.getUser(_target).getUsedCharacter
	local charid = sourceCharacter.charIdentifier -- new line
	local charname = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	local charname1 = targetCharacter.firstname .. ' ' .. targetCharacter.lastname
	if Config.NewPlayers then
		if contains(newchar, charid) then                                               -- new line
			TriggerClientEvent("vorp:TipRight", _source, "Cant Give Item as a new player", 5000) -- new line
			TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
			SvUtils.Trem(_source)                                                       -- new line
			return                                                                      -- new line
		end                                                                             -- new line
	end

	local sourceIdentifier = sourceCharacter.identifier
	local targetIdentifier = targetCharacter.identifier

	local sourceInventory = UsersInventories["default"][sourceIdentifier]
	local targetInventory = UsersInventories["default"][targetIdentifier]

	local sourceCharIdentifier = sourceCharacter.charIdentifier
	local targetCharIdentifier = targetCharacter.charIdentifier

	if sourceInventory == nil or targetInventory == nil then
		TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
		SvUtils.Trem(_source)
		return
	end

	if sourceInventory[itemId] == nil then
		TriggerClientEvent("vorp:TipRight", _source, T.itemerror, 2000)
		if Config.Debug then
			Log.error("ServerGiveItem: User " ..
				sourceCharacter.firstname ..
				' ' .. sourceCharacter.lastname .. '#' .. _source .. ' ' .. 'inventory item ' .. itemName .. ' not found')
		end
		TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
		SvUtils.Trem(_source)
		return
	end
	local item = sourceInventory[itemId]
	local itemMetadata = item:getMetadata()
	local itemName = item:getName()
	local svItem = svItems[itemName]
	if svItem == nil then
		print("[^2GiveItem^7] ^1Error^7: Item [^3" .. itemName .. "^7] does not exist in DB.")
		TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
		SvUtils.Trem(_source)
		return
	end
	local updateClient = function(addedItem)
		TriggerClientEvent("vorpInventory:receiveItem", _target, itemName, addedItem:getId(), amount, itemMetadata)
		TriggerClientEvent("vorpInventory:removeItem", _source, itemName, item:getId(), amount)
		if item:getCount() - amount <= 0 then
			DbService.DeleteItem(sourceCharIdentifier, item:getId())
			sourceInventory[item:getId()] = nil
		else
			item:quitCount(amount)
			DbService.SetItemAmount(sourceCharIdentifier, item:getId(), item:getCount())
		end
		local ItemsLabel = svItem:getLabel()
		--NOTIFY
		TriggerClientEvent("vorp:TipRight", _source, T.yougive .. amount .. T.of .. ItemsLabel .. "", 2000)
		TriggerClientEvent("vorp:TipRight", _target, T.youreceive .. amount .. T.of .. ItemsLabel .. "", 2000)
		--TriggerEvent("vorpinventory:itemlog", _source, _target, itemName, amount)
		local title = T.gaveMoney
		local description = "**Amount** `" ..
			amount .. "`\n **Item** `" .. itemName .. "`" .. "\n **Playername** `" .. charname .. "`\n **to** `" ..
			charname1 .. "`"
		Core.AddWebhook(title, Config.webhook, description, color, _source, logo, footerlogo, avatar)
	end
	InventoryAPI.canCarryItem(_target, itemName, amount, function(canGive)
		if canGive then
			local targetItem = SvUtils.FindItemByNameAndMetadata("default", targetIdentifier, itemName, itemMetadata)
			if targetItem ~= nil then
				targetItem:addCount(amount)
				DbService.SetItemAmount(targetCharIdentifier, targetItem:getId(), targetItem:getCount())
				updateClient(targetItem)
			else
				DbService.CreateItem(targetCharIdentifier, svItem:getId(), amount, itemMetadata, function(craftedItem)
					targetItem = Item:New({
						id = craftedItem.id,
						count = amount,
						limit = svItem:getLimit(),
						label = svItem:getLabel(),
						name = itemName,
						type = "item_inventory",
						metadata = itemMetadata,
						canUse = svItem:getCanUse(),
						canRemove = svItem:getCanRemove(),
						owner = targetCharIdentifier,
						desc = svItem:getDesc()
					})
					targetInventory[craftedItem.id] = targetItem
					updateClient(targetItem)
				end)
			end
		else
			TriggerClientEvent("vorp:TipRight", _source, T.fullInventoryGive, 2000)
			TriggerClientEvent("vorp:TipRight", _target, T.fullInventory, 2000)
		end
	end)
	TriggerClientEvent("vorp_inventory:transactionCompleted", _source)
	SvUtils.Trem(_source)
end

InventoryService.getItemsTable = function()
	local _source = source

	if svItems ~= nil then
		TriggerClientEvent("vorpInventory:giveItemsTable", _source, svItems)
	end
end

InventoryService.getInventory = function()
	local _source = source
	local sourceCharacter = Core.getUser(_source).getUsedCharacter

	if sourceCharacter == nil then
		return
	end

	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharId = sourceCharacter.charIdentifier

	local characterInventory = {}

	if sourceCharId ~= nil then
		DbService.GetInventory(sourceCharId, "default", function(inventory)
			for _, item in pairs(inventory) do
				if svItems[item.item] ~= nil then
					local dbItem = svItems[item.item]
					characterInventory[item.id] = Item:New({
						count = tonumber(item.amount),
						id = item.id,
						limit = dbItem.limit,
						label = dbItem.label,
						metadata = SharedUtils.MergeTables(dbItem.metadata, item.metadata),
						name = dbItem.item,
						type = dbItem.type,
						canUse = dbItem.canUse,
						canRemove = dbItem.canRemove,
						createdAt = item.created_at,
						owner = sourceCharId,
						desc = dbItem.desc
					})
				end
			end
			UsersInventories["default"][sourceIdentifier] = characterInventory
			TriggerClientEvent("vorpInventory:giveInventory", _source, json.encode(inventory))
		end)


		local userWeapons = {}
		for _, weapon in pairs(UsersWeapons["default"]) do
			if weapon.propietary == sourceIdentifier and weapon.charId == sourceCharId and weapon.currInv == "default" and
				weapon.dropped == 0 then
				userWeapons[#userWeapons + 1] = weapon
			end
		end
		TriggerClientEvent("vorpInventory:giveLoadout", _source, userWeapons)

		for id, _ in pairs(CustomInventoryInfos) do
			if UsersInventories[id][sourceIdentifier] ~= nil then
				UsersInventories[id][sourceIdentifier] = nil
			end
		end
	end
end

InventoryService.getInventoryTotalCount = function(identifier, charIdentifier, invId)
	invId = invId ~= nil and invId or "default"
	local userTotalItemCount = 0
	local userInventory = {}
	local userWeapons = UsersWeapons[invId]

	if CustomInventoryInfos[invId].shared then
		userInventory = UsersInventories[invId]
	else
		userInventory = UsersInventories[invId][identifier]
	end

	for _, item in pairs(userInventory) do
		userTotalItemCount = userTotalItemCount + item:getCount()
	end
	for _, weapon in pairs(userWeapons) do
		if CustomInventoryInfos[invId].shared or weapon.charId == charIdentifier then
			userTotalItemCount = userTotalItemCount + 1
		end
	end
	return userTotalItemCount
end

InventoryService.canStoreWeapon = function(identifier, charIdentifier, invId, name, amount)
	local invData = CustomInventoryInfos[invId]

	if invData.limit > 0 then                                  -- if inventory limit is bigger than 0
		local sourceInventoryItemCount = InventoryService.getInventoryTotalCount(identifier, charIdentifier, invId)
		sourceInventoryItemCount = sourceInventoryItemCount + amount -- do the math
		if sourceInventoryItemCount > invData.limit then       -- if its less or equals  then return true
			return false
		end
	end

	if invData.limitedWeapons[string.lower(name)] then             -- if it does exists in the table the weapns name
		local weapons = SvUtils.FindAllWeaponsByName(invId, name)  -- find name
		local weaponCount = #weapons + amount                      -- do the math
		if weaponCount > invData.limitedWeapons[string.lower(name)] then -- if ammount is greater then cancel
			return false
		end
	elseif invData.whitelistWeapons then -- if name isnt on the list and choose whitelist items reject, otherwise say you can store any weapon if whitelist is false
		return false
	end
	return true -- after all checks can store weapon
end

InventoryService.canStoreItem = function(identifier, charIdentifier, invId, name, amount)
	local invData = CustomInventoryInfos[invId]

	if invData.limit > 0 then
		local sourceInventoryItemCount = InventoryService.getInventoryTotalCount(identifier, charIdentifier, invId)
		sourceInventoryItemCount = sourceInventoryItemCount + amount

		if sourceInventoryItemCount > invData.limit then
			return false
		end
	end

	if invData.limitedItems[string.lower(name)] then
		local items = SvUtils.FindAllItemsByName(invId, identifier, name)

		if #items ~= 0 then
			local itemCount = 0
			for _, item in pairs(items) do
				itemCount = itemCount + item:getCount()
			end
			local totalAmount = amount + itemCount

			if totalAmount > invData.limitedItems[string.lower(name)] then
				return false
			end
		elseif amount > invData.limitedItems[string.lower(name)] then
			return false
		end
		return true
	elseif invData.whitelistItems then
		return false
	end

	if not invData.ignoreItemStackLimit then
		local item = SvUtils.FindItemByNameAndMetadata(invId, identifier, name, metadata)
		if item ~= nil then
			local totalCount = item:getCount() + amount

			if totalCount > item:getLimit() then
				return false
			end
		end
	end
	return true
end

InventoryService.getNearbyCharacters = function(obj, sources)
	local _source = source

	local characters = {}
	for _, playerId in pairs(sources) do
		if Config.ShowCharacterNameOnGive then
			local character = Core.getUser(playerId).getUsedCharacter
			characters[#characters + 1] = {
				label = character.firstname .. ' ' .. character.lastname,
				player = playerId
			}
		else
			characters[#characters + 1] = {
				label = tostring(playerId), -- show server id instead of steam name
				player = playerId
			}
		end
	end

	TriggerClientEvent('vorp_inventory:setNearbyCharacters', _source, obj, characters)
end


--================================== CUSTOM INVENTORY ================================================--

InventoryService.DoesHavePermission = function(invId, job, grade, Table)
	if not CustomInventoryInfos[invId].UsePermissions then -- allow everyone if false or nil by fefault is false
		return true
	end

	if not next(Table) then -- if empty allow anyone by default is empty
		return true
	end
	for jobname, jobgrade in pairs(Table) do
		if jobname == job then
			if grade >= jobgrade then
				return true
			end
		end
	end
	return false
end

InventoryService.CheckIsBlackListed = function(invId, ItemName)
	local ItemsTable = CustomInventoryInfos[invId].BlackListItems
	if not CustomInventoryInfos[invId].UseBlackList then -- if not want to black list
		return true
	end
	if next(ItemsTable) then
		for item, _ in pairs(ItemsTable) do
			if item == ItemName then
				return false
			end
		end
	end
	return true
end

InventoryService.DiscordLogs = function(inventory, itemName, amount, playerName, type)
	local title = Config.WebHook.title
	local color = Config.WebHook.color
	local logo = Config.WebHook.logo
	local footerlogo = Config.WebHook.footerlogo
	local avatar = Config.WebHook.avatar
	local names = Config.WebHook.webhookname

	if type == "Move" then
		local webhook = Config.WebHook.CustomInventoryMoveTo
		local description = "**Player:**`" ..
			playerName ..
			"`\n **Moved to:** `" .. inventory .. "` \n**Weapon** `" ..
			itemName .. "`\n **Count:** `" .. amount .. "`"
		Core.AddWebhook(title, webhook, description, color, names, logo, footerlogo, avatar)
	end

	if type == "Take" then
		local webhook = Config.WebHook.CustomInventoryTakeFrom
		local description = "**Player:**`" ..
			playerName ..
			"`\n **Took from:** `" .. inventory .. "`\n **item** `" ..
			itemName .. "`\n **amount:** `" .. amount .. "`"
		Core.AddWebhook(title, webhook, description, color, names, logo, footerlogo, avatar)
	end
end


InventoryService.MoveToCustom = function(obj)
	local _source = source
	local data = json.decode(obj)
	local invId = tostring(data.id)
	local item = data.item
	local amount = tonumber(data.number)
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceIdentifier = sourceCharacter.identifier
	local sourceName = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	local job = sourceCharacter.job
	local grade = sourceCharacter.jobGrade
	local sourceCharIdentifier = sourceCharacter.charIdentifier
	local Table = CustomInventoryInfos[invId].PermissionMoveTo
	local CanMove = InventoryService.DoesHavePermission(invId, job, grade, Table)
	local IsBlackListed = InventoryService.CheckIsBlackListed(invId, string.lower(item.name)) -- lower so we can checkitems and weapons

	if not IsBlackListed then
		Core.NotifyObjective(_source, "Item is blackListed", 5000) -- add your own notifications
		return
	end

	if not CanMove then
		Core.NotifyObjective(_source, "You dont have permision to move into the storage", 5000) -- add your own notifications
		return
	end

	if item.type == "item_weapon" then
		if CustomInventoryInfos[invId].acceptWeapons then -- if accept weapons
			if InventoryService.canStoreWeapon(sourceIdentifier, sourceCharIdentifier, invId, item.name, amount) then
				MySQL.update(
					"UPDATE loadout SET identifier = '',curr_inv = @invId WHERE charidentifier = @charid AND id = @weaponId;"
					, {
						['invId'] = invId,
						['charid'] = sourceCharIdentifier,
						['weaponId'] = item.id,
					})

				UsersWeapons["default"][item.id]:setCurrInv(invId)
				UsersWeapons[invId][item.id] = UsersWeapons["default"][item.id]
				UsersWeapons["default"][item.id] = nil

				TriggerClientEvent("vorpCoreClient:subWeapon", _source, item.id)
				InventoryAPI.reloadInventory(_source, invId)
				InventoryService.DiscordLogs(invId, item.name, amount, sourceName, "Move")
				local text = "you have moved to storage"

				if string.lower(item.name) == "weapon_revolver_lemat" then
					Icon = "weapon_revolver_doubleaction" -- theres no revolver lemat texture
				else
					Icon = item.name
				end
				Core.NotifyAvanced(_source, text, "inventory_items", Icon, "COLOR_PURE_WHITE", 4000)
			else
				TriggerClientEvent("vorp:TipRight", _source, T.fullInventory, 2000)
			end
		end
	else
		if not item.count or not amount then
			return
		end

		if item.count >= amount and
			InventoryService.canStoreItem(sourceIdentifier, sourceCharIdentifier, invId, item.name, amount) then
			InventoryService.subItem(_source, "default", item.id, amount)
			TriggerClientEvent("vorpInventory:removeItem", _source, item.name, item.id, amount)

			InventoryService.addItem(_source, invId, item.name, amount, item.metadata, function(itemAdded)
				if itemAdded == nil then
					return
				end
				TriggerClientEvent("vorp:TipRight", _source,
					"you have Moved " .. amount .. " " .. item.label .. " to storage",
					2000)
				InventoryAPI.reloadInventory(_source, invId)
				InventoryService.DiscordLogs(invId, item.name, amount, sourceName, "Move")
			end)
		else
			TriggerClientEvent("vorp:TipRight", _source, T.fullInventory, 2000)
		end
	end
end

InventoryService.TakeFromCustom = function(obj)
	local _source = source
	local data = json.decode(obj)
	local invId = tostring(data.id)
	local item = data.item
	local amount = tonumber(data.number)
	local sourceCharacter = Core.getUser(_source).getUsedCharacter
	local sourceName = sourceCharacter.firstname .. ' ' .. sourceCharacter.lastname
	local sourceIdentifier = sourceCharacter.identifier
	local sourceCharIdentifier = sourceCharacter.charIdentifier
	local job = sourceCharacter.job
	local grade = sourceCharacter.jobGrade
	local Table = CustomInventoryInfos[invId].PermissionTakeFrom
	local CanMove = InventoryService.DoesHavePermission(invId, job, grade, Table)

	if not CanMove then
		Core.NotifyObjective(_source, "you dont have permmissions to take from this storage", 5000) -- add your own notifications
		return
	end

	if item.type == "item_weapon" then
		InventoryAPI.canCarryAmountWeapons(_source, 1, function(res)
			if res then
				MySQL.update(
					"UPDATE loadout SET curr_inv = 'default', charidentifier = @charid, identifier = @identifier WHERE id = @weaponId;"
					, {
						['charid'] = sourceCharIdentifier,
						['weaponId'] = item.id,
						['identifier'] = sourceIdentifier
					}
				)
				UsersWeapons[invId][item.id]:setCurrInv("default")
				UsersWeapons["default"][item.id] = UsersWeapons[invId][item.id]
				UsersWeapons["default"][item.id].propietary = sourceIdentifier
				UsersWeapons["default"][item.id].charId = sourceCharIdentifier
				UsersWeapons[invId][item.id] = nil
				local weapon = UsersWeapons["default"][item.id]
				TriggerClientEvent("vorpInventory:receiveWeapon", _source, item.id, sourceIdentifier, weapon:getName(),
					weapon:getAllAmmo())
				InventoryAPI.reloadInventory(_source, invId)
				InventoryService.DiscordLogs(invId, item.name, amount, sourceName, "Take")
				local text = " you have Taken From storage "
				if string.lower(item.name) == "weapon_revolver_lemat" then
					Icon = "weapon_revolver_doubleaction" -- theres no revolver lemat texture
				else
					Icon = item.name
				end
				Core.NotifyAvanced(_source, text, "inventory_items", Icon, "COLOR_PURE_WHITE", 4000)
			else
				TriggerClientEvent("vorp:TipRight", _source, T.fullInventory, 2000)
			end
		end, item.name)
	else
		InventoryAPI.canCarryItem(_source, item.name, amount, function(res)
			if res then
				if amount > item.count then
					return
				end
				InventoryService.subItem(_source, invId, item.id, amount)
				InventoryService.addItem(_source, "default", item.name, amount, item.metadata, function(itemAdded)
					if itemAdded == nil then
						return
					end
					TriggerClientEvent("vorpInventory:receiveItem", _source, item.name, itemAdded:getId(), amount,
						itemAdded:getMetadata())
					InventoryAPI.reloadInventory(_source, invId)
					InventoryService.DiscordLogs(invId, item.name, amount, sourceName, "Take")
					TriggerClientEvent("vorp:TipRight", _source,
						"you have Taken " .. amount .. " " .. item.label .. " from storage ",
						2000)
				end)
			else
				TriggerClientEvent("vorp:TipRight", _source, T.fullInventory, 2000)
			end
		end)
	end
end
