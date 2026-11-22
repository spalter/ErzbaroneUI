ErzbaroneUI = ErzbaroneUI or {}

-- Change these RGB multipliers to tint all neutral artwork; 1, 1, 1 keeps it silver.
ErzbaroneUI.NeutralArt = { Tint = { 1, 1, 1 } }

local colors = setmetatable({}, { __mode = "k" })

--- Compares vertex colors with tolerance for rounding by the texture API.
local function SameColor(r, g, b, a, color)
    return math.abs(r - color[1]) < 0.00001
        and math.abs(g - color[2]) < 0.00001
        and math.abs(b - color[3]) < 0.00001
        and math.abs(a - color[4]) < 0.00001
end

--- Multiplies a texture's original RGB by the shared tint while preserving alpha.
--- Remembers the untinted color so repeated HUD and panel refreshes do not compound it.
function ErzbaroneUI.NeutralArt:ApplyTint(texture)
    local r, g, b, a = texture:GetVertexColor()
    local state = colors[texture]
    if not state or not SameColor(r, g, b, a, state.applied) then
        state = { original = { r, g, b, a } }
        colors[texture] = state
    end
    local original, tint = state.original, self.Tint
    local tinted = { original[1] * tint[1], original[2] * tint[2], original[3] * tint[3], original[4] }
    state.applied = tinted
    if not SameColor(r, g, b, a, tinted) then
        texture:SetVertexColor(tinted[1], tinted[2], tinted[3], tinted[4])
    end
end

--- Restores the saved vertex color when it still matches this module's applied tint.
--- Leaves subsequent native or addon color changes intact.
function ErzbaroneUI.NeutralArt:RestoreTint(texture)
    local state = colors[texture]
    if not state then
        return
    end
    colors[texture] = nil
    local r, g, b, a = texture:GetVertexColor()
    if SameColor(r, g, b, a, state.applied) and not SameColor(r, g, b, a, state.original) then
        local original = state.original
        texture:SetVertexColor(original[1], original[2], original[3], original[4])
    end
end
