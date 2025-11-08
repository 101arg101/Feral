Feral = {}
function Feral_OnLoad()
  this:RegisterEvent("PLAYER_ENTERING_WORLD")
  this:RegisterEvent("ADDON_LOADED")
  DEFAULT_CHAT_FRAME:AddMessage("Loading Feral...")
  SlashCmdList["FELINE"] = function(subcmd)
    if (subcmd == "reload") then
      feralInit()
    else
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
      opts.alwaysRip = false
      
      if (not opts.isTarget) then
        TargetNearestEnemy()
        opts.isTarget, opts.targetGUID = UnitExists("target")
      end
      
      opts.isClearcast = CatDruidDPS_isBuffTextureActive("Spell_Shadow_ManaBurn")
      local baseAP, posBuffAP, negBuffAP = UnitAttackPower("player")
      local ap = baseAP + posBuffAP + negBuffAP
      
      
      if (opts.isClearcast) then
        opts.fbAdditionalEnergy = opts.energy
      else
        opts.fbAdditionalEnergy = opts.energy - F_.ferociousCost
      end
      
      if(opts.isTarget and opts.pts > 0) then
        local expectedArmor = 50*UnitLevel("target")
        
        if expectedArmor < 0 then
          expectedArmor = 3731
        end
        
        local isSunder, sunderCount = isDebuff("Ability_Warrior_Sunder")
        local isFF = isDebuff("Spell_Nature_FaerieFire")
        local isReckless = isDebuff("Spell_Shadow_UnholyStrength")
        
        -- TODO: figure out ranks to make expectedArmor more accurate
        expectedArmor = expectedArmor - sunderCount*450
        if (isFF) then
          expectedArmor = expectedArmor - 505
        end
        
        if (isReckless) then
          expectedArmor = expectedArmor - 640
        end
        
        opts.fbDMG = math.floor(
          (1 - expectedArmor/ (expectedArmor + 400 + 85 * UnitLevel("player"))) * (ap * 0.1526 + opts.fbAdditionalEnergy * F_.fbEnergyScale + opts.pts * F_.fbCPScale + F_.fbFlat) * (1 + F_.aggressionCurrRank * .03)
        )
        
        if (F_.genesisSet == 5) then
          opts.fbDMG = opts.fbDMG*1.15
        end
      else
        opts.fbDMG = 0
      end
      opts.deathETA = deathETA(opts.fbDMG)
      
      if (subcmd == "0" or subcmd == "maul") then
        -- Bear power shift
        mauler(opts)
      elseif (subcmd == "1" or subcmd == "multibleed") then
        -- prowl, tiger's fury, pounce, rake, rip, cycle target
        multiBleed(opts)
      elseif (subcmd == "2" or subcmd == "claw-bite") then
        -- prowl, tiger's fury, pounce, rake, rip, claw-spam, ferocious bite
        clawBite(opts)
      elseif (subcmd == "3" or subcmd == "claw-rip") then
        -- prowl, tiger's fury, pounce, rake, claw-spam, rip
        clawBleed(opts)
      elseif (subcmd == "4" or subcmd == "shred-bite") then
        -- prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
        shredBite(opts)
      elseif (subcmd == "5" or subcmd == "shred-rip") then
        -- prowl, tiger's fury, pounce, rake, shred-spam, rip
        shredBleed(opts)
      elseif (subcmd == "6" or subcmd == "claw-nobleed") then
        -- prowl, tiger's fury, ravage, claw-spam, ferocious bite
        noBleedClaw(opts)
      elseif (subcmd == "7" or subcmd == "shred-nobleed") then
        -- prowl, tiger's fury, ravage, shred-spam, ferocious bite
        noBleedShred(opts)
      elseif (subcmd == "8" or subcmd == "auto-bite") then
        -- detect if behind then claw/shred
        if UnitXP("behind","player","target") then
          shredBite(opts)
        else
          clawBite(opts)
        end
      elseif (subcmd == "9" or subcmd == "auto-rip") then
        -- detect if behind then claw/shred
        if UnitXP("behind","player","target") then
          shredBleed(opts)
        else
          clawBleed(opts)
        end
      elseif (subcmd == "10" or subcmd == "auto-nobleed") then
        -- detect if behind then claw/shred
        if UnitXP("behind","player","target") then
          noBleedShred(opts)
        else
          noBleedClaw(opts)
        end
      elseif (subcmd == "help 0" or subcmd == "help maul") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 0")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral maul")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Requires a Bear Form. Casts Reshift if you don't have enough energy for Maul and don't have Enrage active.")
      elseif (subcmd == "help 1" or subcmd == "help multibleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 1")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral multibleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Builds up combo points with Shred/Claw as long as all nearby targets have Rake and Rip.")
      elseif (subcmd == "help 2" or subcmd == "help claw-bite") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 2")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral claw-bite")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Keeps Rake and 1-point Rip applied. Builds up combo points with Claw for Ferocious Bite.")
      elseif (subcmd == "help 3" or subcmd == "help claw-bleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 3")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral claw-bleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake applied, then builds up combo points with Claw for a 5-point Rip.")
      elseif (subcmd == "help 4" or subcmd == "help shred-bite") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 4")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral shred-bite")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake and Rip applied. Won't wait for 5-point Rip. Builds up combo points with Shred for Ferocious Bite.")
      elseif (subcmd == "help 5" or subcmd == "help shred-bleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 5")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral shred-bleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Keeps Rake applied, then builds up combo points with Shred for a 5-point Rip.")
      elseif (subcmd == "help 6" or subcmd == "help claw-nobleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 6")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral claw-nobleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Ravage from stealth. Builds up combo points with Claw for Ferocious Bite.")
      elseif (subcmd == "help 7" or subcmd == "help shred-nobleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 7")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral shred-nobleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Ravage from stealth. Builds up combo points with Shred for Ferocious Bite.")
      elseif (subcmd == "help 8" or subcmd == "help auto-bite") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 8")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral auto-bite")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Uses UnitXP to detect if you're behind the target and chooses to Shred or Claw. Keeps Rake and 1-point Rip applied. Builds up combo points for Ferocious Bite.")
      elseif (subcmd == "help 9" or subcmd == "help auto-rip") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 9")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral auto-rip")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Pounce from stealth. Uses UnitXP to detect if you're behind the target and chooses to Shred or Claw. Keeps Rake and 1-point Rip applied. Builds up combo points for Rip.")
      elseif (subcmd == "help 10" or subcmd == "help auto-nobleed") then
        DEFAULT_CHAT_FRAME:AddMessage("To use:")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral 9")
        DEFAULT_CHAT_FRAME:AddMessage("  /feral auto-nobleed")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Casts Ravage from stealth. Uses UnitXP to detect if you're behind the target and chooses to Shred or Claw. Builds up combo points for Ferocious Bite.")
      else
        DEFAULT_CHAT_FRAME:AddMessage("To use Feral addon, create a macro that uses the following format:")
        DEFAULT_CHAT_FRAME:AddMessage("/feral [name or number of rotation]")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("The following rotations are implemented:")
        DEFAULT_CHAT_FRAME:AddMessage("0 maul: maul")
        DEFAULT_CHAT_FRAME:AddMessage("1 multibleed: prowl, tiger's fury, pounce, rake, rip, cycle target")
        DEFAULT_CHAT_FRAME:AddMessage("2 claw-bite: prowl, tiger's fury, pounce, rip, rake, claw-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage("3 claw-rip: prowl, tiger's fury, pounce, rake, claw-spam, rip")
        DEFAULT_CHAT_FRAME:AddMessage("4 shred-bite: prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage("5 shred-rip: prowl, tiger's fury, pounce, rake, shred-spam, rip")
        DEFAULT_CHAT_FRAME:AddMessage("6 claw-nobleed: prowl, tiger's fury, ravage, claw-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage("7 shred-nobleed: prowl, tiger's fury, ravage, shred-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage("8 auto-bite: prowl, tiger's fury, pounce, claw/shred-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage("9 auto-rip: prowl, tiger's fury, pounce, claw/shred-spam, rip")
        DEFAULT_CHAT_FRAME:AddMessage("10 auto-nobleed: prowl, tiger's fury, ravage, claw/shred-spam, ferocious bite")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("Example macro:")
        DEFAULT_CHAT_FRAME:AddMessage("/feral 1")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        DEFAULT_CHAT_FRAME:AddMessage("for more information about a rotation, use the command: /feral help [name or number of rotation]")
      end
    end
  end
  
  F_ = {}
  SLASH_FELINE1 = "/feral"
  
  local loadBuffer = CreateFrame("Frame", "loadBuffer")
  --loadBuffer:RegisterEvent("PLAYER_ENTERING_WORLD")
  loadBuffer:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- this fixes the problem of talents not being loaded when the addon is first loaded in
  loadBuffer:SetScript("OnEvent", feralInit)
end

function feralInit()
  local _, _, _, _, natShifterCurrRank, _ = GetTalentInfo(1, 8)
  local _, _, _, _, furorCurrRank, _ = GetTalentInfo(3, 2)
  local _, _, _, _, ferocityCurrRank, _ = GetTalentInfo(2, 1)
  local _, _, _, _, aggressionCurrRank, _ = GetTalentInfo(2, 2)
  local _, _, _, _, woundsCurrRank, _ = GetTalentInfo(2, 6)
  local _, _, _, _, shredCurrRank, _ = GetTalentInfo(2, 13)
  local _, _, _, _, frenzyCurrRank, _ = GetTalentInfo(2, 12)
  local _, _, _, _, carnageCurrRank, _ = GetTalentInfo(2, 17)
  local _, _, _, _, heartCurrRank, _ = GetTalentInfo(2, 16)
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
  F_.aggressionCurrRank = aggressionCurrRank
  F_.heartCurrRank = heartCurrRank
  F_.furyCost = 30
  F_.ferociousCost = 35
  F_.ripCost = 30
  F_.isReshift = furorCurrRank == 5
  F_.isFrenzy = frenzyCurrRank == 2
  F_.genesisSet = 0
  F_.cenarionSet = 0
  F_.lastFury = GetTime() -  15
  F_.costs = {}
  F_.group = false
  F_.lastShadowburn = GetTime() - 15
  
  if GetNumPartyMembers() > 0 then F_.group = "party" end
  if GetNumRaidMembers() > 0 then F_.group = "raid" end
  
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
  
  F_.savageryIdolB = nil
  F_.savageryIdolS = nil
  F_.savageryIdolLink = nil
  F_.altIdolB = nil
  F_.altIdolS = nil
  F_.altIdolN = nil
  F_.altIdolL = nil
  
  if(F_.catFormID > 0) then
    indexIdols()
    
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
    
    if (idol ~= nil and string.find(idol, "Idol of Ferocity") and not F_.isIdolSwap) then
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
  end
  
  if (F_.catFormID == 0) then
    DEFAULT_CHAT_FRAME:AddMessage("Cat Form not detected.")
  elseif (F_.bearFormID == 0) then
    DEFAULT_CHAT_FRAME:AddMessage("Bear Form not detected.")
  else
    F_.fbEnergyScale = 0
    F_.fbFlat        = 0
    F_.fbCPScale     = 0
    local biteRank = ""
  
    local i = 1
    while true do
      local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
      if not spellName then
        do
          break
        end
      end
      if (spellName == "Ferocious Bite") then
        biteRank = spellRank
      end
      i = i + 1
    end
    
    if (biteRank == "Rank 1") then
      F_.fbEnergyScale = 1
      F_.fbFlat        = 4
      F_.fbCPScale     = 31
    end
    if (biteRank == "Rank 2") then
      F_.fbEnergyScale = 1
      F_.fbFlat        = 14
      F_.fbCPScale     = 36
    end
    if (biteRank == "Rank 3") then
      F_.fbEnergyScale = 1.5
      F_.fbFlat        = 20
      F_.fbCPScale     = 59
    end
    if (biteRank == "Rank 4") then
      F_.fbEnergyScale = 2
      F_.fbFlat        = 30
      F_.fbCPScale     = 92
    end
    if (biteRank == "Rank 5") then
      F_.fbEnergyScale = 2.5
      F_.fbFlat        = 45
      F_.fbCPScale     = 128
    end
    if (biteRank == "Rank 6") then
      F_.fbEnergyScale = 2.7
      F_.fbFlat        = 52
      F_.fbCPScale     = 147
    end
    DEFAULT_CHAT_FRAME:AddMessage("Feral addon loaded. Type /feral for help.")
  end
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
    elseif(opts.alwaysRip) then
      CastSpellByName("rip")
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

function feralClawShred(opts)
  if (opts.isBehind) then
    feralClaw(opts)
  else
    feralShred(opts)
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
  equipIdol("Idol of Ferocity")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    feralRip(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
      feralClaw(opts)
    else
      feralFerocious(opts)
    end
  end
end

function clawBleed(opts)
  -- prowl, tiger's fury, pounce, rake, claw-spam, rip
  testSwap("Idol of Ferocity")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
      feralClaw(opts)
    else
      opts.alwaysRip = true
      feralRip(opts)
      -- ferocious bite disabled to allow players to force a 5 point rip
      
      -- if (Cursive.curses:HasCurse('rip', opts.targetGUID, 0)) then 
      --   feralFerocious(opts)
      -- else
      --   feralRip(opts)
      -- end
    end
  end
end

function shredBite(opts)
  -- prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
  equipIdol("Idol of the Emerald Rot")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    feralRip(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
      feralShred(opts)
    else
      feralFerocious(opts)
    end
  end
end

function shredBleed(opts)
  -- prowl, tiger's fury, pounce, rake, shred-spam, rip
  testSwap("Idol of Savagery")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralPounce(opts)
    -- if (Cursive.curses:HasCurse('rake', opts.targetGUID, 0)) then
    feralRake(opts)
    --end
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
      feralShred(opts)
    else
      opts.alwaysRip = true
      feralRip(opts)
      -- ferocious bite disabled to allow players to force a 5 point rip
      
      --if (Cursive.curses:HasCurse('rip', opts.targetGUID, 0)) then 
      --  feralFerocious(opts)
      --else
        feralRip(opts)
      --end
    end
  end
end

function multiBleed(opts)
  -- prowl, tiger's fury, pounce, rake, rip, cycle target
  equipIdol("Idol of savagery")
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
        if UnitXP("behind","player","target") then
          CastSpellByName("shred")
        else
          CastSpellByName("claw")
        end
      elseif (opts.pts >= 5) then
        CastSpellByName("ferocious bite")
      end
    end
  end
end

function noBleedClaw(opts)
  -- prowl, tiger's fury, ravage, claw-spam, ferocious bite
  equipIdol("Idol of Ferocity")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralRavage(opts)
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
      feralClaw(opts)
    else
      feralFerocious(opts)
    end
  end
end

function noBleedShred(opts)
  -- prowl, tiger's fury, ravage, shred-spam, ferocious bite
  equipIdol("Idol of Laceration")
  feralStealth(opts)
  feralFury(opts)
  if (opts.isTarget) then
    feralRavage(opts)
    -- spam moves until max combo points
    if (opts.pts > 0 and opts.deathETA <= 2) then
      print("early FB")
      CastSpellByName("ferocious bite")
    elseif (opts.pts < 5) then
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

function isDebuff(debuff)
  local retval = false
  local retcount = 0
  for i = 1, 32 do
    local d, c = UnitDebuff("target", i)
    if (d and "Interface\\Icons\\"..debuff == d) then
      retval = true
      if (c) then
        retcount = c
      end
    end
  end
  return retval, retcount
end

function deathETA(untilHP)
  local targetExist, targetGUID = UnitExists("target")
  
  -- for k,v in pairs(ShaguDPS.data.damage[0]) do print(k) end

  local shaguName = nil
  local shaguValue = nil
  local memberExist = nil
  local memberName = nil
  local memberI = nil
  local memberTarget = nil
  local mtGUID = nil
  local totalDPS = 1 -- start at 1 to prevent division by 0
  if (not untilHP) then
    untilHP = 0
  end
  
  
  
  if F_.group == "party" then
    memberTarget, mtGUID = UnitExists("target")
    memberName = UnitName("player")
    shaguValue = ShaguDPS.data.damage[0][memberName]
    if (memberTarget and shaguValue and shaguValue._ctime >= 30) then
      -- print(memberName.." is targeting "..UnitName(mtGUID))
      -- print("  dps: "..(tostring(shaguValue._sum/shaguValue._ctime)))    
      totalDPS = totalDPS + shaguValue._sum/shaguValue._ctime
    end
    
    for i = 1, 4, 1 do
      memberI = "party"..i
      memberExist = UnitExists(memberI)
      memberTarget, mtGUID = UnitExists(memberI.."target")
      memberName = UnitName(memberI)
      shaguValue = ShaguDPS.data.damage[0][memberName]
      if (memberExist and memberTarget and shaguValue and shaguValue._ctime >= 30) then
        -- print(memberName.." is targeting "..UnitName(mtGUID))
        -- print("  dps: "..(tostring(shaguValue._sum/shaguValue._ctime)))    
        totalDPS = totalDPS + shaguValue._sum/shaguValue._ctime
      end
    end
  elseif F_.group == "raid" then
    for i = 1, 40, 1 do
      memberI = "raid"..i
      memberExist = UnitExists(memberI)
      memberTarget, mtGUID = UnitExists(memberI.."target")
      memberName = UnitName(memberI)
      shaguValue = ShaguDPS.data.damage[0][memberName]
      if (memberExist and memberTarget and shaguValue and shaguValue._ctime >= 30) then
        -- print(memberName.." is targeting "..UnitName(mtGUID))
        -- print("  dps: "..(tostring(shaguValue._sum/shaguValue._ctime)))    
        totalDPS = totalDPS + shaguValue._sum/shaguValue._ctime
      end
    end
  else
    memberTarget, mtGUID = UnitExists("target")
    memberName = UnitName("player")
    shaguValue = ShaguDPS.data.damage[0][memberName]
    if (memberTarget and shaguValue and shaguValue._ctime >= 30) then
      -- print(memberName.." is targeting "..UnitName(mtGUID))
      -- print("  dps: "..(tostring(shaguValue._sum/shaguValue._ctime)))    
      totalDPS = totalDPS + shaguValue._sum/shaguValue._ctime
    end
  end
  
  return (UnitHealth("target") - untilHP)/(totalDPS)
end

function eineLock(curseName)
  local _TT, _TG = UnitExists("target")
  local _TA = Cursive.curses:HasCurse("curse of agony", _TG, 0)
  local _TS = Cursive.curses:HasCurse("curse of shadow", _TG, 0)
  local _TC = Cursive.curses:HasCurse("corruption", _TG, 0)
  local _TV = Cursive.curses:HasCurse("shadow vulnerability", _TG, 0)
  local _TE = deathETA()
  print(_TE)
  if(_TT) then
    if(isBuff("Spell_Shadow_Twilight")) then
      CastSpellByName("Shadow Bolt")
    else
      if(_TA and _TC) then
        if(_TE <= 8) then
          CastSpellByName("Dark Harvest")
        else
          CastSpellByName("Drain Soul")
        end
      else
        if(_TE <= 5) then
          CastSpellByName("Drain Soul")
        elseif(_TE <= 10 and (_TA or _TC)) then
          Cursive:Curse(curseName, _TG, {refreshtime=4})
          Cursive:Curse("curse of agony", _TG, {refreshtime=4})
          Cursive:Curse("Corruption", _TG, {refreshtime=4})
          CastSpellByName("Dark Harvest")
        end
        Cursive:Curse(curseName, _TG, {})
        Cursive:Curse("curse of agony", _TG, {})
        Cursive:Curse("Corruption", _TG, {})
      end
    end
  end
end

function zweiLock(curseName)
  local _TT, _TG = UnitExists("target")
  local _TC = Cursive.curses:HasCurse(curseName, _TG, 0)
  local _TI = Cursive.curses:HasCurse("immolate", _TG, 0)
  local _TE = deathETA()
  local _TD = UnitXP("distanceBetween", "player", "target")
  local _TS = UnitXP("inSight", "player", "target")
  print(_TE)
  
  if(_TT and _TE <= 4 and F_.lastShadowburn + 15 <= GetTime() and _TD < 24 and _TS) then
    CastSpellByName("Shadowburn")
    F_.lastShadowburn = GetTime()
  elseif((not isBuff("Spell_Fire_Fireball02") and not UnitAffectingCombat("player")) or (not isBuff("Spell_Fire_Fireball02") and _TE >= 5)) then
    CastSpellByName("Soul Fire")
  elseif(_TE >= 15 and not _TC) then
    Cursive:Curse(curseName, _TG, {refreshtime=1})
  else
    Cursive:Curse("immolate", _TG, {refreshtime=1})
    CastSpellByName("Conflagrate")
    CastSpellByName("Searing Pain")
  end
end

function einePally(sealName)
  local _TT, _TG = UnitExists("target")
  
  if (not _TT) then
    TargetNearestEnemy()
    _TT, _TG = UnitExists("target")
  end
  
  local buffName = string.lower("seal of "..sealName)
  local curseName = string.lower("judgement of "..sealName)
  
  if(string.lower(sealName) == "crusader") then
    buffName = string.lower("seal of the "..sealName)
    curseName = string.lower("judgement of the "..sealName)
  end
  
  local sealTexturesAssoc = {
    ["seal of wisdom"] = "Spell_Holy_RighteousnessAura",
    ["seal of righteousness"] = "Ability_Thunderbolt",
    ["seal of the crusader"] = "Spell_Holy_HolySmite",
    ["seal of justice"] = "Spell_Holy_SealOfWrath"
  }
  
  local _TC = isDebuff(sealTexturesAssoc[buffName])
  local _TE = deathETA()
  
  print(" ")
  print("targeting: ".._TG)
  print("has buff?")
  print(isBuff(sealTexturesAssoc[buffName]))
  print("has curse?")
  print(_TC)
  
  
  if(pallyLastConsecrate + 8 < GetTime()) then
    pallyLastConsecrate = GetTime()
    CastSpellByName("Consecrate")
  end
  
  if(not isBuff("Spell_Holy_BlessingOfProtection")) then
    print("  shield")
    CastSpellByName("Holy Shield")
  end
  
  if(_TT) then
    if (not isBuff(sealTexturesAssoc[buffName])) then
      print("  seal")
      CastSpellByName(buffName)
    elseif (_TC) then
      print("  strike")
      CastSpellByName("Holy Strike")
    else
      print("  judge")
      CastSpellByName("Judgement")
    end
  end
end

Idol = {}
Idol._index = idol
idols = {}
function Idol:new(name, idolBag, idolSlot, idolLink)
  local obj= {
    name = name
    bag = idolBag
    slot = idolSlot
    link = idolLink
  }
  setmetatable(obj, Idol)
  return obj
end

function Idol:positonSwap(idol1, idol2)
  idol1.bag = idol2.bag
  idol2.slot = idol2.slot
  idol2.bag = nil
  idol2.slot = nil
  return idol1,idol2
end
  

function contains(keyContainer,comparisonValue)
  for _, v in ipairs(keyContainer) do
        if v == value then
          return true 
        end
    end
    return false
end

function testInit()
  local equippedLink = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot"))
  local availableIdols = {"Idol of the Wildshifter", "Idol of Ferocity", "Idol of the Emerald Rot", "Idol of Laceration"}

  for bag=0,4 do
    for slot=1,GetContainerNumSlots(bag) do
      local itemLink = GetContainerItemLink(bag, slot); -- |Hitem:6948:0:0:0:0:0:0:0|h[Idol of Ferocity]|h
      if contains(availableIdols, localName=string.find(equippedLink, "%[.+%]")) then
        idols[localName] = Idol:new(localName, b,s, itemLink)
      end
    end
  end

  if (equippedLink ~= nil) then
    local idolName = string.find(equippedLink, "%[.+%]")
    idols[idolName] = Idol:new(idolName, nil, nil, equippedLink)
    print("idol equipped: "..idolName)
  end
end


function equipIdol(idolToEquip)
  if (F_.isIdolSwap) then
    local idolEquippedLink = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot"))
    eqIdol = idols[string.find(idolEquippedLink, "%[.+%]")]
    target = idols[idolToEquip]
    if eqIdol ~= nil and  target ~= nil then
      Idol:positionSwap(eqIdol, target)
      print("  equip: "..target.name)
      PickupContainerItem(target.bag, target.slot);
      EquipCursorItem(18);
    elseif eqIdol == nil then
      print("  No Idol Equipped")
    elseif target == nil then
      print("  The idol is not in your bags")
    end
  else
    print("  Unable to equip"..target.name)
end

function indexIdols()
  local equippedLink = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot"))
  local availableIdols = {"Idol of the Wildshifter", "Idol of Ferocity", "Idol of the Emerald Rot", "Idol of Laceration"}
  for bag=0,4 do
    for slot=1,GetContainerNumSlots(bag) do
      local itemLink = GetContainerItemLink(bag, slot); -- |Hitem:6948:0:0:0:0:0:0:0|h[Idol of Ferocity]|h
      if contains(availableIdols, localName=string.find(equippedLink, "%[.+%]")) then
        idols[localName] = Idol:new(localName, b,s, itemLink)
      end
    end
  end
  
  -- enable swapping with multiple idols
  for k,v in pairs(idols)
    count = count+1
    if count > 1 then
      f_.isIdolSwap = true
    else
      f_.isIdolSwap = false
    end
  end
end

function testSwap(idolToEquip)
  if (F_.isIdolSwap) then
    --local _TT,_TG=UnitExists("target"); local idol = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot")); local idolEquipped = nil; if (idol ~= nil) then if (string.find(idol, "Idol of the Emerald Rot")) then idolEquipped = "ferocity";elseif (string.find(idol, "Idol of Savagery")) then idolEquipped = "savagery";end;end;if (Cursive.curses:HasCurse("rip",_TG,0)) then if(idolEquipped ~= "ferocity") then PickupContainerItem(_GlobalFerocityB,_GlobalFerocityS);EquipCursorItem(18);end;elseif(idolEquipped ~= "savagery") then PickupContainerItem(_GlobalSavageryB,_GlobalSavageryS);EquipCursorItem(18);end
    local _TT,_TG=UnitExists("target");
    local idolEquipped = GetInventoryItemLink("player", GetInventorySlotInfo("RangedSlot"))
    eqIdol = idols[string.find(idolEquipped, "%[.+%]")]
    target = idols[idolToEquip]
    
    if (_TT and Cursive.curses:HasCurse("rip", _TG, 0)) then
      if (idolEquipped ~= target.name) then
        print("  equip: "..target.name)
        PickupContainerItem(target.bag, target.slot);
        EquipCursorItem(18);
        Idol:positionSwap(eqIdol,target)
      end
    end
  end
end