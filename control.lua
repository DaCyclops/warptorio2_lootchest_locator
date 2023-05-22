local util = require('util')

-- debug functions
function PrintDebug(text)
  -- change this to true if you want debug info
  if (false) then 
    game.print(text, {0.3, 0.3, 0.2, 0.5} )
  end
end

function lcl_on_config_changed(data)
  if data.mod_changes ~= nil and data.mod_changes["warptorio2_lootchest_locator"] ~= nil and data.mod_changes["warptorio2_lootchest_locator"].old_version == nil then
    -- Mod added 

    --Locate chests on mod added
    -- Checks all surfaces
    game.print('Locating all Loot Chests...', settings.global["WarpLCL-Chat-Color"].value)
    --game.print('(this may take a moment)', settings.global["WarpLCL-Chat-Color"].value)
    for _, surf in pairs(game.surfaces) do
      lcl_remap_all_markers(surf)
    end
    game.print('...done')

  end 

end
script.on_configuration_changed(lcl_on_config_changed)

function lcl_runtime_mod_settings_changed(event)
  if (event.setting == "WarpLCL-Marker-ChunkMode") then 
    --Chunkmode was changed. Do a remap...
    -- Checks all surfaces
    game.print('Marker on Chunk-Position changed.', settings.global["WarpLCL-Chat-Color"].value)
    game.print('Remapping all Loot Chests...', settings.global["WarpLCL-Chat-Color"].value)
    --game.print('(this may take a moment)', settings.global["WarpLCL-Chat-Color"].value)
    PrintDebug(settings.global["WarpLCL-Marker-ChunkMode"].value)
    for _, surf in pairs(game.surfaces) do
      -- Force the Chunk Mode, because it needs it?.
      PrintDebug('doing for ' .. surf.name)
      lcl_remap_all_markers(surf)
    end
    game.print('...done')
  end
end
script.on_event(defines.events.on_runtime_mod_setting_changed, lcl_runtime_mod_settings_changed)


script.on_init(function()
  --Nothing to Do Now 
 --PrintDebugt('TEST init', {0.5, 0, 0, 0.5} )
end)   
  
script.on_load(function()
  --Nothing to Do Now  
  --PrintDebug('TEST load', {0.5, 0, 0, 0.5} )
end)
-- End OnLoad/OnInit/OnConfig events




-- Support functions
function lcl_check_for_tags(pos, surf, chunkmode)
  chunkmode = chunkmode or false
  local foundtags = nil
  local checkarea = {left_top={x=pos.x-0.1,y=pos.y-0.1},right_bottom={x=pos.x+0.1,y=pos.y+0.1}}
  if (chunkmode) then 
    checkarea = {left_top={x=pos.x-16,y=pos.y-16},right_bottom={x=pos.x+16,y=pos.y+16}}
  end
  local tags = game.forces["player"].find_chart_tags(surf,checkarea)
  for _, tag in ipairs(tags) do
    --Check if Warpchest Icon
    if (tag.icon) then 
      if (tag.icon.name == 'signal-warpchest-found') then
        -- Uses my icon, must be an proper tag here.
        if (foundtags == nil) then 
          foundtags = {}
        end
        table.insert(foundtags, tag)
        PrintDebug('tag check positive')
      end
    end
  end
  return foundtags
  
end

function lcl_perform_chunk_scan(event)
  -- Check for loot chests
  chests = game.surfaces[event.surface_index].find_entities_filtered{area = event.area, name = "warptorio-lootchest"} 
  for _, ent in ipairs(chests) do
    PrintDebug('LCL Seen at ' .. ent.position.x .. ',' .. ent.position.y .. ' on ' .. ent.surface.name)
    lcl_handle_found_chest(ent)
  end
end
script.on_event(defines.events.on_chunk_charted, lcl_perform_chunk_scan)

function lcl_handle_found_chest(ent,silentMode)
  silentMode = silentMode or false
  chunkMode = settings.global["WarpLCL-Marker-ChunkMode"].value
  if (silentMode) then 
    notifyChat = false
  else 
    notifyChat = settings.global["WarpLCL-Chat-Message"].value
  end
  -- Set position aside so we can change it if ChunkMode
  local pos = ent.position
  -- player or radar sees it, has it already been tagged?.    
  if (chunkMode) then
    -- Chunk-Posistion mode. Move to middle of chunk from event area
    pos = {x=(math.floor(pos.x/32)*32) + 16,y=(math.floor(pos.y/32)*32) + 16}
  end
  local tags = lcl_check_for_tags(pos, ent.surface, chunkMode)
  if (tags == nil) then
    --tag it now
    PrintDebug('LCL Tagged at ' .. ent.position.x .. ',' .. ent.position.y .. ' on ' .. ent.surface.name)
    local resultTag = game.forces["player"].add_chart_tag(ent.surface,{position=pos,text=settings.global["WarpLCL-Marker-Text"].value,icon={type='virtual',name='signal-warpchest-found'}})
    if (notifyChat) then
      game.print('Warp Loot Chest Detected', settings.global["WarpLCL-Chat-Color"].value)
    end
    
    
  end
end


function lcl_handle_removed_chest(event)
  local ent = event.entity
  local pos = ent.position

  if (ent.name == 'warptorio-lootchest') then
    if (settings.global["WarpLCL-Marker-ChunkMode"].value) then
      -- Chunk-Posistion mode. 
      -- reverse engineer Middle of chunk
      pos = {x=(math.floor(pos.x/32)*32) + 16,y=(math.floor(pos.y/32)*32) + 16}
    end
    PrintDebug('warplootchest removed at ' .. ent.position.x .. ',' .. ent.position.y .. ' on ' .. ent.surface.name)
    -- check if tag
    tags = lcl_check_for_tags(pos, event.entity.surface, settings.global["WarpLCL-Marker-ChunkMode"].value)
    -- remove tags
    if (tags) then
    for _, tag in ipairs(tags) do
      PrintDebug('tag removing at ' .. tag.position.x .. ',' .. tag.position.y .. ' on ' .. tag.surface.name)
      tag.destroy()
    end
    end

  end
end
script.on_event(defines.events.on_player_mined_entity, lcl_handle_removed_chest)
script.on_event(defines.events.on_robot_mined_entity, lcl_handle_removed_chest)
script.on_event(defines.events.on_entity_died, lcl_handle_removed_chest)


function lcl_remap_all_markers(surface)
  -- Remove all WarpChest markers on surface
  PrintDebug('finding all tags on ' .. surface.name)
  local tags = game.forces["player"].find_chart_tags(surface)
  
  for itag, tag in ipairs(tags) do
    --Check if Warpchest Icon
    if (tag.icon) then 
      if (tag.icon.name == 'signal-warpchest-found') then
        -- Uses my icon, must be an proper tag here.
        PrintDebug('tag '.. itag ..' cleared at ' .. tag.position.x .. ',' .. tag.position.y .. ' on ' .. tag.surface.name)
        tag.destroy()
      end
    end
  end
  -- Find all known markers
  chests = surface.find_entities_filtered{name = "warptorio-lootchest"}
  -- Try to map them (happy to fail if uncharted)
  for ichest, chest in ipairs (chests) do 
    PrintDebug('LCL '.. ichest ..' found at ' .. chest.position.x .. ',' .. chest.position.y .. ' on ' .. chest.surface.name)
    lcl_handle_found_chest(chest, true)
  end

end


-- /lcl command

function lcl_command_process(event)
  local player = game.players[event.player_index]
  local args = util.split_whitespace(event.parameter)
  if #args == 0 then
    player.print({'command.lcl.help1'})
    player.print({'command.lcl.help2'})
    player.print({'command.lcl.help3'})
  elseif args[1] == 'remark' then
    game.print('Re-Marking All Warp Loot Chests...', settings.global["WarpLCL-Chat-Color"].value)
    lcl_remap_all_markers(player.surface)
    game.print('...done')
  elseif args[1] == 'help' then
    player.print({'command.lcl.help1'})
    player.print({'command.lcl.help2'})
    player.print({'command.lcl.help3'})
  else
    player.print({'command.lcl.help-bad', args[1]})
    player.print({'command.lcl.help2'})
    player.print({'command.lcl.help3'})
  end
end

commands.add_command(
  'lcl',
  {'command.lcl.help'},
  lcl_command_process
)

