local yagao_debug_tools = {}

function yagao_debug_tools.print_table(input_table)
  for k,v in pairs(input_table) do
    game.print(k.."  ------  "..type(v))
  end  
end
-- yagao_debug_tools["print_debug_info"] = print_debug_info


function yagao_debug_tools.check()
  game.print("This is yagaodirac's debug tool")
end
-- yagao_debug_tools["check"]=check

return yagao_debug_tools