-- True Range's settings window, in the game (its key, settings_key): each setting a spinner,
-- taking effect as it's changed, kept on this computer (true_range/settings).

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local Settings = require "true_range/settings"

-- (two columns: what's drawn on the left, how solid and the key on the right - option.col)
local LABEL_W, SPINNER_W, GAP = 215, 195, 50
local COL_W = LABEL_W + SPINNER_W + 10
-- (the game's curly window is at most 1000 by 500, drawn at .7 with its frame round it: measured on
-- a picture of it at 500 high, its inside runs from 310 above the middle to 267 below, the title
-- down to about 265, the buttons up to about -217. Rows from 255 down, the hint under them, clear
-- of the buttons)
local WIN_W, WIN_H = 1000, 500
local ROWS_TOP, ROWS_BOTTOM, HINT_H = 255, -160, 44

local SettingsScreen = Class(Screen, function(self)
    Screen._ctor(self, "TrueRangeSettingsScreen")

    -- (round it, darkened: a click there closes it)
    local black = self:AddChild(ImageButton("images/global.xml", "square.tex"))
    black.image:SetVRegPoint(ANCHOR_MIDDLE)
    black.image:SetHRegPoint(ANCHOR_MIDDLE)
    black.image:SetVAnchor(ANCHOR_MIDDLE)
    black.image:SetHAnchor(ANCHOR_MIDDLE)
    black.image:SetScaleMode(SCALEMODE_FILLSCREEN)
    black.image:SetTint(0, 0, 0, .5)
    black:SetOnClick(function() self:Close() end)
    black:SetHelpTextMessage("")

    local root = self:AddChild(Widget("root"))
    root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    root:SetHAnchor(ANCHOR_MIDDLE)
    root:SetVAnchor(ANCHOR_MIDDLE)
    self.root = root

    local cols = { {}, {} }
    for _, o in ipairs(Settings.OPTIONS) do
        local c = cols[o.col or 1]
        c[#c + 1] = o
    end
    local n = math.max(#cols[1], #cols[2])
    local ROW_H = math.min(52, (ROWS_TOP - ROWS_BOTTOM) / n)
    self.window = root:AddChild(TEMPLATES.CurlyWindow(WIN_W, WIN_H, "True Range+", {
        { text = "Reset", cb = function() self:Reset() end },
        { text = "Done", cb = function() self:Close() end },
    }, nil, nil))

    -- (what the setting under the mouse does)
    self.hint = root:AddChild(Text(CHATFONT, 20, "", UICOLOURS.GREY))
    self.hint:SetPosition(0, ROWS_TOP - n * ROW_H - HINT_H / 2 - 4)
    self.hint:SetRegionSize(2 * COL_W + GAP, HINT_H)
    self.hint:EnableWordWrap(true)

    self.rows = {}
    local top = ROWS_TOP - ROW_H / 2
    local grid = { {}, {} }
    for c, list in ipairs(cols) do
        local x = (c == 1 and -1 or 1) * (COL_W + GAP) / 2
        for i, o in ipairs(list) do
            local row = root:AddChild(TEMPLATES.LabelSpinner(o.label, o.choices, LABEL_W, SPINNER_W, 40, 10, CHATFONT, 24, nil,
                function(data) Settings.Set(o.name, data) end))
            row:SetPosition(x, top - (i - 1) * ROW_H)
            row.spinner:SetSelected(Settings.Get(o.name))
            row.spinner.ongainfocusfn = function() self.hint:SetString(o.hover or "") end
            row.OnGainFocus = function() self.hint:SetString(o.hover or "") end
            self.rows[#self.rows + 1] = { option = o, row = row }
            grid[c][i] = row
        end
    end
    -- (up and down in a column, left and right across, with a controller)
    for c, list in ipairs(grid) do
        local other = grid[3 - c]
        for i, row in ipairs(list) do
            if i > 1 then row:SetFocusChangeDir(MOVE_UP, list[i - 1]) end
            if i < #list then row:SetFocusChangeDir(MOVE_DOWN, list[i + 1]) end
            local across = other[math.min(i, #other)]
            if across ~= nil then row:SetFocusChangeDir(c == 1 and MOVE_RIGHT or MOVE_LEFT, across) end
        end
    end
    self.default_focus = grid[1][1]
end)

function SettingsScreen:Reset()
    Settings.Reset()
    for _, r in ipairs(self.rows) do r.row.spinner:SetSelected(Settings.Get(r.option.name)) end
end

function SettingsScreen:Close()
    TheFrontEnd:PopScreen(self)
end

function SettingsScreen:OnControl(control, down)
    if SettingsScreen._base.OnControl(self, control, down) then
        return true
    end
    if not down and (control == CONTROL_MENU_BACK or control == CONTROL_CANCEL) then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
        self:Close()
        return true
    end
    return false
end

function SettingsScreen:GetHelpText()
    local controller_id = TheInput:GetControllerID()
    return TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK
end

return SettingsScreen
