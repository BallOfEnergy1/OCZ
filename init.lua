_G.ocz_settings = {
  prog = {
    version = "1.0.2",
    override = false,
    file_table = {},
    check_data = function()
      return require("component").isAvailable("data")
    end
  },
  override = {
    compress = nil,
    algorithm_version = nil,
    use_data_card = nil,
    checksum = nil,
    checksum_type = nil,
    force_data_card = nil,
  },
  compress = true,
  algorithm_version = 2,
  use_data_card = true,
  checksum = true,
  checksum_type = "MD5",
  force_data_card = false,
  disable_compressed_run = false,
}

local fs = require("filesystem")
local bit32 = require("bit32")

local function log(data, extraError)
  print("Error!")
  print(data)
  print("Extra information:")
  print(extraError or "None.")
end

local function compileSettings()
  --[[
    Settings bit formatting
  
    lowest bit                                                                           highest bit
    1           2 4                   8               16            32 64                128
    0           0 0                   0               0             0  0                 0
    compress    algorithm_version     use_data_card   checksum      checksum_type        force_data_card
  ]]--
  local settings = _G.ocz_settings
  local output = 0
  if settings.compress then
    output = output + 2^0
  end
  if settings.algorithm_version == 1 then
    output = output + 2^1
  end
  if settings.algorithm_version == 2 then
    output = output + 2^2
  end
  if settings.algorithm_version == 3 then
    output = output + 2^1 + 2^2
  end
  if settings.use_data_card then
    output = output + 2^3
  end
  if settings.checksum then
    output = output + 2^4
  end
  if settings.checksum_type == "SHA256" then
    output = output + 2^5
  end
  if settings.checksum_type == "CRC32" then
    output = output + 2^6
  end
  if settings.checksum_type == "unused" then
    output = output + 2^5 + 2^6
  end
  if settings.force_data_card == true then
   output = output + 2^7
  end
  return output
end

local function loadSettings(data)
  --[[
    Settings bit formatting

    lowest bit                                                                           highest bit
    1           2 4                   8               16            32 64                128
    0           0 0                   0               0             0  0                 0
    compress    algorithm_version     use_data_card   checksum      checksum_type        unused
  ]]--
  _G.ocz_settings.prog.override = true -- override the current settings in favor of the file being read.
  if bit32.extract(data, 0) == 1 then
    _G.ocz_settings.override.compress = true
  else
    _G.ocz_settings.override.compress = false
  end
  _G.ocz_settings.override.algorithm_version = bit32.extract(data, 1, 2)
  if bit32.extract(data, 3) == 1 then
    _G.ocz_settings.override.use_data_card = true
  else
    _G.ocz_settings.override.use_data_card = false
  end
  if bit32.extract(data, 4) == 1 then
    _G.ocz_settings.override.checksum = true
  else
    _G.ocz_settings.override.checksum = false
  end
  if bit32.extract(data, 5, 2) == 0 then
    _G.ocz_settings.override.checksum_type = "MD5"
  elseif bit32.extract(data, 5, 2) == 1 then
    _G.ocz_settings.override.checksum_type = "SHA256"
  elseif bit32.extract(data, 5, 2) == 2 then
      _G.ocz_settings.override.checksum_type = "CRC32"
  elseif bit32.extract(data, 5, 2) == 3 then
    _G.ocz_settings.override.checksum_type = "unused"
  end
  if bit32.extract(data, 7) == 1 then
    _G.ocz_settings.override.force_data_card = true
  else
    _G.ocz_settings.override.force_data_card = false
  end
end

local lib = {}

function lib.changeSetting(setting, newValue)
  if setting == "compress" then
    local result, error = pcall(function() return assert(type(newValue) == "boolean") end)
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.compress = newValue
  elseif setting == "algorithm_version" then
    local result, error = pcall(function() return assert(type(newValue) == "number") end)
    if not result then log("Incorrect type for config, expected `number` and got " .. type(newValue), error) end
    _G.ocz_settings.algorithm_version = newValue
  elseif setting == "use_data_card" then
    local result, error = pcall(function() return assert(type(newValue) == "boolean") end)
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.use_data_card = newValue
  elseif setting == "checksum" then
    local result, error = pcall(function() return assert(type(newValue) == "boolean") end)
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.checksum = newValue
  elseif setting == "checksum_type" then
    local result, error = pcall(function() return assert(type(newValue) == "string") end)
    if not result then log("Incorrect type for config, expected `string` and got " .. type(newValue), error) end
    _G.ocz_settings.checksum_type = newValue
  elseif setting == "disable_compressed_run" then
    local result, error = pcall(function() return assert(type(newValue) == "boolean") end)
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.disable_compressed_run = newValue
  end
end

--- Returns the compressed data in a valid .ocz file format, returns false if failed.
--- @param data any
--- @return any
function lib.compress(data)
  data = tostring(data)
  local settings = _G.ocz_settings
  local output = "OCZFormat-" -- 80 bits/10 bytes (10 chars)
  output = output .. string.char(compileSettings()) -- compile settings into file header
  if not settings.use_data_card then
    -- do not use data card
    if settings.checksum and (settings.checksum_type == "MD5" or settings.checksum_type == "SHA256") then
      local md5 = require("ocz/md5")
      output = output .. tostring(md5.sumhexa(data))
    elseif settings.checksum and settings.checksum_type == "CRC32" then
      local crc = require("ocz/crc32")
      local i, a = 0, ""
      while i < 32 do
        a = require("bit32").extract(crc:Crc32(data), i, math.min(8, 32-i))
        output = string.char(a) .. output
        i = i + 8
      end
    end
    output = output .. data -- no compression :(
    -- skip to `return output`
  else
    -- use data card
    if not _G.ocz_settings.prog.check_data() then
      log("No data card found when attempting to use a data card functionality. Check _G.ocz_settings")
      return false
    else
      local dc = require("component").data
      if settings.checksum == true then
        if settings.checksum_type == "MD5" then
          if _G.ocz_settings.force_data_card then
            output = output .. dc.md5(data)
          else
            local md5 = require("ocz/md5")
            output = output .. tostring(md5.sumhexa(data))
          end
        elseif settings.checksum_type == "SHA256" then
          output = output .. tostring(dc.encode64(dc.sha256(data)))
        elseif settings.checksum_type == "CRC32" then
          if _G.ocz_settings.force_data_card then
            output = output .. dc.crc32(data)
          else
            local crc = require("ocz/crc32")
            local i, a = 0, ""
            while i < 32 do
              a = require("bit32").extract(crc:Crc32(data), i, math.min(8, 32-i))
              output = string.char(a) .. output
              i = i + 8
            end
          end
        end
      end
      if settings.compress then
        if settings.algorithm_version == 1 then -- allow for adding more versions soon
          output = output .. dc.encode64(dc.deflate(data))
        elseif settings.algorithm_version == 2 then
          if _G.ocz_settings.force_data_card then
            output = output .. dc.encode64(dc.deflate(data)) -- use algorithm_version 1
          else
            local lualzw = require("ocz/lualzw")
            output = output .. lualzw.compress(data)
          end
        end
      elseif settings.algorithm_version == 0 or not settings.compress then
        output = output .. data -- AAAAAAAA no compression
      end
    end
  end
  return output
end

--- Returns the decompressed data in a string, returns false if failed.
--- Incorrect checksums will not lead to data being tossed out unless `toss` is true.
--- @param data string
--- @param toss boolean
--- @return string, boolean String contains decompressed data, boolean true if checksum passed.
function lib.decompress(data, toss)
  if data then
    local second = true
    data = tostring(data)
    local a = string.sub(data, 1, 10)
    if not (a == "OCZFormat-") then
      log("Malformed file, `OCZFormat-` header missing at beginning of file.")
      return false
    end
    data = string.sub(data, 11) -- remove format header
    local settings = require("bit32").extract(string.byte(string.sub(data, 1, 1)), 0, 8) -- extract setting bits
    loadSettings(settings) -- load settings from file into override variables
    data = string.sub(data, 2) -- remove setting bits
    if _G.ocz_settings.override.use_data_card
      and not _G.ocz_settings.prog.check_data()
      and (not (_G.ocz_settings.override.algorithm_version == 1)
      or _G.ocz_settings.override.checksum_type == "SHA256") then -- check if a data card must be present to decompress
      log("Unable to decompress, a data card must be present to decompress this file.")
      return "", false
    end
    local dc = require("component").data
    if _G.ocz_settings.override.checksum then
      local checksum = ""
      if _G.ocz_settings.override.checksum_type == "MD5" then
        if _G.ocz_settings.override.force_data_card then
          checksum = tostring(dc.md5(data))
        else
          local md5 = require("ocz/md5")
          checksum = tostring(md5.sumhexa(data))
        end
        if checksum ~= string.sub(data, 32) then
          if toss then
            return "", false
          else
            second = false
            data = string.sub(data, 33)
          end
        end
      elseif _G.ocz_settings.override.checksum_type == "SHA256" then
        checksum = tostring(dc.encode64(dc.sha256(data)))
        if checksum ~= string.sub(data, 32) then
          if toss then
            return "", false
          else
            second = false
            data = string.sub(data, 33)
          end
        end
      elseif _G.ocz_settings.override.checksum_type == "CRC32" then
        if _G.ocz_settings.override.force_data_card then
          checksum = dc.crc32(data)
        else
          local crc = require("ocz/crc32")
          local i, b = 0, ""
          while i < 32 do
            b = require("bit32").extract(crc:Crc32(data), i, math.min(8, 32-i))
            checksum = string.char(b) .. checksum
            i = i + 8
          end
        end
        if checksum ~= string.sub(data, 4) then
          if toss then
            return "", false
          else
            second = false
            data = string.sub(data, 5)
          end
        end
      end--elseif _G.ocz_settings.override.checksum_type == "unused" then
      --soon:tm:
      --end
    end
    local output
    if _G.ocz_settings.override.compress then
      if _G.ocz_settings.override.algorithm_version == 1 then
        output = dc.inflate(dc.decode64(data))
        if output == nil or output == "" then
          log("Warning: Unless you compressed an empty string, something has gone wrong! Data returned after decompressing is `\"\"` or `nil`.")
        end
      elseif _G.ocz_settings.override.algorithm_version == 2 then
        local lualzw = require("ocz/lualzw")
        output = lualzw.decompress(data)
      end
    end
    return output, second
  else
    log("No data to decompress.")
    return "", nil
  end
end

--- Compresses a file and writes contents back to the new location; if nil no data is written.
--- @param filePath string File path of the file to be decompressed.
--- @param newFilePath string|nil File path of the file to write decompressed data to.
--- @return string Compressed data from file.
function lib.compressFile(filePath, newFilePath)
  local before, after = 0, 0
  before = before + fs.size(filePath)
  local readHandle = io.open(filePath, "r")
  local data = readHandle:read("*a")
  local compressedData = lib.compress(data)
  readHandle:close()
  if type(compressedData) ~= "string" then
    return false
  end
  if newFilePath then
    if not fs.exists(newFilePath) then
      local a = newFilePath
      while string.sub(a, -1) ~= "/" do
        a = string.sub(a, 1, #a - 1)
      end
      fs.makeDirectory(a)
    end
    if string.find(newFilePath, ".", 1, true) then
      while string.sub(newFilePath, -1) ~= "." do
        newFilePath = string.sub(newFilePath, 1, #newFilePath - 1)
      end
      newFilePath = string.sub(newFilePath, 1, #newFilePath - 1)
    end
    newFilePath = newFilePath .. ".ocz"
    pcall(fs.remove(newFilePath))
    local writeHandle = io.open(newFilePath, "w")
    writeHandle:write(compressedData)
    writeHandle:close()
    after = after + fs.size(newFilePath)
  end
  after = string.len(compressedData)
  return compressedData, before, after
end

--- Decompresses a file and writes result to `newFilePath`; if nil no data is written.
--- @param filePath string File path of the file to be decompressed.
--- @param newFilePath string|nil File path of the file to write decompressed data to.
--- @return string Decompressed data from file.
function lib.decompressFile(filePath, newFilePath)
  local readHandle = io.open(filePath, "r")
  local compressedData = readHandle:read("*a")
  local data = lib.decompress(compressedData)
  readHandle:close()
  if type(data) ~= "string" then
    return false
  end
  if newFilePath then
    if not fs.exists(newFilePath) then
      local a = newFilePath
      while string.sub(a, -1) ~= "/" do
        a = string.sub(a, 1, #a - 1)
      end
      fs.makeDirectory(a)
    end
    if string.find(newFilePath, ".", 1, true) then
      while string.sub(newFilePath, -1) ~= "." do
        newFilePath = string.sub(newFilePath, 1, #newFilePath - 1)
      end
      newFilePath = string.sub(newFilePath, 1, #newFilePath - 1)
    end
    newFilePath = newFilePath .. ".data"
    pcall(fs.remove(newFilePath))
    local writeHandle = io.open(newFilePath, "w")
    writeHandle:write(data)
    writeHandle:close()
  end
  return data
end

local function getAllFiles(dir)
  local toRecurse = {}
  for file in fs.list(dir) do
    while string.sub(file, -1) == "/" do
      file = string.sub(file, 1, #file - 1)
    end
    if fs.isDirectory(dir .. "/" .. file) then
      if string.sub(dir .. "/" .. file, 1, 4) ~= "/dev" and string.sub(dir .. "/" .. file, 1, 5) ~= "//dev" then -- blacklist /dev from being compressed due to things like /dev/random
        table.insert(toRecurse, file)
      end
    else
      table.insert(_G.ocz_settings.prog.file_table, dir .. "/" .. file)
    end
  end
  if #toRecurse > 0 then
    for _, v in pairs(toRecurse) do
      getAllFiles(dir .. "/" .. v)
    end
  end
  return _G.ocz_settings.prog.file_table
end

--- Compresses files recursively and writes to the new directory.
--- @param directoryPath string Path of the directory to be compressed.
--- @param newDirectoryPath string|nil Path to the directory to output compressed data.
--- @return boolean True if success, false if failed.
function lib.recursiveCompress(directoryPath, newDirectoryPath)
  local before, after = 0, 0
  _G.ocz_settings.prog.file_table = {}
  local files = getAllFiles(directoryPath)
  if not newDirectoryPath then
    return false
  end
  if not fs.exists(newDirectoryPath) or not fs.isDirectory(newDirectoryPath) then
    fs.makeDirectory(newDirectoryPath)
  end
  if fs.isDirectory(directoryPath) then
    for _, v in pairs(files) do
      local _, b, a = lib.compressFile(v, newDirectoryPath .. "/" .. v)
      before = before + b
      after = after + a
    end
  else
    return false
  end
  return true, before, after
end

--- Decompresses files recursively and writes to the new directory.
--- @param directoryPath string Path of the directory to be decompressed.
--- @param newDirectoryPath string|nil Path to the directory to output decompressed data.
--- @return boolean True if success, false if failed.
function lib.recursiveDecompress(directoryPath, newDirectoryPath)
  _G.ocz_settings.prog.file_table = {}
  local files = getAllFiles(directoryPath)
  if not newDirectoryPath then
    return false
  end
  if not fs.exists(newDirectoryPath) or not fs.isDirectory(newDirectoryPath) then
    fs.makeDirectory(newDirectoryPath)
  end
  if fs.isDirectory(directoryPath) then
    for _, v in pairs(files) do
      lib.decompressFile(v, newDirectoryPath .. "/" .. v)
    end
  else
    return false
  end
  return true
end

--- Decompresses a file and directly runs the result; does not check for valid Lua 5.3 code.
--- @param filePath string File path of the file to be executed.
--- @return any Results of the program.
function lib.runCompressedFile(filePath)
  local data = lib.decompressFile(filePath, nil)
  local program, err = load(data) -- uh oh!
  if not program then
    log("Failed to execute: " .. (err or "Unknown"))
    return false
  else
    return program()
  end
end

function lib.recursiveZipDirectory(directoryPath, newFilePath)
  _G.ocz_settings.prog.file_table = {}
  local files = getAllFiles(directoryPath)
  if not directoryPath or not fs.exists(directoryPath) or not fs.isDirectory(directoryPath) then
    return false
  end
  if not newFilePath then
    return false
  end
  local data = ""
  for _, v in pairs(files) do
    data = data .. "OCZ-Start," .. string.sub(v, #directoryPath + 1) .. "HEnd"
    data = data .. lib.compressFile(v, nil)
    data = data .. "OCZ-End"
  end
  data = lib.compress(data)
  if type(data) ~= "string" then
    return false
  end
  pcall(fs.remove(newFilePath))
  local writeHandle = io.open(newFilePath, "w")
  writeHandle:write(data)
  writeHandle:close()
  return true
end

function lib.recursiveUnzipDirectory(filePath, newDirectoryPath)
  local data = lib.decompressFile(filePath, nil)
  while true do
    if string.find(data, "OCZ-Start,", 1, true) then
      local _, b = string.find(data, "OCZ-Start,", 1, true) -- first variable is always 1, if it isn't then we're fucked :fire: :fire:
      local c, d = string.find(data, "HEnd", 1, true)
      local fileFilePath = string.sub(data, b + 1, c - 1)
      data = string.sub(data, d + 1)
      local e, f = string.find(data, "OCZ-End", 1, true)
      if not e or not f then
        log("Invalid sector: " .. tostring(d))
        return false
      end
      local toDecompress = string.sub(data, 1, e-1)
      data = string.sub(data, f + 1)
      --filepath is `fileFilePath`
      --data is `data`
      fileFilePath = newDirectoryPath .. "/" .. fileFilePath
      if not fs.exists(fileFilePath) then
        local a = fileFilePath
        while string.sub(a, -1) ~= "/" do
          a = string.sub(a, 1, #a - 1)
        end
        fs.makeDirectory(a)
      end
      local decompressedData = lib.decompress(toDecompress)
      pcall(fs.remove(fileFilePath))
      local writeHandle = io.open(fileFilePath, "w")
      writeHandle:write(decompressedData)
      writeHandle:close()
    else
      break;
    end
  end
  return true
end

return lib