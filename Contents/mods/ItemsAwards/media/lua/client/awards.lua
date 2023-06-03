local itemsAwards = {
  { Item = "Base.BaseballBatNails", Kills = 1, Count = 1 },
  { Item = "Base.Money", Kills = 2, Count = 10 },
  { Item = "Base.Trousers_CamoGreen", Kills = 10, Count = 1 },
  { Item = "Base.Shoes_ArmyBoots", Kills = 15, Count = 1 },
  { Item = "Base.Vest_BulletArmy", Kills = 20, Count = 1 },
  { Item = "Base.Tshirt_CamoGreen", Kills = 25, Count = 1 }
}

local function ZombKilled()
  local player = getPlayer()
  local countZombieKill = player:getZombieKills() + 1
  for key, value in pairs(itemsAwards) do
    if ( countZombieKill == value.Kills ) then
      local itemName = getItemNameFromFullType(value.Item)
      player:setHaloNote(string.format("You have won: %s. Count: %d", itemName, value.Count))
      player:getInventory():AddItems(value.Item, value.Count)
    end
  end
  player:setHaloNote(string.format("[Items Awards]: Zombies killed: %d", countZombieKill))
end

Events.OnZombieDead.Add(ZombKilled)
