--[[
the process of checking permissions is split into multiple stages.
hierarchy of permission flags is set up in such a way that would allow commands that are unavailable even to guild owners and administrators
however, this property could only be set up for humans, as to disallow abuse of the commands

some theoretical problems do exist, some of them include:
unknown behaviour for webhooks (crash, probably?)
unability to disallow users/roles from using specific commands
crude design of the permission checking system
]]
local function check_perms(member,guild,channel,perms_check)
  --note: all of the checks below are ignored if the command has a "special" flag.
  --6.1) check if the user is the owner of the guild
  if guild.ownerId == tostring(member.id) then
    return true
  end
  local permissions = member:getPermissions(channel):toTable()
  --6.2) check if the user has administrator permissions
  if permissions.administrator then
    return true
  end
  --6.3) finally, check for matching permissions.
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
  --1) check if the user is bot.
  if message.member.user.bot then
    return false
  end
  --2) check if the message arrived for a proper server handler
  if message.guild and message.guild.id == server.id then
    sandboxing_pass = true
  else
    return false
  end
  --3) check if the command allows every user
  if (not command.perms) or command.perms.any then
    permission_pass = true
  else
    --4) check if the user is allowed to use the command
    if command.perms.users then
      permission_pass = command.perms.users[tostring(message.author.id)]
    end
    --5) check if the user has a role that allows them to use the command
    if (not permission_pass) and command.perms.roles then
      local roles_pass = false
      for k,v in pairs(message.member.roles) do
        if command.perms.roles[v.id] then
          roles_pass = true
        end
      end
      permission_pass = roles_pass
    end
    --6) check if the user has matching permissions and the command doesn't have a "special" property
    if (not permission_pass) and command.perms.perms and (not command.perms.special) then
      permission_pass = check_perms(message.member,message.guild,message.channel,command.perms.perms)
    end
  end
  return (sandboxing_pass and permission_pass)
end
