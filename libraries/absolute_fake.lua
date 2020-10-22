--this is a simple and somewhat faulty full fake message generator
return function(client,discordia,author,channel,guild_id,content)
  local guild = client:getGuild(guild_id)
  local fake = {content = content,
    author = client:getUser(author),
    member = guild:getMember(author),
    channel = guild:getChannel(channel),
    client = client,
    guild = guild,
    delete = function() end,
    reply = function(thing,...)
      guild:getChannel(channel):send(...)
    end,
    createdAt = os.time(),
    _parent = guild:getChannel(channel),
    parent = guild:getChannel(channel),
    id = discordia.Date():toSnowflake(),
    attachment = nil,
    attachments = nil,
    cleanContent = content,
    editedTimestamp = nil,
    embed = nil,
    embeds = nil,
    link = "https://http.cat/404",
    mentionedChannels = {},
    mentionedEmojis = {},
    mentionedRoles = {},
    mentionedUsers = {},
    nonce = nil,
    oldContent = {},
    pinned = false,
    reactions = {},
    tts = false,
    type = 0,
    webhookId = nil,
    addReaction = function(...)
    end,
    removeReaction = function(...)
    end,
    emulated = true
  }
  return fake
end
