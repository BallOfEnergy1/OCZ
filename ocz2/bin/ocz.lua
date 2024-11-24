local shell = require("shell")
local fs = require("filesystem")
local ocz = require("oczlib")
local args, ops = shell.parse(...)
local blockSize
local method
local mode

-- Compress or decompress
if ops.c and ops.x then
  io.stderr:write("Invalid flags")
elseif ops.c then
  mode = true
elseif ops.x then
  mode = false  
else
  mode = true
end

-- Get block size
if ops["bs"] ~= nil then
  blockSize = ops["bs"]
elseif type(ops["bs"]) == "boolean" then
  blockSize = 8192
else
  blockSize = 8192
end

-- Get compression method
if ops.d and ops.l then
  io.stderr:write("Invalid flags")
  os.exit()
elseif ops.d then
  method = 1
elseif ops.l then
  method = 2
elseif mode then
  method = 1
end
  
-- Compress/decompress
if args[1] == nil or args[2] == nil then
  print("OCZip2 v.2.0.4")
  print("Usage:")
  print("  oz [options] <source> <destination>")
  print("Options:")
  print("  --bs=n  Sets block size for compression.")
  print("  -c      Zip a file (default)")
  print("  -x      UnZip a file")
  print("  -l      Use lzw compression")
  print("  -d      Use inflate/deflate compression (default)")
else
  if mode then
    _G.oczConfig.maxData = blockSize
    local data = ocz.compressFile(shell.resolve(args[1]), nil, true, method)
    local file = io.open(os.getenv("PWD") .. "/" .. args[2], "w")
    file:write(data)
    file:close()
  else
    local data = ocz.decompressFile(shell.resolve(args[1]))
    local file = io.open(os.getenv("PWD") .. "/" .. args[2], "w")
    file:write(data)
    file:close()
  end
end
