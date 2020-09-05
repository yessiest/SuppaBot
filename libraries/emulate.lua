--i do believe this is a mug moment, for we cannot pass the require function of luvit's core through require itself
return function(args)
  --all of this wrapped into a function to pass objects that we cannot pass using normal methods
  assert(type(args) == "table", "No environment provided")
  local requesites = {
    client = true,
    discordia = true,
  }
  for k,v in pairs(requesites) do
    if not args[k] then
      error("Module "..k.." not found, aborting")
    end
  end
  return {
    send = function(message,overrides)
      local fake = require("fake_message")(message,overrides)
      args.client:emit("messageCreate",fake)
    end,
    sendAwait = function(message,overrides)
      args.client:once("EmulationResult",function(message,reply)
        emulation_output = reply
      end)
      overrides.reply = function(...)
        args.client:emit("EmulationResult",...)
      end
      overrides.delete = function() end
      local fake = require("fake_message")(message,overrides)
      args.client:emit("messageCreate",fake)
      local start = os.time()
      while os.time() < start+2 and not emulation_output do

      end
      return emulation_output
    end,
    generateEnv = function(commands,server)
      --envs table will take care of collision between environments
      args.discordia.commandEnvironments = args.discordia.commandEnvironments or {}
      local envs = args.discordia.commandEnvironments
      local id = math.random(10000,99999)
      while envs[id] do
        math.random(10000,99999)
      end
      envs[id] = true
      --this will emulate bot behavior for commands in the new environment
      local checking_callback = function(message,envId)
        if require("check_partitioning").msg(message,server.id,args.client.user.id) and (envId == id) then
          for k,v in pairs(commands) do
            if (message.content.." "):find(server.config.prefix..k.." ",1,true) == 1 and require("check_perms")(server,v,message,args.discordia) then
              local status,args,opts,err = require("air").parse(message.content:gsub(server.config.prefix..k,"",1),v.args)
              if status then
                v.exec(message,args,opts)
              else
                message:reply(err)
              end
            end
          end
        end
      end
      --and this will act as an interface to our new environment
      local new_emulation_environment = {
        send = function(message,overrides)
          local fake = require("fake_message")(message,overrides)
          args.client:emit("envEmulate",fake,id)
        end,
        sendAwait = function(message,overrides)
          args.client:once("EmulationResult",function(message,reply)
            emulation_output = reply
          end)
          overrides.reply = function(...)
            args.client:emit("EmulationResult",...)
          end
          overrides.delete = function() end
          local fake = require("fake_message")(message,overrides)
          args.client:emit("envEmulate",fake,id)
          local start = os.time()
          while os.time() < start+2 and not emulation_output do

          end
          return emulation_output
        end,
        sendAwaitNoOutput = function(message, overrides)
          args.client:once("EmulationResult",function(message,reply)
            emulation_output = true
          end)
          overrides.reply = function(message,content)
            args.client:emit("EmulationResult")
            message:reply(content)
          end
          overrides.delete = function() end
          local fake = require("fake_message")(message,overrides)
          args.client:emit("envEmulate",fake,id)
          local start = os.time()
          while os.time() < start+2 and not emulation_output do

          end
          return emulation_output
        end,
        destroy = function()
          args.client:removeListener("envEmulate",checking_callback) --destroy the callback
          envs[id] = nil
        end
      }
      args.client:on("envEmulate",checking_callback)
      return new_emulation_environment
    end
  }
end
