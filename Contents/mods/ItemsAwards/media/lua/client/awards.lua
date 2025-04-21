Awards = Awards or {}
Awards.Options = Awards.Options or {}

local itemsAwards = {
  {Item = "Base.BaseballBatNails", Number = 5, Count = 1}, -- Spiked Baseball Bat
  {Item = "Base.FishingRodBreak", Number = 10, Count = 1}, -- Fishing Rod without Line
  {Item = "Base.MetalBar", Number = 15, Count = 3}, -- Metal Bar
  {Item = "Base.MetalPipe", Number = 20, Count = 3}, -- Metal Pipe
  {Item = "Base.Katana", Number = 25, Count = 1}, -- Katana
  {Item = "Base.Machete", Number = 30, Count = 1}, -- Machete
  {Item = "Base.GardenFork", Number = 35, Count = 1}, -- Garden Fork
  {Item = "Base.Revolver_Short", Number = 40, Count = 1}, -- M36 Revolver
  {Item = "Base.AssaultRifle2", Number = 45, Count = 1}, -- M14 Rifle
  {Item = "Base.AssaultRifle", Number = 50, Count = 1}, -- M16 Assault Rifle
  {Item = "Base.DoubleBarrelShotgun", Number = 55, Count = 1}, -- Double Barrel Shotgun
  {Item = "Base.Bullets38", Number = 60, Count = 2}, -- .38 Special Round
  {Item = "Base.ShotgunShellsBox", Number = 65, Count = 1}, -- Box of Shotgun Shells
  {Item = "Base.308Box", Number = 70, Count = 1}, -- Box of .308 Rounds
  {Item = "Base.556Box", Number = 75, Count = 1}, -- Box of 5.56mm Rounds
  {Item = "Base.LongJohns", Number = 80, Count = 1}, -- Long Johns
  {Item = "Base.Jumper_DiamondPatternTINT", Number = 85, Count = 1}, -- Diamond-pattern Sweater
  {Item = "Base.Jacket_Black", Number = 90, Count = 1}, -- Leather Jacket
  {Item = "Base.Apron_Spiffos", Number = 95, Count = 1}, -- Spiffo's Server Apron
  {Item = "Base.TrousersMesh_Leather", Number = 100, Count = 1}, -- Skinny Leather Trousers
  {Item = "Base.SpiffoSuit", Number = 105, Count = 1}, -- Spiffo Suit
  {Item = "Base.SpiffoTail", Number = 110, Count = 1}, -- Spiffo Suit Tail
  {Item = "Base.BunnyTail", Number = 115, Count = 1}, -- Bunny Tail
  {Item = "Base.Hat_HockeyMask", Number = 120, Count = 1}, -- Hockey Mask
  {Item = "Base.Hat_BunnyEarsBlack", Number = 125, Count = 1}, -- Bunny Ears (Black)
  {Item = "Base.Hat_BunnyEarsWhite", Number = 130, Count = 1}, -- Bunny Ears (White)
  {Item = "Base.Hat_Jay", Number = 135, Count = 1}, -- Jay Chicken Hat
  {Item = "Base.Hat_Spiffo", Number = 140, Count = 1}, -- Spiffo Suit Head
  {Item = "Base.Bag_ALICEpack_Army", Number = 145, Count = 1}, -- Military Backpack
  {Item = "Base.Bag_SurvivorBag", Number = 150, Count = 1}, -- Large Backpack
  {Item = "Base.Bag_ALICEpack", Number = 155, Count = 1}, -- Large Backpack
  {Item = "Base.WaterMugSpiffo", Number = 160, Count = 1}, -- Mug of Water
  {Item = "Base.CarBatteryCharger", Number = 165, Count = 1}, -- Car Battery Charger
  {Item = "Base.WoodAxe", Number = 170, Count = 1}, -- Wood Axe
  {Item = "Base.BoxOfJars", Number = 175, Count = 1}, -- Box of Jars
  {Item = "Base.CombinationPadlock", Number = 180, Count = 1}, -- Combination Padlock
  {Item = "Base.Padlock", Number = 185, Count = 1}, -- Padlock
  {Item = "Base.BurgerRecipe", Number = 190, Count = 1}, -- Burger
  {Item = "Base.AlcoholBandage", Number = 195, Count = 1}, -- Sterilized Bandage
  {Item = "Base.Comfrey", Number = 200, Count = 2}, -- Comfrey
  {Item = "Base.Ginseng", Number = 205, Count = 1}, -- Ginseng
  {Item = "Radio.RadioMag1", Number = 210, Count = 1}, -- Guerilla Radio Vol. 1
  {Item = "Radio.RadioMag2", Number = 215, Count = 1}, -- Guerilla Radio Vol. 2
  {Item = "Radio.RadioMag3", Number = 220, Count = 1}, -- Guerilla Radio Vol. 3
  {Item = "Base.HottieZ", Number = 225, Count = 1}, -- HottieZ
  {Item = "Base.EngineParts", Number = 230, Count = 1}, -- Spare Engine Parts
  {Item = "Base.Glue", Number = 235, Count = 1}, -- Glue
  {Item = "Base.Woodglue", Number = 240, Count = 1}, -- Wood Glue
  {Item = "Base.Aluminum", Number = 245, Count = 1}, -- Aluminum
  {Item = "Base.SheetMetal", Number = 250, Count = 1}, -- Metal Sheet
  {Item = "Base.Pillow", Number = 255, Count = 1}, -- Pillow
  {Item = "Base.PropaneTank", Number = 260, Count = 1}, -- Propane Tank
  {Item = "Base.SmallSheetMetal", Number = 265, Count = 1}, -- Small Metal Sheet
  {Item = "Radio.ElectricWire", Number = 270, Count = 1}, -- Electric Wire
  {Item = "Base.SpiffoBig", Number = 275, Count = 1}, -- Big Spiffo
  {Item = "Base.Spiffo", Number = 280, Count = 1}, -- Spiffo
  {Item = "Base.VHS_Home", Number = 290, Count = 1}, -- VHS Home
}

local function ZombKilled(zombie)
  local attacker = zombie:getAttackedBy()

  if attacker == nil or not instanceof(attacker, "IsoPlayer") or attacker:getVehicle() ~= nil then
    return
  end

  local number = ZombRandBetween(1, 501)
  local won = false

  for key, value in pairs(itemsAwards) do
    if (number == value.Number) then
      local itemName = getItemNameFromFullType(value.Item)
      zombie:getInventory():AddItems(value.Item, value.Count)
      if Awards.Options.showMessageInChat then
        attacker:Say(string.format(getText("IGUI_WonItem"), itemName, value.Count))
      else
        attacker:setHaloNote(string.format(getText("IGUI_WonItem"), itemName, value.Count))
      end
      won = true
      break
    end
  end

  if not won and Awards.Options.showNumberWhenLosing then
    if Awards.Options.showMessageInChat then
      attacker:Say(string.format(getText("IGUI_LoseItem"), number))
    else
      attacker:setHaloNote(string.format(getText("IGUI_LoseItem"), number), 255, 0, 0, 300)
    end
  end
end

Events.OnZombieDead.Add(ZombKilled)
