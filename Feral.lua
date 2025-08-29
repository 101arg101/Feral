Feral = {}
function Feral_OnLoad()
  this:RegisterEvent("PLAYER_ENTERING_WORLD")
  this:RegisterEvent("ADDON_LOADED")
  DEFAULT_CHAT_FRAME:AddMessage("Loading Feral...")
  SlashCmdList["FELINE"] = function(subcmd)
    local opts = {}
    opts.time = GetTime()
    opts.isTarget, opts.targetGUID = UnitExists("target")
    opts.curseOptions = {}
    opts.isStealth = isBuff(F_.stealthBuff)
    -- < 17 sec means the tiger's fury is tracked by the addon and we know there's less than 2 seconds left
    -- > 18 sec means the tiger's fury buff was manually cast, and the addon doesn't know how much time is left
    opts.isFury = isBuff(F_.tigersFuryBuff) and (opts.time - F_.lastFury < 17 or 18 < opts.time - F_.lastFury)
    opts.energy, opts.mana = UnitMana("player")
    opts.pts = GetComboPoints()
    opts.isReshiftable = opts.mana >= F_.shiftCost and F_.isReshift
    
    if (not opts.isTarget) then
      TargetNearestEnemy()
      opts.isTarget, opts.targetGUID = UnitExists("target")
    end
    
    if (subcmd == "1" or subcmd == "clawBite") then
      -- prowl, tiger's fury, pounce, rake, rip, claw-spam, ferocious bite
      clawBite(opts)
    elseif (subcmd == "2" or subcmd == "clawBleed") then
      -- prowl, tiger's fury, pounce, rake, claw-spam, rip
      clawBleed(opts)
    elseif (subcmd == "3" or subcmd == "shredBite") then
      -- prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
      shredBite(opts)
    elseif (subcmd == "4" or subcmd == "shredBleed") then
      -- prowl, tiger's fury, pounce, rake, shred-spam, rip
      shredBleed(opts)
    elseif (subcmd == "5" or subcmd == "multiBleed") then
      -- prowl, tiger's fury, pounce, rake, rip, cycle target
      multiBleed(opts)
      -- "multicurse"
      --  local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
      --  local options = parseOptions(optionsStr)
      --  Cursive:Multicurse(spellName, priority, curseOptions)
    elseif (subcmd == "6" or subcmd == "noBleedClaw") then
      -- prowl, tiger's fury, ravage, claw-spam, ferocious bite
      noBleedClaw(opts)
    elseif (subcmd == "7" or subcmd == "noBleedShred") then
      -- prowl, tiger's fury, ravage, shred-spam, ferocious bite
      noBleedShred(opts)
    elseif (subcmd == "8" or subcmd == "mauler") then
      -- Bear power shift
      mauler(opts)
    elseif (subcmd == "reload") then
      feralInit()
    elseif (subcmd == "help 1" or subcmd == "help clawBite") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 1")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral clawBite")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Won't wait for 5-point Rip. Builds up combo points with Claw for Ferocious Bite.")
    elseif (subcmd == "help 2" or subcmd == "help clawBleed") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 2")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral clawBleed")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake applied, then builds up combo points with Claw for a 5-point Rip.")
    elseif (subcmd == "help 3" or subcmd == "help shredBite") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 3")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral shredBite")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Won't wait for 5-point Rip. Builds up combo points with Shred for Ferocious Bite.")
    elseif (subcmd == "help 4" or subcmd == "help shredBleed") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 4")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral shredBleed")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake applied, then builds up combo points with Shred for a 5-point Rip.")
    elseif (subcmd == "help 5" or subcmd == "help multiBleed") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 5")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral multiBleed")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Won't wait for a 5-point Rip. Builds up combo points with Claw as long as all nearby targets have Rake and Rip.")
    elseif (subcmd == "help 6" or subcmd == "help noBleedClaw") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 6")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral noBleedClaw")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Ravage from stealth. Builds up combo points with Claw for Ferocious Bite.")
    elseif (subcmd == "help 7" or subcmd == "help noBleedShred") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 7")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral noBleedShred")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Casts Ravage from stealth. Builds up combo points with Shred for Ferocious Bite.")
    elseif (subcmd == "help 8" or subcmd == "help mauler") then
      DEFAULT_CHAT_FRAME:AddMessage("To use:")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral 8")
      DEFAULT_CHAT_FRAME:AddMessage("  /feral mauler")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Requires a Bear Form. Casts Reshift if you don't have enough energy for Maul and Enrage active.")
    else
      DEFAULT_CHAT_FRAME:AddMessage("To use Feral addon, create a macro that uses the following format:")
      DEFAULT_CHAT_FRAME:AddMessage("/feral [name or number of rotation]")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("The following rotations are implemented:")
      DEFAULT_CHAT_FRAME:AddMessage("1 clawBite: prowl, tiger's fury, pounce, rip, rake, claw-spam, ferocious bite")
      DEFAULT_CHAT_FRAME:AddMessage("2 clawBleed: prowl, tiger's fury, pounce, rake, claw-spam, rip")
      DEFAULT_CHAT_FRAME:AddMessage("3 shredBite: prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite")
      DEFAULT_CHAT_FRAME:AddMessage("4 shredBleed: prowl, tiger's fury, pounce, rake, shred-spam, rip")
      DEFAULT_CHAT_FRAME:AddMessage("5 multiBleed: prowl, tiger's fury, pounce, rake, rip, cycle target")
      DEFAULT_CHAT_FRAME:AddMessage("6 noBleedClaw: prowl, tiger's fury, ravage, claw-spam, ferocious bite")
      DEFAULT_CHAT_FRAME:AddMessage("7 noBleedShred: prowl, tiger's fury, ravage, shred-spam, ferocious bite")
      DEFAULT_CHAT_FRAME:AddMessage("8 mauler: maul")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("Example macro:")
      DEFAULT_CHAT_FRAME:AddMessage("/feral 1")
      DEFAULT_CHAT_FRAME:AddMessage(" ")
      DEFAULT_CHAT_FRAME:AddMessage("for more information about a rotation, use the command: /feral help [name or number of rotation]")
    end
  end
  
  F_ = {}
  SLASH_FELINE1 = "/feral"
  
  local loadBuffer = CreateFrame("Frame", "loadBuffer")
  loadBuffer:RegisterEvent("PLAYER_ENTERING_WORLD")
  loadBuffer:SetScript("OnEvent", feralInit)
end

function feralStealth(opts)
  if (not UnitAffectingCombat("player") and not opts.isStealth) then
    CastSpellByName("prowl")
  end
end

function feralFury(opts)
  if (F_.isFrenzy) then
    if (not opts.isFury) then
      if (opts.energy < 40 and opts.isReshiftable) then
        CastSpellByName("reshift")
      else
        CastSpellByName("tiger's fury")
        F_.lastFury = opts.time
      end
    end
  end
end

function feralPounce(opts)
  if (opts.isStealth) then
    CastSpellByName("pounce")
  end
end

function feralRip(opts)
  if (opts.pts > 0) then
    if (not F_.isFrenzy and opts.energy < F_.ripCost and opts.isReshiftable) then
      CastSpellByName("reshift")
    else
      Cursive:Curse("rip", opts.targetGUID, opts.curseOptions)
    end
  end
end

function feralRake(opts)
  if (not F_.isFrenzy and opts.energy < F_.rakeCost and opts.isReshiftable) then
    CastSpellByName("reshift")
  else
    Cursive:Curse("rake", opts.targetGUID, opts.curseOptions)
  end
end

function feralClaw(opts)
  if (not F_.isFrenzy and opts.energy < F_.clawCost and opts.isReshiftable) then
    CastSpellByName("reshift")
  else
    CastSpellByName("claw")
  end
end

function feralShred(opts)
  if (not F_.isFrenzy and opts.energy < F_.shredCost and opts.isReshiftable) then
    CastSpellByName("reshift")
  else
    CastSpellByName("shred")
  end
end

function feralFerocious(opts)
  if (not F_.isFrenzy and opts.energy < F_.ferociousCost and opts.isReshiftable) then
    CastSpellByName("reshift")
  else
    CastSpellByName("ferocious bite")
  end
end

function feralRavage(opts)
  if (opts.isStealth) then
    CastSpellByName("ravage")
  end
end

function reshiftOrCast(spellName, opts)
  if (not F_.isFrenzy and opts.energy < F_.costs[spellName] and opts.isReshiftable) then
    CastSpellByName("reshift")
  else
    CastSpellByName(spellName)
  end
end

function clawBite(opts)
  -- prowl, tiger's fury, pounce, rake, rip, claw-spam, ferocious bite
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    feralRip(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralClaw(opts)
    else
      feralFerocious(opts)
    end
  end
end

function clawBleed(opts)
  -- prowl, tiger's fury, pounce, rake, claw-spam, rip
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralClaw(opts)
    else
      if (Cursive.curses:HasCurse('rip', opts.targetGUID, 0)) then 
        feralFerocious(opts)
      else
        feralRip(opts)
      end
    end
  end
end

function shredBite(opts)
  -- prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    feralRip(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralShred(opts)
    else
      feralFerocious(opts)
    end
  end
end

function shredBleed(opts)
  -- prowl, tiger's fury, pounce, rake, shred-spam, rip
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralShred(opts)
    else
      if (Cursive.curses:HasCurse('rip', opts.targetGUID, 0)) then 
        feralFerocious(opts)
      else
        feralRip(opts)
      end
    end
  end
end

function multiBleed(opts)
  -- prowl, tiger's fury, pounce, rake, rip, cycle target
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    
    local isRip = Cursive.curses:HasCurse("rip", opts.targetGUID, 0)
    local isRake = Cursive.curses:HasCurse("rake", opts.targetGUID, 0)
    
    if (not isRake) then
      CastSpellByName("rake")
    elseif (isRake and not isRip) then
      CastSpellByName("rip")  
    else
      -- cursive does not want to target neutral mobs, even if they're attacking you :(
      local nextGUID = Cursive:GetTarget("rake", "HIGHEST_HP_RAID_MARK", opts.curseOptions)
      if (nextGUID and not Cursive.curses:HasCurse("rake", nextGUID, 0)) then
        TargetUnit(nextGUID)
        opts.targetGUID = nextGUID
        CastSpellByName("rake")
      elseif (opts.pts < 5) then
        CastSpellByName("claw")
      elseif (opts.pts >= 5) then
        CastSpellByName("ferocious bite")
      end
    end
  end
end

function noBleedClaw(opts)
  -- prowl, tiger's fury, ravage, claw-spam, ferocious bite
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralRavage(opts)
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralClaw(opts)
    else
      feralFerocious(opts)
    end
  end
end

function noBleedShred(opts)
  -- prowl, tiger's fury, ravage, shred-spam, ferocious bite
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralRavage(opts)
    -- spam moves until max combo points
    if (opts.pts < 5) then
      feralShred(opts)
    else
      feralFerocious(opts)
    end
  end
end

function mauler(opts)
  if (opts.energy < F_.maulCost and F_.maulCost <= 10 and opts.isReshiftable and not isBuff(F_.enrageBuff) and not isBuff(F_.brutalityBuff)) then
    CastSpellByName('Reshift')
  else
    CastSpellByName('Maul')
  end
end

function feralInit()
  local _, _, _, _, natShifterCurrRank, _ = GetTalentInfo(1, 8)
  local _, _, _, _, furorCurrRank, _ = GetTalentInfo(3, 2)
  local _, _, _, _, ferocityCurrRank, _ = GetTalentInfo(2, 1)
  local _, _, _, _, shredCurrRank, _ = GetTalentInfo(2, 13)
  local _, _, _, _, frenzyCurrRank, _ = GetTalentInfo(2, 12)
  local baseint, int = UnitStat("player", 4)
  local maxMana = UnitManaMax("player")
  local extraMana = 0
  local idol = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot"))
  local helm = GetInventoryItemLink("player", 1)
  local shoulder = GetInventoryItemLink("player", 3)
  local chest = GetInventoryItemLink("player", 5)
  local belt = GetInventoryItemLink("player", 6)
  local pants = GetInventoryItemLink("player", 7)
  local boots = GetInventoryItemLink("player", 8)
  local bracers = GetInventoryItemLink("player", 9)
  local gloves = GetInventoryItemLink("player", 10)
  
  F_.catFormID = 0
  F_.bearFormID = 0
  F_.tigersFuryBuff = "Ability_Mount_JungleTiger"
  F_.stealthBuff = "Ability_Ambush"
  F_.enrageBuff = "Ability_Druid_Enrage"
  F_.brutalityBuff = "Spell_Shadow_UnholyFrenzy"
  F_.maulCost   = 15 - ferocityCurrRank
  F_.swipeCost  = 20 - ferocityCurrRank
  F_.savageCost = 25 - ferocityCurrRank
  F_.clawCost   = 45 - ferocityCurrRank
  F_.rakeCost   = 40 - ferocityCurrRank
  F_.shredCost  = 60 - shredCurrRank*6
  F_.furyCost = 30
  F_.ferociousCost = 35
  F_.ripCost = 30
  F_.isReshift = furorCurrRank == 5
  F_.isFrenzy = frenzyCurrRank == 2
  F_.genesisSet = 0
  F_.cenarionSet = 0
  F_.lastFury = GetTime()
  F_.costs = {}
  
  if (helm ~= nil) then
    if (string.find(helm, "Genesis Helmet")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(helm, "Cenarion Helmet")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (shoulder ~= nil) then
    if (string.find(shoulder, "Genesis Shoulderpads")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(shoulder, "Cenarion Shoulderpads")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (chest ~= nil) then
    if (string.find(chest, "Genesis Raiments")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(chest, "Cenarion Raiments")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (belt ~= nil) then
    if (string.find(belt, "Genesis Girdle")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(belt, "Cenarion Girdle")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (pants ~= nil) then
    if (string.find(pants, "Genesis Pants")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(pants, "Cenarion Pants")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (boots ~= nil) then
    if (string.find(boots, "Genesis Treads")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(boots, "Cenarion Treads")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (bracers ~= nil) then
    if (string.find(bracers, "Genesis Wristguards")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(bracers, "Cenarion Wristguards")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  if (gloves ~= nil) then
    if (string.find(gloves, "Genesis Handguards")) then
      F_.genesisSet = F_.genesisSet + 1
    elseif (string.find(gloves, "Cenarion Handguards")) then
      F_.cenarionSet = F_.cenarionSet + 1
    end
  end
  
  if (idol ~= nil and string.find(idol, "Idol of Ferocity")) then
    F_.clawCost = F_.clawCost - 3
    F_.rakeCost = F_.rakeCost - 3
  end
  
  if (idol ~= nil and string.find(idol, "Idol of Brutality")) then
    F_.maulCost = F_.maulCost - 3
    F_.swipeCost = F_.swipeCost - 3
  end
  
  if (F_.genesisSet >= 3) then
    F_.clawCost = F_.clawCost - 3
    F_.rakeCost = F_.rakeCost - 3
    F_.shredCost = F_.shredCost - 3
  end
  
  if (F_.cenarionSet >= 5) then
    F_.furyCost = F_.furyCost - 5
  end
  
  if (isBuff("Flask_of_Wisdom")) then
    extraMana = 2000
  end
  
  local baseMana = maxMana - min(20, int) - 15 * (int - min(20, int)) - extraMana
  F_.shiftCost = math.floor((baseMana * .35) * (1 - (natShifterCurrRank * .10)))
  if (itemLink ~= nil and string.find(idol, "Idol of the Wildshifter")) then
    F_.shiftCost = F_.shiftCost - 75
  end
  
  local active = nil
  for i = 1, GetNumShapeshiftForms(), 1 do
    local _, formName, active = GetShapeshiftFormInfo(i)
    
    if (formName == "Cat Form") then
      F_.catFormID = i
    end
    
    if (formName == "Bear Form") then
      F_.bearFormID = i
    end
    
    if (formName == "Dire Bear Form") then
      F_.bearFormID = i
    end
  end
  
  if (F_.catFormID == 0) then
    DEFAULT_CHAT_FRAME:AddMessage("Cat Form not detected.")
  elseif (F_.bearFormID == 0) then
    DEFAULT_CHAT_FRAME:AddMessage("Bear Form not detected.")
  else
    DEFAULT_CHAT_FRAME:AddMessage("Feral addon loaded. Type /feral for help.")
  end
end

function isBuff(texture)
  local i = 0
  local g = GetPlayerBuff

  while not (g(i) == -1) do
    if (GetPlayerBuffTexture(g(i)) == "Interface\\Icons\\"..texture) then
      return true
    end
    i = i + 1
  end
  return false
end

function isCat()
  local _, _, active = GetShapeshiftFormInfo(F_.catFormID)
  return active ~= nil
end

function isBear()
  local _, _, active = GetShapeshiftFormInfo(F_.bearFormID)
  return active ~= nil
end

function testLog(out)
  print(tostring(out))
end