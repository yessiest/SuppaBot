return function(message,overrides)
  assert(type(message) == "table","table expected, got "..type(message))
  assert(type(overrides) == "table","table expected for arg#2, got "..type(overrides))
  local fake = {content = message.content,
    author = message.author,
    member = message.guild:getMember(message.author.id),
    channel = message.channel,
    client = message.client,
    guild = message.guild,
    delete = function() message:delete() end,
    reply = function(thing,...)
      message.channel:send(...)
    end,
    createdAt = message.createdAt,
    _parent = message.parent,
    parent = message.parent,
    id = message.id,
    attachment = message.attachment,
    attachments = message.attachments,
    cleanContent = message.cleanContent,
    editedTimestamp = message.editedTimestamp,
    embed = message.embed,
    embeds = message.embeds,
    link = message.link,
    mentionedChannels = message.mentionedChannels,
    mentionedEmojis = message.mentionedEmojis,
    mentionedRoles = message.mentionedRoles,
    mentionedUsers = message.mentionedUsers,
    nonce = message.nonce,
    oldContent = message.oldContent,
    pinned = message.pinned,
    reactions = message.reactions,
    tts = message.tts,
    type = message.type,
    webhookId = message.webhookId,
    addReaction = function(...)
      message:reactionAdd(...)
    end,
    removeReaction = function(...)
      message:reactionRemove(...)
    end,
    emulated = true
  }
  for k,v in pairs(overrides) do
    fake[k] = v
  end
  return fake
end
