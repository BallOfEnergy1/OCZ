
local args, ops = require("shell").parse(...)

local ocz_lib = require("ocz-lib")

local function parseTable()

end

if args == {} then
  print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
  print("Valid commands:")
  print("  ocz compress")
  print("  ocz decompress")
  print("  ocz run")
  print("  ocz help")
  print("  ocz debug")
  print("Use `ocz help command` to see information on how to use a specific command.")
  return true
else
  local type = args[1]
  if type == "compress" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      print("OCZ Compression")
      print("Ready: ")
      print("Compress file: '" .. args[2] .. "'.")
      print("Destination: '" .. args[3] or args[2] .. "'.")
      print("Y to confirm, N to cancel.")
      local i = 0
      for _, v in pairs(ops) do
        if v == "a" then
          user = "Y"
        end
        i = i + 1
      end
      if user == "y" or user == "Y" then
        print("Compression starting...")
        local time1 = os.time() * (1000/60/60) * 20
        ocz_lib.compressFile(args[2], args[3] or args[2])
        local time2 = os.time() * (1000/60/60) * 20
        print("Compression complete, took (" .. tostring(time2-time1) .. "s).")
      else
        print("Canceled.")
        return true
      end
    end
  elseif type == "decompress" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      print("OCZ Decompression")
      print("Ready: ")
      print("Decompress file: '" .. args[2] .. "'.")
      print("Destination: '" .. args[3] or args[2] .. "'.")
      print("Y to confirm, N to cancel.")
      local user = io.read()
      if user == "y" or user == "Y" then
        print("Decompression starting...")
        local time1 = os.time() * (1000/60/60) * 20
        ocz_lib.decompressFile(args[2], args[3] or args[2])
        local time2 = os.time() * (1000/60/60) * 20
        print("Decompression complete, took (" .. tostring(time2-time1) .. "s).")
      else
        print("Canceled.")
        return true
      end
    end
  elseif type == "run" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      print("OCZ Decompression/Execution")
      print("Ready: ")
      print("Decompress and Execute file: '" .. args[2] .. "'.")
      print("Y to confirm, N to cancel.")
      local user = io.read()
      if user == "y" or user == "Y" then
        print("Decompression starting...")
        local time1 = os.time() * (1000/60/60) * 20
        ocz_lib.runCompressedFile(args[2])
        local time2 = os.time() * (1000/60/60) * 20
        print("Execution complete, took (" .. tostring(time2-time1) .. "s).")
      else
        print("Canceled.")
        return true
      end
    end
  elseif type == "help" then
    
  elseif type == "debug" then
    
  end
end
