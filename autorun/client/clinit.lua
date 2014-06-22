timer.Simple(.1,function()
	include("sh.lua")
	include("cl.lua")
	include("cl_cmd.lua")
end)
function surface.CreateLegacyFont(font, size, weight, antialias, additive, name, shadow, outline, blursize)
	surface.CreateFont(name, {font = font, size = size, weight = weight, antialias = antialias, additive = additive, shadow = shadow, outline = outline, blursize = blursize})
end

local fontfamily = "Typenoksidi"
local fontfamily3d = "hidden"
local fontweight = 0
local fontweight3D = 0
local fontaa = true
local fontshadow = false
local fontoutline = true

-- surface.CreateLegacyFont("csd", 42, 500, true, false, "healthsign", false, true)
-- surface.CreateLegacyFont("tahoma", 96, 1000, true, false, "zshintfont", false, true)

-- surface.CreateLegacyFont(fontfamily3d, 48, fontweight3D, false, false,  "ZS3D2DFontSmall", false, true)
-- surface.CreateLegacyFont(fontfamily3d, 72, fontweight3D, false, false, "ZS3D2DFont", false, true)
surface.CreateLegacyFont(fontfamily3d, 64, fontweight3D, false, false, "StrangeCounter", true, true)
surface.CreateLegacyFont(fontfamily3d, 20, fontweight3D, false, false, "StrangeCounterHUD", true, true)