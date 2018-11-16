--========================
--Copy Right Info
--Developed by YagaoDirac
--成都YagaoDirac游戏玩法研究设计事务所 出品
--All of you are welcomed to modify everything for this map
--Special thank to the friends who helped me debug this map
--(temparorily nobody has helped testing lol)
--Hope you like this map~
--=======================

local function log(t)
    game.write_file("log.txt", serpent.block(t))
end
math.clamp = function(a,min,max)
    return math.min(math.max(a,min),max)
end

--my math utils. Would be collected in a table later
yagao_math={}
yagao_math.point_on_line = function(x1,y1,x2,y2,x)
    --safety
    if math.abs(x1-x2)<0.0000001 then 
        return nil
    end

    local k = (y2-y1)/(x2-x1)
    return (x-x1)*k+y1
end


--我把我自己的名字写到代码里，你们不会有意见吧？如果你们要hack我的地图，直接跟我说，我帮你们写都行。我希望可以有良性的交流。
--严格的说写这个地图也是为了探讨一些玩法设计的具体细节。这次的思路是将放置类游戏的元素加入到工厂里，在不增加游戏任何内容的情况下，让游戏变得更耐玩
--同时解决你们进不了地图的问题。
--所以，我希望你们可以在贴吧开帖子，或者找到我的帖子，在里面讨论这个地图的所有方面。
--因为我自己可能不怎么玩我自己写的地图，所以我以后的更新可能就完全根据你们的喜好来了。
local yagao_idle_factorio = {}

--If any numbric setting doesnt meet your players intrests, modify it here. And let me know, thanks.
--Post something on tieba.baidu.com. First you need an acount and find the factorio web.
--如果有什么不满意的，请直接在这儿改，尤其是不会写lua的，单改这儿的数值就好了，都给你们汇总了。
--如果你有什么不错的想法，包括数值的调整，请在贴吧发帖子让我知道，我在以后的版本中会考虑你们所做的改动的。
--地图初始尺寸
local map_init_size_in_half = 50
--If you don't like the formulas I wrote in this file, you could modify it, or if you are not sure how to script in lua, you could simply change the multipliers here.
--矿的记分倍率
local ore_score_multiplier_iron = 1     --铁
local ore_score_multiplier_copper = 1   --铜   
local ore_score_multiplier_coal = 0.3   --煤
local ore_score_multiplier_stone = 1.5  --石头
local ore_score_multiplier_uranium = 5  --铀
local ore_score_multiplier_all = 0.001  --总控
--杀虫子的分数
local killing_score_multiplier_small = 0.03
local killing_score_multiplier_midium = 0.2
local killing_score_multiplier_big = 0.8
local killing_score_multiplier_very_big = 5
--火箭的分数
local rocket_score_multiplier = 10000
--回合开始时的矿物数量系数
local resource_amount_multiplier_iron = 1000    --铁
local resource_amount_multiplier_copper = 900   --铜   
local resource_amount_multiplier_coal = 600     --煤
local resource_amount_multiplier_stone = 250    --石头
local resource_amount_multiplier_oil = 250    --石油
local resource_amount_multiplier_uranium = 50   --铀
--近战虫子占全部虫子的比例
local biter_ratio_in_biters_and_spitters = 2/3


--OK,dude, if you are not get used to script, stop here. Don't change anything donw below. OK really. Trust me. You don't want your saving file to crash, right?
--如果你不熟悉工厂的脚步系统，情况不要往下看了，你的存档出问题了不要来找我帮你修复。


--A flag to tell function round start this is the first time to init a round.
--标记一下是第一次初始化地图。
global.time_to_start_first_round = true
--When a player died, its valid time is delayed for a moment. When all player's valid times are marked later than the current tick, you lose you current round and start a new round. Maybe it's not a bad thing.Means don't feed.
--当一个玩家死亡的时候，他会有一个叫做有效时间的时间属性会被记录到之后的某个时间点上，当所有的玩家的有效时间都在未来的某个时间点上，你们的当前的回合就输了。意思就是不要死太多了。
global.player_valid_time ={}
--You start new round by getting killed. This time is when the current round started.
global.start_time_in_tick_for_this_round =0
--Score is calc ed by a formula which needs to know how many ores had your lovely team mined.
global.init_ore_count_for_this_round =0
--And how many rocket launched
global.rocket_launched_in_this_round =0
--How many creepers killed in this round
global.small_creepers_killed_in_this_round=0
global.midium_creepers_killed_in_this_round=0
global.big_creepers_killed_in_this_round=0
global.very_big_creepers_killed_in_this_round=0
--A global score starts from 0 which tracks the whole progress
global.score = 0

global.map_size_info={}
global.map_size_info.border_width = 50


global.creeper_info = {}
global.creeper_info.creepers = {}


global.score_track = {}
global.round_info = {}
global.round_info.already_won_this_round = false
global.round_info.player_had_click_end_round_button = {}
global.round_info.new_round_start_time_in_tick = 0
global.round_info.players_in_total = {}


global.player_item_track = {}
global.player_still_have_loot = {}


--Calc ore 
--used twice
local function get_resource_multiplied_count()
    local width = global.map_size_info.border_width
    local ore_score_left_table = game.surfaces[1].find_entities({{0,0},{width,width}})
    local ore_score_left = 0

    if ore_score_left_table["iron-ore"] then
        ore_score_left = ore_score_left +ore_score_left_table["iron-ore"]*     ore_score_multiplier_iron    
    end
    if ore_score_left_table["copper-ore"] then
        ore_score_left = ore_score_left +ore_score_left_table["copper-ore"]*   ore_score_multiplier_copper
    end
    if ore_score_left_table["coal"] then
        ore_score_left = ore_score_left +ore_score_left_table["coal"]*         ore_score_multiplier_coal
    end
    if ore_score_left_table["stone"] then
        ore_score_left = ore_score_left +ore_score_left_table["stone"]*        ore_score_multiplier_stone
    end
    if ore_score_left_table["uranium-ore"] then
        ore_score_left = ore_score_left +ore_score_left_table["uranium-ore"]*  ore_score_multiplier_uranium
    end

    return ore_score_left
end



--Dont modify

local function update_map_size()

    global.map_size_info.border_width = math.pow(global.score,0.5) +50
    global.map_size_info.border_width = math.max( global.map_size_info.border_width,50)
    global.map_size_info.border_width =math.floor(global.map_size_info.border_width)
end

    
local function set_map_tiles_for_new_round()
    local width = global.map_size_info.border_width --for short


    --all the api doesn't work at all with corpse. Reason is still unknown.
    -- --put items in corpses in to chest and remove 
    -- local corpse_list = game.surfaces[1].find_entities_filtered{area = {{-1,-length*2},{length*2,1}}, name = "character-corpse"}
    
    
    -- for  _,corpse in pairs(corpse_list) do
    --     local pos = {}
    --     pos = game.surfaces[1].find_non_colliding_position( "character-corpse", {(1/2)*length,-(1/2)*length},(1/2)*length,0.5)
    --     corpse.teleport({10,-10})  --111111111111111
    -- end



    
    local tiles = {}
    --move players to a safe place
    for x = -55,-45 do
        for y = -5,5 do
            table.insert(tiles,{name = "grass-1",position = {x= x,y =y}})
        end
    end
    game.surfaces[1].set_tiles(tiles)
    for k,v in pairs(game.players) do
        v.teleport(-50-v.position.x,-v.position.y)
    end

    --set tiles
    tiles = {}
    for x = 0,300+2*width do
        for y = -300-2*width,300 do
            table.insert(tiles,{name = "out-of-map",position = {x= x,y =y}})
        end
    end
    game.surfaces[1].set_tiles(tiles)

    --create tiles for safety purpose 
    tiles = {}
    for x = 20,30 do
        for y = -30,-20 do
            table.insert(tiles,{name = "grass-1",position = {x= x,y =y}})
        end
    end
    game.surfaces[1].set_tiles(tiles)
    for k,v in pairs(game.players) do
        v.teleport(width/3-v.position.x,-width/3-v.position.y)
    end
    local tile_name ="grass-1"
    for x = -width*2,4*width do
      for y = -4*width,width*2 do
        y = -y
        tile_name ="grass-1"

        --1,make a square
        if x<0 or y<0 then 
          tile_name = "out-of-map"
        end 
        if x>width+width or y > width+width then 
          tile_name = "out-of-map"
        end 
        -- get rid of left top and right bottom
        if y>width  and y>x+width * 0.3 then 
          tile_name = "out-of-map"
        end 
        if x>width and y<x-width*0.3 then 
          tile_name = "out-of-map"
        end 
        
        table.insert(tiles,{name = tile_name,position = {x= x,y =-y}})
      end 
    end 
    game.surfaces[1].set_tiles(tiles)

end


local function init_resource_for_this_round()
    local width = global.map_size_info.border_width
   
-- log(width)

    local old_resource = game.surfaces[1].find_entities_filtered
        {area = {{-width-200, -width-200}, {width+width+200, width+width+200}}}--, type= "resource"
    for k,v in pairs(old_resource)do
        if v.name ~="player" then
            v.destroy()
        end
    end
    -- local to_find_big_rocks = game.surfaces[1].find_entities
    --     {area = {{-width-200, -width-200}, {width+width+200, width+width+200}}}
    -- for _,entity in pairs(to_find_big_rocks) do
    --     if entity.name ==""
    -- end        11111111111111111111  本来想要删掉初始的大石头和多余的树的，想了一下还是留着吧。

    local tiles = {}
    local one_eighth = math.floor(width/8)
    local one_fourths = math.floor(width/4)
    local three_eighths = math.floor((width*3)/8)
    

    for x = one_fourths + 1,three_eighths - 1 do
        for y = 0, one_eighth do
            table.insert(tiles,{name = "water",position = {x,-y}})
            table.insert(tiles,{name = "water",position = {x+three_eighths,-y}})
            table.insert(tiles,{name = "water",position = {y,-x}})
            table.insert(tiles,{name = "water",position = {y,-(x+three_eighths)  }  })
        end
    end
    game.surfaces[1].set_tiles(tiles)

    local s1 = global.score-- only for short
    if s1<2  then s1 = 2 end
    local surface = game.surfaces[1]-- only for short
    local resource_amount = {}
    resource_amount.iron    = s1*resource_amount_multiplier_iron
    resource_amount.copper  = s1*resource_amount_multiplier_copper
    resource_amount.coal    = s1*resource_amount_multiplier_coal 
    resource_amount.stone   = s1*resource_amount_multiplier_stone 
    resource_amount.oil     = s1*resource_amount_multiplier_oil 
    resource_amount.uranium = s1*resource_amount_multiplier_uranium


    local resident_area = (one_eighth+1)*(one_eighth+1)
    local temp = 0
    if resource_amount.uranium>10000 then 
        for x = 0,one_eighth do
            for y = 0,one_eighth do
                if resident_area ~= 1 then
                    temp = resource_amount.uranium/resident_area
                    surface.create_entity{name="uranium-ore",amount = temp ,position = {x,-y}}
                    resource_amount.uranium = resource_amount.uranium-temp
                else
                    surface.create_entity{name="uranium-ore",amount =resource_amount.uranium,position = {x,-y}}
                end
                resident_area = resident_area - 1
            end
        end
    end
    

    local crude_oil_spring_count =0
    for x = one_eighth + 4 , one_fourths , 9 do
        for y = 1,one_eighth , 9 do
            crude_oil_spring_count = crude_oil_spring_count+1
        end
    end
    crude_oil_spring_count = crude_oil_spring_count*2
    local crude_oil_amount_for_each = resource_amount.oil/crude_oil_spring_count


    if crude_oil_amount_for_each>1 then
        for x = one_eighth + 4 , one_fourths , 9 do
            for y = 1,one_eighth , 9 do
                surface.create_entity{name="crude-oil",amount = crude_oil_amount_for_each , position = {x,-y}}
                surface.create_entity{name="crude-oil",amount = crude_oil_amount_for_each , position = {y,-x}}
            end
        end
    end


    resident_area = (one_eighth+1)*(width-(three_eighths+three_eighths)+1)
    for x = 0 , one_eighth do
        for y = three_eighths+three_eighths,width do
            if resident_area ~= 1 then
                temp = resource_amount.stone/resident_area
                surface.create_entity{name="stone",amount = temp ,position = {x,-y}}
                resource_amount.stone = resource_amount.stone-temp
            else
                surface.create_entity{name="stone",amount =resource_amount.stone,position = {x,-y}}
            end
            resident_area = resident_area - 1
        end
    end


    resident_area = (one_eighth+1)*(one_fourths+1)
    for x = 0 , one_eighth do
        for y = three_eighths,three_eighths+one_fourths do
            if resident_area~=1 then
                temp = resource_amount.copper/resident_area
                surface.create_entity{name="copper-ore",amount = temp ,position = {x,-y}}
                resource_amount.copper = resource_amount.copper-temp
            else
                surface.create_entity{name="copper-ore",amount =resource_amount.copper,position = {x,-y}}
            end
            resident_area = resident_area - 1
        end
    end


    resident_area = (one_eighth+1)*(width-(three_eighths+three_eighths)+1)
    for x = three_eighths+three_eighths,width do
        for y = 0 , one_eighth do
            if resident_area~=1 then
                temp = resource_amount.coal/resident_area
                surface.create_entity{name="coal",amount = temp ,position = {x,-y}}
                resource_amount.coal = resource_amount.coal-temp
            else
                surface.create_entity{name="coal",amount =resource_amount.coal,position = {x,-y}}
            end
            resident_area = resident_area - 1
        end
    end


    resident_area = (one_eighth+1)*(one_fourths+1)
    for x = three_eighths,three_eighths+one_fourths do
        for y = 0 , one_eighth do
            if resident_area~=1 then
                temp = resource_amount.iron/resident_area
                surface.create_entity{name="iron-ore",amount = temp ,position = {x,-y}}
                resource_amount.iron = resource_amount.iron-temp
            else
                surface.create_entity{name="iron-ore",amount =resource_amount.iron,position = {x,-y}}
            end
            resident_area = resident_area - 1
        end
    end

    local pos = {}
    local tree_count = 100 +math.sqrt(global.score)
    for  i = 1,tree_count do
        pos = {(0.4+(math.random(1,101)-1)/200)*width,-(0.4+(math.random(1,101)-1)/200)*width}
        pos = surface.find_non_colliding_position("tree-02", pos,width*(0.5), 0.3)
        if pos then
            surface.create_entity{name="tree-02",position = pos}
        end
    end
end


local function init_map_for_this_round()

    update_map_size()

    set_map_tiles_for_new_round()

    init_resource_for_this_round()
    global.init_ore_count_for_this_round = get_resource_multiplied_count()
end


--Formula to calc score.
local function update_score_for_this_round()

    local ore_score_left = 0
    if false == global.round_info.already_won_this_round then
        ore_score_left =get_resource_multiplied_count()
    end

--calc each score
    local _ore_score =( global.init_ore_count_for_this_round - ore_score_left)*  ore_score_multiplier_all
            * (game.forces["player"].mining_drill_productivity_bonus+1)

    local rocket_score = global.rocket_launched_in_this_round*  rocket_score_multiplier
    local _killing_score = 
        (global.small_creepers_killed_in_this_round*        killing_score_multiplier_small
        +global.midium_creepers_killed_in_this_round*       killing_score_multiplier_midium
        +global.big_creepers_killed_in_this_round*          killing_score_multiplier_big
        +global.very_big_creepers_killed_in_this_round*     killing_score_multiplier_very_big
        )

--update

    if true == global.round_info.already_won_this_round then
        global.score =  global.score +2*(_ore_score +rocket_score +_killing_score)
    else
        global.score =  global.score +_ore_score +rocket_score +_killing_score
    end

    table.insert(global.score_track,{
        round_count = #global.score_track +1,
        win = global.round_info.already_won_this_round,
        score = global.score,
        round_time = global.start_time_in_tick_for_this_round,
        ore_score = _ore_score,
        killing_score = _killing_score,
        rocket = global.rocket_launched_in_this_round,
        mining_productivity = game.forces["player"].mining_drill_productivity_bonus,
        robot_speed = game.forces["player"].worker_robots_speed_modifier
    })
    
    game.write_file("Yagao Idle Factorio Score File.txt", serpent.block(global.score_track))
    game.print({"global notice - score file save"})

end


local function set_team_powerup()
    -- global.score  for short .Used in the whole function
    local s = global.score --only for short

--force bonus
    --notice. Quickbar count starts from 1, following robots count starts from 1,the last boolean ,share chart,is false by defult.
    --注意 。快捷工具栏从1开始，跟随机器人数量从1开始，最后那个共享什么事业还是什么，默认是假。你们如果一定要改这儿的数值的话稍微注意一点。
    --反正快捷栏不要改多了，不然你画面中间会被挡到。

    local r = 0 --result

    r = math.sqrt(s)*0.5
    r = math.clamp(r,0,100)
    game.forces["player"].manual_mining_speed_modifier = r
    r = math.sqrt(s)*0.2
    r = math.clamp(r,0,100)
    game.forces["player"].manual_crafting_speed_modifier = r
    r = math.sqrt(s)*0.1
    r = math.clamp(r,0,1000)
    game.forces["player"].laboratory_speed_modifier  = r
    r = math.sqrt(s)*0.01
    r = math.clamp(r,0,50)
    game.forces["player"].laboratory_productivity_bonus = r
    r = math.sqrt(s)*0.01
    r = math.clamp(r,0,100)
    game.forces["player"].worker_robots_speed_modifier = r
    r = math.sqrt(s)*0.005
    r = math.clamp(r,0,100)
    game.forces["player"].worker_robots_battery_modifier = r
    r = math.sqrt(s)*0.0015
    r = math.clamp(r,0,30)
    game.forces["player"].worker_robots_storage_bonus = math.floor(r)
    r = math.sqrt(s)*0.002
    r = math.clamp(r,0,15)
    game.forces["player"].inserter_stack_size_bonus = math.floor(r)
    r = math.sqrt(s)*0.001
    r = math.clamp(r,0,120)
    game.forces["player"].stack_inserter_capacity_bonus = math.floor(r)
    r = math.sqrt(s)*0.005
    r = math.clamp(r,0,4)
    game.forces["player"].character_logistic_slot_count = math.floor(r) 
    r = math.sqrt(s)*0.001
    r = math.clamp(r,0,2)
    game.forces["player"].character_trash_slot_count = math.floor(r) 
    r = 1
    if s>1000000 then r = 2 end
    game.forces["player"].quickbar_count  = math.floor(r)  --starts from 1
    r = math.sqrt(s)*0.01
    r = math.clamp(r+1,1,300)
    game.forces["player"].maximum_following_robot_count = math.floor(r)  --starts from 1
    r = math.sqrt(s)*0.1
    r = math.clamp(r,0,30)
    game.forces["player"].following_robots_lifetime_modifier = r
    r = math.sqrt(s)*0.0015
    r = math.clamp(r,0,4)
    game.forces["player"].character_running_speed_modifier = r
    r = math.sqrt(s)*0.1
    r = math.clamp(r,0,30)
    game.forces["player"].artillery_range_modifier = r
    r = math.sqrt(s)*0.03
    r = math.clamp(r,0,3)
    game.forces["player"].character_build_distance_bonus = r
    game.forces["player"].character_item_drop_distance_bonus  = r
    game.forces["player"].character_reach_distance_bonus = r
    game.forces["player"].character_resource_reach_distance_bonus = r 
    game.forces["player"].character_item_pickup_distance_bonus = r
    game.forces["player"].character_loot_pickup_distance_bonus = r
    r = s*0.001
    r = math.clamp(r,0,400)
    game.forces["player"].character_inventory_slots_bonus = math.floor(r) 
    r = s*0.003
    r = math.clamp(r,0,10000)
    game.forces["player"].character_health_bonus = math.floor(r)       -- hp =250 + this bonus
    r = s*0.00005
    game.forces["player"].mining_drill_productivity_bonus = r
    game.forces["player"].train_braking_force_bonus = r
    -- game.forces["player"].share_chart(boolean)  --false by defult . To be 



--items

--first , insert common items to all players
--先设置相同的物品。
    local starting_items ={}
    local t = 0 --total. Used when I need to control the total amount of items in a seriers
    local p1 = 0 --percentage
    local p2 = 0 --percentage
    local p3 = 0 --percentage


    t = math.sqrt(s)*10
    t = math.clamp(t+8,8,400)
    p1 = yagao_math.point_on_line(30,1,200,0,s) -- the line go through points with coord of 30,1 and 200,0
    --我是用了一个直线的方程，这个方程通过两个点，坐标如上
    p1 = math.clamp(p1,0,1)
    p2 = -0.001*s + 1.1 -- 100,1  1100,0
    p2 = math.clamp(p2,0,1-p1)
    p3 = math.clamp(1- p1-p2 ,0,1)
    starting_items["transport-belt"] =         math.floor(t * p1)
    starting_items["fast-transport-belt"] =    math.floor(t * p2)
    starting_items["express-transport-belt"] = math.floor(t * p3)

    t = math.sqrt(s)*2
    t = math.clamp(t+3,3,300)
    p1 = -0.001*s + 1.1 -- 100,1  1100,0
    p1 = math.clamp(p1,0,1)
    p2 = math.clamp(1- p1 ,0,1)
    starting_items["burner-inserter"] = math.floor(t* p1) 
    starting_items["inserter"] =         math.floor(t* p2)

    t = math.sqrt(s)
    t = math.clamp(t,0,50)
    p1 = -0.001*s + 1.1 -- 100,1  1100,0
    p1 = math.clamp(p1,0,1)
    p2 = math.clamp(1- p1 ,0,1)
    starting_items["small-electric-pole"] =  math.floor(t* p1) 
    starting_items["medium-electric-pole"] =  math.floor(t* p2) 

    t = math.sqrt(s)*0.3
    t = math.clamp(t,0,30)
    starting_items["big-electric-pole"]= math.floor(t)

    starting_items["car"] = 0
    starting_items["tank"] = 0
    if s>10000 then 
        starting_items["tank"] = 1
    elseif s>3000 then
        starting_items["car"] = 1
    end

    t = math.sqrt(s)*0.15
    t = math.clamp(t,0,15)
    starting_items["construction-robot"] = math.floor(t)

    t = math.sqrt(s)*0.01
    t = math.clamp(t,0,3)
    starting_items["roboport"] = math.floor(t)

    t = math.sqrt(s)*0.4
    t = math.clamp(t,0,12)
    starting_items["boiler"] = math.floor(t)
    t = math.sqrt(s)*0.6
    t = math.clamp(t,0,20)
    starting_items["steam-engine"] = math.floor(t)

    t = 0
    if s>500 then t = math.sqrt(s-500)*0.5 end
    t = math.clamp(t,0,70)
    starting_items["solar-panel"] =  math.floor(t)

    t = 0
    if s>2000 then t = math.sqrt(s-2000)*0.1 end
    t = math.clamp(t,0,50)
    starting_items["accumulator"] =  math.floor(t)

    t = math.sqrt(s)*0.1
    t = math.clamp(t+2,2,20)
    p1 = -0.001*s + 1.1 -- 100,1  1100,0
    p1 = math.clamp(p1,0,1)
    p2 = math.clamp(1- p1 ,0,1)
    starting_items["burner-mining-drill"] = math.floor(t*p1)
    starting_items["electric-mining-drill"] = math.floor(t*p2)

    t = 0
    if s>5 then t =1 end
    starting_items["pumpjack"] =  math.floor(t)

    t = math.sqrt(s)*0.5
    t = math.clamp(t+3,3,50)
    p1 = -1*(s/2000) + 1.25 -- 500,1  2500,0
    p1 = math.clamp(p1,0,1)
    p2 = -1*(s/5000) + 1.3  --1500,1 6500,0
    p2 = math.clamp(p2,0,1-p1)
    p3 = math.clamp(1- p1-p2 ,0,1)
    starting_items["stone-furnace"]    = math.floor(t*p1)
    starting_items["steel-furnace"]    = math.floor(t*p2)
    starting_items["electric-furnace"] = math.floor(t*p3)

    t = math.sqrt(s)*0.15
    t = math.clamp(t-1.5,0,15)
    p1 = -1*(s/2000) + 1.25 -- 500,1  2500,0
    p1 = math.clamp(p1,0,1)
    p2 = -1*(s/5000) + 1.3  --1500,1 6500,0
    p2 = math.clamp(p2,0,1-p1)
    p3 = math.clamp(1- p1-p2 ,0,1)
    starting_items["assembling-machine-1"] =  math.floor(t*p1)
    starting_items["assembling-machine-2"] =  math.floor(t*p2)
    starting_items["assembling-machine-3"] =  math.floor(t*p3)

    t = math.sqrt(s)*0.01
    t = math.clamp(t-1,0,2)
    starting_items["oil-refinery"] =  math.floor(t)
    starting_items["chemical-plant"] = math.floor(t)*5

    t = math.sqrt(s)*0.01
    t = math.clamp(t,0,5)
    starting_items["lab"] = math.floor(t)


    t = math.sqrt(s)*0.15
    t = math.clamp(t-5,0,50)
    p1 = -1*(s/20000) + 1.25 -- 5000,1  25000,0
    p1 = math.clamp(p1,0,1)
    p2 = -1*(s/200000) + 1.25  --50000,1  250000,0
    p2 = math.clamp(p2,0,1-p1)
    p3 = math.clamp(1- p1-p2 ,0,1)
    starting_items["speed-module"]   = math.floor(t*p1)
    starting_items["speed-module-2"] = math.floor(t*p2)
    starting_items["speed-module-3"] = math.floor(t*p3)
    starting_items["effectivity-module"]   = math.floor(t*p1/3)
    starting_items["effectivity-module-2"] = math.floor(t*p2/2)
    starting_items["effectivity-module-3"] = math.floor(t*p3/1.7)
    starting_items["productivity-module"]   = math.floor(t*p1/2)
    starting_items["productivity-module-2"] = math.floor(t*p2/1.6)
    starting_items["productivity-module-3"] = math.floor(t*p3/1.3)

    t = s*0.01
    t = math.clamp(t,0,200)
    starting_items["solid-fuel"] = math.floor(t)

    t = s*0.1
    t = math.clamp(t,0,20)
    starting_items["raw-wood"] = math.floor(t)


    t = s*0.15
    t = math.clamp(t,0,300)
    starting_items["iron-plate"] = math.floor(t)

    t = s*0.1
    t = math.clamp(t,0,400)
    starting_items["copper-plate"] = math.floor(t)

    t = s*0.03
    t = math.clamp(t,0,200)
    starting_items["steel-plate"] = math.floor(t)

    t = s*0.03
    t = math.clamp(t,0,200)
    starting_items["plastic-bar"] = math.floor(t)


    t = s*0.018
    t = math.clamp(t,0,300)
    starting_items["battery"] = math.floor(t)

    t = math.sqrt(s)*4
    t = math.clamp(t,0,400)
    starting_items["electronic-circuit"] = math.floor(t)

    t = math.sqrt(s)
    t = math.clamp(t,0,400)
    starting_items["advanced-circuit"] = math.floor(t)

    t = math.sqrt(s)*0.5
    t = math.clamp(t,0,600)
    starting_items["processing-unit"] = math.floor(t)

    t = math.sqrt(s)*0.5
    t = math.clamp(t,0,100)
    starting_items["engine-unit"] = math.floor(t)

    t = math.sqrt(s)*0.2
    t = math.clamp(t,0,200)
    starting_items["electric-engine-unit"] = math.floor(t)

    -- starting_items["science-pack-1"]
    -- starting_items["science-pack-2"]
    -- starting_items["science-pack-3"]
    -- starting_items["military-science-pack"]
    -- starting_items["production-science-pack"]
    -- starting_items["high-tech-science-pack"]
    -- starting_items["space-tech-science-pack"]



    t = math.sqrt(s)*0.6
    t = math.clamp(t,0,200)
    p1 = -1*(s/20000) + 1.25 -- 5000,1  25000,0
    p1 = math.clamp(p1,0,1)
    p2 = -1*(s/50000) + 2  --50000,1  100000,0
    p2 = math.clamp(p2,0,1-p1)
    p3 = math.clamp(1- p1-p2 ,0,1)

    starting_items["firearm-magazine"]        = math.floor(t*p1)
    starting_items["piercing-rounds-magazine"]= math.floor(t*p2)
    starting_items["uranium-rounds-magazine"] = math.floor(t*p3)


    -- starting_items["shotgun-shells"]
    -- starting_items["piercing-shotgun-shells"]
    -- starting_items["cannon-shell"]
    -- starting_items["explosive-cannon-shell"]
    -- starting_items["uranium-cannon-shell"]
    -- starting_items["explosive-uranium-cannon-shell"]
    -- starting_items["artillery-shell"]
    -- starting_items["rocket"]
    -- starting_items["explosive-rocket"]
    -- starting_items["flamethrower-ammo"]
    -- starting_items["grenade"]
    -- starting_items["cluster-grenade"]
    -- starting_items["poison-capsule"]
    -- starting_items["slowdown-capsule"]
    -- starting_items["defender-capsule"]
    -- starting_items["distractor-capsule"]
    -- starting_items["destroyer-capsule"]
    -- starting_items["light-armor"]
    -- starting_items["heavy-armor"]
    -- starting_items["modular-armor"]
    -- starting_items["power-armor"]
    -- starting_items["power-armor-mk2"]
    -- starting_items["portable-solar-panel"]
    -- starting_items["portable-fusion-reactor"]
    -- starting_items["exoskeleton"]
    -- starting_items["personal-roboport"]
    -- starting_items["personal-roboport-mk2"]
    -- starting_items["nightvision"]

    t = s*0.05
    t = math.clamp(t,0,200)
    starting_items["stone-wall"] = math.floor(t)

    t = math.sqrt(s)*0.4
    t = math.clamp(t,0,10)
    starting_items["gun-turret"] = math.floor(t)

    t = math.sqrt(s)*0.1
    t = math.clamp(t,0,10)
    starting_items["laser-turret"] = math.floor(t)

    t = math.sqrt(s)*0.1
    t = math.clamp(t,0,10)
    starting_items["flamethrower-turret"] = math.floor(t)

    --for all with a count 0, remove it from table
    for k,v in pairs(starting_items) do
        if v == 0 then 
          starting_items[k] = nil
        end
    end

    for _,player in pairs(game.players)do
        if player.connected == true then
            for item_name,item_count in pairs(starting_items) do
                --safety
                if not global.player_item_track[player.index] then
                    global.player_item_track[player.index] ={}
                end

                if not global.player_item_track[player.index][item_name] then
                    global.player_item_track[player.index][item_name] = starting_items[item_name]
                else
                    global.player_item_track[player.index][item_name] = 
                        global.player_item_track[player.index][item_name]+starting_items[item_name]
                end
            end
        else
            --disconnected players only have latest loot
            global.player_item_track[player.index][item_name] = global.player_item_track[player.index][item_name]
        end
      end



--特殊物品先不写











--techs  

--non infinity techs are random
--非无限科技只按需要几种瓶子来绝对概率。
    local posibility_lv ={}
    posibility_lv[1] = global.score/100
    if posibility_lv[1]>1 then posibility_lv[1] =1 end
    posibility_lv[2] = global.score/2000 
    if posibility_lv[2]>1 then posibility_lv[2] =1 end
    posibility_lv[3] = global.score/50000 
    if posibility_lv[3]>1 then posibility_lv[3] =1 end
    posibility_lv[4] = global.score/200000
    if posibility_lv[4]>1 then posibility_lv[4] =1 end
    posibility_lv[5] = global.score/1200000   
    if posibility_lv[5]>1 then posibility_lv[5] =1 end
    posibility_lv[6] = global.score/5000000
    if posibility_lv[6]>1 then posibility_lv[6] =1 end
    posibility_lv[7] = 0 
-- --infinity techs are calc ed directly. No random
    --     local tech_lv_mining_productivity = global.score/100
    --     tech_lv_mining_productivity = math.floor(tech_lv_mining_productivity)
    --     local tech_lv_robots_speed = global.score/10000
    --     tech_lv_robots_speed = math.floor(tech_lv_robots_speed)

    -- --calc other infi techs' level
    --     local tech_lv_rocket_damage = global.score/2500
    --     tech_lv_rocket_damage = math.floor(tech_lv_rocket_damage)
    --     local tech_lv_bullet_damage = global.score/2000
    --     tech_lv_bullet_damage = math.floor(tech_lv_bullet_damage)
    --     local tech_lv_shotgun_shell_damage = global.score/2000
    --     tech_lv_shotgun_shell_damage = math.floor(tech_lv_shotgun_shell_damage)
    --     local tech_lv_laser_turret_damage = global.score/6000
    --     tech_lv_laser_turret_damage = math.floor(tech_lv_laser_turret_damage)
    --     local tech_lv_gun_turret_damage = global.score/2500
    --     tech_lv_gun_turret_damage = math.floor(tech_lv_gun_turret_damage)
    --     local tech_lv_flamethrower_damage = global.score/3000
    --     tech_lv_flamethrower_damage = math.floor(tech_lv_flamethrower_damage)
    --     local tech_lv_combat_robots_damage = global.score/2000
    --     tech_lv_combat_robots_damage = math.floor(tech_lv_combat_robots_damage)
    --     local tech_lv_artillery_shell_range = global.score/800
    --     tech_lv_artillery_shell_range = math.floor(tech_lv_artillery_shell_range)
    --     local tech_lv_cannon_shell_damage = global.score/2000
    --     tech_lv_cannon_shell_damage = math.floor(tech_lv_cannon_shell_damage)
    --     local tech_lv_artillery_shell_shooting_speed = global.score/4000
    --     tech_lv_artillery_shell_shooting_speed = math.floor(tech_lv_artillery_shell_shooting_speed)
    --     local tech_lv_grenade_damage = global.score/2000
    --     tech_lv_grenade_damage = math.floor(tech_lv_grenade_damage)
    --     local tech_lv_follower_robots_count = global.score/2000
    --     tech_lv_follower_robots_count = math.floor(tech_lv_follower_robots_count)

--random all techs first. Inside this part, I ensured upgrade techs are enabled only the lower ones are all enabled in its seriers.
--方案1，数字结尾的单独处理

    for _,v in pairs(game.forces["player"].technologies) do
        local char_pos = string.find(v.name,tostring(v.prototype.level))--->double..
        if char_pos then
        
            if v.prototype.level ==1 then
                if math.random(1,10000)/10000 < posibility_lv[#v.research_unit_ingredients] then
                    if v.prototype.max_level >1 then
                        v.level = v.level+1
                        v.enabled = true
                    else
                        v.researched = true
                    end
                else
                    for i = 2,7 do
                        for k2,v2 in pairs(game.forces["player"].technologies) do
                            if string.gsub(v2.name , tostring(i) , "1") == v.name then
                                for ii=v2.prototype.level ,  v2.prototype.max_level do
                                    if ii< v2.prototype.max_level then
                                        if math.random(1,10000)/10000 < posibility_lv[#v2.research_unit_ingredients] then
                                            v2.level = v2.level+1
                                            v.enabled = true
                                        else
                                            break
                                        end
                                    else
                                        if math.random(1,10000)/10000 < posibility_lv[#v2.research_unit_ingredients] then
                                            v2.researched = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            --this is not a upgrade tech which has a name end up with number
            if math.random(1,10000)/10000 < posibility_lv[#v.research_unit_ingredients] then
                v.enabled = true
            end
        end
    end
--     --finally set 14 infi techs
    --     --notice. If a tech has a max level of 8, and you set its level to something greater then 8, the game crashes.
    -- --mining productivity
    -- --挖矿产能
    --     local tech = game.forces["player"].technologies["mining-productivity-1"]
    --     if tech_lv_mining_productivity>3 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_mining_productivity>1 then
    --             tech.level = tech_lv_mining_productivity
    --         end
    --     end
    --     tech = game.forces["player"].technologies["mining-productivity-4"]
    --     if tech_lv_mining_productivity>8 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_mining_productivity>4 then
    --             tech.level = tech_lv_mining_productivity
    --         end
    --     end
    --     tech = game.forces["player"].technologies["mining-productivity-8"]
    --     if tech_lv_mining_productivity>12 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_mining_productivity>8 then
    --             tech.level = tech_lv_mining_productivity
    --         end
    --     end
    --     tech = game.forces["player"].technologies["mining-productivity-12"]
    --     if tech_lv_mining_productivity>16 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_mining_productivity>12 then
    --             tech.level = tech_lv_mining_productivity
    --         end
    --     end
    --     tech = game.forces["player"].technologies["mining-productivity-16"]
    --     if tech_lv_mining_productivity>16 then
    --         tech.level = tech_lv_mining_productivity
    --     end
    -- --robots-speed
    -- --机器人速度
    --     tech = game.forces["player"].technologies["worker-robots-speed-1"]
    --     if tech_lv_robots_speed>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["worker-robots-speed-2"]
    --     if tech_lv_robots_speed>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["worker-robots-speed-3"]
    --     if tech_lv_robots_speed>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["worker-robots-speed-4"]
    --     if tech_lv_robots_speed>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["worker-robots-speed-5"]
    --     if tech_lv_robots_speed>6 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_robots_speed>5 then
    --             tech.level = tech_lv_robots_speed
    --         end
    --     end
    --     tech = game.forces["player"].technologies["worker-robots-speed-7"]
    --     if tech_lv_robots_speed>7 then
    --         tech.level = tech_lv_robots_speed
    --     end
    -- --rocket damage
    -- --火箭伤害
    --     tech = game.forces["player"].technologies["rocket-damage-1"]
    --     if tech_lv_rocket_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-2"]
    --     if tech_lv_rocket_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-3"]
    --     if tech_lv_rocket_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-4"]
    --     if tech_lv_rocket_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-5"]
    --     if tech_lv_rocket_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-6"]
    --     if tech_lv_rocket_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_rocket_damage>6 then
    --             tech.level = tech_lv_rocket_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["rocket-damage-8"]
    --     if tech_lv_rocket_damage>8 then
    --         tech.level = tech_lv_rocket_damage
    --     end
    -- --bullet-damage
    -- -- 子弹伤害
    --     tech = game.forces["player"].technologies["bullet-damage-1"]
    --     if tech_lv_bullet_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-2"]
    --     if tech_lv_bullet_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-3"]
    --     if tech_lv_bullet_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-4"]
    --     if tech_lv_bullet_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-5"]
    --     if tech_lv_bullet_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-6"]
    --     if tech_lv_bullet_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_bullet_damage>6 then
    --             tech.level = tech_lv_bullet_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["bullet-damage-8"]
    --     if tech_lv_bullet_damage>8 then
    --         tech.level = tech_lv_bullet_damage
    --     end
    -- --shotgun-shell-damage
    -- --散弹枪伤害
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-1"]
    --     if tech_lv_shotgun_shell_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-2"]
    --     if tech_lv_shotgun_shell_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-3"]
    --     if tech_lv_shotgun_shell_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-4"]
    --     if tech_lv_shotgun_shell_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-5"]
    --     if tech_lv_shotgun_shell_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-6"]
    --     if tech_lv_shotgun_shell_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_shotgun_shell_damage>6 then
    --             tech.level = tech_lv_shotgun_shell_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["shotgun-shell-damage-8"]
    --     if tech_lv_shotgun_shell_damage>8 then
    --         tech.level = tech_lv_shotgun_shell_damage
    --     end
    -- --laser-turret-damage
    -- --激光炮台伤害
    --     tech = game.forces["player"].technologies["laser-turret-damage-1"]
    --     if tech_lv_laser_turret_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-2"]
    --     if tech_lv_laser_turret_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-3"]
    --     if tech_lv_laser_turret_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-4"]
    --     if tech_lv_laser_turret_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-5"]
    --     if tech_lv_laser_turret_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-6"]
    --     if tech_lv_laser_turret_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-7"]
    --     if tech_lv_laser_turret_damage>8 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_laser_turret_damage>7 then
    --             tech.level = tech_lv_laser_turret_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["laser-turret-damage-9"]
    --     if tech_lv_laser_turret_damage>9 then
    --         tech.level = tech_lv_laser_turret_damage
    --     end
    -- --gun-turret-damage
    -- --机枪炮台附加伤害
    --     tech = game.forces["player"].technologies["gun-turret-damage-1"]
    --     if tech_lv_gun_turret_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-2"]
    --     if tech_lv_gun_turret_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-3"]
    --     if tech_lv_gun_turret_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-4"]
    --     if tech_lv_gun_turret_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-5"]
    --     if tech_lv_gun_turret_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-6"]
    --     if tech_lv_gun_turret_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_gun_turret_damage>6 then
    --             tech.level = tech_lv_gun_turret_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["gun-turret-damage-8"]
    --     if tech_lv_gun_turret_damage>8 then
    --         tech.level = tech_lv_gun_turret_damage
    --     end
    -- --flamethrower-damage
    -- --火焰炮台附加伤害
    --     tech = game.forces["player"].technologies["flamethrower-damage-1"]
    --     if tech_lv_flamethrower_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-2"]
    --     if tech_lv_flamethrower_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-3"]
    --     if tech_lv_flamethrower_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-4"]
    --     if tech_lv_flamethrower_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-5"]
    --     if tech_lv_flamethrower_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-6"]
    --     if tech_lv_flamethrower_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_flamethrower_damage>6 then
    --             tech.level = tech_lv_flamethrower_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["flamethrower-damage-8"]
    --     if tech_lv_flamethrower_damage>8 then
    --         tech.level = tech_lv_flamethrower_damage
    --     end
    -- --combat-robots-damage
    -- --战斗机器人伤害
    --     tech = game.forces["player"].technologies["combat-robots-damage-1"]
    --     if tech_lv_combat_robots_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["combat-robots-damage-2"]
    --     if tech_lv_combat_robots_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["combat-robots-damage-3"]
    --     if tech_lv_combat_robots_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["combat-robots-damage-4"]
    --     if tech_lv_combat_robots_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["combat-robots-damage-5"]
    --     if tech_lv_combat_robots_damage>6 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_combat_robots_damage>5 then
    --             tech.level = tech_lv_combat_robots_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["combat-robots-damage-7"]
    --     if tech_lv_combat_robots_damage>7 then
    --         tech.level = tech_lv_combat_robots_damage
    --     end
    -- --artillery-shell-range
    -- --重炮距离
    --     tech = game.forces["player"].technologies["artillery-shell-range-1"]
    --     if tech_lv_artillery_shell_range>1 then
    --         tech.level = tech_lv_artillery_shell_range
    --     end
    -- --cannon-shell-damage
    -- --战斗机器人伤害
    --     tech = game.forces["player"].technologies["cannon-shell-damage-1"]
    --     if tech_lv_cannon_shell_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["cannon-shell-damage-2"]
    --     if tech_lv_cannon_shell_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["cannon-shell-damage-3"]
    --     if tech_lv_cannon_shell_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["cannon-shell-damage-4"]
    --     if tech_lv_cannon_shell_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["cannon-shell-damage-5"]
    --     if tech_lv_cannon_shell_damage>6 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_cannon_shell_damage>5 then
    --             tech.level = tech_lv_cannon_shell_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["cannon-shell-damage-7"]
    --     if tech_lv_cannon_shell_damage>7 then
    --         tech.level = tech_lv_cannon_shell_damage
    --     end
    -- --artillery-shell-shooting-speed
    -- --重炮射速
    --     tech = game.forces["player"].technologies["artillery-shell-shooting-speed-1"]
    --     if tech_lv_artillery_shell_shooting_speed>1 then
    --         tech.level = tech_lv_artillery_shell_shooting_speed
    --     end
    -- --grenade-damage
    -- --手雷伤害
    --     tech = game.forces["player"].technologies["grenade-damage-1"]
    --     if tech_lv_grenade_damage>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-2"]
    --     if tech_lv_grenade_damage>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-3"]
    --     if tech_lv_grenade_damage>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-4"]
    --     if tech_lv_grenade_damage>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-5"]
    --     if tech_lv_grenade_damage>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-6"]
    --     if tech_lv_grenade_damage>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_grenade_damage>6 then
    --             tech.level = tech_lv_grenade_damage
    --         end
    --     end
    --     tech = game.forces["player"].technologies["grenade-damage-8"]
    --     if tech_lv_grenade_damage>8 then
    --         tech.level = tech_lv_grenade_damage
    --     end
    -- --follower-robots-count
    -- --手雷伤害
    --     tech = game.forces["player"].technologies["follower-robots-count-1"]
    --     if tech_lv_follower_robots_count>1 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-2"]
    --     if tech_lv_follower_robots_count>2 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-3"]
    --     if tech_lv_follower_robots_count>3 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-4"]
    --     if tech_lv_follower_robots_count>4 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-5"]
    --     if tech_lv_follower_robots_count>5 then
    --         tech.enabled =true
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-6"]
    --     if tech_lv_follower_robots_count>7 then
    --         tech.enabled =true
    --     else 
    --         if tech_lv_follower_robots_count>6 then
    --             tech.level = tech_lv_follower_robots_count
    --         end
    --     end
    --     tech = game.forces["player"].technologies["follower-robots-count-8"]
    --     if tech_lv_follower_robots_count>8 then
    --         tech.level = tech_lv_follower_robots_count
    --     end

end



local function init_creeper()

    local info = global.creeper_info  -- for short

    game.forces["enemy"].reset()
    info.current_wave_number = 0
    
    local r = 0
--time info
    r = game.tick +90*60+ math.sqrt(global.score)*60
    info.next_wave_time_in_tick = r
    r = 60*60 + math.pow(global.score,0.25)*6*60
    info.duration_between_waves = r
    r = 15+math.pow(global.score,0.25)
    r = math.clamp(r,15,25)
    info.min_duration_between_waves  = r
--count info
    r =5+ math.pow(global.score,0.25)
    info.count_for_first_wave = math.floor(r)
    r = 1+ math.pow(global.score,0.15)
    info.count_increace = math.floor(r)
--hp increace
    r =  math.pow(global.score,0.35)
    info.hp_increace_per_second = math.floor(r)
--% for sort
    r = biter_ratio_in_biters_and_spitters-0.1+0.2*(math.random(1,101)-1)/100
    info.percentage_of_melee = r
    info.percentage_of_ranged = 1-info.percentage_of_melee
    
--enemy's building
    local width = global.map_size_info.border_width
    local surface = game.surfaces[1]
    local pos_origin =  {x =1.5*width , y =-1.5*width}
    local pos = {}
    for i = -0.15,0.151,0.075 do
        pos = surface.find_non_colliding_position("small-worm-turret", {pos_origin.x+i,pos_origin.y+i}, 10, 1)
        surface.create_entity{name = "small-worm-turret",position = pos}
    end
    pos_origin =  {x =1.6*width, y =-1.6*width}
    for i = -0.15,0.151,0.075 do
        pos = surface.find_non_colliding_position("medium-worm-turret", {pos_origin.x+i,pos_origin.y+i},10, 1)
        surface.create_entity{name = "medium-worm-turret",position = pos}
    end
    pos_origin =  {x =1.7*width, y =-1.7*width}
    for i = -0.15,0.151,0.075 do
        pos = surface.find_non_colliding_position("big-worm-turret", {pos_origin.x+i,pos_origin.y+i}, 10, 1)
        surface.create_entity{name = "big-worm-turret",position = pos}
    end 
    pos_origin =  {x =1.95*width, y =-1.95*width}
    pos = surface.find_non_colliding_position("biter-spawner",pos_origin, 20, 2)
    surface.create_entity{name = "biter-spawner",position = pos}
    
    
-- game.print("测试用1111111111 1286")
--     info.next_wave_time_in_tick = 300
--     info.duration_between_waves = 15
--     info.min_duration_between_waves  = 10
end



local function round_start()
    --calc score
    if global.time_to_start_first_round == false then
        update_score_for_this_round()
    end
    --set map 
    init_map_for_this_round()
    --reset force
    game.forces["player"].reset()
    game.forces["player"].clear_chart(game.surfaces[1])
    --set powerup
    -- if global.time_to_start_first_round == false then  --改 放开这个if，是需要的。
        set_team_powerup()
    -- end

    global.start_time_in_tick_for_this_round = game.tick

    init_creeper()


    --set valid time
    for k,v in pairs(game.players) do
            global.player_valid_time[v.index] = game.tick -36000 
    end

    if global.time_to_start_first_round == false then
        for _,player in pairs(game.connected_players) do
            if not global.player_item_track[player.index] then
                global.player_item_track[player.index] = {}
            end
            if not global.player_item_track[player.index]["firearm-magazine"] then
                global.player_item_track[player.index]["firearm-magazine"] = 15
            else
                if global.player_item_track[player.index]["firearm-magazine"]< 15 then
                    global.player_item_track[player.index]["firearm-magazine"] = 15
                end
            end
        end
    end

    
    if global.time_to_start_first_round == true then
        global.time_to_start_first_round = false
    end

    global.round_info.already_won_this_round = false




    -- --respawn all dead dudes. May have bug
    -- for _,player in pairs(game.connected_players)do
    --     if not player.character then
    --         player.teleport(25-player.position.x,-25-player.position.y)
    --         player.associate_character(
    --             game.surfaces[1].create_entity{name = "player",position = {25,-25}}
    --         )
    --     end
    -- end


end
    
    
--===========================================
--Functions to setup new round are all above.
--Tick seriers are below
--设置新回合的函数在上面
--每一帧都有可能调用的函数都在下面
--============================== 



local function tick_creepers()
    if true == global.round_info.already_won_this_round then
        return 
    end
    
    local info = global.creeper_info  -- for short
    local r = 0
    local surface = game.surfaces[1]
    local width = global.map_size_info.border_width

    local player_to_attack = game.connected_players[math.random(1,#game.connected_players)]
    if player_to_attack then
        for k,v in pairs(global.creeper_info.creepers ) do
            if false == v.valid then
                table.remove(global.creeper_info.creepers,k)
            else
                v.set_command{type = defines.command.attack_area, destination =player_to_attack.position, radius = 50}
            end
        end
    end


    if game.tick>info.next_wave_time_in_tick then


        info.current_wave_number =info.current_wave_number +1

        local wave_number = info.current_wave_number  -- for short
        r = info.duration_between_waves - wave_number*120 -- duration decreaces 2 seconds each wave
        r = math.max(r, info.min_duration_between_waves)
        
        info.next_wave_time_in_tick = game.tick + r

--create creepers

        local t = info.count_for_first_wave +info.count_increace*(wave_number-1)
        t = math.max(t,5)

        local p = 1.5-(1/20)*wave_number
        p = math.clamp(p,0,1)
        local p_small = p

        p = 1.5-(1/40)*wave_number
        p = math.clamp(p,0,1-p_small)
        local p_medium = p

        p = 1.5-(1/60)*wave_number
        p = math.clamp(p,0,1-p_small-p_medium)
        local p_big = p

        p = 1-p_small-p_medium-p_big
        local p_behemoth = p

        local pos ={}
        local width = global.map_size_info.border_width  -- for short
        local melee_percentage = info.percentage_of_melee
        local new_creeper = {}


      

        local t_small = math.floor(t*p_small+0.5)
        for i = 1,t_small do
            if i/t_small<biter_ratio_in_biters_and_spitters then
                pos =surface.find_non_colliding_position("small-biter" ,{width*1.5,width*-1.5}, width*0.5, 2)
                new_creeper = surface.create_entity{name = "small-biter", position = pos}
                table.insert(info.creepers,new_creeper)
            else
                pos =surface.find_non_colliding_position( "small-spitter" ,{width*1.5,width*-1.5},  width*0.5,2)
                new_creeper = surface.create_entity{name = "small-spitter", position = pos}
                table.insert(info.creepers,new_creeper)
            end
        end
        local t_medium = math.floor(t*p_medium+0.5)
        for i = 1,t_medium do
            if i/t_medium<biter_ratio_in_biters_and_spitters then
                pos =surface.find_non_colliding_position("medium-biter" ,  {width*1.5,width*-1.5},  width*0.5, 2)
                new_creeper = surface.create_entity{name = "medium-biter", position = pos}
                table.insert(info.creepers,new_creeper)
            else
                pos =surface.find_non_colliding_position( "medium-spitter", {width*1.5,width*-1.5},  width*0.5,2)
                new_creeper = surface.create_entity{name = "medium-spitter", position = pos}
                table.insert(info.creepers,new_creeper)
            end
        end
        local t_big = math.floor(t*p_big+0.5)
        for i = 1,t_big do
            if i/t_big<biter_ratio_in_biters_and_spitters then
                pos =surface.find_non_colliding_position ("big-biter" , {width*1.5,width*-1.5},  width*0.5,2)
                new_creeper = surface.create_entity{name = "big-biter", position = pos}
                table.insert(info.creepers,new_creeper)
            else
                pos =surface.find_non_colliding_position("big-spitter" , {width*1.5,width*-1.5},  width*0.5, 2)
                new_creeper = surface.create_entity{name = "big-spitter", position = pos}
                table.insert(info.creepers,new_creeper)
            end
        end
        local t_behemoth = math.floor(t*p_behemoth+0.5)
        for i = 1,t_behemoth do
            if i/t_behemoth<biter_ratio_in_biters_and_spitters then
                pos =surface.find_non_colliding_position( "behemoth-biter" , {width*1.5,width*-1.5},  width*0.5,2)
                new_creeper = surface.create_entity{name = "behemoth-biter", position = pos}
                table.insert(info.creepers,new_creeper)
            else
                pos =surface.find_non_colliding_position( "behemoth-spitter" , {width*1.5,width*-1.5}, width*0.5,2)
                new_creeper = surface.create_entity{name = "behemoth-spitter", position = pos}
                table.insert(info.creepers,new_creeper)
            end
        end

        local a_random_number  = (math.random(1,1001)-1)/1000
        if  a_random_number < p_small then
            pos =surface.find_non_colliding_position( "small-worm-turret" , {width*1.5,width*-1.5},  width*0.3,2)
            new_creeper = surface.create_entity{name = "small-worm-turret", position = pos}
        elseif a_random_number < p_medium then
                pos =surface.find_non_colliding_position("medium-worm-turret" , {width*1.5,width*-1.5},  width*0.3,2)
                new_creeper = surface.create_entity{name = "medium-worm-turret", position = pos}
        else
            pos =surface.find_non_colliding_position( "big-worm-turret" , {width*1.5,width*-1.5},  width*0.3,2)
            new_creeper = surface.create_entity{name = "big-worm-turret", position = pos}
        end
    end  --if game.tick>info.next_wave_time_in_tick
end





--====================================================================
--Events!!!!(Callback functions are below. Utility functions are upon)
--游戏的标准callback导到了这里。上面是其他的函数
--===========================================



yagao_idle_factorio.game_init = function()    

--Init this array. Probably you have only one player at this moment and it's yourself.
    for k,v in pairs(game.players) do
        if not global.player_valid_time[v.index] then 
            global.player_valid_time[v.index] = 0 
        end
    end

    global.time_to_start_first_round = true
    global.start_time_in_tick_for_this_round =1
    global.rocket_launched_in_this_round =0


    global.small_creepers_killed_in_this_round=0
    global.midium_creepers_killed_in_this_round=0
    global.big_creepers_killed_in_this_round=0
    global.very_big_creepers_killed_in_this_round=0

    global.score = 0
    global.map_half_size_for_this_round = map_init_size_in_half

    -- game.print("1583  初始分数 3333 调使用")
    round_start()
    
end



yagao_idle_factorio.on_tick = function()
    if game.tick%300 ==0 and game.tick>1 then
--check round endding condition
--检测回合结束的事件
        local round_end=true
        for k,v in pairs(game.connected_players) do
            if global.player_valid_time[v.index]<= game.tick then
                round_end = false
                break
            end
        end
        if round_end then
            round_start()
        end
        
        --creepers
        tick_creepers()








        for _,player in pairs(game.connected_players) do     
            if player.character then      
                if player.character.valid then
                    if not global.player_item_track[player.index] then
                        global.player_item_track[player.index] ={}
                    else
                        local still_have_loot = false
                        --give items to players in this for loop
                        for item_name,item_count in pairs(global.player_item_track[player.index]) do
                            global.player_item_track[player.index][item_name] = item_count - player.insert{name = item_name,count = item_count}
                            if global.player_item_track[player.index][item_name]>0 then
                                still_have_loot = true
                                break
                            else
                                global.player_item_track[player.index][item_name] = nil
                            end
                        end
                        if true == still_have_loot then
                            global.player_still_have_loot[player.index] = true
                        else 
                            global.player_still_have_loot[player.index] = false
                        end
                    end
                end    
            end    
        end   
            



        -- end
    end

    --add up players connected
    if game.tick%1200 and game.tick>1 then
        for _,player in pairs(game.connected_players)do
            local already_there = false
            for _,player_in_temp_list in pairs(global.round_info.players_in_total) do
                if already_there ==player_in_temp_list then
                    already_there = true
                    break
                end
            end
            if false == already_there then
                table.insert(global.round_info.players_in_total,player)
            end
        end
    end

    --refresh UI
    if true == global.round_info.already_won_this_round  and game.tick%59 ==0 and game.tick>1 then
        refresh_game_info_gui_for_all() 
    end




-- game.print("1548    resource score    "..global.init_ore_count_for_this_round)


end



yagao_idle_factorio.on_player_created = function (event)
    local player = game.players[event.player_index]
    -- player.insert{name="iron-plate", count=50}
    player.insert{name="pistol", count=1}--手枪
    player.insert{name="firearm-magazine", count=30}--黄子弹
    -- player.insert{name="burner-mining-drill", count = 5}--热力矿机
    -- player.insert{name="stone-furnace", count = 3}--石炉
    player.force.chart(player.surface, {{player.position.x - 50, player.position.y - 50}, {player.position.x + 50, player.position.y + 50}})


    --init button
    local button_flow =mod_gui.get_button_flow( game.players[event.player_index])
    button_flow.clear()
    button_flow.add{type="button" ,name="button toggle game introduction frame" ,caption={"?"},
        tooltip = {"Help info for this map"}}
    button_flow.add{type="button" ,name="button toggle game info frame" ,caption={"Info"}, tooltip = {""}}
        -- mouse_button_filter ="left"

--init
    if not global.player_valid_time[event.player_index] then 
        global.player_valid_time[event.player_index] = game.tick - 36000
    end
end


yagao_idle_factorio.on_player_respawned = function (event)
    local player = game.players[event.player_index]
    player.insert{name="pistol", count=1}
    player.insert{name="firearm-magazine", count=10}

    local width = global.map_size_info.border_width

    player.teleport(width/3-player.position.x,-width/3-player.position.y)--because the built-in force:set_spawn_position doesn't work at all.
end



yagao_idle_factorio.on_player_died =function (event)
    if not global.player_valid_time[event.player_index] then
        global.player_valid_time[event.player_index] = -36000
    end
        
    --algotithm is like a drag.
    --when a player died for the first time in a period, its valid time is still before this tick, so at least a player could die for once while not being an invalid member to keep the current round.
    local temp = global.player_valid_time[event.player_index]
    if temp <game.tick -36000 then
        temp = game.tick -36000
    end
    temp = temp*0.6 + (game.tick +36000)*0.4
    if temp >game.tick +21600 then
        temp=game.tick +21600
    end
    global.player_valid_time[event.player_index] =temp
end


yagao_idle_factorio.on_built_entity =function (event)
--     created_entity :: LuaEntity
-- player_index :: uint
-- stack :: LuaItemStack
    local entity = event.created_entity

    if entity.name == "radar" then
        local pos = entity.position

        log(pos)
        entity.die(game.forces["enemy"])
        game.print({"In this ver I don't know how to deal with radar, so plz don't use it now."})
        game.surfaces[1].spill_item_stack(pos, {name = "iron-plate",count = 10}, true)
        game.surfaces[1].spill_item_stack(pos, {name = "iron-gear-wheel",count = 5}, true)
        game.surfaces[1].spill_item_stack(pos, {name = "electronic-circuit",count = 5}, true)
        
    end
end





yagao_idle_factorio.on_entity_died =function (event)
      
    --add up creepers to statistics
    if event.entity.name == "small-biter" or event.entity.name == "small-spitter" then
        global.small_creepers_killed_in_this_round=global.small_creepers_killed_in_this_round+1
    end
    if event.entity.name == "midium-biter" or event.entity.name == "midium-spitter" then
        global.midium_creepers_killed_in_this_round=global.midium_creepers_killed_in_this_round+1
    end
    if event.entity.name == "big-biter" or event.entity.name == "big-spitter" then
        global.big_creepers_killed_in_this_round=global.big_creepers_killed_in_this_round+1
    end
    if event.entity.name == "behemoth-biter" or event.entity.name == "behemoth-spitter" then
        global.behemoth_creepers_killed_in_this_round=global.behemoth_creepers_killed_in_this_round+1
    end

--If you kill this biulding of enemy ,you win this round.
    if event.entity.name == "biter-spawner" and event.entity.force == game.forces["enemy"]
        and event.entity.position.x>global.map_size_info.border_width*1.85 then
        global.round_info.already_won_this_round = true
        global.round_info.new_round_start_time_in_tick = game.tick + 90*60

        --enable the corresponding button
        create_game_info_gui_for_all()
    end
end


--========
--UI below
--下面的函数是UI的部分
--==================

local function toggle_game_introduction_gui(event)
    local player = game.players[event.player_index]
    if #player.gui.center.children>0 then
        player.gui.center.clear()
    else
        local this_gui = player.gui.center.add{type = "frame", direction = "vertical"}
        -- ,
            
        --     style = {align = "left",maximal_width = 1500}}


        this_gui.add{type = "label", caption = {"game introduction text map name"}}
        this_gui.add{type = "label", caption = {"game introduction text L1"}}
        this_gui.add{type = "label", caption = {"game introduction text L2"}}
        this_gui.add{type = "label", caption = {"game introduction text author"}}
        this_gui.add{type = "label", caption = {"game introduction text bbs"}}
        this_gui.add{type = "button",  name = "game intro frame close button", caption = {"Close"}}
    end
end

local function create_game_info_gui_for_all() 
    for _,player in pairs(game.players) do
        local event = {player_index = player.index}
        if #player.gui.left.children>0 then
            toggle_game_info_gui(event)
            toggle_game_info_gui(event)
        else
            toggle_game_info_gui(event)
        end
    end
end


local function refresh_game_info_gui_for_all() 
    for _,player in pairs(game.players) do
        local event = {player_index = player.index}
        if #player.gui.left.children>0 then
            toggle_game_info_gui(event)
            toggle_game_info_gui(event)
        else
            toggle_game_info_gui(event)
        end
    end
end

local function toggle_game_info_gui(event)
    local player = game.players[event.player_index]
    if #player.gui.left.children>0 then
        player.gui.left.clear()
    else
        local this_gui = player.gui.left.add{type = "frame", direction = "vertical"}
        
        this_gui.add{type = "label", caption = {"Round",tostring(#global.score_track+1)}}
        if global.player_valid_time[event.player_index] > game.tick then
            this_gui.add{type = "label", caption = {"You died to frequently."}}
            this_gui.add{type = "label", caption = {"Punish time : ",math.floor((game.tick-global.player_valid_time[event.player_index])/60).." second(s)"}}

            local avilable_player_count = 0
            for _,player in pairs(game.connected_players) do
                if  global.player_valid_time[event.player_index] <= game.tick then
                    avilable_player_count =avilable_player_count+1
                end
            end
            this_gui.add{type = "label", caption = {"ddd avilable/all",avilable_player_count.." / "..#game.connected_players.." are(is)not punished"}}
        end

        if global.round_info.already_won_this_round ==true then
            this_gui.add{type = "label", caption = {"rounds end in : ",
                tostring((global.round_info.new_round_start_time_in_tick-game.tick)/60),
                "second(s)"}}
            this_gui.add{type = "label", caption = {"ddd player ready for next round count",
                tostring(#global.round_info.global.round_info.player_had_click_end_round_button),
                "/",
                tostring(#game.connected_players).."player(s) ready for new round"}}
        end
        local this_button =this_gui.add{type = "button",  name = "game info frame - end this round button", 
            caption = {"End this round"},enabled = false}
        if  global.round_info.already_won_this_round == true then 
            this_button.enabled = true
        end
    end
end

local function close_game_intro_gui(event)
    local player = game.players[event.player_index]
    player.gui.center.clear()
end

local function click_button_end_this_round(event)
    local player = game.players[event.player_index]

    local already_in_table = false
    for _, for_player in pairs(global.round_info.player_had_click_end_round_button) do
        if player == for_player then
            already_in_table = true
            break
        end
    end
    if already_in_table == false then
        table.insert(global.round_info.player_had_click_end_round_button,player)
    end

    if #global.round_info.player_had_click_end_round_button> #game.connected_players*(2/3) then
        round_start()
    end
end

yagao_idle_factorio.on_gui_click = function(event)

    -- element :: LuaGuiElement: The clicked element.
    -- player_index :: uint: The player who did the clicking.
    -- button :: defines.mouse_button_type: The mouse button used if any.
    -- alt :: boolean: If alt was pressed.
    -- control :: boolean: If control was pressed.
    -- shift :: boolean: If shift was pressed.
    local button = event.element
    if button.name == "button toggle game introduction frame" then
        toggle_game_introduction_gui(event)
    end
    if button and button.valid then
        if button.name == "button toggle game info frame" then
            toggle_game_info_gui(event)
        end
    end
    if button and button.valid then
        if button.name == "game intro frame close button" then
            close_game_intro_gui(event)
        end
    end
    if button and button.valid then
        if button.name == "game info frame - end this round button" then
            click_button_end_this_round(event)
        end
    end
end
    


return yagao_idle_factorio 