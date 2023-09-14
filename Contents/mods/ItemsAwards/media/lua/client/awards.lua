local itemsAwards = {
  {Item = "Base.VHS_Home", Number = 10, Count = 1}, -- Home VHS
  {Item = "Base.HazmatSuit", Number = 20, Count = 1}, -- Hazmat Suit
  {Item = "Base.EngineParts", Number = 30, Count = 1}, -- Spare Engine Parts
  {Item = "Base.Hat_SantaHat", Number = 40, Count = 1}, -- Santa Hat
  {Item = "Base.Hat_BunnyEarsWhite", Number = 50, Count = 1}, -- Bunny Ears
  {Item = "Base.Hat_PartyHat_Stars", Number = 60, Count = 1}, -- Colored Party Hat
  {Item = "Base.Katana", Number = 70, Count = 1}, -- Katana
  {Item = "Base.CarKey", Number = 80, Count = 1}, -- Car Key
  {Item = "Base.CombinationPadlock", Number = 90, Count = 1}, -- Combination Padlock
  {Item = "Base.Machete", Number = 100, Count = 1}, -- Machete
}

local function ZombKilled()
  local player = getPlayer()
  local number = ZombRandBetween(1, 1001)
  for key, value in pairs(itemsAwards) do
    if (number == value.Number) then
      local itemName = getItemNameFromFullType(value.Item)
      player:getInventory():AddItems(value.Item, value.Count)
      player:setHaloNote(string.format(getText("IGUI_WonItem"), itemName, value.Count))
    end
  end
end

Events.OnZombieDead.Add(ZombKilled)
