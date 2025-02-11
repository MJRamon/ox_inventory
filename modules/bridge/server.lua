function server.hasGroup(inv, group)
	if type(group) == 'table' then
		for name, rank in pairs(group) do
			local groupRank = inv.player.groups[name]
			if groupRank and groupRank >= (rank or 0) then
				return name, groupRank
			end
		end
	else
		local groupRank = inv.player.groups[group]
		if groupRank then
			return group, groupRank
		end
	end
end

function server.setPlayerData(player)
	return {
		name = player.name,
		groups = player.groups,
		sex = player.sex,
		dateofbirth = player.dateofbirth,
	}
end

if shared.framework == 'ox' then
	function server.getInventory(identifier)
		local inventory = MySQL.prepare.await('SELECT inventory FROM characters WHERE charid = ?', { identifier })
		return inventory and json.decode(inventory)
	end
end

if shared.framework == 'esx' then
	local ESX = exports['es_extended']:getSharedObject()

	-- ESX.ServerCallbacks does not exist in the Overextended fork of ESX, so throw an error
	if ESX.ServerCallbacks then
		shared.error('Ox Inventory requires a modified version of ESX, refer to the documentation.')
	end

	ESX = {
		GetUsableItems = ESX.GetUsableItems,
		GetPlayerFromId = ESX.GetPlayerFromId,
		UseItem = ESX.UseItem
	}

	server.UseItem = ESX.UseItem
	server.UsableItemsCallbacks = ESX.GetUsableItems
	server.GetPlayerFromId = ESX.GetPlayerFromId

	server.accounts = {
		money = 0,
		black_money = 0,
	}

	function server.setPlayerData(player)
		local groups = {
			[player.job.name] = player.job.grade
		}

		return {
			name = player.name,
			groups = groups,
			sex = player.sex or player.variables.sex,
			dateofbirth = player.dateofbirth or player.variables.dateofbirth,
		}
	end

	function server.getInventory(identifier)
		local inventory = MySQL.prepare.await('SELECT inventory FROM users WHERE identifier = ?', { identifier })
		return inventory and json.decode(inventory)
	end

	RegisterServerEvent('ox_inventory:requestPlayerInventory', function()
		local source = source
		local player = server.GetPlayerFromId(source)

		if player then
			exports.ox_inventory:setPlayerInventory(player, player?.inventory)
		end
	end)
end
