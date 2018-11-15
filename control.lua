--========================
--Copy Right Info
--Developed by YagaoDirac
--成都YagaoDirac游戏玩法研究设计事务所 出品
--All of you are welcomed to modify everything for this map
--Special thank to the friends who helped me debug this map
--(temparorily nobody has helped testing lol)
--Hope you like this map~
--=======================

--to do list
  --给玩家物品的功能还未测试清楚
  --ui上提示还有物品没有拿到，应该是还没写的。写作左上那个里面
  --好像还有一个find entities面积是0，反正有一个log。具体的有空了查一下


local function log(t)
  game.write_file("log.txt", serpent.block(t))
end
math.clamp = function(a,min,max)
  return math.min(math.max(a,min),max)
end





require("mod-gui")-- if you had no experience on gui in this game ,check this file first. Dir is Steam\steamapps\common\Factorio\data\core\lualib. The official devs wrote some useful tips in comment which you really need to know before you get started with gui.
local yagao_defines = require("yagaodirac_utils.defines")
local yagao_debug_tools = require("yagaodirac_utils.debug_tools")
local yagao_idle_factorio = require("yagao_idle_factorio")

local print_table = yagao_debug_tools.print_table


script.on_event(defines.events.on_tick, function(event)
  if game.tick ==60 then



    -- game.players[1].cheat_mode=true
    -- game.players[1].force.research_all_technologies()

    -- local button_flow = mod_gui.get_button_flow( game.players[1])
    -- button_flow.add{type="button",name = "test button",caption = {"print someting"}, tooltip = {"debug utils"}}
    -- button_flow.add{type="button",name = "test button2",caption = {"print someting"}, tooltip = {"debug utils"}}
  
    -- game.players[1].character = nil





    yagao_idle_factorio.game_init(event)
  end
  if game.tick > 60 then
    yagao_idle_factorio.on_tick(event)
  end
end
)




script.on_event(defines.events.on_player_created, function(event)



  yagao_idle_factorio.on_player_created(event)
end)
script.on_event(defines.events.on_player_died, function(event)
  yagao_idle_factorio.on_player_died(event)
end)
script.on_event(defines.events.on_player_respawned, function(event)
  yagao_idle_factorio.on_player_respawned(event)
end)



script.on_event(defines.events.on_gui_click, function(event)
  yagao_idle_factorio.on_gui_click(event)

end)



script.on_event(defines.events.on_entity_died,function(event)

  yagao_idle_factorio.on_entity_died(event)
end)




script.on_event(defines.events.on_built_entity,function(event)
  yagao_idle_factorio.on_built_entity(event)
end)

