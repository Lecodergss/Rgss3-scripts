#==============================================================================
# ▼ Instructions
#==============================================================================
# If you didn't read instructions in the core script, do it !
# Also, look theses pre-made challenges for more details
# Template is:
#
# OCCASION = {
#
# "Challenge Name" =>
# "
# code
# ",
#
# }
#
# Do not modify OCCASION, write simply your instrution inside the occasion scope
#==============================================================================

module Lecode_Challenge_Maker
  
  #========================================
  # Occurs on battle start
  # Keys :
  # chall => The chall itSelf
  # $game_temp.chall_usual_vars => an array
  # for some purposes...
  #========================================
  On_Battle_Start = {
  
  "Assassination" =>
  "
  index = rand($game_troop.members.size)
  target = $game_troop.members[index]
  $game_temp.chall_usual_vars[0] = target.name
  chall.description = 'Kill '+target.name.to_s+' firstly'
  ",
  
  "Foreseeing" =>
  "
  for mem in $game_party.members
    hp_perc = mem.hp*100/mem.mhp
    if hp_perc < 75
      fail = true
      break
    end
  end
  if !fail
    success = true
  end
  "
  
  }
  
  #========================================
  # Occurs when the battle end
  #========================================
  On_Battle_End = {
  
  "Perfect" =>
  "
  for mem in $game_party.members
    if mem.hp < mem.mhp
      fail = true
      break
    end
  end
  ",
  
  "Survivor" =>
  "
  for mem in $game_party.members
    if mem.dead?
      fail = true
      break
    end
  end
  ",
  
  "Rage" =>
  "
  for mem in $game_party.members
    if mem.tp >= 100
      success = true
      break
    end
  end
  ",
  
  "Fast and Furious" =>
  "
  if $game_troop.turn_count <= 3
    success = true
  end
  "
  }
  
  #========================================
  # Occurs when someone ends his turn
  # Keys :
  # battler => One who has finished his turn
  #========================================
  On_Turn_End = {
  
  "Rage" =>
  "
  if battler.tp >= 100
    success = true
  end
  ",
  
  "Fast and Furious" =>
  "
  if $game_troop.turn_count > 3
    fail = true
  end
  ",
  
  }
  
  #========================================
  # Occurs when someone takes dmg
  # Keys :
  # user   => One who attacks
  # target => One who receives dmg
  # result => result.hp_damage => amount of hp dmg inflicted
  #           result.mp_damage => amount of mp dmg inflicted
  #           result.hp_drain => ect
  #           result.mp_drain
  #========================================
  On_Dmg = {
  
  "Assassination" =>
  "
    if target.is_a?(Game_Enemy) && target.hp <= result.hp_damage
      if target.name == $game_temp.chall_usual_vars[0]
        success = true
      else
        fail = true
      end
    end
  ",
  
  "Intouchable" =>
  "
  if target.is_a?(Game_Actor)
    fail = true
  end
  ",
  
  "Focus" =>
  "
  nbr_damaged = 0
  for mem in $game_troop.members
    next if mem.dead?
    if mem.hp < mem.mhp
      nbr_damaged += 1
    end
  end
  fail = true if nbr_damaged > 1
  ",
  
  "Brutality" =>
  "
  if user.is_a?(Game_Actor)
    if result.critical
      success = true
    end
  end
  "
  }
  
  #========================================
  # Occurs when someone attacks
  # Keys :
  # attacker     => One who attacks
  # target       => The target
  # attack_skill => Invoked skill from weapon
  #========================================
  On_Attack = {
  
  "Wizard, Wizard everywhere" =>
  "
  if attacker.is_a?(Game_Actor)
    fail = true
  end
  "
  
  }
  
  #========================================
  # Occurs when someone use a skill
  # Keys :
  # user     => One who attacks
  # target   => The target
  # skill    => The used skill
  #========================================
  On_Skill_Use = {
  
  "Serenity" =>
  "
  if skill.tp_cost > 0
    fail = true
  end
  "
  
  }
  
  #========================================
  # Occurs when someone use an item
  # Keys :
  # user     => One who attacks
  # target   => The target
  # item     => The used item
  #========================================
  On_Item_Use = {
  
  }
  
end
