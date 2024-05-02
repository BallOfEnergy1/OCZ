
--[[

  To change compression settings, you must set these in your program in the correct format.
  If invalid values are given to the `changeSetting()` function, then the value will not be changed and an error will be logged in the logging directory.
  It is suggested to use the `changeSetting()` function instead of setting the variables directly to ensure that incorrect values are not inserted.
  
  _G.ocz_settings.perm:
    Do not modify this or anything inside of it to avoid breaking the library.
    Contains important global variables for the library to use.
  
  _G.ocz_settings.compression:
    Determines if the library should compress the data at all.
    Does not work without a data card.
  
  _G.ocz_settings.algorithm_version:
    Sets the version of the algorithm to be used;
    0 is no compression, for use in tandem with the `use_data_card` setting;
    1 is inflate/deflate compression;
  
  _G.ocz_settings.use_data_card:
    This setting is to be set to false when a data card is not inserted to keep the program from faulting.
    Errors are caught, but the returns they may give can cause some severe issues. All errors are logged in the logging directory.
    When this setting is set to false, most program features will be disabled due to the difficulty of implementing certain functions into pure lua.
    *Only MD5 checksums will be supported when this is false.*
    
  _G.ocz_settings.checksum:
    This option can be used to enable or disable the checksum for the file.
    Mainly for smaller files that may not need a checksum/increases the size beyond desirable levels.
    
  _G.ocz_settings.checksum_type:
    This setting sets the checksum type to be used (active when _G.ocz_settings.checksum is true), possible options are:
      "MD5"
      "SHA256"
      "CRC32"
    Note: If the `use_data_card` setting is disabled then MD5 will be forcefully used, as it is the only algorithm supported in that mode.
]]--

_G.ocz_settings = {
  prog = {
    override = false,
  },
  compress = true,
  algorithm_version = 1,
  use_data_card = true,
  checksum = true,
  checksum_type = "MD5",
}

local fs = require("filesystem")
local bit32 = require("bit32")

local function log(data, extraError)

end

local function compileSettings()
  --[[
    Settings bit formatting
  
    lowest bit                                                                           highest bit
    1           2 4                   8               16            32 64                128
    0           0 0                   0               0             0  0                 0
    compress    algorithm_version     use_data_card   checksum      checksum_type        unused
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
  --if settings.unused == "unused" then
  -- output = output + 2^7
  --end
  return output
end

local function getSettings(data)
  --[[
    Settings bit formatting

    lowest bit                                                                           highest bit
    1           2 4                   8               16            32 64                128
    0           0 0                   0               0             0  0                 0
    compress    algorithm_version     use_data_card   checksum      checksum_type        unused
  ]]--
  _G.ocz_settings.prog.override = true -- override the current settings in favor of the file being read.
  if bit32.extract(data, 0) == 1 then
    _G.ocz_settings.compress = true
  else
    _G.ocz_settings.compress = false
  end
  _G.ocz_settings.algorithm_version = bit32.extract(data, 1, 2)
  if bit32.extract(data, 3) == 1 then
    _G.ocz_settings.use_data_card = true
  else
    _G.ocz_settings.use_data_card = false
  end
  if bit32.extract(data, 4) == 1 then
    _G.ocz_settings.checksum = true
  else
    _G.ocz_settings.checksum = false
  end
  if bit32.extract(data, 5, 2) == 0 then
    _G.ocz_settings.checksum_type = "MD5"
  elseif bit32.extract(data, 5, 2) == 1 then
    _G.ocz_settings.checksum_type = "SHA256"
  elseif bit32.extract(data, 5, 2) == 2 then
      _G.ocz_settings.checksum_type = "CRC32"
  elseif bit32.extract(data, 5, 2) == 3 then
    _G.ocz_settings.checksum_type = "unused"
  end
end

local lib = {}

function lib.changeSetting(setting, newValue)
  if setting == "compress" then
    local result, error = pcall(assert(type(newValue) == "boolean"))
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.compress = newValue
  elseif setting == "algorithm_version" then
    local result, error = pcall(assert(type(newValue) == "number"))
    if not result then log("Incorrect type for config, expected `number` and got " .. type(newValue), error) end
    _G.ocz_settings.algorithm_version = newValue
  elseif setting == "use_data_card" then
    local result, error = pcall(assert(type(newValue) == "boolean"))
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.use_data_card = newValue
  elseif setting == "checksum" then
    local result, error = pcall(assert(type(newValue) == "boolean"))
    if not result then log("Incorrect type for config, expected `boolean` and got " .. type(newValue), error) end
    _G.ocz_settings.checksum = newValue
  elseif setting == "checksum_type" then
    local result, error = pcall(assert(type(newValue) == "string"))
    if not result then log("Incorrect type for config, expected `string` and got " .. type(newValue), error) end
    _G.ocz_settings.checksum_type = newValue
  end
end

--- Returns the compressed data in a valid file format, returns false if errored.
--- @type function
--- @param data any
--- @return any
function lib.compress(data)
  local settings = _G.ocz_settings
  local output = "OCZFormat-" -- 80 bits/10 bytes (10 chars)
  output = output .. string.char(compileSettings()) -- compile settings into file header
  if not settings.use_data_card then
    -- do not use data card
    if settings.checksum == true then
      local md5 = require("/lib/OCZ_lib/md5.lua")
      output = output .. tostring(md5.sumhexa(data))
    end
    
  else
    -- use data card
    local result, error = pcall(function() return require("component").data end)
    if not result then
      log("Failed during compression: " .. error)
      return false
    else
      output = output .. tostring()
    end
  end
end