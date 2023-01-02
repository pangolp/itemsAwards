local itemsAwards = {
  { Item = "Base.BaseballBatNails", Kills = 1 },
  { Item = "Base.BaseballBatNails", Kills = 2 },
  { Item = "Base.Trousers_CamoGreen", Kills = 10 },
  { Item = "Base.Shoes_ArmyBoots", Kills = 15 },
  { Item = "Base.Vest_BulletArmy", Kills = 20 },
  { Item = "Base.Tshirt_CamoGreen", Kills = 25 }
}

local function ZombKilled()
  local player = getPlayer()
  local countZombieKill = player:getZombieKills() + 1
  for key, value in pairs(itemsAwards) do
    if ( countZombieKill == value.Kills ) then
      local itemName = getItemNameFromFullType(value.Item)
      player:Say(string.format("You have won: %s", itemName))
      player:getInventory():AddItem(value.Item)
    end
  end
  player:Say(string.format("[Items Awards]: Zombies killed: %d", countZombieKill))
end

Events.OnZombieDead.Add(ZombKilled)
