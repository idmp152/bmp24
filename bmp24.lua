local shell = require("shell")
local filesystem = require("filesystem")
local internet = require("internet")
local component = require("component")
local term = require("term")
local gpu = component.gpu

local args, ops = shell.parse(...)


function rgbToHex(rgb)
  local hexadecimal = '0X'
  for key, value in pairs(rgb) do
    local hex = ''
    while(value > 0)do
      local index = math.fmod(value, 16) + 1
      value = math.floor(value / 16)
      hex = string.sub('0123456789ABCDEF', index, index) .. hex     
    end
    if(string.len(hex) == 0)then
      hex = '00'
    elseif(string.len(hex) == 1)then
      hex = '0' .. hex
    end
    hexadecimal = hexadecimal .. hex
  end
  return hexadecimal
end

local res = filesystem.size(ops["path"])

local img = io.open(ops["path"], "rb")
if(img==nil) then
  error("no such file found")
end
--тут читаются 2 байта, так как первые 2 байта у .bmp должны быть равны BM
local isBmp = img:read(2)
if isBmp ~= "BM" then error("input file is not .bmp") end
--тут читаются байты в промежутке с 19 по 23 байт, где находится информация о ширине изображения
img:read(16)
local w = string.unpack(">B", img:read(1))
--а тут читаются байты в промежутке с 24 по 27 байт, где находится информация о высоте изображения
img:read(3)
local h = string.unpack(">B", img:read(1))
--а тут читаются оставшиеся 31 байт, так как с 1 до 54 байта включительно находится заголовок .bmp
img:read(31)
local byte_to_int = nil
local extrabytes=((res-54)-w*h*3)/h --не спрашивайте зачем, так надо
local rgb_t = {}
local px_t = {}
local r = nil
local b = nil
term.clear()
for i=1, res-54-extrabytes*h do
  byte_to_int=string.unpack(">B", img:read(1))
  table.insert(rgb_t, byte_to_int)
  if(i%(w*3)==0) then
    img:read(extrabytes)
  end
  if(#rgb_t==3) then
    r = rgb_t[1]
    b = rgb_t[3]
    rgb_t[1]=b
    rgb_t[3]=r
    gpu.setForeground(tonumber(rgbToHex(rgb_t)))
    table.insert(px_t, 1, rgb_t)
    rgb_t={}
  end
end
local l = 1
local pc_w, pc_h = gpu.getResolution()
gpu.fill(1, 1, pc_w, pc_h, " ")
for k=2, h+1 do
  for j=1, w do
    gpu.setBackground(tonumber(rgbToHex(px_t[l])))
    gpu.setForeground(tonumber(rgbToHex(px_t[l])))
    gpu.set(j, k, "X")
    l=l+1
  end
end

img:close()
