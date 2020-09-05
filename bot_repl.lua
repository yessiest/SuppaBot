local function start_repl(env)
  local readline = env.readline
  local client = env.client
  env["help"] = function()
    print("There is no help for the damned")
  end
  print("Welcome to "..client.user.username.." repl")
  local function read()
    readline.readLine("[discord]: ",function(status,message)
      local chunk,err
      if type(message) ~= "string" then
        client:emit("shutdown")
      else
        chunk,err = load(message,"Client","t",setmetatable(env,{__index = _G}))
      end
      if chunk then
        status,msg = pcall(chunk)
        if not status then
          print("[REPL runtime warning] "..tostring(msg))
        end
      elseif err then
        print("[REPL compile warning] "..tostring(err))
      end
      read()
    end)
  end
  read()
end
return start_repl
