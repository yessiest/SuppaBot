local segment = {}
local emulate = require("emulate")({
  client = client,
  discordia = discordia,
})
local file = require("file")
file.activate_json(require("json"))
local guild = client:getGuild(id)
segment.pivots = file.readJSON("./servers/"..id.."/reactions.json",{})
local getEmoji = function(id)
  local emoji = guild:getEmoji(id:match("(%d+)[^%d]*$"))
  if emoji then
    return emoji
  else
    return id
  end
end

local function count(tab)
  local n = 0
  for k,v in pairs(tab) do
    n = n + 1
  end
  return n
end

segment.commands = {
  ["pivot"] = {
    help = {
      title = "Select a pivot message to manipulate",
      description = "Pivot is like a message selector which allows easy reaction manipulations",
      fields = {
        {name = "Usage: ",value = "pivot <message link>"},
        {name = "Perms: ",valeu = "Administartor"}
      }
    },
    args = {
      "messageLink"
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if segment.pivot and count(segment.pivot.buttons) == 0 then
        segment.pivots[segment.pivot.id] = nil
      end
      local message = args[1]
      if not message then
        msg:reply("Couldn't find message with id "..args[2])
        return nil
      end
      if not segment.pivots[message.id] then
        segment.pivots[message.id] = {}
        segment.pivots[message.id].message = message.id
        segment.pivots[message.id].channel = message.channel.id
        segment.pivots[message.id].buttons = {}
        segment.pivots[message.id].id = message.id
      end
      segment.pivot = segment.pivots[message.id]
      msg:reply("Pivot message set to "..message.link)
    end
  },
  ["role-toggle"] = {
    help = {
      title = "Add a simple role switch to the pivot",
      description = "Note: you cannot assign more than one role to a single reaction",
      fields = {
        {name = "Usage: ",value = "role-toggle <emoji> <role ping or role id>"},
        {name = "Perms: ",value = "administrator"}
      }
    },
    args = {
      "string",
      "role",
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return nil
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "role-toggler",
          role = tostring(args[2].id)
        }
        msg:reply("Role toggler added successfully")
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
      end
    end
  },
  ["remove-reaction"] = {
    help = {
      title = "Remove a reaction from a pivot",
      description = "If you don't specify a reaction to remove, the entire pivot for the message is removed automatically",
      fields = {
        {name = "Usage: ",value = "remove-reaction <emoji>"},
        {name = "Perms: ",value = "Administrator"}
      }
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      if args[1] then
        local emoji = getEmoji(args[1])
        message:removeReaction(emoji,client.user.id)
        segment.pivot.buttons[((type(emoji) == "table") and emoji.id) or emoji] = nil
        msg:reply("Action successfully removed")
      else
        message:clearReactions()
        segment.pivots[tostring(message.id)] = nil
        segment.pivot = nil
        msg:reply("Pivot successfully removed")
      end
    end
  },
  ["toggle"] = {
    help = {
      title = "Add a toggle that runs specific commands",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "toggle <emoji> <command-on> <command-off>"},
        {name = "Perms: ",value = "administrator"}
      }
    },
    args = {
      "string",
      "string",
      "string",
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return nil
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "toggler",
          on = args[2],
          off = args[3],
        }
        msg:reply("Toggler added successfully")
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
      end
    end
  },
  ["button"] = {
    help = {
      title = "Add a button that runs specific command when pressed",
      description = "Note: you cannot assign more than one action to a single reaction \n``$user`` gets replaced with the id of the user that interacted with the reaction.",
      fields = {
        {name = "Usage: ",value = "button <emoji> <command>"},
        {name = "Perms: ",value = "administrator"}
      }
    },
    args = {
      "string",
      "string",
    },
    perms = {
      perms = {
        "administrator"
      }
    },
    exec = function(msg,args,opts)
      if not segment.pivot then
        msg:reply("Pivot not selected. Use "..globals.prefix.."pivot to select it and then try again")
        return nil
      end
      local emoji = getEmoji(args[1])
      local channel = guild:getChannel(segment.pivot.channel)
      if not channel then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local message = channel:getMessage(segment.pivot.message)
      if not message then
        msg:reply("Something went horribly wrong, but it's not your fault. This incident has been (hopefully) reported")
        return nil
      end
      local grabEmoji = function(reaction)
        segment.pivot.buttons[tostring(reaction.emojiId or reaction.emojiName)] = {
          type = "button",
          on = args[2],
        }
        msg:reply("Button added successfully")
      end
      message:removeReaction(emoji,client.user.id)
      client:once("reactionAdd",grabEmoji)
      if not message:addReaction(emoji) then
        client:removeListener("reactionAdd",grabEmoji)
        msg:reply("Couldn't add reaction - emoji might be invalid")
      end
    end
  },
}


local buttonOn = function(message,hash,userID)
  if segment.pivots[tostring(message.id)] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[tostring(message.id)]
    if current_pivot.buttons[tostring(hash)] then
      local current_button = current_pivot.buttons[tostring(hash)]
      local new_content
      if current_button.on then
        new_content = current_button.on:gsub("%$user",userID)
      end
      if current_button.type == "role-toggler" then
        guild:getMember(userID):addRole(current_button.role)
      end
      if current_button.type == "toggler" then
        emulate.send(message,{
          delete = function() end,
          content = new_content
        })
      end
      if current_button.type == "button" then
        emulate.send(message,{
          delete = function() end,
          content = new_content
        })
      end
    end
  end
end

local buttonOff = function(message,hash,userID)
  if segment.pivots[tostring(message.id)] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[tostring(message.id)]
    if current_pivot.buttons[tostring(hash)] then
      local current_button = current_pivot.buttons[tostring(hash)]
      local new_content
      if current_button.off then
        new_content = current_button.off:gsub("%$user",userID)
      end
      if current_button.type == "role-toggler" then
        guild:getMember(userID):removeRole(current_button.role)
      end
      if current_button.type == "toggler" then
        emulate.send(message,{
          delete = function() end,
          content = new_content
        })
      end
    end
  end
end

events:on("reactionAdd",function(reaction,userID)
  local message = reaction.message
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  buttonOn(message,hash,userID)
end)

events:on("reactionRemove",function(reaction,userID)
  local message = reaction.message
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  buttonOff(message,hash,userID)
end)

events:on("reactionAddUncached",function(channelId,messageId,hash,userId)
  local message = client:getChannel(channelId):getMessage(messageId)
  local hash = tostring(hash)
  buttonOn(message,hash,userId)
end)

events:on("reactionRemoveUncached",function(channelId,messageId,hash,userId)
  local message = client:getChannel(channelId):getMessage(messageId)
  local hash = tostring(hash)
  buttonOff(message,hash,userId)
end)

events:on("serverSaveConfig",function()
  file.writeJSON("./servers/"..id.."/reactions.json",segment.pivots)
end)

return segment
