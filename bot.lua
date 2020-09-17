package.path = "./libraries/?.lua;./libraries/?/init.lua;"..package.path

discordia = require("discordia")
core = require("core")
file = require("file")
color = require("tty-colors")
validate = require("check-lua")
fake_message = require("fake_message")
rl = require("readline")
client = discordia.Client()
create_logger = require("log")
local servers = {}
local utilities = require("bot_utils")
discordia.uptime = discordia.Date()
--because every good program needs a clock
require("timer").setInterval(1000,function()
  client:emit("clock")
end)

local Server = core.Object:extend()
function Server:initialize(id)
  self.guild = client.guilds[tostring(id)]
  self.plugins = {}
  self.id = id
  self.commands = {}
  self.config = {}
  self.signals = core.Emitter:new()
  self.log = create_logger("./servers/"..id.."/all.log",id)
end

function Server:load_data()
  local id = assert(self.id,"Attempted to load savedata for an unitialized server instance")
  --create server save directory
  if not file.existsDir("./servers/"..id) then
    os.execute("mkdir -p ./servers/"..id)
  end
  self.config = file.readJSON("./servers/"..id.."/config.json",{
    prefix = "/"
  })
end

function Server:save_data()
  local id = assert(self.id,"Attempted to load savedata for an unitialized server instance")
  if not file.existsDir("./servers/"..id) then
    os.execute("mkdir -p ./servers/"..id)
  end
  --trigger save event
  client:emit("serverSaveConfig")
  --config.json is global vairables, safe.json is plugins to load by default
  file.writeJSON("./servers/"..id.."/config.json",self.config)
  local autoload_list = {}
  for k,v in pairs(self.plugins) do
    table.insert(autoload_list,k)
  end
  file.writeJSON("./servers/"..id.."/safe.json",autoload_list)
end

function Server:gather_command_info()
  local plugins,commands = {},{}
  for k,v in pairs(self.plugins) do
    if v.origin then
      local name = k:match("./plugins/(%w+)/init.lua")
      plugins[name] = {}
      for k2,v2 in pairs(v.origin.commands) do
        table.insert(plugins[name],k2)
      end
      plugins[name]["_help"] = v.origin.help
    end
  end
  for k,v in pairs(self.commands) do
    --generate a proxy for commands so that a package could not possibly destroy a command from outside
    commands[k] = utilities.deepcopy(v)
    commands[k].exec = function(...) v.exec(...) end
  end
  return {
    plugins = plugins,
    commands = commands
  }
end

function Server:load_plugin(name)
  if self.plugins[name] then
    self.log("warning","Attempted to load an already loaded plugin: "..name)
    return false,"Plugin is already loaded"
  end
  self.plugins[name] = {}
  --create an environment for our plugin to run in
  self.plugins[name].events = core.Emitter:new()
  local per_package_environment = setmetatable({
    id = self.id,
    globals = self.config,
    signals = self.signals,
    client = client,
    events = self.plugins[name].events,
    plugins = {
      get = function() return self.gather_command_info(self) end,
      load = function(name) return self.load_plugin(self,name) end,
      unload = function(name) return self.unload_plugin(self,name) end,
    },
    discordia = discordia,
    require = require,
    log = self.log
  },{__index = _G})
  --validate package code
  local valid,err = validate.check_file_validation(name,per_package_environment,function(segment)
    if segment and segment.unload then
      segment.unload()
    end
  end)
  for k,v in pairs(utilities.events) do
    self.plugins[name].events:removeAllListeners(v)
  end
  if not valid then
    self.plugins[name] = nil
    self.log("error","Exception while loading plugin "..name..": "..err)
    return false,err
  end
  local chunk,err = file.read(name,"*a")
  --register commands
  self.plugins[name].origin = load(chunk,"Plugin: "..name,"t",per_package_environment)()
  for k,v in pairs(self.plugins[name].origin.commands) do
    if not self.commands[k] then
      self.commands[k] = v
    else
      self.unload_plugin(self,name)
      self.log("error","Collision detected for command "..k.." on plugin "..name)
      return nil,("Collision for command "..k)
    end
  end
  client:emit("commandPoolUpdate",self.guild)
  self.log("info","Plugin loaded: "..name)
  return true,"Plugin loaded successfully"
end

function Server:unload_plugin(name)
  local selected_plugin = self.plugins[name]
  if not selected_plugin then
    self.log("warning","Attempted to unload a plugin that was not loaded: "..name)
    return nil,"Plugin is not loaded"
  end
  if type(selected_plugin.origin.unload) == "function" then
    selected_plugin.origin.unload()
  end
  for k,v in pairs(utilities.events) do
    selected_plugin.events:removeAllListeners(v)
  end
  if selected_plugin.origin.commands then
    for k,v in pairs(selected_plugin.origin.commands) do
      selected_plugin.origin.commands[k] = nil
      self.commands[k] = nil
    end
  end
  self.plugins[name] = nil
  client:emit("commandPoolUpdate",self.guild)
  self.log("info","Plugin unloaded: "..name)
  return true,"Plugin unloaded successfully"
end

function Server:start()
  self.log("INFO","Loading server id "..self.id)
  --well APPARENTLY, FOR SOME FUCKING REASON, calling self's method means passing the metatable instead of the table as an argument
  self.load_data(self)
  local autoload_list = file.readJSON("./servers/"..self.id.."/safe.json",{
    "./plugins/plugins/init.lua","./plugins/help/init.lua"
  })
  for k,v in pairs(autoload_list) do --load previously saved plugins
    self.load_plugin(self,v)
  end
  for k,v in pairs(utilities.events) do
    client:on(v,function(...)
      for kk,vv in pairs(self.plugins) do
        if require("check_partitioning").eventArgs(self.id,...) then
          vv.events:emit(v,...) --propogate events to plugins
        end
      end
    end)
  end
  --handle incoming messages
  client:on("messageCreate",function(msg)
    --check if 1) message arrived on this server, 2) message isnt our own
    if require("check_partitioning").msg(msg,self.id,client.user.id) then
      for k,v in pairs(self.commands) do
        --check if it's the right command; check permission requirements, if provided
        if (msg.content.." "):find(self.config.prefix..k.." ",1,true) == 1 and require("check_perms")(self,v,msg,discordia) then
          --break down the message into arguments and options, match arguments if provided
          local status,args,opts,err = require("air").parse(msg.content:sub((self.config.prefix..k):len()+1,-1),v.args,client,self.id)
          if status then
            self.log("INFO","Executing command "..k)
            self.log("DEBUG","Args: "..table.concat(args,";"))
            print_opts = ""
            for k,v in pairs(opts) do
              print_opts = print_opts..tostring(k)..": "..tostring(v).."\n"
            end
            self.log("DEBUG","Options: "..print_opts)
            v.exec(msg,args,opts)
          else
            msg:reply(err)
          end
        end
      end
    end
  end)
  local server_save_counter = 0
  client:on("messageCreate",function(msg)
    if msg.guild.id == self.id then
      server_save_counter = server_save_counter + 1
      if server_save_counter > 10*((math.floor(msg.guild.totalMemberCount/25))+1) then
        self.log("INFO","Saving server configs")
        self.save_data(self)
        server_save_counter = 0
      end
    end
  end)
  self.log("INFO","Finished loading server id "..self.id)
end

function Server:shutdown()
  self.log("INFO","Removing server object for guild id "..self.id)
  for k,v in pairs(self.plugins) do
    self:unload_plugin(k)
  end
  self.log:close()
  if self.signals.handlers then
    for k,v in pairs(self.signals.handlers) do
      self.signals:removeAllListeners(k)
    end
  end
  self = nil
end

client:on("ready",function()
  local blacklist = file.readJSON("./blacklist.json",{})
  for k,v in pairs(client.guilds) do
    if (blacklist.whitelist_mode and blacklist[v.id]) or (not (blacklist[v.id] or blacklist.whitelist_mode)) then
      os.execute("mkdir -p ./servers/"..v.id)
      servers[v.id] = Server:new(v.id)
      servers[v.id]:start()
      client:emit("serverLoaded",v)
    end
  end
  require("bot_repl")({
    client = client,
    readline = rl,
    discordia = discordia,
    vars = {},
    core = core,
    servers = servers,
    Server = Server
  })
end)

client:on("shutdown",function()
  for k,v in pairs(servers) do
    v:shutdown()
  end
  os.exit()
end)

client:on("guildCreate",function(guild)
  os.execute("mkdir -p ./servers/"..guild.id)
  servers[guild.id] = Server:new(guild.id)
  servers[guild.id]:start()
  client:emit("serverLoaded",guild)
end)

client:on("guildDelete",function(guild)
  if not servers[guild.id] then
    return
  end
  servers[guild.id]:shutdown()
end)

local tempfile = io.open("./token","r")
if not tempfile then
  error(color("./token file does not exist","light red"))
end
local nstr = tempfile:read("*l")
tempfile:close()
client:run('Bot '..nstr)
