local check = {}

check.check_file_validation = function(name,sandbox,delete)
  local code_file,err = io.open(name,"r")
  if not err then
    local code = code_file:read("*a")
    code_file:close()
    local chunk,err = load(code,nil,nil,sandbox)
    if not err then
      local validation,err = pcall(chunk)
      if validation then
        local _ = (delete and delete(err))
        return true,nil
      else
        return nil,err
      end
    else
      return nil,err
    end
  else
    return nil,err
  end
end

check.check_file_runtime = function(chunk,sandbox,checking_function,cycles_max,unload_callback)
  local envbox = sandbox
  local err
  envbox.os.glob_time_value = os.time()
  envbox.os.old_time = os.time
  envbox.os.old_date = os.date
  envbox.os.time = function(...)
    if not ({...})[1] then
      envbox.os.glob_time_value = envbox.os.glob_time_value + 1;
      return envbox.os.glob_time_value
    else
      return envbox.os.old_time(...)
    end
  end
  envbox.os.date = function(...)
    return envbox.os.old_date(...,envbox.os.time())
  end
  local code,err = load(chunk,"Sandbox","t",sandbox)
  if not err then
    local valid,err = pcall(code)
    if valid and type(err) == "table" then
      local err = nil
      code = code()
      local cycles = 0
      while cycles < cycles_max do
        status,error_stage_2 = pcall(checking_function,code)
        if (not status) and error_stage_2 then
          err = "Runtime error at cycle "..cycles..": "..error_stage_2
          break
        end
        cycles = cycles + 1
      end
      if err then
        return nil,err
      else
        return true
      end
    else
      if (not valid) and type(err) == "string" then
        return nil,"Runtime error on start: "..err
      else
        return nil,"Chunk is valid, but doesnt return any objects"
      end
    end
  else
    return nil,"Preload error: "..err
  end
end
return check
