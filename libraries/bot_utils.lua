local utilities = {}
utilities.deepcopy = function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utilities.deepcopy(orig_key)] = utilities.deepcopy(orig_value)
        end
        setmetatable(copy, utilities.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
utilities.slice = function(list,start,list_end)
  local output = {}
  for I = (start or 1),(list_end or #table) do
    table.insert(output,list[I])
  end
  return output
end
utilities.shallowcopy = function(orig)
  local copy = {}
  for k,v in pairs(orig) do
    copy[k] = v
  end
  return copy
end
--overwrite the original table's properties with new properties
utilities.overwrite = function(original,overwrite)
  local new = utilities.shallowcopy(original)
  for k,v in pairs(overwrite) do
    new[k] = v
  end
  return new
end
--merge all objects passed as arguments into a table.
--if the object is a table, merge all of it's contents with the table
utilities.merge = function(...)
  local args = {...}
  local new = {}
  for k,v in pairs(args) do
    if type(v) == "table" then
      for k2,v2 in pairs(v) do
        table.insert(new,v2)
      end
    else
       table.insert(new,v)
     end
   end
   return new
end
--a list of all events that can arrive, for convenience
utilities.events = {"clock","ready",
"serverLoaded","serverCommandPoolUpdate",
"serverSaveConfig",
"shardReady","onBotLocalSync",
"onBotReady","onBotLocalSave",
"shardResumed","channelCreate",
"channelUpdate","channelDelete",
"recipientAdd","recipientRemove",
"guildAvailable","guildCreate",
"guildUpdate","guildUnavailable",
"guildDelete","userBan",
"userUnban","emojisUpdate",
"memberJoin","memberLeave",
"memberUpdate","roleCreate",
"roleUpdate","roleDelete",
"messageCreate","messageUpdate",
"messageUpdateUncached","messageDelete",
"messageDeleteUncached","reactionAdd",
"reactionAddUncached","reactionRemove",
"reactionRemoveUncached","pinsUpdate",
"presenceUpdate","relationshipUpdate",
"relationshipAdd","relationshipRemove",
"typingStart","userUpdate",
"voiceConnect","voiceDisconnect",
"voiceUpdate","voiceChannelJoin",
"voiceChannelLeave","webhooksUpdate","debug",
"info","error","heartbeat","raw"}

utilities.unixToString = function(sec)
  local hours = math.floor(sec/3600)
  local minutes = math.floor((sec - hours*3600)/60)
  local seconds = sec - (hours*3600) - (minutes*60)
  hours = ((hours < 10) and ("0"..hours)) or hours
  minutes = ((minutes < 10) and ("0"..minutes)) or minutes
  seconds = ((seconds < 10) and ("0"..seconds)) or seconds
  return ((tonumber(hours) > 0 and hours..":") or "")..minutes..":"..seconds
end
return utilities
