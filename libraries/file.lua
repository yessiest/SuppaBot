--This bot is heavily dependent on file operations, therefore this library exists.
local file = {}
file.safe = true
file.read = function(filename,mode)
  assert(type(filename) == "string","string expected, got "..type(filename))
  local mode = mode or "*a"
  local temp_file,err = io.open(filename,r)
  if err then
    if not file.safe then error(err) else
      ret_string = ""
    end
  else
    ret_string = temp_file:read(mode)
    temp_file:close()
  end
  return ret_string,err
end

file.write = function(filename,write)
  assert(type(filename) == "string", "string expected, got "..type(filename))
  assert(type(write) == "string", "string expected for argument #2, got "..type(write))
  local temp_file,err = io.open(filename,"w+")
  local status = false
  if err then
    if not file.safe then error(err) else
      status = false
    end
  else
    temp_file:write(write)
    temp_file:close()
    status = true
  end
  return status,err
end

file.exists = function(filename)
  local file = io.open(filename,"r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

file.existsDir = function(filename)
  local file = io.open(filename.."/stuff","w")
  if file then
    file:close()
    os.remove(filename.."/stuff")
    return true
  else
    return false
  end
end

file.activate_json = function(jsonlib)
  local json = jsonlib
  file.readJSON = function(filename,default)
    assert(type(filename) == "string","string expected, got "..type(filename))
    local json_data,err = file.read(filename,"*a")
    local table_data, status
    if err then
      if not file.safe then error(err) else
        status = err
        table_data = default or {}
      end
    else
      table_data,_,err = json.decode(json_data)
      if not table_data then
        if not file.safe then error(err) else
          status = err
          table_data = default or {}
        end
      end
    end
    return table_data, status
  end
  file.writeJSON = function(filename,table_data)
    assert(type(filename) == "string","string expected, got "..type(filename))
    assert(type(table_data) == "table","table expected, got "..type(table_data))
    local status = false
    local status,json_object,_,err = pcall(function() return json.encode(table_data) end)
    if not status then
      if not file.safe then error(err) else
        status = false
        err = json_object
      end
    else
      if json_object then
        status,err = file.write(filename,json_object)
      end
    end
    return status, err
  end
end
return file
