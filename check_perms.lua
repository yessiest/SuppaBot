local function check_perms(member,guild,channel,perms_check)
  if guild.ownerId == tostring(member.id) then
    return true
  end
  local permissions = member:getPermissions(channel):toTable()
  if permissions.administrator and (not perms_check.special) then
    return true
  end
  local output = true
  for k,v in pairs(perms_check) do
    if not permissions[v] then
      output = false
    end
  end
  return output
end

return function(server,command,message,discordia)
  local sandboxing_pass,permission_pass

  if message.guild and message.guild.id == server.id then
    sandboxing_pass = true
  else
    return false
  end
  if (not command.perms) or command.perms.any then
    permission_pass = true
  else
    if command.perms.users then
      permission_pass = command.perms.users[tostring(message.author.id)]
    end
    if (not permission_pass) and command.perms.roles then
      local roles_pass = false
      for k,v in pairs(message.member.roles) do
        if command.perms.roles[v.id] then
          roles_pass = true
        end
      end
      permission_pass = roles_pass
    end
    if (not permission_pass) and command.perms.perms then
      permission_pass = check_perms(message.member,message.guild,message.channel,command.perms.perms)
    end
  end
  return (sandboxing_pass and permission_pass)
end
