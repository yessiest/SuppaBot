local segment = {}
local guild = client:getGuild(id)
segment.pivots = require("file").readJSON("./servers/"..id.."/reactions.json",{})
local getEmoji = function(id)
  local emoji = guild:getEmoji(id:match("(%d+)[^%d]*$"))
  if emoji then
    return emoji
  else
    return id
  end
end

segment.commands = {
  ["pivot"] = {
    help = {
      title = "Select a pivot message to manipulate",
      description = "Pivot is like a message selector which allows easy reaction manipulations",
      fields = {
        {name = "Usage: ",value = "pivot <message link>"},
        {name = "Perms: ",valeu = "Administarto"}
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
      if segment.pivot and #segment.pivot.buttons == 0 then
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
        segment.pivot.buttons[tostring(reaction.emojiHash)] = {
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
        segment.pivot.buttons[tostring(emoji.hash)] = nil
        msg:reply("Action for "..emoji.name.." successfully removed")
      else
        message:clearReactions()
        segment.pivots[tostring(message.id)] = nil
        segment.pivot = nil
        msg:reply("Pivot successfully removed")
      end
    end
  }

}

events:on("reactionAdd",function(reaction,userID)
  local messageId = tostring(reaction.message.id)
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  if segment.pivots[messageId] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[messageId]
    if current_pivot.buttons[hash] then
      local current_button = current_pivot.buttons[reaction.emojiHash]
      if current_button.type == "role-toggler" then
        guild:getMember(userID):addRole(current_button.role)
      end
    end
  end
end)

events:on("reactionRemove",function(reaction,userID)
  local messageId = tostring(reaction.message.id)
  local hash = tostring(reaction.emojiId or reaction.emojiName)
  if segment.pivots[messageId] and userID ~= client.user.id  then
    local current_pivot = segment.pivots[messageId]
    if current_pivot.buttons[hash] then
      local current_button = current_pivot.buttons[reaction.emojiHash]
      if current_button.type == "role-toggler" then
        guild:getMember(userID):removeRole(current_button.role)
      end
    end
  end
end)

events:on("reactionAddUncached",function(channelId,messageId,hash,userId)
  local messageId = tostring(messageId)
  local hash = tostring(hash)
  if segment.pivots[messageId] and userId ~= client.user.id then
    local current_pivot = segment.pivots[messageId]
    if current_pivot.buttons[hash] then
      local current_button = current_pivot.buttons[hash]
      if current_button.type == "role-toggler" then
        guild:getMember(userId):addRole(current_button.role)
      end
    end
  end
end)

events:on("reactionRemoveUncached",function(channelId,messageId,hash,userId)
  local messageId = tostring(messageId)
  local hash = tostring(hash)
  if segment.pivots[messageId] and userId ~= client.user.id  then
    local current_pivot = segment.pivots[messageId]
    if current_pivot.buttons[hash] then
      local current_button = current_pivot.buttons[hash]
      if current_button.type == "role-toggler" then
        guild:getMember(userId):removeRole(current_button.role)
      end
    end
  end
end)

events:on("serverSaveConfig",function()
  require("file").readJSON("./servers/"..id.."/reactions.json",segment.pivots)
end)

return segment
