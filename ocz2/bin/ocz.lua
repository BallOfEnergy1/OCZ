local args, ops = require("shell").parse(...)

local ocz_lib = require("oczlib")

if args[1] == nil then
  print("OCZ (OCZip) Version: 2.0.4")
  print("Valid commands:")
  print("  ocz compress")
  print("  ocz decompress")
else
  local command = args[1]
  if command == "compress" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      if require("filesystem").isDirectory(args[2]) then
        print("Cannot compress directory, cancelling...")
        --if not args[3] then
        --  print("No output directory provided.")
        --  return true
        --end
        --print("OCZ Recursive compression")
        --print("Ready: ")
        --print("Compress directory: '" .. args[2] .. "'.")
        --print("Destination directory: '" .. args[3] .. "'.")
        --print("Y to confirm, N to cancel.")
        --local user = (ops["a"] and "Y") or io.read()
        --if user == "y" or user == "Y" then
        --  print("Recursive compression starting...")
        --  local time1 = os.time() * (1000/60/60) * 20
        --  local result, b, a = ocz_lib.recursiveCompress(args[2], args[3] or args[2])
        --  if not result then
        --    print("Recursive compression failed.")
        --    return true
        --  end
        --  local time2 = os.time() * (1000/60/60) * 20
        --  print("Recursive compression complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
        --  print("Pre-compressed size: " .. tostring(b/1000) .. "KB")
        --  print("Post-compressed size: " .. tostring(a/1000) .. "KB")
        --  print("Compression ratio: " .. string.sub(tostring(b/a), 1, 6))
        --else
        --  print("Canceled.")
        --  return true
        --end
      else
        local opCheck
        if ops["checksum"] ~= nil then
          opCheck = require("serialization").unserialize(ops["checksum"])
          if type(opCheck) ~= "boolean" then
            print("Invalid operator for `--checksum`.")
            return true
          end
        end
        if ops["type"] ~= nil then
          if (ops["type"] ~= "none" and ops["type"] ~= "lzw" and ops["type"] ~= "card") then
            print("Invalid operator, options for `--type` are 'none', 'lzw', and 'card'.")
            return true
          end
        end
        local opSize
        if ops["block-size"] ~= nil then
          opSize = require("serialization").unserialize(ops["block-size"])
          if type(opSize) ~= "number" then
            print("Invalid operator, `--block-size` requires `number`, got " .. type(opSize) .. ".")
            return true
          end
        end
        print("OCZ Compression")
        print("Ready: ")
        print("Compress file: '" .. args[2] .. "'.")
        print("Destination: '" .. (args[3] or args[2]) .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Compression starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local beforeSize
          if opSize ~= nil then
            beforeSize = oczConfig.maxData
            oczConfig.maxData = opSize
          end
          local typeInt
          if ops["type"] ~= nil then
            if ops["type"] == "none" then
              typeInt = 0
            elseif ops["type"] == "card" then
              typeInt = 1
            elseif ops["type"] == "lzw" then
              typeInt = 2
            end
          end
          local result, b, a = ocz_lib.compressFile(args[2], nil, opCheck, typeInt)
          if beforeSize ~= nil then
            oczConfig.maxData = beforeSize
          end
          if not result then
            print(b)
            return true
          end
          local handle = io.open(args[3] or args[2], "w")
          handle:write(result)
          handle:close()
          local time2 = os.time() * (1000/60/60) * 20
          print("Compression complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
          print("Pre-compressed size: " .. tostring(b/1000) .. "KB")
          print("Post-compressed size: " .. tostring(a/1000) .. "KB")
          print("Compression ratio: " .. string.sub(tostring(a/b), 1, 6))
        else
          print("Canceled.")
          return true
        end
      end
    end
  elseif command == "decompress" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      if require("filesystem").isDirectory(args[2]) then
        print("Cannot decompress directory, cancelling...")
        --if not args[3] then
        --  print("No output directory provided.")
        --  return true
        --end
        --print("OCZ Recursive Decompression")
        --print("Ready: ")
        --print("Decompress directory: '" .. args[2] .. "'.")
        --print("Destination directory: '" .. args[3] .. "'.")
        --print("Y to confirm, N to cancel.")
        --local user = (ops["a"] and "Y") or io.read()
        --if user == "y" or user == "Y" then
        --  print("Recursive decompression starting...")
        --  local time1 = os.time() * (1000/60/60) * 20
        --  local result = ocz_lib.recursiveDecompress(args[2], args[3])
        --  if not result then
        --    print("Recursive decompression failed.")
        --    return true
        --  end
        --  local time2 = os.time() * (1000/60/60) * 20
        --  print("Recursive decompression complete, took (" .. tostring(math.floor(time2-time1)) .. "ms).")
        --else
        --  print("Canceled.")
        --  return true
        --end
      else
        print("OCZ Decompression")
        print("Ready: ")
        print("Decompress file: '" .. args[2] .. "'.")
        print("Destination: '" .. (args[3] or args[2]) .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Decompression starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result, b = ocz_lib.decompressFile(args[2])
          if not result then
            print(b)
            return true
          end
          local handle = io.open(args[3] or args[2], "w")
          handle:write(result)
          handle:close()
          local time2 = os.time() * (1000/60/60) * 20
          print("Decompression complete, took (" .. tostring(math.floor(time2-time1)) .. "ms).")
        else
          print("Canceled.")
          return true
        end
      end
    end
  else
    print("Command not found, use `ocz` to see valid commands.")
  end
end