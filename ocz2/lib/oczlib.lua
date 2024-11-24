local crc32 = require("crc32")
local bit32 = require("bit32")
local lualzw = require("lualzw")
local component = require("component")

_G.oczConfig = {
  maxData = 8192 -- Default max minus 1.
}

local function createChecksum(data)
  local crc = crc32.Crc32(data)
  local temp = ""
  local b = 255 -- 11111111
  local c = 0
  repeat
    temp = temp .. string.char(bit32.rshift(bit32.band(crc, b), (c * 8)))
    b = bit32.lshift(b, 8) -- Shift 8 bits over to grab next byte.
    c = c + 1
  until c > 3 -- When it's at the end.
  return temp
end

local function checkChecksum(checksum, data)
  if(checksum ~= createChecksum(data)) then
    return false
  else
    return true
  end
end

local function createHeader(customValue, compressionType, checksum)
  assert(customValue < 15, "User defined flags cannot be >15.")
  assert(compressionType < 8, "`compressionType` cannot be >7.")
  local header = "OCZ2"
  local dataByte = customValue -- User defined flags
  dataByte = dataByte + bit32.lshift(compressionType, 4) -- Compression type.
  if checksum then
    dataByte = dataByte + bit32.lshift(1, 7) -- Checksum
  end
  header = header .. string.char(dataByte)
  return header
end

local function parseHeader(header)
  if header:sub(0, 4) ~= "OCZ2" then
    return nil, "Malformed content, could not read."
  end
  header = header:sub(5)
  local options = {}
  options[1] = bit32.band(header:byte(), 15)  -- 11110000 User flags
  options[2] = bit32.rshift(bit32.band(header:byte(), 112), 4)  -- 00001110 Compression
  options[3] = bit32.rshift(bit32.band(header:byte(), 128), 7)  -- 00000001 Checksum
  return options
end

local function compress(data, customValue, checksum, type)
  local header = ""
  local compressedContent = ""
  if customValue == nil then
    customValue = 0
  end
  if type == nil then -- Default
    if component.isAvailable("data") then
      type = 1
    else
      type = 2
    end
  elseif not component.isAvailable("data") and type == 1 then
    return nil, "Could not compress, no data card found."
  end
  if checksum == nil then
    checksum = true
  end
  header = header .. createHeader(customValue, type, checksum)
  if type == 0 then
    compressedContent = compressedContent .. data
  elseif type == 1 or type == 2 then
    while data ~= "" do
      local compressedData
      if type == 1 then
        compressedData = component.data.deflate(data:sub(0, oczConfig.maxData))
        if(compressedData == nil) then
          os.sleep(0.05)  -- attempt throttle
          compressedData = component.data.deflate(data:sub(0, oczConfig.maxData))
        end
        if compressedData == nil then -- most likely due to either huge block size or using more energy than the computer can process per operation.
          return nil, "Compression failed, try lowering max block size or giving the computer more energy."
        end
      else
        compressedData = lualzw.compress(data:sub(0, oczConfig.maxData))
      end
      compressedContent = compressedContent .. #compressedData .. ";" .. compressedData
      data = data:sub(oczConfig.maxData)
    end
  end
  if checksum then
    header = header .. createChecksum(compressedContent)
  end
  return header .. compressedContent
end

local function decompress(data)
  local options, error = parseHeader(data:sub(0, 5))
  if not options then
    return nil, error
  end
  data = data:sub(6)
  if options[3] == 1 then
    local result = checkChecksum(data:sub(0, 4), data:sub(5))
    if not result then
      return nil, "Checksum does not match, the data is likely corrupted."
    end
  end
  data = data:sub(5)
  if options[2] == 0 then
    return data
  elseif options[2] == 1 or options[2] == 2 then
    local decompressedData = ""
    repeat
      local len = ""
      if data:sub(0, 1) == "" then
        break;
      end
      while data:sub(0, 1) ~= ";" do
        len = len .. data:sub(0, 1)
        data = data:sub(2)
      end
      data = data:sub(2)
      len = tonumber(len)
      local toDecompress = data:sub(0, len)
      data = data:sub(len + 1)
      if options[2] == 1 then
        decompressedData = decompressedData .. component.data.inflate(toDecompress)
      else
        decompressedData = decompressedData .. lualzw.decompress(data)
      end
    until toDecompress == ""
    return decompressedData, options[1]
  end
end

local function compressFile(filePath, customValue, checksum, type)
  local file = io.open(filePath, "rb")
  local content = file:read("*a")
  file:close()
  local compressed, error = compress(content, customValue, checksum, type)
  if compressed == nil then
    return nil, error
  end
  return compressed, #content, #compressed
end

local function decompressFile(filePath)
  local file = io.open(filePath, "rb")
  local content = file:read("*a")
  file:close()
  return decompress(content)
end

local function runCompressedFile(filePath)
  local decompressedFile, error = decompressFile(filePath)
  if not decompressedFile then
    return nil, error
  end
  local func, err = load(decompressedFile)
  if not func then
    return nil, "Execution failed with reason: " .. err
  else
    return func()
  end
end

return {
  compress = compress,
  decompress = decompress,
  compressFile = compressFile,
  decompressFile = decompressFile,
  runCompressed = runCompressedFile
}