#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Battle Challenge
# -- By Lecode
# -- Start : Sept. 4 , 2014
# -- Ver. 0.8
# -- Last Update Sept. 20, 2014
#==============================================================================
#==============================================================================
# ▼ Terms of use
#==============================================================================
# All scripts made by me is free for non-commercial purposes only, as long as
# you credit me. 
# If you really want it for your commercial project, PM me and show me your
# work !
#==============================================================================
# ▼ Changelog
#==============================================================================
# -- V. 0.5
#    Functional
#    Knowed bug : when pressing [ok] too fast the battle screen stuck in a loop
# -- V. 0.6
#    Added the On_Message_Window option
# -- V. 0.7
#    Works now with Yanfly engine
#    Added $game_temp.disable_chall command
# -- V. 0.8
#    Added an option for challenges occurrence
#    Added an option for better compatibility
#==============================================================================
# ▼ Overwrite methods
#==============================================================================
# NONE =D
#==============================================================================
# ▼ Alias methods
#==============================================================================
# module BattleManager
#	  def self.init_members
#	  def self.battle_end
#	  def self.process_vitory
#	  def self.process_escape
#	  def self.process_abort
#
# class Game_Temp
# 	def initialize
#
# class Game_Battler
#   def on_turn_end
# 	def execute_damage
# 	def item_apply
#
# class Scene_Battle
# 	def create_all_windows
# 	def battle_start
#==============================================================================
# ▼ Introduction
#==============================================================================
# Well, this script reproduce a challenge system.
# At the start of a battle, a challenge appears. 
# It's simple : if you pass the instructions you get rewards at the end of the battle.
# As an example of a challenge, i can mention, "Win the battle in X turns",
# or... "Do a critical strike", ect.
#
# You can create your OWN challenge with rewards, description and all.
# But to be customizable to the fullest, you need some knowledge in ruby script.
# If you can't manage to make it, you can ask me for help.
#==============================================================================
# ▼ Instructions
#==============================================================================
#
# Firstly, there is a lot of configuration below, read theses headers and
# modify them as needed
# And make sure that the challenge maker is above the core.
# ===== How to create a challenge ? =====
# To add a new challenge to the game, go at line 181 and add an array to the list.
# The template of the array is:
# [ Name, icon index, description, rewards, frequency, Complete if not failed ? ]
# Do not forget a comma if you want to add another array
# Note: 
# About "Complete if not failed ?"
# On true, the challenge is completed at the end of the battle if
# it has not failed. On false, the challenge is automatically failed at the end
# of battle if it's not completed.
# Generally, set false if the challenge asks to do something 
# like : do a critical strike, use this skill, reach X dmg, ect
# and set true if it asks to don't do something
# ===== Rewards configuration ======
# This configuration is also done with an array.
# It should include a tag with values
# Tags are:
# :xp, x        => Party gets x exp as a reward
# :gold, x      => Party gets x gold as a reward
# :xpp, x       => Party gets x% of the troop total exp as a reward
# :goldp, x     => Party gets x% of the troop total gold as a reward
# :item, x, y   => Party gets the item with ID x, y times
# :weap, x, y   => Party gets the weapon with ID x, y times
# :arm, x, y    => Party gets the armor with ID x, y times
# Example:
# [ :xp,50, :xpp,200 ]    => The challenge gives 50 exp and 200% of the troop exp
# [ :xpp,25, :item,1,5 ]  => The challenge gives 25% of the troop exp and 5x Potion
# Look at existing challenges for more details
# ====== How to configure a challenge validation ? ====
# It's the difficult part =x
# The script checks on 7 occasions when a challenge must fail or be validated.
# Occasions are:
# When the battle start
# When a battler end his turn
# When a battler take damage
# When a battler use a skill
# When a battler attacks
# When a battler use an item
# At the end of the battle
#
# Now, depending of the challenge, for each of theses occasions, you
# must script a very little code to decide if the challenge is completed or not.
# Inside the code, "fail = true" means it fails, and "success = true" means
# it's successful. Keep it in mind.
#
# For example, let's make a challenge that says: Do not use any TP
# W'll check in the occasion "When a battler use a skill" to know
# if the used skill uses any TP
# The code is:
#
# if skill.tp_cost > 0
#   fail = true
# end
#
# Yeah, that's all.
# But, where to put the code ?
# Inside the Challenge_Maker module.
# Go there and read the little instruction ^^
# ====== Notes =====
# It's possible to control the challenges occurence
# Calling $game_temp.next_chall = x before a battle will force
# the chall ID x top appears
# You can set a string instead of a number if it's confusing
# You can also set an array. In that case, the challenge is chosen randomly
# Example
# $game_temp.next_chall = 2   => next challenge is Survivor
# $game_temp.next_chall = "Intouchable" => next challenge is Intouchable
# $game_temp.next_chall = [2,4,6] => next chall is Survivor, or Rage or Focus
# $game_temp.next_chall = ["Brutality","Focus"] => next chall is Brutality or Focus
#
# You can use $game_temp.disable_chall = true/false in a script command
# to enable or disable the script
#===============================================================================

module Lecode_BattleChallenge
  
  #===================================================#
  #  **  C O N F I G U R A T I O N   S Y S T E M  **  #
  #===================================================#
  
  #-------------------------------------------------------------------------
  # ▼ Icon index for exp reward
  #-------------------------------------------------------------------------
  Exp_Icon = 125
  ExpPerc_Icon = 125
  #-------------------------------------------------------------------------
  # ▼ Icon index for gold reward
  #-------------------------------------------------------------------------
  Gold_Icon = 262
  GoldPerc_Icon = 262
  #-------------------------------------------------------------------------
  # ▼ Color of the challenge name depending of his status
  # R, G, B
  #-------------------------------------------------------------------------
  Name_Color = Color.new(255, 204, 0, 255)
  Success_Color = Color.new(20, 255, 20, 255)
  Failure_Color = Color.new(255, 20, 20, 255)
  #-------------------------------------------------------------------------
  # ▼ Position of the challenge name+icon on the battle screen
  # Tags to use are:
  # :upleft, :up, :upright, :downleft, :down, :downright and :custom
  # with :custom, positions are determined by Window_CustomPos
  #-------------------------------------------------------------------------
  Challenge_InfoPosition = :upright
  Window_CustomPos = [0,0]
  #-------------------------------------------------------------------------
  # ▼ Define the type of challenge occurrence
  # :list         => challenges appear in the order of the list of challenges
  #                  in the configuration.
  # :totalrand    => challenges appear totally random
  # :averagerand  => challenges are chosen randomly, but a same challenge can 
  #                  not appear twice in a row.
  #-------------------------------------------------------------------------
  Challenge_occurrence = :averagerand
  #-------------------------------------------------------------------------
  # ▼ % of chance to show up a challenge
  #-------------------------------------------------------------------------
  Occurrence_Chance = 100
  #-------------------------------------------------------------------------
  # ▼ Does the script should use frequency ?
  # The frequency of a chall determine his occurrence rarity.
  # When a challenge is picked-up in the list, his frequency define the %
  # of chance to appear. If it's not the case, another chall is chosen
  # in the list and his frequency is checked, and ect.
  #-------------------------------------------------------------------------
  Use_Frequency = true
  #-------------------------------------------------------------------------
  # ▼ Text in the message window and the battle log
  #-------------------------------------------------------------------------
  Success_Text = "Challenge completed !"
  Failure_Text = "Challenge failed !"
  #-------------------------------------------------------------------------
  # ▼ Draw the challenge result in the message window at the battle end ?
  # Set it to false may solve compatibility issues
  #-------------------------------------------------------------------------
  On_Message_Window = false
  #-------------------------------------------------------------------------
  # ▼ May solve compatibility issues
  #-------------------------------------------------------------------------
  Hard_Compatibility = true
  #-------------------------------------------------------------------------
  # ▼ Sounds
  #-------------------------------------------------------------------------
  Success_Sound = RPG::SE.new("Chime2", 100, 100)
  Failure_Sound = RPG::SE.new("Down1", 100, 100)
  #-------------------------------------------------------------------------
  # ▼ Challenges configuration
  #-------------------------------------------------------------------------
  Challenges =
  [
    # Name | Icon | Description | Rewards(Array) | Frequency(1 to 100) | Complete if not failed ?
    ["Intouchable", 1,  "Do not receive damage",  [:xpp,200,  :goldp,300],  20,  true ],
    ["Perfect", 122,  "Win the battle with full life",  [:xpp,80,  :goldp,60], 30,  true ],
    ["Survivor",  17, "No ally should die", [:xpp,30, :goldp,50], 40,  true ],
    ["Serenity",  118,  "Do not use TP",  [:xpp,50, :goldp,60],  55, true],
    ["Rage",  116,  "Reach 100 TP", [:xpp,120, :gold,3000],  40,  false ],
    ["Fast and Furious",  11, "End the battle in 3 turns",  [:xp,340, :item,1,3,  :weap,7,1], 45,  false ],
    ["Focus", 102,  "All attacks must be concentrated |on a single enemy until his death",  [:xpp,70, :goldp,70], 50,  true ],
    ["Wizard, Wizard everywhere", 98, "Do not use the attack command",  [:xpp,50, :goldp,25], 65,  true  ],
    ["Brutality", 116, "Score a critical strike", [:xp,400, :gold,200], 35, false ],
    ["Assassination", 17, " ", [:xpp,100, :goldp,50], 55, false],
    ["Foreseeing", 117, "Start the battle with at least |75% of members HP", [:xpp,80, :goldp,80], 35, true]
  ]
  
  #===================================================#
  #  **     E N D   C O N F I G U R A T I O N     **  #
  #===================================================#
end


#==============================================================================
# BattleManager
#==============================================================================
module BattleManager
  
  #--------------------------------------------------------------------------
  # init_members
  #--------------------------------------------------------------------------
  class <<self; alias lbchll_init_members init_members; end
  def self.init_members
    lbchll_init_members
    @current_BChall = nil
  end
  
  #--------------------------------------------------------------------------
  # current challenge modifier
  #--------------------------------------------------------------------------
  def self.set_current_BChall(value)
    @current_BChall = value
  end
  
  #--------------------------------------------------------------------------
  # current challenge accessor
  #--------------------------------------------------------------------------
  def self.current_BChall=(value)
    @current_BChall = value
  end
  
  #--------------------------------------------------------------------------
  # current challenge accessor
  #--------------------------------------------------------------------------
  def self.current_BChall
    return @current_BChall
  end
  
  #--------------------------------------------------------------------------
  # alias : battle_end
  #--------------------------------------------------------------------------
  class <<self; alias lbchll_battle_end battle_end; end
  def self.battle_end(result)
    @current_BChall = nil
    $game_temp.next_chall = nil
    lbchll_battle_end(result)
  end
  
  #--------------------------------------------------------------------------
  # alias : process_victory
  # check the challenge result
  #--------------------------------------------------------------------------
  class <<self; alias lbchll_process_victory process_victory; end
  def self.process_victory
    if !BattleManager.current_BChall.nil?
      @current_BChall.check_on_battle_end
      @current_BChall.checkSuccess(true)
      SceneManager.scene.draw_chall_rewards if SceneManager.scene_is?(Scene_Battle) && @current_BChall.success?
      display_chall_result
    end
    lbchll_process_victory
  end
  
  #--------------------------------------------------------------------------
  # alias : process_escape
  # force the current challenge to fail
  #--------------------------------------------------------------------------
  class <<self; alias lbchll_process_escape process_escape; end
  def self.process_escape
    @current_BChall.fail if !BattleManager.current_BChall.nil?
    lbchll_process_escape
  end
  
  #--------------------------------------------------------------------------
  # alias : process_abort
  # force the current challenge to fail
  #--------------------------------------------------------------------------
  class <<self; alias lbchll_process_abort process_abort; end
  def self.process_abort
    @current_BChall.fail if !BattleManager.current_BChall.nil?
    lbchll_process_abort
  end
  
  #--------------------------------------------------------------------------
  # Display the challenge result
  #--------------------------------------------------------------------------
  def self.display_chall_result
    if current_BChall.success?
      $game_message.add('\.' + Lecode_BattleChallenge::Success_Text) if Lecode_BattleChallenge::On_Message_Window
      display_chall_reward
    elsif current_BChall.failure?
      $game_message.add('\.' + Lecode_BattleChallenge::Failure_Text) if Lecode_BattleChallenge::On_Message_Window
    end
  end
  
  #--------------------------------------------------------------------------
  # Apply the challenge rewards
  #--------------------------------------------------------------------------
  def self.display_chall_reward
    for i in 0..@current_BChall.gain.size-1
      text = ""
      if @current_BChall.gain[i] == :xp
        amount = @current_BChall.gain[i+1]
        #text = sprintf(Lecode_BattleChallenge::Gain_Text+" exp",amount)
        $game_party.all_members.each do |actor|
          actor.gain_exp(amount)
        end
      elsif @current_BChall.gain[i] == :xpp
        amount = $game_troop.exp_total*@current_BChall.gain[i+1]*0.01
        amount = amount.round
        #text = sprintf(Lecode_BattleChallenge::Gain_Text+" exp",amount)
        $game_party.all_members.each do |actor|
          actor.gain_exp(amount)
        end
      elsif @current_BChall.gain[i] == :gold
        amount = @current_BChall.gain[i+1]
        #text = sprintf(Lecode_BattleChallenge::Gain_Text+" gold",amount)
        $game_party.gain_gold(amount)
      elsif @current_BChall.gain[i] == :goldp
        amount = $game_troop.gold_total*@current_BChall.gain[i+1]*0.01
        amount = amount.round
        #text = sprintf(Lecode_BattleChallenge::Gain_Text+" gold",amount)
        $game_party.gain_gold(amount)
      elsif @current_BChall.gain[i] == :item
        item = $data_items[@current_BChall.gain[i+1]]
        amount = @current_BChall.gain[i+2]
        #text = Lecode_BattleChallenge::Gain_Text+" "+item.name
        $game_party.gain_item(item,amount)
      elsif current_BChall.gain[i] == :weap
        item = $data_weapons[@current_BChall.gain[i+1]]
        amount = @current_BChall.gain[i+2]
        #text = Lecode_BattleChallenge::Gain_Text+" "+item.name
        $game_party.gain_item(item,amount)
      elsif current_BChall.gain[i] == :arm
        amount = @current_BChall.gain[i+2]
        item = $data_armors[@current_BChall.gain[i+1]]
        amount = @current_BChall.gain[i+2]
        #text = Lecode_BattleChallenge::Gain_Text+" "+item.name
        $game_party.gain_item(item,amount)
      end
      #$game_message.add('\.' + text) if !text.empty?
      #wait_for_message if !text.empty?
    end
  end
  
end


#==============================================================================
# new : Battle_Challenge
#==============================================================================
class Battle_Challenge
  
  attr_accessor :name
  attr_accessor :gain
  attr_accessor :result
  attr_accessor :icon
  attr_accessor :description
  attr_accessor :freq
  attr_accessor :lastly_used
  attr_accessor :success_onEnd
  attr_accessor :id
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    @name = ""
    @icon = 1
    @description = ""
    @gain = [:xpp,20]
    @result = 0
    @freq = 60
    @lastly_used = false
    @success_onEnd = false
    @id = 0
  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_battle_start(chall, fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Battle_Start[name]
    error = "Kernel.eval Error | "+name+" | on_battle_end"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_battle_end(fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Battle_End[name]
    error = "Kernel.eval Error | "+name+" | on_battle_end"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_turn_end(battler,fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Turn_End[name]
    error = "Kernel.eval Error | "+name+" | on_turn_end"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_dmg(user,target,result,fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Dmg[name]
    error = "Kernel.eval Error | "+name+" | on_dmg"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_attack(attacker,target,atk_skill,fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Attack[name]
    error = "Kernel.eval Error | "+name+" | on_attack"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end  end
  
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_skill_use(user,target,skill,fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Skill_Use[name]
    error = "Kernel.eval Error | "+name+" | on_skill_use"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
   
  #--------------------------------------------------------------------------
  # evaluate according to the occasion
  #--------------------------------------------------------------------------
  def check_on_item_use(user,target,item,fail = false, success = false)
    string = Lecode_Challenge_Maker::On_Item_Use[name]
    error = "Kernel.eval Error | "+name+" | on_item_use"
    Kernel.eval(string) rescue msgbox error
    if success
      checkSuccess(false)
    else
      checkCondition(!fail)
    end
  end
  
  #--------------------------------------------------------------------------
  # checkCondition
  #--------------------------------------------------------------------------
  def checkCondition(bool)
    return if success? or failure?
    if !bool
      fail
    end
  end
  
  #--------------------------------------------------------------------------
  # check if the chall can be completed
  #--------------------------------------------------------------------------
  def checkSuccess(atend)
    if atend
      if !failure? && @success_onEnd
        succeed
      end
      if !success?
        fail
      end
    else
      if !failure?
        succeed
      end
      if !success?
        fail
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # refresh itself
  #--------------------------------------------------------------------------
  def refresh
    if SceneManager.scene_is?(Scene_Battle)
      SceneManager.scene.refresh_chall
    end
  end
  
  #--------------------------------------------------------------------------
  # force to complete
  #--------------------------------------------------------------------------
  def succeed
    return if success?
    @result = 1
    refresh
  end
  
  #--------------------------------------------------------------------------
  # force to fail
  #--------------------------------------------------------------------------
  def fail
    return if failure?
    @result = -1
    refresh
  end
  
  #--------------------------------------------------------------------------
  # success?
  #--------------------------------------------------------------------------
  def success?
    (@result == 1) ? true : false
  end
  
  #--------------------------------------------------------------------------
  # failure?
  #--------------------------------------------------------------------------
  def failure?
    (@result == -1) ? true : false
  end
  
end


#==============================================================================
# new : Challenge_Manager
#==============================================================================
class Challenge_Manager
  
  attr_accessor :challenges
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize
    @challenges = []
    createChallenges
  end
  
  #--------------------------------------------------------------------------
  # create a challenge according to the configuration at the top of the script
  #--------------------------------------------------------------------------
  def createChallenges
    for tab in Lecode_BattleChallenge::Challenges
      chall = Battle_Challenge.new
      chall.name = tab[0]
      chall.icon = tab[1]
      chall.description = tab[2]
      chall.gain = tab[3]
      chall.freq = tab[4]
      chall.success_onEnd = tab[5]
      chall.id = @challenges.size
      @challenges.push(chall)
      init_evaluation(chall.name)
    end
    
  end
  
  #--------------------------------------------------------------------------
  # initialize evaluation strings
  #--------------------------------------------------------------------------
  def init_evaluation(name)
    sym = name# name.downcase.strip.to_sym <= sym are cool :( but bugy sometimes
    Lecode_Challenge_Maker::On_Battle_Start[sym] = "fail = false" if Lecode_Challenge_Maker::On_Battle_Start[sym].nil?
    Lecode_Challenge_Maker::On_Battle_End[sym] = "fail = false" if Lecode_Challenge_Maker::On_Battle_End[sym].nil?
    Lecode_Challenge_Maker::On_Turn_End[sym] = "fail = false" if Lecode_Challenge_Maker::On_Turn_End[sym].nil?
    Lecode_Challenge_Maker::On_Dmg[sym] = "fail = false" if Lecode_Challenge_Maker::On_Dmg[sym].nil?
    Lecode_Challenge_Maker::On_Attack[sym] = "fail = false" if Lecode_Challenge_Maker::On_Attack[sym].nil?
    Lecode_Challenge_Maker::On_Skill_Use[sym] = "fail = false" if Lecode_Challenge_Maker::On_Skill_Use[sym].nil?
    Lecode_Challenge_Maker::On_Item_Use[sym] = "fail = false" if Lecode_Challenge_Maker::On_Item_Use[sym].nil?
  end
  
  #--------------------------------------------------------------------------
  # generate a chall
  #--------------------------------------------------------------------------
  def generate
    return nil if $game_temp.disable_chall
    return nil if @challenges.empty?
    if $game_temp.next_chall != nil
      generate_from_gametemp
    else
      return nil if !(rand(100) <= Lecode_BattleChallenge::Occurrence_Chance)
      case Lecode_BattleChallenge::Challenge_occurrence
        when :averagerand
          return generate_averagerand
        when :totalrand
          return generate_totalrand
        when :list
          return generate_list
        else
          return generate_averagerand
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # generate from $game_temp.next_chall
  #--------------------------------------------------------------------------
  def generate_from_gametemp
    if $game_temp.next_chall.is_a?(Integer)
      index = $game_temp.next_chall
      return checkIndex(index)
    elsif $game_temp.next_chall.is_a?(Array)
      i = $game_temp.next_chall[rand($game_temp.next_chall.size)]
      if i.is_a?(Integer)
        index = i
        return checkIndex(index)
      elsif i.is_a?(String)
        tab_nbr = 0
        for tab in Lecode_BattleChallenge::Challenges
          if tab[0] == i
            index = tab_nbr
            return checkIndex(index)
          end
          tab_nbr+=1
        end
      end
    elsif $game_temp.next_chall.is_a?(String)
      tab_nbr = 0
      for tab in Lecode_BattleChallenge::Challenges
        if tab[0] == $game_temp.next_chall
          index = tab_nbr
          return checkIndex(index)
        end
        tab_nbr+=1
      end
    end
  end
    
  #--------------------------------------------------------------------------
  # check valide index
  #--------------------------------------------------------------------------
  def checkIndex(index)
    if @challenges[index].nil?
      return @challenges[0]
    else
      return @challenges[index]
    end
  end
    
  
  #--------------------------------------------------------------------------
  # generate a challenge for :averagerand configuration
  #--------------------------------------------------------------------------
  def generate_averagerand
    return @challenges[0] if @challenges.size == 1
    chall = nil
    while chall == nil
      rand_index = rand(@challenges.size)
      if $game_temp.lbchll_lastly_used != rand_index
        if Lecode_BattleChallenge::Use_Frequency #!chall.lastly_used
          chall = @challenges[rand_index]
          if !(rand(100) < chall.freq)
            chall = nil
          end
        else
          chall = @challenges[rand_index]
        end
      end
    end
    msgbox "Error - Nil Challenge" if chall.nil?
    update_lastlyUsed(chall)
    return chall
  end
  
  #--------------------------------------------------------------------------
  # generate a challenge for :totalrand configuration
  #--------------------------------------------------------------------------
  def generate_totalrand
    return @challenges[0] if @challenges.size == 1
    loop do
      rand_index = rand(@challenges.size)
      chall = @challenges[rand_index]
      if Lecode_BattleChallenge::Use_Frequency
        if rand(100) < chall.freq
          update_lastlyUsed(chall)
          return chall
        end
      else
        update_lastlyUsed(chall)
        return chall
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # generate a challenge for :list configuration
  #--------------------------------------------------------------------------
  def generate_list
    if $game_temp.lbchll_last_index >= @challenges.size
      $game_temp.lbchll_last_index = 0
    else
      $game_temp.lbchll_last_index += 1
    end
    return @challenges[$game_temp.lbchll_last_index]
  end
  
  #--------------------------------------------------------------------------
  # update the last challenge
  #--------------------------------------------------------------------------
  def update_lastlyUsed(chall)
    $game_temp.lbchll_lastly_used = chall.id
    #for ch in @challenges
    #  ch.lastly_used = false
    #end
    #chall.lastly_used = true
  end
  
end


#==============================================================================
# Game_Temp
#==============================================================================
class Game_Temp
  
  attr_accessor :lbchll_last_index
  attr_accessor :chall_usual_vars
  attr_accessor :lbchll_lastly_used
  attr_accessor :next_chall
  attr_accessor :disable_chall
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  alias lbchll_initialize initialize
  def initialize
    lbchll_initialize
    @lbchll_last_index = 0
    @lbchll_lastly_used = nil
    @chall_usual_vars = [ ]
    @next_chall = nil
    @disable_chall = false
  end
  
end


#==============================================================================
# Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # alias : on_turn_end
  #--------------------------------------------------------------------------
  alias lbchll_on_turn_end on_turn_end
  def on_turn_end
    lbchll_on_turn_end
    BattleManager.current_BChall.check_on_turn_end(self) if !BattleManager.current_BChall.nil?
  end
  
  #--------------------------------------------------------------------------
  # alias : execute_damage
  #--------------------------------------------------------------------------
  alias lbchll_execute_damage execute_damage
  def execute_damage(user)
    lbchll_execute_damage(user)
    BattleManager.current_BChall.check_on_dmg(user,self,@result) if !BattleManager.current_BChall.nil?
  end
  
  #--------------------------------------------------------------------------
  # alias : item_apply
  #--------------------------------------------------------------------------
  alias lbchll_item_apply item_apply
  def item_apply(user, item)
    lbchll_item_apply(user, item)
    if item.is_a?(RPG::Skill)
      if item == $data_skills[user.attack_skill_id]
        BattleManager.current_BChall.check_on_attack(user,self,item) if !BattleManager.current_BChall.nil?
      else
        BattleManager.current_BChall.check_on_skill_use(user,self,item) if !BattleManager.current_BChall.nil?
      end
    elsif item.is_a?(RPG::Item)
      BattleManager.current_BChall.check_on_item_use(user,self,item) if !BattleManager.current_BChall.nil?
    end
  end
  
end


#==============================================================================
# new : Window_BattleChall
#==============================================================================
class Window_BattleChall < Window_Selectable
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(challenge)
    @challenge = challenge
    w = 240
    h = (description_lines+2)*line_height
    x_center = Graphics.width/2
    x = x_center-w/2
    y_center = Graphics.height/2
    y = y_center-h/2
    super(x,y,w,h)
    @mode = :info
    @nbr_reward = 0
    self.z = 2000 if Lecode_BattleChallenge::Hard_Compatibility
    refresh
  end
  
  #--------------------------------------------------------------------------
  # mode accessor
  #--------------------------------------------------------------------------
  def mode=(value)
    @mode = value
  end
  
  #--------------------------------------------------------------------------
  # get the line number of the description
  #--------------------------------------------------------------------------
  def description_lines
    string = @challenge.description
    lines = 0
    string.each_line('|') { |i|
      lines += 1
    }
    return lines+1
  end
  
  #--------------------------------------------------------------------------
  # refresh the window depending of the mode
  #--------------------------------------------------------------------------
  def refresh
    if @mode == :info
      refresh_info
    elsif @mode == :reward
      refresh_rewards
    end
  end
  
  #--------------------------------------------------------------------------
  # refresh_info
  #--------------------------------------------------------------------------
  def refresh_info
    contents.clear
    self.contents.font.color = Lecode_BattleChallenge::Name_Color
    self.contents.draw_text(24, 0, contents_width, line_height,@challenge.name)
    draw_icon(@challenge.icon,0,0,true)
    line_color = normal_color
    line_color.alpha = 48
    self.contents.fill_rect(0, line_height, contents_width, 2, line_color)
    draw_description(10) #30
    draw_rewards
  end
  
  #--------------------------------------------------------------------------
  # refresh_rewards
  #--------------------------------------------------------------------------
  def refresh_rewards 
    self.height = (@nbr_reward+2)*line_height
    contents.clear
    self.contents = Bitmap.new(self.width-24,self.height-24)
    self.contents.font.color = Lecode_BattleChallenge::Name_Color
    self.contents.draw_text(24, 0, contents_width, line_height,@challenge.name)
    draw_icon(@challenge.icon,0,0,true)
    line_color = normal_color
    line_color.alpha = 48
    self.contents.fill_rect(0, line_height, contents_width, 2, line_color)
    draw_rewards_success(line_height)
  end
  
  #--------------------------------------------------------------------------
  # draw_rewards_success( y cords )
  #--------------------------------------------------------------------------
  def draw_rewards_success(y)
    self.contents.font.color = normal_color
    for i in 0..@challenge.gain.size-1
      text = ""
      if @challenge.gain[i] == :xp
        amount = @challenge.gain[i+1]
        text = "Exp +"+amount.to_s
        draw_icon(Lecode_BattleChallenge::Exp_Icon,0,y,true)
      elsif @challenge.gain[i] == :xpp
        amount = $game_troop.exp_total*@challenge.gain[i+1]*0.01
        amount = amount.round
        text = "Exp +"+amount.to_s
        draw_icon(Lecode_BattleChallenge::ExpPerc_Icon,0,y,true)
      elsif @challenge.gain[i] == :gold
        amount = @challenge.gain[i+1]
        text = "Gold +"+amount.to_s
        draw_icon(Lecode_BattleChallenge::Gold_Icon,0,y,true)
      elsif @challenge.gain[i] == :goldp
        amount = $game_troop.gold_total*@challenge.gain[i+1]*0.01
        amount = amount.round
        text = "Gold +"+amount.to_s
        draw_icon(Lecode_BattleChallenge::GoldPerc_Icon,0,y,true)
      elsif @challenge.gain[i] == :item
        item = $data_items[@challenge.gain[i+1]]
        amount = @challenge.gain[i+2]
        text = item.name+" x"+amount.to_s
        draw_icon(item.icon_index,0,y,true)
      elsif @challenge.gain[i] == :weap
        item = $data_weapons[@challenge.gain[i+1]]
        amount = @challenge.gain[i+2]
        text = item.name+" x"+amount.to_s
        draw_icon(item.icon_index,0,y,true)
      elsif @challenge.gain[i] == :arm
        item = $data_armors[@challenge.gain[i+1]]
        amount = @challenge.gain[i+2]
        text = item.name+" x"+amount.to_s
        draw_icon(item.icon_index,0,y,true)
      end
      if !text.empty?
        self.contents.draw_text(22, y, contents_width, line_height,text)
        y += line_height
      end
      text.clear
    end
  end
  
  #--------------------------------------------------------------------------
  # draw_description( x cord)
  #--------------------------------------------------------------------------
  def draw_description(x)
    self.contents.font.color = normal_color
    string = @challenge.description
    a = 0
    string.each_line('|') { |i|
      i = i[0..i.size-2] if i.include? "|"
      self.contents.draw_text(x, line_height+(line_height*a), contents_width,line_height,i)
      a += 1
    }
  end
  
  #--------------------------------------------------------------------------
  # draw_rewards
  #--------------------------------------------------------------------------
  def draw_rewards
    y = (description_lines)*line_height
    #nbr_reward = 0#@challenge.gain.size/2 
    @nbr_reward = 0
    for i in @challenge.gain
      if (i == :xp or i == :xpp or i == :gold or
        i == :goldp or i == :item or i == :weap or
        i == :arm)
        @nbr_reward += 1
      end
    end
    x = 5
    plus_x = (contents_width/@nbr_reward)
    for i in 0..@challenge.gain.size-1
      if @challenge.gain[i] == :xp
        draw_exp(x,y,@challenge.gain[i+1],false)
        x += plus_x
      elsif @challenge.gain[i] == :xpp
        draw_exp(x,y,@challenge.gain[i+1],true)
        x += plus_x
      elsif @challenge.gain[i] == :gold
        draw_gold(x,y,@challenge.gain[i+1],false)
        x += plus_x
      elsif @challenge.gain[i] == :goldp
        draw_gold(x,y,@challenge.gain[i+1],true)
        x += plus_x
      elsif @challenge.gain[i] == :item
        draw_item(x,y,@challenge.gain[i+1],:item,@challenge.gain[i+2])
        x += plus_x
      elsif @challenge.gain[i] == :weap
        draw_item(x,y,@challenge.gain[i+1],:weap,@challenge.gain[i+2])
        x += plus_x
      elsif @challenge.gain[i] == :arm
        draw_item(x,y,@challenge.gain[i+1],:arm,@challenge.gain[i+2])
        x += plus_x
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # draw_exp
  #--------------------------------------------------------------------------
  def draw_exp(x,y,amount,perc)
    (perc) ? icon_index = Lecode_BattleChallenge::ExpPerc_Icon
    : icon_index = Lecode_BattleChallenge::Exp_Icon
    draw_icon(icon_index,x,y,true)
    self.contents.font.color = system_color
    text = "+"+amount.to_s
    (perc) ? text += "%" : ""
    self.contents.draw_text(x+20, y, contents_width, line_height,text)
  end
  
  #--------------------------------------------------------------------------
  # draw_gold
  #--------------------------------------------------------------------------
  def draw_gold(x,y,amount,perc)
    (perc) ? icon_index = Lecode_BattleChallenge::GoldPerc_Icon
    : icon_index = Lecode_BattleChallenge::Gold_Icon
    draw_icon(icon_index,x,y,true)
    self.contents.font.color = system_color
    text = "+"+amount.to_s
    (perc) ? text += "%" : ""
    self.contents.draw_text(x+20, y, contents_width, line_height,text)
  end
  
  #--------------------------------------------------------------------------
  # draw_item
  #--------------------------------------------------------------------------
  def draw_item(x,y,id,tag,amount)
    if tag == :item
      icon_index = $data_items[id].icon_index
    elsif tag == :weap
      icon_index = $data_weapons[id].icon_index
    elsif tag == :arm
      icon_index = $data_armors[id].icon_index
    end
    draw_icon(icon_index,x,y,true)
    self.contents.font.color = system_color
    self.contents.draw_text(x+20, y, contents_width, line_height,"x"+amount.to_s)
  end
  
end


#==============================================================================
# new : Window_BattleChall_Info
# Draw the current challenge on the battle screen
#==============================================================================
class Window_BattleChall_Info < Window_Base
  
  #--------------------------------------------------------------------------
  # initialize
  #--------------------------------------------------------------------------
  def initialize(challenge)
    @challenge = challenge
    pos = set_position
    super(pos[0],pos[1],pos[2],pos[3])
    self.opacity = 0
    refresh
  end
  
  #--------------------------------------------------------------------------
  # set_position
  #--------------------------------------------------------------------------
  def set_position
    w = 7*@challenge.name.size+60
    h = fitting_height(2)
    case Lecode_BattleChallenge::Challenge_InfoPosition
      when :upright
        x = Graphics.width-w
        y = 0
      when :upleft
        x = 0
        y = -5
      when :up
        x = Graphics.width/2-w/2
        y = -5
      when :downright
        x = Graphics.width-w
        y = Graphics.height-fitting_height(6)
      when :downleft
        x = 0
        y = Graphics.height-fitting_height(6)
      when :down
        x = Graphics.width/2-w/2
        y = Graphics.height-fitting_height(6)
      when :custom
        x = Lecode_BattleChallenge::Window_CustomPos[0]
        y = Lecode_BattleChallenge::Window_CustomPos[1]
      else
        # upright
        x = Graphics.width-w
        y = -5
      end
      return [x,y,w,h]
    end
        
  #--------------------------------------------------------------------------
  # refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    self.contents.font.color = Lecode_BattleChallenge::Name_Color
    if @challenge.success?
      self.contents.font.color = Lecode_BattleChallenge::Success_Color
    elsif @challenge.failure?
      self.contents.font.color = Lecode_BattleChallenge::Failure_Color
    end
    self.contents.draw_text(24, 0, contents_width, line_height,@challenge.name)
    draw_icon(@challenge.icon,0,0,true)
  end
  
end
    

#==============================================================================
# Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
  
  #--------------------------------------------------------------------------
  # alias : create_all_windows
  #--------------------------------------------------------------------------
  alias lbchll_create_all_windows create_all_windows
  def create_all_windows
    lbchll_create_all_windows
    process_battle_challenge
  end
  
  #--------------------------------------------------------------------------
  # new : process_battle_challenge
  #--------------------------------------------------------------------------
  def process_battle_challenge
    @challMng = Challenge_Manager.new
    chall = @challMng.generate
    BattleManager.set_current_BChall(chall)
    if chall != nil
      @chall_window = Window_BattleChall.new(BattleManager.current_BChall)
      @chall_window.set_handler(:ok,     method(:close_chall_window))
      @chall_window.set_handler(:cancel, method(:close_chall_window))
      @chall_info = Window_BattleChall_Info.new(BattleManager.current_BChall)
      @chall_info.hide
      @chall_window.hide
      @chall_window.deactivate
    end
  end
  
  #--------------------------------------------------------------------------
  # new : close_chall_window
  #--------------------------------------------------------------------------
  def close_chall_window
    Sound.play_cursor
    @chall_window.close
  end
  
  #--------------------------------------------------------------------------
  # alias : battle_start
  #--------------------------------------------------------------------------
  alias lbchll_battle_start battle_start
  def battle_start
    if !BattleManager.current_BChall.nil?
      BattleManager.current_BChall.check_on_battle_start(BattleManager.current_BChall)
      # I keep this for reference
      #while @chall_window.active
      #  wait(1)
      #end
      #wait(100)
      #@chall_window.close
      draw_chall_window
      @chall_info.show
      @chall_info.refresh
    end
    lbchll_battle_start
  end
  
  def draw_chall_window
    @chall_window.refresh
    @chall_window.show
    @chall_window.activate
    @chall_window.open
    if Lecode_BattleChallenge::Hard_Compatibility
      while @chall_window.active
        @chall_window.update
        Graphics.update
        Input.update
      end
    else
      update_for_wait
      update_for_wait while @chall_window.active #@chall_window.open?
    end
    @chall_window.close
    @chall_window.hide
  end
  
  #--------------------------------------------------------------------------
  # new : draw_chall_rewards
  # draw the rewards window at the end of the battle
  #--------------------------------------------------------------------------
  def draw_chall_rewards
    if !BattleManager.current_BChall.nil?
      #msgbox "ok"
      @chall_window.mode = :reward
      #I keep this for reference
      #while @chall_window.active
      #  wait(1)
      #end
      draw_chall_window
    end
  end
  
  #--------------------------------------------------------------------------
  # new : refresh_chall
  # refresh the challenge window on the battle screen
  #--------------------------------------------------------------------------
  def refresh_chall
    if !BattleManager.current_BChall.nil?
      @chall_info.refresh
      popup_chall
    end
  end
  
  #--------------------------------------------------------------------------
  # new : popup_chall
  # Draw the current challenge state on the battle log
  #--------------------------------------------------------------------------
  def popup_chall
    if BattleManager.current_BChall.success?
      @log_window.add_text(Lecode_BattleChallenge::Success_Text)
      Lecode_BattleChallenge::Success_Sound.play
    elsif BattleManager.current_BChall.failure?
      @log_window.add_text(Lecode_BattleChallenge::Failure_Text)
      Lecode_BattleChallenge::Failure_Sound.play
    end
  end
  
end
