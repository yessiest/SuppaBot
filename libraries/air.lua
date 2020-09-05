--rewrite this lib (P.S: done)
--P.S: air stands for Advanced Input Recognition, although technically it's not entirely advanced
air = {}
air.match_strings = function(string)
  local strings = {}
  string = string:gsub("\"(.-[^\\])\"",function(capt)
    string_id = string_id + 1
    strings["%str"..string_id] = capt:gsub("\\\"","\"")
    return " %str"..string_id
  end)
  return string,strings
end

--this table will look up special types
special_case = {
  ["voiceChannel"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
    if tostring(channel):match("^GuildVoiceChannel: ") then
      return true,channel
    else
      return false
    end
  end,
  ["textChannel"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
    if tostring(channel):match("^GuildTextChannel: ") then
      return true,channel
    else
      return false
    end
  end,
  ["messageLink"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local channelId,messageId = id:match("(%d+)/(%d+)[^%d]*$")
    channel = guild:getChannel(channelId)
    if tostring(channel):find("GuildTextChannel") then
      message = channel:getMessage(messageId)
      if message then
        return true,message
      end
    end
    return false
  end,
  ["role"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local role = guild:getRole(id:match("(%d+)[^%d]*$"))
    if role then
      return true,role
    else
      return false
    end
  end,
  ["member"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local member = guild:getMember(id:match("(%d+)[^%d]*$"))
    if member then
      return true,member
    else
      return false
    end
  end,
  ["emoji"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local emoji = guild:getEmoji(id:match("(%d+)[^%d]*$"))
    if emoji then
      return true,emoji
    else
      return false
    end
  end,
  ["ban"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local ban = guild:getBan(id:match("(%d+)[^%d]*$"))
    if ban then
      return true,ban
    else
      return false
    end
  end,
  ["channel"] = function(id,client,guild_id)
    local guild = client:getGuild(guild_id)
    local channel = guild:getChannel(id:match("(%d+)[^%d]*$"))
    if channel then
      return true,channel
    else
      return false
    end
  end,
  ["user"] = function(id,client,guild_id)
    local user = client:getUser(id:match("(%d+)[^%d]*$"))
    if user then
      return true,user
    end
    return false
  end,
  ["id"] = function(id)
    if tonumber(id:match("(%d+)[^%d]*$")) and tostring(id:match("(%d+)[^%d]*$")):len() > 10 then
      return true,id
    end
    return false
  end
}

air.parse = function(string,argmatch,client,guild_id)
  local args,opts = {},{}
  local string_id = 0
  local strings = {}
  string = string:gsub("[%s\n]+\"(.-[^\\])\"",function(capt)
    string_id = string_id + 1
    strings["%str"..string_id] = capt:gsub("\\\"","\"")
    return " %str"..string_id
  end)
  string = string:gsub("[%s\n]+%-%-(%w+)=\"(.-[^\\])\"",function(name,value)
    opts[name] = value:gsub("\\\"","\"")
    return ""
  end)
  string = string:gsub("[%s\n]+%-%-(%w+)=(%S+)",function(name,value)
    opts[name] = value
    return ""
  end)
  string = string:gsub("[%s\n]+%-%-(%w+)",function(name)
    opts[name] = true
    return ""
  end)
  string = string:gsub("[%s\n]+%-(%w+)",function(args)
    args:gsub(".",function(key)
      opts[key] = true
    end)
    return ""
  end)
  string:gsub("([^%s\n]+)",function(match)
    table.insert(args,match)
  end)
  for k,v in pairs(args) do
    if v:match("%%str%d+") then
      if strings[v] then
        args[k] = strings[v]
      end
    end
  end
  if argmatch and #argmatch > 0 then
    local match,err = false
    local new_args = {}
    for k,v in pairs(argmatch) do
      if not args[k] then
        match = false
        err = "Missing arguments: "..table.concat(argmatch,", ",k)
        break
      end
      if v == "number" and tonumber(args[k]) then
        match = true
        new_args[k] = tonumber(args[k])
      elseif v == "string" then
        match = true
        new_args[k] = args[k]
      elseif special_case[v] then
        match,new_args[k] = special_case[v](args[k],client,guild_id)
      else
        match = false
      end
      if match == false then
        err = "Type mismatch for argument "..k..": "..argmatch[k].." expected."
        break
      end
    end
    for k,v in pairs(args) do
      if not new_args[k] then
        new_args[k] = v
      end
    end
    return match,new_args,opts,err
  else
    return true,args,opts
  end
end
return air
