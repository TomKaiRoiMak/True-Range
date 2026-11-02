-- True Range's settings window, in the game (its key, settings_key): each setting a spinner,
-- taking effect as it's changed, kept on this computer (true_range/settings).

local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local TEMPLATES = require "widgets/redux/templates"

local Settings = require "true_range/settings"

-- (rows packed closer - 13 of them, the window must fit a small screen)
local ROW_H = 38
local WIDTH, LABEL_W, SPINNER_W = 560, 250, 220

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

    local n = #Settings.OPTIONS
    -- (room for the rows, then the hint under them, then the buttons on the bottom edge)
    local height = n * ROW_H + 150
    self.window = root:AddChild(TEMPLATES.CurlyWindow(WIDTH, height, "True Range+", {
        { text = "Reset", cb = function() self:Reset() end },
        { text = "Done", cb = function() self:Close() end },
    }, nil, nil))

    -- (what the setting under the mouse does)
    self.hint = root:AddChild(Text(CHATFONT, 20, "", UICOLOURS.GREY))
    self.hint:SetPosition(0, height / 2 - 60 - n * ROW_H - 10)
    self.hint:SetRegionSize(WIDTH, 50)
    self.hint:EnableWordWrap(true)

    self.rows = {}
    local top = height / 2 - 60
    for i, o in ipairs(Settings.OPTIONS) do
        local row = root:AddChild(TEMPLATES.LabelSpinner(o.label, o.choices, LABEL_W, SPINNER_W, 34, 10, CHATFONT, 24, nil,
            function(data) Settings.Set(o.name, data) end))
        row:SetPosition(0, top - (i - 1) * ROW_H)
        row.spinner:SetSelected(Settings.Get(o.name))
        row.spinner.ongainfocusfn = function() self.hint:SetString(o.hover or "") end
        row.OnGainFocus = function() self.hint:SetString(o.hover or "") end
        self.rows[i] = { option = o, row = row }
    end
    -- (up and down between them with a controller)
    for i, r in ipairs(self.rows) do
        if i > 1 then r.row:SetFocusChangeDir(MOVE_UP, self.rows[i - 1].row) end
        if i < #self.rows then r.row:SetFocusChangeDir(MOVE_DOWN, self.rows[i + 1].row) end
    end
    self.default_focus = self.rows[1] ~= nil and self.rows[1].row or nil
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
