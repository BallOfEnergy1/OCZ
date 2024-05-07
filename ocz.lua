
local args, ops = require("shell").parse(...)

local ocz_lib = require("ocz")

if args[1] == nil then
  print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
  print("Valid commands:")
  print("  ocz compress")
  print("  ocz decompress")
  print("  ocz zip")
  print("  ocz unzip")
  print("  ocz run")
  print("  ocz help")
  print("  ocz debug")
  print("  ocz setting")
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
      if require("filesystem").isDirectory(args[2]) then
        if not args[3] then
          print("No output directory provided.")
          return true
        end
        print("OCZ Recursive compression")
        print("Ready: ")
        print("Compress directory: '" .. args[2] .. "'.")
        print("Destination directory: '" .. args[3] .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Recursive compression starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result, b, a = ocz_lib.recursiveCompress(args[2], args[3] or args[2])
          if not result then
            print("Recursive compression failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Recursive compression complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
          print("Pre-compressed size: " .. tostring(b/1000) .. "KB")
          print("Post-compressed size: " .. tostring(a/1000) .. "KB")
          print("Compression ratio: " .. string.sub(tostring(b/a), 1, 6))
        else
          print("Canceled.")
          return true
        end
      else
        print("OCZ Compression")
        print("Ready: ")
        print("Compress file: '" .. args[2] .. "'.")
        print("Destination: '" .. (args[3] or args[2]) .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Compression starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result, b, a = ocz_lib.compressFile(args[2], args[3] or args[2])
          if not result then
            print("Compression failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Recursive compression complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
          print("Pre-compressed size: " .. tostring(b/1000) .. "KB")
          print("Post-compressed size: " .. tostring(a/1000) .. "KB")
          print("Compression ratio: " .. string.sub(tostring(b/a), 1, 6))
        else
          print("Canceled.")
          return true
        end
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
      if require("filesystem").isDirectory(args[2]) then
        if not args[3] then
          print("No output directory provided.")
          return true
        end
        print("OCZ Recursive Decompression")
        print("Ready: ")
        print("Decompress directory: '" .. args[2] .. "'.")
        print("Destination directory: '" .. args[3] .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Recursive decompression starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result = ocz_lib.recursiveDecompress(args[2], args[3])
          if not result then
            print("Recursive decompression failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Recursive decompression complete, took (" .. tostring(math.floor(time2-time1)) .. "ms).")
        else
          print("Canceled.")
          return true
        end
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
          local result = ocz_lib.decompressFile(args[2], args[3] or args[2])
          if not result then
            print("Decompression failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Decompression complete, took (" .. tostring(math.floor(time2-time1)) .. "ms).")
        else
          print("Canceled.")
          return true
        end
      end
    end
  elseif type == "zip" then
    if not args[2] then
      print("No directory provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("Directory '" .. args[2] .. "' not found.")
      return true
    else
      if require("filesystem").isDirectory(args[2]) then
        if not args[3] then
          print("No output file provided.")
          return true
        end
        print("OCZ Directory Zipping")
        print("Ready: ")
        print("Compress directory: '" .. args[2] .. "'.")
        print("Destination file: '" .. args[3] .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Zipping starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result = ocz_lib.recursiveZipDirectory(args[2], args[3])
          if not result then
            print("Zipping failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Directory zipping complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
        else
          print("Canceled.")
          return true
        end
      else
        print("Not a directory.")
        return true
      end
    end
  elseif type == "unzip" then
    if not args[2] then
      print("No file provided.")
      return true
    elseif not require("filesystem").exists(args[2]) then
      print("File '" .. args[2] .. "' not found.")
      return true
    else
      if not require("filesystem").isDirectory(args[2]) then
        if not args[3] then
          print("No output directory provided.")
          return true
        end
        print("OCZ Directory Unzipping")
        print("Ready: ")
        print("Compress directory: '" .. args[2] .. "'.")
        print("Destination file: '" .. args[3] .. "'.")
        print("Y to confirm, N to cancel.")
        local user = (ops["a"] and "Y") or io.read()
        if user == "y" or user == "Y" then
          print("Unzipping starting...")
          local time1 = os.time() * (1000/60/60) * 20
          local result = ocz_lib.recursiveUnzipDirectory(args[2], args[3])
          if not result then
            print("Unzipping failed.")
            return true
          end
          local time2 = os.time() * (1000/60/60) * 20
          print("Directory unzipping complete in " .. tostring(math.floor(time2-time1)) .. "ms.")
        else
          print("Canceled.")
          return true
        end
      else
        print("Is directory.")
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
      local user = (ops["a"] and "Y") or io.read()
      if user == "y" or user == "Y" then
        print("Decompression starting...")
        local time1 = os.time() * (1000/60/60) * 20
        ocz_lib.runCompressedFile(args[2])
        local time2 = os.time() * (1000/60/60) * 20
        print("Execution complete, took (" .. tostring(math.floor(time2-time1)) .. "ms).")
      else
        print("Canceled.")
        return true
      end
    end
  elseif type == "help" then
    if not args[2] then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("Valid commands:")
      print("  ocz compress")
      print("  ocz decompress")
      print("  ocz zip")
      print("  ocz unzip")
      print("  ocz run")
      print("  ocz help")
      print("  ocz debug")
      print("Use `ocz help command` to see information on how to use a specific command.")
    elseif args[2] == "compress" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz compress Syntax:")
      print("ocz compress source_file [destination_file] [-a]")
      print("Compresses and the file provided and outputs to a file.")
      print("If `destination_file` is not provided then the file at `source_file` will be overridden with the compressed data.")
      print("Arguments:")
      print("source_file: File to compress.")
      print("destination_file: Location to store data.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
    elseif args[2] == "decompress" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz decompress Syntax:")
      print("ocz decompress source_file [destination_file] [-a]")
      print("Decompresses and the file provided and outputs to a file.")
      print("If `destination_file` is not provided then the file at `source_file` will be overridden with the decompressed data.")
      print("Arguments:")
      print("source_file: File to decompress.")
      print("destination_file: Location to store data.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
    elseif args[2] == "zip" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz zip Syntax:")
      print("ocz compress source_directory destination_file [-a]")
      print("Compresses/zips the directory into `destination_file`")
      print("Arguments:")
      print("source_directory: Directory to compress.")
      print("destination_file: Location to store data.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
    elseif args[2] == "unzip" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz unzip Syntax:")
      print("ocz unzip source_file destination_directory [-a]")
      print("Decompresses/unzips the directory into `destination_directory`")
      print("Arguments:")
      print("source_file: Directory to unzip.")
      print("destination_directory: Location to store data.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
    elseif args[2] == "run" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz run Syntax:")
      print("ocz run source_file [-a]")
      print("Decompresses and directly executes the file provided.")
      print("Arguments:")
      print("source_file: File to decompress then run.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
    elseif args[2] == "debug" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz debug Syntax:")
      print("ocz debug")
      print("Prints debug information about the program.")
    elseif args[2] == "setting" then
      print("OCZ (OCZip) Version: " .. _G.ocz_settings.prog.version)
      print("ocz setting Syntax:")
      print("ocz setting setting_name [value] [-s]")
      print("Arguments:")
      print("source_file: File to decompress.")
      print("destination_file: Location to store data.")
      print("Options:")
      print("-a: Do not ask for user confirmation")
      print("Prints debug information about the program.")
    else
      print("Command not found.")
    end
    return true
  elseif type == "debug" then
    local a = _G.ocz_settings
    local prog = a.prog
    local override = a.override
    print("OCZ (OCZip) Version: " .. prog.version)
    print("Debug information:")
    print("Global table address: " .. tostring(a))
    print("------------------------------")
    print("Program private values: ")
    print("Table address: " .. tostring(prog))
    print("`version`: " .. tostring(prog.version))
    print("`override`: " .. tostring(prog.override))
    print("`check_data`: " .. tostring(prog.check_data))
    print("------------------------------")
    print("Override values: ")
    print("Table address: " .. tostring(override))
    print("`compress`: " .. tostring(override.compress))
    print("`algorithm_version`: " .. tostring(override.algorithm_version))
    print("`use_data_card`: " .. tostring(override.use_data_card))
    print("`checksum`: " .. tostring(override.checksum))
    print("`checksum_type`: " .. tostring(override.checksum_type))
    print("`force_data_card`: " .. tostring(override.force_data_card))
    print("------------------------------")
    print("Program public values:")
    print("`disable_compressed_run`: " .. tostring(a.disable_compressed_run))
    print("`compress`: " .. tostring(a.compress))
    print("`algorithm_version`: " .. tostring(a.algorithm_version))
    print("`use_data_card`: " .. tostring(a.use_data_card))
    print("`checksum`: " .. tostring(a.checksum))
    print("`checksum_type`: " .. tostring(a.checksum_type))
    print("`force_data_card`: " .. tostring(a.force_data_card))
    print("------------------------------")
  elseif type == "setting" then
    if not args[2] then
      print("No setting selected.")
      print("Valid settings:")
      print("  compress")
      print("  algorithm_version")
      print("  use_data_card")
      print("  checksum")
      print("  checksum_type")
      print("  force_data_card")
    else
      if ops["s"] then
        --set
        if not args[3] then
          print("No value provided.")
        else
          print("Changing setting `" .. tostring(args[2]) .. "`")
          print("Original value: " .. tostring(_G.ocz_settings[args[2]]))
          print("New value: " .. tostring(args[3]))
          print("Y to confirm, N to cancel.")
          local user = (ops["a"] and "Y") or io.read()
          if user == "y" or user == "Y" then
            print("Confirmed.")
            ocz_lib.changeSetting(args[2], require("serialization").unserialize(args[3]))
          end
        end
      else
        --read
        local a = _G.ocz_settings[args[2]]
        if a == nil then
          print("Invalid, use `ocz setting` to see valid settings.")
        else
          print(a)
        end
      end
    end
  else
    print("Command not found, use `ocz` to see valid commands.")
  end
end
