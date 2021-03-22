local shell = require("shell")
local filesystem = require("filesystem")
local internet = require("internet")
local component = require("component")
local computer = require("computer")
local term = require("term")
local pull = require('event').pull
local gpu = component.gpu

local args, ops = shell.parse(...)


function rgbToHex(rgb)
  if rgb == nil then return '0X000000' end
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
local extrabytes=((res-54)-w*h*3)/h --не спрашивайте зачем, так надо
local rgb_t = {}
local px_t = {}
print("Loading picture...")
local upt=computer.uptime()
for i=1, res-54-extrabytes*h do
  local byte_to_int=string.unpack(">B", img:read(1))
  table.insert(rgb_t, 1, byte_to_int)
  if(i%(w*3)==0) then
    img:read(extrabytes)
  end
  if(#rgb_t==3) then
    table.insert(px_t, 1, rgb_t)
    rgb_t={}
  end
  if computer.uptime()>=upt+4 then --при обработке больших картинок цикл должен иногда спать (иначе TLWY)
	os.sleep()
	upt=computer.uptime()
  end
end
term.clear()
local l = 1
for k=1, math.ceil(h/2) do
  for j=1, w do
    gpu.setForeground(tonumber(rgbToHex(px_t[l]))) --передней части символа задаем цвет пикселя с нечетной строки
	gpu.setBackground(tonumber(rgbToHex(px_t[l+w]))) --задней части символа задаем цвет пикселя с четной строки
    gpu.set(w-j+1, k, "▀") --рисуем два пикселя в одном символе
    l=l+1
  end
  l=l+w --перескакиваем на другую нечетную строку
end

img:close()
pull('key_down')
