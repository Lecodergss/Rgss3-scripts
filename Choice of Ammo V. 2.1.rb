#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Choice of munitions
# -- By Lecode
# -- Start : Oct. 12 , 2013
# -- Ver. 2.1 : Sept. 4, 2014
#==============================================================================
#==============================================================================
# ▼ Changelog
#==============================================================================
# -- V. 1.0
# -- V. 1.08
#    Debug
# -- V. 2.1
#    Debug
#    Multiple change in the code
#==============================================================================
# ▼ Special thanks
#==============================================================================
# Wren -- For using this script and reporting bugs :)
#==============================================================================
# ▼ Overwrite methods
#==============================================================================
# class Game_Battler
#	    def item_cri
#	    def item_hit
#	    def item_element_rate
#
# class Scene_Battle
#	    def on_skill_ok
#	    def command_attack
#
# class Window_SkillList
#	    def enable?(item)
#
# class Window_ActorCommand
#	    def add_attack_command
#==============================================================================
# ▼ Alias methods
#==============================================================================
# class Game_Battler
#     def initialize
#     def item_apply
#     def execute_damage(user)
#
# class Game_System
#     def initialize
#
# module DataManager
#     def self.load_database
#
# module BattleManager
#     def self.battle_end
#
# class Scene_Battle
#     def create_all_windows
#==============================================================================
# ▼ Introduction
#==============================================================================
# This script allows the characters to choose ammunition when using a skill or an attack.
# Ammunition gives bonus to performed attack, as atk, crit, hit, ect.
# The element of the ammo will replace the element of the skill. Also, damages 
# of the object in the database will be added to the damage of performed attack.
# In the same way for effects ( state, buff ).
#==============================================================================
# ▼ Instructions
#==============================================================================
# +++Item Tags+++
#------------------------------------------------------------------------------
# <lca_ammo_type: x>   x = number
# Define the type of munition.
# A skill/weapon which uses munition of type x = 2 or x = 3 for example cannot use ammunition of type x = 1.
#------------------------------------------------------------------------------
# <lca_ammo_bonus: string,string,string,ect>
# This tag allows ammunition to provide bonuses during the attack.
# Replace string by:
# atk_x   mat_x   hit_x   cri_x   agi_x   luk_x   dmg_x   dmg%_x
# For example, an ammo with this tag:
# <lca_ammo_bonus: atk_15,dmg_55,cri_20,mat_5>
# increases atk by 15 pts, cri by 20 points(real 20% crit chance), mat by 5 points and deal aditional 55 damages 
# during the attack.
# NB: Adding damage through the tag ignores the element of the attack, unlike the damage configured in the DB.
# But it's the same when the element of the arrow in the DB is set to "none".
#------------------------------------------------------------------------------
# The element of the object will replace the element of the attack. Also, damages 
# of the object in the database will be added to the damage of performed attack.
# In the same way for effects ( state, buff ).
#==============================================================================
# +++Skill, Weapon Tags+++
#------------------------------------------------------------------------------
# <lca_ammo_type: x,y,z,ect>
# Determines the type of munition that can be used
#------------------------------------------------------------------------------
# <lca_nbr_ammo_used: x>
# Use x ammo when used. ( Default = 1 )
#===============================================================================

module Lecode_ChoiceOfAmmo
  #===================================================#
  #  **  C O N F I G U R A T I O N   S Y S T E M  **  #
  #===================================================#
#-------------------------------------------------------------------------
# Default type for ammo
#-------------------------------------------------------------------------
Default_ammo_type = 1

  #===================================================#
  #  **     E N D   C O N F I G U R A T I O N     **  #
  #===================================================#
  

AMMO_TYPE = /<lca_ammo_type:[ ](\d+)?>/i
SKILL_AMMO_TYPE = /<lca_ammo_type: (.*)>/i
IS_AMMO = /<lca_ammo>/i
USE_AMMO = /<lca_use_ammo>/i
USE_AMMO_NBR = /<lca_nbr_ammo_used:[ ](\d+)?>/i
AMMO_BONUS = /<lca_ammo_bonus: (.*)>/i
end


#==============================================================================
# Ammo
#==============================================================================
class RPG::Item
  
  attr_accessor :is_lca_ammo
  attr_accessor :ammo_type
  attr_accessor :ammo_atk
  attr_accessor :ammo_mat
  attr_accessor :ammo_agi
  attr_accessor :ammo_luk
  attr_accessor :ammo_hit
  attr_accessor :ammo_cri
  attr_accessor :ammo_dmg
  attr_accessor :ammo_dmg_perc
  #--------------------------------------------------------------------------
  # load_notetags_enbody
  #--------------------------------------------------------------------------
  def load_notetags_lca
    #-- Initialiyation
    @is_lca_ammo = false
    @ammo_type = Lecode_ChoiceOfAmmo::Default_ammo_type
    @ammo_atk = 0
    @ammo_mat = 0
    @ammo_agi = 0
    @ammo_luk = 0
    @ammo_hit = 0
    @ammo_cri = 0
    @ammo_dmg = 0
    @ammo_dmg_perc = 1.0
    
    #-- Read new values from noteboxes
    self.note.split(/[\r\n]+/).each { |line|
    case line
      when Lecode_ChoiceOfAmmo::AMMO_TYPE
        @is_lca_ammo = true
        @ammo_type = $1.to_i
      when Lecode_ChoiceOfAmmo::AMMO_BONUS
        @is_lca_ammo = true
        for i in $1.split(",")
          i.split(/[\r\n]+/).each { |line|
          case line
            when /atk_(.*)/i
            @ammo_atk = $1.to_i
            when /mat_(.*)/i
            @ammo_mat = $1.to_i
            when /agi_(.*)/i
            @ammo_agi = $1.to_i
            when /luk_(.*)/i
            @ammo_luk = $1.to_i
            when /hit_(.*)/i
            @ammo_hit = $1.to_i
            when /cri_(.*)/i
            @ammo_cri = $1.to_i
            when /dmg_(.*)/i
            @ammo_dmg = $1.to_i
            when /dmg%_(.*)/i
            @ammo_dmg_perc = $1.to_i
          end
          }
        end
      end #case
      }
    end #def
  
  end #class Ammo
  
#==============================================================================
# RPG::Skill
#==============================================================================
class RPG::Skill < RPG::UsableItem
  
  attr_accessor :ammo_type
  attr_accessor :use_ammo
  attr_accessor :use_ammo_nbr
  #--------------------------------------------------------------------------
  # load_notetags_enbody
  #--------------------------------------------------------------------------
  def load_notetags_lca
    @ammo_type = [Lecode_ChoiceOfAmmo::Default_ammo_type]
    @use_ammo = false
    @use_ammo_nbr = 1
    self.note.split(/[\r\n]+/).each { |line|
    case line
      when Lecode_ChoiceOfAmmo::SKILL_AMMO_TYPE
        @use_ammo = true
        @ammo_type = [ ]
        for i in $1.split(",")
          @ammo_type.push(i.to_i)
        end
      when Lecode_ChoiceOfAmmo::USE_AMMO_NBR
        @use_ammo = true
        @use_ammo_nbr = $1.to_i
    end
    }
  end#def
  
end#class

#==============================================================================
# RPG::Weapon
#==============================================================================
class RPG::Weapon < RPG::EquipItem
  
  attr_accessor :ammo_type
  attr_accessor :use_ammo
  attr_accessor :use_ammo_nbr
  #--------------------------------------------------------------------------
  # load_notetags_enbody
  #--------------------------------------------------------------------------
  def load_notetags_lca
    @ammo_type = [Lecode_ChoiceOfAmmo::Default_ammo_type]
    @use_ammo = false
    @use_ammo_nbr = 1
    self.note.split(/[\r\n]+/).each { |line|
    case line
      when Lecode_ChoiceOfAmmo::SKILL_AMMO_TYPE
        @use_ammo = true
        @ammo_type = [ ]
        for i in $1.split(",")
          @ammo_type.push(i.to_i)
        end
      when Lecode_ChoiceOfAmmo::USE_AMMO_NBR
        @use_ammo = true
        @use_ammo_nbr = $1.to_i
    end
    }
  end#def
  
end#class
  
  
  
#==========================================================================
# Game_Battler
#==========================================================================
class Game_Battler < Game_BattlerBase
  
  attr_accessor :current_ammo
  attr_accessor :lca_using_obj
  #--------------------------------------------------------------------------
  # alias : initialize
  #--------------------------------------------------------------------------
  alias lecode_lca_ini initialize
  def initialize
    lecode_lca_ini
    @current_ammo = nil
    @lca_using_obj = nil
  end#def
  
  #--------------------------------------------------------------------------
  # new : main_weap
  #--------------------------------------------------------------------------
  def main_weap
    return weapons[0]
  end
  
end

#==============================================================================
# Game_System
#==============================================================================
class Game_System
  
  attr_accessor :lca_for_weapon
  #--------------------------------------------------------------------------
  # alias: initialize
  #--------------------------------------------------------------------------
  alias lecode_lca_ini initialize
  def initialize
    lecode_lca_ini
    @lca_for_weapon = false
  end#def
  
end#class
  
  
#==============================================================================
# DataManager
#==============================================================================
module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_lca load_database; end
  def self.load_database
    load_database_lca
    load_notetags_lca
  end
  #--------------------------------------------------------------------------
  # new method: load_notetags_lca
  #--------------------------------------------------------------------------
  def self.load_notetags_lca
    groups = [$data_items,$data_skills,$data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_lca
      end
    end 
  end  
end # DataManager


#==============================================================================
# Game_Battler
#==============================================================================
class Game_Battler < Game_BattlerBase
  
  #--------------------------------------------------------------------------
  # new : active_ammo_bonus
  #--------------------------------------------------------------------------
  def active_ammo_bonus
    weapons[0].params[2] += current_ammo.ammo_atk
    weapons[0].params[4] += current_ammo.ammo_mat
    weapons[0].params[6] += current_ammo.ammo_agi
    weapons[0].params[7] += current_ammo.ammo_luk
  end
  
  #--------------------------------------------------------------------------
  # new : deactive_ammo_bonus
  #--------------------------------------------------------------------------
  def deactive_ammo_bonus
    weapons[0].params[2] -= current_ammo.ammo_atk
    weapons[0].params[4] -= current_ammo.ammo_mat
    weapons[0].params[6] -= current_ammo.ammo_agi
    weapons[0].params[7] -= current_ammo.ammo_luk
  end
  
  #--------------------------------------------------------------------------
  # alias : item_aply
  #--------------------------------------------------------------------------
  alias lca_item_apply item_apply
  def item_apply(user, item)
    active_ammo_bonus if is_a?(Game_Actor) && current_ammo != nil
    lca_item_apply(user, item)
    deactive_ammo_bonus if is_a?(Game_Actor) && current_ammo != nil
  end
  
  #--------------------------------------------------------------------------
  # alias: execute_damage
  #--------------------------------------------------------------------------
  alias lca_execute_dmg execute_damage
  def execute_damage(user)
    if user.is_a?(Game_Actor)
      if user.current_ammo != nil
        @result.hp_damage += user.current_ammo.ammo_dmg
        if SceneManager.scene_is?(Scene_Battle)
          SceneManager.scene.apply_ammo_effects(self, user.current_ammo)
        end
        ammo_make_dmg(user,self,user.current_ammo)
        @result.hp_damage *= user.current_ammo.ammo_dmg_perc
        @result.hp_damage = @result.hp_damage.round
      end
    end
    lca_execute_dmg(user)
  end

  #--------------------------------------------------------------------------
  # overwrite : item_cri
  #--------------------------------------------------------------------------
  def item_cri(user, item)
    if user.current_ammo != nil
      item.damage.critical ? user.cri+user.current_ammo.ammo_cri * (1 - cev) : 0
    else
      item.damage.critical ? user.cri * (1 - cev) : 0
    end
  end
  
  #--------------------------------------------------------------------------
  # overwrite : item_hit
  #--------------------------------------------------------------------------
  def item_hit(user, item)
    if user.current_ammo != nil
      rate = (item.success_rate+user.current_ammo.ammo_hit) * 0.01
    else
      rate = item.success_rate * 0.01     # Get success rate
    end
    rate *= user.hit if item.physical?  # Physical attack: Multiply hit rate
    return rate                         # Return calculated hit rate
  end
  
  #--------------------------------------------------------------------------
  # overwrite : item_element_rate
  #--------------------------------------------------------------------------
  def item_element_rate(user, item)
    if item.damage.element_id < 0
      user.atk_elements.empty? ? 1.0 : elements_max_rate(user.atk_elements)
    else
      if user.current_ammo != nil
        element_rate(user.current_ammo.damage.element_id)
      else
        element_rate(item.damage.element_id)
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # Make damage for ammo
  #--------------------------------------------------------------------------
  def ammo_make_dmg(user,target,item)
    value = item.damage.eval(user, target, $game_variables)
    value *= item_element_rate(user, item)
    value *= pdr if item.physical?
    value *= mdr if item.magical?
    value *= rec if item.damage.recover?
    value = apply_variance(value, item.damage.variance)
    @result.hp_damage += value.round
  end
  
  #--------------------------------------------------------------------------
  # Apply Effect of ammo
  #--------------------------------------------------------------------------
  def ammo_apply(user, item)
    item.effects.each {|effect| item_effect_apply(user, item, effect) }
  end
  
end
  
  
#==============================================================================
# Scene_Battle
#==============================================================================
class Scene_Battle < Scene_Base
    
  #--------------------------------------------------------------------------
  # alias : create_all_windows
  #--------------------------------------------------------------------------
  alias lca_create_all_windows create_all_windows
  def create_all_windows
  lca_create_all_windows
    create_ammo_window
  end
  
  #--------------------------------------------------------------------------
  # new : create_ammo_window
  #--------------------------------------------------------------------------
  def create_ammo_window
    @ammo_window = Window_BattleAmmo.new(@help_window, @info_viewport)
    @ammo_window.set_handler(:ok,     method(:on_ammo_ok))
    @ammo_window.set_handler(:cancel, method(:on_ammo_cancel))
  end
  
  #--------------------------------------------------------------------------
  # new : choose_ammo
  #--------------------------------------------------------------------------
  def choose_ammo
    @ammo_window.select_last
    @ammo_window.refresh
    @ammo_window.show
    @ammo_window.activate
  end
  
  #--------------------------------------------------------------------------
  # new : on_ammo_cancel
  #--------------------------------------------------------------------------
  def on_ammo_cancel
    @ammo_window.hide
    if $game_system.lca_for_weapon
      @actor_command_window.activate
    else
      @skill_window.show.activate
    end
  end
  
  #--------------------------------------------------------------------------
  # new : on_ammo_ok
  #--------------------------------------------------------------------------
  def on_ammo_ok
    $game_party.last_item.object = @ammo_window.item
    if $game_system.lca_for_weapon
      $game_party.lose_item(@ammo_window.item,BattleManager.actor.weapons[0].use_ammo_nbr)
      BattleManager.actor.current_ammo = @ammo_window.item
      @ammo_window.hide # close ?
      select_enemy_selection
    else
      if @skill.use_ammo
        $game_party.lose_item(@ammo_window.item,@skill.use_ammo_nbr)
        BattleManager.actor.current_ammo = @ammo_window.item
        @ammo_window.hide
      end
      if !@skill.need_selection?
        @skill_window.hide
        next_command
      elsif @skill.for_opponent?
        select_enemy_selection
      else
        select_actor_selection
      end#if
    end#if
    
  end#def
  
  #--------------------------------------------------------------------------
  # overwirte : on_skill_ok
  #--------------------------------------------------------------------------
  def on_skill_ok
    $game_system.lca_for_weapon = false
    @skill = @skill_window.item
    BattleManager.actor.input.set_skill(@skill.id)
    BattleManager.actor.last_skill.object = @skill
    if @skill.use_ammo
      @skill_window.hide
      BattleManager.actor.lca_using_obj = @skill
      choose_ammo
    else
      on_ammo_ok
    end
  end

=begin  
  #--------------------------------------------------------------------------
  # alias : on_enemy_ok
  #--------------------------------------------------------------------------
  alias lca_on_enemy_ok on_enemy_ok
  def on_enemy_ok
    if !BattleManager.actor.weapons.empty?
      if BattleManager.actor.current_ammo != nil
        BattleManager.actor.active_ammo_bonus
      end
    end
    lca_on_enemy_ok
  end #def
=end
  
  #--------------------------------------------------------------------------
  # overwrite : command_attack
  #--------------------------------------------------------------------------
  def command_attack
    BattleManager.actor.input.set_attack
    if BattleManager.actor.weapons.empty?
      select_enemy_selection
    else
      $game_system.lca_for_weapon = true
      if BattleManager.actor.weapons[0].use_ammo
        BattleManager.actor.lca_using_obj = BattleManager.actor.weapons[0]
        choose_ammo
      else
        select_enemy_selection
      end
    end
  end#def
  
  #--------------------------------------------------------------------------
  # new : apply_ammo_effects
  #--------------------------------------------------------------------------
  def apply_ammo_effects(target, item)
    target.ammo_apply(@subject, item)
    refresh_status
    @log_window.display_affected_status(target, item)
  end
  
end# Scene_Battle

#==============================================================================
# Window_AmmoList
#==============================================================================
class Window_AmmoList < Window_Selectable
  
  #--------------------------------------------------------------------------
  # Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height)
    super
    @data = []
  end
  #--------------------------------------------------------------------------
  # Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return 2
  end
  #--------------------------------------------------------------------------
  # Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    @data ? @data.size : 1
  end
  #--------------------------------------------------------------------------
  # Get Item
  #--------------------------------------------------------------------------
  def item
    @data && index >= 0 ? @data[index] : nil
  end
  #--------------------------------------------------------------------------
  # Get Activation State of Selection Item
  #--------------------------------------------------------------------------
  def current_item_enabled?
    enable?(@data[index])
  end
  #--------------------------------------------------------------------------
  # Include in Item List?
  #--------------------------------------------------------------------------
  def include?(item)
    item.is_lca_ammo
  end
  #--------------------------------------------------------------------------
  # Display in Enabled State?
  #--------------------------------------------------------------------------
  def enable?(item)
    BattleManager.actor.lca_using_obj.ammo_type.include?(item.ammo_type)
  end
  #--------------------------------------------------------------------------
  # Create Item List
  #--------------------------------------------------------------------------
  def make_item_list
    @data = [ ]
    for item in $game_party.all_items
      next if item.nil?
      @data.push(item) if item.is_a?(RPG::Item) && $data_items[item.id].is_lca_ammo
    end
  end
  #--------------------------------------------------------------------------
  # Restore Previous Selection Position
  #--------------------------------------------------------------------------
  def select_last
    select(@data.index($game_party.last_item.object) || 0)
  end
  #--------------------------------------------------------------------------
  # Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    item = @data[index]
    if item
      rect = item_rect(index)
      rect.width -= 4
      draw_item_name(item, rect.x, rect.y, enable?(item))
      draw_item_number(rect, item)
    end
  end
  #--------------------------------------------------------------------------
  # Draw Number of Items
  #--------------------------------------------------------------------------
  def draw_item_number(rect, item)
    draw_text(rect, sprintf(":%2d", $game_party.item_number(item)), 2)
  end
  #--------------------------------------------------------------------------
  # Update Help Text
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_item(item)
  end
  #--------------------------------------------------------------------------
  # Refresh
  #--------------------------------------------------------------------------
  def refresh
    make_item_list
    create_contents
    draw_all_items
  end
  
end

#==============================================================================
# Window_BattleAmmo
#==============================================================================
class Window_BattleAmmo < Window_AmmoList
  
  #--------------------------------------------------------------------------
  # Initialization
  #--------------------------------------------------------------------------
  def initialize(help_window, info_viewport)
    y = help_window.height
    super(0, y, Graphics.width, info_viewport.rect.y - y)
    self.visible = false
    @help_window = help_window
    @info_viewport = info_viewport
  end
  #--------------------------------------------------------------------------
  # Include in Item List?
  #--------------------------------------------------------------------------
  def include?(item)
    true
  end
  #--------------------------------------------------------------------------
  # Display in Enabled State?
  #--------------------------------------------------------------------------
  def enable?(item)
    BattleManager.actor.lca_using_obj.ammo_type.include?(item.ammo_type) && 
    $game_party.item_number(item) >= BattleManager.actor.lca_using_obj.use_ammo_nbr
  end
  #--------------------------------------------------------------------------
  # Restore Previous Selection Position
  #--------------------------------------------------------------------------
  def select_last
    select(@data.index($game_party.last_item.object) || 0)
  end
  #--------------------------------------------------------------------------
  # Show Window
  #--------------------------------------------------------------------------
  def show
    select_last
    @help_window.show
    super
  end
  #--------------------------------------------------------------------------
  # Hide Window
  #--------------------------------------------------------------------------
  def hide
    @help_window.hide
    super
  end
  
end


#==============================================================================
# Window_SkillList
#==============================================================================
class Window_SkillList < Window_Selectable
  
  #--------------------------------------------------------------------------
  # overwrite : enable?
  #--------------------------------------------------------------------------
  def enable?(item)
    return if item.nil?
    @actor && @actor.usable?(item) && ammo_check_enable(item)
  end

  #--------------------------------------------------------------------------
  # new : ammo_check_enable
  #--------------------------------------------------------------------------
  def ammo_check_enable(item)
    dispo_ammo = $game_party.all_items.select {|item| item.is_a?(RPG::Item) && item.is_lca_ammo }
    if item.use_ammo
      !dispo_ammo.empty?
    end
  end
  
end
    

#==============================================================================
# Window_ActorCommand
#==============================================================================
class Window_ActorCommand < Window_Command
  
  #--------------------------------------------------------------------------
  # overwrite : add_attack_command
  #--------------------------------------------------------------------------
  def add_attack_command
    if @actor.weapons.empty?
      add_command(Vocab::attack, :attack,@actor.attack_usable?)
    else
      dispo_ammo = $game_party.all_items.select {|item| item.is_a?(RPG::Item) && item.is_lca_ammo }
      check_ammo = true
      if @actor.weapons[0].use_ammo
        for i in dispo_ammo
          if @actor.weapons[0].ammo_type.include?(i.ammo_type)
            found = true
            break
          end
        end
        found ? check_ammo = true : check_ammo = false
      end
      add_command(Vocab::attack, :attack, check_ammo && @actor.attack_usable?)
    end
  end
end


#==============================================================================
# BattleManager
#==============================================================================
module BattleManager
  
  #--------------------------------------------------------------------------
  # alias : battle_end
  #--------------------------------------------------------------------------
  class <<self; alias lca_battle_end battle_end; end
  def self.battle_end(result)
    $game_party.all_members.each do |actor|
      actor.current_ammo = nil
    end
    lca_battle_end(result)
  end
  
end
