local shell = require("shell")
local args, ops = shell.parse(...)

local destdir

if args[1] == nil then
  destdir = "/"
else
  destdir = args[1]
end

shell.execute("mkdir " .. destdir .. "/bin")
shell.execute("mkdir " .. destdir .. "/lib")
shell.execute("mkdir " .. destdir .. "/lib/ocz")

shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/ocz.lua " .. destdir .. "/bin/ocz.lua")
shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/init.lua " .. destdir .. "/lib/ocz/init.lua")
shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/crc32.lua " .. destdir .. "/lib/ocz/crc32.lua")
shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/lualzw.lua " .. destdir .. "/lib/ocz/lualzw.lua")
shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/md5.lua " .. destdir .. "/lib/ocz/md5.lua")
shell.execute("wget https://raw.githubusercontent.com/BallOfEnergy1/OCZ/master/progress.lua " .. destdir .. "/lib/ocz/progress.lua")

return true
