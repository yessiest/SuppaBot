--TODO: Add domain-specific manuals, Document
local air = require("air")
local json = require("json")
local file = require("file")
file.activate_json(json)
local segment = {}
segment.setnames = {}
segment.name = "enforcer"
segment.settings = {
  automod = {
    list = {

    },
    status = false,
    warn_limit = 3
  }
}

if globals.enofrcer then
  if globals.enforcer.setnames then
    segment.setnames = globals.enforcer.setnames
  end
  if globals.enforcer.settings then
    segment.settings = global.enforcer.settings
  end
end
segment.warns = file.readJSON("./servers/"..id.."/warns.json",{})

events:on("serverSaveConfig",function()
  if not globals.enforcer then
    globals.enforcer = {}
  end
  globals.enforcer.setnames = segment.setnames
  globals.enforcer.settings = segment.settings
  file.writeJSON("./servers/"..id.."/warns.json",segment.warns)
end)

local warn = function(ID,reason)
  local guild = client:getGuild(id)
  local member = guild:getMember(tostring(ID))
  if not segment.warns[tostring(ID)] then segment.warns[tostring(ID)] = {} end
  table.insert(segment.warns[tostring(ID)],1,reason)
  if segment.settings.warn_limit and (#segment.warns[tostring(ID)] >= segment.settings.warn_limit) and guild:getMember(tostring(ID)) then
    if segment.settings.warn_punishment == "kick" then
      member:kick("Warning quota exceeded.")
    elseif segment.settings.warn_punishment == "ban" then
      member:ban("Warning quota exceeded.",segment.settings.ban_days)
    end
  end
  _ = (client:getUser(tostring(ID)) and client:getUser(tostring(ID)):send("__You have been warned.__\nReason: "..reason))
  signals:emit("warn",function(args)
    if args[1] and member.name:find(args[1],1,true) then
      return true
    elseif not args[1] then
      return true
    else
      return false
    end
  end,{
    user = member.id,
    name = member.name
  })
end

segment.commands = {
  ["change-name"] = {
    help = {embed = {
      title = "Enforce a name upon a specific user",
      description = "Whenever the user attempts to change their name, it will be changed back",
      fields = {
        {name = "Usage: ",value = "change-name <user> <name>"},
        {name = "Perms: ",value = "manageNicknames"}
      }
    }},
    perms = {
      perms = {
        "manageNicknames"
      }
    },
    args = {
      "member",
      "string"
    },
    exec = function(msg,args,opts)
      name = args[2]
      args[1]:setNickname(name)
      segment.setnames[tostring(args[1].id)] = name
      msg:reply("Now assigning an enforced name upon "..args[1].name)
    end
  },
  ["reset-name"] = {
    help = {embed = {
      title = "Stop enforcing a name upon a user",
      description = "Reverses the effect of ``change-name``",
      fields = {
        {name = "Usage: ",value = "reset-name"},
        {name = "Perms: ",value = "manageNicknames"}
      }
    }},
    perms = {
      perms = {
        "manageNicknames"
      }
    },
    args = {
      "member"
    },
    exec = function(msg,args,opts)
      if segment.setnames[tostring(args[1].id)] then
        segment.setnames[tostring(args[1].id)] = nil
        args[1]:setNickname(nil)
        msg:reply("No longer tracking "..args[1].name)
      else
        msg:reply("This user haven't been assigned an enforced name")
      end
    end
  },
  ["wipe"] = {
    help = {embed={
      title = "Wipe user messages",
      description = "Searches and deletes all messages of a specific user in a specified range",
      fields = {
        {name = "Usage: ",value = "wipe-user <range> <user mention or id>"},
        {name = "Perms: ",value = "manageMessages"}
      }
    }},
    perms = {
      perms = {
        "manageMessages"
      }
    },
    args = {
      "number",
    },
    exec = function(msg,args,opts)
      if tonumber(args[1]) and tonumber(args[1]) > 101 then
        msg:reply("Search limit is too high")
        return
      end
      local messages = {}
      msg.channel:getMessages(args[1]):forEach(function(v) messages[#messages+1] = v.id end)
      msg.channel:bulkDelete(messages)
    end
  },
  ["wipe-user"] = {
    help = {embed={
      title = "Wipe user messages",
      description = "Searches and deletes all messages of a specific user in a specified range",
      fields = {
        {name = "Usage: ",value = "wipe-user <range> <user mention or id>"},
        {name = "Perms: ",value = "manageMessages"}
      }
    }},
    perms = {
      perms = {
        "manageMessages"
      }
    },
    args = {
      "number",
      "member"
    },
    exec = function(msg,args,opts)
      if tonumber(args[1]) and tonumber(args[1]) > 101 then
        msg:reply("Search limit is too high")
        return
      end
      local messages = {}
      local target = args[2].user
      msg.channel:getMessages(args[1]):forEach(function(v)
        if v.author.id == target.id then
          messages[#messages+1] = v.id
        end
      end)
      msg.channel:bulkDelete(messages)
    end
  },
  ["wipe-pattern"] = {
    help = {embed={
      title = "Wipe by pattern",
      description = "Searches for a specific pattern in a range of messages, and wipes if certain conditions are met",
      fields = {
        {name = "Usage: ",value = "wipe-pattern <range> <pattern>"},
        {name = "Perms: ",value = "manageMessages"}
      }
    }},
    perms = {
      perms = {
        "manageMessages"
      }
    },
    args = {
      "number",
      "string"
    },
    exec = function(msg,args,opts)
      if tonumber(args[1]) and tonumber(args[1]) > 101 then
        msg:reply("Search limit is too high")
        return
      end
      local messages = {}
      msg.channel:getMessages(args[1]):forEach(function(v)
        if v.content:find(args[2],1,true) then
          messages[#messages+1] = v.id
        end
      end)
      msg.channel:bulkDelete(messages)
    end
  },
  ["kick"] = {
    help = {embed={
      title = "Kick a member",
      description = "Self-descriptive",
      fields = {
        {name = "Usage: ",value = "kick <member> [<reason>]"},
        {name = "Perms: ",value= "kickMembers"}
      }
    }},
    perms = {
      perms = {
        "kickMembers"
      }
    },
    args = {
      "member"
    },
    exec = function(msg,args,opts)
      local member = args[1]
      signals:emit("kick",function(args)
        if args[1] and member.name:find(args[1],1,true) then
          return true
        elseif not args[1] then
          return true
        else
          return false
        end
      end,{
        user = member.id,
        name = member.name,
        reason = args[2]
      })
      member:kick(args[2])
    end
  },
  ["ban"] = {
    help = {embed={
      title = "Ban a member",
      description = "Self-descriptive",
      fields = {
        {name = "Usage: ",value = "ban <member> [<reason> [<days>]]"},
        {name = "Perms: ",value= "banMembers"}
      }
    }},
    perms = {
      perms = {
        "banMembers"
      }
    },
    args = {
      "member"
    },
    exec = function(msg,args,opts)
      local member = args[1]
      signals:emit("kick",function(args)
        if args[1] and member.name:find(args[1],1,true) then
          return true
        elseif not args[1] then
          return true
        else
          return false
        end
      end,{
        user = member.id,
        name = member.name,
        reason = args[2],
        days = args[3]
      })
      member:ban(args[2],tonumber(args[3]))
    end
  },
  ["purge"] = {
    help = {embed={
      title = "Purge bot messages",
      description = "If a number is provided, the bot will search through that amount of messages, or through 100 of them by default",
      fields = {
        {name = "Usage: ",value = "ban <member> [<reason> [<days>]]"},
        {name = "Perms: ",value= "manageMessages"}
      }
    }},
    perms = {
      perms = {
        "manageMessages"
      }
    },
    exec = function(msg,args,opts)
      local messages = {}
      if tonumber(args[1]) and tonumber(args[1]) > 101 then
        msg:reply("Search limit is too high")
        return
      end
      msg.channel:getMessages(tonumber(args[1]) or 100):forEach(function(v)
        if (v.author.id == client.user.id) or (v.content:find(globals.prefix)==1) then
          messages[#messages+1] = v.id
        end
      end)
      msg.channel:bulkDelete(messages)
    end
  },
  ["warn"] = {
    help = {embed={
      title = "Warn a user",
      descriptions = "Warnings by themselves don't do any punishment to the user, but they allow managing users",
      fields = {
        {name = "Usage: ",value = "warn <user> <reason>"},
        {name = "Perms: ",value = "kickMembers"}
      }
    }},
    perms = {
      perms = {
        "kickMembers"
      }
    },
    args = {
      "member",
      "string"
    },
    exec = function(msg,args,opts)
      local reason = table.concat(args," ",2)
      warn(args[1].id,reason)
      msg:reply({embed = {
        title = "User "..args[1].name.." warned",
        description = "Reason: ```"..reason.."```"
      }})
    end
  },
  ["warns"] = {
    help = {embed={
      title = "List warnings",
      descriptions = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "warns <member> [<page>]"},
        {name = "Perms: ",value = "kickMembers"}
      }
    }},
    perms = {
      perms = {
        "kickMembers"
      }
    },
    args = {
      "member",
    },
    exec = function(msg,args,opts)
      local page = (tonumber(args[2]) or 1)-1
      local new_embed = {
        title = "Warnings for "..args[1].name,
        fields = {}
      }
      if page < 0 then
        new_embed.description = "Page "..page.." not found, reverting to first page"
        page = 0
      end
      if segment.warns[tostring(args[1].id)] and #segment.warns[tostring(args[1].id)] > 0 then
        for I = 1+(page*5),5+(page*5) do
          local warn = segment.warns[tostring(args[1].id)][I]
          if warn then
            table.insert(new_embed.fields,{name = "ID: "..tostring(I),value = warn})
          end
        end
        msg:reply({embed = new_embed})
      else
        msg:reply("This user has no warnings")
      end
    end
  },
  ["unwarn"] = {
    help = {embed={
      title = "Revoke a warning issued to a user",
      descriptions = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "unwarn <user> [<warn id>]"},
        {name = "Perms: ",value = "kickMembers"}
      }
    }},
    perms = {
      perms = {
        "kickMembers"
      }
    },
    args = {
      "member",
    },
    exec = function(msg,args,opts)
      local warn_id = (tonumber(args[2]) or 1)
      if segment.warns[tostring(args[1].id)][warn_id] then
        table.remove(segment.warns[tostring(args[1].id)],warn_id)
        msg:reply("Revoked warning #"..warn_id)
      else
        msg:reply("No warning with id "..warn_id)
      end
    end
  },
  ["add-role"] = {
    help = {embed={
      title = "Give some specific user a role",
      descriptions = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "unwarn <member> <role>"},
        {name = "Perms: ",value = "manageRoles"}
      }
    }},
    perms = {
      perms = {
        "manageRoles"
      }
    },
    args = {
      "member",
      "role"
    },
    exec = function(msg,args,opts)
      args[1]:addRole(tostring(args[2].id))
    end
  },
  ["remove-role"] = {
    help = {embed={
      title = "Revoke a role from a user",
      descriptions = "self-descriptive",
      fields = {
        {name = "Usage: ",value = "remove-role <member> <role>"},
        {name = "Perms: ",value = "manageRoles"}
      }
    }},
    perms = {
      perms = {
        "manageRoles"
      }
    },
    args = {
      "member",
      "role"
    },
    exec = function(msg,args,opts)
      args[1]:removeRole(tostring(args[2].id))
    end
  },
}

events:on("memberUpdate",function(member)
  if segment.setnames[tostring(member.id)] and member.nickname ~= segment.setnames[tostring(member.id)] then
    member:setNickname(segment.setnames[tostring(member.id)])
  end
end)

--old automod code
--[[
events:on("messageCreate",function(msg)
  if segment.settings.automod.status then
    local trigger = ""
    for k,v in pairs(segment.settings.automod.list) do
      if msg.content:find(v) and msg.author ~= client.user then
        trigger = trigger..v..","
      end
    end
    if trigger ~= "" then
      full_text,author = msg.content.."",msg.author
      msg:delete()
      msg.author:send("The words \""..trigger.."\" are banned on this server.\nThis is the text that these words were found in: ```"..full_text.."```")
      if segment.settings.automod.punishment == "kick" then
        msg.author:kick("Usage of banned words")
      elseif segment.settings.automod.punishment == "warn" then
        warn(msg.author.id,"Usage of banned words",msg.guild)
      end
    end
  end
end)
]]
return segment
