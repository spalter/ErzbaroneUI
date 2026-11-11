local root = (... or ".") .. "\\"

dofile(root .. "modules\\config.lua")

local toc = assert(io.open(root .. "ErzbaroneUI.toc", "r"))
local metadata = toc:read("*a")
toc:close()
local callbackName = assert(metadata:match("## AddonCompartmentFunc:%s*([%w_]+)"),
    "Missing AddOns menu callback metadata")
local callback = assert(_G[callbackName], "AddOns menu callback is not a global function")

local categoryID = 42
ErzbaroneUI.Config.Category = {
    GetID = function() return categoryID end,
}

local openedCategories = {}
Settings = {
    OpenToCategory = function(id)
        openedCategories[#openedCategories + 1] = id
    end,
}

callback("ErzbaroneUI", "LeftButton")
assert(#openedCategories == 1 and openedCategories[1] == categoryID,
    "Left-clicking the AddOns entry must open the registered settings category")

categoryID = 73
callback("ErzbaroneUI", "RightButton")
assert(#openedCategories == 2 and openedCategories[2] == categoryID,
    "Right-clicking the AddOns entry must open the current settings category")

print("AddOns menu integration tests passed")
