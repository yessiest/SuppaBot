local check = {}
check.msg = function(msg,id,client_id)
  if msg.guild and msg.guild.id == id and msg.author.id ~= client_id then
    return true
  end
end
check.eventArgs = function(id,...)
  args = {...}
  for k,v in pairs(args) do
    if type(v) == "table" and v.guild and v.guild.id == id then
      return true
    elseif not (type(v) == "table") then
      return true
    elseif type(v) == "table" and (not v.guild) and (tostring(v):find("Guild: ")) and v.id == id then
      return true
    elseif type(v) == "table" and (not v.guild) and (v.message) and (v.message.guild.id == id) then
      return true
    else
      return false
    end
  end
  return true
end
return check
