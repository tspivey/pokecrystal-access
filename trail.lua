module ( "trail", package.seeall )

function direction(x, y, destx, desty)
local s = ""
if y > desty then
s = y-desty .. " up"
elseif y < desty then
s = desty-y .. " down"
end
if x > destx then
s = s .. " " .. x-destx .. " left"
elseif x < destx then
s = s .. " " .. destx-x .. " right"
end
return s
end

function only_direction(x, y, destx, desty)
local s = ""
if y > desty then
return "up"
elseif y < desty then
return "down"
elseif x > destx then
return "left"
elseif x < destx then
return "right"
end
return s
end

