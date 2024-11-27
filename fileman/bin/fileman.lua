--[[
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
]]--

local event = require("event")
local component = require("component")
local thread = require("thread")
local gpu = component.gpu
local computer = require("computer")
local term = require("term")
local progress = require("progress")
local fs = require("filesystem")
local unicode = require("unicode")
local slaxml = require("slaxdom")
local keyboard = require("keyboard")

local isErrored = false
local isPopupShown = false
local popupShown = "None"
local entries = {}
local selected = {}

local canScroll = false

local currentScrollMain = 0
local currentScrollPreview = 0

local sizeSort = false
local reverseSort = false

local sideBarChanged = true

local themes = {
  default = {
    isValid = true
  },
  dark = {
    isValid = true
  },
  light = {
    isValid = true
  },
  custom_1 = {
    isValid = true
  },
  custom_2 = {
    isValid = true
  },
  custom_3 = {
    isValid = true
  }
}

_G.fileman_internal = {}

local currentScheme = {}

local config = {
  searchThreads = {},
  filetypes = {},
  keybinds = {},
  version = ""
}

if computer.totalMemory() < 350000 then -- Most likely will run out of RAM!
  print("Install more memory to use `fileman`, system has " .. math.ceil(computer.totalMemory()/1000) .. "KB, requires >350KB.")
  return
end

local function stripExtension(fileName)
  return fs.name(fileName):match("(.+)%..+$")
end

local function getExtension(fileName)
  return fileName:match("^.+(%..+)$")
end

local inMenu = false

local function onClick(_, _, x, y, button) -- assuming span of screenBuffer
  if isPopupShown then
    if button == 1 then
      sideBarChanged = true
      isPopupShown = false
      inMenu = false
      gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
      gpu.setBackground(currentScheme.background)
      gpu.fill(40, 20, 80, 10, " ")
    end
    if x > 39 and x < 121 then -- inside popupBuffer
      if popupShown == "File" then
        if y == 23 and not inMenu then -- Make File
          inMenu = true
          _G.fileman_internal.cleanPopupBuffer()
          gpu.set(35, 2, "File Name:")
          gpu.setBackground(currentScheme.background)
          gpu.fill(20, 4, 41, 3, " ")
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          local name = ""
          while true do
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.fill(20, 4, 41, 3, " ")
            gpu.set(21, 5, name .. "▎")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 8 and code == 14 then
              name = name:sub(1, #name - 1)
            elseif char == 13 and code == 28 then
              gpu.set(21 + #name + 1, 8, " ")
              break
            elseif char == 3 and code == 46 or char == 127 and code == 18 then
              return
            elseif char ~= 0 then
              name = name .. unicode.char(char)
            end
          end
          if fs.exists(os.getenv("PWD") .. "/" .. name) then
            _G.fileman_internal.cleanPopupBuffer()
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.set(22, 2, "A file with this name already exists, press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          else
            local file = fs.open(os.getenv("PWD") .. "/" .. name, "w")
            file:close()
            entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
            _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          end
          gpu.setBackground(currentScheme.accentColor)
        end
        if y == 24 and not inMenu then -- Make Directory
          inMenu = true
          _G.fileman_internal.cleanPopupBuffer()
          gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
          gpu.set(33, 2, "Directory Name:")
          gpu.setBackground(currentScheme.background)
          gpu.fill(20, 4, 41, 3, " ")
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          local name = ""
          while true do
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.fill(20, 4, 41, 3, " ")
            gpu.set(21, 5, name .. "▎")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 8 and code == 14 then
              name = name:sub(1, #name - 1)
            elseif char == 13 and code == 28 then
              gpu.set(21 + #name + 1, 8, " ")
              break
            elseif char == 3 and code == 46 or char == 127 and code == 18 then
              return
            elseif char ~= 0 then
              name = name .. unicode.char(char)
            end
          end
          if fs.exists(os.getenv("PWD") .. "/" .. name) then
            _G.fileman_internal.cleanPopupBuffer()
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.set(19, 2, "A directory with this name already exists, press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          else
            local dir = os.getenv("PWD") .. "/" .. name
            fs.makeDirectory(dir)
            os.setenv("PWD", dir)
            entries = _G.fileman_internal.scanDirectory(dir)
            _G.fileman_internal.updateCurrentInfo(dir)
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          end
          gpu.setBackground(currentScheme.accentColor)
        end
      elseif popupShown == "View" then
        inMenu = true
        if y == 23 then -- Default
          currentScheme = themes["default"]
        elseif y == 24 then -- Dark Mode
          currentScheme = themes["dark"]
        elseif y == 25 then -- Light Mode
          currentScheme = themes["light"]
        elseif y == 26 then -- Custom 1
          currentScheme = themes["custom_1"]
        elseif y == 27 then -- Custom 2
          currentScheme = themes["custom_2"]
        elseif y == 28 then -- Custom 3
          currentScheme = themes["custom_3"]
        end
        sideBarChanged = true
        isPopupShown = false
        inMenu = false
        _G.fileman_internal.drawMain()
        _G.fileman_internal.updateFileBuffer(currentScrollMain)
        _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
      elseif popupShown == "Link" then
        if y == 23 and not inMenu then -- Create Link
          inMenu = true
          _G.fileman_internal.cleanPopupBuffer()
          gpu.set(33, 2, "Link filepath:")
          gpu.set(34, 6, "Link source:")
          gpu.setBackground(currentScheme.background)
          gpu.fill(20, 3, 41, 3, " ")
          gpu.fill(20, 7, 41, 3, " ")
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          local path = ""
          while true do
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.fill(20, 3, 41, 3, " ")
            gpu.set(21, 4, path .. "▎")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 8 and code == 14 then
              path = path:sub(1, #path - 1)
            elseif char == 13 and code == 28 then
              gpu.set(21 + #path + 1, 8, " ")
              break
            elseif char == 3 and code == 46 or char == 127 and code == 18 then
              return
            elseif char ~= 0 then
              path = path .. unicode.char(char)
            end
          end
          local target = ""
          while true do
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.fill(20, 7, 41, 3, " ")
            gpu.set(21, 8, target .. "▎")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 8 and code == 14 then
              target = target:sub(1, #target - 1)
            elseif char == 13 and code == 28 then
              gpu.set(21 + #target + 1, 8, " ")
              break
            elseif char == 3 and code == 46 or char == 127 and code == 18 then
              return
            elseif char ~= 0 then
              target = target .. unicode.char(char)
            end
          end
          if path:sub(0, 1) ~= "/" then
            path = os.getenv("PWD") .. "/" .. path
          end
          if target:sub(0, 1) ~= "/" then
            target = os.getenv("PWD") .. "/" .. target
          end
          
          local success, link = pcall(require, "link")
          if success then
            link.create(target, path)
          else
            fs.link(target, path)
          end
          
          entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
          _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
          sideBarChanged = true
          isPopupShown = false
          inMenu = false
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.setBackground(currentScheme.background)
          gpu.fill(40, 20, 80, 10, " ")
        end
      elseif popupShown == "Selected" then
        if y == 23 and not inMenu then -- Move Selected
          inMenu = true
          _G.fileman_internal.cleanPopupBuffer()
          gpu.set(31, 2, "Target directory:")
          gpu.setBackground(currentScheme.background)
          gpu.fill(20, 4, 41, 3, " ")
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          local path = ""
          while true do
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.fill(20, 4, 41, 3, " ")
            gpu.set(21, 5, path .. "▎")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 8 and code == 14 then
              path = path:sub(1, #path - 1)
            elseif char == 13 and code == 28 then
              gpu.set(21 + #path + 1, 8, " ")
              break
            elseif char == 3 and code == 46 or char == 127 and code == 18 then
              return
            elseif char ~= 0 then
              path = path .. unicode.char(char)
            end
          end
          if path:sub(0, 1) ~= "/" then
            path = os.getenv("PWD") .. "/" .. path
          end
          
          local isOccupied = false
          for _, v in pairs(selected) do
            if fs.exists(path .. "/" .. v.name) then
              isOccupied = true
              break;
            end
          end
          
          if isOccupied then
            _G.fileman_internal.cleanPopupBuffer()
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.set(3, 2, "One or more files with the same name exist in the target directory, override?")
            gpu.set(24, 4, "Press Y to confirm, N to cancel.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            local _, _, char, code = event.pull("key_down")
            if char == 121 and code == 21 then
              fs.makeDirectory(path)
              for _, v in pairs(selected) do
                if v.type == "LINK" then
                  local success, link = pcall(require, "link")
                  if success then
                    local _, linkPath = fs.isLink(os.getenv("PWD") .. "/" .. v.name)
                    link.remove(os.getenv("PWD") .. "/" .. v.name)
                    link.create(linkPath, path .. "/" .. v.name)
                  else
                    fs.rename(os.getenv("PWD") .. "/" .. v.name, path .. "/" .. v.name)
                  end
                else
                  fs.rename(os.getenv("PWD") .. "/" .. v.name, path .. "/" .. v.name)
                end
              end
              entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
              _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
              _G.fileman_internal.updateFileBuffer(currentScrollMain)
            end
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          elseif not fs.isDirectory(path) and fs.exists(path) then
            _G.fileman_internal.cleanPopupBuffer()
            gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
            gpu.set(7, 2, "The target location is not a directory, press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          else
            fs.makeDirectory(path)
            for _, v in pairs(selected) do
              if v.type == "LINK" then
                local success, link = pcall(require, "link")
                if success then
                  local _, linkPath = fs.isLink(os.getenv("PWD") .. "/" .. v.name)
                  link.remove(os.getenv("PWD") .. "/" .. v.name)
                  link.create(linkPath, path .. "/" .. v.name)
                else
                  fs.rename(os.getenv("PWD") .. "/" .. v.name, path .. "/" .. v.name)
                end
              else
                fs.rename(os.getenv("PWD") .. "/" .. v.name, path .. "/" .. v.name)
              end
            end
            entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
            _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
          end
          gpu.setBackground(currentScheme.accentColor)
        end
        if y == 24 and not inMenu then -- Delete Selected.
          _G.fileman_internal.cleanPopupBuffer()
          if #selected > 1 then
            gpu.set(40 - (47 + #selected[1].name + (math.floor(math.log(#selected, 10)) + 1) / 2), 2, "Are you sure you want to delete '" .. selected[1].name .. "' and " .. #selected - 1 .. " others?")
          else
            gpu.set(40 - (35 + #selected[1].name) / 2, 2, "Are you sure you want to delete '" .. selected[1].name .. "'?")
          end
          gpu.set(24, 4, "Press Y to confirm, N to cancel.")
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          local _, _, char, code = event.pull("key_down")
          if char == 121 and code == 21 then
            for _, v in pairs(selected) do
              local target = os.getenv("PWD") .. "/" .. v.name
              if v.type == "LINK" then
                local success, link = pcall(require, "link")
                if success then
                  link.remove(target)
                else
                  fs.remove(target)
                end
              else
                fs.remove(target)
              end
            end
            entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
            _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
          end
          sideBarChanged = true
          isPopupShown = false
          inMenu = false
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.setBackground(currentScheme.background)
          gpu.fill(40, 20, 80, 10, " ")
        end
        if y == 25 and not inMenu then -- OCZ Compress
          inMenu = true
          local oczStatus, ocz = pcall(require, "oczlib")
          if not oczStatus then
            gpu.set(26, 2, "OCZ library failed to load.")
            gpu.set(40 - (7 + #ocz) / 2, 4, "Error: " .. ocz)
            gpu.set(27, 5, "Press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
            sideBarChanged = true
            isPopupShown = false
            inMenu = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
            return
          end
          _G.fileman_internal.cleanPopupBuffer()
          local skipped = 0
          for _, v in pairs(selected) do
            if v.type == "DIR" then
              skipped = skipped + 1
            else
              local compressedData = ocz.compressFile(os.getenv("PWD") .. "/" .. v.name)
              if not compressedData then
                skipped = skipped + 1
              else
                local handle = io.open(os.getenv("PWD") .. "/" .. stripExtension(v.name) .. ".ocz", "w")
                handle:write(compressedData)
                handle:close()
              end
            end
          end
          if skipped > 0 then
            gpu.set(40 - (34 + math.floor(math.log(skipped, 10)) + 1) / 2, 2, "OCZ compression failed for " .. skipped .. " file(s).")
            gpu.set(29, 4, "Press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
          end
          entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
          _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
          sideBarChanged = true
          isPopupShown = false
          inMenu = false
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.setBackground(currentScheme.background)
          gpu.fill(40, 20, 80, 10, " ")
        end
        if y == 26 and not inMenu then -- OCZ Decompress
          inMenu = true
          local oczStatus, ocz = pcall(require, "oczlib")
          if not oczStatus then
            gpu.set(26, 2, "OCZ library failed to load.")
            gpu.set(40 - (7 + #ocz) / 2, 4, "Error: " .. ocz)
            gpu.set(27, 5, "Press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
            sideBarChanged = true
            isPopupShown = false
            gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
            gpu.setBackground(currentScheme.background)
            gpu.fill(40, 20, 80, 10, " ")
            return
          end
          _G.fileman_internal.cleanPopupBuffer()
          local skipped = 0
          for _, v in pairs(selected) do
            if v.type == "DIR" then
              skipped = skipped + 1
            else
              local decompressedData = ocz.decompressFile(os.getenv("PWD") .. "/" .. v.name)
              if not decompressedData then
                skipped = skipped + 1
              else
                local handle = io.open(os.getenv("PWD") .. "/" .. stripExtension(v.name) .. ".raw", "w")
                handle:write(decompressedData)
                handle:close()
              end
            end
          end
          if skipped > 0 then
            gpu.set(40 - (34 + math.floor(math.log10(skipped)) + 1) / 2, 2, "OCZ decompression failed for " .. skipped .. " file(s).")
            gpu.set(29, 4, "Press any key to continue.")
            gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
            event.pull("key_down")
          end
          entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
          _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
          sideBarChanged = true
          isPopupShown = false
          inMenu = false
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.setBackground(currentScheme.background)
          gpu.fill(40, 20, 80, 10, " ")
        end
        if y == 27 then
          _G.fileman_internal.openInEditor()
        end
      end
    else
      sideBarChanged = true
      isPopupShown = false
      inMenu = false
      gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
      gpu.setBackground(currentScheme.background)
      gpu.fill(40, 20, 80, 10, " ")
    end
  else
    if x > 1 and x < 82 then
      if y == 4 then -- Sorting!!!
        if x > 0 and x < 8 then
          if sizeSort == false then
            if reverseSort == true then
              reverseSort = false
            else
              reverseSort = true
            end
          else
            sizeSort = false
            reverseSort = false
          end
        end
        if x > 50 and x < 58 then
          if sizeSort == true then
            if reverseSort == true then
              reverseSort = false
            else
              reverseSort = true
            end
          else
            sizeSort = true
            reverseSort = false
          end
        end
        entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
        _G.fileman_internal.updateFileBuffer(currentScrollMain)
      end
      if y > 4 and y < 48 then -- inside logBuffer
        if button == 0 and #selected > 0 then
          selected = {}
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
          sideBarChanged = true
          currentScrollPreview = 0
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.setBackground(currentScheme.invalidColor)
          gpu.fill(37, 1, 10, 3, " ")
          gpu.set(38, 2, "Selected")
        end
        if entries[y - 4 + currentScrollMain] ~= nil then
          local item = entries[y - 4 + currentScrollMain]
          if button == 0 then -- left click
            if item.type == "DIR" then
              local dir = fs.canonical(os.getenv("PWD") .. "/" .. item.name) -- ".." will also work
              os.setenv("PWD", dir)
              entries = _G.fileman_internal.scanDirectory(dir)
              _G.fileman_internal.updateCurrentInfo(dir)
              currentScrollMain = 0
              _G.fileman_internal.updateFileBuffer(currentScrollMain)
            end
          else -- right click
            if not isPopupShown then
              if #selected > 0 and not keyboard.isShiftDown() then
                selected = {}
                local element = {
                  name  = item.name,
                  type  = item.type,
                  index = item.index
                }
                table.insert(selected, element)
                _G.fileman_internal.updateFileBuffer(currentScrollMain)
              else
                for i, v in pairs(selected) do
                  if v.index == item.index then
                    table.remove(selected, i)
                    _G.fileman_internal.updateFileBuffer(currentScrollMain)
                    return;
                  end
                end
                local element = {
                  name  = item.name,
                  type  = item.type,
                  index = item.index
                }
                table.insert(selected, element)
                _G.fileman_internal.updateFileBuffer(currentScrollMain)
              end
              sideBarChanged = true
              currentScrollPreview = 0
              gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
              gpu.setBackground(currentScheme.accentColor)
              gpu.fill(37, 1, 10, 3, " ")
              gpu.set(38, 2, "Selected")
            end
          end
        end
      end
    end
    if y < 4 then -- inside the upper bar
      _G.fileman_internal.updateFileBuffer(currentScrollMain)
      if x > 18 and x < 25 then -- "File" button
        _G.fileman_internal.cleanPopupBuffer()
        isPopupShown = true
        popupShown = "File"
        gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
        gpu.set(38, 2, "File")
        -- This gives 6 pixels for options.
        gpu.set(30, 4, "> Make File")
        gpu.set(30, 5, "> Make Directory")
        --gpu.set(30, 6, "> File")
        --gpu.set(30, 7, "> File")
        --gpu.set(30, 8, "> File")
        --gpu.set(30, 9, "> File")
        gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
        gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
      end
      if x > 24 and x < 31 then -- "View" button
        _G.fileman_internal.cleanPopupBuffer()
        isPopupShown = true
        popupShown = "View"
        gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
        gpu.set(38, 2, "View")
        gpu.set(30, 4, "> Default")
        gpu.set(30, 5, "> Dark Mode")
        gpu.set(30, 6, "> Light Mode")
        gpu.set(30, 7, "> Custom Theme 1")
        gpu.set(30, 8, "> Custom Theme 2")
        gpu.set(30, 9, "> Custom Theme 3")
        gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
        gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
      end
      if x > 30 and x < 37 then -- "Link" button
        _G.fileman_internal.cleanPopupBuffer()
        isPopupShown = true
        popupShown = "Link"
        gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
        gpu.set(38, 2, "Link")
        gpu.set(30, 4, "> Create Symlink")
        --gpu.set(30, 5, "> Remove Symlink")
        --gpu.set(30, 6, "> File")
        --gpu.set(30, 7, "> File")
        --gpu.set(30, 8, "> File")
        --gpu.set(30, 9, "> File")
        gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
        gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
      end
      if x > 36 and x < 47 then -- "Selected" button
        if #selected ~= 0 then
          _G.fileman_internal.cleanPopupBuffer()
          isPopupShown = true
          popupShown = "Selected"
          gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
          gpu.set(36, 2, "Selected")
          -- This gives 6 pixels for options.
          gpu.set(30, 4, "> Move")
          gpu.set(30, 5, "> Delete")
          gpu.set(30, 6, "> Compress with OCZ")
          gpu.set(30, 7, "> Decompress with OCZ")
          gpu.set(30, 8, "> Open file in external editor")
          --gpu.set(30, 9, "> File")
          gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
          gpu.bitblt(_G.fileman_internal.screenBuffer, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
        end
      end
    end
  end
end

function _G.fileman_internal.onKeyPress(_, _, _, _)
  for key, value in pairs(config.keybinds) do
    local amountPressed = 0
    for _, v in pairs(value) do
      if keyboard.isKeyDown(v) then
        amountPressed = amountPressed + 1
      end
    end
    if amountPressed == #value then
      if key == "exitPopup" then
        sideBarChanged = true
        isPopupShown = false
        inMenu = false
        gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
        gpu.setBackground(currentScheme.background)
        gpu.fill(40, 20, 80, 10, " ")
      elseif key == "openInEditor" and not isPopupShown then
        _G.fileman_internal.openInEditor()
      elseif key == "refresh" and not isPopupShown then
        entries = _G.fileman_internal.scanDirectory(os.getenv("PWD"))
        _G.fileman_internal.updateFileBuffer(currentScrollMain)
        _G.fileman_internal.updateCurrentInfo(os.getenv("PWD"))
      elseif key == "forceCrash" then
        _G.fileman_internal.progErr("User initiated crash (Ctrl-Alt-Backspace).")
      elseif key == "nudgeDown" and not isPopupShown then
        if canScroll then
          currentScrollMain = currentScrollMain + 2
          if currentScrollMain > #entries - 44 then
            currentScrollMain = #entries - 44
          else
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
          end
        end
      elseif key == "nudgeUp" and not isPopupShown then
        if canScroll then
          currentScrollMain = currentScrollMain - 2
          if currentScrollMain < 0 then
            currentScrollMain = 0
          else
            _G.fileman_internal.updateFileBuffer(currentScrollMain)
          end
        end
      elseif key == "fileTab" and not isPopupShown then
        onClick(nil, nil, 20, 2, 0)
      elseif key == "viewTab" and not isPopupShown then
        onClick(nil, nil, 26, 2, 0)
      elseif key == "linkTab" and not isPopupShown then
        onClick(nil, nil, 32, 2, 0)
      elseif key == "selectedTab" and not isPopupShown then
        onClick(nil, nil, 38, 2, 0)
      end
    end
  end
end

local scrollCachePreview = {}

function _G.fileman_internal.onScroll(_, _, x, y, dir)
  if #selected == 1 and selected[1].type == "FILE" and x > 83 and x < 160 and y > 14 and y < 50 then
    if dir == 1 then
      currentScrollPreview = currentScrollPreview - 2
      if currentScrollPreview < 0 then
        currentScrollPreview = 0
      else
        sideBarChanged = true
      end
    elseif dir == -1 then
      currentScrollPreview = currentScrollPreview + 2
      if scrollCachePreview.name ~= selected[1].name then
        local n = 0
        local handle = io.open(os.getenv("PWD") .. "/" .. selected[1].name)
        for line in handle:lines() do
          if line == nil then -- ????
            n = n + 1
          else
            if #line > 77 then
              while #line > 0 do
                n = n + 1
                line = line:sub(77 + 1)
              end
            else
              n = n + 1
            end
          end
        end
        handle:close()
        scrollCachePreview.name = selected[1].name
        scrollCachePreview.value = n
      end
      if currentScrollPreview > scrollCachePreview.value - 34 then
        currentScrollPreview = scrollCachePreview.value - 34
      else
        sideBarChanged = true
      end
    end
  else
    if canScroll then
      if dir == 1 then
        currentScrollMain = currentScrollMain - 2
        if currentScrollMain < 0 then
          currentScrollMain = 0
        else
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
        end
      elseif dir == -1 then
        currentScrollMain = currentScrollMain + 2
        if currentScrollMain > #entries - 44 then
          currentScrollMain = #entries - 44
        else
          _G.fileman_internal.updateFileBuffer(currentScrollMain)
        end
      end
    end
  end
end

local currentInfo = {
  size = 0,
  count = 0,
  progressBar = {}
}

local function splitText(inputText)
  local x = 78/2 - #inputText/2
  local y = 2
  local lines = {}
  if x < 2 then
    local text = ""
    local words = {}
    for i, _ in inputText:gmatch("([^%s]+)") do
      table.insert(words, i)
    end
    for i, v in pairs(words) do
      text = text .. " " .. v
      if #text > 78 then
        table.insert(lines, {y = y, text = text:sub(1, #text - #words[i] - 1)})
        text = text:sub(#text - #words[i])
        y = y + 1
      end
    end
    table.insert(lines, {y = y, text = text})
  else
    table.insert(lines, {y = y, text = inputText})
  end
  return lines
end

-- please lua
function _G.fileman_internal.progErrWrapper(_, msg)
  _G.fileman_internal.progErr(msg)
end

function _G.fileman_internal.openInEditor()
  local editorPath = os.getenv("EDITOR")
  _G.fileman_internal.dispThread:suspend()
  event.ignore("touch", onClick) -- ignore the onClick event
  event.ignore("scroll", _G.fileman_internal.onScroll)
  event.ignore("key_down", _G.fileman_internal.onKeyPress)
  event.ignore("fileman_err", _G.fileman_internal.progErrWrapper)
  event.ignore("interrupted", _G.fileman_internal.onInterrupt)
  
  gpu.setActiveBuffer(0)
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, 160, 50, " ")
  
  pcall(require("shell").execute(editorPath .. " " .. os.getenv("PWD") .. "/" .. selected[1].name))
  
  event.listen("touch", onClick)
  event.listen("scroll", _G.fileman_internal.onScroll)
  event.listen("key_down", _G.fileman_internal.onKeyPress)
  event.listen("fileman_err", _G.fileman_internal.progErrWrapper) -- wrapper just to extract the event name
  event.listen("interrupted", _G.fileman_internal.onInterrupt)
  
  _G.fileman_internal.drawMain()
  _G.fileman_internal.updateFileBuffer(currentScrollMain)
  
  _G.fileman_internal.sideBarLineCache = {} -- clear cache to force reloading.
  
  _G.fileman_internal.dispThread:resume()
  
  sideBarChanged = true
  isPopupShown = false
end

function _G.fileman_internal.onInterrupt()
  selected = {}
  _G.fileman_internal.updateFileBuffer(currentScrollMain)
  if _G.fileman_internal.dispThread:status() ~= "dead" then
    _G.fileman_internal.dispThread:kill() -- forcefully kill the display thread to keep from overriding the popup
  end
  if _G.fileman_internal.listenerThread:status() ~= "dead" then
    -- after this moment, this function is completely in charge of graphics processing and there is no other VRAM/screen modifications being made.
    _G.fileman_internal.listenerThread:kill() -- forcefully kill the listener thread to keep additional logs from coming in
  end
  os.sleep(0.05)
  event.ignore("touch", onClick) -- ignore the onClick event
  event.ignore("scroll", _G.fileman_internal.onScroll)
  event.ignore("key_down", _G.fileman_internal.onKeyPress)
  event.ignore("fileman_err", _G.fileman_internal.progErrWrapper)
  event.ignore("interrupted", _G.fileman_internal.onInterrupt)
  _G.fileman_internal.cleanPopupBuffer()
  gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
  gpu.set(31, 2, "Exiting Fileman...")
  gpu.setActiveBuffer(0)
  gpu.bitblt(0, 1, 1, 160, 50, _G.fileman_internal.screenBuffer, 1, 1) -- copy screen buffer to screen
  gpu.bitblt(0, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)  -- copy popup to screen; no worries about other content overriding due to the display thread being dead
  os.sleep(0.5)
  -- BEGIN POST-CLEANUP
  
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, 160, 50, " ")
  gpu.freeAllBuffers()
  term.clear()
  isErrored = true
  
  _G.fileman_internal = {} -- Clean all internal tables.
  
  -- END POST-CLEANUP
  
  os.exit(0) -- stop execution completely
end

--- this function ends the program!!!

function _G.fileman_internal.progErr(reason)
  selected = {}
  _G.fileman_internal.updateFileBuffer(currentScrollMain)
  local maxY = 0
  if _G.fileman_internal.dispThread:status() ~= "dead" then
    _G.fileman_internal.dispThread:kill() -- forcefully kill the display thread to keep from overriding the popup
  end
  if _G.fileman_internal.listenerThread:status() ~= "dead" then
    -- after this moment, this function is completely in charge of graphics processing and there is no other VRAM/screen modifications being made.
    _G.fileman_internal.listenerThread:kill() -- forcefully kill the listener thread to keep additional logs from coming in
  end
  os.sleep(0.05)
  event.ignore("touch", onClick) -- ignore the onClick event
  event.ignore("scroll", _G.fileman_internal.onScroll)
  event.ignore("key_down", _G.fileman_internal.onKeyPress)
  event.ignore("fileman_err", _G.fileman_internal.progErrWrapper)
  event.ignore("interrupted", _G.fileman_internal.onInterrupt)
  _G.fileman_internal.cleanPopupBuffer()
  gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
  for _, v in pairs(splitText("Fileman has crashed with the following reason: " .. reason)) do
    gpu.set(80/2 - #v.text/2 + 1, v.y, v.text)
    maxY = math.max(v.y, maxY)
  end
  local text = "Press any key to exit..."
  gpu.set(80/2 - #text/2, maxY + 3, text)
  gpu.setActiveBuffer(0)
  gpu.bitblt(0, 1, 1, 160, 50, _G.fileman_internal.screenBuffer, 1, 1) -- copy screen buffer to screen to ensure that cases like on-startup errors are handled correctly.
  gpu.bitblt(0, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)  -- copy popup to screen; no worries about other content overriding due to the display thread being dead
  computer.beep(1000, 3) -- beep for 3 seconds, also pauses execution completely
  event.pull("key_down") -- pause execution until user presses a key
  
  -- BEGIN POST-CLEANUP
  
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, 160, 50, " ")
  gpu.freeAllBuffers()
  term.clear()
  isErrored = true
  
  _G.fileman_internal = {} -- Clean all internal tables.
  
  -- END POST-CLEANUP
  
  os.exit(0) -- stop execution completely
end

event.listen("fileman_err", _G.fileman_internal.progErrWrapper) -- wrapper just to extract the event name

local function threadWrapper(func, uuid)
  xpcall(function()
    func()
  end, function(reason)
    -- On thread error:
    local t = thread.current()
    if uuid:sub(6, 9) == "LOOP" and t ~= nil then
      event.push("fileman_err", "Error in critical loop thread '" .. uuid .. "'; " .. reason .. ". " .. debug.traceback())
      t:suspend()
    end
    if not t then
      event.push("fileman_err", "Thread wrapper errored outside thread; no additional information.")
      -- realistically this should end the program so no statement needed
    else
      -- uh if we get here
      -- something is really wrong
      -- the thread errored but the uuid was not found inside the thread stack
      -- so the program never actually made the thread but its somehow erroring
      -- ruh roh
      event.push("fileman_err", "Thread error on thread '" .. uuid .. "'; UUID not found in thread stack.")
      t:suspend()
    end
  end)
end

----------------------------------------------------------------------------------------------------

_G.fileman_internal.screenBuffer = gpu.allocateBuffer(160, 50) -- buffer for entire screen

_G.fileman_internal.popupBuffer = gpu.allocateBuffer(80, 10) -- buffer for popups

_G.fileman_internal.fileBuffer = gpu.allocateBuffer(80, 45) -- buffer for logs

_G.fileman_internal.sideBarBuffer = gpu.allocateBuffer(79, 46) -- buffer for info sidebar

function _G.fileman_internal.drawMain()
  
  -- initialize display buffers
  gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
  gpu.setBackground(currentScheme.background)
  gpu.setForeground(currentScheme.textColor)
  gpu.fill(1, 1, 160, 50, " ")  -- blank buffer
  gpu.setBackground(currentScheme.accentColor)
  gpu.fill(1, 1, 160, 3, " ")
  
  gpu.set(3, 2, "Fileman v" .. config.version)
  
  gpu.set(20, 2, "File")
  gpu.set(26, 2, "View")
  gpu.set(32, 2, "Link")
  gpu.setBackground(currentScheme.invalidColor)
  gpu.fill(37, 1, 10, 3, " ")
  gpu.set(38, 2, "Selected")
  _G.fileman_internal.cleanPopupBuffer()
  
  -- initialize display buffers
  gpu.setActiveBuffer(_G.fileman_internal.fileBuffer)
  gpu.setBackground(currentScheme.background)
  gpu.setForeground(currentScheme.textColor)
  gpu.fill(1, 1, 74, 45, " ")  -- blank buffer
  
  gpu.setActiveBuffer(0)
end

-- initialize display buffers
function _G.fileman_internal.cleanPopupBuffer()
  gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
  gpu.setBackground(currentScheme.accentColor)
  gpu.setForeground(currentScheme.textColor)
  gpu.fill(1, 1, 80, 10, " ")  -- blank buffer
  gpu.fill(1, 1, 1, 10, "│")        --  ─────
  gpu.fill(80, 1, 1, 10, "│")       -- │     │
  gpu.fill(1, 1, 80, 1, "─")        -- │     │
  gpu.fill(1, 10, 80, 1, "─")       --  ─────
  
  gpu.set(1, 1, "┌")                -- ┌     ┐
  gpu.set(80, 1, "┐")               --
  gpu.set(1, 10, "└")               --
  gpu.set(80, 10, "┘")              -- └     ┘
end

----------------------------------------------------------------------------------------------------

-- prepare fileBuffer to be written to screen
function _G.fileman_internal.updateFileBuffer(offset)
  gpu.setActiveBuffer(_G.fileman_internal.fileBuffer)
  gpu.fill(1, 1, 80, 45, " ")
  local sortingSymbol = unicode.char(0x1F873) -- Down arrow.
  if reverseSort then
    sortingSymbol = unicode.char(0x1F871) -- Up arrow.
  end
  if not sizeSort then
    gpu.set(1, 1, "Name " .. sortingSymbol) -- oops put these here
    gpu.set(52, 1, "Size")
  else
    gpu.set(1, 1, "Name")
    gpu.set(52, 1, "Size "  .. sortingSymbol)
  end
  gpu.set(68, 1, "Type")
  -- Write name of file to VRAM
  for i, v in pairs(entries) do
    if i > offset then
      for _, w in pairs(selected) do
        if w.index == v.index then
          gpu.setBackground(currentScheme.selectedColor)
          gpu.setForeground(currentScheme.selectedTextColor)
          gpu.fill(1, i + 1 - offset, 80, 1, " ")
          break;
        else
          gpu.setBackground(currentScheme.background)
          gpu.setForeground(currentScheme.textColor)
        end
      end
      -- add 1 to every i to push the entries down
      if #v.name < 50 then -- 1-50 range in X axis
        gpu.set(1, i + 1 - offset, v.name)
      else
        gpu.set(1, i + 1 - offset, v.name:sub(1, 47) .. "...")
      end
      -- Write size of file/dir to VRAM
      local function size() if v.type == "DIR" then return " " else return tostring(fs.size(os.getenv("PWD") .. "/" .. v.name)) .. " Bytes" end end
      gpu.set(52, i + 1 - offset, size()) -- 52-66
      -- Write file/dir label
      gpu.set(68, i + 1 - offset, v.type) -- 68-72
      -- Write file index
      -- gpu.set(74, i + 1 - offset, tostring(v.index)) -- 74-77; unused
    end
  end
  gpu.setBackground(currentScheme.background)
  gpu.setForeground(currentScheme.textColor)
  gpu.setActiveBuffer(0)
end

----------------------------------------------------------------------------------------------------

local function readConfig()
  local handle = io.open("/etc/fileman.xml")
  local success, fileman_config = pcall(slaxml.dom, nil, handle:read("*a"))
  handle:close()
  
  if not success then
    print("Config could not be loaded; " .. fileman_config)
    os.exit(-1)
  else
    fileman_config = fileman_config.root
  end
  
  for _, v in pairs(fileman_config.kids) do
    if v.name == "themes" then
      for _, w in pairs(v.el) do
        for _, x in pairs(w.el) do
          if(tonumber(x.kids[1].value, 16) == nil) then
            if(w.name == "default") then
              print("Default color theme failed to load.")
              os.exit(-1)
            end
            themes[w.attr[1].value].isValid = false
          end
          themes[w.attr[1].value][x.name] = tonumber(x.kids[1].value, 16)
        end
      end
    elseif v.name == "version" then
      config.version = v.kids[1].value
    elseif v.name == "filetypes" then
      for _, w in pairs(v.el) do
        config.filetypes[w.attr[1].value] = w.kids[1].value
      end
    elseif v.name == "keybinds" then
      for _, w in pairs(v.el) do
        
        -- Parse config
        local keyCombo = {}
        
        for entry in w.kids[1].value:gmatch("([^-]+)") do
          local code = keyboard.keys[entry]
          if code == nil then
            print("Invalid keybinding for " .. w.attr[1].value)
            os.exit(-1)
          end
          table.insert(keyCombo, code)
        end
        config.keybinds[w.attr[1].value] = keyCombo
      end
    end
  end
end

readConfig()

currentScheme = {}

currentScheme = themes.default

_G.fileman_internal.drawMain()

----------------------------------------------------------------------------------------------------

_G.fileman_internal.sideBarLineCache = {}

local function addSidebarInfo()
  gpu.setActiveBuffer(_G.fileman_internal.sideBarBuffer)
  gpu.setBackground(currentScheme.accentColor)
  gpu.fill(1, 2, 79, 46, " ") -- blank buffer
  gpu.setBackground(currentScheme.background)
  gpu.setForeground(currentScheme.textColor)
  gpu.fill(1, 1, 79, 1, " ") -- top bar
  if #selected == 0 then
    gpu.set(2, 1, "No file selected.")
  elseif #selected == 1 then
    gpu.set(2, 1, "1 file selected.")
    gpu.setBackground(currentScheme.accentColor)
    gpu.set(2, 3, "File name: " .. selected[1].name)
    if _G.fileman_internal.sideBarLineCache.name ~= selected[1].name then
      _G.fileman_internal.sideBarLineCache.bytes = fs.size(os.getenv("PWD") .. "/" .. selected[1].name)
    end
    gpu.set(2, 5, "File size: " .. _G.fileman_internal.sideBarLineCache.bytes .. " Bytes")
    local extension = getExtension(selected[1].name)
    if extension ~= nil and config.filetypes[extension:sub(2)] ~= nil then
      gpu.set(2, 6, "File type: " .. selected[1].type .. "; (." .. extension:sub(2) .. "): " .. config.filetypes[extension:sub(2)])
    elseif extension ~= nil then
      gpu.set(2, 6, "File type: " .. selected[1].type .. "; (." .. extension:sub(2) .. "): Unknown extension.")
    else
      gpu.set(2, 6, "File type: " .. selected[1].type)
    end
    
    if _G.fileman_internal.sideBarLineCache.name ~= selected[1].name then
      _G.fileman_internal.sideBarLineCache.modified = os.date("%d/%m/%Y, %H:%M:%S", tostring(fs.lastModified(os.getenv("PWD") .. "/" .. selected[1].name)):sub(0, 10))
    end
    gpu.set(2, 8, "Last modified: " .. _G.fileman_internal.sideBarLineCache.modified)
    
    if selected[1].type ~= "DIR" then
      if _G.fileman_internal.sideBarLineCache.name ~= selected[1].name then
        local lines = {}
        local handle = io.open(os.getenv("PWD") .. "/" .. selected[1].name)
        if handle == nil then
          gpu.set(2, 10, "Could not open file for preview.")
          sideBarChanged = false
          return
        end
        local success, err = pcall(function()
          
          _G.fileman_internal.cleanPopupBuffer()
          isPopupShown = true
          gpu.setActiveBuffer(_G.fileman_internal.popupBuffer)
          gpu.set(33, 2, "Loading file...")
          gpu.set(33, 6, "Reading file...")
          
          gpu.bitblt(0, 40, 20, 160, 50, _G.fileman_internal.popupBuffer, 1, 1)
          
          local characterCount = unicode.len(handle:read("*a"))
          if characterCount == 0 then characterCount = 1 end
          local bar = progress.new({totalWork = characterCount, x = 3, y = 4, width = 76, buffer = _G.fileman_internal.popupBuffer})
          bar.draw()
          handle:close()
          
          handle = io.open(os.getenv("PWD") .. "/" .. selected[1].name)
          
          gpu.set(28, 6, "Rendering preview text...")
          
          local fileContent = handle:read("*a")
          for line in fileContent:gmatch("([^\n]+)") do
            local maxLength = 77
            if unicode.wlen(line) > maxLength then
              while unicode.wlen(line) > 0 do
                local outputLine = ""
                local lineWidth = 0
                local charactersInLine = 0
                if unicode.wlen(line) == unicode.len(line) then -- Not a unicode string/all characters are width 1.
                  table.insert(lines, line:sub(0, maxLength))
                  line = line:sub(maxLength + 1)
                  bar.update(#line)
                else
                  for i = 1, unicode.len(line) do
                    local char = unicode.sub(line, i, i)
                    lineWidth = lineWidth + unicode.charWidth(char)
                    if(lineWidth >= maxLength - (unicode.charWidth(char) - 1)) then
                      break
                    end
                    outputLine = outputLine .. char
                    charactersInLine = charactersInLine + 1
                    bar.update(1)
                    if i % 100 == 0 then
                      os.sleep(0.05)
                    end
                  end
                  if #lines % 25 == 0 then
                    os.sleep(0.05)
                  end
                  table.insert(lines, outputLine)
                  line = unicode.sub(line, charactersInLine + 1)
                end
              end
            else
              table.insert(lines, line)
              bar.update(#line)
            end
          end
          bar.finish()
          handle:close()
          _G.fileman_internal.sideBarLineCache.name = selected[1].name
          _G.fileman_internal.sideBarLineCache.value = lines
        end)
        gpu.setActiveBuffer(_G.fileman_internal.sideBarBuffer)
        if not success then
          isPopupShown = false
          if handle ~= nil then
            handle:close()
          end
          gpu.set(2, 10, "Could not open file for preview. Below is a description of the error.")
          gpu.set(2, 12, err)
          local i = 0
          for line in debug.traceback():gmatch("[^\r\n]+") do
            if i == 0 then
              gpu.set(2, 13 + i, line)
            else
              gpu.set(2, 13 + i, line:sub(2))
            end
            i = i + 1
          end
          sideBarChanged = false
          return
        end
      end
      isPopupShown = false
      gpu.set(2, 10, "Lines " .. currentScrollPreview + 1 .. "-" .. currentScrollPreview + 37 .. ", " .. #(_G.fileman_internal.sideBarLineCache.value) .. " lines total.")
      gpu.setBackground(currentScheme.background)
      gpu.fill(2, 11, 77, 39, " ") -- blank file preview buffer
      for i, v in pairs(_G.fileman_internal.sideBarLineCache.value) do
        if i > currentScrollPreview then
          gpu.set(2, 10 + i - currentScrollPreview, v)
        end
      end
    end
  
  elseif #selected > 1 then
    gpu.set(2, 1, #selected .. " files selected.")
    gpu.setBackground(currentScheme.accentColor)
    local totalSize = 0
    local function size(file, type) if type == "DIR" then return 0 else return fs.size(os.getenv("PWD") .. "/" .. file) end end
    for _, v in pairs(selected) do
      totalSize = totalSize + size(v.name, v.type)
    end
    gpu.set(2, 3, "Total size: " .. totalSize .. " Bytes")
  end
  sideBarChanged = false
end

function _G.fileman_internal.scanDirectory(directory)
  local items = {}
  local returnItems = {}
  for name in fs.list(directory) do
    local type = ""
    if fs.isDirectory(directory .. "/" .. name) then
      type = "DIR"
    elseif fs.isLink(directory .. "/" .. name) then
      type = "LINK"
    else
      type = "FILE"
    end
    table.insert(items, {name = name, type = type})
  end
  table.sort(items, function(a, b) -- Sort by name AND type.
    if sizeSort then
      if fs.size(directory .. "/" .. a.name) > fs.size(directory .. "/" .. b.name) then
        return true ~= reverseSort
      elseif fs.size(directory .. "/" .. a.name) < fs.size(directory .. "/" .. b.name) then
        return false ~= reverseSort
      end
    end
    if a.type == b.type then
      for i = 1, #a.name do
        if (a.name:sub(i, i):byte() or 0) < (b.name:sub(i, i):byte() or 0) then
          return true ~= reverseSort
        elseif (a.name:sub(i, i):byte() or 0) > (b.name:sub(i, i):byte() or 0) then
          return false ~= reverseSort
        end
      end
    elseif a.type == "FILE" then
      return false
    elseif a.type == "DIR" then
      return true
    elseif a.type == "LINK" and b.type == "DIR" then
      return false
    elseif a.type == "LINK" and b.type == "FILE" then
      return true
    end
  end)
  if directory ~= "/" then
    table.insert(returnItems, {name = "..", type = "DIR", index = 1})
  end
  for i, v in pairs(items) do
    table.insert(returnItems, {name = v.name, type = v.type, index = i + 1})
  end
  items = {}
  return returnItems
end

function _G.fileman_internal.updateCurrentInfo(directory)
  currentInfo.size = 0
  currentInfo.count = 0
  for name in fs.list(directory) do
    currentInfo.size = currentInfo.size + fs.size(directory .. "/" .. name)
    currentInfo.count = currentInfo.count + 1
  end
  gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
  gpu.setBackground(currentScheme.accentColor)
  gpu.fill(1, 50, 160, 1, " ")
  gpu.set(2, 50, "Size: " .. tostring(currentInfo.size) .. " Bytes")
  gpu.set(24, 50, "Count: " .. tostring(currentInfo.count))
  gpu.setBackground(currentScheme.background)
end

local function addExtraInfo()
  local remainingRAM = computer.freeMemory()
  local totalRAM = computer.totalMemory()
  local usedRAM = totalRAM - remainingRAM
  
  local remainingVRAM = gpu.freeMemory()
  local totalVRAM = gpu.totalMemory()
  local usedVRAM = totalVRAM - remainingVRAM
  
  gpu.setActiveBuffer(_G.fileman_internal.screenBuffer)
  gpu.setBackground(currentScheme.accentColor)
  gpu.fill(85, 2, 76, 1, " ")
  gpu.set(85, 2, "VRAM: " .. math.ceil(remainingVRAM) .. "B/" .. math.ceil(totalVRAM) .."B Free; " .. math.ceil(usedVRAM) .. "B Used")
  gpu.set(126, 2, "RAM: " .. math.ceil(remainingRAM/1000) .. "KB/" .. math.ceil(totalRAM/1000) .."KB Free; " .. math.ceil(usedRAM/1000) .. "KB Used")
end

local function displayLoop()
  while true do
    gpu.setActiveBuffer(0)
    if not isPopupShown then
      gpu.bitblt(_G.fileman_internal.screenBuffer, 2, 4, 160, 50, _G.fileman_internal.fileBuffer, 1, 1)
    end
    if sideBarChanged then
      addSidebarInfo()
      gpu.bitblt(_G.fileman_internal.screenBuffer, 82, 4, 160, 50, _G.fileman_internal.sideBarBuffer, 1, 1)
    end
    addExtraInfo()
    gpu.bitblt(0, 1, 1, 160, 50, _G.fileman_internal.screenBuffer, 1, 1)
    os.sleep(0.05)
  end
end

local function listenLoop()
  while true do
    os.sleep(0.05)
  end
end

-- after this point it is assumed that the program CAN launch.
-- if the program errors in the main chunk and it is uncaught after this point
-- it WILL NOT trigger the error handler!

gpu.setActiveBuffer(0)

-- init screen with directory at [PWD]

local wd = os.getenv("PWD")

entries = _G.fileman_internal.scanDirectory(wd)
_G.fileman_internal.updateCurrentInfo(wd)
_G.fileman_internal.updateFileBuffer(0) -- manually update the logBuffer

-- create 2 threads
_G.fileman_internal.dispThread     = thread.create(function()
  threadWrapper(displayLoop, "DISP_LOOP:" .. math.random(0, 65535))
end)
_G.fileman_internal.listenerThread = thread.create(function()
  threadWrapper(listenLoop, "LIST_LOOP:" .. math.random(0, 65535))
end)

event.listen("touch", onClick)
event.listen("scroll", _G.fileman_internal.onScroll)
event.listen("key_down", _G.fileman_internal.onKeyPress)
event.listen("interrupted", _G.fileman_internal.onInterrupt)

while not isErrored do
  if #entries > 45 then
    canScroll = true
  end
  os.sleep(0.05)
end