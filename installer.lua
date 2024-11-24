local shell = require("shell")
local fs = require("filesystem")
local args, ops = shell.parse(...)
local tmpdir = os.tmpname()

local function grab(file)
  shell.execute(string.format("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/refs/heads/OCZ2/ocz2/%s %s", file, "/" .. file))
end

fs.makeDirectory(tmpdir)
grab("lib/crc32.lua")
grab("lib/lualzw.lua")
grab("lib/oczlib.lua")
grab("lib/progress.lua")
grab("bin/ocz.lua")