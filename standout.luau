_G.StandOutParts = {}
_G.StandOutParts.Library = function()
if Instance == nil then
	local rgb = Color3.fromRGB
	local function createMatchaLibrary()
		assert(type(Drawing) == "table" and type(Drawing.new) == "function", "lazyhub requires Matcha Drawing")
		local previous = _G.Library
		if type(previous) == "table" and previous.IsMatcha and not previous.Unloaded then
			previous:Unload()
		end

		local library = {
			IsMatcha = true, Visible = false, MouseCaptured = false, CaptureInput = false, Unloaded = false,
			RenderCount = 0, LastRenderError = nil, FireOnChanged = false, Name = "Lazynoria",
			FontColor = rgb(224, 224, 224), MainColor = rgb(31, 31, 31),
			BackgroundColor = rgb(25, 25, 25), AccentColor = rgb(133, 76, 164),
			HoverColor = rgb(43, 43, 43), OutlineColor = rgb(50, 50, 50),
			RiskColor = rgb(255, 80, 80), MutedColor = rgb(147, 147, 147),
			DisabledColor = rgb(108, 108, 108),
			Toggles = {}, Options = {}, Signals = {}, Objects = {}, UnloadCallbacks = {}, ToggleKeybind = 163,
		}
		local state = {
			mouseX = 0, mouseY = 0, leftDown = false, clickArmed = false, inputActive = false, primePending = true,
			keys = {}, focus = nil, focusSource = nil, popup = nil, popupOffset = 0, popupCursor = 1,
			drag = nil, regions = {}, focusable = {}, caps = false,
			repeatKey = nil, repeatAt = 0, notification = nil, hoverTooltip = nil,
		}
		local keyNames = {
			RightControl = 163,
			LeftControl = 162,
			RightShift = 161,
			LeftShift = 160,
			RightAlt = 165,
			LeftAlt = 164,
			Space = 32,
			Return = 13,
			Enter = 13,
			Tab = 9,
			Escape = 27,
			Backspace = 8,
			Insert = 45,
			Delete = 46,
			Home = 36,
			End = 35,
			PageUp = 33,
			PageDown = 34,
			Left = 37,
			Up = 38,
			Right = 39,
			Down = 40,
			One = 49,
			Two = 50,
			Three = 51,
			Four = 52,
			Five = 53,
			Six = 54,
			Seven = 55,
			Eight = 56,
			Nine = 57,
			Zero = 48,
		}
		local inputKeys = {
			8,
			9,
			13,
			20,
			27,
			32,
			33,
			34,
			35,
			36,
			37,
			38,
			39,
			40,
			46,
			186,
			187,
			188,
			189,
			190,
			191,
			192,
			219,
			220,
			221,
			222,
		}
		for key = 48, 90 do
			if key <= 57 or key >= 65 then
				inputKeys[#inputKeys + 1] = key
			end
		end

		local function keyDown(key)
			if type(iskeypressed) == "function" then
				local ok, value = pcall(iskeypressed, key)
				return ok and (value == true or value == 1)
			end
			return false
		end
		local function mouseDown()
			local down = keyDown(1)
			if type(ismouse1pressed) == "function" then
				local ok, value = pcall(ismouse1pressed)
				down = down or ok and (value == true or value == 1)
			end
			return down
		end
		local function getToggleKey()
			local toggle = library.ToggleKeybind
			return type(toggle) == "number" and toggle
				or type(toggle) == "string" and (keyNames[toggle] or (#toggle == 1 and string.byte(toggle:upper())))
				or type(toggle) == "table" and (keyNames[toggle.Value] or (#tostring(toggle.Value) == 1 and string.byte(
					tostring(toggle.Value):upper()
				)))
				or 163
		end
		local function primeInput(down, toggledDown)
			state.leftDown = down
			state.toggleDown = toggledDown
			state.clickArmed = not down
			state.drag = nil
			state.repeatKey = nil
			for _, key in ipairs(inputKeys) do
				state.keys[key] = keyDown(key)
			end
			state.keys[162] = keyDown(162)
			state.keys[163] = keyDown(163)
			state.primePending = false
		end
		local function call(callback, value)
			if type(callback) == "function" then
				local ok, problem = pcall(callback, value)
				if not ok then
					warn("[lazyhub] " .. tostring(problem))
					library:Notify("Control failed: " .. tostring(problem), 5)
				end
			end
		end
		local function changed(control)
			call(control.Callback, control.Value)
			call(control.Changed, control.Value)
		end
		local function contains(values, value)
			for _, candidate in ipairs(values) do
				if candidate == value then
					return true
				end
			end
			return false
		end
		local function clamp(value, low, high)
			return math.max(low, math.min(high, value))
		end
		local function hit(rect, x, y)
			return rect and x >= rect.x and y >= rect.y and x <= rect.x + rect.w and y <= rect.y + rect.h
		end
		local function rectangle(x, y, width, height)
			return { x = x, y = y, w = width, h = height }
		end
		local function object(kind)
			local draw = Drawing.new(kind)
			draw.Visible = false
			draw.Transparency = 1
			draw.ZIndex = 20
			if kind == "Square" then
				draw.Filled = true
				draw.Rounding = 3
			elseif kind == "Text" then
				draw.Font = 5
				draw.Size = 13
				draw.Outline = false
				draw.Color = library.FontColor
			end
			library.Objects[#library.Objects + 1] = draw
			return draw
		end
		local function square(draw, x, y, width, height, color, filled, zIndex)
			if width <= 0 or height <= 0 then
				return
			end
			draw.Position = Vector2.new(x, y)
			draw.Size = Vector2.new(width, height)
			draw.Color = color
			draw.Filled = filled ~= false
			draw.Thickness = 1
			draw.ZIndex = zIndex or (filled == false and 22 or 20)
			draw.Visible = true
		end
		local function shortText(value, width, fontSize)
			local text = tostring(value or "")
			local count = math.max(1, math.floor(width / (fontSize * 0.59)))
			if #text > count then
				return text:sub(1, math.max(1, count - 3)) .. "..."
			end
			return text
		end
		local function text(draw, value, x, y, size, color, width, zIndex)
			draw.Text = width and shortText(value, width, size) or tostring(value or "")
			draw.Position = Vector2.new(x, y)
			draw.Size = size
			draw.Color = color or library.FontColor
			draw.ZIndex = zIndex or 40
			draw.Visible = true
		end
		local function wrap(value, columns, maxLines)
			local result = {}
			for paragraph in (tostring(value or "") .. "\n"):gmatch("(.-)\n") do
				local line = ""
				for word in paragraph:gmatch("%S+") do
					if #line + #word + 1 > columns and #line > 0 then
						result[#result + 1] = line
						line = word
					else
						line = line == "" and word or line .. " " .. word
					end
				end
				result[#result + 1] = line
			end
			if maxLines and #result > maxLines then
				while #result > maxLines do
					table.remove(result)
				end
				result[#result] = shortText(result[#result], columns * 8, 13)
			end
			return result
		end
		local function region(rect, action, control, tooltip)
			state.regions[#state.regions + 1] = { rect = rect, action = action, control = control, tooltip = tooltip }
		end
		local function commitInput(control, cancel)
			if not control or control.Type ~= "Input" then
				return
			end
			if not cancel and control.Buffer ~= nil then
				control:SetValue(control.Buffer)
			end
			control.Buffer = nil
		end
		local function setFocus(control, source)
			if control and control.Type ~= "Input" and source ~= "keyboard" then
				control = nil
			end
			if state.focus ~= control then
				commitInput(state.focus, false)
			end
			state.focus = control
			state.focusSource = control and (source or "pointer") or nil
			state.repeatKey = nil
			if control and control.Type == "Input" then
				control.Buffer = tostring(control.Value or "")
			end
		end
		local function clearInput()
			commitInput(state.focus, false)
			state.focus = nil
			state.focusSource = nil
			state.popup = nil
			state.popupRect = nil
			state.popupCursor = 1
			state.drag = nil
			state.repeatKey = nil
			library.MouseCaptured = false
		end
		function library:Notify(message, seconds)
			state.notification = { text = tostring(message), expires = tick() + (tonumber(seconds) or 4) }
		end
		function library:OnUnload(callback)
			assert(type(callback) == "function", "OnUnload requires a callback")
			self.UnloadCallbacks[#self.UnloadCallbacks + 1] = callback
			return self
		end
		function library:Unload()
			if self.Unloaded then
				return
			end
			self.Unloaded = true
			self.Visible = false
			clearInput()
			for _, connection in ipairs(self.Signals) do
				pcall(function()
					connection:Disconnect()
				end)
			end
			for _, draw in ipairs(self.Objects) do
				pcall(function()
					draw:Remove()
				end)
			end
			for _, callback in ipairs(self.UnloadCallbacks) do
				call(callback)
			end
			self.Signals = {}
			self.Objects = {}
			if type(setrobloxinput) == "function" then
				pcall(setrobloxinput, true)
			end
		end
		function library:Toggle(value)
			if self.Unloaded then
				return
			end
			local wasVisible = self.Visible
			if type(value) == "boolean" then
				self.Visible = value
			else
				self.Visible = not self.Visible
			end
			if not self.Visible then
				clearInput()
			elseif not wasVisible then
				state.primePending = true
				state.clickArmed = false
			end
			if type(setrobloxinput) == "function" then
				pcall(setrobloxinput, not (self.CaptureInput and self.Visible))
			end
			return self.Visible
		end
		function library:SetInputCapture(enabled)
			if self.Unloaded then
				return false
			end
			self.CaptureInput = enabled == true
			if type(setrobloxinput) == "function" then
				pcall(setrobloxinput, not (self.CaptureInput and self.Visible))
			end
			return self.CaptureInput
		end
		function library:Show()
			return self:Toggle(true)
		end
		function library:Hide()
			return self:Toggle(false)
		end
		function library:GetTextBounds(value, _, size)
			return #tostring(value or "") * (size or 13) * 0.59, size or 13
		end
		function library:SafeCallback(callback, value)
			call(callback, value)
		end

		local function makeControl(group, kind, id, info)
			info = info or {}
			local control = {
				Type = kind,
				Id = id,
				Text = tostring(info.Text or id or ""),
				Group = group,
				Callback = info.Callback or info.Func,
				Disabled = info.Disabled == true,
				Tooltip = info.Tooltip or info.Reason,
				Info = info,
				Value = info.Default,
				Draw = {},
				Height = kind == "Slider" and 49
					or (kind == "Dropdown" or kind == "Input") and 52
					or kind == "Label" and 23
					or 32,
			}
			function control:OnChanged(callback)
				self.Changed = callback
				if library.FireOnChanged then
					call(callback, self.Value)
				end
				return self
			end
			function control:SetDisabled(disabled, reason)
				self.Disabled = disabled == true
				if reason ~= nil then
					self.Tooltip = tostring(reason)
				end
				if self.Disabled and self.Type == "Toggle" and self.Value then
					self:SetValue(false)
				end
				return self
			end
			function control:SetText(value)
				self.Text = tostring(value or "")
				self.WrapCache = nil
				return self
			end
			function control:SetValue(value)
				local nextValue = value
				if self.Type == "Toggle" then
					nextValue = value == true and not self.Disabled
				elseif self.Type == "Slider" then
					assert(
						type(value) == "number" and value == value and math.abs(value) < math.huge,
						"Slider value must be a finite number"
					)
					local factor = 10 ^ self.Rounding
					nextValue = math.floor(clamp(value, self.Min, self.Max) * factor + 0.5) / factor
				elseif self.Type == "Dropdown" then
					if self.Multi then
						nextValue = {}
						if type(value) == "table" then
							for key, selected in pairs(value) do
								local candidate = type(key) == "number" and selected or key
								if contains(self.Values, candidate) and (type(key) == "number" or selected == true) then
									nextValue[candidate] = true
								end
							end
						end
						local same = true
						for candidate, selected in pairs(self.Value or {}) do
							if selected == true and nextValue[candidate] ~= true then
								same = false
								break
							end
						end
						for candidate, selected in pairs(nextValue) do
							if selected == true and (not self.Value or self.Value[candidate] ~= true) then
								same = false
								break
							end
						end
						if same then
							return self
						end
					else
						nextValue = type(value) == "number" and self.Values[value] or value
						if nextValue ~= nil and not contains(self.Values, nextValue) then
							return self
						end
					end
				elseif self.Type == "Input" then
					nextValue = tostring(value or "")
					if self.Info.Numeric and nextValue ~= "" and tonumber(nextValue) == nil then
						return self
					end
					if self.Info.MaxLength then
						nextValue = nextValue:sub(1, self.Info.MaxLength)
					end
				end
				if self.Value ~= nextValue then
					self.Value = nextValue
					changed(self)
				end
				return self
			end
			function control:SetValues(values)
				assert(type(values) == "table", "Dropdown Values must be a table")
				self.Values = values
				if self.Multi then
					self:SetValue(self.Value or {})
				elseif not contains(values, self.Value) then
					self:SetValue(values[1])
				end
				state.popupOffset = 0
				if state.popup == self then
					state.popupCursor = table.find(values, self.Value) or 1
				end
				return self
			end
			function control:Press()
				if not self.Disabled then
					call(self.Callback)
				end
				return self
			end
			function control:EnsureDrawings()
				if self.Draw.label then
					return
				end
				self.Draw.label = object("Text")
				if self.Type ~= "Label" and self.Type ~= "Divider" then
					self.Draw.back = object("Square")
					self.Draw.border = object("Square")
					self.Draw.value = object("Text")
					self.Draw.fill = object("Square")
					self.Draw.focus = object("Square")
				elseif self.Type == "Divider" then
					self.Draw.back = object("Square")
				end
				if self.Type == "Label" then
					self.Draw.lines = {}
					for _ = 1, 5 do
						self.Draw.lines[#self.Draw.lines + 1] = object("Text")
					end
				elseif self.Type == "Dropdown" then
					self.Draw.arrow = object("Text")
				elseif self.Type == "Slider" then
					self.Draw.knob = object("Square")
				end
			end
			if kind == "Toggle" then
				control.Value = info.Default == true and not control.Disabled
				library.Toggles[id] = control
			elseif kind == "Slider" then
				assert(
					type(info.Min) == "number" and type(info.Max) == "number" and info.Max > info.Min,
					"Slider needs Min < Max"
				)
				control.Min, control.Max, control.Rounding = info.Min, info.Max, tonumber(info.Rounding) or 0
				control.Value = nil
				control.Callback = nil
				control:SetValue(tonumber(info.Default) or info.Min)
				control.Callback = info.Callback
				library.Options[id] = control
			elseif kind == "Dropdown" then
				assert(type(info.Values) == "table", "Dropdown needs Values")
				control.Values, control.Multi = info.Values, info.Multi == true
				control.Value = control.Multi and {} or nil
				control.Callback = nil
				control:SetValue(info.Default ~= nil and info.Default or (control.Multi and {} or info.Values[1]))
				control.Callback = info.Callback
				library.Options[id] = control
			elseif kind == "Input" then
				control.Value = tostring(info.Default or "")
				library.Options[id] = control
			end
			group.Controls[#group.Controls + 1] = control
			return control
		end
		local function makeGroup(tab, title, side)
			local group = { Name = tostring(title), Side = side, Controls = {}, Tab = tab, Draw = {} }
			function group:AddToggle(id, info)
				return makeControl(self, "Toggle", id, info)
			end
			function group:AddSlider(id, info)
				return makeControl(self, "Slider", id, info)
			end
			function group:AddDropdown(id, info)
				return makeControl(self, "Dropdown", id, info)
			end
			function group:AddInput(id, info)
				return makeControl(self, "Input", id, info)
			end
			function group:AddLabel(value, wrapped)
				local info = type(value) == "table" and value or { Text = value, Wrap = wrapped }
				return makeControl(self, "Label", nil, info)
			end
			function group:AddButton(value, callback)
				local info = type(value) == "table" and value or { Text = value, Func = callback }
				return makeControl(self, "Button", nil, info)
			end
			function group:AddDivider()
				local control = makeControl(self, "Divider", nil, {})
				control.Height = 12
				return control
			end
			tab.Groups[side][#tab.Groups[side] + 1] = group
			return group
		end
		local function makeTab(window, name)
			local tab = { Name = tostring(name), Groups = { {}, {} }, Scroll = { 0, 0 }, Content = { 0, 0 }, Draw = {} }
			function tab:AddLeftGroupbox(title)
				return makeGroup(self, title, 1)
			end
			function tab:AddRightGroupbox(title)
				return makeGroup(self, title, 2)
			end
			function tab:Show()
				window.ActiveTab = self
				clearInput()
				return self
			end
			window.Tabs[#window.Tabs + 1] = tab
			window.TabsByName[tab.Name] = tab
			window.ActiveTab = window.ActiveTab or tab
			return tab
		end
		function library:Scroll(amount, side)
			local window = self.Window
			local tab = window and window.ActiveTab
			if tab then
				side = side or (state.mouseX > window.x + window.width / 2 and 2 or 1)
				local height = window.paneHeight or 1
				tab.Scroll[side] =
					clamp(tab.Scroll[side] + amount, 0, math.max(0, tab.Content[side] - height / window.scale))
			end
		end

		local function displayValue(control)
			if control.Multi then
				local selected = {}
				for _, value in ipairs(control.Values) do
					if control.Value[value] then
						selected[#selected + 1] = tostring(value)
					end
				end
				return #selected > 0 and table.concat(selected, ", ") or "None"
			end
			return control.Value ~= nil and tostring(control.Value) or "None"
		end
		local function movePopupCursor(index)
			local control = state.popup
			if not control or #control.Values == 0 then return end
			local count = math.min(8, #control.Values)
			state.popupCursor = clamp(index, 1, #control.Values)
			if state.popupCursor <= state.popupOffset then
				state.popupOffset = state.popupCursor - 1
			elseif state.popupCursor > state.popupOffset + count then
				state.popupOffset = state.popupCursor - count
			end
			state.popupOffset = clamp(state.popupOffset, 0, math.max(0, #control.Values - count))
		end
		local function pagePopup(amount)
			local control = state.popup
			if not control then return end
			local count = math.min(8, #control.Values)
			state.popupOffset = clamp(state.popupOffset + amount, 0, math.max(0, #control.Values - count))
			state.popupCursor = clamp(state.popupCursor, state.popupOffset + 1, state.popupOffset + count)
		end
		local function selectPopup(control, value, source)
			if value == nil or control.Disabled then return end
			if source ~= "keyboard" then setFocus(nil) end
			if control.Multi then
				local values = {}
				for candidate, selected in pairs(control.Value) do values[candidate] = selected end
				values[value] = not values[value]
				control:SetValue(values)
			else
				control:SetValue(value)
				state.popup = nil
				state.popupRect = nil
			end
		end
		local function activate(control, source)
			if not control or control.Disabled then
				return
			end
			setFocus(control, source)
			if control.Type == "Toggle" then
				control:SetValue(not control.Value)
			elseif control.Type == "Button" then
				control:Press()
			elseif control.Type == "Dropdown" then
				state.popup = state.popup == control and nil or control
				state.popupOffset = 0
				state.popupCursor = table.find(control.Values, control.Value) or 1
				if state.popup then movePopupCursor(state.popupCursor) end
			elseif control.Type == "Input" then
				control.Buffer = tostring(control.Value or "")
			end
		end
		local function renderControl(control, x, y, width, scale)
			control:EnsureDrawings()
			local draw = control.Draw
			local font = math.max(12, math.floor(13 * scale + 0.5))
			local rowHeight = control.Height * scale
			local color = control.Disabled and library.DisabledColor or library.FontColor
			control.Rect = rectangle(x, y, width, rowHeight)
			if not control.Disabled and control.Type ~= "Label" and control.Type ~= "Divider" then
				state.focusable[#state.focusable + 1] = control
			end
			if control.Type == "Toggle" then
				square(
					draw.back,
					x,
					y + 7 * scale,
					16 * scale,
					16 * scale,
					control.Value and library.AccentColor or library.BackgroundColor
				)
				square(draw.border, x, y + 7 * scale, 16 * scale, 16 * scale, library.OutlineColor, false)
				if control.Value then
					text(draw.value, "x", x + 3 * scale, y + 5 * scale, font, library.FontColor)
				end
				text(draw.label, control.Text, x + 24 * scale, y + 7 * scale, font, color, width - 25 * scale)
				region(control.Rect, function()
					activate(control)
				end, control, control.Tooltip)
			elseif control.Type == "Slider" then
				text(draw.label, control.Text, x, y + 2 * scale, font, color, width * 0.7)
				text(
					draw.value,
					string.format("%." .. control.Rounding .. "f", control.Value),
					x + width - 55 * scale,
					y + 2 * scale,
					font,
					color,
					55 * scale
				)
				local track = rectangle(x, y + 25 * scale, width, 11 * scale)
				control.Track = track
				square(draw.back, track.x, track.y, track.w, track.h, library.BackgroundColor)
				square(draw.border, track.x, track.y, track.w, track.h, library.OutlineColor, false, 22)
				local ratio = (control.Value - control.Min) / (control.Max - control.Min)
				square(
					draw.fill,
					track.x + 1,
					track.y + 1,
					math.max(1, (track.w - 2) * ratio),
					track.h - 2,
					control.Disabled and library.DisabledColor or library.AccentColor,
					true,
					21
				)
				square(draw.knob, track.x + clamp(track.w * ratio - 4 * scale, 0, track.w - 8 * scale),
					track.y - 2 * scale, 8 * scale, track.h + 4 * scale,
					control.Disabled and library.DisabledColor or library.FontColor, true, 23)
				region(control.Rect, function()
					if not control.Disabled then
						setFocus(control)
						state.drag = { kind = "slider", control = control }
					end
				end, control, control.Tooltip)
			elseif control.Type == "Dropdown" or control.Type == "Input" then
				text(draw.label, control.Text, x, y + 2 * scale, font, color, width)
				local box = rectangle(x, y + 22 * scale, width, 24 * scale)
				control.Box = box
				square(
					draw.back,
					box.x,
					box.y,
					box.w,
					box.h,
					hit(box, state.mouseX, state.mouseY) and not control.Disabled and library.HoverColor
						or library.BackgroundColor
				)
				square(
					draw.border,
					box.x,
					box.y,
					box.w,
					box.h,
					(state.popup == control or control.Type == "Input" and state.focus == control) and library.AccentColor or library.OutlineColor,
					false
				)
				local value = control.Type == "Input" and (control.Buffer or control.Value) or displayValue(control)
				if control.Type == "Input" and state.focus == control then
					value = value .. (math.floor(tick() * 2) % 2 == 0 and "|" or "")
				end
				text(
					draw.value,
					value,
					box.x + 6 * scale,
					box.y + 5 * scale,
					font,
					color,
					box.w - (control.Type == "Dropdown" and 27 or 12) * scale
				)
				if control.Type == "Dropdown" then
					text(draw.label, control.Text, x, y + 2 * scale, font, color, width)
					text(draw.arrow, "v", box.x + box.w - 17 * scale, box.y + 5 * scale, font, color)
				end
				region(control.Rect, function()
					activate(control)
				end, control, control.Tooltip)
			elseif control.Type == "Button" then
				local box = rectangle(x, y + 2 * scale, width, 26 * scale)
				square(
					draw.back,
					box.x,
					box.y,
					box.w,
					box.h,
					hit(box, state.mouseX, state.mouseY) and not control.Disabled and library.HoverColor
						or library.BackgroundColor
				)
				square(draw.border, box.x, box.y, box.w, box.h, library.OutlineColor, false)
				text(draw.label, control.Text, box.x + 8 * scale, box.y + 6 * scale, font, color, box.w - 16 * scale)
				region(box, function()
					activate(control)
				end, control, control.Tooltip)
			elseif control.Type == "Divider" then
				square(draw.back, x, y + 5 * scale, width, 1, library.OutlineColor)
			else
				local lines = control.WrapCache or { control.Text }
				for index, line in ipairs(lines) do
					if index <= #draw.lines then
						text(draw.lines[index], line, x, y + (index - 1) * 18 * scale + 2 * scale, font, color, width)
					end
				end
			end
		end
		local function renderPopup(window)
			local control = state.popup
			if not control or not control.Box or control.Disabled then
				return
			end
			local scale = window.scale
			local rowHeight = 26 * scale
			local count = math.min(8, #control.Values)
			if count == 0 then
				state.popup = nil
				return
			end
			local height = (count + 2) * rowHeight + 4 * scale
			local x, y = control.Box.x, control.Box.y + control.Box.h + 3 * scale
			if y + height > window.viewportY - 8 then
				y = control.Box.y - height - 3 * scale
			end
			local width = control.Box.w
			local draw = window.PopupDraw
			state.popupOffset = clamp(state.popupOffset, 0, math.max(0, #control.Values - count))
			state.popupRect = rectangle(x, y, width, height)
			state.popupCursor = clamp(state.popupCursor, 1, #control.Values)
			region(state.popupRect, function() end)
			square(draw.back, x, y, width, height, library.MainColor, true, 80)
			square(draw.border, x, y, width, height, library.AccentColor, false, 81)
			text(
				draw.up,
				state.popupOffset > 0 and "^  Previous" or control.Multi and "Select items" or "Select an option",
				x + 8 * scale,
				y + 6 * scale,
				math.max(12, 13 * scale),
				library.MutedColor,
				width - 16 * scale,
				83
			)
			region(rectangle(x, y, width, rowHeight), function()
				pagePopup(-count)
			end)
			for index = 1, count do
				local value = control.Values[state.popupOffset + index]
				local rowY = y + index * rowHeight
				local rect = rectangle(x + 3 * scale, rowY, width - 6 * scale, rowHeight)
				local selected = control.Multi and control.Value[value] == true
					or not control.Multi and control.Value == value
				local current = state.focusSource == "keyboard" and state.popupCursor == state.popupOffset + index
				square(
					draw.rows[index].back,
					rect.x,
					rect.y,
					rect.w,
					rect.h,
					(hit(rect, state.mouseX, state.mouseY) or current) and library.HoverColor
						or selected and library.BackgroundColor
						or library.MainColor,
					true,
					82
				)
				text(
					draw.rows[index].label,
					(current and "> " or "  ") .. (selected and "[x] " or "[ ] ") .. tostring(value),
					x + 8 * scale,
					rowY + 6 * scale,
					math.max(12, 13 * scale),
					(selected or current) and library.FontColor or library.MutedColor,
					width - 16 * scale,
					83
				)
				region(rect, function()
					state.popupCursor = state.popupOffset + index
					selectPopup(control, value, "pointer")
				end, control)
			end
			text(
				draw.down,
				(state.popupOffset + count < #control.Values and "v  More  |  " or "") .. tostring(state.popupOffset + 1) .. "-" .. tostring(state.popupOffset + count) .. " / " .. tostring(#control.Values),
				x + 8 * scale,
				y + (count + 1) * rowHeight + 6 * scale,
				math.max(12, 13 * scale),
				library.MutedColor,
				width - 16 * scale,
				83
			)
			region(rectangle(x, y + (count + 1) * rowHeight, width, rowHeight), function()
				pagePopup(count)
			end)
		end
		local function render(window)
			for _, draw in ipairs(library.Objects) do
				draw.Visible = false
			end
			state.regions, state.focusable, state.hoverTooltip = {}, {}, nil
			state.popupRect = nil
			local viewport = window.Camera and window.Camera.ViewportSize
			local viewportX, viewportY = viewport and viewport.X or 1920, viewport and viewport.Y or 1080
			if type(viewportX) ~= "number" or viewportX < 320 or type(viewportY) ~= "number" or viewportY < 240 then
				viewportX, viewportY = 1920, 1080
			end
			window.viewportX, window.viewportY = viewportX, viewportY
			local scale =
				math.min(1, (viewportX - 32) / window.requestedWidth, (viewportY - 32) / window.requestedHeight)
			window.scale = scale
			window.width, window.height = window.requestedWidth * scale, window.requestedHeight * scale
			if not window.x then
				window.x, window.y =
					math.floor((viewportX - window.width) / 2), math.floor((viewportY - window.height) / 2)
			end
			window.x = clamp(window.x, 8, math.max(8, viewportX - window.width - 8))
			window.y = clamp(window.y, 8, math.max(8, viewportY - window.height - 8))
			if library.Visible then
				local x, y, width, height = window.x, window.y, window.width, window.height
				local draw = window.Draw
				square(draw.shadow, x + 5, y + 5, width, height, rgb(12, 12, 12), true, 5)
				square(draw.outer, x, y, width, height, library.BackgroundColor, true, 6)
				square(draw.border, x, y, width, height, library.OutlineColor, false, 7)
				square(draw.accent, x + 1, y + 1, width - 2, 2 * scale, library.AccentColor, true, 8)
				square(draw.header, x + 1, y + 4 * scale, width - 2, 37 * scale, library.MainColor, true, 8)
				text(
					draw.title,
					window.Title,
					x + 14 * scale,
					y + 13 * scale,
					math.max(13, 15 * scale),
					library.FontColor,
					width - 85 * scale
				)
				text(
					draw.close,
					"x",
					x + width - 28 * scale,
					y + 12 * scale,
					math.max(13, 15 * scale),
					library.MutedColor
				)
				region(rectangle(x + width - 39 * scale, y + 5 * scale, 36 * scale, 33 * scale), function()
					library:Toggle(false)
				end)
				region(rectangle(x + 4 * scale, y + 5 * scale, width - 48 * scale, 35 * scale), function()
					setFocus(nil)
					state.drag = { kind = "window", mouseX = state.mouseX, mouseY = state.mouseY, x = x, y = y }
				end)
				local tabX = x + 12 * scale
				for _, tab in ipairs(window.Tabs) do
					if not tab.Draw.label then
						tab.Draw.label, tab.Draw.back, tab.Draw.accent =
							object("Text"), object("Square"), object("Square")
					end
					local tabWidth = math.max(65, #tab.Name * 8 + 22) * scale
					if tabX + tabWidth < x + width - 8 * scale then
						local active = window.ActiveTab == tab
						local rect = rectangle(tabX, y + 47 * scale, tabWidth, 29 * scale)
						square(
							tab.Draw.back,
							rect.x,
							rect.y,
							rect.w,
							rect.h,
							active and library.MainColor or library.BackgroundColor
						)
						text(
							tab.Draw.label,
							tab.Name,
							tabX + 10 * scale,
							y + 54 * scale,
							math.max(12, 13 * scale),
							active and library.FontColor or library.MutedColor,
							tabWidth - 20 * scale
						)
						if active then
							square(
								tab.Draw.accent,
								rect.x,
								rect.y + rect.h - 2 * scale,
								rect.w,
								2 * scale,
								library.AccentColor,
								true,
								21
							)
						end
						region(rect, function()
							tab:Show()
						end)
						tabX = tabX + tabWidth + 4 * scale
					end
				end
				local paneY, paneHeight = y + 88 * scale, height - 121 * scale
				local paneWidth = (width - 42 * scale) / 2
				window.paneHeight = paneHeight
				local tab = window.ActiveTab
				if tab then
					for side = 1, 2 do
						local paneX = x + (side == 1 and 12 * scale or width / 2 + 5 * scale)
						local pane = rectangle(paneX, paneY, paneWidth, paneHeight)
						local logicalHeight = 0
						for _, group in ipairs(tab.Groups[side]) do
							if not group.Draw.back then
								group.Draw.back, group.Draw.border, group.Draw.title =
									object("Square"), object("Square"), object("Text")
							end
							group.Height = 34
							for _, control in ipairs(group.Controls) do
								if control.Type == "Label" and control.Info.Wrap then
									local lines = control.WrapCache
									if not lines or control.WrapWidth ~= math.floor(paneWidth / scale) then
										lines = wrap(
											control.Text,
											math.max(10, math.floor((paneWidth / scale - 30) / 7.7)),
											5
										)
										control.WrapCache = lines
										control.WrapWidth = math.floor(paneWidth / scale)
									end
									control.Height = #lines * 18 + 6
								end
								group.Height = group.Height + control.Height
							end
							logicalHeight = logicalHeight + group.Height + 12
						end
						tab.Content[side] = logicalHeight
						tab.Scroll[side] = clamp(tab.Scroll[side], 0, math.max(0, logicalHeight - paneHeight / scale))
						local groupY = paneY - tab.Scroll[side] * scale
						for _, group in ipairs(tab.Groups[side]) do
							local groupBottom = groupY + group.Height * scale
							local clippedY, clippedBottom =
								math.max(paneY, groupY), math.min(paneY + paneHeight, groupBottom)
							if clippedBottom > clippedY then
								square(
									group.Draw.back,
									paneX,
									clippedY,
									paneWidth,
									clippedBottom - clippedY,
									library.MainColor,
									true,
									10
								)
								square(
									group.Draw.border,
									paneX,
									clippedY,
									paneWidth,
									clippedBottom - clippedY,
									library.OutlineColor,
									false,
									11
								)
								if groupY >= paneY and groupY + 25 * scale <= paneY + paneHeight then
									text(
										group.Draw.title,
										group.Name,
										paneX + 11 * scale,
										groupY + 9 * scale,
										math.max(12, 13 * scale),
										library.FontColor,
										paneWidth - 25 * scale
									)
								end
								local rowY = groupY + 29 * scale
								for _, control in ipairs(group.Controls) do
									if rowY >= paneY and rowY + control.Height * scale <= paneY + paneHeight then
										renderControl(control, paneX + 11 * scale, rowY, paneWidth - 24 * scale, scale)
									end
									rowY = rowY + control.Height * scale
								end
							end
							groupY = groupBottom + 12 * scale
						end
						local scrollDraw = window.ScrollDraw[side]
						if logicalHeight > paneHeight / scale then
							local track = rectangle(
								paneX + paneWidth + 2 * scale,
								paneY + 22 * scale,
								7 * scale,
								paneHeight - 44 * scale
							)
							square(scrollDraw.back, track.x, track.y, track.w, track.h, library.MainColor)
							local thumbHeight = math.max(24 * scale, track.h * (paneHeight / scale) / logicalHeight)
							local maxScroll = logicalHeight - paneHeight / scale
							local thumb = rectangle(
								track.x,
								track.y + (track.h - thumbHeight) * tab.Scroll[side] / maxScroll,
								track.w,
								thumbHeight
							)
							square(scrollDraw.thumb, thumb.x, thumb.y, thumb.w, thumb.h, library.AccentColor, true, 21)
							text(
								scrollDraw.up,
								"^",
								paneX + paneWidth + scale,
								paneY,
								math.max(12, 13 * scale),
								library.MutedColor
							)
							text(
								scrollDraw.down,
								"v",
								paneX + paneWidth + scale,
								paneY + paneHeight - 18 * scale,
								math.max(12, 13 * scale),
								library.MutedColor
							)
							region(rectangle(track.x - 3 * scale, paneY, 14 * scale, 22 * scale), function()
								library:Scroll(-120, side)
							end)
							region(
								rectangle(track.x - 3 * scale, paneY + paneHeight - 22 * scale, 14 * scale, 22 * scale),
								function()
									library:Scroll(120, side)
								end
							)
							region(rectangle(track.x - 3 * scale, track.y, 14 * scale, track.h), function()
								state.drag = {
									kind = "scroll",
									side = side,
									track = track,
									thumbHeight = thumbHeight,
									startY = state.mouseY,
									startOffset = tab.Scroll[side],
									maxScroll = maxScroll,
								}
							end)
						end
					end
				end
				text(
					draw.footer,
					"MATCHA  |  RIGHT CTRL: MENU  |  PGUP / PGDN: SCROLL",
					x + 13 * scale,
					y + height - 23 * scale,
					math.max(12, 12 * scale),
					library.MutedColor,
					width - 26 * scale
				)
				renderPopup(window)
			end
			if state.notification and state.notification.expires > tick() then
				local noteWidth, noteHeight = math.min(430, viewportX - 32), 76
				local noteX, noteY = viewportX - noteWidth - 18, viewportY - noteHeight - 18
				square(window.NoticeDraw.back, noteX, noteY, noteWidth, noteHeight, library.MainColor, true, 90)
				square(window.NoticeDraw.border, noteX, noteY, noteWidth, noteHeight, library.AccentColor, false, 91)
				local lines = wrap(state.notification.text, math.floor((noteWidth - 22) / 7.7), 3)
				for index, line in ipairs(lines) do
					text(
						window.NoticeDraw.lines[index],
						line,
						noteX + 11,
						noteY + 11 + (index - 1) * 18,
						13,
						library.FontColor,
						noteWidth - 22,
						92
					)
				end
			end
		end
		local function typeKey(key)
			local control = state.focus
			if not control or control.Type ~= "Input" then
				return
			end
			local value = control.Buffer or tostring(control.Value or "")
			if key == 8 then
				value = value:sub(1, math.max(0, #value - 1))
			elseif key == 46 then
				value = ""
			else
				local shifted = keyDown(160) or keyDown(161) or keyDown(16)
				local character
				if key >= 65 and key <= 90 then
					character = string.char(key)
					if shifted == state.caps then
						character = character:lower()
					end
				elseif key >= 48 and key <= 57 then
					character = shifted and (")!@#$%^&*("):sub(key - 47, key - 47) or string.char(key)
				elseif key == 32 then
					character = " "
				else
					local plain = {
						[186] = ";",
						[187] = "=",
						[188] = ",",
						[189] = "-",
						[190] = ".",
						[191] = "/",
						[192] = "'",
						[219] = "[",
						[220] = "\\",
						[221] = "]",
						[222] = "'",
					}
					local upper = {
						[186] = ":",
						[187] = "+",
						[188] = "<",
						[189] = "_",
						[190] = ">",
						[191] = "?",
						[192] = "~",
						[219] = "{",
						[220] = "|",
						[221] = "}",
						[222] = '"',
					}
					character = shifted and upper[key] or plain[key]
				end
				if character and (not control.Info.Numeric or character:match("[%d%.%-]")) then
					value = value .. character
				end
			end
			control.Buffer = control.Info.MaxLength and value:sub(1, control.Info.MaxLength) or value
			if not control.Info.Finished then
				control:SetValue(control.Buffer)
			end
		end
		local function pressKey(key)
			if key == 20 then
				state.caps = not state.caps
				return
			end
			if key == 27 then
				if state.popup then
					state.popup = nil
					state.popupRect = nil
				elseif state.focus and state.focus.Type == "Input" then
					commitInput(state.focus, true)
				end
				setFocus(nil)
				return
			end
			if key == 9 then
				state.popup = nil
				state.popupRect = nil
				local position = table.find(state.focusable, state.focus) or 0
				local direction = (keyDown(160) or keyDown(161) or keyDown(16)) and -1 or 1
				if #state.focusable > 0 then
					setFocus(state.focusable[(position - 1 + direction) % #state.focusable + 1], "keyboard")
				end
				return
			end
			if state.focus and state.focus.Type == "Input" then
				if key == 13 then
					commitInput(state.focus, false)
					setFocus(nil)
				else
					typeKey(key)
				end
				return
			end
			if key == 32 then return end
			if key == 33 or key == 34 then
				if state.popup then
					state.focusSource = "keyboard"
					movePopupCursor(state.popupCursor + (key == 33 and -8 or 8))
				else
					setFocus(nil)
					library:Scroll(key == 33 and -250 or 250)
				end
				return
			end
			local control = state.focus
			if state.popup then
				if key == 38 or key == 40 then
					state.focusSource = "keyboard"
					movePopupCursor(state.popupCursor + (key == 38 and -1 or 1))
				elseif key == 36 or key == 35 then
					state.focusSource = "keyboard"
					movePopupCursor(key == 36 and 1 or #state.popup.Values)
				elseif key == 13 then
					selectPopup(state.popup, state.popup.Values[state.popupCursor], "keyboard")
				end
			elseif control and control.Type == "Slider" and (key == 37 or key == 39) then
				control:SetValue(control.Value + (key == 37 and -1 or 1) * 10 ^ -control.Rounding)
			elseif key == 13 and state.focusSource == "keyboard" then
				activate(control, "keyboard")
			end
		end
		local function poll(window)
			local mouse = window.Mouse
			if mouse and type(mouse.X) == "number" and type(mouse.Y) == "number" then
				state.mouseX, state.mouseY = mouse.X, mouse.Y
			end
			local active = true
			if type(isrbxactive) == "function" then
				local ok, value = pcall(isrbxactive)
				active = ok and value == true
			end
			local toggledDown = keyDown(getToggleKey())
			local down = mouseDown()
			local regainedFocus = active and not state.inputActive
			state.inputActive = active
			if not active or regainedFocus or state.primePending then
				clearInput()
				primeInput(down, toggledDown)
				library.MouseCaptured = false
				return
			end
			if active and toggledDown and not state.toggleDown then
				library:Toggle()
			end
			state.toggleDown = toggledDown
			if state.primePending then
				primeInput(down, toggledDown)
				library.MouseCaptured = false
				return
			end
			if not down then
				state.clickArmed = true
			end
			library.MouseCaptured = library.Visible
					and active
					and (hit(
						rectangle(window.x or 0, window.y or 0, window.width or 0, window.height or 0),
						state.mouseX,
						state.mouseY
					) or hit(state.popupRect, state.mouseX, state.mouseY) or state.focus ~= nil or state.drag ~= nil)
				or false
			if library.Visible and active then
				if down and not state.leftDown and state.clickArmed then
					state.clickArmed = false
					setFocus(nil)
					if
						state.popup
						and not hit(state.popupRect, state.mouseX, state.mouseY)
						and not hit(state.popup.Box, state.mouseX, state.mouseY)
					then
						state.popup = nil
						state.popupRect = nil
					else
						local handled = false
						for index = #state.regions, 1, -1 do
							local entry = state.regions[index]
							if hit(entry.rect, state.mouseX, state.mouseY) then
								if not entry.control or not entry.control.Disabled then
									entry.action()
								elseif entry.tooltip then
									library:Notify(entry.tooltip, 4)
								end
								handled = true
								break
							end
						end
						if not handled then
							setFocus(nil)
						end
					end
				end
				if down and state.drag then
					local drag = state.drag
					if drag.kind == "window" then
						window.x, window.y = drag.x + state.mouseX - drag.mouseX, drag.y + state.mouseY - drag.mouseY
					elseif drag.kind == "slider" then
						local track = drag.control.Track
						drag.control:SetValue(
							drag.control.Min
								+ clamp((state.mouseX - track.x) / track.w, 0, 1)
									* (drag.control.Max - drag.control.Min)
						)
					elseif drag.kind == "scroll" and window.ActiveTab then
						window.ActiveTab.Scroll[drag.side] = clamp(
							drag.startOffset
								+ (state.mouseY - drag.startY)
									/ math.max(1, drag.track.h - drag.thumbHeight)
									* drag.maxScroll,
							0,
							drag.maxScroll
						)
					end
				elseif not down then
					state.drag = nil
				end
				for _, key in ipairs(inputKeys) do
					local pressed = keyDown(key)
					if pressed and not state.keys[key] then
						pressKey(key)
						if state.focus and state.focus.Type == "Input" and (key == 8 or key >= 32) then
							state.repeatKey, state.repeatAt = key, tick() + 0.45
						end
					elseif not pressed and state.repeatKey == key then
						state.repeatKey = nil
					end
					state.keys[key] = pressed
				end
				if state.repeatKey and tick() >= state.repeatAt then
					typeKey(state.repeatKey)
					state.repeatAt = tick() + 0.065
				end
			else
				state.drag = nil
				state.repeatKey = nil
				for _, key in ipairs(inputKeys) do
					state.keys[key] = keyDown(key)
				end
			end
			state.leftDown = down
		end
		function library:CreateWindow(info)
			assert(not self.Unloaded, "lazyhub was unloaded; load the library again")
			assert(not self.Window, "Matcha lazyhub supports one window per library")
			info = type(info) == "table" and info or { Title = tostring(info or self.Name) }
			local player = game:GetService("Players").LocalPlayer
			local camera = game.Workspace:FindFirstChild("Camera")
			local size = info.Size
			local width = type(info.Width) == "number" and info.Width or size and size.X or 780
			local height = type(info.Height) == "number" and info.Height or size and size.Y or 690
			if type(width) ~= "number" then
				width = 780
			end
			if type(height) ~= "number" then
				height = 690
			end
			local window = {
				Title = tostring(info.Title or self.Name),
				requestedWidth = math.max(520, width),
				requestedHeight = math.max(400, height),
				Tabs = {},
				TabsByName = {},
				ActiveTab = nil,
				scale = 1,
				Camera = camera,
				Mouse = player and player:GetMouse(),
				Draw = {},
				ScrollDraw = {},
				PopupDraw = {},
				NoticeDraw = {},
			}
			if info.Position and type(info.Position.X) == "number" then
				window.x, window.y = info.Position.X, info.Position.Y
			end
			for _, name in ipairs({ "shadow", "outer", "border", "accent", "header" }) do
				window.Draw[name] = object("Square")
			end
			for _, name in ipairs({ "title", "close", "footer" }) do
				window.Draw[name] = object("Text")
			end
			for side = 1, 2 do
				window.ScrollDraw[side] =
					{ back = object("Square"), thumb = object("Square"), up = object("Text"), down = object("Text") }
			end
			window.PopupDraw = {
				back = object("Square"),
				border = object("Square"),
				up = object("Text"),
				down = object("Text"),
				rows = {},
			}
			for _ = 1, 8 do
				window.PopupDraw.rows[#window.PopupDraw.rows + 1] = { back = object("Square"), label = object("Text") }
			end
			window.NoticeDraw = { back = object("Square"), border = object("Square"), lines = {} }
			for _ = 1, 3 do
				window.NoticeDraw.lines[#window.NoticeDraw.lines + 1] = object("Text")
			end
			function window:AddTab(name)
				return self.TabsByName[tostring(name)] or makeTab(self, name)
			end
			function window:SetTitle(title)
				self.Title = tostring(title)
			end
			function window:Show()
				return library:Show()
			end
			function window:Hide()
				return library:Hide()
			end
			function window:Toggle(value)
				return library:Toggle(value)
			end
			self.Window = window
			self:Toggle(info.AutoShow ~= false)
			primeInput(mouseDown(), keyDown(getToggleKey()))
			state.primePending = true
			local connection = game:GetService("RunService").RenderStepped:Connect(function()
				if self.Unloaded or self.LastRenderError ~= nil then
					return
				end
				local fullWindow = self.Visible and window.ActiveTab ~= nil
				local ok, problem = pcall(function()
					render(window)
					poll(window)
				end)
				if not ok then
					self.LastRenderError = tostring(problem)
					warn("[lazyhub Drawing] " .. self.LastRenderError)
					if type(notify) == "function" then
						pcall(notify, "lazyhub", "Drawing UI failed: " .. self.LastRenderError, 8)
					end
					task.spawn(function()
						task.wait()
						self:Unload()
					end)
				elseif fullWindow then
					self.RenderCount = self.RenderCount + 1
				end
			end)
			self.Signals[#self.Signals + 1] = connection
			local inputService = game:GetService("UserInputService")
			self.Signals[#self.Signals + 1] = inputService.InputBegan:Connect(function(input)
				if self.Unloaded or self.LastRenderError ~= nil or not state.inputActive or input.KeyCode ~= getToggleKey() then return end
				local active = true
				if type(isrbxactive) == "function" then
					local ok, value = pcall(isrbxactive)
					active = ok and value == true
				end
				if active and not state.toggleDown then
					state.toggleDown = true
					self:Toggle()
				end
			end)
			self.Signals[#self.Signals + 1] = inputService.InputEnded:Connect(function(input)
				if input.KeyCode == getToggleKey() then state.toggleDown = false end
			end)
			return window
		end
		function library:SelfTest()
			local count = 0
			local tab = { Groups = { {}, {} } }
			local group = makeGroup(tab, "test", 1)
			local toggle = group:AddToggle("__MatchaSelfTestToggle", {
				Text = "test",
				Callback = function()
					count = count + 1
				end,
			})
			toggle:SetValue(true)
			toggle:SetValue(true)
			assert(toggle.Value == true and count == 1, "Toggle must fire once per change")
			toggle:SetDisabled(true, "unavailable")
			assert(toggle.Value == false and count == 2, "Disabling an active toggle must release it")
			toggle:SetValue(true)
			assert(toggle.Value == false, "Unavailable toggle must stay disabled")
			local slider = group:AddSlider(
				"__MatchaSelfTestSlider",
				{ Text = "test", Min = 0, Max = 100, Default = 50, Rounding = 0 }
			)
			slider:SetValue(300)
			assert(slider.Value == 100, "Slider must clamp")
			slider:SetValue(-1)
			assert(slider.Value == 0, "Slider must clamp negative values")
			local dropdown = group:AddDropdown(
				"__MatchaSelfTestDropdown",
				{ Text = "test", Values = { "Damage", "Ability", "Health" }, Default = 2 }
			)
			assert(dropdown.Value == "Ability", "Dropdown must accept numeric defaults")
			dropdown:SetValues({ "Damage", "Health" })
			assert(dropdown.Value == "Damage", "Dropdown must discard removed values")
			local multiple = group:AddDropdown(
				"__MatchaSelfTestMulti",
				{ Text = "test", Values = { "A", "B" }, Multi = true, Default = { A = true } }
			)
			assert(multiple.Value.A == true and not multiple.Value.B, "Multi dropdown must preserve selected values")
			multiple:SetValues({ "B" })
			assert(multiple.Value.A == nil, "Multi dropdown must discard removed selections")
			local label = group:AddLabel("before")
			label:SetText("after")
			assert(label.Text == "after", "Label updates must reach display state")
			library.Toggles.__MatchaSelfTestToggle = nil
			for _, key in ipairs({ "__MatchaSelfTestSlider", "__MatchaSelfTestDropdown", "__MatchaSelfTestMulti" }) do
				library.Options[key] = nil
			end
			assert(keyNames.RightControl == 163 and keyNames.Space == 32, "Input must use Windows VK codes")
			return true
		end
		_G.Library, _G.Toggles, _G.Options = library, library.Toggles, library.Options
		return library
	end
	local matchaLibrary = createMatchaLibrary()
	return matchaLibrary
end

local InputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RenderStepped = RunService.RenderStepped
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local ScreenGui = Instance.new("ScreenGui")
ProtectGui(ScreenGui)

ScreenGui.Name = "Lazynoria"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10000
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

local Toggles = {}
local Options = {}

getgenv().Toggles = Toggles
getgenv().Options = Options

local Library = {
	Registry = {},
	RegistryMap = {},

	HudRegistry = {},

	FontColor = Color3.fromRGB(224, 224, 224),
	MainColor = Color3.fromRGB(31, 31, 31),
	BackgroundColor = Color3.fromRGB(25, 25, 25),
	AccentColor = Color3.fromRGB(133, 76, 164),
	HoverColor = Color3.fromRGB(43, 43, 43),
	Name = "Lazynoria",
	Features = {},
	FireOnChanged = false,
	OutlineColor = Color3.fromRGB(50, 50, 50),
	RiskColor = Color3.fromRGB(255, 50, 50),

	Black = Color3.new(0, 0, 0),
	Font = Enum.Font.Code,

	OpenedFrames = {},
	DependencyBoxes = {},

	Signals = {},
	ScreenGui = ScreenGui,
}

local RainbowStep = 0
local Hue = 0

table.insert(
	Library.Signals,
	RenderStepped:Connect(function(Delta)
		RainbowStep = RainbowStep + Delta

		if RainbowStep >= (1 / 60) then
			RainbowStep = 0

			Hue = Hue + (1 / 400)

			if Hue > 1 then
				Hue = 0
			end

			Library.CurrentRainbowHue = Hue
			Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1)
		end
	end)
)

local function GetPlayersString()
	local PlayerList = Players:GetPlayers()

	for i = 1, #PlayerList do
		PlayerList[i] = PlayerList[i].Name
	end

	table.sort(PlayerList, function(str1, str2)
		return str1 < str2
	end)

	return PlayerList
end

local function GetTeamsString()
	local TeamList = Teams:GetTeams()

	for i = 1, #TeamList do
		TeamList[i] = TeamList[i].Name
	end

	table.sort(TeamList, function(str1, str2)
		return str1 < str2
	end)

	return TeamList
end

function Library:SafeCallback(f, ...)
	if not f then
		return
	end

	if not Library.NotifyOnError then
		return f(...)
	end

	local success, event = pcall(f, ...)

	if not success then
		local _, i = event:find(":%d+: ")

		if not i then
			return Library:Notify(event)
		end

		return Library:Notify(event:sub(i + 1), 3)
	end
end

function Library:AttemptSave()
	if Library.SaveManager then
		Library.SaveManager:Save()
	end
end

function Library:Create(Class, Properties)
	local _Instance = Class

	if type(Class) == "string" then
		_Instance = Instance.new(Class)
	end

	for Property, Value in next, Properties do
		_Instance[Property] = Value
	end

	local parent = _Instance.Parent
	if
		_Instance:IsA("GuiObject")
		and parent
		and parent:FindFirstChildOfClass("UIListLayout")
		and Properties.LayoutOrder == nil
	then
		local order = 0
		for _, child in ipairs(parent:GetChildren()) do
			if child ~= _Instance and child:IsA("GuiObject") then
				order = math.max(order, child.LayoutOrder)
			end
		end
		_Instance.LayoutOrder = order + 1
	end

	return _Instance
end

function Library:RoundSurface(surface, radius, outlined)
	surface.BorderSizePixel = 0
	Library:Create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = surface })
	if outlined then
		local stroke = Library:Create("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = surface.BorderColor3,
			Thickness = 1,
			Parent = surface,
		})
		Library:AddToRegistry(stroke, {
			Color = function()
				return surface.BorderColor3
			end,
		})
		surface:GetPropertyChangedSignal("BorderColor3"):Connect(function()
			stroke.Color = surface.BorderColor3
		end)
	end
end

function Library:OnSurfaceHover(target, surface)
	local overlay = Library:Create("Frame", {
		Name = "SurfaceHover",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = surface.ZIndex,
		Parent = surface,
	})
	local corner = surface:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Clone().Parent = overlay
	end
	local tween
	local function fade(transparency)
		if tween then
			tween:Cancel()
		end
		tween = TweenService:Create(overlay, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = transparency,
		})
		tween:Play()
	end
	target.MouseEnter:Connect(function()
		fade(0.92)
	end)
	target.MouseLeave:Connect(function()
		fade(1)
	end)
	return overlay
end

function Library:ApplyTextStroke(Inst)
	Inst.TextStrokeTransparency = 1
end

function Library:CreateLabel(Properties, IsHud)
	local _Instance = Library:Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Library.Font,
		TextColor3 = Library.FontColor,
		TextSize = 14,
		TextStrokeTransparency = 1,
	})

	Library:ApplyTextStroke(_Instance)

	Library:AddToRegistry(_Instance, {
		TextColor3 = "FontColor",
	}, IsHud)

	return Library:Create(_Instance, Properties)
end

function Library:IsPointerInput(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

function Library:GetPointerPosition(Input)
	if Input and Input.UserInputType == Enum.UserInputType.Touch then
		return Vector2.new(Input.Position.X, Input.Position.Y)
	end
	return Vector2.new(Mouse.X, Mouse.Y)
end

function Library:IsPointerDown(Input)
	if Input.UserInputType == Enum.UserInputType.Touch then
		return Input.UserInputState ~= Enum.UserInputState.End and Input.UserInputState ~= Enum.UserInputState.Cancel
	end
	return InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

function Library:MakeDraggable(Instance, Cutoff)
	Instance.Active = true

	Instance.InputBegan:Connect(function(Input)
		if Library:IsPointerInput(Input) then
			local ObjPos = Library:GetPointerPosition(Input) - Instance.AbsolutePosition

			if ObjPos.Y > (Cutoff or 40) then
				return
			end

			while not Library.Unloaded and Library:IsPointerDown(Input) do
				local Point = Library:GetPointerPosition(Input)
				Instance.Position = UDim2.new(
					0,
					Point.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
					0,
					Point.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
				)

				RenderStepped:Wait()
			end
		end
	end)
end

function Library:AddToolTip(InfoStr, HoverInstance)
	local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14)
	local Tooltip = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,

		Size = UDim2.fromOffset(X + 5, Y + 4),
		ZIndex = 100,
		Parent = Library.ScreenGui,

		Visible = false,
	})

	local Label = Library:CreateLabel({
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.fromOffset(X, Y),
		TextSize = 14,
		Text = InfoStr,
		TextColor3 = Library.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = Tooltip.ZIndex + 1,

		Parent = Tooltip,
	})

	Library:AddToRegistry(Tooltip, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})

	Library:AddToRegistry(Label, {
		TextColor3 = "FontColor",
	})

	local IsHovering = false

	HoverInstance.MouseEnter:Connect(function()
		if Library:MouseIsOverOpenedFrame() then
			return
		end

		IsHovering = true

		Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		Tooltip.Visible = true

		while IsHovering and not Library.Unloaded and HoverInstance.Parent do
			RunService.Heartbeat:Wait()
			Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
		end
	end)

	HoverInstance.MouseLeave:Connect(function()
		IsHovering = false
		Tooltip.Visible = false
	end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
	HighlightInstance.MouseEnter:Connect(function()
		local Reg = Library.RegistryMap[Instance]

		for Property, ColorIdx in next, Properties do
			Instance[Property] = Library[ColorIdx] or ColorIdx

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)

	HighlightInstance.MouseLeave:Connect(function()
		local Reg = Library.RegistryMap[Instance]

		for Property, ColorIdx in next, PropertiesDefault do
			Instance[Property] = Library[ColorIdx] or ColorIdx

			if Reg and Reg.Properties[Property] then
				Reg.Properties[Property] = ColorIdx
			end
		end
	end)
end

function Library:MouseIsOverOpenedFrame(Input)
	for Frame, _ in next, Library.OpenedFrames do
		if Library:IsMouseOverFrame(Frame, Input) then
			return true
		end
	end
end

function Library:IsMouseOverFrame(Frame, Input)
	local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
	local Point = Library:GetPointerPosition(Input)

	if
		Point.X >= AbsPos.X
		and Point.X <= AbsPos.X + AbsSize.X
		and Point.Y >= AbsPos.Y
		and Point.Y <= AbsPos.Y + AbsSize.Y
	then
		return true
	end
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in next, Library.DependencyBoxes do
		Depbox:Update()
	end
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
	return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB
end

function Library:GetTextBounds(Text, Font, Size, Resolution)
	local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
	return Bounds.X, Bounds.Y
end

function Library:GetDarkerColor(Color)
	local H, S, V = Color3.toHSV(Color)
	return Color3.fromHSV(H, S, V / 1.5)
end
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)

function Library:AddToRegistry(Instance, Properties, IsHud)
	local Idx = #Library.Registry + 1
	local Data = {
		Instance = Instance,
		Properties = Properties,
		Idx = Idx,
	}

	table.insert(Library.Registry, Data)
	Library.RegistryMap[Instance] = Data

	if IsHud then
		Data.HudIdx = #Library.HudRegistry + 1
		table.insert(Library.HudRegistry, Data)
	end
end

function Library:RemoveFromRegistry(Instance)
	local Data = Library.RegistryMap[Instance]

	if Data then
		local Last = Library.Registry[#Library.Registry]
		Library.Registry[Data.Idx] = Last
		Last.Idx = Data.Idx
		Library.Registry[#Library.Registry] = nil
		if Data.HudIdx then
			Last = Library.HudRegistry[#Library.HudRegistry]
			Library.HudRegistry[Data.HudIdx] = Last
			Last.HudIdx = Data.HudIdx
			Library.HudRegistry[#Library.HudRegistry] = nil
		end

		Library.RegistryMap[Instance] = nil
	end
end

function Library:UpdateColorsUsingRegistry()
	for Idx, Object in next, Library.Registry do
		for Property, ColorIdx in next, Object.Properties do
			if type(ColorIdx) == "string" then
				Object.Instance[Property] = Library[ColorIdx]
			elseif type(ColorIdx) == "function" then
				Object.Instance[Property] = ColorIdx()
			end
		end
	end
end

function Library:GiveSignal(Signal)
	table.insert(Library.Signals, Signal)
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true

	for Idx = #Library.Signals, 1, -1 do
		local Connection = table.remove(Library.Signals, Idx)
		Connection:Disconnect()
	end

	local callback = Library.UnloadCallback
	Library.UnloadCallback = nil
	if callback then
		local ok, err = pcall(callback)
		if not ok then
			warn(err)
		end
	end

	ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
	Library.UnloadCallback = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
	task.defer(function()
		if not Instance:IsDescendantOf(ScreenGui) then
			Library:RemoveFromRegistry(Instance)
		end
	end)
end))

local BaseAddons = {}

do
	local Funcs = {}

	function Funcs:AddColorPicker(Idx, Info)
		local ToggleLabel = self.TextLabel

		assert(Info.Default, "AddColorPicker: Missing default value.")

		local ColorPicker = {
			Value = Info.Default,
			Transparency = Info.Transparency or 0,
			Type = "ColorPicker",
			Title = type(Info.Title) == "string" and Info.Title or "Color picker",
			Callback = Info.Callback or function(Color) end,
		}

		function ColorPicker:SetHSVFromRGB(Color)
			local H, S, V = Color3.toHSV(Color)

			ColorPicker.Hue = H
			ColorPicker.Sat = S
			ColorPicker.Vib = V
		end

		ColorPicker:SetHSVFromRGB(ColorPicker.Value)

		local DisplayFrame = Library:Create("Frame", {
			BackgroundColor3 = ColorPicker.Value,
			BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(0, 28, 0, 14),
			ZIndex = 6,
			Parent = ToggleLabel,
		})

		local CheckerFrame = Library:Create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(0, 27, 0, 13),
			ZIndex = 5,
			Image = "http://www.roblox.com/asset/?id=12977615774",
			Visible = not not Info.Transparency,
			Parent = DisplayFrame,
		})

		local PickerFrameOuter = Library:Create("Frame", {
			Name = "Color",
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18),
			Size = UDim2.fromOffset(230, Info.Transparency and 271 or 253),
			Visible = false,
			ZIndex = 15,
			Parent = ScreenGui,
		})

		DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			PickerFrameOuter.Position =
				UDim2.fromOffset(DisplayFrame.AbsolutePosition.X, DisplayFrame.AbsolutePosition.Y + 18)
		end)

		local PickerFrameInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 16,
			Parent = PickerFrameOuter,
		})

		local Highlight = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 2),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local SatVibMapOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.new(0, 4, 0, 25),
			Size = UDim2.new(0, 200, 0, 200),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local SatVibMapInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = SatVibMapOuter,
		})

		local SatVibMap = Library:Create("ImageLabel", {
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Image = "rbxassetid://4155801252",
			Parent = SatVibMapInner,
		})

		local CursorOuter = Library:Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 6, 0, 6),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=9619665977",
			ImageColor3 = Color3.new(0, 0, 0),
			ZIndex = 19,
			Parent = SatVibMap,
		})

		local CursorInner = Library:Create("ImageLabel", {
			Size = UDim2.new(0, CursorOuter.Size.X.Offset - 2, 0, CursorOuter.Size.Y.Offset - 2),
			Position = UDim2.new(0, 1, 0, 1),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=9619665977",
			ZIndex = 20,
			Parent = CursorOuter,
		})

		local HueSelectorOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.new(0, 208, 0, 25),
			Size = UDim2.new(0, 15, 0, 200),
			ZIndex = 17,
			Parent = PickerFrameInner,
		})

		local HueSelectorInner = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = HueSelectorOuter,
		})

		local HueCursor = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			AnchorPoint = Vector2.new(0, 0.5),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 1),
			ZIndex = 18,
			Parent = HueSelectorInner,
		})

		local HueBoxOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(4, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			ZIndex = 18,
			Parent = PickerFrameInner,
		})

		local HueBoxInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 18,
			Parent = HueBoxOuter,
		})

		Library:Create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
			}),
			Rotation = 90,
			Parent = HueBoxInner,
		})

		local HueBox = Library:Create("TextBox", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -5, 1, 0),
			Font = Library.Font,
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
			PlaceholderText = "Hex color",
			Text = "#FFFFFF",
			TextColor3 = Library.FontColor,
			TextSize = 14,
			TextStrokeTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 20,
			Parent = HueBoxInner,
		})

		Library:ApplyTextStroke(HueBox)

		local RgbBoxBase = Library:Create(HueBoxOuter:Clone(), {
			Position = UDim2.new(0.5, 2, 0, 228),
			Size = UDim2.new(0.5, -6, 0, 20),
			Parent = PickerFrameInner,
		})

		local RgbBox = Library:Create(RgbBoxBase.Frame:FindFirstChild("TextBox"), {
			Text = "255, 255, 255",
			PlaceholderText = "RGB color",
			TextColor3 = Library.FontColor,
		})

		local TransparencyBoxOuter, TransparencyBoxInner, TransparencyCursor

		if Info.Transparency then
			TransparencyBoxOuter = Library:Create("Frame", {
				BorderColor3 = Color3.new(0, 0, 0),
				Position = UDim2.fromOffset(4, 251),
				Size = UDim2.new(1, -8, 0, 15),
				ZIndex = 19,
				Parent = PickerFrameInner,
			})

			TransparencyBoxInner = Library:Create("Frame", {
				BackgroundColor3 = ColorPicker.Value,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 19,
				Parent = TransparencyBoxOuter,
			})

			Library:AddToRegistry(TransparencyBoxInner, { BorderColor3 = "OutlineColor" })

			Library:Create("ImageLabel", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Image = "http://www.roblox.com/asset/?id=12978095818",
				ZIndex = 20,
				Parent = TransparencyBoxInner,
			})

			TransparencyCursor = Library:Create("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(0, 1, 1, 0),
				ZIndex = 21,
				Parent = TransparencyBoxInner,
			})
		end

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.fromOffset(5, 5),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 14,
			Text = ColorPicker.Title,
			TextWrapped = false,
			ZIndex = 16,
			Parent = PickerFrameInner,
		})

		local ContextMenu = {}
		do
			ContextMenu.Options = {}
			ContextMenu.Container = Library:Create("Frame", {
				BorderColor3 = Color3.new(),
				ZIndex = 14,

				Visible = false,
				Parent = ScreenGui,
			})

			ContextMenu.Inner = Library:Create("Frame", {
				BackgroundColor3 = Library.BackgroundColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 15,
				Parent = ContextMenu.Container,
			})

			Library:Create("UIListLayout", {
				Name = "Layout",
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = ContextMenu.Inner,
			})

			Library:Create("UIPadding", {
				Name = "Padding",
				PaddingLeft = UDim.new(0, 4),
				Parent = ContextMenu.Inner,
			})

			local function updateMenuPosition()
				ContextMenu.Container.Position = UDim2.fromOffset(
					(DisplayFrame.AbsolutePosition.X + DisplayFrame.AbsoluteSize.X) + 4,
					DisplayFrame.AbsolutePosition.Y + 1
				)
			end

			local function updateMenuSize()
				local menuWidth = 60
				for i, label in next, ContextMenu.Inner:GetChildren() do
					if label:IsA("TextLabel") then
						menuWidth = math.max(menuWidth, label.TextBounds.X)
					end
				end

				ContextMenu.Container.Size =
					UDim2.fromOffset(menuWidth + 8, ContextMenu.Inner.Layout.AbsoluteContentSize.Y + 4)
			end

			DisplayFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateMenuPosition)
			ContextMenu.Inner.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMenuSize)

			task.spawn(updateMenuPosition)
			task.spawn(updateMenuSize)

			Library:AddToRegistry(ContextMenu.Inner, {
				BackgroundColor3 = "BackgroundColor",
				BorderColor3 = "OutlineColor",
			})

			function ContextMenu:Show()
				self.Container.Visible = true
			end

			function ContextMenu:Hide()
				self.Container.Visible = false
			end

			function ContextMenu:AddOption(Str, Callback)
				if type(Callback) ~= "function" then
					Callback = function() end
				end

				local Button = Library:CreateLabel({
					Active = false,
					Size = UDim2.new(1, 0, 0, 15),
					TextSize = 13,
					Text = Str,
					ZIndex = 16,
					Parent = self.Inner,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				Library:OnHighlight(Button, Button, { TextColor3 = "AccentColor" }, { TextColor3 = "FontColor" })

				Button.InputBegan:Connect(function(Input)
					if not Library:IsPointerInput(Input) then
						return
					end

					Callback()
				end)
			end

			ContextMenu:AddOption("Copy color", function()
				Library.ColorClipboard = ColorPicker.Value
				Library:Notify("Copied color!", 2)
			end)

			ContextMenu:AddOption("Paste color", function()
				if not Library.ColorClipboard then
					return Library:Notify("You have not copied a color!", 2)
				end
				ColorPicker:SetValueRGB(Library.ColorClipboard)
			end)

			ContextMenu:AddOption("Copy HEX", function()
				pcall(setclipboard, ColorPicker.Value:ToHex())
				Library:Notify("Copied hex code to clipboard!", 2)
			end)

			ContextMenu:AddOption("Copy RGB", function()
				pcall(
					setclipboard,
					table.concat({
						math.floor(ColorPicker.Value.R * 255),
						math.floor(ColorPicker.Value.G * 255),
						math.floor(ColorPicker.Value.B * 255),
					}, ", ")
				)
				Library:Notify("Copied RGB values to clipboard!", 2)
			end)
		end

		Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(Highlight, { BackgroundColor3 = "AccentColor" })
		Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" })

		Library:AddToRegistry(HueBoxInner, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(RgbBoxBase.Frame, { BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor" })
		Library:AddToRegistry(RgbBox, { TextColor3 = "FontColor" })
		Library:AddToRegistry(HueBox, { TextColor3 = "FontColor" })

		local SequenceTable = {}

		for Hue = 0, 1, 0.1 do
			table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
		end

		local HueSelectorGradient = Library:Create("UIGradient", {
			Color = ColorSequence.new(SequenceTable),
			Rotation = 90,
			Parent = HueSelectorInner,
		})

		HueBox.FocusLost:Connect(function(enter)
			if enter then
				local success, result = pcall(Color3.fromHex, HueBox.Text)
				if success and typeof(result) == "Color3" then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(result)
				end
			end

			ColorPicker:Display()
		end)

		RgbBox.FocusLost:Connect(function(enter)
			if enter then
				local r, g, b = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
				if r and g and b then
					ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color3.toHSV(Color3.fromRGB(r, g, b))
				end
			end

			ColorPicker:Display()
		end)

		function ColorPicker:Display()
			ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)
			SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)

			Library:Create(DisplayFrame, {
				BackgroundColor3 = ColorPicker.Value,
				BackgroundTransparency = ColorPicker.Transparency,
				BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
			})

			if TransparencyBoxInner then
				TransparencyBoxInner.BackgroundColor3 = ColorPicker.Value
				TransparencyCursor.Position = UDim2.new(1 - ColorPicker.Transparency, 0, 0, 0)
			end

			CursorOuter.Position = UDim2.new(ColorPicker.Sat, 0, 1 - ColorPicker.Vib, 0)
			HueCursor.Position = UDim2.new(0, 0, ColorPicker.Hue, 0)

			HueBox.Text = "#" .. ColorPicker.Value:ToHex()
			RgbBox.Text = table.concat({
				math.floor(ColorPicker.Value.R * 255),
				math.floor(ColorPicker.Value.G * 255),
				math.floor(ColorPicker.Value.B * 255),
			}, ", ")

			Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
			Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
		end

		function ColorPicker:OnChanged(Func)
			ColorPicker.Changed = Func
			if Library.FireOnChanged then
				Func(ColorPicker.Value)
			end
		end

		function ColorPicker:Show()
			for Frame, Val in next, Library.OpenedFrames do
				if Frame.Name == "Color" then
					Frame.Visible = false
					Library.OpenedFrames[Frame] = nil
				end
			end

			PickerFrameOuter.Visible = true
			Library.OpenedFrames[PickerFrameOuter] = true
		end

		function ColorPicker:Hide()
			PickerFrameOuter.Visible = false
			Library.OpenedFrames[PickerFrameOuter] = nil
		end

		function ColorPicker:SetValue(HSV, Transparency)
			local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

			ColorPicker.Transparency = Transparency or 0
			ColorPicker:SetHSVFromRGB(Color)
			ColorPicker:Display()
		end

		function ColorPicker:SetValueRGB(Color, Transparency)
			ColorPicker.Transparency = Transparency or 0
			ColorPicker:SetHSVFromRGB(Color)
			ColorPicker:Display()
		end

		SatVibMap.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) then
				while not Library.Unloaded and Library:IsPointerDown(Input) do
					local MinX = SatVibMap.AbsolutePosition.X
					local MaxX = MinX + SatVibMap.AbsoluteSize.X
					local MouseX = math.clamp(Library:GetPointerPosition(Input).X, MinX, MaxX)

					local MinY = SatVibMap.AbsolutePosition.Y
					local MaxY = MinY + SatVibMap.AbsoluteSize.Y
					local MouseY = math.clamp(Library:GetPointerPosition(Input).Y, MinY, MaxY)

					ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX)
					ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY))
					ColorPicker:Display()

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		HueSelectorInner.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) then
				while not Library.Unloaded and Library:IsPointerDown(Input) do
					local MinY = HueSelectorInner.AbsolutePosition.Y
					local MaxY = MinY + HueSelectorInner.AbsoluteSize.Y
					local MouseY = math.clamp(Library:GetPointerPosition(Input).Y, MinY, MaxY)

					ColorPicker.Hue = ((MouseY - MinY) / (MaxY - MinY))
					ColorPicker:Display()

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		DisplayFrame.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
				if PickerFrameOuter.Visible then
					ColorPicker:Hide()
				else
					ContextMenu:Hide()
					ColorPicker:Show()
				end
			elseif
				Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame(Input)
			then
				ContextMenu:Show()
				ColorPicker:Hide()
			end
		end)

		if TransparencyBoxInner then
			TransparencyBoxInner.InputBegan:Connect(function(Input)
				if Library:IsPointerInput(Input) then
					while not Library.Unloaded and Library:IsPointerDown(Input) do
						local MinX = TransparencyBoxInner.AbsolutePosition.X
						local MaxX = MinX + TransparencyBoxInner.AbsoluteSize.X
						local MouseX = math.clamp(Library:GetPointerPosition(Input).X, MinX, MaxX)

						ColorPicker.Transparency = 1 - ((MouseX - MinX) / (MaxX - MinX))

						ColorPicker:Display()

						RenderStepped:Wait()
					end

					Library:AttemptSave()
				end
			end)
		end

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) then
				if
					not Library:IsMouseOverFrame(PickerFrameOuter, Input)
					and not Library:IsMouseOverFrame(DisplayFrame, Input)
				then
					ColorPicker:Hide()
				end

				if not Library:IsMouseOverFrame(ContextMenu.Container, Input) then
					ContextMenu:Hide()
				end
			end

			if Input.UserInputType == Enum.UserInputType.MouseButton2 and ContextMenu.Container.Visible then
				if
					not Library:IsMouseOverFrame(ContextMenu.Container, Input)
					and not Library:IsMouseOverFrame(DisplayFrame, Input)
				then
					ContextMenu:Hide()
				end
			end
		end))

		ColorPicker:Display()
		ColorPicker.DisplayFrame = DisplayFrame

		Options[Idx] = ColorPicker

		return self
	end

	function Funcs:AddKeyPicker(Idx, Info)
		local ParentObj = self
		local ToggleLabel = self.TextLabel
		local Container = self.Container

		assert(Info.Default, "AddKeyPicker: Missing default value.")

		local KeyPicker = {
			Value = Info.Default,
			Toggled = false,
			Mode = Info.Mode or "Toggle",
			Type = "KeyPicker",
			Callback = Info.Callback or function(Value) end,
			ChangedCallback = Info.ChangedCallback or function(New) end,

			SyncToggleState = Info.SyncToggleState or false,
		}

		if KeyPicker.SyncToggleState then
			Info.Modes = { "Toggle" }
			Info.Mode = "Toggle"
		end

		local PickOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(0, 28, 0, 15),
			ZIndex = 6,
			Parent = ToggleLabel,
		})

		local PickInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 7,
			Parent = PickOuter,
		})

		Library:AddToRegistry(PickInner, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 13,
			Text = Info.Default,
			TextWrapped = true,
			ZIndex = 8,
			Parent = PickInner,
		})

		local ModeSelectOuter = Library:Create("Frame", {
			BorderColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromOffset(
				ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
				ToggleLabel.AbsolutePosition.Y + 1
			),
			Size = UDim2.new(0, 60, 0, 45 + 2),
			Visible = false,
			ZIndex = 14,
			Parent = ScreenGui,
		})

		ToggleLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			ModeSelectOuter.Position = UDim2.fromOffset(
				ToggleLabel.AbsolutePosition.X + ToggleLabel.AbsoluteSize.X + 4,
				ToggleLabel.AbsolutePosition.Y + 1
			)
		end)

		local ModeSelectInner = Library:Create("Frame", {
			BackgroundColor3 = Library.BackgroundColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 15,
			Parent = ModeSelectOuter,
		})

		Library:AddToRegistry(ModeSelectInner, {
			BackgroundColor3 = "BackgroundColor",
			BorderColor3 = "OutlineColor",
		})

		Library:Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ModeSelectInner,
		})

		local ContainerLabel = Library:CreateLabel({
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.new(1, 0, 0, 18),
			TextSize = 13,
			Visible = false,
			ZIndex = 110,
			Parent = Library.KeybindContainer,
		}, true)

		local Modes = Info.Modes or { "Always", "Toggle", "Hold" }
		local ModeButtons = {}

		for Idx, Mode in next, Modes do
			local ModeButton = {}

			local Label = Library:CreateLabel({
				Active = false,
				Size = UDim2.new(1, 0, 0, 15),
				TextSize = 13,
				Text = Mode,
				ZIndex = 16,
				Parent = ModeSelectInner,
			})

			function ModeButton:Select()
				for _, Button in next, ModeButtons do
					Button:Deselect()
				end

				KeyPicker.Mode = Mode

				Label.TextColor3 = Library.AccentColor
				Library.RegistryMap[Label].Properties.TextColor3 = "AccentColor"

				ModeSelectOuter.Visible = false
			end

			function ModeButton:Deselect()
				KeyPicker.Mode = nil

				Label.TextColor3 = Library.FontColor
				Library.RegistryMap[Label].Properties.TextColor3 = "FontColor"
			end

			Label.InputBegan:Connect(function(Input)
				if Library:IsPointerInput(Input) then
					ModeButton:Select()
					Library:AttemptSave()
				end
			end)

			if Mode == KeyPicker.Mode then
				ModeButton:Select()
			end

			ModeButtons[Mode] = ModeButton
		end

		function KeyPicker:Update()
			if Info.NoUI then
				return
			end

			local State = KeyPicker:GetState()

			ContainerLabel.Text = string.format("[%s] %s (%s)", KeyPicker.Value, Info.Text, KeyPicker.Mode)

			ContainerLabel.Visible = true
			ContainerLabel.TextColor3 = State and Library.AccentColor or Library.FontColor

			Library.RegistryMap[ContainerLabel].Properties.TextColor3 = State and "AccentColor" or "FontColor"

			local YSize = 0
			local XSize = 0

			for _, Label in next, Library.KeybindContainer:GetChildren() do
				if Label:IsA("TextLabel") and Label.Visible then
					YSize = YSize + 18
					if Label.TextBounds.X > XSize then
						XSize = Label.TextBounds.X
					end
				end
			end

			Library.KeybindFrame.Size = UDim2.new(0, math.max(XSize + 10, 210), 0, YSize + 23)
		end

		function KeyPicker:GetState()
			if KeyPicker.Mode == "Always" then
				return true
			elseif KeyPicker.Mode == "Hold" then
				if KeyPicker.Value == "None" then
					return false
				end

				local Key = KeyPicker.Value

				if Key == "MB1" or Key == "MB2" then
					return Key == "MB1" and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
						or Key == "MB2" and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
				else
					return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value])
				end
			else
				return KeyPicker.Toggled
			end
		end

		function KeyPicker:SetValue(Data)
			local Key, Mode = Data[1], Data[2]
			DisplayLabel.Text = Key
			KeyPicker.Value = Key
			ModeButtons[Mode]:Select()
			KeyPicker:Update()
		end

		function KeyPicker:OnClick(Callback)
			KeyPicker.Clicked = Callback
		end

		function KeyPicker:OnChanged(Callback)
			KeyPicker.Changed = Callback
			if Library.FireOnChanged then
				Callback(KeyPicker.Value)
			end
		end

		if ParentObj.Addons then
			table.insert(ParentObj.Addons, KeyPicker)
		end

		function KeyPicker:DoClick()
			if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
				ParentObj:SetValue(not ParentObj.Value)
			end

			Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
			Library:SafeCallback(KeyPicker.Clicked, KeyPicker.Toggled)
		end

		local Picking = false

		PickOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.Touch and not Library:MouseIsOverOpenedFrame(Input) then
				ModeSelectOuter.Visible = not ModeSelectOuter.Visible
			elseif
				Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame(Input)
			then
				Picking = true

				DisplayLabel.Text = ""

				local Break
				local Text = ""

				task.spawn(function()
					while not Break and not Library.Unloaded do
						if Text == "..." then
							Text = ""
						end

						Text = Text .. "."
						DisplayLabel.Text = Text

						wait(0.4)
					end
				end)

				wait(0.2)

				local Event
				Event = InputService.InputBegan:Connect(function(Input)
					local Key

					if Input.UserInputType == Enum.UserInputType.Keyboard then
						Key = Input.KeyCode.Name
					elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Key = "MB1"
					elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
						Key = "MB2"
					end

					if not Key then
						return
					end

					Break = true
					Picking = false

					DisplayLabel.Text = Key
					KeyPicker.Value = Key

					Library:SafeCallback(KeyPicker.ChangedCallback, Input.KeyCode or Input.UserInputType)
					Library:SafeCallback(KeyPicker.Changed, Input.KeyCode or Input.UserInputType)

					Library:AttemptSave()

					Event:Disconnect()
				end)
				Library:GiveSignal(Event)
			elseif
				Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame(Input)
			then
				ModeSelectOuter.Visible = true
			end
		end)

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if not Picking then
				if KeyPicker.Mode == "Toggle" then
					local Key = KeyPicker.Value

					if Key == "MB1" or Key == "MB2" then
						if
							Key == "MB1" and Input.UserInputType == Enum.UserInputType.MouseButton1
							or Key == "MB2" and Input.UserInputType == Enum.UserInputType.MouseButton2
						then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end
					elseif Input.UserInputType == Enum.UserInputType.Keyboard then
						if Input.KeyCode.Name == Key then
							KeyPicker.Toggled = not KeyPicker.Toggled
							KeyPicker:DoClick()
						end
					end
				end

				KeyPicker:Update()
			end

			if Library:IsPointerInput(Input) then
				if
					not Library:IsMouseOverFrame(ModeSelectOuter, Input)
					and not Library:IsMouseOverFrame(PickOuter, Input)
				then
					ModeSelectOuter.Visible = false
				end
			end
		end))

		Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
			if not Picking then
				KeyPicker:Update()
			end
		end))

		KeyPicker:Update()

		Options[Idx] = KeyPicker

		return self
	end

	BaseAddons.__index = Funcs
	BaseAddons.__namecall = function(Table, Key, ...)
		return Funcs[Key](...)
	end
end

local BaseGroupbox = {}

do
	local Funcs = {}

	function Funcs:AddBlank(Size)
		local Groupbox = self
		local Container = Groupbox.Container

		Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Size),
			ZIndex = 1,
			Parent = Container,
		})
	end

	function Funcs:AddLabel(Text, DoesWrap)
		local textSize = 14
		if type(Text) == "table" then
			textSize = Text.Size or 14
			DoesWrap = Text.DoesWrap or Text.Wrapped or DoesWrap
			Text = Text.Text
		end
		Text = tostring(Text or "")
		local Label = {}

		local Groupbox = self
		local Container = Groupbox.Container

		local TextLabel = Library:CreateLabel({
			Size = UDim2.new(1, -4, 0, textSize + 1),
			TextSize = textSize,
			Text = Text,
			TextWrapped = DoesWrap or false,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = Container,
		})

		if not DoesWrap then
			Library:Create("UIListLayout", {
				Padding = UDim.new(0, 4),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = TextLabel,
			})
		end

		Label.TextLabel = TextLabel
		Label.Container = Container
		local lastWidth, lastText
		function Label:SetText(Text)
			if TextLabel.Text ~= Text then
				TextLabel.Text = Text
			end
			if not DoesWrap then
				return
			end
			local width = math.max(1, math.floor(TextLabel.AbsoluteSize.X))
			if width == lastWidth and Text == lastText then
				return
			end
			lastWidth, lastText = width, Text
			local height = select(2, Library:GetTextBounds(Text, Library.Font, textSize, Vector2.new(width, math.huge)))
			if TextLabel.Size.Y.Offset ~= height then
				TextLabel.Size = UDim2.new(1, -4, 0, height)
			end
		end
		if DoesWrap then
			Label:SetText(Text)
			TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if math.max(1, math.floor(TextLabel.AbsoluteSize.X)) ~= lastWidth then
					Label:SetText(TextLabel.Text)
				end
			end)
		end

		if not DoesWrap then
			setmetatable(Label, BaseAddons)
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		return Label
	end

	function Funcs:AddButton(...)
		local Button = {}
		local function ProcessButtonParams(Class, Obj, ...)
			local Props = select(1, ...)
			if type(Props) == "table" then
				Obj.Text = Props.Text
				Obj.Func = Props.Func
				Obj.DoubleClick = Props.DoubleClick
				Obj.Tooltip = Props.Tooltip
			else
				Obj.Text = select(1, ...)
				Obj.Func = select(2, ...)
			end

			assert(type(Obj.Func) == "function", "AddButton: `Func` callback is missing.")
		end

		ProcessButtonParams("Button", Button, ...)

		local Groupbox = self
		local Container = Groupbox.Container

		local function CreateBaseButton(Button)
			local Outer = Library:Create("TextButton", {
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, -4, 0, 22),
				ZIndex = 5,
			})

			local Inner = Library:Create("Frame", {
				BackgroundColor3 = Library.MainColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 6,
				Parent = Outer,
			})

			local Label = Library:CreateLabel({
				Size = UDim2.new(1, 0, 1, 0),
				TextSize = 14,
				Text = Button.Text,
				ZIndex = 7,
				Parent = Inner,
			})

			Library:AddToRegistry(Outer, {
				BorderColor3 = "Black",
			})

			Library:AddToRegistry(Inner, {
				BackgroundColor3 = "MainColor",
				BorderColor3 = "OutlineColor",
			})

			Library:RoundSurface(Outer, 2)
			Outer.BackgroundTransparency = 1
			Library:RoundSurface(Inner, 2, true)
			Library:OnSurfaceHover(Outer, Inner)
			Button.Surface, Button.HoverTarget = Inner, Outer

			return Outer, Inner, Label
		end

		local function InitEvents(Button)
			local function WaitForEvent(event, timeout, validator)
				local bindable = Instance.new("BindableEvent")
				local connection = event:Once(function(...)
					if type(validator) == "function" and validator(...) then
						bindable:Fire(true)
					else
						bindable:Fire(false)
					end
				end)
				task.delay(timeout, function()
					connection:disconnect()
					bindable:Fire(false)
				end)
				return bindable.Event:Wait()
			end

			local function ValidateClick(Input)
				if Library:MouseIsOverOpenedFrame(Input) then
					return false
				end

				if not Library:IsPointerInput(Input) then
					return false
				end

				return true
			end

			Button.Outer.Activated:Connect(function(Input)
				if not ValidateClick(Input) then
					return
				end
				if Button.Locked then
					return
				end

				if Button.DoubleClick then
					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = "AccentColor" })

					Button.Label.TextColor3 = Library.AccentColor
					Button.Label.Text = "Are you sure?"
					Button.Locked = true

					local clicked = WaitForEvent(Button.Outer.Activated, 0.5, ValidateClick)

					Library:RemoveFromRegistry(Button.Label)
					Library:AddToRegistry(Button.Label, { TextColor3 = "FontColor" })

					Button.Label.TextColor3 = Library.FontColor
					Button.Label.Text = Button.Text
					task.defer(rawset, Button, "Locked", false)

					if clicked then
						Library:SafeCallback(Button.Func)
					end

					return
				end

				Library:SafeCallback(Button.Func)
			end)
		end

		Button.Outer, Button.Inner, Button.Label = CreateBaseButton(Button)
		Button.Outer.Parent = Container

		InitEvents(Button)

		function Button:AddTooltip(tooltip)
			if type(tooltip) == "string" then
				Library:AddToolTip(tooltip, self.Outer)
			end
			return self
		end

		function Button:AddButton(...)
			local SubButton = {}

			ProcessButtonParams("SubButton", SubButton, ...)

			self.Outer.Size = UDim2.new(0.5, -2, 0, 22)

			SubButton.Outer, SubButton.Inner, SubButton.Label = CreateBaseButton(SubButton)

			SubButton.Outer.Position = UDim2.new(1, 3, 0, 0)
			SubButton.Outer.Size = UDim2.fromOffset(self.Outer.AbsoluteSize.X - 2, self.Outer.AbsoluteSize.Y)
			SubButton.Outer.Parent = self.Outer

			function SubButton:AddTooltip(tooltip)
				if type(tooltip) == "string" then
					Library:AddToolTip(tooltip, self.Outer)
				end
				return SubButton
			end

			if type(SubButton.Tooltip) == "string" then
				SubButton:AddTooltip(SubButton.Tooltip)
			end

			InitEvents(SubButton)
			return SubButton
		end

		if type(Button.Tooltip) == "string" then
			Button:AddTooltip(Button.Tooltip)
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		return Button
	end

	function Funcs:AddDivider(Text)
		if type(Text) == "string" and Text ~= "" then
			local label = self:AddLabel(Text)
			Library.RegistryMap[label.TextLabel].Properties.TextColor3 = "AccentColor"
			label.TextLabel.TextColor3 = Library.AccentColor
			return label
		end
		local Groupbox = self
		local Container = self.Container

		local Divider = {
			Type = "Divider",
		}

		Groupbox:AddBlank(2)
		local DividerOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 1),
			ZIndex = 5,
			Parent = Container,
		})

		local DividerInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderSizePixel = 0,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = DividerOuter,
		})

		Library:AddToRegistry(DividerOuter, {
			BorderColor3 = "Black",
		})

		Library:AddToRegistry(DividerInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		Groupbox:AddBlank(9)
		Groupbox:Resize()
	end

	function Funcs:AddInput(Idx, Info)
		assert(Info.Text, "AddInput: Missing `Text` string.")

		local Textbox = {
			Value = Info.Default or "",
			Numeric = Info.Numeric or false,
			Finished = Info.Finished or false,
			Type = "Input",
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local InputLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 0, 15),
			TextSize = 14,
			Text = Info.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 5,
			Parent = Container,
		})

		Groupbox:AddBlank(1)

		local TextBoxOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 22),
			ZIndex = 5,
			Parent = Container,
		})

		local TextBoxInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = TextBoxOuter,
		})

		Library:AddToRegistry(TextBoxInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		Library:RoundSurface(TextBoxOuter, 2)
		TextBoxOuter.BackgroundTransparency = 1
		Library:RoundSurface(TextBoxInner, 2, true)
		Library:OnSurfaceHover(TextBoxOuter, TextBoxInner)
		Textbox.Surface, Textbox.HoverTarget = TextBoxInner, TextBoxOuter

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, TextBoxOuter)
		end

		local Container = Library:Create("Frame", {
			BackgroundTransparency = 1,
			ClipsDescendants = true,

			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -5, 1, 0),

			ZIndex = 7,
			Parent = TextBoxInner,
		})

		local Box = Library:Create("TextBox", {
			BackgroundTransparency = 1,

			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(5, 1),

			Font = Library.Font,
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190),
			PlaceholderText = Info.Placeholder or "",

			Text = Info.Default or "",
			ClearTextOnFocus = Info.ClearTextOnFocus == true,
			TextColor3 = Library.FontColor,
			TextSize = 14,
			TextStrokeTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 7,
			Parent = Container,
		})

		Library:ApplyTextStroke(Box)

		function Textbox:SetValue(Text)
			if Info.MaxLength and #Text > Info.MaxLength then
				Text = Text:sub(1, Info.MaxLength)
			end

			if Textbox.Numeric then
				if (not tonumber(Text)) and Text:len() > 0 then
					Text = Textbox.Value
				end
			end

			Textbox.Value = Text
			Box.Text = Text

			Library:SafeCallback(Textbox.Callback, Textbox.Value)
			Library:SafeCallback(Textbox.Changed, Textbox.Value)
		end

		if Textbox.Finished then
			Box.FocusLost:Connect(function(enter)
				if not enter then
					return
				end

				Textbox:SetValue(Box.Text)
				Library:AttemptSave()
			end)
		else
			Box:GetPropertyChangedSignal("Text"):Connect(function()
				Textbox:SetValue(Box.Text)
				Library:AttemptSave()
			end)
		end

		local function Update()
			local PADDING = 2
			local reveal = Container.AbsoluteSize.X

			if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
				Box.Position = UDim2.new(0, PADDING, 0, 0)
			else
				local cursor = Box.CursorPosition
				if cursor ~= -1 then
					local subtext = string.sub(Box.Text, 1, cursor - 1)
					local width =
						TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

					local currentCursorPos = Box.Position.X.Offset + width

					if currentCursorPos < PADDING then
						Box.Position = UDim2.fromOffset(PADDING - width, 0)
					elseif currentCursorPos > reveal - PADDING - 1 then
						Box.Position = UDim2.fromOffset(reveal - width - PADDING - 1, 0)
					end
				end
			end
		end

		task.spawn(Update)

		Box:GetPropertyChangedSignal("Text"):Connect(Update)
		Box:GetPropertyChangedSignal("CursorPosition"):Connect(Update)
		Box.FocusLost:Connect(Update)
		Box.Focused:Connect(Update)

		Library:AddToRegistry(Box, {
			TextColor3 = "FontColor",
		})

		function Textbox:OnChanged(Func)
			Textbox.Changed = Func
			if Library.FireOnChanged then
				Func(Textbox.Value)
			end
		end

		Groupbox:AddBlank(5)
		Groupbox:Resize()

		Options[Idx] = Textbox

		return Textbox
	end

	function Funcs:AddToggle(Idx, Info)
		assert(Info.Text, "AddInput: Missing `Text` string.")

		local Toggle = {
			Value = Info.Default or false,
			Type = "Toggle",

			Callback = Info.Callback or function(Value) end,
			Addons = {},
			Risky = Info.Risky,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local ToggleOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 15),
			BackgroundTransparency = 1,
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(ToggleOuter, {
			BorderColor3 = "Black",
		})

		local ToggleInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.fromOffset(14, 14),
			ZIndex = 6,
			Parent = ToggleOuter,
		})

		Library:AddToRegistry(ToggleInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(1, -23, 0, 14),
			Position = UDim2.fromOffset(20, 0),
			TextSize = 14,
			Text = Info.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 6,
			Parent = ToggleOuter,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 4),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ToggleLabel,
		})

		local ToggleRegion = Library:Create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 8,
			Parent = ToggleOuter,
		})

		local function resizeToggle()
			local addonsWidth = 0
			for _, child in ipairs(ToggleLabel:GetChildren()) do
				if child:IsA("GuiObject") then
					addonsWidth = addonsWidth + child.Size.X.Offset + 4
				end
			end
			ToggleRegion.Size = UDim2.new(1, -addonsWidth, 1, 0)
		end
		ToggleLabel.ChildAdded:Connect(resizeToggle)
		ToggleLabel.ChildRemoved:Connect(resizeToggle)
		resizeToggle()

		Library:RoundSurface(ToggleOuter, 2)
		Library:RoundSurface(ToggleInner, 2, true)
		Library:OnSurfaceHover(ToggleRegion, ToggleInner)
		Toggle.Surface, Toggle.HoverTarget = ToggleInner, ToggleRegion

		function Toggle:UpdateColors()
			Toggle:Display()
		end

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor
			ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor

			Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
			Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and "AccentColorDark"
				or "OutlineColor"
		end

		function Toggle:OnChanged(Func)
			Toggle.Changed = Func
			if Library.FireOnChanged then
				Func(Toggle.Value)
			end
		end

		function Toggle:SetValue(Bool)
			Bool = not not Bool

			Toggle.Value = Bool
			Toggle:Display()

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
					Addon.Toggled = Bool
					Addon:Update()
				end
			end

			Library:SafeCallback(Toggle.Callback, Toggle.Value)
			Library:SafeCallback(Toggle.Changed, Toggle.Value)
			Library:UpdateDependencyBoxes()
		end

		ToggleRegion.Activated:Connect(function(Input)
			if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
				Toggle:SetValue(not Toggle.Value)
				Library:AttemptSave()
			end
		end)

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = "RiskColor" })
		end

		Toggle:Display()
		Groupbox:AddBlank(Info.BlankSize or 5 + 2)
		Groupbox:Resize()

		Toggle.TextLabel = ToggleLabel
		Toggle.Container = Container
		setmetatable(Toggle, BaseAddons)

		Toggles[Idx] = Toggle

		Library:UpdateDependencyBoxes()

		return Toggle
	end

	function Funcs:AddSlider(Idx, Info)
		assert(Info.Default, "AddSlider: Missing default value.")
		assert(Info.Text, "AddSlider: Missing slider text.")
		assert(Info.Min, "AddSlider: Missing minimum value.")
		assert(Info.Max, "AddSlider: Missing maximum value.")
		assert(Info.Rounding, "AddSlider: Missing rounding value.")

		local Slider = {
			Value = Info.Default,
			Min = Info.Min,
			Max = Info.Max,
			Rounding = Info.Rounding,
			MaxSize = 232,
			Type = "Slider",
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		if not Info.Compact then
			Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10),
				TextSize = 14,
				Text = Info.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 5,
				Parent = Container,
			})

			Groupbox:AddBlank(3)
		end

		local SliderOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 18),
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(SliderOuter, {
			BorderColor3 = "Black",
		})

		local SliderInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = SliderOuter,
		})

		Library:AddToRegistry(SliderInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local FillClip = Library:Create("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 7,
			Parent = SliderInner,
		})

		local Fill = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderColor3 = Library.AccentColorDark,
			Size = UDim2.new(0, 0, 1, 0),
			ZIndex = 7,
			Parent = FillClip,
		})

		Library:AddToRegistry(Fill, {
			BackgroundColor3 = "AccentColor",
			BorderColor3 = "AccentColorDark",
		})

		Library:RoundSurface(Fill, 2)

		local DisplayLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 14,
			Text = "Infinite",
			ZIndex = 9,
			Parent = SliderInner,
		})

		Library:RoundSurface(SliderOuter, 2)
		SliderOuter.BackgroundTransparency = 1
		Library:RoundSurface(SliderInner, 2, true)
		Library:OnSurfaceHover(SliderOuter, SliderInner)
		Slider.Surface, Slider.HoverTarget = SliderInner, SliderOuter

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, SliderOuter)
		end

		function Slider:UpdateColors()
			Fill.BackgroundColor3 = Library.AccentColor
			Fill.BorderColor3 = Library.AccentColorDark
		end

		function Slider:Display()
			local Suffix = Info.Suffix or ""

			if Info.Compact then
				DisplayLabel.Text = Info.Text .. ": " .. Slider.Value .. Suffix
			elseif Info.HideMax then
				DisplayLabel.Text = string.format("%s", Slider.Value .. Suffix)
			else
				DisplayLabel.Text = string.format("%s / %s", Slider.Value .. Suffix, Slider.Max .. Suffix)
			end

			local fraction = Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, 1)
			Fill.Size = UDim2.fromScale(fraction > 0 and 1 / fraction or 1, 1)
			FillClip.Size = UDim2.fromScale(fraction, 1)
			FillClip.Visible = fraction > 0
		end

		function Slider:OnChanged(Func)
			Slider.Changed = Func
			if Library.FireOnChanged then
				Func(Slider.Value)
			end
		end

		local function Round(Value)
			if Slider.Rounding == 0 then
				return math.floor(Value)
			end

			return tonumber(string.format("%." .. Slider.Rounding .. "f", Value))
		end

		function Slider:GetValueFromXOffset(X)
			return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
		end

		function Slider:SetValue(Str)
			local Num = tonumber(Str)

			if not Num then
				return
			end

			Num = math.clamp(Num, Slider.Min, Slider.Max)

			Slider.Value = Num
			Slider:Display()

			Library:SafeCallback(Slider.Callback, Slider.Value)
			Library:SafeCallback(Slider.Changed, Slider.Value)
		end

		SliderInner.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
				local mPos = Library:GetPointerPosition(Input).X
				local gPos = FillClip.AbsoluteSize.X
				local Diff = mPos - (FillClip.AbsolutePosition.X + gPos)

				while not Library.Unloaded and Library:IsPointerDown(Input) do
					local nMPos = Library:GetPointerPosition(Input).X
					local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize)

					local nValue = Slider:GetValueFromXOffset(nX)
					local OldValue = Slider.Value
					Slider.Value = nValue

					Slider:Display()

					if nValue ~= OldValue then
						Library:SafeCallback(Slider.Callback, Slider.Value)
						Library:SafeCallback(Slider.Changed, Slider.Value)
					end

					RenderStepped:Wait()
				end

				Library:AttemptSave()
			end
		end)

		SliderInner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			Slider.MaxSize = math.max(1, SliderInner.AbsoluteSize.X)
		end)
		Slider.MaxSize = math.max(1, SliderInner.AbsoluteSize.X)
		Slider:Display()
		Groupbox:AddBlank(Info.BlankSize or 6)
		Groupbox:Resize()

		Options[Idx] = Slider

		return Slider
	end

	function Funcs:AddDropdown(Idx, Info)
		if Info.SpecialType == "Player" then
			Info.Values = GetPlayersString()
			Info.AllowNull = true
		elseif Info.SpecialType == "Team" then
			Info.Values = GetTeamsString()
			Info.AllowNull = true
		end

		assert(Info.Values, "AddDropdown: Missing dropdown value list.")
		if Info.Default == nil then
			Info.AllowNull = true
		end

		if not Info.Text then
			Info.Compact = true
		end

		local Dropdown = {
			Values = Info.Values,
			Value = Info.Multi and {},
			Multi = Info.Multi,
			Type = "Dropdown",
			SpecialType = Info.SpecialType,
			Callback = Info.Callback or function(Value) end,
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local RelativeOffset = 0

		if not Info.Compact then
			local DropdownLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10),
				TextSize = 14,
				Text = Info.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom,
				ZIndex = 5,
				Parent = Container,
			})

			Groupbox:AddBlank(3)
		end

		for _, Element in next, Container:GetChildren() do
			if not Element:IsA("UIListLayout") then
				RelativeOffset = RelativeOffset + Element.Size.Y.Offset
			end
		end

		local DropdownOuter = Library:Create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Color3.new(0, 0, 0),
			Size = UDim2.new(1, -4, 0, 22),
			ZIndex = 5,
			Parent = Container,
		})

		Library:AddToRegistry(DropdownOuter, {
			BorderColor3 = "Black",
		})

		local DropdownInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 6,
			Parent = DropdownOuter,
		})

		Library:AddToRegistry(DropdownInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local DropdownArrow = Library:Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			BorderSizePixel = 0,
			ZIndex = 8,
			Parent = DropdownInner,
		})

		for index = 1, 2 do
			local line = Library:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Library.FontColor,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(index == 1 and 3 or 8, 6),
				Size = UDim2.fromOffset(7, 2),
				Rotation = index == 1 and 45 or -45,
				ZIndex = 8,
				Parent = DropdownArrow,
			})
			Library:AddToRegistry(line, { BackgroundColor3 = "FontColor" })
		end

		local ItemList = Library:CreateLabel({
			Position = UDim2.new(0, 5, 0, 0),
			Size = UDim2.new(1, -24, 1, 0),
			TextSize = 14,
			Text = "--",
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = false,
			ZIndex = 7,
			Parent = DropdownInner,
		})

		Library:RoundSurface(DropdownOuter, 2)
		DropdownOuter.BackgroundTransparency = 1
		Library:RoundSurface(DropdownInner, 2, true)
		Library:OnSurfaceHover(DropdownOuter, DropdownInner)
		Dropdown.Surface, Dropdown.HoverTarget = DropdownInner, DropdownOuter

		if type(Info.Tooltip) == "string" then
			Library:AddToolTip(Info.Tooltip, DropdownOuter)
		end

		local MAX_DROPDOWN_ITEMS = 8
		local DROPDOWN_ITEM_HEIGHT = 22

		local ListOuter = Library:Create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderColor3 = Library.OutlineColor,
			ZIndex = 20,
			Visible = false,
			Parent = ScreenGui,
		})

		Library:AddToRegistry(ListOuter, { BorderColor3 = "OutlineColor" })

		local function RecalculateListPosition()
			local viewport = ScreenGui.AbsoluteSize
			local height = ListOuter.Size.Y.Offset
			local below = DropdownOuter.AbsolutePosition.Y + DropdownOuter.AbsoluteSize.Y + 1
			local y = below + height <= viewport.Y and below or DropdownOuter.AbsolutePosition.Y - height - 1
			ListOuter.Position = UDim2.fromOffset(
				math.clamp(DropdownOuter.AbsolutePosition.X, 0, math.max(0, viewport.X - ListOuter.Size.X.Offset)),
				math.max(0, y)
			)
		end

		local function RecalculateListSize(YSize)
			ListOuter.Size =
				UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * DROPDOWN_ITEM_HEIGHT + 2))
			RecalculateListPosition()
		end

		RecalculateListPosition()
		RecalculateListSize()

		DropdownOuter:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			if ListOuter.Visible then
				RecalculateListPosition()
			end
		end)
		DropdownOuter:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if ListOuter.Visible then
				RecalculateListSize(ListOuter.Size.Y.Offset)
			end
		end)

		local ListInner = Library:Create("Frame", {
			BackgroundColor3 = Library.MainColor,
			BorderColor3 = Library.OutlineColor,
			BorderMode = Enum.BorderMode.Inset,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 21,
			Parent = ListOuter,
		})

		Library:RoundSurface(ListOuter, 2, true)
		Library:RoundSurface(ListInner, 2)
		Library:AddToRegistry(ListInner, {
			BackgroundColor3 = "MainColor",
			BorderColor3 = "OutlineColor",
		})

		local Scrolling = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 21,
			Parent = ListInner,

			TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
			BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",

			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.AccentColor,
		})

		Library:AddToRegistry(Scrolling, {
			ScrollBarImageColor3 = "AccentColor",
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 0),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Scrolling,
		})

		function Dropdown:Display()
			local Values = Dropdown.Values
			local Str = ""

			if Info.Multi then
				for Idx, Value in next, Values do
					if Dropdown.Value[Value] then
						Str = Str .. Value .. ", "
					end
				end

				Str = Str:sub(1, #Str - 2)
			else
				Str = Dropdown.Value or ""
			end

			ItemList.Text = (Str == "" and "--" or Str)
		end

		function Dropdown:GetActiveValues()
			if Info.Multi then
				local T = {}

				for Value, Bool in next, Dropdown.Value do
					table.insert(T, Value)
				end

				return T
			else
				return Dropdown.Value and 1 or 0
			end
		end

		local Buttons = {}

		function Dropdown:BuildDropdownList()
			local Values = Dropdown.Values
			local Count = 0

			for Idx, Value in next, Values do
				local Table = Buttons[Idx]

				Count = Count + 1

				if not Table then
					Table = { Value = Value }
					local Button = Library:Create("TextButton", {
						Text = "",
						AutoButtonColor = false,
						BackgroundColor3 = Library.MainColor,
						BorderColor3 = Library.OutlineColor,
						BorderMode = Enum.BorderMode.Middle,
						Size = UDim2.new(1, -1, 0, DROPDOWN_ITEM_HEIGHT),
						ZIndex = 23,
						Active = true,
						Parent = Scrolling,
					})

					Library:AddToRegistry(Button, {
						BackgroundColor3 = "MainColor",
						BorderColor3 = "OutlineColor",
					})

					local ButtonLabel = Library:CreateLabel({
						Active = false,
						Size = UDim2.new(1, -6, 1, 0),
						Position = UDim2.new(0, 6, 0, 0),
						TextSize = 14,
						Text = Value,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 25,
						Parent = Button,
					})

					Library:RoundSurface(Button, 2)
					Library:OnSurfaceHover(Button, Button)

					local Selected

					if Info.Multi then
						Selected = Dropdown.Value[Table.Value]
					else
						Selected = Dropdown.Value == Table.Value
					end

					function Table:UpdateButton()
						if Info.Multi then
							Selected = Dropdown.Value[Table.Value]
						else
							Selected = Dropdown.Value == Table.Value
						end

						ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor
						Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and "AccentColor"
							or "FontColor"
					end

					Button.Activated:Connect(function(Input)
						if Library:IsPointerInput(Input) then
							local Try = not Selected

							if Dropdown:GetActiveValues() == 1 and not Try and not Info.AllowNull then
							else
								if Info.Multi then
									Selected = Try

									if Selected then
										Dropdown.Value[Table.Value] = true
									else
										Dropdown.Value[Table.Value] = nil
									end
								else
									Selected = Try

									if Selected then
										Dropdown.Value = Table.Value
									else
										Dropdown.Value = nil
									end

									for _, OtherButton in next, Buttons do
										OtherButton:UpdateButton()
									end
								end

								Table:UpdateButton()
								Dropdown:Display()

								Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
								Library:SafeCallback(Dropdown.Changed, Dropdown.Value)

								Library:AttemptSave()
							end
						end
					end)

					Table.Button, Table.Label = Button, ButtonLabel
					Buttons[Idx] = Table
				end
				Table.Value = Value
				Table.Label.Text = Value
				Table.Button.LayoutOrder = Idx
				Table:UpdateButton()
			end

			for Idx = #Buttons, Count + 1, -1 do
				Buttons[Idx].Button:Destroy()
				Buttons[Idx] = nil
			end
			Dropdown:Display()

			local Y = math.min(Count, MAX_DROPDOWN_ITEMS) * DROPDOWN_ITEM_HEIGHT + 1
			RecalculateListSize(Y)
		end

		function Dropdown:SetValues(NewValues)
			if NewValues then
				Dropdown.Values = NewValues
			end

			Dropdown:BuildDropdownList()
		end

		function Dropdown:OpenDropdown()
			RecalculateListSize(ListOuter.Size.Y.Offset)
			ListOuter.Visible = true
			Library.OpenedFrames[ListOuter] = true
			DropdownArrow.Rotation = 180
		end

		function Dropdown:CloseDropdown()
			ListOuter.Visible = false
			Library.OpenedFrames[ListOuter] = nil
			DropdownArrow.Rotation = 0
		end

		function Dropdown:OnChanged(Func)
			Dropdown.Changed = Func
			if Library.FireOnChanged then
				Func(Dropdown.Value)
			end
		end

		function Dropdown:SetValue(Val)
			if Dropdown.Multi then
				local nTable = {}

				for Value, Bool in next, Val or {} do
					if Bool and table.find(Dropdown.Values, Value) then
						nTable[Value] = true
					end
				end

				Dropdown.Value = nTable
			else
				if not Val then
					Dropdown.Value = nil
				elseif table.find(Dropdown.Values, Val) then
					Dropdown.Value = Val
				end
			end

			for _, Button in ipairs(Buttons) do
				Button:UpdateButton()
			end
			Dropdown:Display()

			Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
		end

		DropdownOuter.Activated:Connect(function(Input)
			if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
				if ListOuter.Visible then
					Dropdown:CloseDropdown()
				else
					Dropdown:OpenDropdown()
				end
			end
		end)

		Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
			if Library:IsPointerInput(Input) then
				if
					not Library:IsMouseOverFrame(ListOuter, Input)
					and not Library:IsMouseOverFrame(DropdownOuter, Input)
				then
					Dropdown:CloseDropdown()
				end
			end
		end))

		Dropdown:BuildDropdownList()
		Dropdown:Display()

		local Defaults = {}

		if type(Info.Default) == "string" then
			local Idx = table.find(Dropdown.Values, Info.Default)
			if Idx then
				table.insert(Defaults, Idx)
			end
		elseif type(Info.Default) == "table" then
			for _, Value in next, Info.Default do
				local Idx = table.find(Dropdown.Values, Value)
				if Idx then
					table.insert(Defaults, Idx)
				end
			end
		elseif type(Info.Default) == "number" and Dropdown.Values[Info.Default] ~= nil then
			table.insert(Defaults, Info.Default)
		end

		if next(Defaults) then
			for i = 1, #Defaults do
				local Index = Defaults[i]
				if Info.Multi then
					Dropdown.Value[Dropdown.Values[Index]] = true
				else
					Dropdown.Value = Dropdown.Values[Index]
				end

				if not Info.Multi then
					break
				end
			end

			Dropdown:BuildDropdownList()
			Dropdown:Display()
		end

		Groupbox:AddBlank(Info.BlankSize or 5)
		Groupbox:Resize()

		Options[Idx] = Dropdown

		return Dropdown
	end

	function Funcs:AddDependencyBox()
		local Depbox = {
			Dependencies = {},
		}

		local Groupbox = self
		local Container = Groupbox.Container

		local Holder = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = false,
			Parent = Container,
		})

		local Frame = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = true,
			Parent = Holder,
		})

		local Layout = Library:Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Frame,
		})

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
			Groupbox:Resize()
		end

		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Depbox:Resize()
		end)

		Holder:GetPropertyChangedSignal("Visible"):Connect(function()
			Depbox:Resize()
		end)

		function Depbox:Update()
			for _, Dependency in next, Depbox.Dependencies do
				local Elem = Dependency[1]
				local Value = Dependency[2]

				if Elem.Type == "Toggle" and Elem.Value ~= Value then
					Holder.Visible = false
					Depbox:Resize()
					return
				end
			end

			Holder.Visible = true
			Depbox:Resize()
		end

		function Depbox:SetupDependencies(Dependencies)
			for _, Dependency in next, Dependencies do
				assert(type(Dependency) == "table", "SetupDependencies: Dependency is not of type `table`.")
				assert(Dependency[1], "SetupDependencies: Dependency is missing element argument.")
				assert(Dependency[2] ~= nil, "SetupDependencies: Dependency is missing value argument.")
			end

			Depbox.Dependencies = Dependencies
			Depbox:Update()
		end

		Depbox.Container = Frame
		Depbox.Holder = Holder

		setmetatable(Depbox, BaseGroupbox)

		table.insert(Library.DependencyBoxes, Depbox)

		return Depbox
	end

	BaseGroupbox.__index = Funcs
	BaseGroupbox.__namecall = function(Table, Key, ...)
		return Funcs[Key](...)
	end
end

do
	local funcs = BaseGroupbox.__index
	for _, name in ipairs({ "AddLabel", "AddButton", "AddDivider", "AddInput", "AddToggle", "AddSlider", "AddDropdown" }) do
		local add = funcs[name]
		funcs[name] = function(self, ...)
			local args = table.pack(...)
			local existing = {}
			local order = 0
			for _, child in ipairs(self.Container:GetChildren()) do
				existing[child] = true
				if child:IsA("GuiObject") then
					order = math.max(order, child.LayoutOrder)
				end
			end
			local control = add(self, table.unpack(args, 1, args.n)) or { Type = "Divider" }
			if control.Holder then
				return control
			end
			local row = Library:Create("Frame", {
				Name = tostring(args[1] or name),
				BackgroundColor3 = Library.HoverColor,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				ZIndex = 4,
				LayoutOrder = order + 1,
			})
			local height = 0
			for _, child in ipairs(self.Container:GetChildren()) do
				if not existing[child] and child:IsA("GuiObject") then
					height = height + child.Size.Y.Offset
					child.Parent = row
				end
			end
			row.Size = UDim2.new(1, 0, 0, height)
			Library:Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = row,
			})
			row.Parent = self.Container
			Library:AddToRegistry(row, { BackgroundColor3 = "HoverColor" })
			control.Holder = row
			control.Groupbox = self
			function control:SetVisible(visible)
				self.Holder.Visible = visible == true
				if not visible and self.CloseDropdown then
					self:CloseDropdown()
				end
				self.Groupbox:Resize()
				if self.Groupbox.Window then
					self.Groupbox.Window:RefreshSearch()
				end
			end
			row:GetPropertyChangedSignal("Visible"):Connect(function()
				self:Resize()
			end)
			local function updateRowHeight()
				local height = 0
				for _, child in ipairs(row:GetChildren()) do
					if child:IsA("GuiObject") and child.Visible then
						height = height + child.Size.Y.Offset
					end
				end
				if row.Size.Y.Offset ~= height then
					row.Size = UDim2.new(1, 0, 0, height)
					self:Resize()
				end
			end
			for _, child in ipairs(row:GetChildren()) do
				if child:IsA("GuiObject") then
					child:GetPropertyChangedSignal("Size"):Connect(updateRowHeight)
					child:GetPropertyChangedSignal("Visible"):Connect(updateRowHeight)
				end
			end
			local interactive = name ~= "AddLabel" and name ~= "AddDivider"
			if interactive then
				local info = type(args[2]) == "table" and args[2] or type(args[1]) == "table" and args[1] or {}
				control.Text = info.Text or tostring(args[1])
				control.Id = name == "AddButton" and control.Text or tostring(args[1])
				table.insert(Library.Features, control)
				if self.Window then
					table.insert(self.Window.Features, control)
					self.Window:AddSearchFeature(control)
				end
			end
			self:Resize()
			return control
		end
	end
	local addDependency = funcs.AddDependencyBox
	funcs.AddDependencyBox = function(self)
		local box = addDependency(self)
		box.Window, box.MainTab, box.ParentPage, box.Name = self.Window, self.MainTab, self, self.Name
		return box
	end
	function funcs:AddTabbox(info)
		return Library:CreateTabbox(info or {}, self.Container, self)
	end
end

do
	Library.NotificationArea = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(0, 300, 0, 200),
		ZIndex = 100,
		Parent = ScreenGui,
	})

	Library:Create("UIListLayout", {
		Padding = UDim.new(0, 4),
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Library.NotificationArea,
	})

	local WatermarkOuter = Library:Create("Frame", {
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 100, 0, -25),
		Size = UDim2.new(0, 213, 0, 20),
		ZIndex = 200,
		Visible = false,
		Parent = ScreenGui,
	})

	local WatermarkInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.AccentColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 201,
		Parent = WatermarkOuter,
	})

	Library:AddToRegistry(WatermarkInner, {
		BorderColor3 = "AccentColor",
	})

	local InnerFrame = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 202,
		Parent = WatermarkInner,
	})

	local Gradient = Library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		}),
		Rotation = -90,
		Parent = InnerFrame,
	})

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			})
		end,
	})

	local WatermarkLabel = Library:CreateLabel({
		Position = UDim2.new(0, 5, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 203,
		Parent = InnerFrame,
	})

	Library.Watermark = WatermarkOuter
	Library.WatermarkText = WatermarkLabel
	Library:MakeDraggable(Library.Watermark)

	local KeybindOuter = Library:Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 210, 0, 20),
		Visible = false,
		ZIndex = 100,
		Parent = ScreenGui,
	})

	local KeybindInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 101,
		Parent = KeybindOuter,
	})

	Library:AddToRegistry(KeybindInner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	}, true)

	local ColorFrame = Library:Create("Frame", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 102,
		Parent = KeybindInner,
	})

	Library:AddToRegistry(ColorFrame, {
		BackgroundColor3 = "AccentColor",
	}, true)

	local KeybindLabel = Library:CreateLabel({
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.fromOffset(5, 2),
		TextXAlignment = Enum.TextXAlignment.Left,

		Text = "Keybinds",
		ZIndex = 104,
		Parent = KeybindInner,
	})

	local KeybindContainer = Library:Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -20),
		Position = UDim2.new(0, 0, 0, 20),
		ZIndex = 1,
		Parent = KeybindInner,
	})

	Library:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = KeybindContainer,
	})

	Library:Create("UIPadding", {
		PaddingLeft = UDim.new(0, 5),
		Parent = KeybindContainer,
	})

	Library.KeybindFrame = KeybindOuter
	Library.KeybindContainer = KeybindContainer
	Library:MakeDraggable(KeybindOuter)
end

function Library:SetWatermarkVisibility(Bool)
	Library.Watermark.Visible = Bool
end

function Library:SetWatermark(Text)
	local X, Y = Library:GetTextBounds(Text, Library.Font, 14)
	Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3)
	Library:SetWatermarkVisibility(true)

	Library.WatermarkText.Text = Text
end

function Library:Notify(Text, Time)
	local closable = false
	if type(Text) == "table" then
		closable = Text.Closable == true
		Time = Text.Time or Time
		Text = (Text.Title and tostring(Text.Title) .. "\n" or "") .. tostring(Text.Description or "")
	end
	Text = tostring(Text)
	local notificationWidth = math.max(100, math.min(380, ScreenGui.AbsoluteSize.X - 40))
	local padding = closable and 26 or 12
	local XSize, YSize =
		Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(notificationWidth + 12 - padding, math.huge))

	YSize = YSize + 7

	local NotifyOuter = Library:Create("Frame", {
		BorderColor3 = Color3.new(0, 0, 0),
		Position = UDim2.new(0, 100, 0, 10),
		Size = UDim2.new(0, 0, 0, YSize),
		ClipsDescendants = true,
		ZIndex = 100,
		Parent = Library.NotificationArea,
	})

	local NotifyInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 101,
		Parent = NotifyOuter,
	})

	Library:AddToRegistry(NotifyInner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	}, true)

	local InnerFrame = Library:Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 102,
		Parent = NotifyInner,
	})

	local Gradient = Library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		}),
		Rotation = -90,
		Parent = InnerFrame,
	})

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			})
		end,
	})

	local NotifyLabel = Library:CreateLabel({
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -4, 1, 0),
		Text = Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 14,
		ZIndex = 103,
		Parent = InnerFrame,
	})

	local LeftColor = Library:Create("Frame", {
		BackgroundColor3 = Library.AccentColor,
		BorderSizePixel = 0,
		Position = UDim2.new(0, -1, 0, -1),
		Size = UDim2.new(0, 3, 1, 2),
		ZIndex = 104,
		Parent = NotifyOuter,
	})

	Library:AddToRegistry(LeftColor, {
		BackgroundColor3 = "AccentColor",
	}, true)

	pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + padding, 0, YSize), "Out", "Quad", 0.4, true)

	if closable then
		local close = Library:Create("TextButton", {
			Text = "x",
			Font = Library.Font,
			TextSize = 14,
			TextColor3 = Library.FontColor,
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -19, 0, 0),
			Size = UDim2.fromOffset(18, 18),
			ZIndex = 105,
			Parent = NotifyOuter,
		})
		NotifyLabel.Size = UDim2.new(1, -22, 1, 0)
		close.Activated:Connect(function()
			NotifyOuter:Destroy()
		end)
	end

	task.spawn(function()
		wait(Time or 5)

		if Library.Unloaded or not NotifyOuter.Parent then
			return
		end

		pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), "Out", "Quad", 0.4, true)

		wait(0.4)

		NotifyOuter:Destroy()
	end)
	return NotifyOuter
end

function Library:CreateTabbox(Info, Parent, Owner)
	local Tabbox = {
		Tabs = {},
	}

	local BoxOuter = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		BorderMode = Enum.BorderMode.Inset,
		Size = UDim2.new(1, 0, 0, 0),
		ZIndex = 2,
		Parent = Parent,
	})

	Library:AddToRegistry(BoxOuter, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})

	local BoxInner = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Color3.new(0, 0, 0),

		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = 4,
		Parent = BoxOuter,
	})

	Library:RoundSurface(BoxOuter, 2, true)
	Library:RoundSurface(BoxInner, 2)
	Library:AddToRegistry(BoxInner, {
		BackgroundColor3 = "MainColor",
	})

	local TabboxButtons = Library:Create("Frame", {
		Name = "SectionHeader",
		BackgroundColor3 = Library.BackgroundColor,
		BorderSizePixel = 0,
		Position = UDim2.new(),
		Size = UDim2.new(1, 0, 0, 22),
		ZIndex = 5,
		Parent = BoxInner,
	})

	Library:RoundSurface(TabboxButtons, 2)
	Library:AddToRegistry(TabboxButtons, { BackgroundColor3 = "BackgroundColor" })

	Library:Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabboxButtons,
	})

	function Tabbox:AddTab(Name)
		local firstTab = next(Tabbox.Tabs) == nil
		local Tab =
			{ Name = Name, Window = Owner.Window, MainTab = Owner.MainTab or Owner, ParentPage = Owner, Tabboxes = {} }

		local Button = Library:Create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Library.MainColor,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.5, 0, 1, 0),
			ZIndex = 6,
			Parent = TabboxButtons,
		})

		Library:AddToRegistry(Button, {
			BackgroundColor3 = "MainColor",
		})

		local ButtonLabel = Library:CreateLabel({
			Size = UDim2.new(1, 0, 1, 0),
			TextSize = 14,
			Text = Name,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 7,
			Parent = Button,
		})

		local Block = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.fromOffset(Library:GetTextBounds(Name, Library.Font, 14), 2),
			Visible = false,
			ZIndex = 9,
			Parent = Button,
		})

		Library:AddToRegistry(Block, {
			BackgroundColor3 = "AccentColor",
		})

		local Container = Library:Create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 7, 0, 22),
			Size = UDim2.new(1, -10, 1, -22),
			ZIndex = 1,
			Visible = false,
			Parent = BoxInner,
		})

		Library:Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = Container,
		})

		function Tab:Show()
			for _, Tab in next, Tabbox.Tabs do
				Tab:Hide()
			end

			Container.Visible = true
			Block.Visible = true
			ButtonLabel.TextColor3 = Library.AccentColor
			Library.RegistryMap[ButtonLabel].Properties.TextColor3 = "AccentColor"

			Button.BackgroundColor3 = Library.BackgroundColor
			Library.RegistryMap[Button].Properties.BackgroundColor3 = "BackgroundColor"

			Tab:Resize()
		end

		function Tab:Hide()
			Container.Visible = false
			Block.Visible = false
			ButtonLabel.TextColor3 = Library.FontColor
			Library.RegistryMap[ButtonLabel].Properties.TextColor3 = "FontColor"

			Button.BackgroundColor3 = Library.MainColor
			Library.RegistryMap[Button].Properties.BackgroundColor3 = "MainColor"
		end

		function Tab:Resize()
			local TabCount = 0

			for _, Tab in next, Tabbox.Tabs do
				TabCount = TabCount + 1
			end

			if Tabbox.TabCount ~= TabCount then
				Tabbox.TabCount = TabCount
				for _, Button in next, TabboxButtons:GetChildren() do
					if Button:IsA("GuiObject") then
						Button.Size = UDim2.new(1 / TabCount, 0, 1, 0)
					end
				end
			end

			if not Container.Visible then
				return
			end

			local Size = 0

			for _, Element in next, Tab.Container:GetChildren() do
				if (not Element:IsA("UIListLayout")) and Element.Visible then
					Size = Size + Element.Size.Y.Offset
				end
			end

			local size = UDim2.new(1, 0, 0, 22 + Size + 2 + 2)
			if BoxOuter.Size ~= size then
				BoxOuter.Size = size
			end
			if Owner.Resize then
				Owner:Resize()
			end
		end

		Button.Activated:Connect(function(Input)
			if Library:IsPointerInput(Input) and not Library:MouseIsOverOpenedFrame(Input) then
				Tab:Show()
				Tab:Resize()
			end
		end)

		Tab.Container = Container
		Tab.Holder = BoxOuter
		Tabbox.Tabs[Name] = Tab

		setmetatable(Tab, BaseGroupbox)

		Tab:AddBlank(3)
		Tab:Resize()

		if firstTab then
			Tab:Show()
		end

		return Tab
	end

	Owner.Tabboxes = Owner.Tabboxes or {}
	Owner.Tabboxes[Info.Name or ""] = Tabbox
	Tabbox.Holder = BoxOuter
	if Owner.Window and (Owner.MainTab == Owner or not Owner.MainTab) then
		table.insert(Owner.Boxes, { Holder = BoxOuter, Side = (Info.Side == 1 or Info.Side == "Left") and 1 or 2 })
		Owner:RefreshSides()
	end

	return Tabbox
end

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == "table" then
		Config = ...
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false
	end

	if type(Config.Title) ~= "string" then
		Config.Title = "No title"
	end
	if type(Config.TabPadding) ~= "number" then
		Config.TabPadding = 8
	end

	if typeof(Config.Position) ~= "UDim2" then
		Config.Center = true
		Config.Position = UDim2.fromOffset(175, 50)
	end
	if typeof(Config.Size) ~= "UDim2" then
		Config.Size = UDim2.fromOffset(800, 600)
	end
	if Config.AutoShow == nil then
		Config.AutoShow = true
	end
	if Config.ShowCustomCursor == nil then
		Config.ShowCustomCursor = false
	end

	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5)
		Config.Position = UDim2.fromScale(0.5, 0.5)
	end

	local Window =
		{ Tabs = {}, TabOrder = {}, Features = {}, TabPosition = Config.TabPosition == "Left" and "Left" or "Top" }
	Library.Window = Window
	Library.LocalPlayer = LocalPlayer
	Library.Toggles = Toggles
	Library.Options = Options

	local Outer = Library:Create("Frame", {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Position = Config.Position,
		Size = Config.Size,
		Visible = false,
		ZIndex = 1,
		Parent = ScreenGui,
	})

	Window.Holder = Outer

	local Inner = Library:Create("Frame", {
		Active = true,
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.AccentColor,
		BorderMode = Enum.BorderMode.Inset,
		Position = UDim2.new(0, 1, 0, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 1,
		Parent = Outer,
	})

	Library:RoundSurface(Outer, 3)
	Library:RoundSurface(Inner, 2, true)
	Library:AddToRegistry(Inner, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "AccentColor",
	})

	local WindowLabel = Library:CreateLabel({
		Position = UDim2.new(0, 38, 0, 0),
		Size = UDim2.new(1, -246, 0, 27),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = Config.Title or "",
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 1,
		Parent = Inner,
	})

	local MainSectionOuter = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(0, 7, 0, 29),
		Size = UDim2.new(1, -14, 1, -55),
		ZIndex = 1,
		Parent = Inner,
	})

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = "BackgroundColor",
		BorderColor3 = "OutlineColor",
	})

	local MainSectionInner = Library:Create("Frame", {
		BackgroundColor3 = Library.BackgroundColor,
		BorderColor3 = Color3.new(0, 0, 0),
		BorderMode = Enum.BorderMode.Inset,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 1,
		Parent = MainSectionOuter,
	})

	Library:RoundSurface(MainSectionOuter, 2, true)
	Library:RoundSurface(MainSectionInner, 2)
	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = "BackgroundColor",
	})

	local TabArea = Library:Create("ScrollingFrame", {
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollBarThickness = 0,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(1, -16, 0, 21),
		ZIndex = 1,
		Parent = MainSectionInner,
	})

	local TabListLayout = Library:Create("UIListLayout", {
		Padding = UDim.new(0, Config.TabPadding),
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = TabArea,
	})

	local TabContainer = Library:Create("Frame", {
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(0, 8, 0, 30),
		Size = UDim2.new(1, -16, 1, -38),
		ZIndex = 2,
		Parent = MainSectionInner,
	})

	Library:RoundSurface(TabContainer, 2, true)
	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = "MainColor",
		BorderColor3 = "OutlineColor",
	})

	function Window:ClosePopups()
		for frame in pairs(Library.OpenedFrames) do
			if frame.Parent then
				frame.Visible = false
			end
			Library.OpenedFrames[frame] = nil
		end
		for _, option in pairs(Options) do
			if option.Type == "Dropdown" then
				option:CloseDropdown()
			end
		end
		if self.SearchResults then
			self.SearchResults.Visible = false
		end
	end

	function Window:SetTabPosition(position)
		assert(position == "Top" or position == "Left", "TabPosition must be Top or Left")
		self:ClosePopups()
		self.TabPosition = position
		local left = position == "Left"
		TabListLayout.FillDirection = left and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
		TabArea.Position = UDim2.fromOffset(6, 6)
		TabArea.Size = left and UDim2.new(0, 120, 1, -12) or UDim2.new(1, -12, 0, 23)
		TabContainer.Position = left and UDim2.fromOffset(132, 6) or UDim2.fromOffset(6, 31)
		TabContainer.Size = left and UDim2.new(1, -138, 1, -12) or UDim2.new(1, -12, 1, -37)
		for _, tab in ipairs(self.TabOrder) do
			if tab.Button then
				tab.Button.Size = left and UDim2.new(1, 0, 0, 25) or UDim2.fromOffset(tab.ButtonWidth, 23)
				tab.Label.TextXAlignment = left and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
				tab.Label.Position = left and UDim2.fromOffset(7, 0) or UDim2.new()
				tab.Label.Size = UDim2.new(1, left and -7 or 0, 1, -1)
				tab:RefreshSides()
			end
		end
	end

	function Window:SetSize(size)
		assert(typeof(size) == "Vector2", "SetSize requires Vector2")
		local expanded = Vector2.new(math.max(360, size.X), math.max(240, size.Y))
		if self.ExpandedSize ~= expanded then
			self.ExpandedSize = expanded
		end
		local contentSize = UDim2.fromOffset(expanded.X - 16, expanded.Y - 57)
		if MainSectionOuter.Size ~= contentSize then
			MainSectionOuter.Size = contentSize
		end
		local width = self.Minimized
				and math.clamp(
					Library:GetTextBounds(WindowLabel.Text, Library.Font, WindowLabel.TextSize) + 50,
					100,
					360
				)
			or expanded.X
		local target = UDim2.fromOffset(width, self.Minimized and 28 or expanded.Y)
		if Outer.Size ~= target then
			Outer.Size = target
		end
	end

	function Window:ClampPosition()
		local viewport = ScreenGui.AbsoluteSize
		local position = Outer.Position
		local x = position.X.Scale * viewport.X + position.X.Offset - Outer.Size.X.Offset * Outer.AnchorPoint.X
		local y = position.Y.Scale * viewport.Y + position.Y.Offset - Outer.Size.Y.Offset * Outer.AnchorPoint.Y
		if Outer.AnchorPoint ~= Vector2.zero then
			Outer.AnchorPoint = Vector2.zero
		end
		local target = UDim2.fromOffset(
			math.clamp(x, 48 - Outer.Size.X.Offset, math.max(0, viewport.X - 48)),
			math.clamp(y, 0, math.max(0, viewport.Y - 28))
		)
		if Outer.Position ~= target then
			Outer.Position = target
		end
	end

	local minimize = Library:Create("TextButton", {
		Name = "Minimize",
		Text = "-",
		Font = Library.Font,
		TextSize = 18,
		TextColor3 = Library.FontColor,
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.fromOffset(7, 5),
		Size = UDim2.fromOffset(22, 18),
		AutoButtonColor = false,
		ZIndex = 12,
		Parent = Inner,
	})
	Library:AddToRegistry(
		minimize,
		{ BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", TextColor3 = "FontColor" }
	)
	Library:RoundSurface(minimize, 2)
	Library:OnSurfaceHover(minimize, minimize)

	local footer = Library:CreateLabel({
		Name = "Footer",
		Text = Config.Footer or "",
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 8, 1, -20),
		Size = UDim2.new(1, -16, 0, 16),
		ZIndex = 5,
		Parent = Inner,
	})
	local resize = Library:Create("TextButton", {
		Name = "Resize",
		Text = "",
		Font = Library.Font,
		TextSize = 16,
		TextColor3 = Library.AccentColor,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(1, -23, 1, -23),
		Size = UDim2.fromOffset(22, 22),
		ZIndex = 12,
		Parent = Inner,
	})
	for index, length in ipairs({ 4, 7, 10 }) do
		local line = Library:Create("Frame", {
			Name = "GripLine",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Library.FontColor,
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -3 - index * 3, 1, -3 - index * 3),
			Size = UDim2.fromOffset(length, 1),
			Rotation = -45,
			ZIndex = 13,
			Parent = resize,
		})
		Library:AddToRegistry(line, { BackgroundColor3 = "FontColor" })
	end
	function Window:SetMinimized(value)
		self:ClosePopups()
		self.Minimized = value == true
		if self.SearchBox then
			self.SearchBox.Visible = not self.Minimized
			if self.Minimized then
				self.SearchBox:ReleaseFocus()
			end
		end
		WindowLabel.Size = UDim2.new(1, self.Minimized and -48 or -246, 0, 27)
		MainSectionOuter.Visible = not self.Minimized
		footer.Visible = not self.Minimized
		resize.Visible = not self.Minimized
		minimize.Text = self.Minimized and "+" or "-"
		self:SetSize(self.ExpandedSize)
	end
	minimize.Activated:Connect(function()
		Window:SetMinimized(not Window.Minimized)
	end)
	Window.MinimizeButton, Window.ResizeHandle, Window.Footer = minimize, resize, footer

	local search = Library:Create("TextBox", {
		Name = "FeatureSearch",
		Text = "",
		PlaceholderText = "Search",
		Font = Library.Font,
		TextSize = 14,
		TextColor3 = Library.FontColor,
		PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Library.BackgroundColor,
		BorderColor3 = Library.OutlineColor,
		Position = UDim2.new(1, -191, 0, 4),
		Size = UDim2.fromOffset(184, 19),
		ZIndex = 12,
		Parent = Inner,
	})
	Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 5), Parent = search })
	Library:AddToRegistry(
		search,
		{ TextColor3 = "FontColor", BackgroundColor3 = "BackgroundColor", BorderColor3 = "OutlineColor" }
	)
	Library:RoundSurface(search, 2, true)
	local searchHover = Library:OnSurfaceHover(search, search)
	searchHover.Position = UDim2.fromOffset(-5, 0)
	searchHover.Size = UDim2.new(1, 5, 1, 0)
	local results = Library:Create("ScrollingFrame", {
		Name = "SearchResults",
		BackgroundColor3 = Library.MainColor,
		BorderColor3 = Library.OutlineColor,
		Size = UDim2.fromOffset(400, 0),
		Visible = false,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Library.AccentColor,
		ZIndex = 110,
		Parent = ScreenGui,
	})
	Library:RoundSurface(results, 2, true)
	Library:AddToRegistry(
		results,
		{ BackgroundColor3 = "MainColor", BorderColor3 = "OutlineColor", ScrollBarImageColor3 = "AccentColor" }
	)
	Library:Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = results })
	Window.SearchBox, Window.SearchResults = search, results

	function Window:IsFeatureVisible(feature)
		local page = feature.Groupbox
		if not feature.Holder.Visible then
			return false
		end
		local parent = feature.Holder.Parent
		while parent and parent ~= page.Container do
			if parent:IsA("GuiObject") and not parent.Visible then
				return false
			end
			parent = parent.Parent
		end
		while page.ParentPage do
			if page.Holder and not page.Holder.Visible then
				return false
			end
			page = page.ParentPage
		end
		return true
	end

	function Window:Search(query)
		local matches = {}
		query = tostring(query or ""):lower():match("^%s*(.-)%s*$")
		if query == "" then
			return matches
		end
		for _, feature in ipairs(self.Features) do
			local group = feature.Groupbox
			local path = group.MainTab.Name .. " / " .. group.Name .. " / " .. feature.Text
			if
				self:IsFeatureVisible(feature)
				and (path:lower():find(query, 1, true) or feature.Id:lower():find(query, 1, true))
			then
				table.insert(matches, { Control = feature, Path = path })
			end
		end
		return matches
	end

	function Window:RevealFeature(feature)
		if not self:IsFeatureVisible(feature) then
			return false
		end
		self:SetMinimized(false)
		if not Outer.Visible then
			Library:Toggle()
		end
		feature.Groupbox.MainTab:ShowTab()
		local pages, page = {}, feature.Groupbox
		while page do
			table.insert(pages, 1, page)
			page = page.ParentPage
		end
		for _, child in ipairs(pages) do
			if child.Show then
				child:Show()
			end
		end
		search:ReleaseFocus()
		results.Visible = false
		task.defer(function()
			if Library.Unloaded or not feature.Holder.Parent then
				return
			end
			RenderStepped:Wait()
			local side = feature.Holder:FindFirstAncestorWhichIsA("ScrollingFrame")
			if side then
				local y = feature.Holder.AbsolutePosition.Y - side.AbsolutePosition.Y + side.CanvasPosition.Y - 8
				side.CanvasPosition =
					Vector2.new(0, math.clamp(y, 0, math.max(0, side.AbsoluteCanvasSize.Y - side.AbsoluteSize.Y)))
			end
			local surface = feature.Surface
			local overlay = surface and surface:FindFirstChild("SurfaceHover")
			if overlay then
				overlay.BackgroundTransparency = 0.78
				TweenService:Create(overlay, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
			end
		end)
		return true
	end

	local searchRows, activeRows, searchDirty = {}, {}, false
	local noMatches = Library:CreateLabel({
		Text = "  No matching features",
		TextSize = 14,
		Size = UDim2.new(1, 0, 0, 26),
		Visible = false,
		ZIndex = 111,
		Parent = results,
	})

	function Window:AddSearchFeature(feature)
		local button = Library:Create("TextButton", {
			Text = "",
			Font = Library.Font,
			TextSize = 14,
			TextColor3 = Library.FontColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			BackgroundColor3 = Library.MainColor,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Size = UDim2.new(1, -3, 0, 26),
			LayoutOrder = #self.Features,
			Visible = false,
			ZIndex = 111,
			Parent = results,
		})
		Library:AddToRegistry(button, { TextColor3 = "FontColor", BackgroundColor3 = "MainColor" })
		Library:OnHighlight(button, button, { BackgroundColor3 = "HoverColor" }, { BackgroundColor3 = "MainColor" })
		button.Activated:Connect(function()
			self:RevealFeature(feature)
		end)
		searchRows[feature] = button
	end

	function Window:RefreshSearch()
		searchDirty = false
		if self.Minimized or not Outer.Visible or not search.Visible or not search:IsFocused() then
			results.Visible = false
			return
		end
		local query = search.Text:match("^%s*(.-)%s*$")
		if query == "" then
			results.Visible = false
			return
		end
		local matches = self:Search(query)
		local previousRows = activeRows
		activeRows = {}
		for index, match in ipairs(matches) do
			local button = searchRows[match.Control]
			local text = "  " .. match.Path
			if button.Text ~= text then
				button.Text = text
			end
			if button.LayoutOrder ~= index then
				button.LayoutOrder = index
			end
			if not previousRows[button] then
				button.Visible = true
			end
			activeRows[button] = true
		end
		for button in pairs(previousRows) do
			if not activeRows[button] then
				button.Visible = false
				button.BackgroundColor3 = Library.MainColor
				Library.RegistryMap[button].Properties.BackgroundColor3 = "MainColor"
			end
		end
		noMatches.Visible = #matches == 0
		local viewport = ScreenGui.AbsoluteSize
		local width = math.min(400, viewport.X - 16)
		local height = math.min(math.max(1, #matches) * 26, 208, math.max(26, viewport.Y - 40))
		results.Position = UDim2.fromOffset(
			math.clamp(search.AbsolutePosition.X + search.AbsoluteSize.X - width, 0, math.max(0, viewport.X - width)),
			math.clamp(search.AbsolutePosition.Y + 22, 0, math.max(0, viewport.Y - height))
		)
		results.Size = UDim2.fromOffset(width, height)
		results.CanvasPosition = Vector2.zero
		results.Visible = true
	end
	search:GetPropertyChangedSignal("Text"):Connect(function()
		searchDirty = true
	end)
	search.Focused:Connect(function()
		Window:RefreshSearch()
	end)
	search.FocusLost:Connect(function(enter)
		if enter then
			local first = Window:Search(search.Text)[1]
			if first then
				Window:RevealFeature(first.Control)
			end
		end
	end)
	Library:GiveSignal(InputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape then
			search:ReleaseFocus()
			results.Visible = false
		end
		if
			Library:IsPointerInput(input)
			and not Library:IsMouseOverFrame(search, input)
			and not Library:IsMouseOverFrame(results, input)
		then
			results.Visible = false
		end
	end))

	local drag, dragInput, sizeStart, pointerStart, pendingSize, pendingPosition
	resize.InputBegan:Connect(function(input)
		if not drag and Library:IsPointerInput(input) and Library:IsMouseOverFrame(resize, input) then
			Window:ClosePopups()
			drag, dragInput, sizeStart, pointerStart =
				"resize", input, pendingSize or Window.ExpandedSize, Library:GetPointerPosition(input)
		end
	end)
	Inner.InputBegan:Connect(function(input)
		if drag or not Library:IsPointerInput(input) then
			return
		end
		local point = Library:GetPointerPosition(input)
		local offset = point - Inner.AbsolutePosition
		if
			offset.X < 0
			or offset.X > Inner.AbsoluteSize.X
			or offset.Y < 0
			or offset.Y > 28
			or (search.Visible and Library:IsMouseOverFrame(search, input))
			or Library:IsMouseOverFrame(minimize, input)
		then
			return
		end
		Window:ClosePopups()
		drag, dragInput, sizeStart, pointerStart = "move", input, pendingPosition or Outer.AbsolutePosition, point
	end)
	local function queueDrag(pointer)
		local delta = pointer - pointerStart
		if drag == "resize" then
			pendingSize = sizeStart + delta
		else
			pendingPosition = sizeStart + delta
		end
	end
	Library:GiveSignal(RenderStepped:Connect(function()
		if searchDirty then
			Window:RefreshSearch()
		end
		if drag then
			queueDrag(Library:GetPointerPosition(dragInput))
			if not Library:IsPointerDown(dragInput) then
				drag, dragInput = nil, nil
			end
		end
		if pendingSize then
			local size = pendingSize
			pendingSize = nil
			Window:SetSize(size)
		end
		if pendingPosition then
			local position = UDim2.fromOffset(pendingPosition.X, pendingPosition.Y)
			pendingPosition = nil
			if Outer.Position ~= position then
				Outer.Position = position
			end
		end
	end))
	Library:GiveSignal(InputService.InputEnded:Connect(function(input)
		if drag and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
			queueDrag(Library:GetPointerPosition(dragInput))
			drag, dragInput = nil, nil
		end
	end))

	Library:GiveSignal(ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		Window:ClampPosition()
	end))
	Window:SetSize(
		Vector2.new(
			math.min(Config.Size.X.Offset, ScreenGui.AbsoluteSize.X - 16),
			math.min(Config.Size.Y.Offset, ScreenGui.AbsoluteSize.Y - 40)
		)
	)
	Window:ClampPosition()
	Window:SetTabPosition(Window.TabPosition)
	Library.NotificationArea.Position = Config.NotifySide == "Left" and UDim2.new(0, 8, 0, 40)
		or UDim2.new(1, -308, 0, 40)
	Library.NotificationArea.UIListLayout.HorizontalAlignment = Config.NotifySide == "Left"
			and Enum.HorizontalAlignment.Left
		or Enum.HorizontalAlignment.Right

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title
		if self.Minimized then
			self:SetSize(self.ExpandedSize)
		end
	end

	function Window:AddTab(Name)
		local Tab = { Name = Name, Window = Window, Groupboxes = {}, Tabboxes = {}, Boxes = {} }
		Tab.MainTab = Tab
		table.insert(Window.TabOrder, Tab)

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 14)

		local TabButton = Library:Create("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Library.BackgroundColor,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0),
			ZIndex = 1,
			Parent = TabArea,
		})

		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = "BackgroundColor",
		})

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, -1),
			Text = Name,
			ZIndex = 1,
			Parent = TabButton,
		})

		local Blocker = Library:Create("Frame", {
			BackgroundColor3 = Library.AccentColor,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6, 1, -2),
			Size = UDim2.fromOffset(TabButtonWidth, 2),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = TabButton,
		})

		Library:AddToRegistry(Blocker, {
			BackgroundColor3 = "AccentColor",
		})

		local TabFrame = Library:Create("Frame", {
			Name = "TabFrame",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.fromOffset(TabContainer.AbsoluteSize.X, TabContainer.AbsoluteSize.Y),
			Visible = false,
			ZIndex = 2,
			Parent = TabContainer,
		})

		function Tab:RefreshSides()
			if not self.Sides or not self.Container.Visible then
				return
			end
			local narrow = self.Container.AbsoluteSize.X < 440
			if self.Narrow == narrow and self.BoxCount == #self.Boxes then
				return
			end
			self.Narrow, self.BoxCount = narrow, #self.Boxes
			local left, right = self.Sides[1], self.Sides[2]
			local size = UDim2.new(narrow and 1 or 0.5, narrow and -14 or -10, 1, -14)
			if left.Size ~= size then
				left.Size = size
			end
			if right.Visible == narrow then
				right.Visible = not narrow
			end
			for index, box in ipairs(self.Boxes) do
				if box.Holder.LayoutOrder ~= index then
					box.Holder.LayoutOrder = index
				end
				local parent = narrow and left or self.Sides[box.Side]
				if box.Holder.Parent ~= parent then
					box.Holder.Parent = parent
				end
			end
		end

		local LeftSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -10, 1, -14),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.AccentColor,
			ZIndex = 2,
			Parent = TabFrame,
		})

		local RightSide = Library:Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1),
			Size = UDim2.new(0.5, -10, 1, -14),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			BottomImage = "",
			TopImage = "",
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.AccentColor,
			ZIndex = 2,
			Parent = TabFrame,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = LeftSide,
		})

		Library:Create("UIListLayout", {
			Padding = UDim.new(0, 8),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Parent = RightSide,
		})

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild("UIListLayout"):GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y)
			end)
		end

		function Tab:ShowTab()
			Window:ClosePopups()
			Window.ActiveTab = self
			for _, Tab in next, Window.Tabs do
				Tab:HideTab()
			end

			Blocker.BackgroundTransparency = 0
			TabButtonLabel.TextColor3 = Library.AccentColor
			Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = "AccentColor"
			TabButton.BackgroundColor3 = Library.MainColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "MainColor"
			TabFrame.Size = UDim2.fromScale(1, 1)
			TabFrame.Visible = true
			self:RefreshSides()
		end

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1
			TabButtonLabel.TextColor3 = Library.FontColor
			Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = "FontColor"
			TabButton.BackgroundColor3 = Library.BackgroundColor
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = "BackgroundColor"
			TabFrame.Visible = false
			local size = UDim2.fromOffset(TabFrame.AbsoluteSize.X, TabFrame.AbsoluteSize.Y)
			if TabFrame.Size ~= size then
				TabFrame.Size = size
			end
		end

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position
			TabListLayout:ApplyLayout()
		end

		function Tab:AddGroupbox(Info)
			local Groupbox = { Name = Info.Name, Window = Window, MainTab = Tab, Tabboxes = {} }

			local BoxOuter = Library:Create("Frame", {
				BackgroundColor3 = Library.MainColor,
				BorderColor3 = Library.OutlineColor,
				BorderMode = Enum.BorderMode.Inset,
				Size = UDim2.new(1, 0, 0, 507 + 2),
				ZIndex = 2,
				Parent = (Info.Side == nil or Info.Side == 1 or Info.Side == "Left") and LeftSide or RightSide,
			})

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = "MainColor",
				BorderColor3 = "OutlineColor",
			})

			local BoxInner = Library:Create("Frame", {
				BackgroundColor3 = Library.MainColor,
				BorderColor3 = Color3.new(0, 0, 0),

				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				ZIndex = 4,
				Parent = BoxOuter,
			})

			Library:RoundSurface(BoxOuter, 2, true)
			Library:RoundSurface(BoxInner, 2)
			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = "MainColor",
			})

			local Header = Library:Create("Frame", {
				Name = "SectionHeader",
				BackgroundColor3 = Library.BackgroundColor,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 22),
				ZIndex = 5,
				Parent = BoxInner,
			})
			Library:RoundSurface(Header, 2)
			Library:AddToRegistry(Header, { BackgroundColor3 = "BackgroundColor" })

			local Highlight = Library:Create("Frame", {
				BackgroundColor3 = Library.AccentColor,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 2, 0, 12),
				Position = UDim2.fromOffset(7, 5),
				ZIndex = 6,
				Parent = Header,
			})

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = "AccentColor",
			})

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18),
				Position = UDim2.new(0, 15, 0, 2),
				TextSize = 14,
				Text = Info.Name,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 6,
				Parent = Header,
			})

			local Container = Library:Create("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 7, 0, 22),
				Size = UDim2.new(1, -10, 1, -22),
				ZIndex = 1,
				Parent = BoxInner,
			})

			Library:Create("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = Container,
			})

			function Groupbox:Resize()
				local Size = 0

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA("UIListLayout")) and Element.Visible then
						Size = Size + Element.Size.Y.Offset
					end
				end

				local size = UDim2.new(1, 0, 0, 22 + Size + 2 + 2)
				if BoxOuter.Size ~= size then
					BoxOuter.Size = size
				end
			end

			Groupbox.Container = Container
			Groupbox.Holder = BoxOuter
			table.insert(
				Tab.Boxes,
				{ Holder = BoxOuter, Side = (Info.Side == nil or Info.Side == 1 or Info.Side == "Left") and 1 or 2 }
			)
			Tab:RefreshSides()
			setmetatable(Groupbox, BaseGroupbox)

			Groupbox:AddBlank(7)
			Groupbox:Resize()

			Tab.Groupboxes[Info.Name] = Groupbox

			return Groupbox
		end

		function Tab:AddLeftGroupbox(Name)
			return Tab:AddGroupbox({ Side = 1, Name = Name })
		end

		function Tab:AddRightGroupbox(Name)
			return Tab:AddGroupbox({ Side = 2, Name = Name })
		end

		function Tab:AddTabbox(Info)
			Info = Info or {}
			if Info.Side == nil then
				Info.Side = "Left"
			end
			return Library:CreateTabbox(Info, (Info.Side == 1 or Info.Side == "Left") and LeftSide or RightSide, self)
		end

		function Tab:AddLeftTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 1 })
		end

		function Tab:AddRightTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 2 })
		end

		TabButton.Activated:Connect(function(Input)
			if Library:IsPointerInput(Input) then
				Tab:ShowTab()
			end
		end)

		if #Window.TabOrder == 1 then
			Tab:ShowTab()
		end

		Tab.Container = TabFrame
		Tab.Button = TabButton
		Tab.ButtonWidth = TabButtonWidth + 12
		Tab.Label = TabButtonLabel
		Tab.Sides = { LeftSide, RightSide }
		Tab:RefreshSides()
		TabFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if TabFrame.Visible then
				Tab:RefreshSides()
			end
		end)
		Window.Tabs[Name] = Tab
		Window:SetTabPosition(Window.TabPosition)
		return Tab
	end

	local ModalElement = Library:Create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 0, 0),
		Visible = true,
		Text = "",
		Modal = false,
		Parent = ScreenGui,
	})

	local Toggled = false

	function Library:Toggle()
		if Library.Unloaded then
			return
		end
		Window:ClosePopups()
		Toggled = not Toggled
		Outer.Visible = Toggled
		ModalElement.Modal = Toggled

		if Toggled then
			if Config.ShowCustomCursor then
				task.spawn(function()
					local State = InputService.MouseIconEnabled

					local Cursor = Drawing.new("Triangle")
					Cursor.Thickness = 1
					Cursor.Filled = true
					Cursor.Visible = true

					local CursorOutline = Drawing.new("Triangle")
					CursorOutline.Thickness = 1
					CursorOutline.Filled = false
					CursorOutline.Color = Color3.new(0, 0, 0)
					CursorOutline.Visible = true

					while Toggled and ScreenGui.Parent do
						InputService.MouseIconEnabled = false

						local mPos = InputService:GetMouseLocation()

						Cursor.Color = Library.AccentColor

						Cursor.PointA = Vector2.new(mPos.X, mPos.Y)
						Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6)
						Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16)

						CursorOutline.PointA = Cursor.PointA
						CursorOutline.PointB = Cursor.PointB
						CursorOutline.PointC = Cursor.PointC

						RenderStepped:Wait()
					end

					InputService.MouseIconEnabled = State

					Cursor:Remove()
					CursorOutline:Remove()
				end)
			end
		end

		for _, overlay in ipairs(Outer:QueryDescendants('Frame[Name = "SurfaceHover"]')) do
			TweenService:Create(overlay, TweenInfo.new(0), { BackgroundTransparency = 1 }):Play()
		end
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if InputService:GetFocusedTextBox() then
			return
		end
		if type(Library.ToggleKeybind) == "table" and Library.ToggleKeybind.Type == "KeyPicker" then
			if
				Input.UserInputType == Enum.UserInputType.Keyboard
				and Input.KeyCode.Name == Library.ToggleKeybind.Value
			then
				task.spawn(Library.Toggle)
			end
		elseif
			Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and not Processed)
		then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then
		task.spawn(function()
			Library:Toggle()
		end)
	end

	Window.Holder = Outer

	return Window
end

local function OnPlayerChange()
	local PlayerList = GetPlayersString()

	for _, Value in next, Options do
		if Value.Type == "Dropdown" and Value.SpecialType == "Player" then
			Value:SetValues(PlayerList)
		end
	end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

getgenv().Library = Library
return Library
end

_G.StandOutParts = _G.StandOutParts or {}
_G.StandOutParts.Water = function()
	local rings = {
		{
			{-3061.239360809326, 1322.660397529602}, {-3061.239360809326, 1371.9904861450195}, {-3056.692434310913, 1371.9904861450195},
			{-3056.6923871040344, 1373.0574178695679}, {-3062.4094791412354, 1373.0574178695679}, {-3062.4094614982605, 1463.5173788070679},
			{-3074.5694546699524, 1463.5173788070679}, {-3074.569420814514, 1571.7704842090607}, {-3045.749400138855, 1571.7704842090607},
			{-3045.749400138855, 1649.820369720459}, {-3034.17130279541, 1649.8204110124238}, {-3034.17130279541, 1708.1170667432025},
			{-3063.5718501480874, 1761.9989362929318}, {-2840.057466747055, 1874.5612342643938}, {-2838.592697829783, 1901.6071446814458},
			{-2826.422033231798, 1900.947996488064}, {-2826.42178071883, 1971.7354446010706}, {-2774.448865929356, 1971.7354491446872},
			{-2774.448865147104, 1989.6312981352194}, {-2599.467801130057, 1989.6312949808566}, {-2599.4675799741926, 2021.8362963449933},
			{-2499.1784127025967, 2021.8360492221477}, {-2499.1784573125938, 1971.1812707355393}, {-2455.164680367901, 1971.1812728744246},
			{-2455.164486474523, 1992.6658868578893}, {-2354.8755833044233, 1992.6657663102926}, {-2354.8755741803357, 1960.8313212752223},
			{-2323.1626251113357, 1960.8313198890053}, {-2323.1624041929426, 1997.3059008371808}, {-2273.161427018475, 1997.3059297292673},
			{-2273.1614276304426, 2004.3060229074933}, {-2172.8722659483137, 2004.3060261952899}, {-2172.8722651200087, 1994.8313219812685},
			{-2155.328867931318, 1994.8313212144221}, {-2155.3288659205955, 2040.831295101438}, {-2142.119441542819, 2040.8313206394935},
			{-2142.119444291169, 2072.268782473409}, {-2137.1192950048126, 2072.2687829105357}, {-2137.119443748042, 2137.268782473409},
			{-2098.3289842034496, 2137.2686696427627}, {-2098.32898225556, 2181.8311997431038}, {-2083.328867693082, 2181.8312129838873},
			{-2083.328866075762, 2218.8311806605197}, {-1970.3289890389476, 2218.831386292066}, {-1970.3289887766862, 2224.831230251584},
			{-1861.4691697207902, 2224.831386385248}, {-1861.469173696554, 2270.3088249763273}, {-1845.3691479984643, 2270.3088263838363},
			{-1845.3691607825735, 2313.6186432242516}, {-1768.693472569639, 2313.6186499274536}, {-1763.4911922782096, 2371.908558167141},
			{-1719.6283506743112, 2367.9939513834433}, {-1718.903427528738, 2376.1164863621716}, {-1651.268005276498, 2370.080058351586},
			{-1651.2680595964496, 2401.9925961548865}, {-1620.2442442275585, 2401.9925988670743}, {-1619.9571616554404, 2405.2092698000524},
			{-1591.569953624503, 2402.6757583322715}, {-1598.6872053516304, 2456.7338353920495}, {-1572.3238508719007, 2460.2046274643903},
			{-1572.3238503012547, 2473.259487573334}, {-1521.4107908292913, 2473.259498582191}, {-1521.4107900768925, 2490.4723759749486},
			{-1462.8950642190248, 2490.472364294293}, {-1462.5915199426893, 2495.5812447818066}, {-1382.8131315006212, 2490.8414561742115},
			{-1382.8132268866025, 2504.65376899944}, {-1239.269569583746, 2504.653775282671}, {-1239.2696315344388, 2492.6537693341925},
			{-1236.2134074355693, 2492.653769601376}, {-1236.213363789661, 2519.85362553325}, {-1162.517105244739, 2519.8536319759814},
			{-1162.5170572212621, 2339.7426360674513}, {-1010.9853294388721, 2339.7426368151437}, {-1010.9853314152009, 2362.3492029332647},
			{-1010.3630200896819, 2362.349202987669}, {-1010.3630200906096, 2362.359814467004}, {-1006.3170339150724, 2362.3598148207157},
			{-1006.3170339141362, 2362.3491057223887}, {-1006.2879744616467, 2362.3491057249294}, {-1006.2879758615877, 2378.3625637666732},
			{-1010.0096902218125, 2378.2065794603545}, {-1010.0389972541774, 2378.905831877355}, {-1010.0664641152534, 2378.904680687646},
			{-1016.211889272687, 2525.5303899709897}, {-1016.184499896452, 2525.531537913158}, {-1016.1877608470653, 2525.60934270655},
			{-983.0611936146813, 2526.997855801983}, {-983.0611932631938, 2535.0389510383307}, {-874.2151542431204, 2535.038943859984},
			{-874.2468215137446, 2553.18181157401}, {-863.6267550923263, 2553.2003425271155}, {-863.6715604138313, 2578.9014874976415},
			{-817.89175491769, 2578.981368676833}, {-816.8616239310791, 2590.3000921650514}, {-799.959262102656, 2588.761866217128},
			{-797.3812547193314, 2597.5210409940937}, {-785.0984984636307, 2593.9060380606084}, {-785.0984984636307, 2650.474786758423},
			{-784.9988361778054, 2650.474786758423}, {-784.99883617338, 2650.5760266456}, {-703.668955193412, 2650.576025271235},
			{-703.6689954774511, 2689.640421193159}, {-653.7749450571293, 2689.6404255550356}, {-653.7749474564653, 2744.53083186027},
			{-575.0074980362149, 2744.5308259523927}, {-575.0075415490875, 2722.1568365354196}, {-520.9744439993307, 2722.1568369186},
			{-520.9744440011985, 2722.1782029681262}, {-517.8219440870292, 2722.178203243727}, {-517.8219428192366, 2707.6763457122433},
			{-446.22178184615683, 2707.676346612656}, {-446.22178184457096, 2707.6582062472366}, {-446.14225404648005, 2707.6582062541893},
			{-446.14225386872874, 2705.624968488977}, {-393.40780606212365, 2705.740685338844}, {-393.38186694183315, 2693.931386698125},
			{-388.2253953038617, 2693.942710317412}, {-388.22539619729844, 2745.6865294000168}, {-311.9579554016956, 2745.6865327337723},
			{-311.9579415328763, 2675.093669037628}, {-285.74059921092874, 2675.0936701836245}, {-285.7405929006052, 2690.3256075605723},
			{-285.76206595635125, 2690.325607561511}, {-285.7620658185511, 2693.47810747568}, {-247.38990093275277, 2693.4781057983796},
			{-247.48755651776892, 2737.9478324533434}, {-171.2202899282428, 2738.115315482735}, {-171.19156420803554, 2725.0343951710897},
			{-79.07824951272141, 2715.3516954502297}, {-85.79132497464114, 2651.490083217621}, {-66.44779777526855, 2651.490083217621},
			{-66.44779777526855, 2645.003731207679}, {-48.92490261088811, 2645.042171758895}, {-48.70637090685925, 2545.5281058892024},
			{-4.172065663777637, 2545.5281039425463}, {-4.172065805948925, 2542.275603885326}, {-4.190608736013923, 2542.275603886136},
			{-4.190608254447147, 2514.2112799972033}, {71.3163718883956, 2512.8932608781247}, {70.92077503648657, 2490.226089030185},
			{176.65660199111386, 2480.7894196341977}, {175.5898625633137, 2468.8368667674745}, {233.16214355617709, 2463.6986344116276},
			{227.68585668720448, 2402.3385431992783}, {310.40854963864984, 2402.3387108885763}, {310.40855033477084, 2335.9809455707095},
			{429.1165463929875, 2335.980950599039}, {429.1165467284394, 2250.5158976614475}, {497.36992263793945, 2250.5158976614475},
			{497.36992263793945, 2250.305995296317}, {627.674512687191, 2250.3059969462684}, {627.7078786947449, 2269.426901129957},
			{678.5280781052292, 2269.338219802907}, {678.4843834735912, 2244.293787190036}, {768.1665126862896, 2244.2947579310276},
			{768.166514008078, 2214.055763669507}, {783.856448764453, 2214.055599285337}, {783.8564510033434, 2162.8357576129365},
			{821.9569080934708, 2162.8357609437844}, {821.956880684152, 2097.850897362411}, {826.9568852052872, 2097.8508977995252},
			{826.9569028348418, 2066.3145966811394}, {849.9602481476558, 2066.3145976866476}, {849.9602481475847, 2066.3162230517264},
			{854.2064978233354, 2066.316223237336}, {854.2064998332927, 2020.33376323439}, {876.1396374646883, 2020.333764193118},
			{876.1396375796959, 2020.335754306521}, {880.1665121219322, 2020.3357544825415}, {880.1665147000224, 1961.3559285445954},
			{888.8445599599227, 1960.8859409069898}, {884.5888259662723, 1882.305804658454}, {944.8783530186181, 1878.0878236729943},
			{940.8880511223534, 1821.052996246304}, {974.3082831248139, 1824.5668464006221}, {982.5388007193069, 1746.2859837897122},
			{1192.1675853729248, 1746.2859837897122}, {1192.1675853729248, 1746.2049830071628}, {982.5473172554051, 1746.2049830071628},
			{982.552574610104, 1746.154980301857}, {1192.20090675354, 1746.154980301857}, {1192.2008514404297, 1723.6971926689148},
			{1192.2130813598633, 1723.6971926689148}, {1192.2130813598633, 1723.8487009778619}, {1263.2991485595703, 1723.8487009778619},
			{1263.2991523742676, 1771.986767411232}, {1263.3552169799805, 1771.986767411232}, {1263.3552169799805, 1772.0442164056003},
			{1263.3097467496991, 1772.0442164056003}, {1263.3097467496991, 1772.1252171881497}, {1386.880084991455, 1772.1251902356744},
			{1386.880084991455, 1825.1416746377945}, {1386.965950012207, 1825.1416746377945}, {1386.965950012207, 1825.1806910149753},
			{1386.9203424528241, 1825.1806910149753}, {1386.9203347129167, 1825.3022326175123}, {1494.7112348474304, 1825.3022326175123},
			{1498.10455175727, 1917.842746408056}, {1565.3419898828827, 1915.377202628546}, {1565.7805434197678, 1927.3373435419455},
			{1577.314217854067, 1926.9144217588619}, {1577.3142180067666, 1930.4077803592131}, {1632.1913782132754, 1930.4077735702747},
			{1632.2191323476418, 1946.651801235282}, {1644.0033339282627, 1946.631236173247}, {1651.2815638306552, 2081.0184126670497},
			{1849.9927559230375, 2070.256763570062}, {1849.9616535355551, 2069.682476043701}, {1870.9591808096661, 2069.682476043701},
			{1870.9591980414418, 2130.301845847169}, {2093.9183293163146, 2130.301981435441}, {2093.8776904741135, 2148.841027900021},
			{2141.834658424879, 2148.9461700613692}, {2141.846845427103, 2143.386577606201}, {2224.745351076126, 2143.386577606201},
			{2224.745361328125, 2163.1755913496017}, {2383.499277830124, 2163.175678253174}, {2383.499277830124, 2140.0925835371017},
			{2483.355884226965, 2140.0925835371017}, {2483.3559417116603, 2175.1853381344063}, {2483.374192249312, 2175.185338137162},
			{2483.3741922629974, 2175.2693389400856}, {2545.4393163167892, 2175.269214578235}, {2545.4393284747307, 2249.894123333927},
			{2548.5885189006035, 2249.8941228208582}, {2548.5885188973475, 2249.874139036077}, {2744.4469861252082, 2249.8741306768147},
			{2744.4469860994586, 2249.716081567064}, {2744.6075923135013, 2249.716081591315}, {2744.6074471093816, 2162.4932924684817},
			{2798.373745510848, 2162.493290118282}, {2798.3738832871313, 2031.7955739403112}, {2818.1191027007944, 2031.7955745287554},
			{2818.119104039015, 1986.8916604127696}, {2818.3270077548204, 1986.891660403682}, {2818.3270528123376, 1901.1597822652623},
			{2808.6734644591083, 1901.1598718808734}, {2808.6734696087797, 1842.2545025132495}, {2883.140074048345, 1842.2544907689369},
			{2883.140074049113, 1842.2369235103617}, {2883.2788580445363, 1842.2369235224946}, {2883.2788681336497, 1643.1487629238945},
			{2883.12008339441, 1643.1487629100131}, {2883.120083401473, 1642.987178631718}, {2794.756283966404, 1642.9871782379942},
			{2794.754344887983, 1641.8759226575494}, {2802.430943250656, 1641.8759226575494}, {2802.430943250656, 1641.8354357425123},
			{2803.8883969783783, 1641.8354357425123}, {2803.8883969783783, 1641.7949353512377}, {2802.430943250656, 1641.7949353512377},
			{2802.430943250656, 1641.717715261756}, {2803.9171497829566, 1641.7151219150342}, {2803.8415298405084, 1598.3785130865872},
			{2810.902407646179, 1598.3785130865872}, {2810.902407646179, 1598.2975123040378}, {2803.8413884987035, 1598.2975123040378},
			{2803.8413132724054, 1598.2544012865812}, {2810.92940519474, 1598.2420329652537}, {2810.837183616446, 1545.4040257818997},
			{2841.0992221832275, 1545.4040257818997}, {2841.0992221832275, 1545.342428447026}, {2841.17658835314, 1545.3424284537894},
			{2841.176561958249, 1495.8315160162747}, {2860.2737970352173, 1495.8315160162747}, {2860.2737970352173, 1495.7910021487623},
			{2862.1866814494133, 1495.7910021487623}, {2862.1866814494133, 1495.7505017574877}, {2841.17656196533, 1495.7505152337253},
			{2841.1765619680423, 1495.7194949063153}, {2862.19034646337, 1495.6828270721935}, {2862.0815521148525, 1433.3460733211548},
			{2855.3278698921204, 1433.357858104591}, {2855.3278698921204, 1373.8057283118121}, {2872.2834923500827, 1373.8057297941198},
			{2872.2835805182644, 1048.6791367202732}, {2636.3195650390726, 1048.6791349026732}, {2636.3197133307644, 845.4485458999607},
			{2504.8284964621316, 845.4485613421084}, {2504.8285023932644, 777.6043076187107}, {2074.4825398688504, 777.6043029159573},
			{2074.482535005717, 914.5136808636483}, {2066.692782334002, 914.5136777373148}, {2066.6924358578976, 840.0472376241667},
			{2066.6752195361737, 840.0472376310931}, {2066.675219592062, 839.9079824964787}, {1867.683434526994, 839.9082651244231},
			{1867.6834344630645, 840.0675556017263}, {1867.521780263078, 840.0675556667634}, {1867.5213957126234, 977.8291097201638},
			{1818.4864854812622, 977.8291075767798}, {1818.486473083496, 903.362133026123}, {1818.46865978347, 903.362133026123},
			{1818.4686597895336, 903.2234116280121}, {1619.4805012832176, 903.2234025347107}, {1619.4805012762795, 903.3821258544922},
			{1619.3191595077515, 903.3821258544922}, {1619.3191595077515, 1062.0950469970703}, {1639.5610269442761, 1062.0950469970703},
			{1639.561029113998, 1086.0408467212985}, {1596.191162273361, 1086.0408429297845}, {1596.191203907059, 1206.0770716920563},
			{1615.8592804323357, 1206.0770734114942}, {1615.8593059592545, 1206.0917017571628}, {1596.2021970748901, 1206.0917017571628},
			{1596.2021970748901, 1206.1727025397122}, {1615.859447308141, 1206.1727025397122}, {1615.9514250587883, 1259.0963907241821},
			{1548.986240386963, 1259.0963907241821}, {1548.9863166809082, 1283.2917030567098}, {1515.4710647605154, 1283.3501882144933},
			{1515.4719288504352, 1283.8453598518458}, {1511.869541168213, 1283.8516461304778}, {1511.869541168213, 1256.0619354248047},
			{1374.939542392554, 1256.063060760498}, {1374.9395847320557, 1227.826220870018}, {1129.7095947265625, 1227.826220870018},
			{1129.709550857544, 1260.9899171590805}, {1009.2397804260254, 1260.9899171590805}, {1009.239803314209, 1231.1146730184555},
			{881.6204993099931, 1231.1146730184555}, {888.8445729773636, 1097.7268361857473}, {880.1665121730573, 1097.2568472530247},
			{880.1665147640541, 1037.9817505762915}, {876.1396402218177, 1037.981750400271}, {876.1396402217305, 1037.983744738162},
			{854.206497889341, 1037.983743779434}, {854.2064998992903, 992.0014649365547}, {849.9602502235396, 992.0014647509453},
			{849.9602502234711, 992.0030303801291}, {826.9569044113159, 992.003029374621}, {826.9568862915039, 960.4622640609741},
			{821.956880569458, 960.4622640609741}, {821.9569091787284, 895.4767322540283}, {783.856449933573, 895.4767322540283},
			{783.8564521594272, 844.555122448179}, {768.1665128650968, 844.5551375823183}, {768.1665141996967, 814.0230523035863},
			{678.4843779530112, 814.0240804639614}, {678.5279383125845, 788.9764184774988}, {627.7078953044457, 788.887742588249},
			{627.6745261377097, 808.0115709819137}, {435.93307917148434, 808.0115694050024}, {433.279305119348, 778.2766777960709},
			{385.4063586815015, 782.549251146103}, {381.48359805677, 738.5956742052638}, {386.3467844580628, 738.1616450899395},
			{382.25426049011264, 692.3059496879578}, {404.95871925354004, 692.3059496879578}, {404.9587001800537, 540.5259594917297},
			{352.3900006464054, 540.5259594917297}, {359.59650271977216, 485.790056785754}, {224.73640066416124, 468.03544831797063},
			{223.48286410540152, 446.9356628096523}, {143.70390939712524, 451.6753864067004}, {143.7039127310886, 437.86469197273254},
			{0.16034698486328125, 437.86469197273254}, {0.16034555344951756, 449.86469197273254}, {-11.746083646781214, 449.86469197273254},
			{-27.15195027990655, 326.1796614177956}, {-89.27806979528219, 333.91791219108956}, {-90.45452393415167, 324.4728581222438},
			{-137.7394776611498, 330.36253798360667}, {-139.4650678487368, 316.5089993935633}, {-215.7987912102534, 326.0169084411334},
			{-214.4005334488232, 337.24282240668595}, {-222.81925949177622, 338.29142912128395}, {-221.47744928678063, 349.0640783419841},
			{-263.4804383938052, 354.27482165355826}, {-262.94799326340757, 358.57038120385477}, {-417.0971713390845, 358.5703780125495},
			{-417.27706890324475, 357.53961112147147}, {-421.6993533878333, 358.31142307399637}, {-422.2526995058911, 352.23155571994465},
			{-484.6604118347168, 357.9110731110651}, {-484.6604347229004, 331.4874219894409}, {-772.5258445739746, 331.4874076843262},
			{-772.5258856517027, 418.56220021513843}, {-782.6302690372058, 420.0723165785948}, {-783.8579901632659, 406.3156485895844},
			{-926.8332916506008, 419.07593795094664}, {-925.766516984886, 431.02848228117057}, {-952.2176159537477, 433.38919921042867},
			{-954.6356099395497, 406.29680493227744}, {-1081.903309058871, 417.65525907894187}, {-1076.724473843994, 475.6828490170981},
			{-1170.2523786515737, 471.7628965588327}, {-1171.5638146859856, 462.9879062298571}, {-1183.8235257034046, 464.82012084591895},
			{-1185.9891128902702, 450.329574285578}, {-1265.0299890495573, 462.14234574717375}, {-1266.2578314268815, 448.38568642736703},
			{-1409.2330108889332, 461.1459757921703}, {-1408.1663077958221, 473.0984022742525}, {-1453.085444339769, 477.10736107826233},
			{-1668.2258911132812, 477.10736107826233}, {-1668.2258660793304, 560.3210857213213}, {-1691.2815798605052, 560.3207074145537},
			{-1691.281578203089, 598.2379689216614}, {-1843.2994384765625, 598.2379689216614}, {-1843.2994384765625, 662.9364351121818},
			{-1942.85328073111, 662.9364367050854}, {-1942.8866495869054, 643.8127865110837}, {-1993.7068489973897, 643.9014626732398},
			{-1993.6630887840097, 668.9490072224835}, {-2083.328867715322, 668.9479771540501}, {-2083.328866381346, 699.4657822135276},
			{-2099.0189367583894, 699.4657632113704}, {-2099.0189345319236, 750.4013633728027}, {-2137.1194458007812, 750.4013633728027},
			{-2137.1192951202393, 815.3869571685791}, {-2142.119300842285, 815.3869571685791}, {-2142.1194410324097, 846.9278340621237},
			{-2169.3689748246998, 846.9274064038399}, {-2169.3689741996077, 861.2278384378476}, {-2171.0784191560692, 861.320419869672},
			{-2171.163772604298, 812.4159316584136}, {-2244.0517015457153, 812.5431833116338}, {-2244.0517444610596, 781.3704996109009},
			{-2288.791778564453, 781.3704996109009}, {-2288.7918739318848, 765.2621467113495}, {-2486.0494384765625, 765.2621467113495},
			{-2486.049545300282, 802.5978496339856}, {-2596.0852275252473, 802.7899570741095}, {-2595.8965460308673, 910.9649035825797},
			{-2611.359212044436, 911.8023425149939}, {-2612.220191188915, 895.9045146534037}, {-2793.36847476261, 905.7152656881703},
			{-2791.614825690187, 938.0942411436473}, {-2975.258962121183, 948.0401412419562}, {-2973.131575210861, 987.3173112869263},
			{-3015.759563446045, 987.3173246383667}, {-3015.7595978901845, 1006.9372863769531}, {-3072.5794563293457, 1006.9372863769531},
			{-3072.579387664795, 1151.8205261230469}, {-3049.9494347572327, 1151.820513010025}, {-3049.949504852295, 1177.7772521972656},
			{-3086.619358062744, 1177.7772521972656}, {-3086.619553565979, 1322.660397529602}, {-3061.239360809326, 1322.660397529602},
		},
		{
			{497.1422116756439, 2277.6510960943997}, {502.5621340274811, 2277.6510960943997}, {502.5621340274811, 2277.5700953118503},
			{497.1422116756439, 2277.5700953118503}, {497.1422116756439, 2277.6510960943997},
		},
		{
			{639.4720993041992, 2291.7453343756497}, {666.6172561645508, 2291.7453343756497}, {666.6172561645508, 2291.6643335931003},
			{639.4720993041992, 2291.6643335931003}, {639.4720993041992, 2291.7453343756497},
		},
		{
			{589.2808933258057, 2295.5521382838488}, {612.5091342926025, 2295.5521382838488}, {612.5091342926025, 2295.5117052737623},
			{635.6918096542358, 2295.5117052737623}, {635.6918096542358, 2295.4711700631806}, {639.4265489578247, 2295.4711644537747},
			{639.4265489578247, 2295.3901636712253}, {612.5091342926025, 2295.3901636712253}, {612.5091342926025, 2295.2281351536512},
			{570.9715785980225, 2295.2281351536512}, {570.9715785980225, 2295.5521382838488}, {571.2903957366943, 2295.5521382838488},
			{571.2903957366943, 2295.5927599612623}, {589.2808933258057, 2295.5927599612623}, {589.2808933258057, 2295.5521382838488},
		},
		{
			{505.06713926792145, 2313.1293675787747}, {528.2498550415039, 2313.1293675787747}, {528.2498550415039, 2313.0888537112623},
			{551.4780712127686, 2313.0888537112623}, {551.4780712127686, 2313.0484761744738}, {571.2903642430902, 2313.0485300794244},
			{571.2903642430902, 2312.8865285143256}, {571.1537208557129, 2312.8865285143256}, {571.1537208557129, 2312.7244730442762},
			{522.1466941833496, 2312.7244730442762}, {522.1466941833496, 2313.0483667962253}, {502.5621566772461, 2313.0483667962253},
			{502.56213319301605, 2313.1699083987623}, {505.06713926792145, 2313.1699083987623}, {505.06713926792145, 2313.1293675787747},
		},
		{
			{-1135.3398550332506, 2351.705845613633}, {-1122.198718863817, 2351.705844621505}, {-1122.1987191854994, 2347.445033292617},
			{-1135.339855354933, 2347.445034284745}, {-1135.3398550332506, 2351.705845613633},
		},
		{
			{-1040.839855354933, 2347.445034284745}, {-1040.8398550332506, 2351.705845613633}, {-1027.698718863817, 2351.705844621505},
			{-1027.6987191854994, 2347.445033292617}, {-1040.839855354933, 2347.445034284745},
		},
	}
	local pockets = {
		{-34, 326, -28, 328}, {-50, 328, -26, 330}, {-66, 330, -26, 332}, {-772, 332, -484, 358}, {-82, 332, -26, 334},
		{-90, 334, -26, 338}, {-88, 338, -26, 340}, {-88, 340, -28, 342}, {-88, 342, -44, 344}, {-88, 344, -60, 346},
		{-88, 346, -76, 348}, {-238, 350, -226, 352}, {-430, 352, -426, 354}, {-254, 352, -226, 354}, {-452, 354, -450, 356},
		{-264, 354, -226, 358}, {-474, 356, -472, 358}, {-772, 358, -494, 360}, {-422, 358, -226, 362}, {-772, 360, -516, 362},
		{-772, 362, -534, 364}, {-422, 362, -224, 364}, {-772, 364, -532, 386}, {-420, 364, -224, 370}, {-420, 370, -240, 372},
		{-232, 370, -224, 372}, {-376, 372, -240, 376}, {-376, 376, -248, 378}, {-244, 376, -240, 378}, {-376, 378, -250, 380},
		{-242, 378, -240, 380}, {-376, 380, -252, 382}, {-376, 382, -256, 384}, {-376, 384, -258, 386}, {-772, 386, -530, 402},
		{-376, 386, -260, 388}, {-376, 388, -264, 390}, {-376, 390, -266, 392}, {-376, 392, -360, 394}, {-356, 392, -268, 394},
		{-772, 402, -754, 404}, {-740, 402, -530, 408}, {-986, 408, -984, 410}, {-740, 408, -528, 412}, {-740, 412, -718, 414},
		{-708, 412, -528, 414}, {-706, 414, -528, 416}, {-1074, 416, -1072, 418}, {-706, 416, -576, 426}, {-550, 416, -528, 418},
		{-1082, 418, -1070, 428}, {-706, 426, -578, 428}, {-1080, 428, -1070, 438}, {-692, 428, -578, 430}, {-646, 430, -578, 432},
		{-624, 432, -578, 440}, {-624, 440, -592, 442}, {-624, 442, -614, 444}, {-1274, 448, -1266, 450}, {-1296, 450, -1288, 452},
		{-1318, 452, -1310, 454}, {-1340, 454, -1334, 456}, {-1362, 456, -1356, 458}, {-1386, 458, -1378, 460}, {-1408, 460, -1400, 462},
		{-1410, 462, -1408, 464}, {-1430, 474, -1424, 476}, {-1422, 474, -1420, 476}, {-1668, 478, -1472, 480}, {-1668, 480, -1624, 482},
		{-1622, 480, -1474, 482}, {-1668, 482, -1626, 486}, {-1620, 482, -1472, 484}, {-1616, 484, -1474, 486}, {-1668, 486, -1628, 490},
		{-1612, 486, -1480, 488}, {-1608, 488, -1482, 490}, {-1668, 490, -1630, 494}, {-1604, 490, -1484, 492}, {-1600, 492, -1490, 494},
		{-1668, 494, -1632, 496}, {-1596, 494, -1490, 496}, {-1668, 496, -1634, 500}, {-1592, 496, -1494, 498}, {-1476, 496, -1472, 498},
		{-1590, 498, -1494, 500}, {-1490, 498, -1488, 500}, {-1486, 498, -1472, 500}, {-1668, 500, -1636, 504}, {-1586, 500, -1472, 502},
		{-1582, 502, -1472, 504}, {-1668, 504, -1638, 508}, {-1578, 504, -1470, 506}, {-1574, 506, -1470, 508}, {-1668, 508, -1640, 512},
		{-1570, 508, -1470, 510}, {-1566, 510, -1470, 512}, {-1668, 512, -1642, 516}, {-1562, 512, -1470, 514}, {-1558, 514, -1470, 516},
		{-1668, 516, -1644, 520}, {-1556, 516, -1470, 518}, {-1552, 518, -1470, 520}, {-1668, 520, -1646, 524}, {-1548, 520, -1470, 522},
		{-1544, 522, -1470, 524}, {-1668, 524, -1648, 528}, {-1540, 524, -1470, 526}, {-1536, 526, -1470, 528}, {-1668, 528, -1650, 530},
		{-1532, 528, -1468, 530}, {-1668, 530, -1652, 534}, {-1528, 530, -1468, 532}, {-1526, 532, -1468, 534}, {-1668, 534, -1654, 538},
		{-1522, 534, -1468, 536}, {-1518, 536, -1468, 538}, {-1668, 538, -1656, 542}, {-1514, 538, -1508, 540}, {-1494, 538, -1468, 540},
		{-1510, 540, -1508, 542}, {-1470, 540, -1468, 542}, {352, 540, 404, 552}, {-1668, 542, -1658, 546}, {-1668, 546, -1660, 550},
		{-1668, 550, -1662, 554}, {350, 552, 404, 642}, {-1668, 554, -1664, 558}, {-1668, 558, -1666, 560}, {352, 642, 404, 656},
		{356, 656, 404, 658}, {358, 658, 404, 660}, {362, 660, 404, 664}, {364, 664, 404, 670}, {366, 670, 404, 676},
		{368, 676, 404, 686}, {366, 686, 404, 690}, {364, 690, 404, 692}, {364, 692, 382, 694}, {358, 694, 360, 696},
		{362, 694, 382, 696}, {358, 696, 382, 700}, {360, 700, 384, 716}, {362, 716, 384, 722}, {362, 722, 386, 730},
		{364, 730, 386, 736}, {974, 1232, 1010, 1242}, {-3034, 1650, -3012, 1710}, {-3036, 1710, -3012, 1714}, {-3038, 1714, -3012, 1716},
		{-3040, 1716, -3012, 1720}, {-3042, 1720, -2988, 1724}, {-3044, 1724, -2988, 1728}, {-3046, 1728, -2988, 1732}, {-3048, 1732, -2988, 1736},
		{-3050, 1736, -2988, 1738}, {-3052, 1738, -2988, 1742}, {-3054, 1742, -2988, 1746}, {-3056, 1746, -2988, 1750}, {974, 1746, 982, 1754},
		{-3058, 1750, -2988, 1754}, {-3060, 1754, -2988, 1758}, {974, 1754, 980, 1756}, {974, 1756, 976, 1758}, {-3062, 1758, -2988, 1760},
		{-3064, 1760, -2988, 1762}, {-3062, 1762, -2846, 1764}, {-3058, 1764, -2846, 1766}, {-3054, 1766, -2846, 1768}, {-3050, 1768, -2846, 1770},
		{-3046, 1770, -2846, 1772}, {976, 1770, 980, 1772}, {-3042, 1772, -2846, 1774}, {974, 1772, 980, 1778}, {-3038, 1774, -2846, 1776},
		{-3034, 1776, -2846, 1778}, {-3030, 1778, -2846, 1780}, {976, 1778, 980, 1780}, {-3026, 1780, -2846, 1782}, {-3022, 1782, -2846, 1784},
		{-3018, 1784, -2844, 1786}, {-3014, 1786, -2844, 1788}, {-3010, 1788, -2844, 1790}, {-3006, 1790, -2844, 1792}, {-3002, 1792, -2844, 1794},
		{-2998, 1794, -2844, 1796}, {974, 1794, 978, 1800}, {-2994, 1796, -2844, 1798}, {-2990, 1798, -2844, 1800}, {-2986, 1800, -2844, 1802},
		{974, 1800, 976, 1818}, {-2982, 1802, -2844, 1804}, {-2978, 1804, -2844, 1806}, {-2974, 1806, -2844, 1808}, {-2970, 1808, -2844, 1810},
		{-2966, 1810, -2844, 1812}, {-2962, 1812, -2844, 1814}, {-2958, 1814, -2844, 1816}, {-2954, 1816, -2844, 1818}, {-2950, 1818, -2844, 1820},
		{-2946, 1820, -2842, 1822}, {-2942, 1822, -2842, 1824}, {960, 1822, 974, 1824}, {-2938, 1824, -2842, 1826}, {-2934, 1826, -2842, 1828},
		{-2930, 1828, -2842, 1830}, {-2926, 1830, -2842, 1832}, {-2922, 1832, -2842, 1834}, {-2918, 1834, -2842, 1836}, {-2914, 1836, -2842, 1838},
		{-2910, 1838, -2842, 1840}, {-2906, 1840, -2842, 1842}, {-2902, 1842, -2842, 1844}, {-2898, 1844, -2842, 1846}, {-2894, 1846, -2842, 1848},
		{-2890, 1848, -2842, 1850}, {-2886, 1850, -2842, 1852}, {-2882, 1852, -2842, 1854}, {-2878, 1854, -2842, 1856}, {-2874, 1856, -2842, 1858},
		{-2870, 1858, -2840, 1860}, {-2868, 1860, -2840, 1862}, {-2864, 1862, -2840, 1864}, {-2860, 1864, -2840, 1866}, {-2856, 1866, -2840, 1868},
		{-2852, 1868, -2840, 1870}, {-2848, 1870, -2840, 1872}, {-2844, 1872, -2840, 1874}, {-1594, 2356, -1590, 2358}, {-1618, 2358, -1590, 2360},
		{-1640, 2360, -1590, 2362}, {-1662, 2362, -1590, 2364}, {-1684, 2364, -1590, 2366}, {-1706, 2366, -1590, 2368}, {-1720, 2368, -1590, 2370},
		{-1720, 2370, -1662, 2372}, {-1652, 2370, -1592, 2384}, {-1720, 2372, -1684, 2374}, {-1720, 2374, -1706, 2376}, {-1652, 2384, -1594, 2400},
		{-1652, 2400, -1596, 2402}, {-1620, 2402, -1596, 2404}, {-1620, 2404, -1618, 2406}, {-1572, 2460, -1568, 2462}, {-1572, 2462, -1552, 2464},
		{-1572, 2464, -1538, 2466}, {-1572, 2466, -1522, 2468}, {-1572, 2468, -1506, 2470}, {-1572, 2470, -1492, 2472}, {-1572, 2472, -1476, 2474},
		{-1522, 2474, -1464, 2490}, {156, 2474, 176, 2476}, {134, 2476, 176, 2478}, {110, 2478, 176, 2480}, {88, 2480, 174, 2482},
		{68, 2482, 152, 2484}, {68, 2484, 130, 2486}, {68, 2486, 108, 2488}, {68, 2488, 84, 2490}, {68, 2490, 70, 2494},
		{68, 2494, 72, 2512}, {-34, 2514, -4, 2546}, {-140.625, 316.375, -139.375, 316.875}, {-142.625, 316.625, -141.375, 317.125}, {-144.625, 316.875, -143.375, 317.375},
		{-146.625, 317.125, -145.375, 317.625}, {-148.625, 317.375, -147.375, 317.875}, {-150.625, 317.625, -149.375, 318.125}, {-152.625, 317.875, -151.375, 318.375}, {-154.625, 318.125, -153.375, 318.625},
		{-156.625, 318.375, -155.375, 318.875}, {-158.625, 318.625, -157.375, 319.125}, {-160.625, 318.875, -159.375, 319.375}, {-162.625, 319.125, -161.375, 319.625}, {-164.625, 319.375, -163.375, 319.875},
		{-166.625, 319.625, -165.375, 320.125}, {-168.625, 319.875, -167.375, 320.375}, {-170.625, 320.125, -169.375, 320.625}, {-172.625, 320.375, -171.375, 320.875}, {-174.625, 320.625, -173.375, 321.125},
		{-176.625, 320.875, -175.375, 321.375}, {-178.625, 321.125, -177.375, 321.625}, {-180.625, 321.375, -179.375, 321.875}, {-182.875, 321.625, -181.375, 322.125}, {-184.875, 321.875, -183.375, 322.375},
		{-186.875, 322.125, -185.375, 322.625}, {-188.875, 322.375, -187.375, 322.875}, {-190.875, 322.625, -189.375, 323.125}, {-192.875, 322.875, -191.375, 323.375}, {-194.875, 323.125, -193.375, 323.625},
		{-196.875, 323.375, -195.375, 323.875}, {-198.875, 323.625, -197.375, 324.125}, {-200.875, 323.875, -199.375, 324.375}, {-202.875, 324.125, -201.375, 324.625}, {-204.875, 324.375, -203.625, 324.875},
		{-90.875, 324.375, -90.375, 325.125}, {-206.875, 324.625, -205.625, 325.125}, {-208.875, 324.875, -207.625, 325.375}, {-90.875, 324.875, -90.125, 326.125}, {-210.875, 325.125, -209.625, 325.625},
		{-212.875, 325.375, -211.625, 325.875}, {-214.875, 325.625, -213.625, 326.125}, {-90.625, 325.875, -90.125, 327.125}, {-28.125, 326.125, -26.875, 328.125}, {-90.625, 326.875, -89.875, 328.125},
		{-34.875, 326.875, -33.875, 327.375}, {-36.875, 327.125, -33.875, 327.625}, {-38.875, 327.375, -33.875, 327.875}, {-40.875, 327.625, -33.875, 328.125}, {-90.375, 327.875, -89.875, 329.125},
		{-90.375, 328.875, -89.625, 330.125}, {-51.125, 328.875, -49.875, 329.375}, {-53.125, 329.125, -49.875, 329.625}, {-55.125, 329.375, -49.875, 329.875}, {-57.125, 329.625, -49.875, 330.125},
		{-90.125, 329.875, -89.625, 331.125}, {-90.125, 330.875, -89.375, 332.125}, {-67.125, 330.875, -65.875, 331.375}, {-69.125, 331.125, -65.875, 331.625}, {-772.625, 331.375, -484.625, 332.125},
		{-71.125, 331.375, -65.875, 331.875}, {-73.125, 331.625, -65.875, 332.125}, {-772.625, 331.875, -771.875, 404.125}, {-89.875, 331.875, -89.375, 333.125}, {-89.875, 332.875, -89.125, 334.125},
		{-83.125, 332.875, -81.875, 333.375}, {-85.125, 333.125, -81.875, 333.625}, {-87.125, 333.375, -81.875, 333.875}, {-89.125, 333.625, -81.875, 334.125}, {-26.125, 336.125, -25.625, 338.375},
		{-89.125, 337.875, -87.875, 340.125}, {-26.125, 338.125, -25.375, 340.125}, {-88.875, 339.875, -87.875, 342.125}, {-28.125, 339.875, -25.375, 340.375}, {-28.125, 340.125, -25.125, 340.625},
		{-28.125, 340.375, -25.625, 340.875}, {-28.125, 340.625, -27.625, 341.125}, {-88.625, 341.875, -87.875, 344.125}, {-44.125, 341.875, -37.875, 342.375}, {-44.125, 342.125, -39.875, 342.625},
		{-44.125, 342.375, -41.875, 342.875}, {-88.375, 343.875, -87.875, 346.125}, {-60.125, 343.875, -53.875, 344.375}, {-60.125, 344.125, -55.875, 344.625}, {-60.125, 344.375, -57.875, 344.875},
		{-76.125, 345.875, -69.875, 346.375}, {-76.125, 346.125, -71.875, 346.625}, {-76.125, 346.375, -73.875, 346.875}, {-87.875, 347.875, -85.875, 348.375}, {-226.125, 349.375, -225.625, 349.875},
		{-228.125, 349.625, -225.625, 350.125}, {-226.125, 349.875, -225.625, 351.625}, {-238.375, 350.875, -237.875, 351.375}, {-240.375, 351.125, -237.875, 351.625}, {-242.375, 351.375, -237.875, 351.875},
		{-226.125, 351.375, -225.375, 353.625}, {-244.375, 351.625, -237.875, 352.125}, {-424.125, 352.125, -422.125, 352.625}, {-426.125, 352.375, -422.125, 353.125}, {-432.375, 352.875, -429.875, 353.375},
		{-426.125, 352.875, -423.625, 353.375}, {-422.625, 352.875, -422.125, 353.625}, {-254.375, 352.875, -253.875, 353.375}, {-434.875, 353.125, -429.875, 353.875}, {-256.375, 353.125, -253.875, 353.625},
		{-437.875, 353.375, -435.125, 353.875}, {-422.625, 353.375, -421.875, 353.875}, {-258.375, 353.375, -253.875, 353.875}, {-226.125, 353.375, -225.125, 355.625}, {-440.625, 353.625, -435.125, 354.125},
		{-434.875, 353.625, -432.125, 354.125}, {-422.375, 353.625, -421.875, 356.375}, {-260.375, 353.625, -253.875, 354.125}, {-443.375, 353.875, -435.125, 354.375}, {-446.125, 354.125, -437.625, 354.625},
		{-448.875, 354.375, -440.375, 354.875}, {-450.125, 354.625, -443.125, 355.125}, {-454.375, 354.875, -451.875, 355.375}, {-450.125, 354.875, -445.875, 355.375}, {-457.125, 355.125, -451.875, 355.625},
		{-450.125, 355.125, -448.875, 355.625}, {-459.875, 355.375, -451.875, 355.875}, {-226.125, 355.375, -224.875, 357.625}, {-462.625, 355.625, -454.375, 356.125}, {-465.375, 355.875, -457.125, 356.375},
		{-468.125, 356.125, -459.875, 356.625}, {-422.375, 356.125, -421.625, 356.875}, {-470.875, 356.375, -462.875, 356.875}, {-472.125, 356.625, -465.625, 357.125}, {-422.125, 356.625, -421.625, 358.125},
		{-476.375, 356.875, -473.875, 357.375}, {-472.125, 356.875, -468.375, 357.375}, {-479.125, 357.125, -473.875, 357.625}, {-472.125, 357.125, -471.125, 357.625}, {-481.875, 357.375, -473.875, 357.875},
		{-417.875, 357.375, -417.125, 357.875}, {-226.125, 357.375, -224.625, 359.625}, {-484.125, 357.625, -476.625, 358.125}, {-419.375, 357.625, -417.125, 358.125}, {-494.125, 357.875, -479.625, 358.375},
		{-494.125, 358.125, -482.375, 358.625}, {-494.125, 358.375, -485.125, 358.875}, {-494.125, 358.625, -487.875, 359.125}, {-494.125, 358.875, -490.625, 359.375}, {-494.125, 359.125, -493.625, 359.625},
		{-226.125, 359.375, -224.375, 361.625}, {-516.125, 359.875, -501.875, 360.375}, {-516.125, 360.125, -504.625, 360.625}, {-516.125, 360.375, -507.375, 360.875}, {-516.125, 360.625, -510.375, 361.125},
		{-516.125, 360.875, -513.125, 361.375}, {-226.125, 361.375, -224.125, 362.125}, {-534.125, 361.875, -524.125, 362.375}, {-534.125, 362.125, -527.125, 362.625}, {-534.125, 362.375, -529.875, 362.875},
		{-534.125, 362.625, -532.625, 364.125}, {-421.625, 363.875, -419.875, 365.125}, {-421.375, 364.875, -419.875, 367.875}, {-224.125, 365.375, -223.625, 367.625}, {-224.125, 367.375, -223.375, 369.625},
		{-421.125, 367.625, -419.875, 370.875}, {-224.125, 369.375, -223.125, 371.625}, {-240.125, 369.875, -231.875, 372.125}, {-420.875, 370.625, -419.875, 372.125}, {-224.125, 371.375, -222.875, 372.125},
		{-420.875, 371.875, -375.875, 373.125}, {-240.125, 371.875, -222.875, 373.625}, {-240.125, 373.375, -222.625, 375.625}, {-532.125, 373.625, -531.625, 376.625}, {-240.125, 375.375, -222.375, 377.625},
		{-248.125, 375.875, -243.875, 378.125}, {-532.125, 376.375, -531.375, 379.375}, {-240.125, 377.375, -222.125, 379.625}, {-250.125, 377.875, -241.875, 380.125}, {-532.125, 379.125, -531.125, 382.125},
		{-240.125, 379.375, -221.875, 380.125}, {-252.125, 379.875, -221.875, 381.625}, {-252.125, 381.375, -221.625, 382.125}, {-532.125, 381.875, -530.875, 384.875}, {-256.125, 381.875, -221.625, 383.625},
		{-256.125, 383.375, -221.375, 384.125}, {-258.125, 383.875, -221.375, 385.625}, {-532.125, 384.625, -530.625, 386.125}, {-258.125, 385.375, -221.125, 386.125}, {-260.125, 385.875, -221.125, 387.625},
		{-260.125, 387.375, -220.875, 388.125}, {-264.125, 387.875, -220.875, 389.625}, {-264.125, 389.375, -220.625, 390.125}, {-266.125, 389.875, -220.625, 391.625}, {-266.125, 391.375, -220.375, 392.125},
		{-360.125, 391.875, -355.875, 394.125}, {-268.125, 391.875, -220.375, 393.625}, {-268.125, 393.375, -220.125, 394.125}, {-376.125, 393.875, -220.125, 394.375}, {-530.125, 395.875, -529.625, 398.875},
		{-530.125, 398.625, -529.375, 401.875}, {-530.125, 401.625, -529.125, 404.625}, {-754.125, 401.875, -741.375, 402.375}, {-740.875, 401.875, -739.875, 402.625}, {-754.125, 402.125, -744.125, 402.625},
		{-754.125, 402.375, -746.875, 402.875}, {-740.625, 402.375, -739.875, 405.375}, {-754.125, 402.625, -749.625, 403.125}, {-754.125, 402.875, -752.625, 403.375}, {-772.625, 403.875, -763.625, 404.375},
		{-772.625, 404.125, -766.625, 404.625}, {-772.625, 404.375, -769.375, 404.875}, {-530.125, 404.375, -528.875, 407.375}, {-772.625, 404.625, -772.125, 405.125}, {-740.375, 405.125, -739.875, 408.375},
		{-955.625, 406.125, -954.375, 406.625}, {-958.625, 406.375, -957.125, 406.875}, {-954.875, 406.375, -954.375, 408.875}, {-961.375, 406.625, -960.125, 407.125}, {-964.125, 406.875, -962.875, 407.375},
		{-966.875, 407.125, -965.625, 407.625}, {-530.125, 407.125, -528.625, 408.125}, {-969.875, 407.375, -968.375, 407.875}, {-972.625, 407.625, -971.125, 408.125}, {-975.375, 407.875, -973.875, 408.375},
		{-978.125, 408.125, -976.875, 408.625}, {-980.875, 408.375, -979.625, 408.875}, {-983.875, 408.625, -982.375, 409.125}, {-986.625, 408.875, -985.875, 409.375}, {-954.625, 408.875, -954.125, 411.625},
		{-989.375, 409.125, -987.875, 409.625}, {-992.125, 409.375, -990.875, 409.875}, {-994.875, 409.625, -993.625, 410.125}, {-997.875, 409.875, -996.375, 410.375}, {-1000.625, 410.125, -999.125, 410.625},
		{-1003.375, 410.375, -1001.875, 410.875}, {-1006.125, 410.625, -1004.625, 411.125}, {-1008.875, 410.875, -1007.625, 411.375}, {-1011.875, 411.125, -1010.375, 411.625}, {-1014.625, 411.375, -1013.125, 411.875},
		{-1017.375, 411.625, -1015.875, 412.125}, {-1020.125, 411.875, -1018.625, 412.375}, {-954.375, 411.875, -953.875, 414.375}, {-718.125, 411.875, -707.875, 412.375}, {-1022.875, 412.125, -1021.625, 412.625},
		{-718.125, 412.125, -710.125, 412.625}, {-1025.875, 412.375, -1024.375, 412.875}, {-718.125, 412.375, -712.875, 412.875}, {-1028.625, 412.625, -1027.125, 413.125}, {-718.125, 412.625, -715.625, 413.125},
		{-1031.375, 412.875, -1029.875, 413.375}, {-1034.125, 413.125, -1032.625, 413.625}, {-1036.875, 413.375, -1035.375, 413.875}, {-1039.875, 413.625, -1038.375, 414.125}, {-1042.625, 413.875, -1041.125, 414.375},
		{-739.625, 413.875, -729.625, 414.375}, {-707.375, 413.875, -705.875, 415.125}, {-1045.375, 414.125, -1043.875, 414.625}, {-739.625, 414.125, -732.375, 414.625}, {-1048.125, 414.375, -1046.625, 414.875},
		{-739.625, 414.375, -735.125, 414.875}, {-1050.875, 414.625, -1049.375, 415.125}, {-954.125, 414.625, -953.625, 417.125}, {-739.625, 414.625, -737.875, 415.125}, {-1053.875, 414.875, -1052.375, 415.375},
		{-707.125, 414.875, -705.875, 418.125}, {-1056.625, 415.125, -1055.125, 415.625}, {-1059.375, 415.375, -1057.875, 415.875}, {-1062.125, 415.625, -1060.625, 416.125}, {-1064.875, 415.875, -1063.375, 416.375},
		{-571.625, 415.875, -549.875, 416.375}, {-1067.875, 416.125, -1066.125, 416.625}, {-567.125, 416.125, -549.875, 416.625}, {-1070.625, 416.375, -1069.125, 416.875}, {-562.625, 416.375, -549.875, 416.875},
		{-1072.125, 416.625, -1070.875, 418.125}, {-558.125, 416.625, -549.875, 417.125}, {-1076.125, 416.875, -1073.875, 417.375}, {-553.625, 416.875, -549.875, 417.375}, {-1079.125, 417.125, -1073.875, 417.625},
		{-1081.875, 417.375, -1073.875, 417.875}, {-953.875, 417.375, -953.375, 419.875}, {-1082.125, 417.625, -1073.875, 418.125}, {-706.875, 417.875, -705.875, 420.875}, {-535.625, 417.875, -527.875, 418.375},
		{-531.125, 418.125, -527.875, 418.625}, {-953.625, 420.125, -953.125, 422.875}, {-706.625, 420.625, -705.875, 423.625}, {-953.375, 422.875, -952.875, 425.625}, {-706.375, 423.375, -705.875, 426.375},
		{-953.125, 425.875, -952.625, 428.375}, {-578.125, 425.875, -576.375, 428.375}, {-1081.125, 427.875, -1079.875, 429.375}, {-706.125, 427.875, -691.875, 429.125}, {-578.125, 428.125, -576.625, 432.875},
		{-952.875, 428.625, -952.375, 431.125}, {-705.125, 428.875, -691.875, 429.375}, {-1080.875, 429.125, -1079.875, 432.125}, {-699.125, 429.125, -691.875, 429.625}, {-1070.125, 429.375, -1069.625, 432.375},
		{-693.375, 429.375, -691.875, 429.875}, {-681.375, 429.875, -645.875, 430.375}, {-675.375, 430.125, -645.875, 430.625}, {-669.625, 430.375, -645.875, 430.875}, {-663.625, 430.625, -645.875, 431.125},
		{-927.125, 430.875, -926.375, 431.375}, {-657.625, 430.875, -645.875, 431.375}, {-929.875, 431.125, -926.375, 431.625}, {-651.875, 431.125, -645.875, 431.625}, {-952.625, 431.375, -952.125, 433.375},
		{-932.625, 431.375, -926.375, 431.875}, {-935.375, 431.625, -928.125, 432.125}, {-1080.625, 431.875, -1079.875, 435.125}, {-938.375, 431.875, -930.875, 432.375}, {-634.125, 431.875, -623.875, 432.375},
		{-1070.125, 432.125, -1069.375, 435.125}, {-941.125, 432.125, -933.625, 432.625}, {-628.125, 432.125, -623.875, 432.625}, {-943.875, 432.375, -936.375, 432.875}, {-946.625, 432.625, -939.125, 433.125},
		{-578.125, 432.625, -576.875, 437.375}, {-949.375, 432.875, -942.125, 433.375}, {-952.625, 433.125, -944.875, 433.625}, {-952.625, 433.375, -947.625, 433.875}, {-952.375, 433.625, -950.375, 434.125},
		{-1080.375, 434.875, -1079.875, 437.875}, {-1070.125, 434.875, -1069.125, 437.875}, {-578.125, 437.125, -577.125, 440.125}, {-1070.125, 437.625, -1068.875, 438.125}, {0.125, 437.625, 143.875, 438.625},
		{-1080.125, 437.875, -1068.875, 438.375}, {-1079.125, 438.125, -1068.875, 438.625}, {-624.375, 438.125, -623.875, 444.125}, {-1073.125, 438.375, -1068.875, 438.875}, {143.125, 438.375, 143.875, 447.125},
		{-592.125, 439.875, -577.125, 440.375}, {-592.125, 440.125, -579.625, 440.625}, {-592.125, 440.375, -582.375, 440.875}, {-592.125, 440.625, -585.375, 441.125}, {-592.125, 440.875, -588.125, 441.375},
		{-592.125, 441.125, -590.875, 441.625}, {-614.125, 441.875, -599.375, 442.375}, {-614.125, 442.125, -602.125, 442.625}, {-614.125, 442.375, -604.875, 442.875}, {-614.125, 442.625, -607.625, 443.125},
		{-614.125, 442.875, -610.375, 443.375}, {-614.125, 443.125, -613.125, 443.625}, {-624.375, 443.875, -621.625, 444.375}, {-1274.875, 448.875, -1273.875, 449.375}, {-1277.625, 449.125, -1273.875, 449.625},
		{-1280.375, 449.375, -1273.875, 449.875}, {-1283.125, 449.625, -1275.125, 450.125}, {-11.875, 449.625, 0.125, 450.625}, {-1285.875, 449.875, -1277.875, 450.375}, {-1266.375, 449.875, -1265.875, 450.625},
		{-1288.125, 450.125, -1280.875, 450.625}, {-1288.125, 450.375, -1283.625, 450.875}, {-1288.125, 450.625, -1286.375, 451.125}, {-1297.125, 450.875, -1295.875, 451.375}, {-1299.875, 451.125, -1295.875, 451.625},
		{-1302.875, 451.375, -1295.875, 451.875}, {-1305.625, 451.625, -1297.625, 452.125}, {-1308.375, 451.875, -1300.375, 452.375}, {-1310.125, 452.125, -1303.125, 452.625}, {-1310.125, 452.375, -1305.875, 452.875},
		{-1266.125, 452.375, -1265.625, 453.375}, {-1310.125, 452.625, -1308.625, 453.125}, {-1319.625, 452.875, -1317.875, 453.375}, {-1322.375, 453.125, -1317.875, 453.625}, {-1325.125, 453.375, -1317.875, 453.875},
		{-1328.125, 453.625, -1319.875, 454.125}, {-1330.875, 453.875, -1322.625, 454.375}, {-1333.625, 454.125, -1325.625, 454.625}, {-1334.125, 454.375, -1328.375, 454.875}, {-1334.125, 454.625, -1331.125, 455.125},
		{-1342.125, 454.875, -1339.875, 455.375}, {-1344.875, 455.125, -1339.875, 455.625}, {-1265.875, 455.125, -1265.375, 456.125}, {-1347.625, 455.375, -1339.875, 455.875}, {-1350.375, 455.625, -1342.375, 456.125},
		{-1353.125, 455.875, -1345.125, 456.375}, {-1356.125, 456.125, -1347.875, 456.625}, {-1356.125, 456.375, -1350.625, 456.875}, {-1356.125, 456.625, -1353.375, 457.125}, {-1364.375, 456.875, -1361.875, 457.375},
		{-1367.125, 457.125, -1361.875, 457.625}, {-1370.125, 457.375, -1361.875, 457.875}, {-1372.875, 457.625, -1364.625, 458.125}, {-1375.625, 457.875, -1367.375, 458.375}, {-1378.125, 458.125, -1370.125, 458.625},
		{-1378.125, 458.375, -1373.125, 458.875}, {-1378.125, 458.625, -1375.875, 459.125}, {-1386.875, 458.875, -1385.875, 459.375}, {-1389.625, 459.125, -1385.875, 459.625}, {-1392.375, 459.375, -1385.875, 459.875},
		{-1395.125, 459.625, -1387.125, 460.125}, {-1398.125, 459.875, -1389.875, 460.375}, {-1400.125, 460.125, -1392.625, 460.625}, {-1400.125, 460.375, -1395.375, 460.875}, {-1400.125, 460.625, -1398.125, 461.125},
		{-1409.125, 460.875, -1407.875, 461.375}, {-1409.375, 461.125, -1407.875, 461.875}, {-1409.375, 461.625, -1408.875, 462.125}, {-1409.125, 463.875, -1408.625, 465.375}, {-1408.875, 465.875, -1408.375, 468.125},
		{-1408.625, 468.625, -1408.125, 470.875}, {-1408.375, 471.375, -1407.875, 473.125}, {-1408.625, 472.875, -1407.875, 473.375}, {-1411.625, 473.125, -1407.875, 473.625}, {-1414.375, 473.375, -1407.875, 473.875},
		{-1417.125, 473.625, -1407.875, 474.125}, {-1419.875, 473.875, -1407.875, 474.375}, {-1422.625, 474.125, -1421.875, 474.625}, {-1420.125, 474.125, -1407.625, 475.125}, {-1424.125, 474.375, -1421.875, 476.125},
		{-1431.125, 474.875, -1429.875, 475.375}, {-1420.125, 474.875, -1409.375, 475.375}, {-1433.875, 475.125, -1429.875, 475.625}, {-1420.125, 475.125, -1412.125, 475.625}, {-1436.625, 475.375, -1429.875, 475.875},
		{-1420.125, 475.375, -1414.875, 475.875}, {-1439.625, 475.625, -1429.875, 476.125}, {-1420.125, 475.625, -1417.625, 476.125}, {-1442.375, 475.875, -1420.625, 476.375}, {-1445.125, 476.125, -1423.375, 476.625},
		{-1447.875, 476.375, -1426.125, 476.875}, {-1450.625, 476.625, -1428.875, 477.125}, {-1668.375, 476.875, -1431.625, 477.375}, {-1668.375, 477.125, -1434.625, 477.625}, {-1668.375, 477.375, -1437.375, 477.875},
		{-1668.375, 477.625, -1440.125, 478.125}, {-1668.375, 477.875, -1667.875, 560.125}, {-1472.125, 477.875, -1442.875, 478.375}, {-1472.125, 478.125, -1445.625, 478.625}, {-1472.125, 478.375, -1448.625, 478.875},
		{-1472.125, 478.625, -1451.375, 479.125}, {-1472.125, 478.875, -1454.125, 479.375}, {-1472.125, 479.125, -1456.875, 479.625}, {-1472.125, 479.375, -1459.625, 479.875}, {-1472.125, 479.625, -1462.625, 480.125},
		{-1624.125, 479.875, -1621.875, 481.625}, {-1474.125, 479.875, -1465.375, 480.375}, {-1474.125, 480.125, -1468.125, 480.625}, {-1474.125, 480.375, -1470.875, 480.875}, {-1474.125, 480.625, -1473.125, 481.625},
		{-1623.625, 481.375, -1621.875, 481.875}, {-1474.125, 481.375, -1472.875, 482.125}, {-1623.125, 481.625, -1621.875, 482.125}, {-1626.125, 481.875, -1624.625, 482.375}, {-1622.875, 481.875, -1619.875, 482.375},
		{-1626.125, 482.125, -1624.875, 482.875}, {-1622.375, 482.125, -1619.875, 482.625}, {-1621.875, 482.375, -1619.875, 482.875}, {-1626.125, 482.625, -1625.125, 483.375}, {-1621.375, 482.625, -1619.875, 483.125},
		{-1620.875, 482.875, -1619.875, 483.375}, {-1626.125, 483.125, -1625.375, 483.875}, {-1620.375, 483.125, -1619.875, 483.625}, {-1626.125, 483.625, -1625.625, 484.375}, {-1618.875, 483.875, -1615.875, 484.375},
		{-1474.125, 483.875, -1472.875, 484.375}, {-1618.625, 484.125, -1615.875, 484.625}, {-1474.125, 484.125, -1472.625, 486.125}, {-1618.125, 484.375, -1615.875, 484.875}, {-1617.625, 484.625, -1615.875, 485.125},
		{350.875, 484.625, 352.875, 485.125}, {-1617.125, 484.875, -1615.875, 485.375}, {350.875, 484.875, 354.625, 485.375}, {-1616.625, 485.125, -1615.875, 485.625}, {350.875, 485.125, 356.625, 485.625},
		{350.875, 485.375, 358.625, 485.875}, {350.875, 485.625, 359.625, 487.625}, {-1628.125, 485.875, -1626.875, 486.625}, {-1615.125, 485.875, -1611.875, 486.375}, {-1480.125, 485.875, -1472.625, 487.125},
		{-1614.875, 486.125, -1611.875, 486.625}, {-1628.125, 486.375, -1627.125, 487.125}, {-1614.375, 486.375, -1611.875, 486.875}, {-1613.875, 486.625, -1611.875, 487.125}, {-1628.125, 486.875, -1627.375, 487.625},
		{-1613.375, 486.875, -1611.875, 487.375}, {-1480.125, 486.875, -1472.375, 488.125}, {-1612.875, 487.125, -1611.875, 487.625}, {-1628.125, 487.375, -1627.625, 488.125}, {-1612.375, 487.375, -1611.875, 487.875},
		{350.875, 487.375, 359.375, 489.625}, {-1611.375, 487.875, -1607.875, 488.375}, {-1482.125, 487.875, -1472.375, 489.875}, {-1611.125, 488.125, -1607.875, 488.625}, {-1610.625, 488.375, -1607.875, 488.875},
		{-1610.125, 488.625, -1607.875, 489.125}, {-1609.625, 488.875, -1607.875, 489.375}, {-1609.125, 489.125, -1607.875, 489.625}, {-1608.625, 489.375, -1607.875, 489.875}, {350.875, 489.375, 359.125, 491.375},
		{-1482.125, 489.625, -1472.125, 490.125}, {-1630.125, 489.875, -1628.875, 490.375}, {-1607.625, 489.875, -1603.875, 490.375}, {-1484.125, 489.875, -1472.125, 492.125}, {-1630.125, 490.125, -1629.125, 490.875},
		{-1607.125, 490.125, -1603.875, 490.625}, {-1606.875, 490.375, -1603.875, 490.875}, {-1630.125, 490.625, -1629.375, 491.375}, {-1606.375, 490.625, -1603.875, 491.125}, {-1605.875, 490.875, -1603.875, 491.375},
		{-1630.125, 491.125, -1629.625, 491.875}, {-1605.375, 491.125, -1603.875, 491.625}, {350.875, 491.125, 358.875, 493.375}, {-1604.875, 491.375, -1603.875, 491.875}, {-1604.375, 491.625, -1603.875, 492.125},
		{-1603.875, 491.875, -1599.875, 492.375}, {-1490.125, 491.875, -1472.125, 492.625}, {-1603.375, 492.125, -1599.875, 492.625}, {-1603.125, 492.375, -1599.875, 492.875}, {-1490.125, 492.375, -1471.875, 495.625},
		{-1602.625, 492.625, -1599.875, 493.125}, {-1602.125, 492.875, -1599.875, 493.375}, {-1601.625, 493.125, -1599.875, 493.625}, {350.875, 493.125, 358.625, 495.375}, {-1601.125, 493.375, -1599.875, 493.875},
		{-1600.625, 493.625, -1599.875, 494.125}, {-1632.125, 493.875, -1631.125, 494.625}, {-1600.125, 493.875, -1595.875, 494.375}, {-1599.625, 494.125, -1595.875, 494.625}, {-1632.125, 494.375, -1631.375, 495.125},
		{-1599.375, 494.375, -1595.875, 494.875}, {-1598.875, 494.625, -1595.875, 495.125}, {-1632.125, 494.875, -1631.625, 495.625}, {-1598.375, 494.875, -1595.875, 495.375}, {-1597.875, 495.125, -1595.875, 495.625},
		{350.875, 495.125, 358.375, 497.125}, {-1597.375, 495.375, -1595.875, 495.875}, {-1490.125, 495.375, -1471.625, 496.125}, {-1596.875, 495.625, -1595.875, 496.125}, {-1634.125, 495.875, -1632.125, 496.625},
		{-1596.375, 495.875, -1591.875, 496.375}, {-1494.125, 495.875, -1475.875, 498.125}, {-1472.125, 495.875, -1471.625, 498.375}, {-1595.875, 496.125, -1591.875, 496.625}, {-1634.125, 496.375, -1632.375, 497.125},
		{-1595.375, 496.375, -1591.875, 496.875}, {-1595.125, 496.625, -1591.875, 497.125}, {-1634.125, 496.875, -1632.625, 497.375}, {-1594.625, 496.875, -1591.875, 497.375}, {350.875, 496.875, 358.125, 499.125},
		{-1634.125, 497.125, -1632.875, 497.875}, {-1594.125, 497.125, -1591.875, 497.625}, {-1593.625, 497.375, -1591.875, 497.875}, {-1634.125, 497.625, -1633.125, 498.375}, {-1593.125, 497.625, -1591.875, 498.125},
		{-1592.625, 497.875, -1589.875, 498.375}, {-1494.125, 497.875, -1489.875, 500.125}, {-1488.125, 497.875, -1485.875, 500.125}, {-1634.125, 498.125, -1633.375, 498.875}, {-1592.125, 498.125, -1589.875, 498.625},
		{-1472.125, 498.125, -1471.375, 501.125}, {-1591.625, 498.375, -1589.875, 498.875}, {-1634.125, 498.625, -1633.625, 499.375}, {-1591.375, 498.625, -1589.875, 499.125}, {-1590.875, 498.875, -1589.875, 499.375},
		{350.875, 498.875, 357.875, 500.875}, {-1590.375, 499.125, -1589.875, 499.625}, {-1636.125, 499.875, -1634.125, 500.375}, {-1588.875, 499.875, -1585.875, 500.375}, {-1636.125, 500.125, -1634.375, 500.875},
		{-1588.375, 500.125, -1585.875, 500.625}, {-1587.875, 500.375, -1585.875, 500.875}, {-1636.125, 500.625, -1634.625, 501.375}, {-1587.375, 500.625, -1585.875, 501.125}, {350.875, 500.625, 357.625, 502.875},
		{-1587.125, 500.875, -1585.875, 501.375}, {-1472.125, 500.875, -1471.125, 503.875}, {-1636.125, 501.125, -1634.875, 501.625}, {-1586.625, 501.125, -1585.875, 501.625}, {-1636.125, 501.375, -1635.125, 502.125},
		{-1636.125, 501.875, -1635.375, 502.625}, {-1585.125, 501.875, -1581.875, 502.375}, {-1584.625, 502.125, -1581.875, 502.625}, {-1636.125, 502.375, -1635.625, 503.125}, {-1584.125, 502.375, -1581.875, 502.875},
		{-1583.625, 502.625, -1581.875, 503.125}, {350.875, 502.625, 357.375, 504.875}, {-1583.375, 502.875, -1581.875, 503.375}, {-1582.875, 503.125, -1581.875, 503.625}, {-1582.375, 503.375, -1581.875, 503.875},
		{-1472.125, 503.625, -1470.875, 504.125}, {-1638.125, 503.875, -1636.375, 504.625}, {-1581.375, 503.875, -1577.875, 504.375}, {-1580.875, 504.125, -1577.875, 504.625}, {-1638.125, 504.375, -1636.625, 505.125},
		{-1580.375, 504.375, -1577.875, 504.875}, {-1579.875, 504.625, -1577.875, 505.125}, {350.875, 504.625, 357.125, 506.625}, {-1638.125, 504.875, -1636.875, 505.375}, {-1579.625, 504.875, -1577.875, 505.375},
		{-1638.125, 505.125, -1637.125, 505.875}, {-1579.125, 505.125, -1577.875, 505.625}, {-1578.625, 505.375, -1577.875, 505.875}, {-1638.125, 505.625, -1637.375, 506.375}, {-1577.625, 505.875, -1573.875, 506.375},
		{-1638.125, 506.125, -1637.625, 506.875}, {-1577.125, 506.125, -1573.875, 506.625}, {-1576.625, 506.375, -1573.875, 506.875}, {350.875, 506.375, 356.875, 508.625}, {-1576.125, 506.625, -1573.875, 507.125},
		{-1575.625, 506.875, -1573.875, 507.375}, {-1575.375, 507.125, -1573.875, 507.625}, {-1574.875, 507.375, -1573.875, 507.875}, {-1574.375, 507.625, -1573.875, 508.125}, {-1640.125, 507.875, -1638.375, 508.375},
		{-1573.875, 507.875, -1569.875, 508.375}, {-1640.125, 508.125, -1638.625, 508.875}, {-1573.375, 508.125, -1569.875, 508.625}, {-1572.875, 508.375, -1569.875, 508.875}, {350.875, 508.375, 356.625, 510.375},
		{-1640.125, 508.625, -1638.875, 509.125}, {-1572.375, 508.625, -1569.875, 509.125}, {-1640.125, 508.875, -1639.125, 509.625}, {-1571.875, 508.875, -1569.875, 509.375}, {-1571.625, 509.125, -1569.875, 509.625},
		{-1640.125, 509.375, -1639.375, 510.125}, {-1571.125, 509.375, -1569.875, 509.875}, {-1570.625, 509.625, -1569.875, 510.125}, {-1640.125, 509.875, -1639.625, 510.625}, {-1570.125, 509.875, -1565.875, 510.375},
		{-1569.625, 510.125, -1565.875, 510.625}, {350.875, 510.125, 356.375, 512.375}, {-1569.125, 510.375, -1565.875, 510.875}, {-1568.625, 510.625, -1565.875, 511.125}, {-1568.125, 510.875, -1565.875, 511.375},
		{-1567.625, 511.125, -1565.875, 511.625}, {-1567.375, 511.375, -1565.875, 511.875}, {-1566.875, 511.625, -1565.875, 512.125}, {-1642.125, 511.875, -1640.625, 512.625}, {-1566.375, 511.875, -1561.875, 512.375},
		{-1565.875, 512.125, -1561.875, 512.625}, {350.875, 512.125, 356.125, 514.375}, {-1642.125, 512.375, -1640.875, 513.125}, {-1565.375, 512.375, -1561.875, 512.875}, {-1564.875, 512.625, -1561.875, 513.125},
		{-1642.125, 512.875, -1641.125, 513.375}, {-1564.375, 512.875, -1561.875, 513.375}, {-1642.125, 513.125, -1641.375, 513.875}, {-1563.875, 513.125, -1561.875, 513.625}, {-1563.625, 513.375, -1561.875, 513.875},
		{-1642.125, 513.625, -1641.625, 514.375}, {-1563.125, 513.625, -1561.875, 514.125}, {-1562.625, 513.875, -1557.875, 514.375}, {-1562.125, 514.125, -1557.875, 514.625}, {350.875, 514.125, 355.875, 516.125},
		{-1561.625, 514.375, -1557.875, 514.875}, {-1561.125, 514.625, -1557.875, 515.125}, {-1560.625, 514.875, -1557.875, 515.375}, {-1560.125, 515.125, -1557.875, 515.625}, {-1559.875, 515.375, -1557.875, 515.875},
		{-1559.375, 515.625, -1557.875, 516.125}, {-1644.125, 515.875, -1642.625, 516.375}, {-1558.875, 515.875, -1555.875, 516.375}, {350.875, 515.875, 355.625, 518.125}, {-1644.125, 516.125, -1642.875, 516.875},
		{-1558.375, 516.125, -1555.875, 516.625}, {-1557.875, 516.375, -1555.875, 516.875}, {-1644.125, 516.625, -1643.125, 517.125}, {-1557.375, 516.625, -1555.875, 517.125}, {-1644.125, 516.875, -1643.375, 517.625},
		{-1556.875, 516.875, -1555.875, 517.375}, {-1556.375, 517.125, -1555.875, 517.625}, {-1644.125, 517.375, -1643.625, 518.125}, {-1470.125, 517.625, -1469.625, 520.875}, {-1555.125, 517.875, -1551.875, 518.375},
		{350.875, 517.875, 355.375, 519.875}, {-1554.625, 518.125, -1551.875, 518.625}, {-1554.125, 518.375, -1551.875, 518.875}, {-1553.625, 518.625, -1551.875, 519.125}, {-1553.125, 518.875, -1551.875, 519.375},
		{-1552.625, 519.125, -1551.875, 519.625}, {350.875, 519.625, 355.125, 521.875}, {-1646.125, 519.875, -1644.875, 520.625}, {-1551.375, 519.875, -1547.875, 520.375}, {-1550.875, 520.125, -1547.875, 520.625},
		{-1646.125, 520.375, -1645.125, 521.125}, {-1550.375, 520.375, -1547.875, 520.875}, {-1549.875, 520.625, -1547.875, 521.125}, {-1470.125, 520.625, -1469.375, 523.625}, {-1646.125, 520.875, -1645.375, 521.375},
		{-1549.375, 520.875, -1547.875, 521.375}, {-1646.125, 521.125, -1645.625, 521.875}, {-1548.875, 521.125, -1547.875, 521.625}, {-1548.375, 521.375, -1547.875, 521.875}, {350.875, 521.625, 354.875, 523.875},
		{-1547.625, 521.875, -1543.875, 522.375}, {-1547.125, 522.125, -1543.875, 522.625}, {-1546.625, 522.375, -1543.875, 522.875}, {-1546.125, 522.625, -1543.875, 523.125}, {-1545.625, 522.875, -1543.875, 523.375},
		{-1545.125, 523.125, -1543.875, 523.625}, {-1544.625, 523.375, -1543.875, 523.875}, {-1470.125, 523.375, -1469.125, 526.375}, {350.875, 523.625, 354.625, 525.625}, {-1648.125, 523.875, -1646.875, 524.375},
		{-1543.875, 523.875, -1539.875, 524.375}, {-1648.125, 524.125, -1647.125, 524.875}, {-1543.375, 524.125, -1539.875, 524.625}, {-1542.875, 524.375, -1539.875, 524.875}, {-1648.125, 524.625, -1647.375, 525.125},
		{-1542.375, 524.625, -1539.875, 525.125}, {-1648.125, 524.875, -1647.625, 525.625}, {-1541.875, 524.875, -1539.875, 525.375}, {-1541.375, 525.125, -1539.875, 525.625}, {-1540.875, 525.375, -1539.875, 525.875},
		{350.875, 525.375, 354.375, 527.625}, {-1540.375, 525.625, -1539.875, 526.125}, {-1540.125, 525.875, -1535.875, 526.375}, {-1539.625, 526.125, -1535.875, 526.625}, {-1470.125, 526.125, -1468.875, 528.125},
		{-1539.125, 526.375, -1535.875, 526.875}, {-1538.625, 526.625, -1535.875, 527.125}, {-1538.125, 526.875, -1535.875, 527.375}, {-1537.625, 527.125, -1535.875, 527.625}, {-1537.125, 527.375, -1535.875, 527.875},
		{350.875, 527.375, 354.125, 529.375}, {-1536.625, 527.625, -1535.875, 528.125}, {-1650.125, 527.875, -1649.125, 528.625}, {-1536.125, 527.875, -1531.875, 528.375}, {-1535.875, 528.125, -1531.875, 528.625},
		{-1650.125, 528.375, -1649.375, 528.875}, {-1535.375, 528.375, -1531.875, 528.875}, {-1650.125, 528.625, -1649.625, 529.375}, {-1534.875, 528.625, -1531.875, 529.125}, {-1534.375, 528.875, -1531.875, 529.375},
		{-1533.875, 529.125, -1531.875, 529.625}, {350.875, 529.125, 353.875, 531.375}, {-1533.375, 529.375, -1531.875, 529.875}, {-1532.875, 529.625, -1531.875, 530.125}, {-1652.125, 529.875, -1650.125, 530.375},
		{-1532.375, 529.875, -1527.875, 530.375}, {-1652.125, 530.125, -1650.375, 530.875}, {-1532.125, 530.125, -1527.875, 530.625}, {-1531.625, 530.375, -1527.875, 530.875}, {-1652.125, 530.625, -1650.625, 531.375},
		{-1531.125, 530.625, -1527.875, 531.125}, {-1530.625, 530.875, -1527.875, 531.375}, {-1652.125, 531.125, -1650.875, 531.875}, {-1530.125, 531.125, -1527.875, 531.625}, {350.875, 531.125, 353.625, 533.125},
		{-1529.625, 531.375, -1527.875, 531.875}, {-1652.125, 531.625, -1651.125, 532.375}, {-1529.125, 531.625, -1527.875, 532.125}, {-1528.625, 531.875, -1525.875, 532.375}, {-1652.125, 532.125, -1651.375, 532.875},
		{-1528.375, 532.125, -1525.875, 532.625}, {-1527.875, 532.375, -1525.875, 532.875}, {-1652.125, 532.625, -1651.625, 533.125}, {-1527.375, 532.625, -1525.875, 533.125}, {-1526.875, 532.875, -1525.875, 533.375},
		{350.875, 532.875, 353.375, 535.125}, {-1526.375, 533.125, -1525.875, 533.625}, {-1654.125, 533.875, -1652.375, 534.625}, {-1524.875, 533.875, -1521.875, 534.375}, {-1524.375, 534.125, -1521.875, 534.625},
		{-1654.125, 534.375, -1652.625, 535.125}, {-1524.125, 534.375, -1521.875, 534.875}, {-1523.625, 534.625, -1521.875, 535.125}, {-1654.125, 534.875, -1652.875, 535.625}, {-1523.125, 534.875, -1521.875, 535.375},
		{350.875, 534.875, 353.125, 537.125}, {-1522.625, 535.125, -1521.875, 535.625}, {-1654.125, 535.375, -1653.125, 536.125}, {-1654.125, 535.875, -1653.375, 536.625}, {-1521.125, 535.875, -1517.875, 536.375},
		{-1520.625, 536.125, -1517.875, 536.625}, {-1654.125, 536.375, -1653.625, 536.875}, {-1520.375, 536.375, -1517.875, 536.875}, {-1519.875, 536.625, -1517.875, 537.125}, {-1519.375, 536.875, -1517.875, 537.375},
		{350.875, 536.875, 352.875, 538.875}, {-1518.875, 537.125, -1517.875, 537.625}, {-1518.375, 537.375, -1517.875, 537.875}, {-1656.125, 537.875, -1654.375, 538.375}, {-1517.375, 537.875, -1513.875, 538.375},
		{-1505.125, 537.875, -1493.875, 538.375}, {-1656.125, 538.125, -1654.625, 538.875}, {-1516.875, 538.125, -1513.875, 538.625}, {-1502.375, 538.125, -1493.875, 538.625}, {-1516.375, 538.375, -1513.875, 538.875},
		{-1499.375, 538.375, -1493.875, 538.875}, {-1656.125, 538.625, -1654.875, 539.375}, {-1516.125, 538.625, -1513.875, 539.125}, {-1496.625, 538.625, -1493.875, 539.125}, {350.875, 538.625, 352.625, 540.125},
		{-1515.625, 538.875, -1513.875, 539.375}, {-1656.125, 539.125, -1655.125, 539.875}, {-1515.125, 539.125, -1513.875, 539.625}, {-1514.625, 539.375, -1513.875, 539.875}, {-1656.125, 539.625, -1655.375, 540.375},
		{-1513.625, 539.875, -1509.875, 540.375}, {-1482.375, 539.875, -1469.875, 540.375}, {350.875, 539.875, 352.125, 552.125}, {-1656.125, 540.125, -1655.625, 540.875}, {-1513.125, 540.125, -1509.875, 540.625},
		{-1479.375, 540.125, -1469.875, 540.625}, {-1468.125, 540.125, -1467.625, 542.125}, {-1512.625, 540.375, -1509.875, 540.875}, {-1476.625, 540.375, -1469.875, 540.875}, {403.875, 540.375, 405.125, 692.125},
		{-1512.375, 540.625, -1509.875, 541.125}, {-1473.625, 540.625, -1469.875, 541.125}, {-1511.875, 540.875, -1509.875, 541.375}, {-1470.875, 540.875, -1469.875, 541.375}, {-1511.375, 541.125, -1509.875, 541.625},
		{-1510.875, 541.375, -1509.875, 541.875}, {-1510.375, 541.625, -1509.875, 542.125}, {-1658.125, 541.875, -1656.625, 542.625}, {-1509.875, 541.875, -1508.375, 542.375}, {-1468.375, 541.875, -1467.625, 542.875},
		{-1509.375, 542.125, -1508.375, 542.625}, {-1658.125, 542.375, -1656.875, 543.125}, {-1508.875, 542.375, -1508.375, 542.875}, {-1468.625, 542.625, -1467.625, 543.125}, {-1658.125, 542.875, -1657.125, 543.625},
		{-1468.625, 542.875, -1467.375, 545.625}, {-1658.125, 543.375, -1657.375, 544.125}, {-1658.125, 543.875, -1657.625, 544.625}, {-1468.875, 545.375, -1467.375, 545.875}, {-1468.875, 545.625, -1467.125, 546.625},
		{-1660.125, 545.875, -1658.625, 546.375}, {-1660.125, 546.125, -1658.875, 546.875}, {-1660.125, 546.625, -1659.125, 547.375}, {-1660.125, 547.125, -1659.375, 547.875}, {-1660.125, 547.625, -1659.625, 548.375},
		{-1662.125, 549.875, -1660.875, 550.625}, {-1662.125, 550.375, -1661.125, 551.125}, {-1662.125, 550.875, -1661.375, 551.625}, {-1662.125, 551.375, -1661.625, 552.125}, {-1664.125, 553.875, -1662.875, 554.375},
		{-1664.125, 554.125, -1663.125, 554.875}, {-1664.125, 554.625, -1663.375, 555.375}, {-1664.125, 555.125, -1663.625, 555.875}, {-1666.125, 557.875, -1665.125, 558.625}, {-1666.125, 558.375, -1665.375, 559.125},
		{-1666.125, 558.875, -1665.625, 559.625}, {-1668.375, 559.875, -1666.125, 560.375}, {-1691.375, 560.125, -1666.375, 560.625}, {-1691.375, 560.375, -1690.875, 628.125}, {350.875, 641.875, 352.125, 656.125},
		{350.875, 655.875, 356.125, 658.125}, {350.875, 657.875, 358.125, 660.125}, {350.875, 659.875, 362.125, 664.125}, {350.875, 663.875, 364.125, 670.125}, {350.875, 669.875, 366.125, 676.125},
		{350.875, 675.875, 368.125, 686.125}, {350.875, 685.875, 366.125, 690.125}, {350.875, 689.875, 364.125, 694.125}, {381.875, 691.875, 405.125, 692.375}, {381.875, 692.125, 382.375, 693.625},
		{381.875, 693.375, 382.625, 696.375}, {350.875, 693.875, 358.125, 700.125}, {359.875, 693.875, 362.125, 696.125}, {381.875, 696.125, 382.875, 699.375}, {381.875, 699.125, 383.125, 700.125},
		{350.875, 699.875, 360.125, 716.125}, {383.875, 713.125, 384.375, 716.125}, {350.875, 715.875, 362.125, 730.125}, {383.875, 715.875, 384.625, 718.875}, {383.875, 718.625, 384.875, 721.625},
		{383.875, 721.375, 385.125, 722.125}, {350.875, 729.875, 364.125, 734.375}, {350.875, 734.625, 364.125, 736.125}, {385.875, 735.375, 386.375, 736.125}, {350.875, 735.875, 386.375, 736.375},
		{446.875, 807.875, 497.125, 808.375}, {1129.625, 1227.625, 1263.375, 1242.125}, {973.125, 1230.875, 1009.375, 1232.125}, {973.125, 1231.875, 974.125, 1242.125}, {-3034.375, 1649.625, -3010.875, 1650.125},
		{-3034.375, 1649.875, -3033.875, 1708.625}, {-3012.125, 1649.875, -3010.875, 1719.875}, {-3034.625, 1708.375, -3033.875, 1709.125}, {-3034.875, 1708.875, -3033.875, 1709.625}, {-3035.125, 1709.375, -3033.875, 1709.875},
		{-3035.375, 1709.625, -3033.875, 1710.125}, {-3036.375, 1711.625, -3035.875, 1712.375}, {-3036.625, 1712.125, -3035.875, 1712.625}, {-3036.875, 1712.375, -3035.875, 1713.125}, {-3037.125, 1712.875, -3035.875, 1713.625},
		{-3037.375, 1713.375, -3035.875, 1714.125}, {-3038.375, 1715.125, -3037.875, 1715.875}, {-3038.625, 1715.625, -3037.875, 1716.125}, {-3040.375, 1718.875, -3039.875, 1719.625}, {-3040.625, 1719.375, -3039.875, 1720.125},
		{-3012.125, 1719.625, -2987.875, 1720.125}, {-3042.375, 1722.625, -3041.875, 1723.375}, {-3042.625, 1723.125, -3041.875, 1723.625}, {-3042.875, 1723.375, -3041.875, 1724.125}, {-3044.375, 1726.125, -3043.875, 1726.875},
		{-3044.625, 1726.625, -3043.875, 1727.375}, {-3044.875, 1727.125, -3043.875, 1727.875}, {-3045.125, 1727.625, -3043.875, 1728.125}, {-3046.375, 1729.875, -3045.875, 1730.625}, {-3046.625, 1730.375, -3045.875, 1731.125},
		{-3046.875, 1730.875, -3045.875, 1731.625}, {-3047.125, 1731.375, -3045.875, 1731.875}, {-3047.375, 1731.625, -3045.875, 1732.125}, {-3048.375, 1733.625, -3047.875, 1734.375}, {-3048.625, 1734.125, -3047.875, 1734.625},
		{-3048.875, 1734.375, -3047.875, 1735.125}, {-3049.125, 1734.875, -3047.875, 1735.625}, {-3049.375, 1735.375, -3047.875, 1736.125}, {-3050.375, 1737.125, -3049.875, 1737.875}, {-3050.625, 1737.625, -3049.875, 1738.125},
		{-3052.375, 1740.875, -3051.875, 1741.625}, {-3052.625, 1741.375, -3051.875, 1742.125}, {-3054.375, 1744.625, -3053.875, 1745.125}, {-3054.625, 1744.875, -3053.875, 1745.625}, {-3054.875, 1745.375, -3053.875, 1746.125},
		{981.875, 1746.125, 982.625, 1748.125}, {981.875, 1747.875, 982.375, 1750.375}, {-3056.375, 1748.125, -3055.875, 1748.875}, {-3056.625, 1748.625, -3055.875, 1749.375}, {-3056.875, 1749.125, -3055.875, 1749.875},
		{-3057.125, 1749.625, -3055.875, 1750.125}, {-3058.375, 1751.875, -3057.875, 1752.625}, {-3058.625, 1752.375, -3057.875, 1753.125}, {-3058.875, 1752.875, -3057.875, 1753.375}, {-3059.125, 1753.125, -3057.875, 1753.875},
		{-3059.375, 1753.625, -3057.875, 1754.125}, {979.875, 1753.875, 981.875, 1755.125}, {979.875, 1754.875, 981.625, 1756.125}, {-3060.375, 1755.625, -3059.875, 1756.125}, {-3060.625, 1755.875, -3059.875, 1756.625},
		{975.875, 1755.875, 981.625, 1757.625}, {-3060.875, 1756.375, -3059.875, 1757.125}, {-3061.125, 1756.875, -3059.875, 1757.625}, {-3061.375, 1757.375, -3059.875, 1758.125}, {975.875, 1757.375, 981.375, 1758.125},
		{974.375, 1757.875, 981.375, 1759.875}, {-3062.375, 1759.125, -3061.875, 1759.875}, {-3062.625, 1759.625, -3061.875, 1760.125}, {974.375, 1759.625, 981.125, 1762.375}, {-2988.125, 1761.375, -2846.125, 1762.125},
		{-3063.375, 1761.875, -3061.875, 1762.375}, {-3062.875, 1762.125, -3061.875, 1762.625}, {974.375, 1762.125, 980.875, 1764.625}, {-3062.375, 1762.375, -3061.875, 1762.875}, {-3059.375, 1763.875, -3057.875, 1764.375},
		{-3059.125, 1764.125, -3057.875, 1764.625}, {-3058.625, 1764.375, -3057.875, 1764.875}, {974.375, 1764.375, 980.625, 1767.125}, {-3055.625, 1765.875, -3053.875, 1766.375}, {-3055.125, 1766.125, -3053.875, 1766.625},
		{-3054.625, 1766.375, -3053.875, 1766.875}, {974.375, 1766.875, 980.375, 1769.375}, {-2846.125, 1767.625, -2845.625, 1772.375}, {-3051.625, 1767.875, -3049.875, 1768.375}, {-3051.125, 1768.125, -3049.875, 1768.625},
		{-3050.625, 1768.375, -3049.875, 1768.875}, {974.375, 1769.125, 980.125, 1770.125}, {-3047.625, 1769.875, -3045.875, 1770.375}, {974.375, 1769.875, 976.125, 1771.375}, {-3047.125, 1770.125, -3045.875, 1770.625},
		{-3046.625, 1770.375, -3045.875, 1770.875}, {974.125, 1771.125, 976.125, 1772.125}, {-3043.625, 1771.875, -3041.875, 1772.375}, {-3043.125, 1772.125, -3041.875, 1772.625}, {-2846.125, 1772.125, -2845.375, 1777.125},
		{-3042.625, 1772.375, -3041.875, 1772.875}, {-3039.625, 1773.875, -3037.875, 1774.375}, {-3039.125, 1774.125, -3037.875, 1774.625}, {-3038.625, 1774.375, -3037.875, 1774.875}, {-3035.625, 1775.875, -3033.875, 1776.375},
		{-3035.125, 1776.125, -3033.875, 1776.625}, {-3034.625, 1776.375, -3033.875, 1776.875}, {-2846.125, 1776.875, -2845.125, 1781.625}, {-3031.625, 1777.875, -3029.875, 1778.375}, {974.125, 1777.875, 976.125, 1780.125},
		{-3031.125, 1778.125, -3029.875, 1778.625}, {-3030.625, 1778.375, -3029.875, 1778.875}, {-3027.625, 1779.875, -3025.875, 1780.375}, {974.125, 1779.875, 979.125, 1781.375}, {-3027.125, 1780.125, -3025.875, 1780.625},
		{-3026.625, 1780.375, -3025.875, 1780.875}, {974.125, 1781.125, 978.875, 1783.625}, {-2846.125, 1781.375, -2844.875, 1784.125}, {-3023.875, 1781.875, -3021.875, 1782.375}, {-3023.375, 1782.125, -3021.875, 1782.625},
		{-3022.875, 1782.375, -3021.875, 1782.875}, {-3022.375, 1782.625, -3021.875, 1783.125}, {974.125, 1783.375, 978.625, 1785.625}, {-3019.875, 1783.875, -3017.875, 1784.375}, {-3019.375, 1784.125, -3017.875, 1784.625},
		{-3018.875, 1784.375, -3017.875, 1784.875}, {-3018.375, 1784.625, -3017.875, 1785.125}, {973.875, 1785.375, 978.625, 1786.125}, {-3015.875, 1785.875, -3013.875, 1786.375}, {973.875, 1785.875, 978.375, 1788.375},
		{-3015.375, 1786.125, -3013.875, 1786.625}, {-3014.875, 1786.375, -3013.875, 1786.875}, {-3014.375, 1786.625, -3013.875, 1787.125}, {-3011.875, 1787.875, -3009.875, 1788.375}, {-3011.375, 1788.125, -3009.875, 1788.625},
		{973.875, 1788.125, 978.125, 1790.875}, {-3010.875, 1788.375, -3009.875, 1788.875}, {-3010.375, 1788.625, -3009.875, 1789.125}, {-3007.875, 1789.875, -3005.875, 1790.375}, {-3007.375, 1790.125, -3005.875, 1790.625},
		{-3006.875, 1790.375, -3005.875, 1790.875}, {-3006.375, 1790.625, -3005.875, 1791.125}, {973.875, 1790.625, 977.875, 1793.125}, {-3003.875, 1791.875, -3001.875, 1792.375}, {-3003.375, 1792.125, -3001.875, 1792.625},
		{-3002.875, 1792.375, -3001.875, 1792.875}, {-3002.375, 1792.625, -3001.875, 1793.125}, {973.875, 1792.875, 977.625, 1794.125}, {-2999.875, 1793.875, -2997.875, 1794.375}, {-2999.375, 1794.125, -2997.875, 1794.625},
		{-2998.875, 1794.375, -2997.875, 1794.875}, {-2998.375, 1794.625, -2997.875, 1795.125}, {-2995.875, 1795.875, -2993.875, 1796.375}, {-2995.375, 1796.125, -2993.875, 1796.625}, {-2994.875, 1796.375, -2993.875, 1796.875},
		{-2994.375, 1796.625, -2993.875, 1797.125}, {-2991.875, 1797.875, -2989.875, 1798.375}, {-2991.375, 1798.125, -2989.875, 1798.625}, {-2990.875, 1798.375, -2989.875, 1798.875}, {-2990.375, 1798.625, -2989.875, 1799.125},
		{973.625, 1799.625, 974.125, 1814.375}, {-2988.125, 1799.875, -2985.875, 1800.375}, {975.875, 1799.875, 977.125, 1800.375}, {-2987.625, 1800.125, -2985.875, 1800.625}, {975.875, 1800.125, 976.875, 1802.875},
		{-2987.125, 1800.375, -2985.875, 1800.875}, {-2986.625, 1800.625, -2985.875, 1801.125}, {-2984.125, 1801.875, -2981.875, 1802.375}, {-2983.625, 1802.125, -2981.875, 1802.625}, {-2983.125, 1802.375, -2981.875, 1802.875},
		{-2982.625, 1802.625, -2981.875, 1803.125}, {975.875, 1802.625, 976.625, 1805.125}, {-2980.125, 1803.875, -2977.875, 1804.375}, {-2979.625, 1804.125, -2977.875, 1804.625}, {-2979.125, 1804.375, -2977.875, 1804.875},
		{-2978.625, 1804.625, -2977.875, 1805.125}, {-2844.125, 1804.625, -2843.625, 1809.375}, {975.875, 1804.875, 976.375, 1807.625}, {-2976.125, 1805.875, -2973.875, 1806.375}, {-2975.625, 1806.125, -2973.875, 1806.625},
		{-2975.125, 1806.375, -2973.875, 1806.875}, {-2974.625, 1806.625, -2973.875, 1807.125}, {-2972.125, 1807.875, -2969.875, 1808.375}, {-2971.625, 1808.125, -2969.875, 1808.625}, {-2971.125, 1808.375, -2969.875, 1808.875},
		{-2970.625, 1808.625, -2969.875, 1809.125}, {-2844.125, 1809.125, -2843.375, 1813.875}, {-2968.125, 1809.875, -2965.875, 1810.375}, {-2967.625, 1810.125, -2965.875, 1810.625}, {-2967.125, 1810.375, -2965.875, 1810.875},
		{-2966.625, 1810.625, -2965.875, 1811.125}, {-2964.125, 1811.875, -2961.875, 1812.375}, {-2963.625, 1812.125, -2961.875, 1812.625}, {-2963.125, 1812.375, -2961.875, 1812.875}, {-2962.625, 1812.625, -2961.875, 1813.125},
		{-2844.125, 1813.625, -2843.125, 1818.625}, {-2960.125, 1813.875, -2957.875, 1814.375}, {-2959.625, 1814.125, -2957.875, 1814.625}, {973.375, 1814.125, 974.125, 1818.125}, {-2959.125, 1814.375, -2957.875, 1814.875},
		{-2958.625, 1814.625, -2957.875, 1815.125}, {-2956.125, 1815.875, -2953.875, 1816.375}, {-2955.625, 1816.125, -2953.875, 1816.625}, {-2955.125, 1816.375, -2953.875, 1816.875}, {-2954.875, 1816.625, -2953.875, 1817.125},
		{-2954.375, 1816.875, -2953.875, 1817.375}, {-2952.375, 1817.875, -2949.875, 1818.375}, {973.375, 1817.875, 975.125, 1819.375}, {-2951.875, 1818.125, -2949.875, 1818.625}, {-2951.375, 1818.375, -2949.875, 1818.875},
		{-2844.125, 1818.375, -2842.875, 1820.125}, {-2950.875, 1818.625, -2949.875, 1819.125}, {-2950.375, 1818.875, -2949.875, 1819.375}, {973.375, 1819.125, 974.875, 1821.875}, {-2948.375, 1819.875, -2945.875, 1820.375},
		{-2947.875, 1820.125, -2945.875, 1820.625}, {-2947.375, 1820.375, -2945.875, 1820.875}, {-2946.875, 1820.625, -2945.875, 1821.125}, {-2946.375, 1820.875, -2945.875, 1821.375}, {973.375, 1821.625, 974.625, 1822.125},
		{-2944.375, 1821.875, -2941.875, 1822.375}, {973.875, 1821.875, 974.625, 1824.125}, {-2943.875, 1822.125, -2941.875, 1822.625}, {-2943.375, 1822.375, -2941.875, 1822.875}, {-2942.875, 1822.625, -2941.875, 1823.125},
		{957.875, 1822.625, 960.125, 1823.125}, {-2942.375, 1822.875, -2941.875, 1823.375}, {-2940.375, 1823.875, -2937.875, 1824.375}, {969.875, 1823.875, 974.375, 1824.375}, {-2939.875, 1824.125, -2937.875, 1824.625},
		{972.375, 1824.125, 974.375, 1824.625}, {-2939.375, 1824.375, -2937.875, 1824.875}, {-2938.875, 1824.625, -2937.875, 1825.125}, {-2938.375, 1824.875, -2937.875, 1825.375}, {-2936.375, 1825.875, -2933.875, 1826.375},
		{-2935.875, 1826.125, -2933.875, 1826.625}, {-2935.375, 1826.375, -2933.875, 1826.875}, {-2934.875, 1826.625, -2933.875, 1827.125}, {-2934.375, 1826.875, -2933.875, 1827.375}, {-2932.375, 1827.875, -2929.875, 1828.375},
		{-2931.875, 1828.125, -2929.875, 1828.625}, {-2931.375, 1828.375, -2929.875, 1828.875}, {-2930.875, 1828.625, -2929.875, 1829.125}, {-2930.375, 1828.875, -2929.875, 1829.375}, {-2928.375, 1829.875, -2925.875, 1830.375},
		{-2927.875, 1830.125, -2925.875, 1830.625}, {-2927.375, 1830.375, -2925.875, 1830.875}, {-2926.875, 1830.625, -2925.875, 1831.125}, {-2926.375, 1830.875, -2925.875, 1831.375}, {-2924.375, 1831.875, -2921.875, 1832.375},
		{-2923.875, 1832.125, -2921.875, 1832.625}, {-2923.375, 1832.375, -2921.875, 1832.875}, {-2922.875, 1832.625, -2921.875, 1833.125}, {-2922.375, 1832.875, -2921.875, 1833.375}, {-2920.375, 1833.875, -2917.875, 1834.375},
		{-2920.125, 1834.125, -2917.875, 1834.625}, {-2919.625, 1834.375, -2917.875, 1834.875}, {-2919.125, 1834.625, -2917.875, 1835.125}, {-2918.625, 1834.875, -2917.875, 1835.375}, {-2916.625, 1835.875, -2913.875, 1836.375},
		{-2916.125, 1836.125, -2913.875, 1836.625}, {-2915.625, 1836.375, -2913.875, 1836.875}, {-2915.125, 1836.625, -2913.875, 1837.125}, {-2914.625, 1836.875, -2913.875, 1837.375}, {-2912.625, 1837.875, -2909.875, 1838.375},
		{-2912.125, 1838.125, -2909.875, 1838.625}, {-2911.625, 1838.375, -2909.875, 1838.875}, {-2911.125, 1838.625, -2909.875, 1839.125}, {-2910.625, 1838.875, -2909.875, 1839.375}, {-2908.625, 1839.875, -2905.875, 1840.375},
		{-2908.125, 1840.125, -2905.875, 1840.625}, {-2907.625, 1840.375, -2905.875, 1840.875}, {-2907.125, 1840.625, -2905.875, 1841.125}, {-2906.625, 1840.875, -2905.875, 1841.375}, {-2842.125, 1841.375, -2841.625, 1846.375},
		{-2904.625, 1841.875, -2901.875, 1842.375}, {-2904.125, 1842.125, -2901.875, 1842.625}, {-2903.625, 1842.375, -2901.875, 1842.875}, {-2903.125, 1842.625, -2901.875, 1843.125}, {-2902.625, 1842.875, -2901.875, 1843.375},
		{-2900.625, 1843.875, -2897.875, 1844.375}, {-2900.125, 1844.125, -2897.875, 1844.625}, {-2899.625, 1844.375, -2897.875, 1844.875}, {-2899.125, 1844.625, -2897.875, 1845.125}, {-2898.625, 1844.875, -2897.875, 1845.375},
		{-2896.625, 1845.875, -2893.875, 1846.375}, {-2896.125, 1846.125, -2893.875, 1846.625}, {-2842.125, 1846.125, -2841.375, 1850.875}, {-2895.625, 1846.375, -2893.875, 1846.875}, {-2895.125, 1846.625, -2893.875, 1847.125},
		{-2894.625, 1846.875, -2893.875, 1847.375}, {-2892.625, 1847.875, -2889.875, 1848.375}, {-2892.125, 1848.125, -2889.875, 1848.625}, {-2891.625, 1848.375, -2889.875, 1848.875}, {-2891.125, 1848.625, -2889.875, 1849.125},
		{-2890.625, 1848.875, -2889.875, 1849.375}, {-2888.625, 1849.875, -2885.875, 1850.375}, {-2888.125, 1850.125, -2885.875, 1850.625}, {-2887.625, 1850.375, -2885.875, 1850.875}, {-2887.125, 1850.625, -2885.875, 1851.125},
		{-2842.125, 1850.625, -2841.125, 1855.625}, {-2886.625, 1850.875, -2885.875, 1851.375}, {-2884.875, 1851.875, -2881.875, 1852.375}, {-2884.375, 1852.125, -2881.875, 1852.625}, {-2883.875, 1852.375, -2881.875, 1852.875},
		{-2883.375, 1852.625, -2881.875, 1853.125}, {-2882.875, 1852.875, -2881.875, 1853.375}, {-2882.375, 1853.125, -2881.875, 1853.625}, {-2880.875, 1853.875, -2877.875, 1854.375}, {-2880.375, 1854.125, -2877.875, 1854.625},
		{-2879.875, 1854.375, -2877.875, 1854.875}, {-2879.375, 1854.625, -2877.875, 1855.125}, {-2878.875, 1854.875, -2877.875, 1855.375}, {-2878.375, 1855.125, -2877.875, 1855.625}, {-2842.125, 1855.375, -2840.875, 1858.125},
		{-2876.875, 1855.875, -2873.875, 1856.375}, {-2876.375, 1856.125, -2873.875, 1856.625}, {-2875.875, 1856.375, -2873.875, 1856.875}, {-2875.375, 1856.625, -2873.875, 1857.125}, {-2874.875, 1856.875, -2873.875, 1857.375},
		{-2874.375, 1857.125, -2873.875, 1857.625}, {-2872.875, 1857.875, -2869.875, 1858.375}, {-2872.375, 1858.125, -2869.875, 1858.625}, {-2871.875, 1858.375, -2869.875, 1858.875}, {-2871.375, 1858.625, -2869.875, 1859.125},
		{-2870.875, 1858.875, -2869.875, 1859.375}, {-2870.375, 1859.125, -2869.875, 1859.625}, {-2868.875, 1859.875, -2867.875, 1860.375}, {-2868.375, 1860.125, -2867.875, 1860.625}, {-2864.875, 1861.875, -2863.875, 1862.375},
		{-2864.375, 1862.125, -2863.875, 1862.625}, {-2860.875, 1863.875, -2859.875, 1864.375}, {-2860.375, 1864.125, -2859.875, 1864.625}, {-2856.875, 1865.875, -2855.875, 1866.375}, {-2856.375, 1866.125, -2855.875, 1866.625},
		{-2852.875, 1867.875, -2851.875, 1868.375}, {-2852.375, 1868.125, -2851.875, 1868.625}, {-2849.125, 1869.875, -2847.875, 1870.375}, {-2848.625, 1870.125, -2847.875, 1870.625}, {-2845.125, 1871.875, -2843.875, 1872.375},
		{-2844.625, 1872.125, -2843.875, 1872.625}, {-2841.125, 1873.875, -2839.875, 1874.375}, {-2840.625, 1874.125, -2839.875, 1874.625}, {883.875, 1876.375, 884.375, 1880.125}, {883.875, 1879.875, 884.625, 1880.375},
		{884.125, 1880.125, 884.625, 1884.875}, {600.625, 2295.125, 612.625, 2295.625}, {562.875, 2312.625, 571.375, 2313.125}, {502.375, 2312.875, 528.375, 2313.375}, {-1590.125, 2356.125, -1588.625, 2357.375},
		{-1596.625, 2356.625, -1593.875, 2357.125}, {-1599.375, 2356.875, -1593.875, 2357.375}, {-1602.125, 2357.125, -1593.875, 2357.625}, {-1590.125, 2357.125, -1588.875, 2359.125}, {-1604.875, 2357.375, -1593.875, 2357.875},
		{-1607.875, 2357.625, -1593.875, 2358.125}, {-1618.875, 2358.625, -1617.875, 2359.125}, {-1621.625, 2358.875, -1617.875, 2359.375}, {-1590.125, 2358.875, -1589.125, 2361.125}, {-1624.625, 2359.125, -1617.875, 2359.625},
		{-1627.375, 2359.375, -1617.875, 2359.875}, {-1630.125, 2359.625, -1617.875, 2360.125}, {-1641.375, 2360.625, -1639.875, 2361.125}, {-1644.125, 2360.875, -1639.875, 2361.375}, {-1590.125, 2360.875, -1589.375, 2363.125},
		{-1646.875, 2361.125, -1639.875, 2361.625}, {-1649.625, 2361.375, -1639.875, 2361.875}, {-1652.375, 2361.625, -1639.875, 2362.125}, {-1663.625, 2362.625, -1661.875, 2363.125}, {-1666.375, 2362.875, -1661.875, 2363.375},
		{-1590.125, 2362.875, -1589.625, 2364.875}, {-1669.125, 2363.125, -1661.875, 2363.625}, {-1672.125, 2363.375, -1661.875, 2363.875}, {-1674.875, 2363.625, -1661.875, 2364.125}, {-1686.125, 2364.625, -1683.875, 2365.125},
		{-1688.875, 2364.875, -1683.875, 2365.375}, {-1691.625, 2365.125, -1683.875, 2365.625}, {-1694.375, 2365.375, -1683.875, 2365.875}, {-1697.125, 2365.625, -1683.875, 2366.125}, {-1174.625, 2366.375, -1162.375, 2462.375},
		{-1006.375, 2366.375, -998.125, 2378.375}, {-1708.375, 2366.625, -1705.875, 2367.125}, {-1711.125, 2366.875, -1705.875, 2367.375}, {-1713.875, 2367.125, -1705.875, 2367.625}, {-1716.875, 2367.375, -1705.875, 2367.875},
		{-1719.625, 2367.625, -1705.875, 2368.125}, {-1722.375, 2367.875, -1720.875, 2368.375}, {-1725.125, 2368.125, -1723.625, 2368.625}, {-1727.875, 2368.375, -1726.375, 2368.875}, {-1730.625, 2368.625, -1729.375, 2369.125},
		{-1733.625, 2368.875, -1732.125, 2369.375}, {-1736.375, 2369.125, -1734.875, 2369.625}, {-1739.125, 2369.375, -1737.625, 2369.875}, {-1741.875, 2369.625, -1740.375, 2370.125}, {-1744.625, 2369.875, -1743.375, 2370.375},
		{-1662.125, 2369.875, -1651.875, 2370.375}, {-1592.125, 2369.875, -1590.375, 2370.625}, {-1747.625, 2370.125, -1746.125, 2370.625}, {-1662.125, 2370.125, -1654.375, 2370.625}, {-1750.375, 2370.375, -1748.875, 2370.875},
		{-1662.125, 2370.375, -1657.125, 2370.875}, {-1592.125, 2370.375, -1590.625, 2372.625}, {-1753.125, 2370.625, -1751.625, 2371.125}, {-1662.125, 2370.625, -1659.875, 2371.125}, {-1755.875, 2370.875, -1754.375, 2371.375},
		{-1758.625, 2371.125, -1757.375, 2371.625}, {-1761.375, 2371.375, -1760.125, 2371.875}, {-1763.625, 2371.625, -1762.875, 2372.125}, {-1684.125, 2371.875, -1673.875, 2372.375}, {-1684.125, 2372.125, -1676.625, 2372.625},
		{-1684.125, 2372.375, -1679.625, 2372.875}, {-1592.125, 2372.375, -1590.875, 2374.375}, {-1684.125, 2372.625, -1682.375, 2373.125}, {-1706.125, 2373.875, -1696.375, 2374.375}, {-1706.125, 2374.125, -1699.125, 2374.625},
		{-1592.125, 2374.125, -1591.125, 2376.375}, {-1706.125, 2374.375, -1701.875, 2374.875}, {-1706.125, 2374.625, -1704.875, 2375.125}, {-1592.125, 2376.125, -1591.375, 2378.125}, {-1592.125, 2377.875, -1591.625, 2380.125},
		{-1010.125, 2378.125, -998.125, 2380.125}, {-1010.375, 2379.875, -998.125, 2386.125}, {-1594.125, 2383.875, -1592.375, 2385.875}, {-1594.125, 2385.625, -1592.625, 2387.625}, {-1010.625, 2385.875, -998.125, 2392.125},
		{-1594.125, 2387.375, -1592.875, 2389.625}, {-1594.125, 2389.375, -1593.125, 2391.625}, {-1594.125, 2391.375, -1593.375, 2393.375}, {-1010.875, 2391.875, -998.125, 2398.125}, {-1594.125, 2393.125, -1593.625, 2395.375},
		{-1011.125, 2397.875, -998.125, 2404.125}, {-1596.125, 2399.875, -1594.375, 2401.125}, {-1596.125, 2400.875, -1594.625, 2402.875}, {-1620.375, 2401.875, -1619.875, 2403.625}, {-1596.125, 2402.625, -1594.875, 2403.125},
		{-1618.125, 2403.875, -1607.625, 2404.375}, {-1011.375, 2403.875, -998.125, 2410.125}, {-1618.125, 2404.125, -1610.375, 2404.625}, {-1618.125, 2404.375, -1613.125, 2404.875}, {-1618.125, 2404.625, -1615.875, 2405.125},
		{-1011.625, 2409.875, -998.125, 2415.875}, {-1011.875, 2415.625, -998.125, 2421.375}, {-1011.875, 2421.125, -991.375, 2421.875}, {-1012.125, 2421.625, -991.375, 2427.875}, {-1012.375, 2427.625, -991.375, 2433.875},
		{-1012.625, 2433.625, -991.375, 2435.375}, {-1012.625, 2435.125, -1004.625, 2439.875}, {-1012.875, 2439.625, -1004.625, 2445.875}, {-1013.125, 2445.625, -1004.625, 2451.875}, {-1013.375, 2451.625, -1004.625, 2457.625},
		{-1597.875, 2456.625, -1596.625, 2457.125}, {-1595.875, 2456.875, -1594.875, 2457.375}, {-1594.125, 2457.125, -1592.875, 2457.625}, {-1592.125, 2457.375, -1590.875, 2457.875}, {-1013.625, 2457.375, -1004.625, 2462.125},
		{-1590.125, 2457.625, -1589.125, 2458.125}, {-1588.375, 2457.875, -1587.125, 2458.375}, {-1586.375, 2458.125, -1585.375, 2458.625}, {-1584.625, 2458.375, -1583.375, 2458.875}, {-1582.625, 2458.625, -1581.375, 2459.125},
		{-1580.625, 2458.875, -1579.625, 2459.375}, {-1578.875, 2459.125, -1577.625, 2459.625}, {-1576.875, 2459.375, -1575.875, 2459.875}, {-1575.125, 2459.625, -1573.875, 2460.125}, {-1573.125, 2459.875, -1571.875, 2460.375},
		{-1572.375, 2460.125, -1571.875, 2473.375}, {-1568.125, 2460.625, -1566.375, 2461.125}, {-1568.125, 2460.875, -1564.375, 2461.375}, {-1568.125, 2461.125, -1562.375, 2461.625}, {-1568.125, 2461.375, -1560.625, 2461.875},
		{-1568.125, 2461.625, -1558.625, 2462.125}, {-1010.875, 2461.875, -1004.625, 2462.375}, {-1162.875, 2462.125, -1162.375, 2518.875}, {-1005.125, 2462.125, -1004.625, 2462.625}, {-1552.125, 2462.625, -1551.125, 2463.125},
		{-1552.125, 2462.875, -1549.125, 2463.375}, {-1552.125, 2463.125, -1547.375, 2463.625}, {-1552.125, 2463.375, -1545.375, 2463.875}, {-1552.125, 2463.625, -1543.625, 2464.125}, {-1538.125, 2464.625, -1535.875, 2465.125},
		{-1538.125, 2464.875, -1534.125, 2465.375}, {-1538.125, 2465.125, -1532.125, 2465.625}, {-1538.125, 2465.375, -1530.125, 2465.875}, {-1538.125, 2465.625, -1528.375, 2466.125}, {-1522.125, 2466.625, -1520.625, 2467.125},
		{-1522.125, 2466.875, -1518.875, 2467.375}, {-1522.125, 2467.125, -1516.875, 2467.625}, {-1522.125, 2467.375, -1515.125, 2467.875}, {-1522.125, 2467.625, -1513.125, 2468.125}, {-1506.125, 2468.625, -1505.625, 2469.125},
		{-1506.125, 2468.875, -1503.625, 2469.375}, {-1506.125, 2469.125, -1501.625, 2469.625}, {-1506.125, 2469.375, -1499.875, 2469.875}, {-1506.125, 2469.625, -1497.875, 2470.125}, {-1492.125, 2470.625, -1490.375, 2471.125},
		{-1492.125, 2470.875, -1488.375, 2471.375}, {-1492.125, 2471.125, -1486.625, 2471.625}, {-1492.125, 2471.375, -1484.625, 2471.875}, {-1492.125, 2471.625, -1482.625, 2472.125}, {-1476.125, 2472.625, -1475.125, 2473.125},
		{174.125, 2472.625, 176.125, 2473.125}, {-1476.125, 2472.875, -1473.125, 2473.375}, {171.375, 2472.875, 176.125, 2473.375}, {-1476.125, 2473.125, -1471.375, 2473.625}, {168.625, 2473.125, 176.125, 2473.625},
		{-1476.125, 2473.375, -1469.375, 2473.875}, {165.625, 2473.375, 176.125, 2473.875}, {-1476.125, 2473.625, -1467.625, 2474.125}, {162.875, 2473.625, 176.125, 2474.125}, {-1464.125, 2474.375, -1463.625, 2478.625},
		{154.625, 2474.375, 156.125, 2474.875}, {151.625, 2474.625, 156.125, 2475.125}, {175.875, 2474.625, 176.375, 2477.625}, {148.875, 2474.875, 156.125, 2475.375}, {146.125, 2475.125, 156.125, 2475.625},
		{143.375, 2475.375, 156.125, 2475.875}, {140.625, 2475.625, 156.125, 2476.125}, {132.125, 2476.375, 134.125, 2476.875}, {129.375, 2476.625, 134.125, 2477.125}, {126.625, 2476.875, 134.125, 2477.375},
		{123.875, 2477.125, 134.125, 2477.625}, {120.875, 2477.375, 134.125, 2477.875}, {175.875, 2477.375, 176.625, 2480.125}, {118.125, 2477.625, 134.125, 2478.125}, {-1464.125, 2478.375, -1463.375, 2482.625},
		{107.125, 2478.625, 110.125, 2479.125}, {104.125, 2478.875, 110.125, 2479.375}, {101.375, 2479.125, 110.125, 2479.625}, {98.625, 2479.375, 110.125, 2479.875}, {95.875, 2479.625, 110.125, 2480.125},
		{173.875, 2479.875, 176.625, 2480.375}, {173.875, 2480.125, 176.875, 2480.875}, {87.375, 2480.375, 88.125, 2480.875}, {84.625, 2480.625, 88.125, 2481.125}, {173.875, 2480.625, 175.875, 2481.125},
		{81.875, 2480.875, 88.125, 2481.375}, {79.125, 2481.125, 88.125, 2481.625}, {76.375, 2481.375, 88.125, 2481.875}, {73.375, 2481.625, 88.125, 2482.125}, {151.875, 2481.875, 161.875, 2482.375},
		{151.875, 2482.125, 159.125, 2482.625}, {-1464.125, 2482.375, -1463.125, 2486.625}, {151.875, 2482.375, 156.375, 2482.875}, {151.875, 2482.625, 153.625, 2483.125}, {129.875, 2483.875, 139.625, 2484.375},
		{129.875, 2484.125, 136.625, 2484.625}, {129.875, 2484.375, 133.875, 2484.875}, {129.875, 2484.625, 131.125, 2485.125}, {107.875, 2485.875, 117.125, 2486.375}, {107.875, 2486.125, 114.375, 2486.625},
		{-1464.125, 2486.375, -1462.875, 2490.125}, {107.875, 2486.375, 111.625, 2486.875}, {107.875, 2486.625, 108.625, 2487.125}, {83.875, 2487.875, 94.625, 2488.375}, {83.875, 2488.125, 91.875, 2488.625},
		{83.875, 2488.375, 89.125, 2488.875}, {83.875, 2488.625, 86.375, 2489.125}, {-1521.625, 2489.875, -1462.875, 2490.625}, {69.875, 2489.875, 72.375, 2490.375}, {69.875, 2490.125, 71.125, 2494.125},
		{-1463.125, 2490.375, -1462.625, 2491.125}, {-1382.875, 2490.875, -1382.375, 2504.125}, {-1462.875, 2494.375, -1462.375, 2495.375}, {-1382.875, 2503.875, -1239.125, 2504.875}, {68.125, 2511.875, 71.375, 2513.125},
		{-33.125, 2513.125, 44.375, 2513.625}, {-33.125, 2513.375, 30.125, 2513.875}, {-33.125, 2513.625, 15.875, 2514.125}, {-4.125, 2513.875, 1.375, 2514.375}, {-1236.375, 2518.625, -1162.375, 2519.875},
		{502.5, 2312.7, 571.35, 2313.2}, {570.9, 2295.2, 639.5, 2295.65}, {639.4, 2291.6, 666.7, 2291.8}, {982.5, 1746.15, 1192.25, 1746.3},
	}
	local pocketBuckets = {}
	for _, pocket in ipairs(pockets) do
		for bucket = math.floor(pocket[2] / 64), math.floor(pocket[4] / 64) do
			pocketBuckets[bucket] = pocketBuckets[bucket] or {}
			table.insert(pocketBuckets[bucket], pocket)
		end
	end
	for _, ring in ipairs(rings) do
		ring.MinX, ring.MaxX, ring.MinZ, ring.MaxZ, ring.Buckets = math.huge, -math.huge, math.huge, -math.huge, {}
		for index, point in ipairs(ring) do
			local nextPoint = ring[index % #ring + 1]
			local x, z, dx, dz = point[1], point[2], nextPoint[1] - point[1], nextPoint[2] - point[2]
			ring.MinX, ring.MaxX = math.min(ring.MinX, x), math.max(ring.MaxX, x)
			ring.MinZ, ring.MaxZ = math.min(ring.MinZ, z), math.max(ring.MaxZ, z)
			local length = dx * dx + dz * dz
			if length > 0 then
				local edge = {X = x, Z = z, EndZ = nextPoint[2], DX = dx, DZ = dz, MinX = math.min(x, nextPoint[1]),
					MaxX = math.max(x, nextPoint[1]), Length = length, Tolerance = math.sqrt(length) * 0.01}
				for bucket = math.floor((math.min(z, nextPoint[2]) - 0.01) / 64), math.floor((math.max(z, nextPoint[2]) + 0.01) / 64) do
					ring.Buckets[bucket] = ring.Buckets[bucket] or {}
					table.insert(ring.Buckets[bucket], edge)
				end
			end
		end
	end
	local function finite(value)
		return type(value) == "number" and value == value and math.abs(value) < 100000000
	end
	local function isLand(x, z)
		if not finite(x) or not finite(z) then return false end
		local bucket = math.floor(z / 64)
		for _, pocket in ipairs(pocketBuckets[bucket] or {}) do
			if x >= pocket[1] and x <= pocket[3] and z >= pocket[2] and z <= pocket[4] then return false end
		end
		for _, ring in ipairs(rings) do
			if x >= ring.MinX - 0.01 and x <= ring.MaxX + 0.01 and z >= ring.MinZ - 0.01 and z <= ring.MaxZ + 0.01 then
				local inside = false
				for _, edge in ipairs(ring.Buckets[bucket] or {}) do
					if x <= edge.MaxX + 0.01 then
						local rx, rz = x - edge.X, z - edge.Z
						if x >= edge.MinX - 0.01 then
							local cross, dot = rx * edge.DZ - rz * edge.DX, rx * edge.DX + rz * edge.DZ
							if math.abs(cross) <= edge.Tolerance and dot >= -edge.Tolerance and dot <= edge.Length + edge.Tolerance then return true end
						end
						if (z < edge.Z) ~= (z < edge.EndZ) and x < edge.X + rz * edge.DX / edge.DZ then inside = not inside end
					end
				end
				if inside then return true end
			end
		end
		return false
	end
	local sea, parts, refreshed = nil, {}, -math.huge
	local function child(parent, name) return parent and parent:FindFirstChild(name) end
	local function attribute(object, name) return object and object:GetAttribute(name) end
	local function contains(point)
		if not point or not finite(point.X) or not finite(point.Y) or not finite(point.Z) then return false end
		local now = tick()
		if now - refreshed >= 5 then
			sea, parts, refreshed = child(game.Workspace, "Sea"), {}, now
			local folder = child(sea, "Water")
			for _, part in ipairs(folder and folder:GetDescendants() or {}) do
				if part.ClassName == "Part" or part.ClassName == "MeshPart" or part.ClassName == "UnionOperation" then parts[#parts + 1] = part end
			end
		end
		local land = isLand(point.X, point.Z)
		for _, part in ipairs(parts) do
			if part.Parent then
				local ocean, height, boatHeight = attribute(part, "OceanVolume"), attribute(part, "SurfaceHeight"), attribute(part, "BoatSurfaceHeight")
				if ocean == nil then ocean = height == nil and boatHeight == nil end
				if not land or ocean ~= true then
					local frame, size = part.CFrame, part.Size
					if frame and size then
						local localPoint = frame:PointToObjectSpace(point)
						if math.abs(localPoint.X) <= size.X * 0.5 + 0.01 and math.abs(localPoint.Z) <= size.Z * 0.5 + 0.01 and localPoint.Y >= -size.Y * 0.5 - 0.01 then
							height = height or boatHeight or attribute(sea, "SurfaceHeight") or attribute(sea, "BoatSurfaceHeight") or part.Position.Y + size.Y * 0.5
							local amplitude = attribute(part, "WaveAmplitude")
							if amplitude == nil then amplitude = attribute(sea, "WaveAmplitude") or attribute(sea, "BoatWaveAmplitude") or 0 end
							if finite(height) and finite(amplitude) and point.Y <= height + math.max(0, amplitude) * 1.5 + 0.01 then return true end
						end
					end
				end
			end
		end
		return false
	end
	return {Contains = contains, IsLand = isLand}
end

_G.StandOutParts = _G.StandOutParts or {}

_G.StandOutParts.PhoneTargetReader = function(player: any, nowFn: any): any
	local clock, nextScan, canvases = nowFn or tick, -math.huge, {}
	local function readText(label: any): string?
		local text = label and label.Text
		return type(text) == "string" and text ~= "failed to fetch text" and text or nil
	end
	return function(): (number?, string)
		if clock() >= nextScan then
			nextScan, canvases = clock() + 3, {}
			local gui = player:FindFirstChild("PlayerGui")
			local phone = gui and gui:FindFirstChild("Phone")
			if phone then
				for _, node in ipairs(phone:GetDescendants()) do
					if node.ClassName == "Frame" then
						local scaled, labels = false, {}
						for _, child in ipairs(node:GetChildren()) do
							if child.ClassName == "UIScale" then
								scaled = true
							end
							if child.ClassName == "TextLabel" then
								labels[#labels + 1] = child
							end
						end
						if scaled and #labels >= 4 then
							canvases[#canvases + 1] = { node = node, labels = labels }
						end
					end
				end
			end
		end
		local matched, message = nil, "Open an active player elimination contract in the phone"
		for _, canvas in ipairs(canvases) do
			if canvas.node.Parent then
				local username, tracking, npc = nil, false, false
				local title, titleY, ambiguous = nil, math.huge, false
				for _, label in ipairs(canvas.labels) do
					local text = readText(label)
					if text then
						username = text:match("^%(@([%w_]+)%)$") or username
						tracking = tracking or text:match("^Location updates in %d+s$") ~= nil
							or text == "Target respawning, bounty still active"
						npc = npc or text == "(NPC)"
					end
					local position = label.AbsolutePosition
					local y = position and position.Y
					if type(y) == "number" and y == y then
						if y < titleY then
							title, titleY, ambiguous = text, y, false
						elseif y == titleY then
							ambiguous = true
						end
					end
				end
				if tracking and not ambiguous and title and title ~= "" and title ~= "ELIMINATIONS" then
					if npc then
						message = "Phone contract targets an NPC"
					elseif username then
						local targetId = nil
						for _, target in ipairs(game:GetService("Players"):GetPlayers()) do
							if target.Name == username and target.UserId ~= player.UserId then
								targetId = target.UserId
								break
							end
						end
						if targetId then
							if matched and matched ~= targetId then
								return nil, "Phone target controls are ambiguous"
							end
							matched, message = targetId, "Tracking " .. username
						else
							message = "Phone target is not another player in this server"
						end
					end
				end
			end
		end
		return matched, message
	end
end

_G.StandOutParts.Resources = function(ctx: any): any
	local resource = {
		Status = { Harvest = "Waiting for grown owned crops", Supplies = "Waiting for buried supplies", Arrows = "Waiting for dropped arrows", Crates = "Waiting for nearby cash cases" },
		Available = { Harvest = true, Supplies = true, Arrows = true, Crates = true },
		Metrics = { Harvest = 0, Supplies = 0, Arrows = 0, Crates = 0, Replants = 0, TargetsCleared = 0 },
		LastConfirmation = {}, CratesProgress = { Opened = nil, Total = 10 },
		SeedOptions = {
			"None", "Amethyst Roka Seed", "Apple Seed", "Banana Seed", "Carrot Seed", "Cherry Seed",
			"Chili Pepper Seed", "Dragon Fruit Seed", "Emerald Roka Seed", "Grapes Seed", "Lemon Seed",
			"Onion Seed", "Opal Roka Seed", "Peach Seed", "Pineapple Seed", "Potato Seed", "Rokaka Seed",
			"Sapphire Roka Seed", "Tomato Seed", "Watermelon Seed",
		},
	}
	local settingKeys = { Harvest = "AutoHarvest", Supplies = "AutoSupplies", Arrows = "AutoArrows", Crates = "AutoCrates" }
	local arrowItems = {
		["Mysterious Arrow"] = true, ["Lucky Arrow"] = true, ["Bizarre Arrow"] = true,
		["Mysterious Arrow [Part 3]"] = true, ["Mysterious Arrow [Part 5]"] = true,
		["Over Heaven Arrow"] = true,
	}
	local cache: any = { Harvest = {}, Supplies = {}, Arrows = {}, Crates = {} }
	local caseIds = {}
	for i = 1, 10 do caseIds[string.format("case_%02d", i)] = true end
	local seedNames, seedKeys = {}, { Y = 89, U = 85, Quote = 222, BackSlash = 220, Minus = 189, Equals = 187 }
	for i = 2, #resource.SeedOptions do seedNames[resource.SeedOptions[i]] = true end
	local retryAfter: { [string]: number }, failedAttempts: { [string]: number } = {}, {}
	local completedCycles: { [string]: boolean } = {}
	local lastCollect, lastRecovery, job: any, now = -math.huge, -math.huge, nil, ctx.now or tick
	local claimScene: any

	local function report(kind: string, message: string)
		if resource.Status[kind] ~= message then
			resource.Status[kind] = message
			ctx.setStatus(kind, message)
		end
	end

	local function child(parent: any, name: string): any
		return parent and parent:FindFirstChild(name) or nil
	end

	local function textOf(instance: any): string?
		local value = instance and instance.Text
		if type(value) == "string" and value ~= "failed to fetch text" then
			return value
		end
		return nil
	end

	local function live(instance: any): boolean
		return instance ~= nil and instance.Parent ~= nil
	end

	local function finitePosition(position: any): boolean
		if not position then
			return false
		end
		local x, y, z = position.X, position.Y, position.Z
		return type(x) == "number" and type(y) == "number" and type(z) == "number"
			and x == x and y == y and z == z
			and math.abs(x) < 1000000 and math.abs(y) < 1000000 and math.abs(z) < 1000000
	end

	local function decodeCases(raw: any): (any, number?)
		if type(raw) ~= "string" then return nil, nil end
		local opened, count = {}, 0
		for id in raw:gmatch("[^,]+") do
			if caseIds[id] and not opened[id] then opened[id], count = true, count + 1 end
		end
		return opened, count
	end

	local function readCases(): any
		local save = child(child(child(ctx.player, "Data"), "Stats"), "HowlerCasesOpened")
		local opened, count = decodeCases(save and save.Value)
		resource.CratesProgress.Opened = count
		return opened
	end

	local function potEligible(owner: any, userId: any, stage: any, inUse: any, potId: any, cycleId: any): boolean
		return type(owner) == "number" and owner == userId and stage == "Ready" and inUse ~= true
			and type(potId) == "string" and potId ~= ""
			and type(cycleId) == "string" and cycleId ~= ""
	end

	local function plantEligible(owner: any, userId: any, stage: any, inUse: any, potId: any, hasDirt: any): boolean
		return type(owner) == "number" and owner == userId and stage == "DirtReady" and inUse ~= true
			and type(potId) == "string" and potId ~= "" and hasDirt == true
	end

	local function progressOf(status: string?): (number?, number?)
		if not status then
			return nil, nil
		end
		local done, count = status:match("(%d+)%s*/%s*(%d+)")
		local completed, total = tonumber(done), tonumber(count)
		if completed and total and total > 0 and total <= 100 and completed <= total then
			return completed, total
		end
		return nil, nil
	end

	local function closingLabel(action: string?, status: string?): boolean
		local combined = string.lower((action or "") .. " " .. (status or ""))
		return combined:find("plant", 1, true) ~= nil or combined:find("next step", 1, true) ~= nil
			or combined:find("continue", 1, true) ~= nil or combined:find("next: your other pot", 1, true) ~= nil
	end

	local function inputBlocked(): boolean
		return ctx.attr(ctx.player, "DialogueInputLocked") == true
			or ctx.attr(ctx.player, "QTEInputLocked") == true
			or ctx.attr(ctx.player, "GardenEffectInputLocked") ~= nil
	end

	local function growingUi(): any
		local playerGui = child(ctx.player, "PlayerGui")
		local gui = child(playerGui, "GrowingInterface")
		if gui then
			return gui
		end
		if playerGui then
			for _, candidate in ipairs(playerGui:GetChildren()) do
				local presentation = child(candidate, "Presentation")
				local instruction = child(presentation, "Instruction")
				local heading = textOf(child(instruction, "Heading"))
				if heading == "HARVEST" or heading == "PLANT THE SEED" then
					return candidate
				end
			end
		end
		return nil
	end

	local function uiState(gui: any): any
		local presentation = child(gui, "Presentation")
		local instruction, footer = child(presentation, "Instruction"), child(presentation, "Footer")
		local action = child(footer, "Action")
		return {
			heading = textOf(child(instruction, "Heading")), body = textOf(child(instruction, "Body")),
			action = textOf(child(action, "Label")), status = textOf(child(footer, "Status")),
		}
	end

	local function collect()
		if now() - lastCollect < 0.2 then
			return
		end
		lastCollect = now()
		cache.Harvest, cache.Supplies, cache.Arrows, cache.Crates = {}, {}, {}, {}
		local opened, localProps = readCases(), child(ctx.world.Parent, "LocalProps")
		if opened and localProps then
			for _, model in ipairs(localProps:GetChildren()) do
				local id = ctx.attr(model, "HowlerCaseId")
				local key = "Crates:" .. tostring(id)
				if model.ClassName == "Model" and caseIds[id] and not opened[id] and (retryAfter[key] or 0) <= now() then
					local base = child(model, "PromptAnchor")
					local prompt = child(base, "HowlerCaseOpen")
					if base and finitePosition(base.Position) and prompt and prompt.ClassName == "ProximityPrompt" then
						cache.Crates[#cache.Crates + 1] = { model = model, base = base, prompt = prompt, key = key, caseId = id, crop = "Cash Case " .. id }
					end
				end
			end
		end
		for _, folderName in ipairs({ "SpawnedItems", "WorldEventDrops" }) do
			local spawnedItems = child(ctx.world, folderName)
			if spawnedItems then
				for _, model in ipairs(spawnedItems:GetChildren()) do
					local itemName, key = ctx.attr(model, "ItemName"), "Arrows:" .. tostring(model.Address)
					if model.ClassName == "Model" and arrowItems[itemName] and (retryAfter[key] or 0) <= now() then
						for _, prompt in ipairs(ctx.findPrompts(model)) do
							if prompt.ClassName == "ProximityPrompt" and (prompt.Name == "WorldItemPickup" or prompt.Name == "WorldEventPickup") then
								local base = prompt.Parent
								if base and base.ClassName == "Attachment" then base = base.Parent end
								if base and finitePosition(base.Position) then
									cache.Arrows[#cache.Arrows + 1] = { model = model, base = base, prompt = prompt, key = key, crop = itemName }
									break
								end
							end
						end
					end
				end
			end
		end
		local gardening = child(ctx.world, "Gardening")
		if not gardening or ctx.attr(gardening, "Enabled") == false then
			return
		end
		local pots = child(gardening, "Pots")
		if pots then
			local wanted = ctx.getSetting("ReplantSeed")
			for _, model in ipairs(pots:GetChildren()) do
				local potId, cycleId = ctx.attr(model, "PotId"), ctx.attr(model, "PlantCycleId")
				local owner, stage, inUse = ctx.attr(model, "OwnerUserId"), ctx.attr(model, "Stage"), ctx.attr(model, "InUse")
				local harvest = potEligible(owner, ctx.player.UserId, stage, inUse, potId, cycleId)
				local planting = seedNames[wanted] and plantEligible(owner, ctx.player.UserId, stage, inUse, potId, ctx.attr(model, "HasDirt"))
				if
					model.ClassName == "Model"
					and (harvest or planting)
				then
					local base = child(model, "Garden Pot")
					local prompt = child(child(base, "Interaction"), "GardenWork")
					local key = harvest and "Harvest:" .. potId .. ":" .. cycleId or "Plant:" .. potId .. ":" .. wanted
					if base and prompt and not completedCycles[key] and (retryAfter[key] or 0) <= now() then
						cache.Harvest[#cache.Harvest + 1] = {
							model = model, base = base, prompt = prompt, key = key,
							cycle = cycleId, crop = harvest and (ctx.attr(model, "Contains") or "crop") or wanted, potId = potId,
							plantOnly = planting == true and not harvest,
						}
					end
				end
			end
		end
		local foraging = child(gardening, "Foraging")
		if foraging then
			for _, model in ipairs(foraging:GetChildren()) do
				if
					model.ClassName == "Model"
					and model.Name == "BuriedSupplies"
					and ctx.attr(model, "GardenSupplyAvailable") == true
				then
					local base = child(model, "Handle")
					local prompt = child(base, "GardenGather")
					local key = "Supplies:" .. tostring(model.Address)
					if
						base
						and prompt
						and ctx.attr(prompt, "StoryPromptAvailable") == true
						and (retryAfter[key] or 0) <= now()
					then
						cache.Supplies[#cache.Supplies + 1] = {
							model = model, base = base, prompt = prompt, key = key,
							crop = ctx.attr(model, "GardenSupplyItem") or "supplies", spawnNode = ctx.attr(model, "SpawnNode"), address = model.Address,
						}
					end
				end
			end
		end
	end

	local function choose(kind: string): any
		local root = ctx.getRoot()
		local rootPosition = root and root.Position
		if not finitePosition(rootPosition) then
			return nil
		end
		local best, bestDistance, bestPriority = nil, math.huge, math.huge
		for _, candidate in ipairs(cache[kind] or {}) do
			local position = live(candidate.model) and live(candidate.base) and candidate.base.Position
			if finitePosition(position) then
				local distance = (rootPosition - position).Magnitude
				local priority = candidate.plantOnly and 1 or 0
				if priority < bestPriority or (priority == bestPriority and distance < bestDistance) then
					best, bestDistance, bestPriority = candidate, distance, priority
				end
			end
		end
		return best
	end

	local function dropJob(message: string, cooldown: number, completed: boolean?)
		if not job then
			return
		end
		local previous = job
		ctx.releaseAll()
		if (completed or previous.harvestConfirmed) and not previous.plantOnly then
			if not previous.harvestConfirmed then resource.Metrics[previous.kind] = resource.Metrics[previous.kind] + 1 end
			if previous.kind == "Supplies" then
				resource.Metrics.TargetsCleared = resource.Metrics.TargetsCleared + 1
			end
			resource.LastConfirmation[previous.kind] = {
				at = now(), item = previous.crop, spawnNode = previous.spawnNode,
				address = previous.address or previous.model.Address, key = previous.key, message = message,
			}
		end
		if (completed or previous.harvestConfirmed) and previous.kind == "Harvest" and not previous.plantOnly then
			completedCycles[previous.key] = true
		end
		retryAfter[previous.key] = now() + cooldown
		job = nil
		lastCollect = -math.huge
		report(previous.kind, message)
	end

	function resource.Poll()
		if not job or job.phase ~= "canceling" then return end
		if ctx.attr(ctx.player, "GrowingInputOwner") ~= job.token then
			dropJob(job.closeMessage, job.closeCooldown, job.closeCompleted)
			return
		end
		local focused = ctx.isFocused and ctx.isFocused() or (not ctx.isFocused and isrbxactive())
		if focused and not inputBlocked() and now() >= (job.closeRetry or 0) then
			local sent = ctx.closeOwnedGrowing and ctx.closeOwnedGrowing(job.token) or (not ctx.closeOwnedGrowing and ctx.tap(8))
			if sent ~= false then job.closeRetry = now() + 0.2 end
		end
		report(job.kind, "Waiting for the owned game interaction to close")
	end

	local function endJob(message: string, cooldown: number, completed: boolean?): boolean
		if job and job.kind == "Harvest" and not job.token and claimScene then claimScene() end
		if job and job.kind == "Harvest" and job.token and ctx.attr(ctx.player, "GrowingInputOwner") == job.token then
			if job.phase ~= "canceling" then
				ctx.releaseAll()
				job.phase, job.dragParts, job.projection = "canceling", nil, nil
				job.closeMessage, job.closeCooldown, job.closeCompleted = message, cooldown, completed
			end
			resource.Poll()
			return false
		end
		dropJob(message, cooldown, completed)
		return true
	end

	local function samePot(): boolean
		return live(job.model) and ctx.attr(job.model, "OwnerUserId") == ctx.player.UserId
			and ctx.attr(job.model, "PotId") == job.potId
	end

	local function finishReplant(message: string): string
		local finished = endJob((job.plantOnly and "Planting; " or "Harvest completed; ") .. message, job.replantConfirmed and 0.1 or 10, true)
		return finished and "done" or "busy"
	end

	local function markHarvest()
		job.harvestConfirmed = true
		resource.Metrics.Harvest = resource.Metrics.Harvest + 1
		completedCycles[job.key] = true
	end

	local function seedScene(token: string?, potId: string?): (any, string?, any)
		local camera = child(ctx.world.Parent, "Camera")
		local expectedToken, expectedPot = token or (job and job.token), potId or (job and job.potId)
		if not camera or not expectedToken or ctx.attr(ctx.player, "GrowingInputOwner") ~= expectedToken then return nil, "waiting" end
		local cameraOwner = ctx.attr(camera, "GrowingCameraOwner")
		if type(cameraOwner) == "string" and cameraOwner ~= "" and cameraOwner ~= expectedToken then return nil, "waiting" end
		if job and now() < (job.nextSceneRead or 0) then
			local preview = job.scenePreview
			return nil, "waiting", live(preview) and ctx.attr(preview, "PotId") == expectedPot and preview or nil
		end
		if job then job.nextSceneRead = now() + 0.15 end
		local matching, other, matchedPreview = false, false, nil
		for _, scene in ipairs(camera:GetChildren()) do
			if scene.Name == "GrowingLocal" then
				local preview = child(scene, "GrowingPot")
				if preview and (not expectedPot or ctx.attr(preview, "PotId") == expectedPot) then
					matching, matchedPreview = true, preview
					if job then job.scenePreview = preview end
					local bag, source, dirt = child(preview, "GrowingBag"), nil, nil
					for i, part in ipairs(preview:GetDescendants()) do
						if i > 128 then break end
						local class = part.ClassName
						if (class == "Part" or class == "MeshPart" or class == "UnionOperation") and finitePosition(part.Position) then
							if part.Name == "Dirt" then dirt = part
							elseif bag and part.Parent and part.Parent.Address == bag.Address then source = source or part end
						end
					end
					if dirt and source then return { source = source, dirt = dirt, preview = preview, camera = camera }, nil end
				elseif preview then other = true
				end
			end
		end
		return nil, not matching and other and "changed" or "waiting", matchedPreview
	end

	claimScene = function()
		if not samePot() then return end
		local owner, gui = ctx.attr(ctx.player, "GrowingInputOwner"), growingUi()
		if type(owner) ~= "string" or owner == "" or not gui then return end
		local heading = uiState(gui).heading
		local seedSceneOpen = heading == "PLANT THE SEED" and seedNames[job.replantSeed]
			and ctx.attr(ctx.player, "GardeningSelectedItem") == job.replantSeed
		local harvestSceneOpen = heading == "HARVEST" and not job.plantOnly and not job.harvestConfirmed
		if not seedSceneOpen and not harvestSceneOpen then return end
		job.nextSceneRead = nil
		local parts, _, preview = seedScene(owner)
		if parts or preview then job.gui, job.token = gui, owner end
	end

	local function recoverPlant(): boolean
		if now() - lastRecovery < 0.2 then return false end
		lastRecovery = now()
		local seed, owner = ctx.getSetting("ReplantSeed"), ctx.attr(ctx.player, "GrowingInputOwner")
		local gui = growingUi()
		if not seedNames[seed] or type(owner) ~= "string" or owner == "" or not gui or uiState(gui).heading ~= "PLANT THE SEED"
			or ctx.attr(ctx.player, "GardeningSelectedItem") ~= seed then return false end
		local parts = seedScene(owner)
		local id = parts and ctx.attr(parts.preview, "PotId")
		local pots = child(child(ctx.world, "Gardening"), "Pots")
		if type(id) ~= "string" or id == "" or not pots then return false end
		for _, model in ipairs(pots:GetChildren()) do
			if model.ClassName == "Model" and ctx.attr(model, "PotId") == id and ctx.attr(model, "OwnerUserId") == ctx.player.UserId
				and ctx.attr(model, "Stage") == "DirtReady" and ctx.attr(model, "HasDirt") == true then
				local base = child(model, "Garden Pot")
				local prompt = child(child(base, "Interaction"), "GardenWork")
				if base and prompt and finitePosition(base.Position) then
					local cycle = ctx.attr(model, "PlantCycleId")
					job = { kind = "Harvest", model = model, base = base, prompt = prompt, potId = id,
						key = "Plant:" .. id .. ":" .. seed, crop = seed, replantSeed = seed, plantOnly = true,
						cycle = cycle, clearCycle = cycle, seedStarted = true, seedId = ctx.attr(ctx.player, "GardeningSelectedId"),
						phase = "planting", gui = gui, token = owner, seedParts = parts, dragParts = parts,
						started = now(), deadline = now() + 45, lastInput = 0, targetPosition = base.Position }
					report("Harvest", "Resuming the owned pot planting scene")
					return true
				end
			end
		end
		return false
	end

	function resource.Render()
		if not job or not job.dragParts then return end
		local parts = job.dragParts
		if not parts.source or not parts.dirt then job.projection = nil; return end
		local source, goal = parts.source.Position, parts.dirt.Position
		if not finitePosition(source) or not finitePosition(goal) then job.projection = nil; return end
		local a, av = WorldToScreen(source)
		local b, bv = WorldToScreen(goal + Vector3.new(0, 2.6, 0))
		job.projection = av and bv and { source = a, goal = b, at = now() } or nil
	end

	local function stepReplant(): string
		if ctx.getSetting("ReplantSeed") ~= job.replantSeed then return finishReplant("replant stopped because the seed preference changed") end
		if not samePot() then return finishReplant("replant skipped because the pot owner or ID changed") end
		local owner, stage = ctx.attr(ctx.player, "GrowingInputOwner"), ctx.attr(job.model, "Stage")
		local cycle, contains = ctx.attr(job.model, "PlantCycleId"), ctx.attr(job.model, "Contains")
		local planted = job.seedStarted and stage == "Growing" and contains == job.replantSeed
			and type(cycle) == "string" and cycle ~= "" and cycle ~= job.cycle and cycle ~= job.clearCycle
		if planted and not job.replantConfirmed then
			job.replantConfirmed = true
			resource.Metrics.Replants = resource.Metrics.Replants + 1
			resource.LastConfirmation.Replant = { at = now(), item = contains, potId = job.potId, cycle = cycle, key = job.key, message = "Selected seed planted" }
			ctx.releaseAll()
			if owner == job.token then
				if job.phase ~= "closingSeed" then ctx.tap(8); job.deadline = now() + 5 end
				job.phase, job.dragParts = "closingSeed", nil
			else return finishReplant("planted " .. job.replantSeed) end
		end
		if job.phase == "closingSeed" then
			if owner ~= job.token then return finishReplant(job.replantConfirmed and "planted " .. job.replantSeed or "planting closed without confirmation") end
			return "busy"
		end
		if inputBlocked() or string.lower(uiState(job.gui).status or ""):find("time stopped", 1, true) then
			ctx.releaseAll()
			job.dragPhase, job.goalAt = nil, nil
			job.deadline = math.min(math.max(job.deadline, now() + 15), job.started + 180)
			report("Harvest", "Replant paused")
			return "busy"
		end
		if job.phase == "replantReady" then
			if owner ~= nil or ctx.attr(ctx.player, "GardeningInputLocked") == true then return "busy" end
			if stage == "Ready" then
				if job.plantOnly then return finishReplant("free pot now has a crop") end
				report("Harvest", "Waiting for the harvested pot to clear"); return "busy"
			end
			if stage ~= "DirtReady" or ctx.attr(job.model, "InUse") == true then return finishReplant("replant skipped because the pot is not ready for a seed") end
			job.clearCycle, job.phase, job.deadline = cycle, "selectingSeed", now() + 12
		end
		if job.phase == "selectingSeed" then
			if stage ~= "DirtReady" or cycle ~= job.clearCycle or ctx.attr(job.model, "InUse") == true or owner ~= nil then
				return finishReplant("replant skipped because the pot changed before seed selection")
			end
			if ctx.focusPrompt and not ctx.focusPrompt(job.prompt, true) then return "busy" end
			local strip = child(child(child(ctx.player, "PlayerGui"), "GardenSeedStrip"), "Strip")
			local caption = textOf(child(strip, "Caption"))
			local key = caption and seedKeys[caption:match("^%[([%w]+)%] Next seed$")]
			if not key then report("Harvest", "Waiting for native seed selection controls"); return "busy" end
			local selectedName, selectedId = ctx.attr(ctx.player, "GardeningSelectedItem"), ctx.attr(ctx.player, "GardeningSelectedId")
			if job.selectionPendingAt then
				if selectedName == job.previousSelectionName and selectedId == job.previousSelectionId and now() - job.selectionPendingAt < 1.5 then
					report("Harvest", "Waiting for native seed selection acknowledgment"); return "busy"
				end
				job.selectionPendingAt = nil
			end
			if selectedName == job.replantSeed then
				job.seedId, job.phase, job.deadline = selectedId, "openingSeed", now() + 12
			elseif now() - job.lastInput >= 0.2 then
				if ctx.tap(key) ~= false then
					job.lastInput, job.selectionPendingAt = now(), now()
					job.previousSelectionName, job.previousSelectionId = selectedName, selectedId
				end
				report("Harvest", "Selecting owned " .. job.replantSeed .. " in the native seed strip")
			end
			return "busy"
		end
		if job.phase == "openingSeed" then
			if ctx.attr(ctx.player, "GardeningSelectedItem") ~= job.replantSeed or ctx.attr(ctx.player, "GardeningSelectedId") ~= job.seedId then
				return finishReplant("replant skipped because the selected seed changed")
			end
			local gui = growingUi()
			if type(owner) == "string" and owner ~= "" and gui and uiState(gui).heading == "PLANT THE SEED" then
				local parts, sceneState, preview = seedScene(owner)
				if sceneState == "changed" then return finishReplant("planting opened for another pot") end
				if preview then job.gui, job.token = gui, owner end
				if not parts then report("Harvest", "Waiting for the owned pot planting scene"); return "busy" end
				job.gui, job.token, job.phase, job.seedStarted = gui, owner, "planting", true
				job.deadline, job.dragParts, job.seedParts = now() + 45, parts, parts
				ctx.releaseAll()
			elseif owner ~= nil then return finishReplant("replant skipped because another interaction opened")
			elseif stage == "DirtReady" and cycle == job.clearCycle and ctx.attr(job.model, "InUse") ~= true then
				if ctx.focusPrompt and not ctx.focusPrompt(job.prompt, true) then return "busy" end
				ctx.interact(job.prompt)
			else return finishReplant("replant skipped because the pot changed before planting") end
			report("Harvest", "Opening planting for " .. job.replantSeed)
			return "busy"
		end
		if owner ~= job.token or not live(job.gui) then return finishReplant("planting was interrupted") end
		if not job.seedParts or not live(job.seedParts.preview) or ctx.attr(job.seedParts.preview, "PotId") ~= job.potId then
			return finishReplant("planting scene no longer belongs to the harvested pot")
		end
		local cameraOwner = ctx.attr(job.seedParts.camera, "GrowingCameraOwner")
		if type(cameraOwner) == "string" and cameraOwner ~= "" and cameraOwner ~= job.token then return finishReplant("planting camera belongs to another interaction") end
		local state = uiState(job.gui)
		if state.heading ~= "PLANT THE SEED" then return finishReplant("planting controls changed") end
		local lower = string.lower(state.status or "")
		local done, count = progressOf(state.status)
		local actionLower = string.lower(state.action or "")
		if state.status == "PLANTED" or actionLower:find("continue", 1, true) or actionLower:find("next step", 1, true) then
			ctx.releaseAll()
			if job.phase ~= "awaitingSeedReceipt" then job.deadline = now() + 5 end
			job.phase, job.dragParts = "awaitingSeedReceipt", nil
			report("Harvest", "Waiting for selected seed planting confirmation")
		elseif done and count and string.lower(state.action or ""):find("cover", 1, true) then
			ctx.release(1)
			job.dragParts = nil
			if done < count and not lower:find("working", 1, true) and now() - job.lastInput >= 0.15 then
				ctx.tap(32)
				job.lastInput = now()
			end
			report("Harvest", "Covering planted seed " .. tostring(done) .. "/" .. tostring(count))
		elseif lower:find("plant ", 1, true) or lower:find("drag the seed", 1, true) then
			job.dragParts = job.dragParts or seedScene()
			local projection = job.projection
			if not projection or now() - projection.at > 0.6 then
				if job.dragPhase == "carrying" then ctx.release(1) end
				job.dragPhase, job.goalAt = nil, nil
				report("Harvest", "Waiting for visible planting targets"); return "busy"
			end
			if job.dragPhase == "dropped" then
				if now() < job.dragRetry then return "busy" end
				if (job.dragAttempts or 0) >= 3 then return finishReplant("seed placement was not confirmed") end
				job.dragPhase = nil
			end
			if not job.dragPhase then
				if ctx.mouseMove(projection.source.X, projection.source.Y, nil, true) ~= false and ctx.hold(1) ~= false then
					job.dragPhase, job.dragAt, job.dragAttempts, job.dragStart = "carrying", now(), (job.dragAttempts or 0) + 1, projection.source
					job.dragGoal, job.dragProgress, job.dragPoint, job.goalAt = projection.goal, 0, nil, nil
				end
			elseif job.dragPhase == "carrying" then
				if ctx.hold(1) == false then ctx.release(1); job.dragPhase, job.goalAt = nil, nil; return "busy" end
				if math.abs(projection.goal.X - job.dragGoal.X) > 2 or math.abs(projection.goal.Y - job.dragGoal.Y) > 2 then
					job.dragAt, job.dragStart, job.dragGoal, job.dragProgress, job.dragPoint, job.goalAt = now(), projection.source, projection.goal, 0, nil, nil
				end
				local elapsed = now() - job.dragAt
				if elapsed >= 0.1 then
					if not job.dragPoint then
						local progress = math.min(1, job.dragProgress + 0.25, (elapsed - 0.1) / 0.55)
						job.dragPoint = { X = job.dragStart.X + (job.dragGoal.X - job.dragStart.X) * progress,
							Y = job.dragStart.Y + (job.dragGoal.Y - job.dragStart.Y) * progress, progress = progress }
					end
					job.goalReady = ctx.mouseMove(job.dragPoint.X, job.dragPoint.Y, nil, true) ~= false
					if job.goalReady then job.dragProgress, job.dragPoint = job.dragPoint.progress, nil end
					local position, soil = job.dragParts.source.Position, job.dragParts.dirt.Position
					local nearSoil = finitePosition(position) and finitePosition(soil)
						and (position.X - soil.X) ^ 2 + (position.Z - soil.Z) ^ 2 <= 0.55 ^ 2
					if job.dragProgress == 1 and job.goalReady and nearSoil then job.goalAt = job.goalAt or now() else job.goalAt = nil end
					if job.goalAt and now() - job.goalAt >= 0.2 then ctx.release(1); job.dragPhase, job.dragRetry = "dropped", now() + 1.2 end
				end
			end
			report("Harvest", "Placing selected seed over the soil")
		else report("Harvest", "Waiting for native planting progress") end
		return "busy"
	end

	function resource.Stop(kind: string?)
		if job and (not kind or job.kind == kind) then
			endJob("Stopped", 2, false)
			if job and job.phase == "canceling" and ctx.closeOwnedGrowing and not job.closeWorker then
				job.closeWorker = true
				local token, deadline = job.token, now() + 45
				task.spawn(function()
					while job and job.phase == "canceling" and job.token == token and now() < deadline do
						resource.Poll()
						task.wait(0.1)
					end
					if job and job.token == token then job.closeWorker = nil end
				end)
			end
		end
	end

	function resource.Busy(kind: string?): boolean
		return job ~= nil and (not kind or job.kind == kind) and job.phase ~= "moving"
	end

	function resource.Ready(kind: string, candidate: boolean?): boolean
		resource.Poll()
		if job and job.phase == "canceling" then return job.kind == kind end
		if not resource.Available[kind] or not ctx.getSetting(settingKeys[kind]) then
			resource.Stop(kind)
			return false
		end
		if job and (job.kind == kind or not candidate) then
			return job.kind == kind
		end
		if not job and kind == "Harvest" and recoverPlant() then return true end
		if
			inputBlocked()
			or ctx.attr(ctx.player, "GrowingInputOwner") ~= nil
			or ctx.attr(ctx.player, "GardeningInputLocked") == true
		then
			report(kind, "Waiting for the current game interaction to close")
			return false
		end
		collect()
		if kind == "Crates" and resource.CratesProgress.Opened == nil then
			report(kind, "Waiting for readable saved cash case progress")
			return false
		end
		if #cache[kind] == 0 then
			report(
				kind,
				kind == "Crates" and (resource.CratesProgress.Opened == 10 and "All 10 cash cases are saved as opened"
					or "Waiting for nearby cash cases (" .. tostring(resource.CratesProgress.Opened) .. "/10 opened)")
					or kind == "Harvest" and (seedNames[ctx.getSetting("ReplantSeed")] and "Waiting for grown crops or free owned pots" or "Waiting for grown owned crops")
					or (kind == "Supplies" and "Waiting for buried supplies" or "Waiting for dropped arrows")
			)
			return false
		end
		return choose(kind) ~= nil
	end

	function resource.Step(kind: string): string
		if not resource.Ready(kind) then
			return "waiting"
		end
		if job and job.phase == "canceling" then return "busy" end
		if not job then
			local selected = choose(kind)
			if not selected then
				return "waiting"
			end
			job = selected
			job.kind, job.phase = kind, "moving"
			job.started, job.deadline, job.lastInput = now(), now() + 45, 0
			job.targetPosition = selected.base.Position
			local seed = kind == "Harvest" and ctx.getSetting("ReplantSeed") or nil
			job.replantSeed = seedNames[seed] and seed or nil
		end
		if not ctx.getRoot() then
			endJob("Interrupted by character respawn", 3, false)
			return "blocked"
		end
		if kind == "Crates" then
			local opened = readCases()
			if not opened then
				endJob("Saved cash case progress is unavailable", 10, false)
				return "blocked"
			end
			if opened[job.caseId] then
				local confirmed = job.attempted == true
				endJob(confirmed and "Cash case opening saved" or "Cash case was already opened", confirmed and 0.1 or 2, confirmed)
				return confirmed and "done" or "waiting"
			end
		end
		local removed, depleted = not live(job.model), kind == "Supplies" and ctx.attr(job.model, "GardenSupplyAvailable") == false
		if kind == "Crates" and (removed or not live(job.base)) then
			if job.attempted and job.phase ~= "confirming" then
				ctx.releaseAll()
				job.phase, job.deadline = "confirming", now() + 5
			end
			if job.attempted and now() <= job.deadline then
				report(kind, "Waiting for saved cash case confirmation")
				return "busy"
			end
			endJob("Cash case disappeared without saved confirmation", 10, false)
			return "waiting"
		end
		local currentItem, currentNode = kind == "Supplies" and ctx.attr(job.model, "GardenSupplyItem") or nil,
			kind == "Supplies" and ctx.attr(job.model, "SpawnNode") or nil
		local refreshed = kind == "Supplies"
			and not removed
			and (
				(type(currentItem) == "string" and currentItem ~= job.crop)
				or (type(currentNode) == "string" and job.spawnNode ~= nil and currentNode ~= job.spawnNode)
			)
		if kind ~= "Harvest" and kind ~= "Crates" and (removed or depleted or refreshed) then
			failedAttempts[job.key] = nil
			local rootPosition = ctx.getRoot().Position
			local nearby = finitePosition(rootPosition)
				and finitePosition(job.targetPosition)
				and (rootPosition - job.targetPosition).Magnitude <= 8
			local focused = ctx.isFocused and ctx.isFocused() or (not ctx.isFocused and isrbxactive())
			local confirmed = job.attempted == true and (kind == "Arrows" or depleted or (nearby and focused))
			endJob(
				confirmed and (kind == "Supplies" and "Supply node cleared" or "Arrow pickup confirmed")
					or "Target changed before pickup could be verified",
				confirmed and 0.1 or 2,
				confirmed
			)
			return confirmed and "done" or "waiting"
		end
		if not live(job.model) or not live(job.base) then
			endJob("Target disappeared", 3, false)
			return "waiting"
		end
		if now() > job.deadline then
			local attempts = (failedAttempts[job.key] or 0) + 1
			failedAttempts[job.key] = attempts
			endJob(job.plantOnly and "Planting timed out without confirmation" or (job.harvestConfirmed and "Harvest completed; replant timed out without further attempts" or "Interaction timed out; waiting before retry"), attempts >= 3 and 60 or 10, false)
			return "blocked"
		end

		if job.phase == "moving" then
			if
				kind == "Harvest"
				and not (job.plantOnly and plantEligible(
					ctx.attr(job.model, "OwnerUserId"), ctx.player.UserId, ctx.attr(job.model, "Stage"),
					ctx.attr(job.model, "InUse"), ctx.attr(job.model, "PotId"), ctx.attr(job.model, "HasDirt")
				) or not job.plantOnly and potEligible(
					ctx.attr(job.model, "OwnerUserId"),
					ctx.player.UserId,
					ctx.attr(job.model, "Stage"),
					ctx.attr(job.model, "InUse"),
					ctx.attr(job.model, "PotId"),
					ctx.attr(job.model, "PlantCycleId")
				))
			then
				endJob("Crop is no longer available", 2, false)
				return "waiting"
			end
			local position = job.base.Position
			if not finitePosition(position) then
				endJob("Target position is unavailable", 10, false)
				return "blocked"
			end
			local rootPosition = ctx.getRoot().Position
			if (rootPosition - position).Magnitude > 6 then
				ctx.move(position + Vector3.new(0, 3, 0))
				report(kind, "Moving to " .. tostring(job.crop))
				return "busy"
			end
			job.phase = kind == "Harvest" and (job.plantOnly and "replantReady" or "opening") or "gathering"
			job.deadline = now() + 18
			job.targetPosition = position
		end

		if kind ~= "Harvest" then
			if job.phase == "gathering" then
				if kind == "Crates" then
					if ctx.attr(job.model, "HowlerCaseId") ~= job.caseId or not live(job.prompt) then
						endJob("Cash case interaction changed", 10, false); return "waiting"
					end
					local rootPosition, point = ctx.getRoot().Position, job.base.Position
					if not finitePosition(rootPosition) or not finitePosition(point) then
						endJob("Cash case position is unavailable", 10, false); return "blocked"
					end
					if (rootPosition - point).Magnitude > 8 then
						job.holdAt, job.phase = nil, "moving"
						ctx.move(point + Vector3.new(0, 3, 0)); report(kind, "Moving to " .. tostring(job.crop)); return "busy"
					end
					local focused = ctx.isFocused and ctx.isFocused() or (not ctx.isFocused and isrbxactive())
					if not focused or inputBlocked() or ctx.attr(ctx.player, "GardeningInputLocked") == true or ctx.attr(ctx.player, "GrowingInputOwner") ~= nil then
						job.holdAt = nil; report(kind, "Pickup is currently blocked"); return "busy"
					end
					if not live(job.remote) then job.remote = child(child(game.ReplicatedStorage, "Remotes"), "HowlerCases") end
					local remote = job.remote
					if not remote or remote.ClassName ~= "RemoteEvent" then
						job.holdAt = nil; report(kind, "Waiting for the HowlerCases remote"); return "busy"
					end
					if job.holdAt and now() - job.holdAt < 0.8 then report(kind, "Opening " .. tostring(job.crop)); return "busy" end
					local action = job.holdAt and "Open" or "Hold"
					local ok, result = pcall(function() return remote:FireServer(action, job.caseId) end)
					if not ok or result == false then endJob("Cash case request failed: " .. tostring(result), 10, false); return "blocked" end
					if action == "Hold" then job.holdAt = now(); report(kind, "Opening " .. tostring(job.crop))
					else
						job.attempted, job.phase, job.deadline = true, "confirming", now() + 5
						report(kind, "Waiting for saved cash case confirmation")
					end
					return "busy"
				end
				local result = ctx.interact(job.prompt)
				if result ~= "blocked" then
					job.attempted = true
				end
				if result == "triggered" then
					job.phase, job.deadline = "confirming", now() + 5
				end
				report(
					kind,
					result == "blocked" and "Pickup is currently blocked"
						or (kind == "Supplies" and "Uncovering " or "Collecting ") .. tostring(job.crop)
				)
			elseif job.phase == "confirming" then
				report(kind, "Waiting for pickup confirmation")
			end
			return "busy"
		end
		if job.harvestConfirmed or job.plantOnly then return stepReplant() end
		local wantedSeed = ctx.getSetting("ReplantSeed")
		job.replantSeed = seedNames[wantedSeed] and wantedSeed or nil

		local owner = ctx.attr(ctx.player, "GrowingInputOwner")
		if job.phase == "opening" then
			local gui = growingUi()
			local state = gui and uiState(gui)
			if type(owner) == "string" and owner ~= "" and state and state.heading == "HARVEST" then
				job.gui, job.token, job.phase = gui, owner, "harvesting"
				job.deadline = now() + 45
				ctx.releaseAll()
				report(kind, "Harvesting " .. tostring(job.crop))
			else
				if ctx.focusPrompt and not ctx.focusPrompt(job.prompt, true) then return "busy" end
				ctx.interact(job.prompt)
				report(kind, "Opening harvest")
			end
			return "busy"
		end
		if owner ~= job.token then
			local cycleId, stage = ctx.attr(job.model, "PlantCycleId"), ctx.attr(job.model, "Stage")
			local completed = job.completeSeen == true
				or (type(cycleId) == "string" and cycleId ~= "" and cycleId ~= job.cycle)
				or stage == "Empty"
				or stage == "DirtReady"
				or stage == "Growing"
			if completed and job.replantSeed then
				markHarvest()
				job.phase, job.deadline, job.token = "replantReady", now() + 12, nil
				ctx.releaseAll()
				report(kind, "Harvest completed; preparing to replant " .. job.replantSeed)
				return "busy"
			end
			endJob(completed and "Harvest completed" or "Harvest was interrupted", completed and 0.1 or 10, completed)
			return completed and "done" or "blocked"
		end
		if not live(job.gui) then
			endJob("Harvest interface closed", 10, false)
			return "blocked"
		end
		local state = uiState(job.gui)
		local done, count = progressOf(state.status)
		if job.phase == "closing" then
			return "busy"
		end
		if state.heading ~= "HARVEST" or closingLabel(state.action, state.status) then
			if state.heading == "HARVEST" then
				job.completeSeen = true
				ctx.tap(8)
			end
			job.phase = "closing"
			job.deadline = now() + 5
			report(kind, job.replantSeed and "Closing harvest before replanting " .. job.replantSeed or "Closing harvest without replanting")
			return "busy"
		end
		local statusLower = string.lower(state.status or "")
		if statusLower:find("time stopped", 1, true) or inputBlocked() then
			ctx.releaseAll()
			job.deadline = math.min(math.max(job.deadline, now() + 15), job.started + 120)
			report(kind, "Harvest paused")
			return "busy"
		end
		if
			done
			and count
			and done < count
			and not statusLower:find("working", 1, true)
			and string.lower(state.action or ""):find("pick", 1, true)
			and now() - job.lastInput >= 0.15
		then
			ctx.tap(32)
			job.lastInput = now()
			report(kind, "Picking fruit " .. tostring(done + 1) .. "/" .. tostring(count))
		elseif done and count and done >= count then
			report(kind, "Waiting for harvest confirmation")
		elseif not state.status or not state.action then
			report(kind, "Waiting for readable harvest controls")
		end
		return "busy"
	end

	function resource.SelfTest(): boolean
		assert(#resource.SeedOptions == 20 and resource.SeedOptions[1] == "None")
		assert(seedNames["Rokaka Seed"] and not seedNames["Peridot Roka Seed"] and not seedNames.None)
		local opened, openedCount = decodeCases("case_01,case_02,case_01,unknown,case_10")
		assert(openedCount == 3 and opened.case_01 and opened.case_02 and opened.case_10 and not opened.unknown)
		assert(decodeCases(nil) == nil and not caseIds.case_11)
		assert(potEligible(7, 7, "Ready", false, "pot", "cycle"))
		assert(not potEligible(8, 7, "Ready", false, "pot", "cycle"))
		assert(not potEligible(7, 7, "Growing", false, "pot", "cycle"))
		assert(not potEligible(7, 7, "Ready", true, "pot", "cycle"))
		assert(potEligible(7, 7, "Ready", nil, "pot", "cycle"))
		assert(not potEligible(7, 7, "Ready", false, "pot", nil))
		assert(plantEligible(7, 7, "DirtReady", nil, "pot", true))
		assert(not plantEligible(8, 7, "DirtReady", nil, "pot", true) and not plantEligible(7, 7, "DirtReady", true, "pot", true))
		local done, count = progressOf("CLICK EACH FRUIT | 2 / 4")
		assert(done == 2 and count == 4)
		assert(progressOf("Working...") == nil)
		assert(progressOf("99 / 4") == nil)
		assert(closingLabel("Space Plant again", "PLANT ROKAKA AGAIN (x1)"))
		assert(closingLabel("Next step", "NEXT: YOUR OTHER POT"))
		assert(not closingLabel("Space Pick", "CLICK EACH FRUIT | 2 / 4"))
		assert(arrowItems["Mysterious Arrow"] and arrowItems["Lucky Arrow"])
		assert(not arrowItems["Arrow Part"] and not arrowItems["Stone Mask"])
		assert("Harvest:pot:cycleA" ~= "Harvest:pot:cycleB")
		return true
	end

	readCases()
	return resource
end

_G.StandOutParts = _G.StandOutParts or {}

local components = { "Heart", "Star", "Moon", "Clasp" }
local fishSymbols = { "Jelly", "Fish", "Beyond", "Humu", "Shark", "Frog", "Seal", "Bass" }

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function integer(value, low, high)
	return finite(value) and value % 1 == 0 and value >= low and value <= high
end

local function sampleStroke(stroke, count)
	local lengths, total = {}, 0
	for index = 2, #stroke do
		local a, b = stroke[index - 1], stroke[index]
		local length = math.sqrt((b.X - a.X) ^ 2 + (b.Y - a.Y) ^ 2)
		lengths[index] = length
		total += length
	end
	local result, segment, passed = { stroke[1] }, 2, 0
	for index = 2, count - 1 do
		local distance = total * (index - 1) / (count - 1)
		while segment < #stroke and passed + lengths[segment] < distance do
			passed += lengths[segment]
			segment += 1
		end
		local a, b = stroke[segment - 1], stroke[segment]
		local alpha = lengths[segment] > 0 and math.clamp((distance - passed) / lengths[segment], 0, 1) or 0
		result[index] = Vector2.new(a.X + (b.X - a.X) * alpha, a.Y + (b.Y - a.Y) * alpha)
	end
	result[count] = stroke[#stroke]
	return result
end

local function cursorAngle(track, cursor, geometry)
	if not track or not cursor or not track.Parent or not cursor.Parent then return nil end
	local p, size, cp, cs = track.AbsolutePosition, track.AbsoluteSize, cursor.AbsolutePosition, cursor.AbsoluteSize
	if not p or not cp or not finite(p.X) or not finite(p.Y) or not finite(cp.X) or not finite(cp.Y) then return nil end
	local width, height = size and size.X or 0, size and size.Y or 0
	local cx, cy, reset = cs and cs.X or 0, cs and cs.Y or 0, false
	local x, y
	if finite(width) and finite(height) and width > 10 and height > 10 and finite(cx) and finite(cy) and cx > 0 and cy > 0 then
		if geometry and geometry.fallback then geometry.fallback, reset = false, true end
		x, y = (cp.X + cx / 2 - p.X) / width, (cp.Y + cy / 2 - p.Y) / height
	else
		if not geometry then return nil end
		if not finite(width) or not finite(height) or width <= 10 or height <= 10 then
			local panel = track.Parent.AbsolutePosition
			if not panel or not finite(panel.X) or not finite(panel.Y) then return nil end
			width, height = (p.X - panel.X) * 0.64 / 0.18, (p.Y - panel.Y) * 0.64 / 0.15
		end
		if not finite(width) or not finite(height) or width <= 10 or height <= 10 then return nil end
		if not geometry.fallback or geometry.track ~= track.Address or geometry.cursor ~= cursor.Address
			or geometry.x ~= p.X or geometry.y ~= p.Y or geometry.width ~= width or geometry.height ~= height then
			geometry.fallback, geometry.track, geometry.cursor = true, track.Address, cursor.Address
			geometry.x, geometry.y, geometry.width, geometry.height = p.X, p.Y, width, height
			geometry.minX, geometry.maxX, geometry.minY, geometry.maxY, geometry.ready = cp.X, cp.X, cp.Y, cp.Y, false
			reset = true
		end
		if not geometry.ready and geometry.resting then
			-- The native countdown fixes the cursor at the middle of the top edge.
			geometry.offsetX, geometry.offsetY, geometry.ready = p.X + width * 0.5 - cp.X, p.Y + height * 0.05 - cp.Y, true
		end
		if not geometry.ready then
			geometry.minX, geometry.maxX = math.min(geometry.minX, cp.X), math.max(geometry.maxX, cp.X)
			geometry.minY, geometry.maxY = math.min(geometry.minY, cp.Y), math.max(geometry.maxY, cp.Y)
			local spanX, spanY = geometry.maxX - geometry.minX, geometry.maxY - geometry.minY
			local toleranceX, toleranceY = math.max(0.01, width * 0.001), math.max(0.01, height * 0.001)
			if spanX > width * 0.9 + toleranceX or spanY > height * 0.9 + toleranceY then
				geometry.minX, geometry.maxX, geometry.minY, geometry.maxY = cp.X, cp.X, cp.Y, cp.Y
				reset = true
			elseif math.abs(spanX - width * 0.9) <= toleranceX and math.abs(spanY - height * 0.9) <= toleranceY then
				geometry.offsetX, geometry.offsetY, geometry.ready = p.X + width * 0.05 - geometry.minX, p.Y + height * 0.05 - geometry.minY, true
			end
		end
		if not geometry.ready then return nil, reset end
		x, y = (cp.X + geometry.offsetX - p.X) / width, (cp.Y + geometry.offsetY - p.Y) / height
	end
	if not finite(x) or not finite(y) or x < 0 or x > 1 or y < 0 or y > 1 then return nil, reset end
	local side, nearest = 1, math.abs(y - 0.05)
	for index, distance in ipairs({math.abs(x - 0.95), math.abs(y - 0.95), math.abs(x - 0.05)}) do
		if distance < nearest then side, nearest = index + 1, distance end
	end
	if nearest > 0.12 then return nil, reset end
	local turn
	if side == 1 then turn = (x - 0.05) / 0.9
	elseif side == 2 then turn = 1 + (y - 0.05) / 0.9
	elseif side == 3 then turn = 2 + (0.95 - x) / 0.9
	else turn = 3 + (0.95 - y) / 0.9 end
	return ((turn - 0.5) % 4) * 90, reset
end

local function choiceText(button)
	if not button then return "" end
	local label = button:FindFirstChild("Label") or button
	return tostring(label.Text or ""):lower():gsub("^%s*%d+%.%s*", ""):gsub("[%.%!%?]+$", "")
end

local function investigativeChoice(buttons)
	local accepted = {
		["where is the missing package"] = true,
		["where's the missing package"] = true,
		["where is hubert's missing package"] = true,
		["how did you know where hubert's package was"] = true,
	}
	local selected
	for index = 1, 2 do
		local button = buttons[index]
		if accepted[choiceText(button)] then
			if selected then return nil end
			selected = index
		end
	end
	return selected
end

_G.StandOutParts.Incidents = function(ctx)
	local controller, player = {}, ctx.player
	local http = game:GetService("HttpService")
	local remote = game.ReplicatedStorage.Remotes.Bounty
	local readNative, scanNative = ctx.incidentReadTable or readtbl, ctx.incidentScan or getgc
	local refreshNative = ctx.incidentRefresh or refreshgc
	local readMemory, nativeTables = ctx.incidentReadMemory or memory_read, {}
	local session, drawingToken, drawingMemory, storageModule, jewelryModule, armModule, verityModule, tabletopModule
	local armRemote = game.ReplicatedStorage.Remotes.ArmWrestling
	local tabletopRemote = game.ReplicatedStorage.Remotes.Tabletop
	local scanFunctions = ctx.incidentFunctionScan or findgc
	local function say(text) ctx.setStatus("Bounties", text) end
	local function child(parent, name) return parent and parent:FindFirstChild(name) end
	local function stringValue(value)
		if type(value) ~= "string" then return nil end
		if value:sub(1, 1) == '"' then
			local ok, decoded = pcall(function() return http:JSONDecode(value) end)
			return ok and type(decoded) == "string" and decoded or nil
		end
		return value
	end
	local function address(value)
		local hex = type(value) == "string" and value:match("^table%(0x(%x+)%)$")
		local result = hex and tonumber(hex, 16)
		return integer(result, 65536, 281474976710655) and result or nil
	end
	local function memory(kind, pointer)
		if type(readMemory) ~= "function" or not integer(pointer, 65536, 281474976710655) then return nil end
		local ok, result = pcall(readMemory, kind, pointer)
		return ok and result or nil
	end
	local function tableExponent(pointer)
		local current = memory("byte", pointer + 1) == 6
		if not current and memory("byte", pointer) ~= 6 then return nil end
		local exponent = memory("byte", pointer + (current and 4 or 5))
		if not integer(exponent, 0, 7) or current and memory("byte", pointer + 7) ~= math.min(2 ^ exponent - 1, 255) then return nil end
		return exponent
	end
	local function nativePointer(row)
		if integer(row.addr, 65536, 281474976710655) then
			if memory("int", row.addr + 12) ~= 6 then return nil end
			local pointer = memory("uintptr", row.addr)
			if integer(pointer, 65536, 281474976710655) and tableExponent(pointer) ~= nil then
				nativeTables[pointer] = true
				return pointer
			end
			return nil
		end
		return row.type == "table" and address(row.value) or nil
	end
	local function instancePointer(field)
		if not integer(field, 65536, 281474976710655) or memory("int", field + 12) ~= 8 then return nil end
		local pointer = memory("uintptr", field)
		if not integer(pointer, 65536, 281474976710655)
			or memory("byte", pointer + 1) ~= 8 and memory("byte", pointer) ~= 8
			or memory("int", pointer + 4) ~= 16 then return nil end
		local instance = memory("uintptr", pointer + 16)
		return integer(instance, 65536, 281474976710655) and instance or nil
	end
	local function readMap(pointer, slots)
		if not integer(pointer, 65536, 281474976710655) then return nil end
		local array, arrayCount, nodes = nil, 0, pointer
		if nativeTables[pointer] then
			local exponent = tableExponent(pointer)
			if exponent == nil then return nil end
			arrayCount, array = memory("int", pointer + 8), memory("uintptr", pointer + 32)
			nodes = memory("uintptr", pointer + 40)
			if not integer(exponent, 0, 7) or not integer(arrayCount, 0, 128)
				or not integer(nodes, 65536, 281474976710655)
				or (arrayCount > 0 and not integer(array, 65536, 281474976710655)) then return nil end
			slots = 2 ^ exponent
		end
		local ok, rows = pcall(readNative, nodes, slots)
		if not ok or type(rows) ~= "table" then return nil end
		local result, kinds = {}, {}
		for _, row in ipairs(rows) do
			local key = row.key
			if type(key) == "string" or integer(key, 1, 128) then
				local tablePointer, instance = nativePointer(row), instancePointer(row.addr)
				if tablePointer then result[key], kinds[key] = tablePointer, "table"
				elseif instance then result[key], kinds[key] = instance, "Instance"
				elseif row.type == "string" then
					local decoded = stringValue(row.value)
					result[key] = decoded
				elseif row.type == "number" then
					local number = tonumber(row.value)
					if finite(number) then result[key] = number end
				elseif row.type == "boolean" then
					if row.addr ~= nil then
						if not integer(row.addr, 65536, 281474976710655) or memory("int", row.addr + 12) ~= 1 then return nil end
						local boolean = memory("int", row.addr)
						if boolean ~= 0 and boolean ~= 1 then return nil end
						result[key] = boolean == 1
					elseif row.value == true or row.value == "true" then result[key] = true
					elseif row.value == false or row.value == "false" then result[key] = false
					else return nil end
				elseif row.type == "table" then result[key] = nativePointer(row) end
				kinds[key] = kinds[key] or row.type
			end
		end
		for index = 1, arrayCount do
			local field = array + (index - 1) * 16
			local tag = memory("int", field + 12)
			if tag == 3 then
				local number = memory("double", field)
				if finite(number) then result[index], kinds[index] = number, "number" end
			elseif tag == 1 then
				local boolean = memory("int", field)
				if boolean ~= 0 and boolean ~= 1 then return nil end
				result[index], kinds[index] = boolean == 1, "boolean"
			elseif tag == 6 then
				local pointerValue = memory("uintptr", field)
				if integer(pointerValue, 65536, 281474976710655) and tableExponent(pointerValue) ~= nil then
					nativeTables[pointerValue] = true
					result[index], kinds[index] = pointerValue, "table"
				end
			elseif tag == 8 then
				local pointerValue = memory("uintptr", field)
				local current = memory("byte", pointer + 1) == 6
				if integer(pointerValue, 65536, 281474976710655) and memory("byte", pointerValue + (current and 1 or 0)) == 8
					and memory("byte", pointerValue + 3) == 9 and memory("int", pointerValue + 4) == 8 then
					local x, y = memory("float", pointerValue + 16), memory("float", pointerValue + 20)
					if finite(x) and finite(y) and x >= 0 and x <= 1 and y >= 0 and y <= 1 then result[index], kinds[index] = Vector2.new(x, y), "Vector2" end
				end
			end
		end
		return result, kinds, arrayCount
	end
	local function typed(map, kinds, field, kind)
		return map ~= nil and kinds ~= nil and kinds[field] == kind and map[field] ~= nil
	end
	local function nativeMap(pointer)
		if not integer(pointer, 65536, 281474976710655) or tableExponent(pointer) == nil then return nil end
		nativeTables[pointer] = true
		return readMap(pointer, 128)
	end
	local function closureRefs(pointer)
		if not integer(pointer, 65536, 281474976710655) then return nil end
		local current = memory("byte", pointer + 1) == 7
		if not current and memory("byte", pointer) ~= 7 then return nil end
		if memory("byte", pointer + (current and 5 or 3)) ~= 0 then return nil end
		local count = memory("byte", pointer + 4)
		if not integer(count, 1, 48) then return nil end
		local refs = {}
		for index = 0, count - 1 do
			local field = pointer + 32 + index * 16
			refs[index + 1] = {tag = memory("int", field + 12), pointer = memory("uintptr", field), field = field}
		end
		return refs
	end
	local function tabletopModulePointer(refs)
		if not refs then return nil end
		local found, hasRemote
		for _, ref in ipairs(refs) do
			if instancePointer(ref.field) == tabletopRemote.Address then hasRemote = true end
			if ref.tag == 6 then
				local _, kinds = nativeMap(ref.pointer)
				if kinds and kinds.Start == "function" and kinds.Refresh == "function" and kinds.Close == "function" then
					if found and found ~= ref.pointer then return nil end
					found = ref.pointer
				end
			end
		end
		return hasRemote and found or nil
	end
	local function tabletopSnapshot()
		if not tabletopRemote or tabletopRemote.ClassName ~= "RemoteEvent" or not integer(tabletopRemote.Address, 65536, 281474976710655) then return nil end
		if not tabletopModule then
			tabletopModule = {candidates = {}}
			local ok, rows
			if ctx.incidentFunctionScan then
				ok, rows = pcall(scanFunctions, "Refresh", {Start = "function", Refresh = "function", Close = "function"})
			else
				ok, rows = pcall(scanNative, "Start")
				if ok and type(rows) == "table" then
					local starts = {}
					for _, row in ipairs(rows) do
						if row.key == "Start" and row.type == "function" then starts[#starts + 1] = row end
					end
					rows = starts
				end
			end
			if not ok or type(rows) ~= "table" or #rows > 256 then return nil end
			local seen = {}
			for _, row in ipairs(rows) do
				if row.key == "Start" and integer(row.addr, 65536, 281474976710655) and memory("int", row.addr + 12) == 7 then
					local pointer = memory("uintptr", row.addr)
					local refs = closureRefs(pointer)
					local module = tabletopModulePointer(refs)
					if module and not seen[pointer] then
						seen[pointer] = true
						tabletopModule.candidates[#tabletopModule.candidates + 1] = {start = pointer, module = module}
					end
				end
			end
		end
		if #tabletopModule.candidates ~= 1 then return nil end
		local candidate = tabletopModule.candidates[1]
		local refs = closureRefs(candidate.start)
		if tabletopModulePointer(refs) ~= candidate.module then return nil end
		local module, kinds = nativeMap(candidate.module)
		if not typed(module, kinds, "Session", "table") then return nil end
		return nativeMap(module.Session)
	end
	local function armSnapshot()
		if not armRemote or armRemote.ClassName ~= "RemoteEvent" or not integer(armRemote.Address, 65536, 281474976710655) then return nil end
		if not armModule then
			armModule = {candidates = {}}
			local ok, rows
			if ctx.incidentFunctionScan then
				ok, rows = pcall(ctx.incidentFunctionScan, "GetSession", {GetSession = "function", Stop = "function"})
			else
				ok, rows = pcall(getgc, {"GetSession", "Stop"})
			end
			if not ok or type(rows) ~= "table" or #rows > 4096 then return nil end
			local gets, stops = {}, {}
			for _, row in ipairs(rows) do
				if (row.key == "GetSession" or row.key == "Stop") and integer(row.addr, 65536, 281474976710655)
					and memory("int", row.addr + 12) == 7 then
					local pointer = memory("uintptr", row.addr)
					local refs = closureRefs(pointer)
					if refs then
						if row.key == "GetSession" and #refs == 1 and refs[1].tag == 15 then gets[pointer] = refs[1].pointer
						elseif row.key == "Stop" and #refs == 6 and refs[1].tag == 15 and instancePointer(refs[2].field) == armRemote.Address then
							stops[pointer] = refs[1].pointer
						end
					end
				end
			end
			for get, cell in pairs(gets) do
				for stop, other in pairs(stops) do
					if cell == other then armModule.candidates[#armModule.candidates + 1] = {get = get, stop = stop, cell = cell} end
				end
			end
		end
		if #armModule.candidates ~= 1 then return nil end
		local candidate = armModule.candidates[1]
		local gets, stops = closureRefs(candidate.get), closureRefs(candidate.stop)
		if not gets or #gets ~= 1 or not stops or #stops ~= 6 or gets[1].tag ~= 15 or stops[1].tag ~= 15
			or gets[1].pointer ~= candidate.cell or stops[1].pointer ~= candidate.cell
			or instancePointer(stops[2].field) ~= armRemote.Address then return nil end
		local cell = candidate.cell
		if memory("byte", cell + 1) ~= 15 and memory("byte", cell) ~= 15 then return nil end
		local value = memory("uintptr", cell + 8)
		if not integer(value, 65536, 281474976710655) or memory("int", value + 12) ~= 6 then return nil end
		local pointer = memory("uintptr", value)
		local snapshot, kinds = nativeMap(pointer)
		return snapshot, kinds, pointer
	end
	local function jewelrySnapshot()
		if not remote or remote.ClassName ~= "RemoteEvent" or not integer(remote.Address, 65536, 281474976710655) then return nil end
		if not jewelryModule then
			jewelryModule = {candidates = {}}
			local ok, rows = pcall(scanFunctions, "IsOpen", {IsOpen = "function", Close = "function"})
			if not ok or type(rows) ~= "table" or #rows > 256 then return nil end
			local opens, closes = {}, {}
			for _, row in ipairs(rows) do
				if (row.key == "IsOpen" or row.key == "Close") and integer(row.addr, 65536, 281474976710655)
					and memory("int", row.addr + 12) == 7 then
					local pointer = memory("uintptr", row.addr)
					local refs = closureRefs(pointer)
					if refs then
						if row.key == "IsOpen" and #refs == 1 and refs[1].tag == 15 then opens[pointer] = refs[1].pointer
						elseif row.key == "Close" and #refs == 6 and refs[3].tag == 15 and instancePointer(refs[5].field) == remote.Address then
							closes[pointer] = refs[3].pointer
						end
					end
				end
			end
			for open, cell in pairs(opens) do
				for close, other in pairs(closes) do
					if cell == other then jewelryModule.candidates[#jewelryModule.candidates + 1] = {open = open, close = close, cell = cell} end
				end
			end
		end
		if #jewelryModule.candidates ~= 1 then return nil end
		local candidate = jewelryModule.candidates[1]
		local opens, closes = closureRefs(candidate.open), closureRefs(candidate.close)
		if not opens or #opens ~= 1 or not closes or #closes ~= 6 or opens[1].tag ~= 15 or closes[3].tag ~= 15
			or opens[1].pointer ~= candidate.cell or closes[3].pointer ~= candidate.cell
			or instancePointer(closes[5].field) ~= remote.Address then return nil end
		local cell = candidate.cell
		if memory("byte", cell + 1) ~= 15 and memory("byte", cell) ~= 15 then return nil end
		local value = memory("uintptr", cell + 8)
		if not integer(value, 65536, 281474976710655) or memory("int", value + 12) ~= 6 then return nil end
		local pointer = memory("uintptr", value)
		local snapshot, kinds = nativeMap(pointer)
		return snapshot, kinds, pointer
	end
	local function veritySnapshot(gui)
		if not gui or not integer(gui.Address, 65536, 281474976710655) or not remote or remote.ClassName ~= "RemoteEvent" then return nil end
		local function valueField(cell)
			if not integer(cell, 65536, 281474976710655) or memory("byte", cell + 1) ~= 15 and memory("byte", cell) ~= 15 then return nil end
			local field = memory("uintptr", cell + 8)
			return integer(field, 65536, 281474976710655) and field or nil
		end
		local function capture(pointer)
			local refs = closureRefs(pointer)
			if not refs or #refs ~= 6 or refs[1].tag ~= 15 or refs[2].tag ~= 15 or refs[4].tag ~= 15
				or instancePointer(valueField(refs[2].pointer)) ~= remote.Address
				or instancePointer(valueField(refs[4].pointer)) ~= gui.Address then return nil end
			return refs[1].pointer
		end
		if not verityModule or verityModule.gui ~= gui.Address then
			verityModule = {gui = gui.Address, candidates = {}}
			local ok, rows
			if ctx.incidentFunctionScan then ok, rows = pcall(ctx.incidentFunctionScan, "CloseChoices", {CloseChoices = "function"})
			else ok, rows = pcall(getgc, "CloseChoices") end
			if not ok or type(rows) ~= "table" or #rows > 4096 then return nil end
			local seen = {}
			for _, row in ipairs(rows) do
				if row.key == "CloseChoices" and integer(row.addr, 65536, 281474976710655) and memory("int", row.addr + 12) == 7 then
					local pointer = memory("uintptr", row.addr)
					if not seen[pointer] then
						seen[pointer] = true
						local cell = capture(pointer)
						if cell then verityModule.candidates[#verityModule.candidates + 1] = {pointer = pointer, cell = cell} end
					end
				end
			end
		end
		if #verityModule.candidates ~= 1 then return nil end
		local candidate = verityModule.candidates[1]
		if capture(candidate.pointer) ~= candidate.cell then return nil end
		local field = valueField(candidate.cell)
		if not field or memory("int", field + 12) ~= 6 then return nil end
		local pointer = memory("uintptr", field)
		local snapshot, kinds = nativeMap(pointer)
		return snapshot, kinds, pointer
	end
	local function storageSnapshot()
		local storageRemote = child(game.ReplicatedStorage.Remotes, "StandStorage")
		if not storageRemote or storageRemote.ClassName ~= "RemoteEvent" then return nil end
		if not storageModule then
			storageModule = {candidates = {}}
			local scan = ctx.incidentFunctionScan or findgc
			if type(scan) ~= "function" then return nil end
			local ok, rows = pcall(scan, "Start", {Start = "function", Stop = "function", Init = "function", Refresh = "function"})
			if not ok or type(rows) ~= "table" or #rows > 256 then return nil end
			local starts, stops = {}, {}
			for _, row in ipairs(rows) do
				if (row.key == "Start" or row.key == "Stop") and integer(row.addr, 65536, 281474976710655)
					and memory("int", row.addr + 12) == 7 then
					local pointer = memory("uintptr", row.addr)
					local refs = closureRefs(pointer)
					if refs then
						if row.key == "Start" and #refs == 13 and refs[1].tag == 15 and instancePointer(refs[5].field) == storageRemote.Address then
							starts[pointer] = refs[1].pointer
						elseif row.key == "Stop" and (#refs == 9 or #refs == 10) and refs[3].tag == 15 then stops[pointer] = refs[3].pointer end
					end
				end
			end
			for start, cell in pairs(starts) do
				for stop, other in pairs(stops) do
					if cell == other then storageModule.candidates[#storageModule.candidates + 1] = {start = start, stop = stop, cell = cell} end
				end
			end
		end
		if #storageModule.candidates ~= 1 then return nil end
		local candidate = storageModule.candidates[1]
		local starts, stops = closureRefs(candidate.start), closureRefs(candidate.stop)
		if not starts or #starts ~= 13 or not stops or (#stops ~= 9 and #stops ~= 10) or starts[1].tag ~= 15 or stops[3].tag ~= 15
			or starts[1].pointer ~= candidate.cell or stops[3].pointer ~= candidate.cell
			or instancePointer(starts[5].field) ~= storageRemote.Address then return nil end
		local cell = candidate.cell
		if memory("byte", cell + 1) ~= 15 and memory("byte", cell) ~= 15 then return nil end
		local value = memory("uintptr", cell + 8)
		if not integer(value, 65536, 281474976710655) or memory("int", value + 12) ~= 6 then return nil end
		local pointer = memory("uintptr", value)
		local snapshot, kinds = nativeMap(pointer)
		return snapshot, kinds, pointer
	end
	function controller.GoFishStep(state, cached)
		local index = type(state.active) == "string" and tonumber(state.active:match("^%d+%-(%d+)"))
		local expired = state.active == nil and state.readable == true and storageModule and storageModule.owned ~= nil
		if (index ~= 13 and not expired) or state.inputLock ~= true or state.dialogue == true or state.leader ~= player.UserId then return false end
		local native, kinds, pointer = storageSnapshot()
		local actor = child(child(ctx.world, "NPCs"), "Darby")
		local root, character = actor and child(actor, "HumanoidRootPart"), player.Character
		if not actor or not actor.Parent or not root or not root.Parent or not typed(native, kinds, "Npc", "Instance")
			or native.Npc ~= actor.Address or not typed(native, kinds, "Root", "Instance") or native.Root ~= root.Address
			or not typed(native, kinds, "State", "table") or not typed(native, kinds, "Phase", "string") or native.PvP == true then return false end
		if expired then
			if storageModule.owned ~= pointer then return false end
			local now = ctx.now()
			if now >= (storageModule.nextAction or 0) then
				local remote = child(game.ReplicatedStorage.Remotes, "StandStorage")
				local ok, result = pcall(function() return remote:FireServer("Close") end)
				if ok and result ~= false then storageModule.nextAction = now + 0.5 end
			end
			say("Go Fish: closing the expired bounty table")
			return true
		end
		local data, dataKinds = nativeMap(native.State)
		local wager = typed(data, dataKinds, "Wager", "table") and nativeMap(data.Wager)
		if not wager or wager.Bounty ~= true and not (storageModule.owned == pointer and storageModule.contract == state.active) then return false end
		storageModule.owned, storageModule.contract = pointer, state.active
		local now = ctx.now()
		if now < (storageModule.nextAction or 0) then return true end
		local function tap(key, text)
			if ctx.tap(key) then storageModule.nextAction = now + 0.3 end
			say(text)
		end
		if native.Phase == "Table" then
			if native.Leaving or native.Waiting or native.Picker then say("Go Fish: waiting for the table"); return true end
			if state.claim or wager.Bounty ~= true then tap(88, "Go Fish: leaving the native table")
			elseif native.Selected ~= 1 then tap(37, "Go Fish: selecting the bounty wager")
			elseif native.Action == "Unlock" then
				local button = cached.storageAction
				local caption = child(button, "Caption")
				if button and button.Parent and caption and caption.Text == "CHALLENGE" then
					if ctx.click(button) then storageModule.nextAction = now + 0.3 end
					say("Go Fish: starting D'Arby's native challenge")
				else tap(32, "Go Fish: starting the native bounty game") end
			else say("Go Fish: waiting for the bounty wager") end
			return true
		end
		if native.Phase ~= "Fish" then say("Go Fish: waiting for the native transition"); return true end
		local fish, fishKinds
		if typed(native, kinds, "Fish", "table") then fish, fishKinds = nativeMap(native.Fish) end
		if not fish or not typed(fish, fishKinds, "Session", "table") or fish.Session ~= pointer then
			say("Go Fish: waiting for matching card authority"); return true
		end
		if storageModule.fish ~= native.Fish then storageModule.fish, storageModule.missed = native.Fish, {} end
		if fish.Phase == "Result" then
			local actions = typed(fish, fishKinds, "ResultActions", "table") and nativeMap(fish.ResultActions)
			if actions and (type(actions.Second) == "string" and actions.Second ~= "" or actions.First == "BACK TO THE TABLE") then
				tap(88, "Go Fish: closing the native result")
			elseif actions and type(actions.First) == "string" and actions.First ~= "" then tap(32, "Go Fish: retrying the native game")
			else say("Go Fish: waiting for native result actions") end
			return true
		end
		local queue
		if typed(fish, fishKinds, "Queue", "table") then queue = nativeMap(fish.Queue) end
		if fish.Phase ~= "Play" or fish.Ended or fish.Paused == true or fish.Pumping or fish.Waiting or not queue or next(queue) ~= nil
			or character and (ctx.attr(character, "TimeStopped") or ctx.attr(character, "Stunned")) then
			say("Go Fish: waiting for the native turn"); return true
		end
		local view, viewKinds
		if typed(fish, fishKinds, "View", "table") then view, viewKinds = nativeMap(fish.View) end
		if not view then say("Go Fish: waiting for the native cards"); return true end
		local action = typed(view, viewKinds, "Action", "table") and nativeMap(view.Action)
		if action and (action.Kind == "Draw" or action.Kind == "Give") and action.Id ~= nil then
			if table.find(fishSymbols, action.Symbol) then
				if action.Kind == "Draw" and action.Refill == false then storageModule.missed[action.Symbol] = true
				elseif action.Kind == "Give" then storageModule.missed[action.Symbol] = nil end
			end
			tap(32, action.Kind == "Draw" and "Go Fish: drawing from the deck" or "Go Fish: giving the requested cards")
			return true
		end
		if view.Turn ~= "You" or action then say("Go Fish: waiting for D'Arby"); return true end
		local hand = typed(view, viewKinds, "Hand", "table") and nativeMap(view.Hand)
		if not hand then say("Go Fish: waiting for the native hand"); return true end
		for symbol, count in pairs(hand) do
			if not table.find(fishSymbols, symbol) or not integer(count, 0, 4) then say("Go Fish: waiting for valid native cards"); return true end
		end
		local best, bestCount, bestSlot, slot = nil, 0, nil, 0
		local alternative = false
		for _, symbol in ipairs(fishSymbols) do if (hand[symbol] or 0) > 0 and not storageModule.missed[symbol] then alternative = true; break end end
		if not alternative then storageModule.missed = {} end
		for _, symbol in ipairs(fishSymbols) do
			local count = hand[symbol]
			if count and count > 0 then
				slot += 1
				if not storageModule.missed[symbol] and count > bestCount then best, bestCount, bestSlot = symbol, count, slot end
			end
		end
		if bestSlot then tap(48 + bestSlot, "Go Fish: asking for " .. best)
		else say("Go Fish: waiting for matching legal cards") end
		return true
	end
	local function drawingReference(pointer)
		local strokes, kinds, count = readMap(pointer, 64)
		if not strokes or not integer(count, 1, 64) then return nil end
		local reference, total = {}, 0
		for key in pairs(strokes) do if not integer(key, 1, count) then return nil end end
		for index = 1, count do
			if not typed(strokes, kinds, index, "table") then return nil end
			local points, pointKinds, pointCount = readMap(strokes[index], 128)
			if not points or not integer(pointCount, 2, 128) then return nil end
			local stroke = {}
			for key in pairs(points) do if not integer(key, 1, pointCount) then return nil end end
			for point = 1, pointCount do
				if not typed(points, pointKinds, point, "Vector2") then return nil end
				stroke[point] = points[point]
				if point > 1 then
					local a, b = stroke[point - 1], stroke[point]
					total += math.sqrt((b.X - a.X) ^ 2 + (b.Y - a.Y) ^ 2)
				end
			end
			if total > 24 then return nil end
			reference[index] = stroke
		end
		return reference
	end
	local function currentToken(state)
		return type(state.progress) == "table" and state.progress.IncidentToken or nil
	end
	local function send(action, payload)
		payload.Action = action
		local ok, accepted
		if ctx.incidentSend then ok, accepted = pcall(ctx.incidentSend, payload)
		else ok, accepted = pcall(function() return remote:FireServer("Incident", payload) end) end
		return ok and accepted ~= false
	end
	local function clear()
		if session and session.ownedPress then ctx.release(1) end
		session = nil
	end
	local function enter(kind, key, state)
		if not session or session.kind ~= kind or session.key ~= key or session.id ~= state.active then
			clear()
			session = { kind = kind, key = key, id = state.active, born = ctx.now(), completed = 0 }
		end
		return session
	end
	local function acquire(owner, anchor, schema, accepts, slots, acceptsRow, unique)
		if owner.pointer then return true end
		local now = ctx.now()
		if now - owner.born < 0.4 or (owner.scanAt and now - owner.scanAt < 1) then return false end
		owner.scanAt = now
		if not owner.scanned then
			owner.scanned = true
			local ok, rows = pcall(scanNative, anchor, schema)
			if not ok or type(rows) ~= "table" then return false end
			owner.scanRows = rows
		else
			if not owner.scanRows or type(refreshNative) ~= "function" then return false end
			local ok, rows = pcall(refreshNative, owner.scanRows)
			if not ok or rows == false then return false end
			if type(rows) == "table" and #rows > 0 then owner.scanRows = rows end
		end
		local rows = owner.scanRows
		local seen, examined, selected = {}, 0, nil
		local tag = ({ table = 6, number = 3, string = 5, boolean = 1 })[schema[anchor]]
		for index = 1, #rows do
			if examined >= 64 then if unique then return false end; break end
			local row = rows[index]
			local pointer = row.tbl
			if (row.vtt == nil or tag == nil or row.vtt == tag) and (not acceptsRow or acceptsRow(row))
				and integer(pointer, 65536, 281474976710655) and not seen[pointer] then
				seen[pointer] = true
				examined += 1
				local map, kinds = readMap(pointer, slots)
				if accepts(map, kinds) then
					if not unique then owner.pointer = pointer; return true end
					if selected then return false end
					selected = pointer
				end
			end
		end
		if selected then owner.pointer = selected; return true end
		return false
	end
	local function dialogueChoices(gui, npc)
		local holder = child(child(gui, "Dialogue"), "Holder")
		local title, choices = child(holder, "Title"), child(holder, "Choices")
		if not title or title.Text ~= npc or not choices then return nil end
		local captions, numbers, count = {}, {}, 0
		for _, button in ipairs(choices:GetChildren()) do
			if button.Parent and button.ClassName == "ImageButton" then
				local box = child(button, "Box")
				local number = box and type(box.Text) == "string" and tonumber(box.Text:match("^%s*(%d+)%."))
				if not integer(number, 1, 9) or tonumber(button.Name) ~= number or numbers[number] then return nil end
				local caption = choiceText(box)
				if captions[caption] then return nil end
				captions[caption], numbers[number], count = number, true, count + 1
			end
		end
		return captions, count
	end
	local function jewelryDialogue(state, cached, scenes)
		local progress, token = state.progress, currentToken(state)
		if state.dialogue ~= true or state.jewelry == true or type(progress) ~= "table" or progress.IncidentScenario ~= "Jewelry"
			or progress.ReadyToClaim == true or type(token) ~= "string" or token == ""
			or not integer(state.leader, 1, 9007199254740991)
			or (progress.IncidentPhase ~= nil and type(progress.IncidentPhase) ~= "string") then return false end
		local npc, accept, decline = progress.IncidentNPC
		if npc == "Dragona" then accept, decline = "let's open them", "give me a minute"
		elseif npc == "Meryl Mei Qi" then
			accept = progress.IncidentPhase == "report" and "hand over the necklace and evidence" or "i'll ask dragona to help"
			decline = progress.IncidentPhase == "report" and "one moment" or "i'll be back"
		else return false end
		local choices, count = dialogueChoices(cached.gui, npc)
		if not choices or not choices[accept] or not choices[decline]
			or count ~= 2 and not (count == 3 and npc == "Meryl Mei Qi" and choices["about driving practice"]) then return false end
		local owned = false
		for _, scene in ipairs(scenes or {}) do
			local id = ctx.attr(scene, "BountyId") or ctx.attr(scene, "Bounty")
			if scene.Parent and id ~= nil and tostring(id) == state.active
				and tonumber(ctx.attr(scene, "BountyLeaderId")) == state.leader then owned = true; break end
		end
		if not owned and type(ctx.findPrompts) == "function" and type(ctx.position) == "function" then
			local actor = child(child(ctx.world, "NPCs"), npc)
			local root = ctx.getRoot()
			local a, b = root and root.Position, actor and ctx.position(actor)
			if a and b and finite(a.X) and finite(a.Y) and finite(a.Z) and finite(b.X) and finite(b.Y) and finite(b.Z)
				and (a - b).Magnitude <= 8 then
				local phase, marker = progress.IncidentPhase, state.targetMarker
				local actorRoot, detector = child(actor, "HumanoidRootPart"), child(actor, "ClickDetector")
				if state.leader == player.UserId and (npc == "Meryl Mei Qi" and (phase == "meryl" or phase == "report") or npc == "Dragona" and phase == "dragona")
					and actor.ClassName == "Model" and actor.Parent and actor.Parent.Address == child(ctx.world, "NPCs").Address
					and actorRoot and actorRoot.Parent and actorRoot.Parent.Address == actor.Address
					and detector and detector.Parent and detector.Parent.Address == actor.Address and detector.ClassName == "ClickDetector"
					and marker and finite(marker.X) and finite(marker.Y) and finite(marker.Z) and (marker - b).Magnitude <= 8 then
					owned = true
					for _, object in ipairs({ actor, actorRoot, detector }) do
						local id = ctx.attr(object, "BountyId") or ctx.attr(object, "Bounty")
						local leader = ctx.attr(object, "BountyLeaderId") or ctx.attr(object, "BountyOwnerId")
						local owner, carrier = ctx.attr(object, "StoryPromptOwnerId"), ctx.attr(object, "BountyDeliveryCarrierId")
						if id ~= nil and tostring(id) ~= state.active or leader ~= nil and tonumber(leader) ~= state.leader
							or owner ~= nil and tonumber(owner) ~= player.UserId or carrier ~= nil and tonumber(carrier) ~= player.UserId
							or ctx.attr(object, "StoryPromptAvailable") == false or ctx.attr(object, "BountySourceHidden") == true
							or ctx.attr(object, "BountyDeliveryAvailable") == false then owned = false; break end
					end
				end
				for _, prompt in ipairs(ctx.findPrompts(actor)) do
					local id = ctx.attr(prompt, "BountyId") or ctx.attr(prompt, "Bounty")
					local owner = ctx.attr(prompt, "StoryPromptOwnerId")
					local carrier = ctx.attr(prompt, "BountyDeliveryCarrierId")
					if prompt.Parent and prompt:IsDescendantOf(actor) and (id == nil or tostring(id) == state.active)
						and tonumber(ctx.attr(prompt, "BountyLeaderId")) == state.leader
						and (owner == nil or tonumber(owner) == player.UserId)
						and (carrier == nil or tonumber(carrier) == player.UserId)
						and ctx.attr(prompt, "StoryPromptAvailable") == true
						and ctx.attr(prompt, "BountySourceHidden") ~= true
						and ctx.attr(prompt, "BountyDeliveryAvailable") ~= false then owned = true; break end
				end
			end
		end
		if not owned then return false end
		local owner = enter("JewelryDialogue", token .. "|" .. npc .. "|" .. tostring(progress.IncidentPhase) .. "|" .. accept, state)
		local now = ctx.now()
		if owner.answerAt and now - owner.answerAt < 1 then say("Jewelry: waiting for the dialogue result"); return true end
		if ctx.tap(48 + choices[accept]) then owner.answerAt = now end
		say("Jewelry: " .. (progress.IncidentPhase == "report" and "reporting the necklace and evidence" or "starting " .. npc .. "'s native task"))
		return true
	end
	local function darbyRules(state, cached, scenes)
		local progress = state.progress
		if state.dialogue ~= true or state.inputLock ~= true or type(progress) ~= "table" or progress.ReadyToClaim == true
			or not integer(state.leader, 1, 9007199254740991) or type(ctx.position) ~= "function" then return false end
		local choices, count = dialogueChoices(cached.gui, "D'Arby")
		if not choices or not choices["not now"] then return false end
		local number = choices["just deal"] or choices["deal"]
		if not number or not (count == 2 and choices["deal"] or count == 3 and choices["just deal"]
			and (choices["go on"] or choices["go over the rules"])) then return false end
		local root = ctx.getRoot()
		local position = root and root.Position
		if not position or not finite(position.X) or not finite(position.Y) or not finite(position.Z) then return false end
		local actor
		local nativeRules = progress.IncidentNPC == nil or progress.IncidentNPC == ""
		if nativeRules then
			actor = child(child(ctx.world, "NPCs"), "Darby")
			local root = child(actor, "HumanoidRootPart")
			if state.leader ~= player.UserId or not actor or not root then return false end
			local native, kinds = storageSnapshot()
			if not typed(native, kinds, "Npc", "Instance") or native.Npc ~= actor.Address
				or not typed(native, kinds, "Root", "Instance") or native.Root ~= root.Address or native.Phase ~= "Fish" or native.PvP == true
				or not typed(native, kinds, "State", "table") then return false end
			local data, dataKinds = nativeMap(native.State)
			local wager = typed(data, dataKinds, "Wager", "table") and nativeMap(data.Wager)
			if not wager or wager.Bounty ~= true then return false end
		elseif type(progress.IncidentNPC) ~= "string" then return false end
		for _, scene in ipairs(scenes or {}) do
			local id = ctx.attr(scene, "BountyId") or ctx.attr(scene, "Bounty")
			if scene.Parent and id ~= nil and tostring(id) == state.active and tonumber(ctx.attr(scene, "BountyLeaderId")) == state.leader then
				local pending, cursor = { {scene, 0} }, 1
				while cursor <= #pending and cursor <= 64 do
					local object, depth = pending[cursor][1], pending[cursor][2]
					if object.Parent and (depth == 0 or object:IsDescendantOf(scene)) then
						if object.ClassName == "Model" and object.Name == progress.IncidentNPC and child(object, "HumanoidRootPart") then actor = object; break end
						if depth < 4 then
							for _, nested in ipairs(object:GetChildren()) do
								if #pending >= 64 then break end
								pending[#pending + 1] = {nested, depth + 1}
							end
						end
					end
					cursor += 1
				end
				actor = actor or child(child(ctx.world, "NPCs"), progress.IncidentNPC)
				if actor then break end
			end
		end
		local point = actor and child(actor, "HumanoidRootPart") and ctx.position(actor)
		if not point or not finite(point.X) or not finite(point.Y) or not finite(point.Z) or (position - point).Magnitude > 8 then return false end
		local marker = state.targetMarker or state.marker
		if nativeRules and (not marker or not finite(marker.X) or not finite(marker.Y) or not finite(marker.Z) or (marker - point).Magnitude > 8) then return false end
		local id, leader = ctx.attr(actor, "BountyId") or ctx.attr(actor, "Bounty"), ctx.attr(actor, "BountyLeaderId")
		if id ~= nil and tostring(id) ~= state.active or leader ~= nil and tonumber(leader) ~= state.leader then return false end
		local owner = enter("GoFishRules", tostring(actor.Address or actor:GetFullName()) .. "|" .. tostring(number), state)
		local now = ctx.now()
		if owner.answerAt and now - owner.answerAt < 1 then say("Go Fish: waiting for the native deal"); return true end
		if ctx.tap(48 + number) then owner.answerAt = now end
		say("Go Fish: accepting D'Arby's native deal")
		return true
	end
	local function jewelry(state)
		local ownerKey = ctx.attr(game.Workspace.Camera, "JewelryInspectionOwner")
		local token = currentToken(state)
		local cameraOwned = type(ownerKey) == "string" and ownerKey ~= ""
		local owner = enter("Jewelry", tostring(cameraOwned and ownerKey or token or state.active), state)
		if not cameraOwned and (state.jewelry ~= true or type(token) ~= "string" or token == "") then say("Jewelry: waiting for camera authority"); return true end
		local function accepts(map, kinds)
			if not typed(map, kinds, "id", "string") or map.id ~= state.active or map.finished == true
				or not typed(map, kinds, "token", "string") or map.token == "" or cameraOwned and map.token ~= ownerKey
				or not typed(map, kinds, "payload", "table") or not typed(map, kinds, "rows", "table") then return false end
			local payload, payloadKinds = readMap(map.payload, 32)
			return typed(payload, payloadKinds, "Token", "string") and (token == nil or payload.Token == token)
				and typed(payload, payloadKinds, "Version", "number") and integer(payload.Version, 0, 100000)
		end
		local native, nativeKinds
		if type(scanFunctions) == "function" then
			if ctx.now() - owner.born < 0.4 then say("Jewelry: waiting for the native puzzle session"); return true end
			local pointer
			native, nativeKinds, pointer = jewelrySnapshot()
			if not native then say("Jewelry: waiting for the native puzzle session"); return true end
			if owner.pointer ~= pointer then owner.pointer, owner.request = pointer, nil end
		else
			local anchor = cameraOwned and "token" or "id"
			local function acceptsRow(row) return row.key == anchor and stringValue(row.value) == (cameraOwned and ownerKey or state.active) end
			if not acquire(owner, anchor, { token = "string", id = "string", payload = "table", rows = "table" }, accepts, 128, acceptsRow, not cameraOwned) then
				say("Jewelry: waiting for the native puzzle session"); return true
			end
			native, nativeKinds = readMap(owner.pointer, 128)
		end
		if not accepts(native, nativeKinds) then say("Jewelry: waiting for matching puzzle authority"); return true end
		local payload, kinds = readMap(native.payload, 32)
		if native.pending == true then say("Jewelry: waiting for the current placement"); return true end
		if owner.request then
			local request, now = owner.request, ctx.now()
			if payload.Version < request.version or payload.Version == request.version and native.payload == request.payload then
				if now - (request.keepaliveAt or request.at) >= 2
					and send("InspectKeepalive", { Id = native.id, Token = payload.Token }) then request.keepaliveAt = now end
				say("Jewelry: waiting for the placement acknowledgment"); return true
			end
			local placed = request.component and typed(payload, kinds, "Placed", "table") and readMap(payload.Placed, 8)
			local values = request.row and typed(payload, kinds, "Values", "table") and readMap(payload.Values, 4)
			local accepted = placed and placed[request.component] == true or values and values[request.row] == request.notch
				or request.action == "TakeEvidence" and payload.Stage ~= "Evidence"
			if not accepted and now - request.at < 2 then
				say("Jewelry: waiting before retrying the placement"); return true
			end
			owner.request = nil
		end
		local packet = { Id = native.id, Token = payload.Token, Version = payload.Version }
		local action
		if payload.Stage == "Evidence" then action = "TakeEvidence"
		elseif payload.Kind == "Assembly" or payload.Index == 4 then
			if not typed(payload, kinds, "Placed", "table") then say("Jewelry: waiting for fitted components"); return true end
			local placed = readMap(payload.Placed, 8)
			if not placed then return true end
			for _, component in ipairs(components) do
				if placed[component] ~= true then packet.Component, action = component, "FitComponent"; break end
			end
		else
			if not typed(payload, kinds, "Target", "table") or not typed(payload, kinds, "Values", "table") then
				say("Jewelry: waiting for the engraved clasp targets"); return true
			end
			local target, targetKinds = readMap(payload.Target, 4)
			local values, valueKinds = readMap(payload.Values, 4)
			for row = 1, 3 do
				if not typed(target, targetKinds, row, "number") or not typed(values, valueKinds, row, "number")
					or not integer(target[row], 1, 4) or not integer(values[row], 1, 4) then
					say("Jewelry: waiting for all three clasp positions"); return true
				end
			end
			for row = 1, 3 do
				if values[row] ~= target[row] then packet.Row, packet.Notch, action = row, target[row], "PlaceClasp"; break end
			end
		end
		if action and send(action, packet) then
			owner.request = { version = payload.Version, payload = native.payload, at = ctx.now(), action = action,
				component = packet.Component, row = packet.Row, notch = packet.Notch }
			say(action == "TakeEvidence" and "Jewelry: taking the restored evidence" or "Jewelry: fitting " .. tostring(packet.Component or ("clasp " .. packet.Row)))
		else say("Jewelry: waiting for the puzzle stage to advance") end
		return true
	end
	local function drawing(state, gui, token)
		local owner = enter("Rohan", token, state)
		if drawingToken ~= token then drawingToken, drawingMemory = token, { completed = 0 } end
		local memory = drawingMemory
		local panel = child(child(child(gui, "HeavensDoorBook"), "Root"), "DrawingContest")
		owner.clock = child(panel, "Clock")
		local function accepts(map, kinds)
			return typed(map, kinds, "Id", "string") and map.Id == state.active
				and typed(map, kinds, "Token", "string") and map.Token == token
				and typed(map, kinds, "Strokes", "table") and typed(map, kinds, "Ink", "table")
		end
		if not acquire(owner, "Strokes", { Id = "string", Strokes = "table", Ink = "table", Connections = "table" }, accepts, 64) then
			say("Rohan: waiting for the native drawing session"); return true
		end
		local native, kinds = readMap(owner.pointer, 64)
		if not accepts(native, kinds) then say("Rohan: waiting for matching contest authority"); return true end
		if currentToken(state) ~= nil and currentToken(state) ~= token then say("Rohan: waiting for the bounty token"); return true end
		if not memory.reference then
			memory.reference = drawingReference(native.Strokes)
			if not memory.reference then say("Rohan: waiting for the native reference strokes"); return true end
			memory.referencePointer = native.Strokes
		end
		if memory.referencePointer ~= native.Strokes then say("Rohan: waiting for the matching reference"); return true end
		local reference = memory.reference
		local clock = owner.clock and tostring(owner.clock.Text or "") or ""
		local seconds = tonumber(clock:match("^(%d+%.?%d*)s$"))
		if not typed(native, kinds, "Start", "number") or not seconds or seconds <= 0 then
			say("Rohan: waiting for the drawing countdown"); return true
		end
		if memory.submitted or native.Submitting == true or native.SubmitQueued == true then say("Rohan: waiting for the drawing result"); return true end
		if memory.request then
			if native.Index == memory.request.index then
				if native.Pending == true or ctx.now() - memory.request.at < 2 then
					say("Rohan: waiting for stroke " .. (memory.completed + 1) .. " acknowledgment"); return true
				end
			elseif not integer(native.Index, 1, 65) or memory.request.index ~= nil and native.Index ~= memory.request.index + 1 then
				say("Rohan: waiting for the next native stroke index"); return true
			else
				memory.completed += 1
			end
			memory.request = nil
		end
		if native.Pending == true then say("Rohan: waiting for the current native stroke"); return true end
		if native.Index ~= nil and not integer(native.Index, 1, 65) then say("Rohan: waiting for a valid stroke index"); return true end
		if memory.completed == 0 and native.Index ~= nil and native.Index ~= 1 then say("Rohan: waiting for a fresh contest before drawing"); return true end
		local packet = { Id = native.Id, Token = native.Token }
		if memory.completed == #reference then
			if send("DrawingSubmit", packet) then memory.submitted = true; say("Rohan: submitting the completed drawing") end
		else
			packet.Index, packet.Points = native.Index, sampleStroke(reference[memory.completed + 1], 128)
			if send("DrawingStroke", packet) then
				memory.request = { index = native.Index, at = ctx.now() }
				say("Rohan: drawing stroke " .. (memory.completed + 1) .. " / " .. #reference)
			end
		end
		return true
	end
	local function armState(owner)
		local readStarted = ctx.now()
		owner.resting, owner.checkedAt = false, nil
		local function accepts(map, kinds)
			return typed(map, kinds, "Id", "string") and map.Id == owner.key
				and typed(map, kinds, "Side", "number") and integer(map.Side, 1, 2)
				and typed(map, kinds, "Connections", "table") and map.Variant ~= "Lockpick" and map.Variant ~= "Breath"
		end
		local native, kinds
		if type(scanFunctions) == "function" or type(getgc) == "function" then
			local pointer
			native, kinds, pointer = armSnapshot()
			if owner.pointer ~= pointer then
				if owner.ownedPress then ctx.release(1) end
				owner.pointer, owner.round, owner.lastAngle, owner.lastAt, owner.pressed, owner.moving, owner.ownedPress = pointer, nil, nil, nil, false, false, false
			end
			if not native then owner.round = nil; return nil, "Paco: waiting for the native arm-wrestling session" end
		else
			if not acquire(owner, "Side", {Side = "number", Connections = "table", Id = "string"}, accepts, 64) then
				owner.round = nil; return nil, "Paco: waiting for the native arm-wrestling session"
			end
			native, kinds = readMap(owner.pointer, 64)
		end
		if not accepts(native, kinds) or native.Ended == true then owner.round = nil; return nil, "Paco: waiting for the match result" end
		owner.checkedAt = readStarted
		if not typed(native, kinds, "Round", "number") or not integer(native.Round, 1, 40)
			or not typed(native, kinds, "Target", "number") or native.Target < 0 or native.Target > 360
			or not typed(native, kinds, "Duration", "number") or native.Duration < 0.1 or native.Duration > 10 then
			owner.round = nil
			owner.resting = native.Round == nil and typed(native, kinds, "ReadyAt", "number") and finite(native.ReadyAt)
			return nil, "Paco: waiting for the round countdown"
		end
		if owner.round ~= native.Round then
			owner.round, owner.lastAngle, owner.lastAt, owner.pressed, owner.moving = native.Round, nil, nil, false, false
		end
		owner.target, owner.nativePressed, owner.checkedAt = native.Target, native.Pressed == true, readStarted
		return native, "Paco: timing round " .. native.Round
	end
	local function armWrestling(state, gui)
		local owner = enter("Paco", tostring(state.armSession), state)
		local panel = child(child(gui, "ArmWrestling"), "Panel")
		owner.track = child(panel, "Track")
		owner.cursor = child(owner.track, "Cursor")
		local _, _, character = ctx.getRoot()
		owner.character = character
		local _, status = armState(owner)
		say(status)
		return true
	end
	local function verity(state, cached, scenes)
		if state.targetMarker then
			local root = ctx.getRoot()
			if not root or (root.Position - state.targetMarker).Magnitude > 8 then return false end
		end
		local phase = type(state.progress) == "table" and state.progress.IncidentPhase
		local confirmedBox = phase == "box" or phase == "helper" or phase == "question"
		local owned = state.verityBox == true
		for _, scene in ipairs(scenes or {}) do
			if scene.Name == "Incident_Verity" then
				local id, leader = ctx.attr(scene, "BountyId") or ctx.attr(scene, "Bounty"), ctx.attr(scene, "BountyLeaderId")
				if (id == nil or tostring(id) == state.active) and (leader == nil or tonumber(leader) == state.leader) then owned = true end
			end
		end
		local authenticatedBox = confirmedBox and type(currentToken(state)) == "string" and currentToken(state) ~= ""
		if not owned and not authenticatedBox then return false end
		local buttons = { child(cached.choices, "Choice1"), child(cached.choices, "Choice2") }
		local title = child(cached.choices, "Title")
		local heading = tostring(title and title.Text or ""):lower()
		if heading ~= "ask berity" and heading ~= "your personal helper friend" and heading ~= "hubert's missing package" then return false end
		for index = 1, 2 do
			local size = buttons[index] and buttons[index].AbsoluteSize
			if not size or size.X <= 10 or size.Y <= 10 then
				if not (authenticatedBox and (not size or (size.X == 0 and size.Y == 0))) then return false end
			end
		end
		local selected = investigativeChoice(buttons)
		if not selected then say("Berity: waiting for the missing-package question"); return confirmedBox end
		local token = currentToken(state)
		local owner = enter("Verity", tostring(token or state.active) .. "|" .. choiceText(buttons[1]) .. "|" .. choiceText(buttons[2]), state)
		local function choicesFor(map, kinds)
			if not typed(map, kinds, "Id", "string") or map.Id ~= state.active
				or not typed(map, kinds, "Token", "string") or map.Token == "" or (token ~= nil and map.Token ~= token)
				or not typed(map, kinds, "Choices", "table") then return nil end
			local choices, choiceKinds = readMap(map.Choices, 4)
			local packets = {}
			for index = 1, 2 do
				if not typed(choices, choiceKinds, index, "table") then return nil end
				local choice, entryKinds = readMap(choices[index], 4)
				if not typed(choice, entryKinds, "Text", "string")
					or (not typed(choice, entryKinds, "Id", "string") and not typed(choice, entryKinds, "Id", "number"))
					or choice.Id == "" or (type(choice.Id) == "number" and not integer(choice.Id, 1, 128)) then return nil end
				local caption = choice.Text:lower():gsub("[%.%!%?]+$", "")
				if caption ~= choiceText(buttons[index]) then return nil end
				packets[index] = choice
			end
			if choices[3] ~= nil or packets[1].Id == packets[2].Id then return nil end
			return packets
		end
		local map, kinds
		if type(scanFunctions) == "function" then
			if ctx.now() - owner.born < 0.4 then return false end
			local pointer
			map, kinds, pointer = veritySnapshot(cached.choices)
			if not map then
				owner.pointer, owner.answered = nil, nil
				say("Berity: waiting for the native question session"); return false
			end
			if owner.pointer ~= pointer then owner.pointer, owner.answered = pointer, nil end
		else
			local function accepts(map, kinds) return choicesFor(map, kinds) ~= nil end
			if not acquire(owner, "Choices", { Id = "string", Token = "string", Choices = "table" }, accepts, 64) then
				say("Berity: waiting for the native question session"); return false
			end
			map, kinds = readMap(owner.pointer, 64)
		end
		local choices = choicesFor(map, kinds)
		if not choices then say("Berity: waiting for matching question authority"); return confirmedBox end
		if owner.answered and ctx.now() - owner.answered < 1 then say("Berity: waiting for the answer"); return true end
		local point, size = buttons[selected].AbsolutePosition, buttons[selected].AbsoluteSize
		if not point or not finite(point.X) or not finite(point.Y) then say("Berity: waiting for the native answer button"); return true end
		local viewport = game.Workspace.Camera.ViewportSize
		local x = size and size.X > 1 and point.X + size.X / 2 or viewport.X / 2
		local y = point.Y + (size and size.Y > 1 and size.Y / 2 or 24)
		if ctx.mouseMove(x, y, nil, true) and ctx.tap(1) then
			owner.answered = ctx.now()
			say("Berity: asking about Hubert's missing package")
		end
		return true
	end
	function controller.TabletopState(owner, state)
		local index = type(state.active) == "string" and tonumber(state.active:match("^%d+%-(%d+)"))
		if index ~= 14 or state.claim or not owner or type(owner.owner) ~= "string" or owner.owner == ""
			or ctx.attr(player, "TabletopInputOwner") ~= owner.owner then return nil end
		owner.born = owner.born or ctx.now()
		local function accepts(map, kinds)
			return typed(map, kinds, "Token", "string") and map.Token == owner.owner and map.Action == "Tabletop_" .. owner.owner
				and typed(map, kinds, "State", "table") and typed(map, kinds, "Steps", "table")
				and typed(map, kinds, "Props", "table") and typed(map, kinds, "Connections", "table")
		end
		local map, kinds
		if type(scanFunctions) == "function" then
			map, kinds = tabletopSnapshot()
		else
			if not acquire(owner, "Token", { Token = "string", State = "table", Steps = "table", Props = "table", Connections = "table" }, accepts, 128, nil, true) then return nil end
			map, kinds = readMap(owner.pointer, 128)
		end
		if not accepts(map, kinds) then return nil end
		local progress, progressKinds = readMap(map.State, 32)
		if not typed(progress, progressKinds, "Index", "number") or not integer(progress.Count, 1, 64)
			or not integer(progress.Index, 1, progress.Count + 1) or (progress.Done ~= nil and progressKinds.Done ~= "boolean") then return nil end
		local result = { Index = progress.Index, Done = progress.Done == true, Ending = map.Ending == true }
		if result.Done or result.Ending then return result end
		local steps, stepKinds = readMap(map.Steps, 64)
		if not typed(steps, stepKinds, progress.Index, "table") then return nil end
		local step = readMap(steps[progress.Index], 32)
		if not step or (step.Kind ~= "Drag" and step.Kind ~= "Click" and step.Kind ~= "Hold" and step.Kind ~= "Wait") then return nil end
		result.Kind = step.Kind
		return result
	end
	function controller.KaraokeSubmitted(owner, state)
		local index = type(state.active) == "string" and tonumber(state.active:match("^%d+%-(%d+)"))
		if index ~= 12 or state.claim or not owner or type(owner.session) ~= "string" or owner.session == ""
			or ctx.attr(player, "KaraokeInputLocked") ~= owner.session then return nil end
		owner.born = owner.born or ctx.now()
		local function accepts(map, kinds)
			return typed(map, kinds, "Id", "string") and map.Id == owner.session
				and typed(map, kinds, "Connections", "table") and typed(map, kinds, "Cleanups", "table")
				and map.Config == nil and (map.Submitted == nil or kinds.Submitted == "boolean")
		end
		if not acquire(owner, "Id", { Id = "string", Connections = "table", Cleanups = "table" }, accepts, 64, nil, true) then return nil end
		local map, kinds = readMap(owner.pointer, 64)
		return accepts(map, kinds) and map.Submitted == true or nil
	end
	function controller.Step(state, cached, scenes)
		if not state.active or state.claim or type(state.progress) == "table" and state.progress.ReadyToClaim == true then clear(); return false end
		local _, index = tostring(state.active):match("^(%d+)%-(%d+)")
		index = tonumber(index)
		if index == 6 then
			if jewelryDialogue(state, cached, scenes) then return true end
			if state.jewelry then return jewelry(state) end
		end
		if index == 13 and darbyRules(state, cached, scenes) then return true end
		if index == 10 then
			if state.armSession then return armWrestling(state, cached.gui) end
			if not armModule and state.leader == player.UserId and type(state.progress) == "table" and state.progress.IncidentPhase == "table"
				and (type(scanFunctions) == "function" or type(getgc) == "function") then armSnapshot() end
		end
		local token = ctx.attr(player, "RohanDrawingToken")
		if index == 11 and type(token) == "string" and token ~= "" then return drawing(state, cached.gui, token) end
		if index == 8 and (state.verityBox == true or (type(state.progress) == "table" and (state.progress.IncidentPhase == "box" or state.progress.IncidentPhase == "helper" or state.progress.IncidentPhase == "question"))) then
			local handled = verity(state, cached, scenes)
			if handled then return true end
			if session and session.kind == "Verity" then return false end
		end
		clear()
		return false
	end
	function controller.Render()
		local owner = session
		if not owner or owner.kind ~= "Paco" then return end
		local character = owner.character
		if not character or tostring(ctx.attr(character, "ArmWrestlingSession")) ~= owner.key then clear(); return end
		if not owner.checkedAt or ctx.now() - owner.checkedAt > 0.1 or owner.pressed or owner.nativePressed
			or not owner.round and not owner.resting then return end
		owner.geometry = owner.geometry or {}
		owner.geometry.resting = owner.resting
		local angle, reset = cursorAngle(owner.track, owner.cursor, owner.geometry)
		if reset then owner.lastAngle, owner.lastAt, owner.moving = nil, nil, false end
		if angle == nil then return end
		if not owner.round then return end
		local point, size = owner.track.AbsolutePosition, owner.track.AbsoluteSize
		local width = size and size.X > 10 and size.X or owner.geometry.width
		local height = size and size.Y > 10 and size.Y or owner.geometry.height
		local pointerReady = point and width and height and ctx.mouseMove(point.X + width / 2, point.Y + height / 2, "Paco", true)
		local now = ctx.now()
		local previous, elapsed = owner.lastAngle, owner.lastAt and now - owner.lastAt or 0
		local delta = previous and (angle - previous) % 360
		local forward = delta and delta > 0 and delta <= 45
		if forward then owner.moving = true end
		local current, target = forward and previous + delta or angle, owner.target
		if forward and target < previous and current >= 360 then target += 360 end
		local crossed = forward and previous <= target and current >= target
		local approaching = false
		if forward and elapsed > 0 and elapsed < 0.1 then
			approaching = current <= target and current + delta * 0.5 >= target
		end
		local gap = math.abs(angle - owner.target)
		if pointerReady and owner.moving and (crossed or approaching or math.min(gap, 360 - gap) <= 1) then
			if ctx.tap(1) then owner.pressed, owner.ownedPress = true, true end
		end
		owner.lastAngle, owner.lastAt = angle, now
	end
	function controller.Stop()
		clear()
	end
	function controller.SelfTest()
		local stroke = { Vector2.new(0.1, 0.2), Vector2.new(0.1, 0.8), Vector2.new(0.6, 0.8) }
		local points = sampleStroke(stroke, 128)
		assert(#points == 128 and math.abs(points[1].X - stroke[1].X) < 0.000001)
		assert(math.abs(points[128].Y - stroke[#stroke].Y) < 0.000001)
		for _, point in ipairs(points) do assert(point.X >= 0 and point.X <= 1 and point.Y >= 0 and point.Y <= 1) end
		return true, 18
	end
	return controller
end

_G.StandOutParts = _G.StandOutParts or {}

local bountyOrder = { 1, 5, 2, 6, 3, 7, 8, 9, 10, 11, 12, 13, 14 }
local bountyNames = {
	[1] = "Three Wishes", [2] = "Dispose of the Vampires", [3] = "Save Chubby Baby",
	[5] = "Small Change, Big Problem", [6] = "Cheap Jewelry, Expensive Problem", [7] = "Trust Me on This One",
	[8] = "Your Personal Helper Friend", [9] = "MISSING FROG", [10] = "PACO'S CHALLENGE",
	[11] = "ROHAN'S DRAWING CONTEST", [12] = "USAGI'S KARAOKE NIGHT",
	[13] = "Beat D'Arby at Go Fish", [14] = "ICED TEA RUN",
}
_G.StandOutParts.BountyNames = bountyNames
local families = {
	[5] = "Harvest", [6] = "Jewelry", [7] = "HeyYa", [8] = "Verity", [9] = "Frog", [10] = "Paco",
	[11] = "Rohan", [12] = "Usagi", [13] = "GoFish", [14] = "IcedTea",
}
local keyNames = {
	SPACE = 32, SPACEBAR = 32, RETURN = 13, ENTER = 13, TAB = 9,
	SHIFT = 16, CTRL = 17, CONTROL = 17, ALT = 18, BACKSPACE = 8,
	UP = 38, DOWN = 40, LEFT = 37, RIGHT = 39,
}
local karaokeBinds = { X = "KaraokeBlue", A = "KaraokeGreen", Y = "KaraokeYellow", B = "KaraokeRed" }
local karaokeDefaults = { X = "Q", A = "W", Y = "E", B = "R" }
local incidentDialogs = {
	[10] = { npc = "paco", scene = "Incident_Paco", answer = "youreon", decline = "notyet" },
	[11] = { npc = "rohan", scene = "Incident_Rohan", answer = "letsdraw", decline = "notyet" },
	[12] = { npc = "usagi", scene = "Incident_Usagi", answer = "letsgo" },
}

local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function parseId(id)
	if type(id) ~= "string" then
		return nil
	end
	local rotation, index, tier = id:match("^(%d+)%-(%d+)%-(%d+)$")
	if not rotation then
		rotation, index = id:match("^(%d+)%-(%d+)$")
		tier = "1"
	end
	rotation, index, tier = tonumber(rotation), tonumber(index), tonumber(tier)
	if
		not finite(rotation)
		or not finite(index)
		or not finite(tier)
		or rotation < 0
		or index < 1
		or index > 14
		or tier < 1
	then
		return nil
	end
	return rotation, index, tier
end

local function available(rotation)
	local result = {}
	for offset = 0, 6 do
		result[#result + 1] = bountyOrder[(rotation * 3 + offset) % #bountyOrder + 1]
	end
	return result
end

local function activeId(data)
	if type(data) ~= "table" then
		return nil, false
	end
	local count = 0
	for slot, id in pairs(data) do
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or not parseId(id) then
			return nil, false
		end
		count += 1
	end
	return data[1], count == #data
end

local function ownerMatches(id, leader, active, partyLeader)
	return id ~= nil and id == active and leader == partyLeader
end

local function completionMap(data, earned)
	if type(data) ~= "table" then
		return nil
	end
	local result = {}
	local function merge(source)
		if type(source) ~= "table" then
			return false
		end
		for key, value in pairs(source) do
			local index = type(key) == "string" and tonumber(key:match("^(%d+):?%d*$"))
			if index and index >= 1 and index <= 14 then
				if not finite(value) or value < 0 or value % 1 ~= 0 then
					return false
				end
				result[index] = math.max(result[index] or -1, value)
			end
		end
		return true
	end
	if not merge(data) or (earned and not merge(data.Earned or {})) then
		return nil
	end
	return result
end

local function validVector(v)
	return v ~= nil
		and finite(v.X)
		and finite(v.Y)
		and finite(v.Z)
		and math.abs(v.X) < 100000
		and math.abs(v.Y) < 100000
		and math.abs(v.Z) < 100000
end

local function normalized(s)
	return tostring(s or ""):lower():gsub("[^%w]", "")
end
local function canonicalNPC(s)
	local name = normalized(s)
	return name == "rohankishibe" and "rohan" or name == "pacochallenge" and "paco"
		or name == "usagikaraoke" and "usagi" or name
end
local function jewelryNPC(progress, id)
	local _, index = parseId(id)
	if index ~= 6 or type(progress) ~= "table" or progress.IncidentScenario ~= "Jewelry" or progress.ReadyToClaim == true
		or type(progress.IncidentToken) ~= "string" or progress.IncidentToken == "" then return nil end
	local npc, phase = progress.IncidentNPC, progress.IncidentPhase
	return (npc == "Meryl Mei Qi" and (phase == "meryl" or phase == "report") or npc == "Dragona" and phase == "dragona") and npc or nil
end
local function karaokeGoal(progress, objective, id)
	local _, index = parseId(id)
	if index ~= 12 then return false end
	local phase = type(progress) == "table" and progress.IncidentPhase
	local instruction = type(progress) == "table" and progress.IncidentObjective or objective
	return phase == "booth" or phase == "karaoke" or (type(instruction) == "string"
		and instruction:lower():match("^sing .- with usagi") ~= nil)
end
local function karaokeSong(progress, objective, id)
	if not karaokeGoal(progress, objective, id) then return nil end
	local instruction = type(progress) == "table" and progress.IncidentObjective or objective
	return type(instruction) == "string" and instruction:match("^[Ss]ing (.-) [Ww]ith [Uu]sagi") or nil
end
local function talkTarget(progress, objective, id)
	local _, index = parseId(id)
	if index == 13 then return "darby" end
	if index == 10 and type(progress) == "table" and progress.IncidentPhase == "hospital" then return "hospitalnurse" end
	local jewelry = jewelryNPC(progress, id)
	if jewelry then return canonicalNPC(jewelry) end
	local instruction = type(progress) == "table" and progress.IncidentObjective or objective
	local target = type(instruction) == "string" and instruction:match("[Tt]alk%s+to%s+(.+)")
	if target then
		return canonicalNPC(target:gsub("%s+%d+%s*/%s*%d+.*$", ""))
	end
	local namedFamily = index == 10 and "Paco" or index == 11 and "Rohan" or index == 12 and "Usagi"
	local scenario = type(progress) == "table" and progress.IncidentScenario
	if type(scenario) == "string" and namedFamily and normalized(scenario) == normalized(namedFamily) then
		return normalized(scenario)
	end
	return namedFamily and normalized(namedFamily) or nil
end
local function markerVector(value)
	local kind, x, y, z = type(value)
	if kind == "table" then
		x, y, z = value.x or value.X or value[1], value.y or value.Y or value[2], value.z or value.Z or value[3]
	elseif kind == "string" then
		x, y, z = value:match("^%s*([%-%.%d]+)%s*[,%s]+%s*([%-%.%d]+)%s*[,%s]+%s*([%-%.%d]+)%s*$")
	elseif kind == "userdata" or kind == "vector" then
		return validVector(value) and value or nil
	else
		return nil
	end
	x, y, z = tonumber(x), tonumber(y), tonumber(z)
	if not finite(x) or not finite(y) or not finite(z) then
		return nil
	end
	local point = Vector3.new(x, y, z)
	return validVector(point) and point or nil
end

local function progressTarget(progress)
	if type(progress) ~= "table" then return nil end
	local marker, path, name
	for _, key in ipairs({ "TargetPos", "TargetPosition", "WorldPos", "WorldPosition", "ObjectivePos", "ObjectivePosition", "WaypointPos", "Waypoint", "MarkerPos", "Position", "Pos" }) do
		marker = markerVector(progress[key])
		if marker then break end
	end
	for _, key in ipairs({ "TargetPath", "ObjectivePath", "WaypointPath" }) do
		if type(progress[key]) == "string" and progress[key] ~= "" then path = progress[key]; break end
	end
	for _, key in ipairs({ "TargetName", "ObjectiveName", "WaypointName", "Target", "Objective", "Location" }) do
		if type(progress[key]) == "string" and progress[key] ~= "" then name = progress[key]; break end
	end
	return marker, path, name
end

local function keyCode(text)
	local name = tostring(text or ""):gsub("<[^>]*>", ""):upper():gsub("%s+", "")
	if #name == 1 then
		local code = string.byte(name)
		if code >= 48 and code <= 90 then
			return code
		end
	end
	return keyNames[name]
end

local function drainKeys(keys)
	local result = {}
	for key in pairs(keys) do
		result[#result + 1] = key
		keys[key] = nil
	end
	return result
end

_G.StandOutParts.Bounties = function(ctx)
	local module = {
		Capabilities = {
			Classic = { Supported = true, Detail = "Owned combat, delivery, defense and marked interactions" },
			Harvest = { Supported = true, Detail = "Catch available owned Harvest prompts, then recover the stash" },
			HeyYa = { Supported = true, Detail = "Can and bell prompts; release movement and hold at HeySpot" },
			Frog = { Supported = true, Detail = "Find and collect the owned marked frog" },
			Verity = {
				Supported = "partial",
				Detail = "Package, follow, chase and combat; dialogue choices need readable selection",
			},
			Jewelry = {
				Supported = "partial",
				Detail = "Prompts and evidence; necklace fitting needs readable puzzle targets",
			},
			Paco = {
				Supported = "partial",
				Detail = "Prompts and combat; timed arm wrestling needs readable round target",
			},
			Rohan = { Supported = "partial", Detail = "Prompts; drawing needs readable stroke targets" },
			Usagi = { Supported = true, Detail = "Native rhythm input and held notes from visible lane geometry" },
			GoFish = { Supported = true, Detail = "Legal ask, draw and give actions from native instructions" },
			IcedTea = {
				Supported = true,
				Detail = "Native named-prop drag, band pour, wait and drink; requires visible scene geometry",
			},
		},
	}
	local player, world = ctx.player, ctx.world
	local status, busy, executing = "Idle", false, false
	local state = {
		lastSense = -math.huge, lastWorld = -math.huge, nextAction = 0,
		menuStage = nil, menuUntil = 0, active = nil, rotation = nil,
		completed = {}, blockedUntil = 0,
	}
	local inputs, karaoke, tea, prompts, fighters, scenes = {}, nil, nil, {}, {}, {}
	local cached, lookup = {}, {}
	local lastObserved = ""
	local incidents = _G.StandOutParts.Incidents and _G.StandOutParts.Incidents(ctx)
	if incidents then
		for _, family in ipairs({ "Jewelry", "Paco", "Rohan", "Verity" }) do module.Capabilities[family].Supported = true end
		module.Capabilities.Jewelry.Detail = "Owned clasp placement, component fitting and confirmed evidence"
		module.Capabilities.Paco.Detail = "Owned challenge dialogue and native arm-wrestling rounds"
		module.Capabilities.Rohan.Detail = "Owned drawing challenge and acknowledged native strokes"
		module.Capabilities.Verity.Detail = "Owned package, follow, chase, combat and authenticated native choices"
	end

	local function child(parent, name, recursive)
		if not parent then return nil end
		local direct = parent:FindFirstChild(name)
		if direct or not recursive then return direct end
		local address, now = parent.Address, ctx.now()
		lookup[address] = lookup[address] or {}
		local entry = lookup[address][name]
		if entry and now < entry.untilAt and (not entry.object or entry.object.Parent) then return entry.object end
		local found
		for _, object in ipairs(parent:GetDescendants()) do if object.Name == name then found = object; break end end
		lookup[address][name] = {object = found, untilAt = now + (found and 5 or 0.2)}
		return found
	end

	local function textOf(object)
		if not object then return "" end
		local text = object.Text
		if type(text) ~= "string" then
			local label = child(object, "TextLabel", true) or child(object, "Label", true)
			text = label and label.Text
		end
		return type(text) == "string" and text ~= "failed to fetch text" and text or ""
	end

	local function label(parent, name)
		local object = child(parent, name, true)
		return textOf(object)
	end

	local function karaokeBinding(symbol)
		local name, fallback = karaokeBinds[symbol], karaokeDefaults[symbol]
		return name and ctx.bind(name, fallback) or nil
	end

	local function karaokeButton(panel, song)
		if not panel or not song or song == "" then return nil end
		local wanted, selected = normalized(song), nil
		for _, object in ipairs(panel:GetDescendants()) do
			if (object.ClassName == "TextButton" or object.ClassName == "ImageButton") and object.Name:match("^Song%d+$")
				and normalized(label(object, "Title")) == wanted then
				if selected then return nil end
				selected = object
			end
		end
		return selected
	end

	local function say(message, family)
		status = message
		ctx.setStatus("Bounties", message)
		if family and module.Capabilities[family] then
			module.Capabilities[family].Reason = message
		end
	end

	local function releaseKeys()
		for _, key in ipairs(drainKeys(inputs)) do
			ctx.release(key)
		end
		if tea and tea.mouseDown then
			mouse1release()
			tea.mouseDown = false
		end
	end

	local function hold(key)
		if ctx.hold(key) == false then return false end
		inputs[key] = true
		return true
	end

	local function release(key)
		inputs[key] = nil
		ctx.release(key)
	end

	local function partOf(object)
		if not object then
			return nil
		end
		local class = object.ClassName
		if class == "Part" or class == "MeshPart" or class == "UnionOperation" or class == "Seat" then
			return object
		end
		local part = child(object, "HumanoidRootPart") or child(object, "CharacterPart")
		if part then return part end
		local primary = object.PrimaryPart
		local primaryClass = primary and primary.ClassName
		if primaryClass ~= "Part" and primaryClass ~= "MeshPart" and primaryClass ~= "UnionOperation" and primaryClass ~= "Seat" then primary = nil end
		return primary
			or child(object, "Hitbox") or child(object, "PromptPart") or child(object, "Head") or child(object, "Primary")
	end

	local function promptPart(object)
		local current = object
		for _ = 1, 8 do
			local part = partOf(current)
			if part then
				return part
			end
			current = current and current.Parent
			if not current then
				break
			end
		end
		return nil
	end

	local function getOwner(object)
		local current, id, leader = object, nil, nil
		for _ = 1, 8 do
			if not current then
				break
			end
			id = id or ctx.attr(current, "BountyId") or ctx.attr(current, "Bounty")
			leader = leader or ctx.attr(current, "BountyLeaderId") or ctx.attr(current, "BountyOwnerId")
			if not leader and current.Name == "Party_" .. tostring(state.leader) then
				local bountyWorld = child(world, "BountyWorld")
				if bountyWorld and current.Parent and current.Parent.Address == bountyWorld.Address then leader = state.leader end
			end
			if id and leader then
				break
			end
			current = current.Parent
		end
		return id and tostring(id), tonumber(leader)
	end

	local function isOwned(object)
		local id, leader = getOwner(object)
		return ownerMatches(id, leader, state.active, state.leader)
	end

	local function targetObjectAllowed(object)
		if not object or not object.Parent then return false end
		local id, leader = getOwner(object)
		if id or leader then return ownerMatches(id, leader, state.active, state.leader) end
		local current, npc = object, nil
		local npcFolder, playerFolder = child(world, "NPCs"), child(world, "Players")
		for _ = 1, 8 do
			if not current then break end
			if playerFolder and current.Address == playerFolder.Address then return false end
			if npcFolder and current.Parent and current.Parent.Address == npcFolder.Address then npc = current; break end
			current = current.Parent
		end
		local _, index = parseId(state.active)
		if npc and index == 13 then
			local darby = child(npcFolder, "Darby")
			local root = child(darby, "HumanoidRootPart")
			return state.leader == player.UserId and darby ~= nil and npc.Address == darby.Address and root ~= nil
				and (object.Address == darby.Address or object.Address == root.Address or object.Parent.Address == root.Address)
		end
		return not npc or state.talkNPC ~= nil and (canonicalNPC(npc.Name) == state.talkNPC
			or canonicalNPC(ctx.attr(npc, "Config")) == state.talkNPC)
	end

	local function resolveTargetPath(path)
		if type(path) ~= "string" then return nil end
		local pieces = {}
		for piece in path:gsub("/", "."):gmatch("[^%.]+") do pieces[#pieces + 1] = piece end
		if normalized(pieces[1]) == "game" and (normalized(pieces[2]) == "workspace" or pieces[2] == world.Name) then table.remove(pieces, 1) end
		local current = game.Workspace
		if normalized(pieces[1]) == "workspace" then
			table.remove(pieces, 1)
		elseif pieces[1] ~= world.Name then
			current = world
		end
		for _, piece in ipairs(pieces) do current = child(current, piece); if not current then return nil end end
		return targetObjectAllowed(current) and current or nil
	end

	local function relatedToTarget(object)
		local target = state.targetObject
		if not target then return not state.targetMissing end
		for _ = 1, 12 do
			if not object then break end
			if object.Address == target.Address then return true end
			object = object.Parent
		end
		return false
	end

	local function promptAllowed(prompt, marker)
		if
			not prompt
			or not prompt.Parent
			or ctx.attr(prompt, "StoryPromptAvailable") == false
			or ctx.attr(prompt, "BountySourceHidden") == true
			or ctx.attr(prompt, "BountyDeliveryAvailable") == false
		then
			return false
		end
		local carrier, owner = ctx.attr(prompt, "BountyDeliveryCarrierId"), ctx.attr(prompt, "StoryPromptOwnerId")
		if carrier and tonumber(carrier) ~= player.UserId then
			return false
		end
		if owner and tonumber(owner) ~= player.UserId then
			return false
		end
		local id, leader = getOwner(prompt)
		local part = promptPart(prompt)
		local nearby = validVector(marker) and part and validVector(part.Position) and (part.Position - marker).Magnitude < 14
		local _, index = parseId(state.active)
		local jewelry = jewelryNPC(state.progress, state.active)
		if index == 10 and state.phase == "hospital" and prompt.Name == "ProximityPrompt" then
			local folder = child(world, "NPCs")
			local nurse = child(folder, "Hospital Nurse")
			local root = child(nurse, "HumanoidRootPart")
			if state.leader ~= player.UserId or prompt.ClassName ~= "ProximityPrompt" or not nurse or not nurse.Parent
				or nurse.Parent.Address ~= folder.Address or not root or not root.Parent or root.Parent.Address ~= nurse.Address
				or prompt.Parent.Address ~= root.Address or not validVector(state.targetMarker) or not validVector(root.Position)
				or (root.Position - state.targetMarker).Magnitude > 8 or not relatedToTarget(prompt) then return false end
			for _, object in ipairs({prompt, root, nurse}) do
				local bounty, partyLeader = getOwner(object)
				local carrier, owner = ctx.attr(object, "BountyDeliveryCarrierId"), ctx.attr(object, "StoryPromptOwnerId")
				if bounty and bounty ~= state.active or partyLeader and partyLeader ~= state.leader
					or carrier and tonumber(carrier) ~= player.UserId or owner and tonumber(owner) ~= player.UserId then return false end
			end
			return true
		end
		if jewelry and prompt.ClassName == "ClickDetector" and prompt.Name == "ClickDetector" then
			local folder = child(world, "NPCs")
			local actor = child(folder, jewelry)
			local root = child(actor, "HumanoidRootPart")
			if state.leader ~= player.UserId or not actor or not actor.Parent or actor.Parent.Address ~= folder.Address
				or not root or not root.Parent or root.Parent.Address ~= actor.Address or prompt.Parent.Address ~= actor.Address
				or not validVector(state.targetMarker) or not validVector(root.Position) or (root.Position - state.targetMarker).Magnitude > 8
				or state.targetObject and state.targetObject.Address ~= actor.Address and state.targetObject.Address ~= root.Address and not relatedToTarget(prompt) then return false end
			for _, object in ipairs({ prompt, root, actor }) do
				local bounty, partyLeader = getOwner(object)
				local carrier, owner = ctx.attr(object, "BountyDeliveryCarrierId"), ctx.attr(object, "StoryPromptOwnerId")
				if bounty and bounty ~= state.active or partyLeader and partyLeader ~= state.leader
					or carrier and tonumber(carrier) ~= player.UserId or owner and tonumber(owner) ~= player.UserId then return false end
			end
			return true
		end
		if index == 13 and prompt.Name == "StandStorageOpen" then
			local darby = child(child(world, "NPCs"), "Darby")
			local root = child(darby, "HumanoidRootPart")
			if state.leader ~= player.UserId or prompt.ClassName ~= "ProximityPrompt"
				or not root or not root.Parent or root.Parent.Address ~= darby.Address or prompt.Parent.Address ~= root.Address
				or not validVector(marker) or not validVector(root.Position) or (root.Position - marker).Magnitude > 8
				or not relatedToTarget(prompt) or ctx.attr(prompt, "ServerInteraction") ~= true
				or ctx.attr(prompt, "InteractionKeybind") ~= "Interactables" then return false end
			for _, object in ipairs({ prompt, root, darby }) do
				local bounty, partyLeader = getOwner(object)
				local carrier, owner = ctx.attr(object, "BountyDeliveryCarrierId"), ctx.attr(object, "StoryPromptOwnerId")
				if bounty and bounty ~= state.active or partyLeader and partyLeader ~= state.leader
					or carrier and tonumber(carrier) ~= player.UserId or owner and tonumber(owner) ~= player.UserId then return false end
			end
			return true
		end
		local stationFolder = index == 10 and "ArmWrestlingTables" or index == 13 and "GoFishTables"
		if stationFolder then
			local container, ancestor, station = child(world, stationFolder), prompt, nil
			for _ = 1, 8 do
				if not ancestor or not container then break end
				local bounty = ctx.attr(ancestor, "BountyId") or ctx.attr(ancestor, "Bounty")
				local partyLeader, partyOwner = ctx.attr(ancestor, "BountyLeaderId"), ctx.attr(ancestor, "BountyOwnerId")
				if bounty and tostring(bounty) ~= state.active or partyLeader and tonumber(partyLeader) ~= state.leader
					or partyOwner and tonumber(partyOwner) ~= state.leader then return false end
				if ancestor.Address == container.Address then
					local party = child(child(world, "BountyWorld"), "Party_" .. tostring(state.leader))
					local owned = false
					for _, scene in ipairs(party and party:GetChildren() or {}) do
						if isOwned(scene) then owned = true; break end
					end
					local users = ctx.attr(prompt, "InteractionUserIds")
					local reserved = index == 10 and state.phase == "table" and state.leader == player.UserId and leader == nil
						and prompt.ClassName == "ProximityPrompt" and station and station.ClassName == "Model"
						and tonumber(ctx.attr(station, "ReservedOwner")) == player.UserId and type(users) == "string"
						and users:find("," .. tostring(player.UserId) .. ",", 1, true) ~= nil
					return owned and (id == nil or id == state.active) and (leader == state.leader or reserved) and validVector(marker) and part and validVector(part.Position)
						and (part.Position - marker).Magnitude <= 8
						and (index == 10 and prompt.Name == "ArmWrestlingSit"
							or index == 13 and (prompt.Name == "GoFishOwnedSeat" or prompt.Name == "PlayerGoFish"))
				end
				station, ancestor = ancestor, ancestor.Parent
			end
		end
		if id then return ownerMatches(id, leader, state.active, state.leader) and relatedToTarget(prompt)
			and (state.targetObject ~= nil or marker == nil or nearby) end
		local classic = index and index <= 3 and prompt.ClassName == "ProximityPrompt"
		local delivery = classic and (prompt.Name == "BountyDeliverPickup_" .. tostring(state.leader) or prompt.Name == "BountyDeliverDrop_" .. tostring(state.leader))
		if classic and (prompt.Name == "BountyPrompt_" .. tostring(state.leader) or delivery) then
			local step = type(state.progress) == "table" and state.progress.StepIndex
			return leader == state.leader and finite(step) and step >= 1 and step % 1 == 0
				and (not delivery or type(state.progress.HasItem) == "boolean" and prompt.Name == (state.progress.HasItem and "BountyDeliverDrop_" or "BountyDeliverPickup_") .. tostring(state.leader))
				and validVector(state.targetMarker) and part and validVector(part.Position) and (part.Position - state.targetMarker).Magnitude <= 8
				and relatedToTarget(prompt) and ctx.attr(prompt, "InteractionKeybind") == "Interactables"
		end
		if state.karaokeObjective then
			local stations, model = child(world, "KaraokeStations"), part and part.Parent
			local party = child(child(world, "BountyWorld"), "Party_" .. tostring(state.leader))
			local scene = child(party, "Incident_Usagi")
			return nearby and stations ~= nil and model ~= nil and model.Parent ~= nil
				and model.Parent.Address == stations.Address and prompt.Name == "Karaoke" and (leader == nil or leader == state.leader)
				and scene ~= nil and isOwned(scene)
		end
		if state.talkNPC then
			local target = prompt.Name:match("^BountyIncident_(.+)Talk$")
			return nearby and target ~= nil and canonicalNPC(target) == state.talkNPC
				and leader == state.leader and ctx.attr(prompt, "StoryPromptAvailable") == true
		end
		if not nearby or leader ~= nil then return false end
		local npcFolder, ancestor = child(world, "NPCs"), part
		for _ = 1, 8 do
			if not ancestor then break end
			if npcFolder and ancestor.Address == npcFolder.Address then return false end
			ancestor = ancestor.Parent
		end
		return true
	end

	local function goFishRoot(gui)
		cached.storageAction = nil
		local _, index = parseId(state.active)
		if not gui or index ~= 13 or ctx.attr(player, "QTEInputLocked") ~= true then return nil end
		local selected, storageAction, storageAmbiguous
		for _, root in ipairs(gui:GetChildren()) do
			if root.ClassName == "ScreenGui" and root.Parent and root.Parent.Address == gui.Address then
				local panel = child(root, "Panel", true)
				local title, action = child(panel, "Title"), child(panel, "Action")
				if title and title.ClassName == "TextLabel" and title.Text == "STAND STORAGE"
					and action and action.ClassName == "TextButton" then
					if storageAction then storageAmbiguous = true else storageAction = action end
				end
				local speech = child(root, "Speech", true)
				local stage = speech and speech.Parent
				local speaker, line = child(speech, "Speaker"), child(speech, "Line")
				local darby, hand = child(stage, "DarbyHand", true), child(stage, "Hand", true)
				local board = hand and hand.Parent
				local result, leave = child(stage, "Result"), child(stage, "LeaveTable")
				local body, primary = child(result, "Body"), child(result, "Primary")
				if speech and (speech.ClassName == "Frame" or speech.ClassName == "ImageLabel") and stage and stage.ClassName == "Frame"
					and stage.Parent and stage.Parent.Address == root.Address
					and speaker and speaker.ClassName == "TextLabel" and speaker.Text == "D'ARBY"
					and line and line.ClassName == "TextLabel"
					and hand and (hand.ClassName == "Frame" or hand.ClassName == "ImageLabel")
					and darby and (darby.ClassName == "Frame" or darby.ClassName == "ImageLabel")
					and board and board.ClassName == "Frame" and board.Parent and board.Parent.Address == stage.Address
					and darby.Parent and darby.Parent.Address == board.Address
					and result and (result.ClassName == "Frame" or result.ClassName == "ImageLabel") and body and body.ClassName == "TextLabel"
					and primary and primary.ClassName == "TextButton" and leave and leave.ClassName == "TextButton" then
					if selected then return nil end
					selected = root
				end
			end
		end
		cached.storageAction = not storageAmbiguous and storageAction or nil
		return selected
	end

	local function refreshUI()
		cached.gui = child(player, "PlayerGui")
		cached.bounty = child(cached.gui, "Bounty")
		cached.menu = child(cached.bounty, "BountySelect")
		cached.tracker = child(cached.bounty, "BountyTracker")
		cached.objective = label(cached.tracker, "TitleAlt")
		if cached.objective == "failed to fetch text" then
			cached.objective = ""
		end
		cached.heyHead = label(child(cached.bounty, "IncidentNarrator"), "TutorialHead")
		cached.choices = child(cached.bounty, "VerityChoices")
		cached.goFish = goFishRoot(cached.gui)
		cached.goFishLine = label(child(cached.goFish, "Speech", true), "Line")
		cached.tabletop = child(cached.gui, "TabletopInterface")
	end

	local function collectKaraoke(session)
		if not karaoke or karaoke.session ~= session then
			releaseKeys()
			karaoke = { session = session, notes = {}, pressed = {}, held = {}, lastCollect = -math.huge }
		end
		local owner = karaoke
		if ctx.now() - owner.lastCollect < (owner.lane and 0.015 or 0.12) then return end
		owner.lastCollect = ctx.now()
		local lane = owner.lane
		if not lane or not lane.Parent then
			owner.selection = child(cached.gui, "SongSelection", true)
			if karaoke ~= owner then return end
			if owner.selection then
				owner.song = karaokeSong(state.progress, cached.objective, state.active) or owner.song
				owner.choice = karaokeButton(owner.selection, owner.song)
				owner.notes, owner.error = {}, nil
				return
			end
			owner.choice = nil
			local panel = child(cached.gui, "RhythmPanel", true)
			local receptor = child(panel, "X", true)
			lane = receptor and receptor.Parent
			owner.lane = lane
		end
		if not lane then
			owner.notes = {}
			owner.error = "Usagi needs the visible karaoke lane"
			return
		end
		local notes = {}
		owner.error = nil
		for _, object in ipairs(lane:GetChildren()) do
			local index = tonumber(object.Name:match("^Note(%d+)$"))
			if index then
				local key = keyCode(label(object, "Key"))
				local notePosition = object.AbsolutePosition
				local noteSize = object.AbsoluteSize
				local closest, gap = nil, math.huge
				if notePosition and noteSize and finite(notePosition.X) and finite(notePosition.Y) and notePosition.X > 0 then
					for _, symbol in ipairs({ "X", "A", "Y", "B" }) do
						local r = child(lane, symbol)
						local rp, rs = r and r.AbsolutePosition, r and r.AbsoluteSize
						if rp and rs and finite(rp.X) and finite(rp.Y) and rp.X > 0 and rp.Y > 0 then
							local distance = math.abs(notePosition.Y + noteSize.Y / 2 - rp.Y - rs.Y / 2)
							if distance < gap then
								closest, gap = r, distance
							end
						end
					end
				end
				if closest then key = key or karaokeBinding(closest.Name) end
				if key and closest then
					notes[#notes + 1] = {
						index = index,
						object = object,
						receptor = closest,
						key = key,
						tail = child(lane, "Hold" .. index),
					}
				else
					owner.error = "Usagi needs readable note keys and receptor positions"
				end
			end
		end
		if karaoke == owner then owner.notes = notes end
	end

	local function karaokeStep()
		if not karaoke then say("Usagi needs its native karaoke session", "Usagi"); return end
		local owner = karaoke
		if not owner.selection then
			say(owner.error or "Usagi: following the native notes and holds", "Usagi")
			return
		end
		if not owner.song then say("Usagi needs the bounty's requested song title", "Usagi"); return end
		if incidents and incidents.KaraokeSubmitted then
			local submitted = incidents.KaraokeSubmitted(owner, state) == true
			if karaoke ~= owner then return end
			owner.submitted = submitted
		end
		if owner.submitted then say("Usagi: waiting for the selected performance to start", "Usagi"); return end
		local choice, now = owner.choice, ctx.now()
		if not choice or not choice.Parent then say("Usagi needs the requested song in its native selection menu", "Usagi"); return end
		if now < (owner.nextClick or 0) then return end
		owner.nextClick = now + 0.3
		local point, viewport = choice.AbsolutePosition, game.Workspace.Camera.ViewportSize
		if not point or not finite(point.X) or not finite(point.Y) or point.X <= 0 then
			say("Usagi needs readable native song button positions", "Usagi"); return
		end
		local width, height = viewport.X < 700 and 450 or 660, viewport.X < 700 and 610 or 580
		local scale = math.min(1, (viewport.X - 28) / width, (viewport.Y - 40) / height)
		local top = viewport.Y / 2 - height * scale / 2 + 126 * scale
		local bottom = viewport.Y / 2 + height * scale / 2 - 11 * scale
		if point.Y < top or point.Y + 30 * scale > bottom then
			if ctx.mouseMove(viewport.X / 2, (top + bottom) / 2) then mousescroll(point.Y < top and 4 or -4) end
			say("Usagi: scrolling to " .. owner.song, "Usagi")
			return
		end
		if ctx.attr(player, "KaraokeInputLocked") ~= owner.session or karaoke ~= owner then return end
		if ctx.click(choice) then
			owner.nextClick = now + 0.9
			say("Usagi: selecting " .. owner.song, "Usagi")
		end
	end

	local function scanWorld()
		prompts, fighters, scenes = {}, {}, {}
		state.targetObject = resolveTargetPath(state.targetPath)
		local namedTarget, namedAmbiguous
		cached.petyr = child(child(world, "NPCs"), "Petyr")
		cached.petyrPart = partOf(cached.petyr)
		cached.petyrPrompt = child(cached.petyr, "ProximityPrompt") or child(cached.petyr, "ClickDetector")
		state.lastWorld = ctx.now()
		if not state.active then
			return
		end
		local seen, fighterSeen, sceneSeen = {}, {}, {}
		local function directlyOwned(model)
			local id = ctx.attr(model, "BountyId") or ctx.attr(model, "Bounty")
			local leader = ctx.attr(model, "BountyLeaderId") or ctx.attr(model, "BountyOwnerId")
			return id ~= nil and ownerMatches(tostring(id), tonumber(leader), state.active, state.leader),
				id ~= nil or leader ~= nil
		end
		local function nearMarker(model)
			if not state.marker then
				return false
			end
			local part = partOf(model)
			return part and part.Parent and validVector(part.Position) and (part.Position - state.marker).Magnitude < 20
		end
		local function neutralTarget(model, container)
			if not state.talkNPC then
				return container ~= "Players"
			end
			if container ~= "NPCs" then
				return false
			end
			local config = ctx.attr(model, "Config")
			return canonicalNPC(model.Name) == state.talkNPC
				or (type(config) == "string" and canonicalNPC(config) == state.talkNPC)
		end
		local function addPrompt(prompt)
			local address = prompt.Address
			if address and not seen[address] then
				seen[address] = true
				prompts[#prompts + 1] = { object = prompt, part = promptPart(prompt) }
			end
		end
		local function matchTargetName(object)
			if state.targetName and object.Name == state.targetName and targetObjectAllowed(object) then
				if namedTarget and namedTarget.Address ~= object.Address then namedAmbiguous = true end
				namedTarget = object
			end
		end
		local function scanModel(model, combatFolder, ownership, nestedCombat)
			local owned = ownership
			if owned == nil then
				owned = isOwned(model)
			end
			matchTargetName(model)
			if model.Name:match("^Incident_") and owned and not sceneSeen[model.Address] then
				sceneSeen[model.Address] = true
				scenes[#scenes + 1] = model
			end
			local scaledTier = ctx.attr(model, "BountyScaledTier")
			local partyEnemy = finite(scaledTier) and scaledTier >= 1 and scaledTier % 1 == 0
			if owned and combatFolder and (not nestedCombat or partyEnemy) and model.ClassName == "Model" and not fighterSeen[model.Address] then
				local hum, root = child(model, "Humanoid"), child(model, "HumanoidRootPart")
				if hum and root then
					fighterSeen[model.Address] = true
					fighters[#fighters + 1] = { object = model, humanoid = hum, part = root }
				end
			end
			if owned or not combatFolder then
				local storyActor = model.Parent and model.Parent.Name == "StoryActors"
				for _, prompt in ipairs(ctx.findPrompts(model)) do
					if not storyActor or ctx.attr(prompt, "StoryPromptAvailable") == true then addPrompt(prompt) end
				end
			end
			if nestedCombat or state.targetName then
				for _, object in ipairs(model:GetDescendants()) do
					matchTargetName(object)
					local enemyTier = nestedCombat and object.ClassName == "Model" and ctx.attr(object, "BountyScaledTier") or nil
					if nestedCombat and object.ClassName == "Model" and (ctx.attr(object, "BountyId") or ctx.attr(object, "Bounty")) and isOwned(object)
						and finite(enemyTier) and enemyTier >= 1 and enemyTier % 1 == 0 then
						scanModel(object, true, true, false)
					end
				end
			end
		end
		for _, name in ipairs({ "NPCs", "Players", "QuestInteractables", "StoryActors", "KaraokeStations", "ArmWrestlingTables", "GoFishTables" }) do
			local container = child(world, name)
			if container then
				for _, model in ipairs(container:GetChildren()) do
					local owned, hasOwner = directlyOwned(model)
					local _, index = parseId(state.active)
					local station = name == "ArmWrestlingTables" and index == 10 or name == "GoFishTables" and index == 13
					local named = state.targetName and model.Name == state.targetName and targetObjectAllowed(model)
					if owned or station or name ~= "StoryActors" and (not hasOwner and neutralTarget(model, name) and (nearMarker(model) or named)) then
						scanModel(model, name == "Players", owned)
					end
				end
			end
		end
		local _, index = parseId(state.active)
		local deliveries = index and index <= 3 and child(child(world, "Map"), "Deliveries")
		for _, model in ipairs(deliveries and deliveries:GetChildren() or {}) do
			if nearMarker(model) then scanModel(model, false) end
		end
		local bountyWorld = child(world, "BountyWorld")
		local party = child(bountyWorld, "Party_" .. tostring(state.leader))
		if party then
			for _, model in ipairs(party:GetChildren()) do
				scanModel(model, true, nil, true)
			end
		end

		for _, model in ipairs(world:GetChildren()) do
			if model.Name:match("^Incident_") and isOwned(model) then
				scanModel(model, true, true, true)
			end
		end
		local mapScene = families[index] and child(child(world, "Map"), "Incident_" .. families[index])
		if mapScene and isOwned(mapScene) then scanModel(mapScene, true, true, true) end
		if not state.targetObject and not namedAmbiguous then state.targetObject = namedTarget end
		local targetPart = partOf(state.targetObject)
		if not state.targetMarker and targetPart and validVector(targetPart.Position) then state.marker = targetPart.Position end
		state.targetMissing = (state.targetPath ~= nil or state.targetName ~= nil) and state.targetObject == nil and state.marker == nil
		state.lastWorld = ctx.now()
	end

	local function collectTea(owner)
		local scene = child(child(world, "Effects"), "TabletopScene") or child(world, "TabletopScene") or child(game.Workspace, "TabletopScene")
		if not tea or tea.owner ~= owner then
			releaseKeys()
			tea = { owner = owner, stage = nil, retryAt = 0 }
		end
		tea.scene = scene
		tea.body = label(child(cached.tabletop, "Instruction", true), "Body")
		tea.action = label(child(cached.tabletop, "Footer", true), "Action")
		tea.status = label(child(cached.tabletop, "Footer", true), "Status")
		tea.actionObject = child(child(cached.tabletop, "Footer", true), "Action")
		tea.viewObject = child(child(cached.tabletop, "Footer", true), "Reset")
		tea.view = textOf(tea.viewObject)
		tea.target = child(scene, "DropTarget")
		tea.props, tea.pivots, tea.fills, tea.bands = {}, {}, {}, {}
		if not scene then
			return
		end
		for _, object in ipairs(scene:GetChildren()) do
			if object.Name == "BandLine" then
				tea.bands[#tea.bands + 1] = object
			end
			if object.ClassName == "Model" then
				local bounds = child(object, "GrabBounds")
				local pickup
				for _, part in ipairs(object:GetDescendants()) do
					if not pickup and (part.ClassName == "Part" or part.ClassName == "MeshPart" or part.ClassName == "UnionOperation")
						and finite(part.Transparency) and part.Transparency < 0.95 and part.CanQuery ~= false
						and validVector(part.Position) and not ctx.attr(part, "TabletopGrabHandle") then pickup = part end
					if ctx.attr(part, "TabletopFill") then
						tea.fills[#tea.fills + 1] = part
					end
				end
				if bounds then
					local primary = object.PrimaryPart
					if not primary or (primary.ClassName ~= "Part" and primary.ClassName ~= "MeshPart" and primary.ClassName ~= "UnionOperation")
						or not validVector(primary.Position) then primary = bounds end
					tea.props[normalized(object.Name)], tea.pivots[normalized(object.Name)] = pickup or bounds, primary
				end
			end
		end
	end

	local function sense(force)
		local now = ctx.now()
		if not force and now - state.lastSense < 0.16 then
			return
		end
		state.lastSense = now
		local data = child(player, "Data")
		local stats = child(data, "Stats")
		local active = ctx.decode(child(stats, "ActiveBounties"))
		local newId, readable = activeId(active)
		state.readable = readable
		local partyLeader = child(child(data, "Party"), "Leader")
		local leader = partyLeader and tonumber(partyLeader.Value) or 0
		if not leader or leader <= 0 then leader = player.UserId end
		if readable and newId == state.active and state.armSession and not state.claim and leader == player.UserId
			and leader == state.leader and ctx.attr(player.Character, "ArmWrestlingSession") == state.armSession then
			return
		end
		refreshUI()
		local rotationValue = child(stats, "BountyRotationKey")
		local epoch = type(ctx.utcNow) == "function" and ctx.utcNow()
		local rotation = type(epoch) == "number" and epoch > 0 and epoch < math.huge
			and (math.floor(epoch / 3600) + 1000000000) or rotationValue and tonumber(rotationValue.Value)
		if type(rotation) ~= "number" or rotation ~= rotation or rotation < 0 or rotation % 1 ~= 0 then state.readable = false; return end
		if state.rotation ~= rotation then
			state.rotation, state.completed, state.blockedUntil = rotation, {}, 0
		end
		if newId ~= state.active and state.readable then
			releaseKeys()
			karaoke, tea = nil, nil
			state.active, state.menuStage, busy = newId, nil, false
			state.lastWorld = -math.huge
		end
		state.leader = leader
		local progress = ctx.decode(child(stats, "BountyProgress"))
		state.progress = type(progress) == "table" and progress[state.active] or nil
		state.stepIndex = type(state.progress) == "table" and state.progress.StepIndex or nil
		state.phase = type(state.progress) == "table" and state.progress.IncidentPhase or nil
		state.karaokeObjective = karaokeGoal(state.progress, cached.objective, state.active)
		state.talkNPC = not state.karaokeObjective and talkTarget(state.progress, cached.objective, state.active) or nil
		state.claim = state.active
			and (
				(type(state.progress) == "table" and state.progress.ReadyToClaim == true)
				or cached.objective:lower():find("return to petyr", 1, true) ~= nil
			)
		local completions = completionMap(ctx.decode(child(stats, "BountyCompletions")), true)
		if completions then
			for index, doneRotation in pairs(completions) do
				if doneRotation >= rotation then
					state.completed[index] = true
				end
			end
		end
		state.targetMarker, state.targetPath, state.targetName = progressTarget(state.progress)
		state.marker = state.targetMarker or markerVector(ctx.attr(player, "VisibleBountyTrackerPosition"))
		if not validVector(state.marker) then
			state.marker = nil
		end
		local _, activeFamily = parseId(state.active)
		local karaokeSession = ctx.attr(player, "KaraokeInputLocked")
		state.karaokeSession = activeFamily == 12 and not state.claim and type(karaokeSession) == "string" and karaokeSession ~= "" and karaokeSession or nil
		local teaOwner = ctx.attr(player, "TabletopInputOwner")
		state.teaOwner = activeFamily == 14 and type(teaOwner) == "string" and teaOwner ~= "" and teaOwner or nil
		state.jewelry = ctx.attr(player, "JewelryInspecting") == true
		local character = player.Character
		local armSession = character and ctx.attr(character, "ArmWrestlingSession")
		state.armSession = activeFamily == 10 and not state.claim and type(armSession) == "string" and armSession ~= "" and armSession or nil
		if state.armSession and state.leader == player.UserId then
			if state.pacoSession ~= state.armSession then state.pacoExitAt = nil end
			state.pacoSession, state.pacoCharacter = state.armSession, character.Address
		end
		state.dialogue = ctx.attr(player, "DialogueInputLocked") == true
		state.inputLock = ctx.attr(player, "QTEInputLocked") == true
		local observed = tostring(state.active) .. "|" .. cached.objective .. "|" .. tostring(state.claim)
			.. "|" .. tostring(state.stepIndex) .. "|" .. tostring(state.phase) .. "|" .. tostring(state.targetPath) .. "|" .. tostring(state.targetName)
		if observed ~= lastObserved then
			if state.interactionOwned and ctx.cancelInteraction then ctx.cancelInteraction() end
			state.interactionOwned = false
			state.progressAt, state.blockedUntil, state.nextAction, state.lastWorld = now, 0, 0, -math.huge
			lastObserved = observed
		end
		if now - state.lastWorld >= 0.2 then
			scanWorld()
		end
		local _, index = parseId(state.active)
		state.verityBox = false
		local questionTitle = normalized(label(cached.choices, "Title"))
		if index == 8 and (questionTitle == "askberity" or questionTitle == "yourpersonalhelperfriend" or questionTitle == "hubertsmissingpackage") then
			local progress = state.progress
			state.verityBox = type(progress) == "table" and (progress.IncidentPhase == "box" or progress.IncidentPhase == "helper" or progress.IncidentPhase == "question") and type(progress.IncidentToken) == "string" and progress.IncidentToken ~= ""
			for _, scene in ipairs(scenes) do
				if scene.Name == "Incident_Verity" and isOwned(scene) then state.verityBox = true; break end
			end
		end
		if state.karaokeSession then
			collectKaraoke(state.karaokeSession)
		elseif karaoke then
			releaseKeys()
			karaoke = nil
		end
		if state.teaOwner then
			collectTea(state.teaOwner)
		elseif tea then
			releaseKeys()
			tea = nil
		end
		state.lastSense = ctx.now()
	end

	local function nearestPrompt()
		local root = ctx.getRoot()
		if not root then
			return nil
		end
		local target, distance = nil, math.huge
		for _, candidate in ipairs(prompts) do
			local part = candidate.part
			if
				part
				and part.Parent
				and validVector(part.Position)
				and promptAllowed(candidate.object, state.marker)
			then
				local d = (part.Position - root.Position).Magnitude
				if d < distance then
					target, distance = candidate, d
				end
			end
		end
		return target, distance
	end

	local function nearestFighter()
		local root = ctx.getRoot()
		local target, distance = nil, math.huge
		if not root then
			return nil
		end
		for _, candidate in ipairs(fighters) do
			if
				candidate.object.Parent
				and isOwned(candidate.object)
				and candidate.humanoid.Health > 0
				and validVector(candidate.part.Position)
				and not state.targetMissing
			then
				local currentTarget, targetHumanoid = state.targetObject, nil
				for _ = 1, 8 do
					if not currentTarget then break end
					targetHumanoid = child(currentTarget, "Humanoid")
					if targetHumanoid then break end
					currentTarget = currentTarget.Parent
				end
				local d = (candidate.part.Position - (state.marker or root.Position)).Magnitude
				if targetHumanoid and candidate.object.Address ~= currentTarget.Address then d = math.huge end
				if d < distance then
					target, distance = candidate.object, d
				end
			end
		end
		return target
	end

	local function incidentDialogue()
		local _, index = parseId(state.active)
		local definition = incidentDialogs[index]
		if not definition or state.claim then return false end
		local party = child(child(world, "BountyWorld"), "Party_" .. tostring(state.leader))
		local scene = child(party, definition.scene) or child(child(world, "Map"), definition.scene) or child(world, definition.scene)
		local holder = child(child(cached.gui, "Dialogue"), "Holder")
		if not scene or not isOwned(scene) or canonicalNPC(label(holder, "Title")) ~= definition.npc then return false end
		local choices, selected, count = child(holder, "Choices"), nil, 0
		for _, choice in ipairs(choices and choices:GetChildren() or {}) do
			if choice.ClassName == "ImageButton" then
				count += 1
				local answer = textOf(child(choice, "Box"))
				local number = tonumber(answer:match("^(%d+)%."))
				if not number or number < 1 or number > 9 or tonumber(choice.Name) ~= number then return false end
				local phrase = normalized(answer:gsub("^%d+%.%s*", ""))
				if phrase == definition.answer then
					if selected then return false end
					selected = choice
				elseif not definition.decline or phrase ~= definition.decline then return false end
			end
		end
		local answer = selected and textOf(child(selected, "Box"))
		local number = answer and tonumber(answer:match("^(%d+)%."))
		if not number or number < 1 or number > 9 or tonumber(selected.Name) ~= number
			or count > (definition.decline and 2 or 1) then return false end
		if not ctx.tap(48 + number) then return false end
		say((families[index] or definition.npc) .. ": starting the owned native challenge", families[index])
		return true
	end

	local function atPetyr()
		local root, part = ctx.getRoot(), cached.petyrPart
		if not root or not part or not part.Parent or not validVector(part.Position) then
			say("Waiting for Petyr to spawn")
			return false
		end
		if (root.Position - part.Position).Magnitude > 7 then
			ctx.move(part.Position + Vector3.new(0, 0, 3))
			say("Travelling to Petyr")
			return false
		end
		return true
	end

	local function claimAtPetyr()
		local rotation, index, tier = parseId(state.active)
		if not rotation then return false end
		local now = ctx.now()
		local data = child(player, "Data")
		local stats = child(data, "Stats")
		if state.menuStage ~= "claiming" then
			if not state.claim or type(state.progress) ~= "table" or state.progress.ReadyToClaim ~= true then return false end
			local completed = ctx.decode(child(stats, "CompletedQuests"), true)
			if type(completed) ~= "string" or not ("," .. completed .. ","):find(",P9_32_RETURN_TO_IKO_IKO,", 1, true) then return false end
			local leaderValue = child(child(data, "Party"), "Leader")
			local leader = leaderValue and tonumber(leaderValue.Value) or 0
			if not finite(leader) or (leader > 0 and leader ~= player.UserId and ctx.attr(player, "PersonalBountyReward") ~= state.active) then return false end
		end
		local claims = ctx.decode(child(stats, "BountyCompletions"))
		local key = tostring(index)
		local receipt = type(claims) == "table" and claims[key]
		if finite(receipt) and receipt % 1 == 0 and receipt >= rotation then
			state.menuStage, state.nextAction = nil, now + 0.1
			say("Bounty reward receipt confirmed")
			return true
		end
		if state.menuStage == "claiming" then
			if now > state.menuUntil then
				state.menuStage, state.blockedUntil = nil, now + 8
				say("Petyr needs reward claim confirmation")
			else
				busy = true
				say("Waiting for Petyr's reward receipt")
			end
			state.nextAction = now + 0.1
			return true
		end
		if now < state.blockedUntil or not atPetyr() then return true end
		local sent, result = pcall(function()
			return game.ReplicatedStorage.Remotes.Bounty:FireServer("ClaimAtPetyr", state.active)
		end)
		if not sent or result == false then
			state.blockedUntil, state.nextAction = now + 1, now + 0.1
			say("Petyr's reward request needs its native remote")
			return true
		end
		state.menuStage, state.menuUntil, state.nextAction = "claiming", now + 8, now + 0.1
		busy = true
		say("Waiting for Petyr's reward receipt")
		return true
	end

	local function petyrMenu()
		if not atPetyr() then
			return
		end
		local now = ctx.now()
		if state.menuStage == nil then
			if not cached.petyrPrompt then
				say("Petyr needs a readable bounty prompt")
				return
			end
			if ctx.interact(cached.petyrPrompt) ~= "triggered" then return end
			state.interactionOwned = true
			state.tierClicks = 0
			state.menuStage, state.menuUntil, state.nextAction = "opening", now + 12, now + 0.1
			busy = true
			say(state.claim and "Claiming the completed bounty at Petyr" or "Opening Petyr's bounty board")
			return
		end
		if now < state.nextAction then
			return
		end
		if state.dialogue then
			if ctx.dialogueStep then
				ctx.dialogueStep(state.claim and "BountyReward" or "Bounties")
				state.nextAction = now + 0.12
			else
				say("Petyr needs native dialogue controls")
			end
			if now > state.menuUntil then
				state.menuStage, busy = nil, false
				state.blockedUntil = now + 8
			end
			return
		end
		if state.claim then
			if now > state.menuUntil then
				state.menuStage, busy = nil, false
				state.blockedUntil = now + 8
				say("Petyr needs reward claim confirmation")
			end
			return
		end
		if state.menuStage == "accepting" then
			if now > state.menuUntil then
				state.menuStage, busy = nil, false
				state.blockedUntil = now + 8
				say("Petyr needs bounty acceptance confirmation")
			end
			return
		end
		local menu, objectives = cached.menu, child(cached.menu, "Objectives")
		local tierLabel = label(child(menu, "TierSelector"), "Label")
		local tier = tonumber(tierLabel:match("TIER%s+(%d+)"))
		if not tier or not objectives then
			if now > state.menuUntil then
				state.menuStage, busy = nil, false
				state.blockedUntil = now + 8
				say("Petyr needs the native bounty board")
			end
			return
		end
		local tierSetting = tostring(ctx.getSetting("BountyTier") or "Highest unlocked")
		local desired = tonumber(tierSetting) or tonumber(tierSetting:match("Tier%s+(%d+)"))
		if desired == 1 then
			tier = 1
		end
		local indices, candidate, blocked = available(state.rotation), nil, ctx.getSetting("BlockedBounties")
		for slot, index in ipairs(indices) do
			local title = label(child(objectives, "Bounty_" .. slot), "Title"):gsub(" | COMPLETE$", "")
			if title ~= bountyNames[index] and (index ~= 13 or title ~= "D'ARBY'S REMATCH") then
				state.nextAction = now + 0.2
				say("Waiting for the current native bounty board")
				return
			end
		end
		local anyBlocked, unreadable = false, false
		for slot, index in ipairs(indices) do
			local card = child(objectives, "Bounty_" .. slot)
			local title, description = label(card, "Title"), label(card, "Desc")
			if
				card
				and (
					ctx.attr(card, "BountyComplete") == true
					or title:find(" | COMPLETE", 1, true)
					or description == "BOUNTY COMPLETE!"
				)
			then
				state.completed[index] = true
			end
			local excluded = type(blocked) == "table" and blocked[bountyNames[index]] == true
			anyBlocked = anyBlocked or excluded
			if not excluded and not state.completed[index] and (not card or title == "") then unreadable = true end
			if not candidate and card and title ~= "" and not state.completed[index] and not excluded then
				candidate = { card = card, index = index, slot = slot }
			end
		end
		if not candidate then
			if unreadable then
				state.nextAction = now + 0.2
				say("Waiting for the native bounty cards")
				return
			end
			ctx.click(child(menu, "EXIT"))
			state.menuStage, busy, state.allDone = nil, false, state.rotation
			say(anyBlocked and "All offered bounties blocked or completed; waiting for refresh" or "All offered bounties completed; waiting for refresh")
			return
		end
		local begin = child(child(menu, "Start"), "Begin")
		local beginText = textOf(begin)
		if beginText == "Return to Petyr" then
			say("Petyr has a reward to claim before accepting")
			state.menuStage = nil
			state.blockedUntil = now + 2
			return
		end
		if beginText ~= "Begin" and beginText ~= "COMPLETE" then
			say("Petyr needs an available Begin button")
			state.nextAction = now + 0.1
			if now > state.menuUntil then
				state.menuStage, busy = nil, false
				state.blockedUntil = now + 8
			end
			return
		end
		game.ReplicatedStorage.Remotes.Bounty:FireServer(
			"Accept",
			string.format("%d-%02d-%d", state.rotation, candidate.index, tier)
		)
		state.menuStage, state.menuUntil, state.nextAction = "accepting", now + 8, now + 0.1
		say("Waiting for native bounty acceptance")
	end

	local function heyStill()
		for _, scene in ipairs(scenes) do
			local spot = child(scene, "HeySpot")
			if spot and isOwned(scene) then
				local root = ctx.getRoot()
				if not root then
					return true
				end
				releaseKeys()
				ctx.releaseAll()
				local point = validVector(state.targetMarker) and state.targetMarker or spot.Position
				local delta = root.Position - point
				if delta.X ^ 2 + delta.Z ^ 2 > 1 and ctx.now() >= (state.stillMoveAt or 0) then
					ctx.move(point + Vector3.new(0, 3, 0))
					state.stillMoveAt = ctx.now() + 2
				end
				busy = true
				say(cached.heyHead ~= "" and cached.heyHead or "Hey Ya: standing still at the marked spot", "HeyYa")
				return true
			end
		end
		say("Hey Ya needs its owned HeySpot to spawn", "HeyYa")
		return false
	end

	local function goFishStep()
		if not incidents or type(incidents.GoFishStep) ~= "function" then return false end
		local handled = incidents.GoFishStep(state, cached)
		busy = handled or busy
		return handled
	end

	local function teaStep()
		busy = true
		if not tea or not tea.scene then
			say("Iced tea needs its live tabletop scene", "IcedTea")
			return
		end
		local now = ctx.now()
		local dragging = tea.stage == "dragStart" or tea.stage == "dragMove"
		local native = incidents and incidents.TabletopState and incidents.TabletopState(tea, state)
		local step = native and native.Index or tea.status:match("Step%s+(%d+)%s*/") or tea.body:gsub("^Move the highlighted ", "Move the ")
		if tea.step ~= step then
			releaseKeys()
			tea.step, tea.stage, tea.retryAt, tea.failures, tea.failed = step, nil, 0, 0, false
			tea.viewClicks, tea.viewRetryAt, tea.viewEntering = 0, 0, nil
			if dragging then return end
		end
		if native and (native.Done or native.Ending or native.Kind == "Wait") then
			releaseKeys()
			tea.stage = nil
			say("Iced tea: waiting for the native recipe step", "IcedTea")
			return
		end
		if dragging then
			say("Iced tea: moving the native drag prop", "IcedTea")
			return
		end
		if native and native.Kind == "Click" then
			releaseKeys()
			if ctx.tap(32) then state.nextAction = now + 0.2 end
			say("Iced tea: " .. tea.action, "IcedTea")
			return
		end
		if tea.failed then
			say("Iced tea needs native recipe confirmation", "IcedTea")
			return
		end
		if tea.stage == "confirm" then
			if now - (tea.confirmAt or now) < 3 then
				say("Iced tea: checking the native recipe result", "IcedTea")
				return
			end
			tea.failures = (tea.failures or 0) + 1
			if tea.failures >= 3 then
				tea.failed = true
				say("Iced tea needs native recipe confirmation", "IcedTea")
				return
			end
			tea.stage, tea.retryAt = nil, now + 1
		end
		if
			tea.body:find("Let it fall", 1, true)
			or tea.body:find("Placing the", 1, true)
			or tea.body:find("Too much tea", 1, true)
			or tea.body:find("Wait", 1, true)
		then
			releaseKeys()
			say("Iced tea: waiting for the native recipe step", "IcedTea")
			return
		end
		-- The native view button can stop responding during a drag step.
		if tea.view == "OVERHEAD VIEW" and (tea.body:find("Hold to pour", 1, true)
			or tea.target and tea.target.Transparency < 0.9 and tea.body:find("Move the highlighted", 1, true)) then
			if tea.stage == "hold" then releaseKeys(); tea.stage = nil; return end
			if native and native.ViewEligible == false then say("Iced tea: waiting for the native view control", "IcedTea"); return end
			if now < (tea.viewRetryAt or 0) then return end
			if (tea.viewClicks or 0) >= 6 then
				tea.failed = true
				say("Iced tea needs native view confirmation", "IcedTea")
				return
			end
			local p, size = tea.viewObject.AbsolutePosition, tea.viewObject.AbsoluteSize
			local clicked
			if p and size and (size.X <= 1 or size.Y <= 1) and finite(p.X) and finite(p.Y) then
				-- shortcut: native Reset uses this measured interior; recalibrate if its layout changes.
				if not tea.viewEntering then
					if ctx.mouseMove(p.X + 84, p.Y - 100, nil, true) then
						tea.viewEntering, tea.viewRetryAt = true, now + 0.1
					end
					return
				end
				clicked = ctx.mouseMove(p.X + 84, p.Y + 40, nil, true)
				if clicked then
					if type(setrobloxinput) == "function" then setrobloxinput(true) end
					mouse1click()
				end
			else clicked = ctx.click(tea.viewObject) end
			if clicked then
				tea.viewClicks = (tea.viewClicks or 0) + 1
				tea.viewEntering = nil
				tea.viewRetryAt, state.nextAction = now + 1, now + 1
			end
			say("Iced tea: opening the native overhead view", "IcedTea")
			return
		end
		if tea.target and tea.target.Transparency < 0.9 and tea.body:find("Move the highlighted", 1, true) then
			if type(ctx.mouseMove) ~= "function" then
				say("Iced tea needs calibrated native pointer input", "IcedTea")
				return
			end
			local propName = tea.body:match("Move the highlighted (.-) over the ")
			local propKey = propName and normalized(propName)
			propKey = propKey == "icecubes" and "ice" or propKey == "lemonslice" and "lemon" or propKey
			local prop = propKey and tea.props[propKey]
			if not prop then
				say("Iced tea needs the named prop's drag bounds", "IcedTea")
				return
			end
			if now >= tea.retryAt and not tea.stage then
				tea.stage, tea.prop, tea.pivot, tea.start, tea.pickAt = "dragStart", prop, tea.pivots and tea.pivots[propKey] or prop, now, nil
			end
			say("Iced tea: placing " .. propName, "IcedTea")
			return
		end
		if tea.action:find("[SPACE]", 1, true) then
			if not tea.stage then
				tea.fill, tea.targetHeight = nil, nil
				local a, b = tea.bands[1], tea.bands[2]
				local visibleBand = a and b and finite(a.Transparency) and finite(b.Transparency) and a.Transparency < 0.9 and b.Transparency < 0.9
				if tea.status:lower():match("stop between %d+%% and %d+%%") or visibleBand then
					local low, high = math.huge, -math.huge
					for _, band in ipairs(tea.bands) do
						low = math.min(low, band.Position.Y)
						high = math.max(high, band.Position.Y)
					end
					if low >= high then
						say("Iced tea needs the visible pour band", "IcedTea")
						return
					end
					local targetY = (low + high) / 2
					for _, fill in ipairs(tea.fills) do
						local bottom = fill.Position.Y - fill.Size.Y / 2
						if
							targetY > bottom
							and (
								not tea.fill
								or math.abs(fill.Position.X - tea.bands[1].Position.X)
										+ math.abs(fill.Position.Z - tea.bands[1].Position.Z)
									< tea.fillDistance
							)
						then
							tea.fill, tea.targetHeight = fill, targetY - bottom
							tea.fillDistance = math.abs(fill.Position.X - tea.bands[1].Position.X)
								+ math.abs(fill.Position.Z - tea.bands[1].Position.Z)
						end
					end
					if not tea.fill then
						say("Iced tea needs its live pour fill", "IcedTea")
						return
					end
				end
				tea.stage, tea.start = "hold", now
			end
			if tea.stage == "hold" then
				hold(32)
				say("Iced tea: " .. tea.action:gsub("%s*%[SPACE%]", ""), "IcedTea")
			end
			return
		end
		if tea.action ~= "" and tea.body ~= "Done!" then
			releaseKeys()
			if ctx.click(tea.actionObject) then state.nextAction = now + 0.6 end
			say("Iced tea: " .. tea.action, "IcedTea")
			return
		end
		releaseKeys()
		say("Iced tea: waiting for the native recipe", "IcedTea")
	end

	function module.ResumeDialogue()
		if not ctx.getSetting("AutoBounties") then return false end
		sense(true)
		if not state.readable or not state.active or state.leader ~= player.UserId or not state.dialogue or ctx.now() < state.nextAction then return false end
		if incidentDialogue() or incidents and incidents.Step(state, cached, scenes)
			or ctx.dialogueStep and ctx.dialogueStep("BountyClose") then
			state.nextAction = ctx.now() + 0.12
			return true
		end
		return false
	end

	function module.Ready()
		local blocked, selection = ctx.getSetting("BlockedBounties"), 0
		if type(blocked) == "table" then
			for index, name in pairs(bountyNames) do if blocked[name] == true then selection += 2 ^ index end end
		end
		if (state.blockSelection or 0) ~= selection then state.allDone = nil end
		state.blockSelection = selection
		if not ctx.getSetting("AutoBounties") then
			return false
		end
		sense(false)
		if busy or (state.interactionOwned and ctx.interactionBusy and ctx.interactionBusy()) then
			return true
		end
		if not state.readable then
			say("Bounties need readable ActiveBounties state")
			return false
		end
		if ctx.now() < state.blockedUntil then
			return false
		end
		if state.active then
			if state.claim then
				return cached.petyrPart ~= nil
			end
			if
				state.karaokeSession
				or state.teaOwner
				or state.jewelry
				or state.armSession
				or state.dialogue
				or state.inputLock
				or state.verityBox
			then
				return true
			end
			local _, index = parseId(state.active)
			if index == 7 and (state.phase == "spot" or state.phase == "catching") or cached.heyHead:find("HOLD STILL", 1, true) then
				return true
			end
			if nearestFighter() or nearestPrompt() then
				return true
			end
			local root = ctx.getRoot()
			if state.marker and root and (root.Position - state.marker).Magnitude > 8 then
				return true
			end
			say("Waiting for the bounty objective to spawn")
			return false
		end
		if state.allDone == state.rotation then
			return false
		end
		return cached.petyrPart ~= nil
	end

	function module.SeatedAtPaco()
		local root = ctx.getRoot()
		local tableModel = child(child(world, "ArmWrestlingTables"), "BanditArmWrestling")
		if not root or not tableModel then return false end
		for _, name in ipairs({"Seat1", "Seat2"}) do
			local seat = child(tableModel, name)
			if seat and seat.Parent and child(seat, "SeatWeld") and validVector(seat.Position) then
				local delta = root.Position - seat.Position
				if delta.X ^ 2 + delta.Z ^ 2 < 0.25 and delta.Y > 0.8 and delta.Y < 2.5 then return true end
			end
		end
		return false
	end

	function module.CarryingPaco()
		local _, index = parseId(state.active)
		return ctx.getSetting("AutoBounties") == true and state.readable == true and state.leader == player.UserId
			and index == 10 and not state.claim and state.phase == "hospital"
	end

	function module.NeedsFreeHands()
		local _, index = parseId(state.active)
		return ctx.getSetting("AutoBounties") == true and state.readable == true and state.leader == player.UserId
			and not state.claim and (index == 12 and (state.karaokeObjective == true or state.karaokeSession ~= nil)
				or index == 14 and (state.phase == "brew" or state.phase == "drink"
					or type(state.teaOwner) == "string" and state.teaOwner ~= ""))
	end

	function module.Busy()
		return (busy or (state.interactionOwned and ctx.interactionBusy and ctx.interactionBusy()) or false)
			and ctx.getSetting("AutoBounties") == true
	end

	function module.Step()
		executing = true
		sense(state.armSession ~= nil)
		busy = false
		if not ctx.getSetting("AutoBounties") or not ctx.getRoot() then
			releaseKeys()
			executing = false
			return false
		end
		if not state.readable then
			releaseKeys()
			say("Bounties need readable ActiveBounties state")
			return false
		end
		local _, activeIndex = parseId(state.active)
		if not state.inputLock and not state.armSession and (not state.active or activeIndex == 10 and state.phase == "pickup")
			and module.SeatedAtPaco and module.SeatedAtPaco() then
			busy = true
			if state.interactionOwned and ctx.cancelInteraction then ctx.cancelInteraction() end
			state.interactionOwned = false
			if not state.pacoExitAt then
				if hold(88) then state.pacoExitAt = ctx.now() end
			else
				local elapsed = ctx.now() - state.pacoExitAt
				if elapsed < 0.15 then hold(88)
				elseif elapsed < 0.55 then release(88)
				elseif elapsed < 1.15 then release(88); hold(32)
				else release(32) end
			end
			say("Paco: waiting for the native chair exit", "Paco")
			return true
		elseif state.pacoExitAt then
			release(88); release(32); state.pacoExitAt = nil
		end
		if state.interactionOwned and ctx.interactionBusy and ctx.interactionBusy() then
			busy = true
			return true
		end
		state.interactionOwned = false
		if ctx.now() < state.nextAction then
			busy = state.menuStage ~= nil or state.karaokeSession ~= nil or state.teaOwner ~= nil or state.inputLock
			return busy
		end
		if (activeIndex == 13 or state.active == nil) and state.inputLock and not state.dialogue then
			if goFishStep() then return true end
			if activeIndex == 13 then
				releaseKeys()
				busy = true
				say("Go Fish: waiting for the current native session", "GoFish")
				return true
			end
		end
		if state.dialogue and incidentDialogue() then
			busy = true
			state.nextAction = ctx.now() + 0.12
			return true
		end
		if state.dialogue and ctx.dialogueStep
			and (ctx.dialogueStep(state.claim and "BountyReward" or "Bounties") or ctx.dialogueStep("BountyClose"))
		then
			busy = true
			state.nextAction = ctx.now() + 0.12
			return true
		end
		if (state.menuStage == "claiming" or state.claim) and claimAtPetyr() then return busy end
		if not state.active or state.claim then
			petyrMenu()
			return busy
		end
		local _, index = parseId(state.active)
		local family = families[index] or "Classic"
		if state.karaokeSession then
			busy = true
			karaokeStep()
			return true
		end
		if state.teaOwner then
			teaStep()
			return busy
		end
		if incidents and incidents.Step(state, cached, scenes) then
			busy = true
			return true
		end
		if state.jewelry then
			busy = true
			local gui = child(cached.gui, "JewelryInspection")
			local fitted = label(gui, "Status")
			if fitted:find("4 / 4", 1, true) then
				local action = child(child(gui, "Footer", true), "Action")
				if action then
					if ctx.click(action) then state.nextAction = ctx.now() + 1 end
					say("Jewelry: taking the restored evidence", "Jewelry")
				else
					say("Jewelry needs the native evidence action", "Jewelry")
				end
			else
				say("Jewelry needs readable component and clasp targets", "Jewelry")
			end
			return true
		end
		if state.armSession then
			busy = true
			releaseKeys()
			say("Paco needs the current arm-wrestling round target", "Paco")
			return true
		end
		if
			not incidents and index == 8
			and type(state.progress) == "table"
			and state.progress.IncidentPhase == "box"
			and label(cached.choices, "Choice1") ~= ""
		then
			busy = true
			releaseKeys()
			say("Berity needs a readable dialogue choice", "Verity")
			return true
		end
		if state.dialogue then
			busy = true
			if ctx.dialogueStep then
				ctx.dialogueStep("Bounty")
				state.nextAction = ctx.now() + 0.12
			else
				say(family .. " needs native dialogue controls", family)
			end
			return true
		end
		if state.inputLock then
			busy = true
			releaseKeys()
			say(family .. " needs readable native minigame input state", family)
			return true
		end
		if
			index == 7
			and (
				(type(state.progress) == "table" and (state.progress.IncidentPhase == "spot" or state.progress.IncidentPhase == "catching"))
				or cached.heyHead:find("HOLD STILL", 1, true)
			)
		then
			return heyStill()
		end
		local fighter = nearestFighter()
		if fighter then
			ctx.fight(fighter)
			say(family .. ": fighting the owned bounty target", family)
			return false
		end
		local prompt, distance = nearestPrompt()
		if prompt then
			if index == 10 and prompt.object.Name == "BountyIncident_PacoPickup" then
				local approach = prompt.part.Position + Vector3.new(2, 3, 0)
				local delta = ctx.getRoot().Position - approach
				if math.sqrt(delta.X ^ 2 + delta.Z ^ 2) > 1.5 or distance > 5 then
					ctx.move(approach)
					say("Paco: approaching injured Paco", family)
					return false
				end
			end
			if index == 14 and (prompt.object.Name == "BountyIncident_Pitcher" or state.phase == "gather" and distance < 2) then
				local pitcher = prompt.object.Name == "BountyIncident_Pitcher"
				local approach = prompt.part.Position + (pitcher and Vector3.new(5, 0, 0) or Vector3.new(3, 2, 0))
				local delta = ctx.getRoot().Position - approach
				if math.sqrt(delta.X ^ 2 + delta.Z ^ 2) > 1.5 then
					ctx.move(approach)
					say("IcedTea: approaching the side of the tea stand", family)
					return false
				end
			end
			if distance > 7 then
				ctx.move(prompt.part.Position + Vector3.new(0, 3, index == 13 and 5 or 2))
				say(family .. ": reaching " .. prompt.object.Name, family)
			else
				ctx.interact(prompt.object)
				state.interactionOwned = true
				busy = true
				state.nextAction = ctx.now() + 0.1
				say(family .. ": using " .. prompt.object.Name, family)
			end
			return busy
		end
		if state.marker then
			ctx.move(state.marker)
			say(family .. ": following the bounty marker", family)
		else
			say("Waiting for the bounty objective to spawn", family)
		end
		return false
	end

	function module.Render()
		if not executing or not busy or not ctx.getSetting("AutoBounties") then
			return
		end
		local now = ctx.now()
		if incidents then incidents.Render() end
		local owner = karaoke
		if owner then
			local _, family = parseId(state.active)
			if family ~= 12 or state.claim or ctx.attr(player, "KaraokeInputLocked") ~= owner.session then
				releaseKeys()
				karaoke = nil
				return
			end
			if karaoke ~= owner then return end
			if owner.lane then
				collectKaraoke(owner.session)
				if karaoke ~= owner then return end
			end
			for index, held in pairs(owner.held) do
				local size = held.tail and held.tail.Parent and held.tail.AbsoluteSize
				if size and finite(size.X) and (size.X > 1 or size.X == 0) then
					hold(held.key)
				elseif now - held.start >= 0.04 then
					release(held.key)
					owner.held[index] = nil
				end
			end
			for _, note in ipairs(owner.notes) do
				if not owner.pressed[note.index] and note.object.Parent and note.receptor.Parent then
					local np, ns = note.object.AbsolutePosition, note.object.AbsoluteSize
					local rp, rs = note.receptor.AbsolutePosition, note.receptor.AbsoluteSize
					local delta = np and ns and rp and rs and finite(np.X) and finite(ns.X) and finite(rp.X) and finite(rs.X)
						and ns.X >= 0 and rs.X >= 0
						and (ns.X > 1 and rs.X > 1 and np.X + ns.X / 2 - rp.X - rs.X / 2 or np.X - rp.X)
					if delta and delta <= 5 and delta >= -18 then
						if inputs[note.key] then
							release(note.key)
						end
						if hold(note.key) then
							owner.pressed[note.index] = true
							owner.held[note.key] = { key = note.key, tail = note.tail, start = now }
						end
					end
				end
			end
		end
		local currentTea = tea
		if currentTea then
			local owner = ctx.attr(player, "TabletopInputOwner")
			if tea ~= currentTea or owner ~= currentTea.owner then
				releaseKeys()
				return
			end
			if (currentTea.stage == "dragStart" or currentTea.stage == "dragMove") and type(ctx.mouseMove) ~= "function" then
				releaseKeys()
				currentTea.stage = nil
				say("Iced tea needs calibrated native pointer input", "IcedTea")
				return
			end
			if currentTea.stage == "hold" then
				local height = currentTea.fill and currentTea.fill.Size.Y
				if tea ~= currentTea then releaseKeys(); return end
				if height and height >= currentTea.targetHeight then
					release(32)
					currentTea.stage, currentTea.confirmAt = "confirm", now
				elseif now - currentTea.start > 20 then
					release(32)
					currentTea.stage, currentTea.confirmAt = "confirm", now
					say("Iced tea needs native pour confirmation", "IcedTea")
				else
					hold(32)
				end
			elseif currentTea.stage == "dragStart" and currentTea.prop and currentTea.target then
				local point, visible = WorldToScreen(currentTea.prop.Position)
				local pivot, pivotVisible = WorldToScreen((currentTea.pivot or currentTea.prop).Position)
				if tea ~= currentTea then releaseKeys(); return end
				if visible and pivotVisible then
					local moved = ctx.mouseMove(point.X, point.Y, nil, true)
					if tea ~= currentTea then releaseKeys(); return end
					if moved then
						currentTea.pickAt = currentTea.pickAt or now
						if now - currentTea.pickAt >= 0.06 then
							mouse1press()
							currentTea.mouseDown, currentTea.stage, currentTea.start = true, "dragMove", now
							currentTea.pickX, currentTea.pickY = point.X, point.Y
							currentTea.gripX, currentTea.gripY = point.X - pivot.X, point.Y - pivot.Y
						end
					else currentTea.pickAt = nil end
				else
					currentTea.stage, currentTea.retryAt, currentTea.pickAt = nil, now + 2, nil
					say("Iced tea needs its drag prop on screen", "IcedTea")
				end
			elseif currentTea.stage == "dragMove" then
				if now - currentTea.start < 0.1 then return end
				local destination, visible = WorldToScreen(currentTea.target.Position)
				if tea ~= currentTea then releaseKeys(); return end
				local x, y = destination.X + (currentTea.gripX or 0), destination.Y + (currentTea.gripY or 0)
				local alpha = math.clamp((now - currentTea.start - 0.1) / 0.55, 0, 1)
				local moved = visible and ctx.mouseMove((currentTea.pickX or x) + (x - (currentTea.pickX or x)) * alpha,
					(currentTea.pickY or y) + (y - (currentTea.pickY or y)) * alpha, nil, true)
				if tea ~= currentTea then releaseKeys(); return end
				local settled = moved and alpha >= 1
				if settled and currentTea.status == "Release now to drop it in." then currentTea.dropReadyAt = currentTea.dropReadyAt or now
				else currentTea.dropReadyAt = nil end
				if now - currentTea.start > 0.4 and currentTea.dropReadyAt and now - currentTea.dropReadyAt >= 0.12 then
					mouse1release()
					currentTea.mouseDown, currentTea.stage, currentTea.retryAt, currentTea.confirmAt, currentTea.dropReadyAt = false, "confirm", now + 2, now, nil
				elseif now - currentTea.start > 3 then
					mouse1release()
					currentTea.mouseDown, currentTea.stage, currentTea.retryAt, currentTea.confirmAt, currentTea.dropReadyAt = false, "confirm", now + 4, now, nil
					say("Iced tea needs native drag placement confirmation", "IcedTea")
				end
			end
		end
	end

	function module.Pause()
		releaseKeys()
		state.pacoExitAt = nil
		if tea and tea.failed then
			tea.failed, tea.failures, tea.stage, tea.retryAt = false, 0, nil, ctx.now() + 0.2
			tea.viewClicks, tea.viewRetryAt = 0, 0
		end
		if tea and (tea.stage == "dragStart" or tea.stage == "dragMove") then
			tea.stage, tea.retryAt = nil, ctx.now() + 0.2
		end
	end

	function module.Stop()
		if incidents then incidents.Stop() end
		releaseKeys()
		executing, busy = false, false
		state.menuStage = nil
		state.pacoExitAt = nil
		state.interactionOwned = false
		karaoke, tea = nil, nil
	end

	function module.Status()
		return status
	end

	function module.SelfTest()
		assert(validVector(markerVector({ x = "2", y = "3", z = "4" })))
		assert(markerVector({ x = "NaN", y = "3", z = "4" }) == nil)
		local checks = 0
		local function check(condition, message)
			checks = checks + 1
			assert(condition, message)
		end
		local rotation, index, tier = parseId("1000467321-05-4")
		check(rotation == 1000467321 and index == 5 and tier == 4, "tiered bounty id")
		rotation, index, tier = parseId("1000467321-05")
		check(index == 5 and tier == 1, "legacy tier one id")
		check(parseId("broken") == nil and parseId("100-99-1") == nil, "reject invalid ids")
		local active, readable = activeId({ "1000467321-05-4" })
		check(active == "1000467321-05-4" and readable, "read active contract")
		active, readable = activeId({})
		check(active == nil and readable, "confirmed empty active array")
		local _, malformed = activeId({ "truncated" })
		check(not malformed and select(2, activeId(nil)) == false, "malformed active state never means no contract")
		local offered, seen = available(1000467321), {}
		for _, offeredIndex in ipairs(offered) do
			check(not seen[offeredIndex] and offeredIndex ~= 4, "unique nonretired bounty")
			seen[offeredIndex] = true
		end
		check(#offered == 7 and offered[1] == bountyOrder[(1000467321 * 3) % 13 + 1], "native rotation ordering")
		local done = completionMap({ ["5:4"] = 40, ["5"] = 39, Earned = { ["5:2"] = 41 } }, true)
		check(done[5] == 41, "completion dedupe crosses tiers and earned rewards")
		check(ownerMatches("100-05", 7, "100-05", 7), "current leader owns the mission")
		check(
			not ownerMatches("100-05", 8, "100-05", 7) and not ownerMatches("100-06", 7, "100-05", 7),
			"foreign leaders and contracts are excluded"
		)
		check(
			completionMap(nil, true) == nil and completionMap({ ["5"] = "bad" }, true) == nil,
			"missing/truncated state never becomes empty completion map"
		)
		local keys = { [81] = true, [32] = true }
		check(#drainKeys(keys) == 2 and next(keys) == nil, "input cleanup drains every owned key")
		check(keyCode(" q ") == 81 and keyCode("Space") == 32 and keyCode("") == nil, "native note key mapping")
		return true, checks
	end

	return module
end

_G.StandOutParts = _G.StandOutParts or {}

_G.StandOutParts.Meteors = function(ctx)
	local module = { Available = true, Status = "Waiting for meteor drops", Metrics = { Attempts = 0, TargetsCleared = 0 } }
	local now, lastCollect, cache, meteorIds, retries, failures, job = ctx.now or tick, -math.huge, {}, {}, {}, {}, nil
	local inventoryAt, inventoryCount, inventoryReason, skipped, arrowReason = -math.huge, nil, nil, {}, nil
	local readMemory = ctx.meteorReadMemory or memory_read
	local function child(parent, name)
		return parent and parent:FindFirstChild(name)
	end
	local function live(object)
		return object ~= nil and object.Parent ~= nil
	end
	local function validPosition(point)
		return point ~= nil and type(point.X) == "number" and type(point.Y) == "number" and type(point.Z) == "number"
			and point.X == point.X and point.Y == point.Y and point.Z == point.Z
			and math.abs(point.X) < 100000 and math.abs(point.Y) < 100000 and math.abs(point.Z) < 100000
	end
	local function validDrop(item, eventId, dropId, meteor, marked)
		return type(item) == "string" and item ~= "" and type(eventId) == "string" and eventId ~= ""
			and type(dropId) == "string" and dropId:sub(1, #eventId + 1) == eventId .. ":"
			and dropId:sub(#eventId + 2):match("^%d+$") ~= nil and meteor == true and marked == true
	end
	local function report(message)
		if module.Status ~= message then
			module.Status = message
			ctx.setStatus("Meteors", message)
		end
	end
	local function integer(value, minimum, maximum)
		return type(value) == "number" and value == value and value % 1 == 0 and value >= minimum and value <= maximum
	end
	local function countParts(entries)
		if type(entries) ~= "table" then return nil end
		local count, slots, seen = 0, 0, {}
		for index, entry in pairs(entries) do
			if not integer(index, 1, #entries) then return nil end
			slots = slots + 1
			local name = type(entry) == "string" and entry or type(entry) == "table" and entry.Name
			if type(name) ~= "string" or name == "" then return nil end
			if name == "Arrow Part" then
				local amount, id
				if type(entry) == "table" then amount, id = entry.Amount, entry.ID end
				amount = amount == nil and 1 or amount
				if not integer(amount, 1, 1000000) then return nil end
				if id ~= nil then
					if type(id) ~= "string" or id == "" or seen[id] then return nil end
					seen[id] = true
				end
				count = count + amount
			end
		end
		return slots == #entries and count or nil
	end
	local function decode(raw)
		if type(raw) ~= "string" or not raw:match("^%s*%[") or not raw:match("%]%s*$") then return nil end
		local ok, value = pcall(ctx.decode, raw)
		return ok and type(value) == "table" and value or nil
	end
	local function memory(kind, address)
		if type(readMemory) ~= "function" or not integer(address, 65536, 281474976710655) then return nil end
		local ok, value = pcall(readMemory, kind, address)
		return ok and value or nil
	end
	local function readInventory()
		local inventory = child(child(child(ctx.player, "Data"), "Stats"), "Inventory")
		local raw = inventory and inventory.Value
		if type(raw) ~= "string" then return nil end
		local count = countParts(decode(raw))
		if count ~= nil then return count end
		local address = inventory.Address
		if not integer(address, 65536, 281474976710655) or #raw < 64 then return nil end
		local pointer, length, capacity = memory("uintptr", address + 160), memory("uintptr", address + 176), memory("uintptr", address + 184)
		if not integer(pointer, 65536, 281474976710655) or not integer(length, #raw, 65536)
			or not integer(capacity, length, 131071) then return nil end
		local first = memory("string", pointer)
		if type(first) ~= "string" or first:sub(1, #raw) ~= raw then return nil end
		local chunks = {}
		for offset = 0, length - 1, 255 do
			local chunk = offset == 0 and first or memory("string", pointer + offset)
			local size = math.min(255, length - offset)
			if type(chunk) ~= "string" or #chunk < size then return nil end
			chunks[#chunks + 1] = chunk:sub(1, size)
		end
		local full = table.concat(chunks)
		if #full ~= length then return nil end
		return countParts(decode(full))
	end
	local function refreshInventory(force)
		if force or now() - inventoryAt >= 0.2 then
			inventoryAt, inventoryCount = now(), readInventory()
			inventoryReason = inventoryCount == nil and "Waiting for readable Arrow Part capacity" or nil
			module.ArrowPartCount = inventoryCount
		end
		return inventoryCount
	end
	local function arrowRoom(target, force)
		if target.item ~= "Arrow Part" then return true end
		local count = refreshInventory(force)
		local amount = ctx.attr(target.model, "Amount")
		amount = amount == nil and 1 or amount
		local reason
		if count == nil then reason = inventoryReason
		elseif not integer(amount, 1, 1000000) then reason = "Waiting for readable Arrow Part drop amount"
		elseif count >= 200 then reason = "Arrow Parts full: " .. count .. " / 200; collecting other meteor loot"
		elseif count + amount > 200 then reason = "Arrow Part capacity: " .. count .. " / 200; skipping drop of " .. amount end
		if reason then
			if not skipped[target.id] then
				skipped[target.id] = true
				module.Metrics.CapacitySkips = (module.Metrics.CapacitySkips or 0) + 1
			end
			return false, reason
		end
		skipped[target.id] = nil
		return true
	end
	local function blocked()
		return ctx.attr(ctx.player, "DialogueInputLocked") == true or ctx.attr(ctx.player, "QTEInputLocked") == true
			or ctx.attr(ctx.player, "GardeningInputLocked") == true or ctx.attr(ctx.player, "GrowingInputOwner") ~= nil
			or ctx.attr(ctx.player, "KaraokeInputLocked") ~= nil or ctx.attr(ctx.player, "TabletopInputOwner") ~= nil
	end
	local function eligible(target)
		return live(target.model) and live(target.prompt) and live(target.base) and validPosition(target.base.Position)
			and ctx.attr(target.model, "WorldDropId") == target.id and ctx.attr(target.model, "WorldEventId") == target.eventId
			and validDrop(ctx.attr(target.model, "ItemName"), target.eventId, target.id, meteorIds[target.eventId], ctx.attr(target.prompt, "WorldEventDrop"))
			and target.prompt.Name == "WorldEventPickup" and ctx.attr(target.prompt, "StoryPromptAvailable") ~= false
	end
	local function collect()
		if now() - lastCollect < 0.2 then return end
		lastCollect, cache = now(), {}
		local events, retained = {}, {}
		local effects, drops = child(ctx.world, "Effects"), child(ctx.world, "WorldEventDrops")
		if effects then
			for _, effect in ipairs(effects:GetChildren()) do
				local id = ctx.attr(effect, "WorldEventId")
				if effect.Name:match("^Meteor_") and type(id) == "string" and id ~= "" then
					events[id], retained[id] = true, true
				end
			end
		end
		if drops then
			for _, model in ipairs(drops:GetChildren()) do
				local eventId, id, item = ctx.attr(model, "WorldEventId"), ctx.attr(model, "WorldDropId"), ctx.attr(model, "ItemName")
				local meteor = type(eventId) == "string" and (events[eventId] or meteorIds[eventId]) == true
				if model.ClassName == "Model" and meteor then
					retained[eventId] = true
					for _, prompt in ipairs(ctx.findPrompts(model)) do
						if prompt.ClassName == "ProximityPrompt" and prompt.Name == "WorldEventPickup"
							and validDrop(item, eventId, id, meteor, ctx.attr(prompt, "WorldEventDrop"))
						then
							local base = prompt.Parent
							if base and base.ClassName == "Attachment" then base = base.Parent end
							if base and validPosition(base.Position) then
								cache[#cache + 1] = { model = model, prompt = prompt, base = base, id = id, eventId = eventId, item = item }
								break
							end
						end
					end
				end
			end
		end
		meteorIds = retained
	end
	local function choose()
		local root, selected, distance = ctx.getRoot(), nil, math.huge
		arrowReason = nil
		if not root or not validPosition(root.Position) then return nil end
		for _, target in ipairs(cache) do
			if (retries[target.id] or 0) <= now() and eligible(target) then
				local available, reason = arrowRoom(target)
				if available then
					local d = (target.base.Position - root.Position).Magnitude
					if d < distance then selected, distance = target, d end
				else arrowReason = reason end
			end
		end
		return selected
	end
	local function finish(message, confirmed)
		if confirmed then
			module.Metrics.TargetsCleared = module.Metrics.TargetsCleared + 1
			module.LastConfirmation = { Kind = "DropRemoved", DropId = job.id, ItemName = job.item, At = now() }
			failures[job.id], retries[job.id] = nil, now() + 2
		else
			failures[job.id] = (failures[job.id] or 0) + 1
			retries[job.id] = now() + math.min(40, 2 ^ failures[job.id])
		end
		ctx.releaseAll()
		job, lastCollect = nil, -math.huge
		report(message)
	end
	function module.Ready()
		if not ctx.getSetting("AutoMeteors") then module.Stop(); return false end
		if blocked() or not ctx.getRoot() then return false end
		if job then return true end
		collect()
		local target = choose()
		if not target then report(arrowReason or "Waiting for meteor drops") end
		return target ~= nil
	end
	function module.Step()
		if not module.Ready() then return "waiting" end
		if not job then
			job = choose()
			if not job then return "waiting" end
			job.deadline, job.nextMove, job.nextInput = now() + 40, 0, 0
		end
		if not live(job.model) then
			local attempted = job.attempted == true
			finish(attempted and "Meteor drop removed after pickup" or "Meteor drop disappeared before pickup", attempted)
			return attempted and "done" or "waiting"
		end
		if now() > job.deadline then finish("Meteor pickup needs native confirmation", false); return "blocked" end
		if job.confirming then report("Waiting for meteor pickup confirmation"); return "busy" end
		if not eligible(job) then finish("Meteor drop is no longer available", false); return "waiting" end
		local room, reason = arrowRoom(job)
		if not room then
			ctx.releaseAll()
			job, lastCollect = nil, -math.huge
			report(reason)
			return "waiting"
		end
		local root, position = ctx.getRoot(), job.base.Position
		if (root.Position - position).Magnitude > 6 then
			if now() >= job.nextMove then ctx.move(position + Vector3.new(0, 2.5, 2)); job.nextMove = now() + 0.2 end
			report("Moving to meteor drop: " .. job.item)
			return "busy"
		end
		if now() >= job.nextInput then
			local capacity, message = arrowRoom(job, true)
			if not capacity then
				ctx.releaseAll()
				job, lastCollect = nil, -math.huge
				report(message)
				return "waiting"
			end
			local result = ctx.interact(job.prompt)
			job.nextInput = now() + 0.05
			if result == "triggered" or result == "holding" then
				if not job.attempted then module.Metrics.Attempts = module.Metrics.Attempts + 1 end
				job.attempted = true
			end
			if result == "triggered" then job.confirming, job.deadline = true, now() + 5 end
			report(result == "blocked" and "Meteor pickup is currently blocked" or "Collecting meteor drop: " .. job.item)
		end
		return "busy"
	end
	function module.Busy()
		return job ~= nil and ctx.getSetting("AutoMeteors") == true
	end
	function module.Stop()
		if job then ctx.releaseAll() end
		job = nil
	end
	function module.SelfTest()
		assert(validDrop("Arrow Part", "event", "event:1", true, true))
		assert(validDrop("Sapphire Roka", "event", "event:2", true, true))
		assert(validDrop("Other Loot", "event", "event:3", true, true))
		assert(not validDrop("Arrow Part", "event", "other:1", true, true))
		assert(not validDrop("Arrow Part", "event", "event:1", false, true))
		assert(not validDrop("Arrow Part", "event", "event:1", true, false))
		assert(not validDrop("", "event", "event:1", true, true))
		assert(countParts({ {Name = "Arrow Part", Amount = 99, ID = "one"}, {Name = "Arrow Part", Amount = 99, ID = "two"}, {Name = "Arrow Part", Amount = 2, ID = "three"} }) == 200)
		assert(countParts({ "Arrow Part", {Name = "Arrow Part"}, {Name = "Sapphire Roka", Amount = 99} }) == 2)
		assert(countParts({ {Name = "Arrow Part", Amount = "200"} }) == nil)
		assert(countParts({ {Name = "Arrow Part", ID = "one"}, {Name = "Arrow Part", ID = "one"} }) == nil)
		return true, 11
	end
	return module
end

_G.StandOutParts = _G.StandOutParts or {}

local function phoneFinite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function phoneInteger(value: any, low: number, high: number): boolean
	return phoneFinite(value) and value % 1 == 0 and value >= low and value <= high
end
local function phonePosition(point: any): boolean
	return point ~= nil and phoneFinite(point.X) and phoneFinite(point.Y) and phoneFinite(point.Z)
		and math.abs(point.X) < 1000000 and math.abs(point.Y) < 1000000 and math.abs(point.Z) < 1000000
end
local function phoneChild(parent: any, name: string): any return parent and parent:FindFirstChild(name) or nil end
local function phoneRemote(ctx: any): any
	if ctx.phoneRemote then return ctx.phoneRemote end
	return phoneChild(phoneChild(game:GetService("ReplicatedStorage"), "Remotes"), "PlayerBounties")
end

_G.StandOutParts.PhoneSnapshotReader = function(ctx: any): any
	local scan, readTable, readMemory = ctx.phoneScan or getgc, ctx.phoneReadTable or readtbl, ctx.phoneReadMemory or memory_read
	local remote, http = phoneRemote(ctx), game:GetService("HttpService")
	local scanned, holder, stateCell, modulePointer = false, nil, nil, nil
	local function pointer(value: any): boolean return phoneInteger(value, 65536, 281474976710655) end
	local function memory(kind: string, address: any): any
		if type(readMemory) ~= "function" or not pointer(address) then return nil end
		local ok, value = pcall(readMemory, kind, address)
		return ok and value or nil
	end
	local function tagged(address: any, tag: number): boolean
		return pointer(address) and (memory("byte", address + 1) == tag or memory("byte", address) == tag)
	end
	local function textValue(value: any): any
		if type(value) ~= "string" then return nil end
		if value:sub(1, 1) ~= '"' then return value end
		local ok, decoded = pcall(function() return http:JSONDecode(value) end)
		return ok and type(decoded) == "string" and decoded or nil
	end
	local function rowsAt(nodes: any, count: number): any
		if type(readTable) ~= "function" or not pointer(nodes) then return nil end
		local ok, rows = pcall(readTable, nodes, count)
		return ok and type(rows) == "table" and rows or nil
	end
	local function nativeMap(address: any): any
		if not pointer(address) then return nil end
		local current = memory("byte", address + 1) == 6
		if not current and memory("byte", address) ~= 6 then return nil end
		local exponent = memory("byte", address + (current and 4 or 5))
		if not phoneInteger(exponent, 0, 7) or current and memory("byte", address + 7) ~= math.min(2 ^ exponent - 1, 255) then return nil end
		local arrayCount, nodes = memory("int", address + 8), memory("uintptr", address + 40)
		if not phoneInteger(exponent, 0, 7) or not phoneInteger(arrayCount, 0, 128) or not pointer(nodes) then return nil end
		local count, map = 2 ^ exponent, {}
		local rows = rowsAt(nodes, count)
		if not rows then return nil end
		for _, row in ipairs(rows) do
			local slot = row.addr
			if type(row.key) == "string" and pointer(slot) and slot >= nodes and slot < nodes + count * 32 and (slot - nodes) % 32 == 0 then
				local tag = memory("int", slot + 12)
				if tag == 5 then map[row.key] = textValue(row.value)
				elseif tag == 3 then map[row.key] = memory("double", slot)
				elseif tag == 1 then local value = memory("int", slot); if value ~= nil then map[row.key] = value ~= 0 end
				elseif tag == 4 then
					local x, y, z = memory("float", slot), memory("float", slot + 4), memory("float", slot + 8)
					if phoneFinite(x) and phoneFinite(y) and phoneFinite(z) then map[row.key] = Vector3.new(x, y, z) end
				elseif tag == 7 then local value = memory("uintptr", slot); if tagged(value, 7) then map[row.key] = value end
				end
			end
		end
		return map
	end
	local function uprefs(closure: any): any
		if not tagged(closure, 7) or memory("byte", closure + (memory("byte", closure + 1) == 7 and 5 or 3)) ~= 0 then return nil end
		local count = memory("byte", closure + 4)
		if not phoneInteger(count, 1, 48) then return nil end
		local refs = {}
		for index = 0, count - 1 do
			local address = closure + 32 + index * 16
			refs[#refs + 1] = { tag = memory("int", address + 12), pointer = memory("uintptr", address) }
		end
		return refs
	end
	local function remoteRef(ref: any): boolean
		return remote ~= nil and ref.tag == 8 and tagged(ref.pointer, 8)
			and memory("int", ref.pointer + 4) == 16 and memory("uintptr", ref.pointer + 16) == remote.Address
	end
	local function cellMap(cell: any): any
		if not tagged(cell, 15) then return nil end
		local value = memory("uintptr", cell + 8)
		if not pointer(value) or memory("int", value + 12) ~= 6 then return nil end
		return nativeMap(memory("uintptr", value))
	end
	local function stateMap(map: any): boolean
		return type(map) == "table" and (map.State == "Idle" or map.State == "Active" or map.State == "Searching"
			or map.State == "Completing" or map.State == "Completed" or map.State == "Cancelled"
			or (map.State == nil and (type(map.Message) == "string" or next(map) == nil)))
	end
	local function locate(open: any): boolean
		local refs, candidate = uprefs(open), nil
		if not refs then return false end
		local hasRemote = false
		for _, ref in ipairs(refs) do
			if remoteRef(ref) then hasRemote = true end
			if ref.tag == 6 and pointer(ref.pointer) then
				local map = nativeMap(ref.pointer)
				if map and map.Open == open and map.Started == true and map.Init and map.Destroy then candidate = { map = map, pointer = ref.pointer } end
			end
		end
		if not candidate or not hasRemote then return false end
		local initRefs, shared, initRemote = uprefs(candidate.map.Init), {}, false
		if not initRefs then return false end
		for _, ref in ipairs(initRefs) do
			if ref.tag == 15 then shared[ref.pointer] = true end
			if remoteRef(ref) then initRemote = true end
		end
		if not initRemote then return false end
		local found
		for _, ref in ipairs(refs) do
			if ref.tag == 15 and shared[ref.pointer] and stateMap(cellMap(ref.pointer)) then
				if found and found ~= ref.pointer then return false end
				found = ref.pointer
			end
		end
		if not found then return false end
		holder, stateCell, modulePointer = open, found, candidate.pointer
		return true
	end
	local function discover()
		if scanned or type(scan) ~= "function" or not remote or remote.ClassName ~= "RemoteEvent" then return end
		scanned = true
		local ok, rows = pcall(scan, "Started", { Started = "boolean", Init = "function", Open = "function", Destroy = "function" })
		if not ok or type(rows) ~= "table" then return end
		local seen, examined = {}, 0
		for _, row in ipairs(rows) do
			if (row.vtt == 1 or row.type == "boolean") and pointer(row.tbl) and not seen[row.tbl] then
				seen[row.tbl], examined = true, examined + 1
				if examined > 64 then break end
				for _, field in ipairs(rowsAt(row.tbl, 64) or {}) do
					if field.key == "Open" and pointer(field.addr) and memory("int", field.addr + 12) == 7 and locate(memory("uintptr", field.addr)) then return end
				end
			end
		end
	end
	return function(): (any, string)
		discover()
		if not holder then return nil, "Waiting for the native ELIMINATIONS app to initialize" end
		local owner = nativeMap(modulePointer)
		if not owner or owner.Started ~= true or owner.Open ~= holder then return nil, "Waiting for the native phone app to recover" end
		local map = cellMap(stateCell)
		if not stateMap(map) then return nil, "Waiting for a readable native elimination snapshot" end
		return map, "Native phone snapshot"
	end
end

_G.StandOutParts.PhoneEliminations = function(ctx: any): any
	local player, clock = ctx.player, ctx.now or tick
	local players, remote = ctx.players or game:GetService("Players"), phoneRemote(ctx)
	local readSnapshot = ctx.readPhoneSnapshot or _G.StandOutParts.PhoneSnapshotReader(ctx)
	local cached, nextRead, nextSync, pendingUntil, active = {}, -math.huge, 0, 0, nil
	local snapshot, snapshotMessage, authoritative, status = nil, nil, false, "Waiting for a native phone elimination contract"
	local packetCache, packetMessage, packetAt = nil, nil, -math.huge
	local module = {}
	local function attr(parent: any, name: string): any return parent and (ctx.attr and ctx.attr(parent, name) or parent:GetAttribute(name)) or nil end
	local function userId(value: any): boolean return phoneInteger(value, 1, 9007199254740991) end
	local function say(message: string)
		status = message
		if ctx.setStatus then ctx.setStatus("PhoneEliminations", message) end
	end
	local function collect()
		if clock() < nextRead then return end
		nextRead, cached = clock() + 0.2, {}
		local users, folder = {}, phoneChild(ctx.world, "Players")
		for _, user in ipairs(players:GetPlayers()) do
			local character = user.Character
			if character and character.Address then users[character.Address] = true end
		end
		for _, model in ipairs(folder and folder:GetChildren() or {}) do
			if model.ClassName == "Model" and not users[model.Address] and attr(model, "PlayerBountyOwner") == player.UserId then
				local config, level = attr(model, "Config"), attr(model, "PlayerBountyLevel")
				if attr(model, "FightableNPC") == true and type(config) == "string" and config ~= "" and phoneFinite(level) and level > 0 then
					cached[#cached + 1] = { Type = "NPC", Id = model.Name, Config = config, OwnerUserId = player.UserId, Level = level,
						Model = model, Root = phoneChild(model, "HumanoidRootPart"), Humanoid = phoneChild(model, "Humanoid"), Address = model.Address }
				end
			end
		end
	end
	local function readable(target: any): boolean
		return target.Model and target.Model.Parent ~= nil and target.Root and target.Root.Parent ~= nil
			and target.Humanoid and target.Humanoid.Parent ~= nil and target.Root.Parent.Address == target.Model.Address
			and target.Humanoid.Parent.Address == target.Model.Address and phoneFinite(target.Humanoid.Health) and phonePosition(target.Root.Position)
	end
	local function currentNPC(candidate: any): boolean
		return candidate.Model.Parent ~= nil and attr(candidate.Model, "PlayerBountyOwner") == player.UserId
			and attr(candidate.Model, "FightableNPC") == true and attr(candidate.Model, "Config") == candidate.Config
			and attr(candidate.Model, "PlayerBountyLevel") == candidate.Level
	end
	local function playerTarget(id: any): any
		if not userId(id) or id == player.UserId then return nil end
		for _, user in ipairs(players:GetPlayers()) do
			if user.UserId == id then
				local model = user.Character
				return { Type = "Player", Id = id, Name = user.Name, OwnerUserId = player.UserId,
					Model = model, Root = phoneChild(model, "HumanoidRootPart"), Humanoid = phoneChild(model, "Humanoid") }
			end
		end
		return { Type = "Player", Id = id, OwnerUserId = player.UserId }
	end
	function module.Read(): (any, string)
		active, snapshot = nil, nil
		if clock() - packetAt >= 0.025 or clock() < packetAt then
			local ok, packet, message = pcall(readSnapshot)
			packetCache = ok and type(packet) == "table" and packet or nil
			packetMessage, packetAt = ok and message or "Waiting for a readable native elimination snapshot", clock()
		end
		if packetCache then snapshot, authoritative = packetCache, true else snapshotMessage = packetMessage end
		if snapshot and (snapshot.State == "Searching" or snapshot.State == "Active" or snapshot.State == "Completing") then pendingUntil = 0 end
		if not snapshot and authoritative then return nil, snapshotMessage or "Waiting for a readable native elimination snapshot" end
		if snapshot and snapshot.State ~= "Active" then
			if snapshot.State == "Searching" then return nil, "Native phone is finding an elimination target" end
			if snapshot.State == "Completing" then return nil, "Waiting for the native elimination receipt" end
			return nil, snapshot.Message or "Requesting another native phone elimination contract"
		end
		if not snapshot and attr(player, "EliminationActive") ~= true then return nil, snapshotMessage or "Waiting for a native elimination snapshot" end
		if snapshot and snapshot.Kind ~= "NPC" and snapshot.Kind ~= "Player" then return nil, "Waiting for a valid native elimination kind" end
		collect()
		if not snapshot or snapshot.Kind == "NPC" then
			local target, owned = nil, 0
			for _, candidate in ipairs(cached) do
				if currentNPC(candidate) and (not snapshot or (type(snapshot.CharacterName) == "string" and snapshot.CharacterName == candidate.Id
					and (snapshot.Level == nil or snapshot.Level == candidate.Level))) then owned, target = owned + 1, candidate end
			end
			if owned > 1 then return nil, "Waiting for an unambiguous owned NPC elimination target" end
			if target then
				active = target
				if not readable(target) then target.Root, target.Humanoid = phoneChild(target.Model, "HumanoidRootPart"), phoneChild(target.Model, "Humanoid") end
				if not readable(target) then return target, "Waiting for the owned NPC target to stream in" end
				if target.Humanoid.Health <= 0 then return target, "Waiting for the native NPC elimination receipt" end
				return target, "Tracking owned NPC " .. target.Config
			end
			if snapshot and type(snapshot.CharacterName) == "string" and snapshot.CharacterName ~= "" then
				active = { Type = "NPC", Id = snapshot.CharacterName, OwnerUserId = player.UserId, Position = snapshot.Position, Respawning = snapshot.Respawning == true }
				return active, "Following the native position for NPC " .. snapshot.CharacterName
			end
		end
		if snapshot and snapshot.Kind == "Player" then
			local target = playerTarget(snapshot.UserId)
			if not target then return nil, "Waiting for a valid native player elimination identity" end
			target.Position, target.Respawning = snapshot.Position, snapshot.Respawning == true
			active = target
			return target, readable(target) and (target.Humanoid.Health > 0 and "Tracking phone player " .. target.Name or "Waiting for the phone target to respawn")
				or "Waiting for the phone target to stream in"
		end
		if not snapshot and ctx.readPhonePlayer then
			local id, uiMessage = ctx.readPhonePlayer()
			local target = playerTarget(id)
			if target and target.Model then active = target; return target, "Tracking verified phone player " .. target.Name end
			return nil, uiMessage or snapshotMessage or "Waiting for native player or owned NPC elimination target data"
		end
		return nil, snapshotMessage or "Waiting for native player or owned NPC elimination target data"
	end
	local function send(action: string): boolean
		if not remote or remote.ClassName ~= "RemoteEvent" then return false end
		local ok, accepted = pcall(function() return remote:FireServer(action) end)
		return ok and accepted ~= false
	end
	local function acquisitionReady(): boolean
		return snapshot ~= nil and snapshot.State ~= "Active" and snapshot.State ~= "Searching" and snapshot.State ~= "Completing"
			and clock() >= pendingUntil and remote ~= nil and remote.ClassName == "RemoteEvent"
	end
	function module.Ready(): boolean
		if not ctx.getSetting("PhoneEliminations") then return false end
		local target, message = module.Read()
		say(message)
		return target ~= nil or acquisitionReady()
	end
	function module.Step(): string
		if not ctx.getSetting("PhoneEliminations") then module.Stop(); return "disabled" end
		local target, message = module.Read()
		if clock() >= nextSync then nextSync = clock() + 5; send("Sync") end
		if not target then
			if acquisitionReady() and send("Start") then pendingUntil = clock() + 5; message = "Requested a native phone elimination contract" end
			say(message)
			return "waiting"
		end
		if not readable(target) then
			if target.Respawning ~= true and phonePosition(target.Position) and ctx.move then ctx.move(target.Position + Vector3.new(0, 3, 0)) end
			say(message)
			return "waiting"
		end
		if target.Humanoid.Health <= 0 then say(message); return "waiting" end
		if target.Type == "NPC" and not currentNPC(target) then active = nil; say("Waiting for current owned NPC authority"); return "waiting" end
		local result = ctx.fight(target.Model)
		say(message .. ": " .. tostring(result or "fighting"))
		return "busy"
	end
	function module.Busy(): boolean
		if not ctx.getSetting("PhoneEliminations") then return false end
		local target = module.Read()
		return target ~= nil and readable(target) and target.Humanoid.Health > 0
	end
	function module.Stop() active, packetCache, packetAt = nil, nil, -math.huge; if ctx.releaseAll then ctx.releaseAll() end end
	function module.Status(): string return status end
	return module
end

_G.StandOutParts = _G.StandOutParts or {}

_G.StandOutParts.Rafts = function(ctx)
	local module = { Available = true, Status = "Waiting for scrap platforms", Metrics = { HeavyAttempts = 0, BrokenPieces = 0, LootAttempts = 0, LootRemoved = 0, Rewards = 0, TargetsCleared = 0 } }
	local now, lastCollect, targets, retryAfter, suppressed = ctx.now or tick, -math.huge, {}, {}, {}
	local job, lastHeavy, lastMove, lastSummon = nil, -math.huge, -math.huge, -math.huge
	local function child(parent, name) return parent and parent:FindFirstChild(name) end
	local function live(object) return object ~= nil and object.Parent ~= nil end
	local function attr(object, name) return object and ctx.attr(object, name) end
	local function position(point)
		return point ~= nil and type(point.X) == "number" and type(point.Y) == "number" and type(point.Z) == "number"
			and point.X == point.X and point.Y == point.Y and point.Z == point.Z
			and math.abs(point.X) < 100000 and math.abs(point.Y) < 100000 and math.abs(point.Z) < 100000
	end
	local function part(object)
		local class = object and object.ClassName
		return class == "Part" or class == "MeshPart" or class == "UnionOperation" or class == "WedgePart"
	end
	local function protected(object)
		return attr(object, "NoDestruction") == true or attr(object, "Indestructible") == true or attr(object, "Destroyed") == true
	end
	local function report(message)
		if module.Status ~= message then module.Status = message; ctx.setStatus("Rafts", message) end
	end
	local function busy(value) return value ~= nil and value ~= false and value ~= "" end
	local function blocked()
		local root, _, character = ctx.getRoot()
		local paused = not root or not position(root.Position) or attr(character, "Stunned") == true or attr(ctx.world.Parent, "TimeScale") == 0
			or busy(attr(ctx.player, "DialogueInputLocked")) or busy(attr(ctx.player, "QTEInputLocked"))
			or busy(attr(ctx.player, "GardeningInputLocked")) or busy(attr(ctx.player, "GrowingInputOwner"))
			or busy(attr(ctx.player, "GardenEffectInputLocked")) or busy(attr(ctx.player, "KaraokeInputLocked"))
			or busy(attr(ctx.player, "TabletopInputOwner"))
		return paused, root, character
	end
	local function describe(model, platform)
		if model.ClassName ~= "Model" or model.Name ~= "DebrisPiece" or protected(model) or suppressed[model.Address] then return nil end
		local pieces, anchor = {}, nil
		for _, object in ipairs(model:GetChildren()) do
			if part(object) and position(object.Position) then
				if object.Name == "Destructable" and not protected(object) then pieces[#pieces + 1] = object end
				if object.Name == "SFX" then anchor = object end
			end
		end
		if #pieces == 0 then return nil end
		return { model = model, platform = platform, base = anchor or pieces[1], pieces = pieces, visual = attr(model, "VisualOnly") == true, shadows = {} }
	end
	local function eligible(target)
		local modelParent = target.model and target.model.Parent
		if not modelParent or not live(target.platform) or not live(target.base) or protected(target.model) or protected(target.platform) then return false end
		if modelParent.Address ~= target.platform.Address or not position(target.base.Position) then return false end
		for _, object in ipairs(target.pieces) do
			local parent = object.Parent
			if parent and parent.Address == target.model.Address and not protected(object) then return true end
		end
		return false
	end
	local function broken(target)
		if not live(target.model) or not live(target.platform) then return true end
		for _, object in ipairs(target.model:GetChildren()) do
			if part(object) and object.Name == "Destructable" then return false end
		end
		return true
	end
	local function deckTop(target)
		local best, distance = nil, math.huge
		local baseSize = target.base.Size
		local clearance = position(baseSize) and math.max(baseSize.X, baseSize.Z) / 2 + 1.5 or 3
		for _, object in ipairs(target.platform:GetChildren()) do
			if part(object) and object.Name == "Destructable" and not protected(object) and object.CanCollide ~= false then
				local size, frame = object.Size, object.CFrame
				if position(object.Position) and position(size) and size.X > 0 and size.Y > 0 and size.Z > 0 and frame
					and position(frame.RightVector) and position(frame.UpVector) and position(frame.LookVector) then
					local height = (math.abs(frame.RightVector.Y) * size.X + math.abs(frame.UpVector.Y) * size.Y + math.abs(frame.LookVector.Y) * size.Z) / 2
					local point = object.Position + Vector3.new(0, height, 0)
					local offset = Vector3.new(point.X - target.base.Position.X, 0, point.Z - target.base.Position.Z).Magnitude
					if position(point) and (target.base.Position.Y <= point.Y + 0.5 or offset >= clearance)
						and (not best or point.Y > best.Y + 0.25 or math.abs(point.Y - best.Y) <= 0.25 and offset < distance) then
						best, distance = point, offset
					end
				end
			end
		end
		return best
	end
	local function nearbyCharacter(target)
		local root, _, character = ctx.getRoot()
		return root and character and character.Address == target.characterAddress and position(root.Position)
			and (root.Position - target.point).Magnitude <= 20
	end
	local function collect()
		if now() - lastCollect < 0.2 then return end
		lastCollect, targets = now(), {}
		local map = child(ctx.world, "Map")
		if not map then return end
		for _, platform in ipairs(map:GetChildren()) do
			if platform.ClassName == "Model" and platform.Name == "ScrapPlatform" and not protected(platform) then
				local pieces = {}
				for _, model in ipairs(platform:GetChildren()) do
					local target = describe(model, platform)
					if target then pieces[#pieces + 1] = target end
				end
				for _, target in ipairs(pieces) do
					local counterpart = nil
					if target.visual then
						for _, other in ipairs(pieces) do
							if not other.visual and (other.base.Position - target.base.Position).Magnitude <= 2 then counterpart = other; break end
						end
					end
					if counterpart then counterpart.shadows[#counterpart.shadows + 1] = target.model.Address
					elseif (retryAfter[target.model.Address] or 0) <= now() then targets[#targets + 1] = target end
				end
			end
		end
	end
	local function choose()
		local root, best, distance = ctx.getRoot(), nil, math.huge
		if not root or not position(root.Position) then return nil end
		for _, target in ipairs(targets) do
			if eligible(target) then
				local current = (target.base.Position - root.Position).Magnitude
				if current < distance then best, distance = target, current end
			end
		end
		return best
	end
	local function lootRoots()
		local roots = {}
		for _, entry in ipairs({ { ctx.world, "SpawnedItems" }, { ctx.world, "LootDrops" }, { ctx.world.Parent, "LootDrops" } }) do
			local folder = child(entry[1], entry[2])
			if folder and folder.ClassName == "Folder" then roots[#roots + 1] = folder end
		end
		return roots
	end
	local function baseline()
		local seen = {}
		for _, folder in ipairs(lootRoots()) do for _, model in ipairs(folder:GetChildren()) do seen[model.Address] = true end end
		return seen
	end
	local function rewardSnapshot()
		local data = child(ctx.player, "Data")
		local stats = child(data, "Stats")
		local coins, inventory = child(stats, "Coins"), child(stats, "Inventory")
		if attr(data, "Loaded") ~= true or not coins or not inventory or type(ctx.decode) ~= "function" then return nil end
		local money = coins.Value
		if type(money) ~= "number" or money ~= money or money < 0 or money == math.huge then return nil end
		local ok, entries = pcall(ctx.decode, inventory)
		if not ok or type(entries) ~= "table" then return nil end
		local items = {}
		for _, item in pairs(entries) do
			local name = type(item) == "string" and item or type(item) == "table" and item.Name
			local amount = type(item) == "table" and item.Amount
			if amount == nil then amount = 1 end
			if type(name) ~= "string" or name == "" or type(amount) ~= "number" or amount ~= amount
				or amount <= 0 or amount == math.huge or amount % 1 ~= 0 then return nil end
			items[name] = (items[name] or 0) + amount
		end
		return { coins = money, items = items }
	end
	local function belongs(object, model)
		for _ = 1, 5 do
			if not object then return false end
			if object.Address == model.Address then return true end
			object = object.Parent
		end
		return false
	end
	local function lootEligible(target)
		local owner = attr(target.model, "OwnerUserId")
		local parent = target.model and target.model.Parent
		return parent ~= nil and live(target.base) and live(target.prompt) and position(target.base.Position)
			and parent.Address == target.folder.Address and attr(target.model, "ItemName") == target.item
			and (owner == nil or owner == 0 or owner == ctx.player.UserId) and target.prompt.Name == "WorldItemPickup"
			and belongs(target.base, target.model) and belongs(target.prompt, target.model)
			and attr(target.prompt, "StoryPromptAvailable") ~= false and (target.base.Position - job.point).Magnitude <= 30
	end
	local function findLoot()
		for _, folder in ipairs(lootRoots()) do
			for _, model in ipairs(folder:GetChildren()) do
			local item, owner = attr(model, "ItemName"), attr(model, "OwnerUserId")
			if model.ClassName == "Model" and not job.baseline[model.Address] and not job.collected[model.Address]
				and type(item) == "string" and item ~= "" and (owner == nil or owner == 0 or owner == ctx.player.UserId) then
				for _, prompt in ipairs(ctx.findPrompts(model)) do
					if prompt.ClassName == "ProximityPrompt" and prompt.Name == "WorldItemPickup" then
						local base = prompt.Parent
						if base and base.ClassName == "Attachment" then base = base.Parent end
						local target = { model = model, base = base, prompt = prompt, folder = folder, item = item }
						if part(base) and lootEligible(target) then return target end
					end
				end
			end
		end
		end
		return nil
	end
	local function finish(message, completed)
		ctx.releaseAll()
		if job then retryAfter[job.model.Address] = now() + (completed and 0.2 or 10) end
		if completed then module.Metrics.TargetsCleared = module.Metrics.TargetsCleared + 1 end
		job, lastCollect = nil, -math.huge
		report(message)
	end
	function module.Stop()
		if job then finish("Stopped", false) end
	end
	function module.Busy() return job ~= nil and ctx.getSetting("AutoRafts") == true end
	function module.Breaking() return job ~= nil and job.phase == "breaking" and ctx.getSetting("AutoRafts") == true end
	function module.Ready()
		if not ctx.getSetting("AutoRafts") then module.Stop(); return false end
		local paused, root, character = blocked()
		if job and (not root or not character or character.Address ~= job.characterAddress) then
			finish("Raft farm interrupted by character change or death", false)
			return false
		end
		if paused then ctx.releaseAll(); report("Raft farm paused by the current interaction"); return false end
		if job then return true end
		collect()
		if choose() then return true end
		report("Waiting for scrap platforms")
		return false
	end
	function module.Step()
		if not module.Ready() then return "waiting" end
		if not job then
			job = choose()
			local _, _, character = ctx.getRoot()
			if not job or not character or type(character.Address) ~= "number" or character.Address <= 0 then job = nil; return "waiting" end
			job.characterAddress = character.Address
			job.phase, job.deadline, job.point = "breaking", now() + 35, job.base.Position
			job.baseline, job.collected, job.confirmed = baseline(), {}, 0
		end
		if job.phase == "breaking" then
			if not eligible(job) then
				if not job.attempted or not broken(job) or not nearbyCharacter(job) then finish("Raft changed without a confirmed break", false); return "waiting" end
				for _, address in ipairs(job.shadows) do suppressed[address] = true end
				module.Metrics.BrokenPieces = module.Metrics.BrokenPieces + 1
				job.phase, job.deadline = "loot", now() + 1
				ctx.releaseAll()
				report("Raft piece cleared; waiting for native loot drops")
				return "busy"
			end
			if now() > job.deadline then finish("Heavy attacks timed out without a confirmed break", false); return "blocked" end
			local root, _, character = ctx.getRoot()
			if not root or not character or character.Address ~= job.characterAddress then finish("Raft farm interrupted by character change or death", false); return "blocked" end
			local point, rootPoint = deckTop(job), root.Position
			if not point then finish("Raft deck changed before approach", false); return "blocked" end
			local approach = point + Vector3.new(0, 3, 0)
			local toward = Vector3.new(point.X - rootPoint.X, 0, point.Z - rootPoint.Z)
			local facing = root.CFrame and root.CFrame.LookVector
			local aligned = toward.Magnitude <= 1.5 or facing and facing:Dot(toward.Unit) >= 0.97
			if (point - rootPoint).Magnitude > 6 or rootPoint.Y < point.Y + 1.5 or not aligned then
				if now() - lastMove >= 0.2 then ctx.move(approach, job.point); lastMove = now() end
				report("Approaching scrap debris")
				return "busy"
			end
			if ctx.getSetting("AutoSummon") and attr(character, "Summoned") ~= true then
				if now() - lastSummon >= 2 and ctx.tap(ctx.bind("Summon", "E")) then lastSummon = now() end
				report("Summoning before the heavy attack")
				return "busy"
			end
			local active = child(child(ctx.player, "Data"), "SkillActive")
			local value = active and active.Value
			if value ~= nil and value ~= "" and value ~= false then report("Waiting for the active skill"); return "busy" end
			if ctx.prepareRaftAttack and not ctx.prepareRaftAttack(character) then report("Putting umbrella away before the heavy attack"); return "busy" end
			if now() - lastHeavy >= 2 then
				local seen = not job.attempted and baseline() or nil
				local reward = not job.attempted and rewardSnapshot() or nil
				local sent = ctx.tap(ctx.bind("Heavy", "R"))
				lastHeavy = now()
				if sent then
					if seen then job.baseline = seen end
					if reward then job.rewardBefore = reward end
					job.attempted = true
					module.Metrics.HeavyAttempts = module.Metrics.HeavyAttempts + 1
				end
			end
			report("Breaking scrap debris with heavy attacks")
			return "busy"
		end
		if job.rewardBefore and not job.rewardConfirmed and now() >= (job.rewardReadAt or 0) and nearbyCharacter(job) then
			job.rewardReadAt = now() + 0.2
			local current = rewardSnapshot()
			if current then
				local gained = {}
				for name, amount in pairs(current.items) do
					local delta = amount - (job.rewardBefore.items[name] or 0)
					if delta > 0 then gained[name] = delta end
				end
				local coins = math.max(0, current.coins - job.rewardBefore.coins)
				if coins > 0 or next(gained) then
					-- Ocean scrap can award inventory directly instead of spawning a pickup.
					job.rewardConfirmed, job.confirmed, job.quietUntil = true, job.confirmed + 1, now() + 0.2
					module.Metrics.Rewards = module.Metrics.Rewards + 1
					module.LastReward = { at = now(), coins = coins, items = gained, platform = job.platform.Address }
				end
			end
		end
		local target = job.loot
		if target then
			if not live(target.model) then
				if target.attempted then
					job.collected[target.model.Address], job.confirmed = true, job.confirmed + 1
					module.Metrics.LootRemoved = module.Metrics.LootRemoved + 1
					job.quietUntil, job.deadline = now() + 0.2, now() + 12
				end
				job.loot = nil
			elseif not lootEligible(target) then finish("Raft loot changed before pickup confirmation", false); return "blocked"
			elseif now() > target.deadline then finish("Raft pickup timed out without confirmation", false); return "blocked"
			else
				local root, _, character = ctx.getRoot()
				if not root or not character or character.Address ~= job.characterAddress then finish("Raft farm interrupted by character change or death", false); return "blocked" end
				if (root.Position - target.base.Position).Magnitude > 6 then
					if now() - lastMove >= 0.2 then ctx.move(target.base.Position + Vector3.new(0, 2.5, 2)); lastMove = now() end
				elseif not target.triggered then
					local result = ctx.interact(target.prompt)
					if result == "triggered" then target.attempted, target.triggered = true, true; module.Metrics.LootAttempts = module.Metrics.LootAttempts + 1 end
				end
				report("Waiting for " .. target.item .. " pickup removal")
				return "busy"
			end
		end
		job.loot = findLoot()
		if job.loot then job.loot.deadline = now() + 8; return "busy" end
		if job.confirmed > 0 and now() >= (job.quietUntil or 0) then finish(job.rewardConfirmed and "Raft reward saved to inventory" or "Raft loot removed after pickup", true); return "done" end
		if now() > job.deadline then finish("Raft cleared without a confirmed native loot drop", false); return "blocked" end
		report("Waiting for native raft loot to spawn")
		return "busy"
	end
	return module
end

do
local function startStandOut()
	if _G.StandOut and _G.StandOut.Stop then
		_G.StandOut.Stop()
	end
	assert(game.PlaceId == 128828638194450, "Stand Out: this place is not STAND OUT")
	assert(type(Drawing) == "table" and type(keypress) == "function", "Stand Out: Matcha bindings required")
	local rgb, v2, v3, lookAt = Color3.fromRGB, Vector2.new, Vector3.new, CFrame.lookAt
	assert(_G.StandOutParts and type(_G.StandOutParts.Library) == "function", "Stand Out UI factory missing")
	_G.StandOutParts.Library()
	local library = _G.Library
	assert(library and library.IsMatcha, "lazyhub Matcha backend did not load")
	local players, runService, http, lighting = game:GetService("Players"), game:GetService("RunService"), game:GetService("HttpService"), game:GetService("Lighting")
	local player = players.LocalPlayer
	local world = game.Workspace:FindFirstChild("Game")
	assert(player and world, "Stand Out: game is still loading")
	local water = _G.StandOutParts.Water()
	local runtime: any = {
		Running = true, Settings = {}, Status = {}, Controllers = {}, Errors = {},
		Metrics = { PositionWrites = 0 },
	}
	_G.StandOut = runtime
	local settings, statuses = runtime.Settings, runtime.Status
	local keys: any, collision: any, connections: any = {}, {}, {}
	local drawings: any, targets: any, prompts: any = {}, {}, {}
	local snapshot: any = { mobs = {}, bosses = {}, users = {}, quests = {} }
	local currentJob: any, interaction: any = nil, nil
	local flyPoint, flyAt, flyVelocityY, flyGravity, flyAddress = nil, 0, nil, 196.2, nil
	local speedOverride: any = nil
	local lastMove, lastLight, lastHeavy, lastSkill, lastSummon, lastAimCamera = 0, 0, 0, 0, 0, 0
	local nextSkill = 1
	local lastUmbrella, lastInventoryClose, lastClick, jumpWasDown, umbrellaRequestClosing = 0, 0, 0, false, nil
	local lastJumpVelocityY, highJumpUntil, highJumpReady = nil, 0, false
	local phoneMissingAt: number? = nil
	local focusAt, focusAddress = 0, 0
	local worldFocus: any = nil
	local mouseTarget: any = nil
	local pointerInside
	local characterAddress = 0
	local aimTarget, aimHumanoid, aimOffset, aimUpdated, aimCameraNeeded, aimAllowed = nil, nil, v3(0, 0, 0), 0, false, false
	local function uiReady(): boolean
		return runtime.Running and not library.Unloaded and library.LastRenderError == nil and library.RenderCount > 0
	end
	local keyNames = {
		Space = 32, Return = 13, Enter = 13, Backspace = 8, Tab = 9, Escape = 27,
		LeftShift = 160, RightShift = 161, LeftControl = 162, RightControl = 163,
		Left = 37, Right = 39, Up = 38, Down = 40,
		One = 49, Two = 50, Three = 51, Four = 52, Five = 53,
		Six = 54, Seven = 55, Eight = 56, Nine = 57, Zero = 48,
	}
	local inputLocks = {
		"DialogueInputLocked", "QTEInputLocked", "KaraokeInputLocked",
		"GardeningInputLocked", "GrowingInputOwner", "GardenEffectInputLocked", "JewelryInspecting",
		"TabletopInputOwner", "PhoneInputLocked", "StoryCinematic",
		"SettingsInputLocked", "QuickUseInventoryOpen",
	}
	local function child(node: any, name: string): any return node and node:FindFirstChild(name) or nil end
	local function attr(node: any, name: string): any
		if not node then
			return nil
		end
		local ok, value = pcall(function()
			return node:GetAttribute(name)
		end)
		if ok then
			return value
		end
		return nil
	end
	local function value(node: any): any return node and node.Value or nil end
	local function finite(n: any): boolean
		return type(n) == "number" and n == n and math.abs(n) < 10000000
	end
	local function validPosition(p: any): boolean
		return p ~= nil and finite(p.X) and finite(p.Y) and finite(p.Z)
	end
	local function getRoot(): any
		local character = player.Character
		local root = child(character, "HumanoidRootPart") or child(character, "Core")
		local humanoid = child(character, "Humanoid")
		if root and humanoid and finite(humanoid.Health) and humanoid.Health > 0 and validPosition(root.Position) then
			return root, humanoid, character
		end
		return nil
	end
	local function position(node: any): any
		for _ = 1, 7 do
			if not node then
				break
			end
			local class = node.ClassName
			if class == "Part" or class == "MeshPart" or class == "UnionOperation" or class == "Seat" or class == "VehicleSeat" then
				return node.Position
			end
			if class == "Model" then
				local part = child(node, "HumanoidRootPart")
					or node.PrimaryPart
					or child(node, "Head")
					or child(node, "Handle")
				if part then
					return part.Position
				end
			end
			node = node.Parent
		end
		return nil
	end
	local function bind(name: string, fallback: any): any
		local data = child(player, "Data")
		local binds = child(child(data, "Settings"), "Keybinds")
		local text = value(child(binds, name))
		if type(text) ~= "string" then
			text = fallback
		end
		if type(text) == "number" then
			return text
		end
		text = tostring(text):gsub("Enum.KeyCode%.", "")
		if keyNames[text] then
			return keyNames[text]
		end
		if #text == 1 then
			return string.byte(string.upper(text))
		end
		return nil
	end
	local function release(vk: number)
		if keys[vk] then
			if vk == 1 then
				mouse1release()
			elseif vk == 2 then
				mouse2release()
			else
				keyrelease(vk)
			end
			keys[vk] = nil
		end
	end
	local function releaseAll()
		local list = {}
		for vk in pairs(keys) do
			list[#list + 1] = vk
		end
		for _, vk in ipairs(list) do
			release(vk)
		end
	end
	local function hold(vk: any): boolean
		if type(vk) ~= "number" or vk < 1 or vk > 255 or not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive() then
			return false
		end
		if vk == 1 or vk == 2 then
			local mouse = player:GetMouse()
			if not mouse or not pointerInside(mouse.X, mouse.Y) then release(vk); return false end
		end
		-- Matcha can close the native input gate between actions.
		if type(setrobloxinput) == "function" then setrobloxinput(true) end
		if not keys[vk] then
			if vk == 1 then
				mouse1press()
			elseif vk == 2 then
				mouse2press()
			else
				keypress(vk)
			end
		end
		keys[vk] = tick() + 0.45
		return true
	end
	local function tap(vk: any): boolean
		if keys[vk] or not hold(vk) then
			return false
		end
		keys[vk] = tick() + 0.08
		return true
	end
	local function setStatus(name: string, text: string)
		statuses[name] = text
	end
	local function move(p: any, target: any?): boolean
		if not uiReady() then
			return false
		end
		local root, _, character = getRoot()
		if not root or not validPosition(p) or attr(character, "Stunned") or attr(game.Workspace, "TimeScale") == 0 then
			return false
		end
		if currentJob and currentJob.seated and currentJob.seated() then return false end
		if currentJob and currentJob.carrying and currentJob.carrying() then
			local delta = p - root.Position
			if delta.Magnitude > 6 then p = root.Position + delta.Unit * 6 end
		end
		local now = tick()
		if now - lastMove < 0.2 or (root.Position - p).Magnitude < 1.5 then
			return false
		end
		lastMove = now
		local facing = validPosition(target) and v3(target.X, p.Y, target.Z) or nil
		root.CFrame = facing and (facing - p).Magnitude > 0.01 and lookAt(p, facing) or CFrame.new(p.X, p.Y, p.Z)
		runtime.Metrics.PositionWrites = runtime.Metrics.PositionWrites + 1
		return true
	end
	pointerInside = function(x: number, y: number, margin: number?): boolean
		local camera = game.Workspace.Camera
		local viewport = camera and camera.ViewportSize
		margin = margin or 0
		return viewport ~= nil and finite(viewport.X) and finite(viewport.Y) and viewport.X > margin * 2 and viewport.Y > margin * 2
			and finite(x) and finite(y) and x >= margin and y >= margin and x < viewport.X - margin and y < viewport.Y - margin
	end
	local function mouseMove(x: number, y: number, owner: any, screen: boolean?)
		if not uiReady() or not isrbxactive() or library.Visible or library.MouseCaptured or not finite(x) or not finite(y) then return false end
		if not pointerInside(x, y) then mouseTarget = nil; return false end
		if type(setrobloxinput) == "function" then setrobloxinput(true) end
		if mouseTarget then mouseTarget.owner = owner end
		if mouseTarget and math.abs(mouseTarget.x - x) <= 2 and math.abs(mouseTarget.y - y) <= 2 then
			if mouseTarget.ready then
				local mouse = player:GetMouse()
				if pointerInside(mouse.X, mouse.Y) and math.abs(mouse.X - x) <= 2 and math.abs(mouse.Y - y) <= 2 then return true end
				mouseTarget.ready, mouseTarget.sentAt = false, nil
			end
			return false
		end
		if mouseTarget then
			if mouseTarget.ready then mouseTarget.sentAt = nil end
			mouseTarget.x, mouseTarget.y, mouseTarget.ready, mouseTarget.attempts, mouseTarget.retryAt = x, y, false, 0, nil
		else
			mouseTarget = {x = x, y = y, attempts = 0, owner = owner}
		end
		return false
	end
	local function pollMouse()
		local target, now = mouseTarget, tick()
		if not target then return end
		if not uiReady() or not isrbxactive() or library.Visible or library.MouseCaptured then mouseTarget = nil; release(1); release(2); return end
		if not pointerInside(target.x, target.y) then mouseTarget = nil; release(1); release(2); return end
		local mouse = player:GetMouse()
		if not finite(mouse.X) or not finite(mouse.Y) then target.ready = false; release(1); release(2); return end
		if not pointerInside(mouse.X, mouse.Y) then release(1); release(2) end
		if target.sentAt then
			local elapsed = now - target.sentAt
			if elapsed < 0.04 or elapsed < 0.2 and math.abs(mouse.X - target.fromX) < 0.5 and math.abs(mouse.Y - target.fromY) < 0.5 then return end
			target.sentAt = nil
		end
		target.ready = pointerInside(mouse.X, mouse.Y) and math.abs(mouse.X - target.x) <= 2 and math.abs(mouse.Y - target.y) <= 2
		if target.ready or now < (target.retryAt or 0) then return end
		-- GetMouse is relative to the current Roblox window; absolute input targets the primary desktop.
		local dx, dy = math.floor(target.x - mouse.X + 0.5), math.floor(target.y - mouse.Y + 0.5)
		target.fromX, target.fromY, target.sentAt = mouse.X, mouse.Y, now
		if type(setrobloxinput) == "function" then setrobloxinput(true) end
		mousemoverel(dx, dy)
		target.attempts += 1
		if target.attempts >= 3 then target.attempts, target.retryAt = 0, now + 0.5 end
	end

	local function clearWorldFocus()
		if not worldFocus then return end
		worldFocus = nil
		if mouseTarget and mouseTarget.owner == "GardenWork" then mouseTarget = nil end
		release(2)
	end
	local function dragCamera(point: any, horizontalOnly: boolean?)
		if not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive() then release(2); return end
		local camera, now = game.Workspace.Camera, tick()
		local frame = camera and camera.CFrame
		if not validPosition(point) or not frame or not validPosition(frame.Position) or not validPosition(frame.LookVector)
			or not validPosition(frame.RightVector) or not validPosition(frame.UpVector) then release(2); return end
		local direction = point - frame.Position
		if direction.Magnitude <= 0.01 then release(2); return end
		if now - lastAimCamera < 0.016 then return end
		local mouse, viewport = player:GetMouse(), camera.ViewportSize
		if not pointerInside(mouse.X, mouse.Y) then mouseTarget = nil; release(2); return end
		if not pointerInside(mouse.X, mouse.Y, 24) then
			release(2)
			if not mouseMove(viewport.X / 2, viewport.Y / 2) then return end
			mouse = player:GetMouse()
			if not pointerInside(mouse.X, mouse.Y, 24) then return end
		end
		local right, forward, up = direction:Dot(frame.RightVector), direction:Dot(frame.LookVector), direction:Dot(frame.UpVector)
		local yaw, pitch = math.atan2(right, forward), -math.atan2(up, math.sqrt(right * right + forward * forward))
		if horizontalOnly then
			yaw = math.atan2(direction.X * frame.RightVector.X + direction.Z * frame.RightVector.Z,
				direction.X * frame.LookVector.X + direction.Z * frame.LookVector.Z)
			pitch = 0
		end
		local x = math.clamp(math.clamp(yaw * 1200, -480, 480), 8 - mouse.X, viewport.X - 9 - mouse.X)
		local y = math.clamp(math.clamp(pitch * 1200, -360, 360), 8 - mouse.Y, viewport.Y - 9 - mouse.Y)
		if hold(2) then mouseTarget = nil; mousemoverel(x, y); lastAimCamera = now end
	end
	local function renderWorldFocus()
		local focus, now = worldFocus, tick()
		if not focus then return end
		local camera = game.Workspace.Camera
		local cameraOwner = attr(camera, "GrowingCameraOwner")
		local tabletopOwner = attr(player, "TabletopInputOwner")
		if not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive() or not focus.target.Parent or not focus.part.Parent
			or now - focus.requested > 1.5 or attr(player, "GardeningInputLocked") == true
			or (tabletopOwner ~= nil and tabletopOwner ~= false and tabletopOwner ~= "")
			or (cameraOwner ~= nil and cameraOwner ~= false and cameraOwner ~= "") then clearWorldFocus(); return end
		local point = focus.part.Position
		if not validPosition(point) then clearWorldFocus(); return end
		local frame = camera.CFrame
		if focus.frame and ((frame.Position - focus.frame.Position).Magnitude > 0.25
			or frame.LookVector:Dot(focus.frame.LookVector) < 0.9998
			or (point - focus.point).Magnitude > 0.25) then focus.readyAt = nil end
		local screen, visible = WorldToScreen(point)
		focus.frame, focus.point, focus.at, focus.visible = frame, point, now, visible and screen ~= nil and finite(screen.X) and finite(screen.Y)
		if focus.turning then
			local direction = point - frame.Position
			if direction.Magnitude > 0.01 and (not focus.visible or focus.centerActor and direction.Unit:Dot(frame.LookVector) < 0.999) then
				dragCamera(point, not focus.interactionCamera)
				return
			end
			focus.turning, focus.adjusting = false, false
		end
		if focus.tilting then
			if frame.LookVector.Y > -0.9 then dragCamera(frame.Position + v3(0,-30,0)); return end
			focus.tilting, focus.adjusting = false, false
		end
		if focus.visible then focus.x, focus.y = screen.X, screen.Y; if not focus.adjusting then release(2) end end
		if focus.visible and (focus.interactionCamera == false or focus.adjusting == false) then
			release(2)
			focus.adjusting = false
			mouseMove(focus.x, focus.y, "GardenWork", true)
		end
	end
	local function focusPrompt(target: any, interactionCamera: boolean?): boolean
		if not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive() then clearWorldFocus(); return false end
		local camera = game.Workspace.Camera
		local cameraOwner = attr(camera, "GrowingCameraOwner")
		local tabletopOwner = attr(player, "TabletopInputOwner")
		if attr(player, "GardeningInputLocked") == true or (cameraOwner ~= nil and cameraOwner ~= false and cameraOwner ~= "")
			or (tabletopOwner ~= nil and tabletopOwner ~= false and tabletopOwner ~= "") then clearWorldFocus(); return true end
		local root = getRoot()
		if not target or not target.Parent or not root then clearWorldFocus(); return false end
		local focus, now = worldFocus, tick()
		if not focus or focus.address ~= target.Address or not focus.part.Parent then
			clearWorldFocus()
			local class = target.ClassName
			local physical = class == "Part" or class == "MeshPart" or class == "UnionOperation" or class == "Seat" or class == "VehicleSeat"
			local part = physical and target or target.Parent
			if target.Name == "GardenWork" then
				for _ = 1, 6 do
					if not part or part.Name == "Garden Pot" then break end
					part = part.Parent
				end
				part = part and (child(part, "Dirt") or part)
			else
				for _ = 1, 6 do
					if part and part.ClassName == "Model" then
						part = child(part, "HumanoidRootPart") or part.PrimaryPart or child(part, "Root") or child(part, "Head") or child(part, "Handle")
						break
					end
					if not part or part.ClassName ~= "Attachment" and validPosition(part.Position) then break end
					part = part.Parent
				end
				if part and part.Name == "HumanoidRootPart" then
					local actor = part.Parent
					for _, name in ipairs({"Torso", "UpperTorso", "Head"}) do
						local body = child(actor, name)
						if body and validPosition(body.Position) and finite(body.Transparency) and body.Transparency < 0.95 then part = body; break end
					end
				end
				if part and finite(part.Transparency) and part.Transparency >= 0.95 and part.Parent and part.Parent.ClassName == "Model" then
					local nearest, distance = part, math.huge
					for _, body in ipairs(part.Parent:GetChildren()) do
						local class = body.ClassName
						if (class == "Part" or class == "MeshPart" or class == "UnionOperation") and validPosition(body.Position)
							and finite(body.Transparency) and body.Transparency < 0.95 then
							local d = (body.Position - part.Position).Magnitude
							if d < distance then nearest, distance = body, d end
						end
					end
					part = nearest
				end
			end
			if not part or not validPosition(part.Position) then return false end
			local name = target.Name
			worldFocus = {address=target.Address,target=target,part=part,requested=now,at=0,visible=false,zooms=0,interactionCamera=interactionCamera~=false,
				overhead=settings.SupplyCameraFocus == true and (name == "GardenWork" or name == "GardenGather" or name == "WorldEventPickup" or name == "WorldItemPickup" or name == "HowlerCaseOpen")}
			return false
		end
		focus.requested = now
		focus.interactionCamera = interactionCamera ~= false
		if focus.at == 0 or now - focus.at > 0.75 then focus.readyAt=nil; return false end
		local frame = camera and camera.CFrame
		if not frame or not validPosition(frame.Position) or not validPosition(frame.LookVector) then return false end
		local point, projectedFrame = focus.part.Position, focus.frame
		if not validPosition(point) or not projectedFrame or (point - focus.point).Magnitude > 0.25
			or (frame.Position - projectedFrame.Position).Magnitude > 0.25
			or frame.LookVector:Dot(projectedFrame.LookVector) < 0.9998 then focus.readyAt=nil;return false end
		local position = root.Position
		if focus.interactionCamera and validPosition(position) and math.abs(position.Y - point.Y) < 6
			and v3(position.X - point.X, 0, position.Z - point.Z).Magnitude < 1.5 then
			release(2)
			focus.readyAt = nil
			move(point + v3(3, 2, 0))
			return false
		end
		if focus.interactionCamera and (frame.Position - focus.point).Magnitude > 18 and (focus.zoomIns or 0) < 6 then
			release(2)
			focus.adjusting, focus.readyAt = true, nil
			if now >= (focus.zoomAt or 0) then mousescroll(1);focus.zoomIns=(focus.zoomIns or 0)+1;focus.zoomAt=now+0.15 end
			return false
		end
		focus.adjusting = false
		if focus.overhead and frame.LookVector.Y > -0.5 then focus.overheadReady = false end
		if focus.overhead and not focus.overheadReady and frame.LookVector.Y > -0.9 then
			focus.adjusting,focus.readyAt,focus.tilting=true,nil,true
			dragCamera(frame.Position + v3(0,-30,0))
			return false
		end
		-- shortcut: bound zoom retries at six steps; revisit if native camera limits change.
		if focus.zooms < 6 and (focus.overhead and not focus.overheadReady and frame.Position.Y - focus.point.Y < 8
			or focus.interactionCamera and (frame.Position - focus.point).Magnitude < 6) then
			focus.adjusting,focus.readyAt=true,nil
			if now >= (focus.zoomAt or 0) then mousescroll(-1);focus.zooms+=1;focus.zoomAt=now+0.15 end
			return false
		end
		focus.overheadReady = focus.overhead
		local centerActor = target.Name == "BountyIncident_PacoPickup" or target.Name == "BountyIncident_FinishVerity" or target.Name == "BountyIncident_TalkVerity" or target.Name == "StandStorageOpen"
		if not focus.visible or focus.interactionCamera and centerActor and frame.LookVector:Dot((focus.point - frame.Position).Unit) < 0.999 then
			focus.adjusting,focus.turning,focus.centerActor=true,true,centerActor
			focus.readyAt=nil;dragCamera(focus.point, not focus.interactionCamera);return false
		end
		release(2)
		if not mouseMove(focus.x,focus.y,"GardenWork",true) then
			local mouse = player:GetMouse()
			-- Native actor animation moves while relative cursor input is acknowledged.
			if not focus.interactionCamera or not pointerInside(mouse.X, mouse.Y)
				or math.abs(mouse.X - focus.x) > 8 or math.abs(mouse.Y - focus.y) > 8 then focus.readyAt=nil;return false end
		end
		focus.readyAt=focus.readyAt or now
		return now-focus.readyAt >= 0.06
	end
	local function click(gui: any): boolean
		if not gui or tick() - lastClick < 0.1 then
			return false
		end
		local p, size = gui.AbsolutePosition, gui.AbsoluteSize
		local viewport = game.Workspace.Camera.ViewportSize
		if not p or not size then
			return false
		end
		local x, y = p.X + (size.X > 1 and size.X / 2 or 12), p.Y + (size.Y > 1 and size.Y / 2 or 10)
		if x < 0 or y < 0 or x > viewport.X or y > viewport.Y then
			return false
		end
		if not mouseMove(x, y, nil, true) then
			return false
		end
		if type(setrobloxinput) == "function" then setrobloxinput(true) end
		mouse1click()
		lastClick = tick()
		return true
	end
	local function decode(node: any, plain: boolean?): any
		local raw = type(node) == "string" and node or value(node)
		if type(raw) ~= "string" then
			return nil
		end
		if type(node) ~= "string" and #raw == 255 and node.ClassName == "StringValue" then
			if not plain then
				local ok, decoded = pcall(function() return http:JSONDecode(raw) end)
				if ok and type(decoded) == "table" then return decoded end
			end
			if type(memory_read) ~= "function" then return nil end
			local ok, full = pcall(function()
				local function integer(n, minimum, maximum)
					return type(n) == "number" and n == n and n % 1 == 0 and n >= minimum and n <= maximum
				end
				local address = node.Address
				if not integer(address, 65536, 281474976710400) then return nil end
				local pointer, length, capacity = memory_read("uintptr", address + 160), memory_read("uintptr", address + 176), memory_read("uintptr", address + 184)
				if not integer(pointer, 65536, 281474976645119) or not integer(length, #raw, 65536)
					or not integer(capacity, length, 131071) then return nil end
				local chunks = {}
				for offset = 0, length - 1, 255 do
					local chunk, size = memory_read("string", pointer + offset), math.min(255, length - offset)
					if type(chunk) ~= "string" or #chunk < size or (offset == 0 and chunk:sub(1, #raw) ~= raw) then return nil end
					chunks[#chunks + 1] = chunk:sub(1, size)
				end
				if memory_read("uintptr", address + 160) ~= pointer or memory_read("uintptr", address + 176) ~= length then return nil end
				return table.concat(chunks)
			end)
			if not ok or type(full) ~= "string" then return nil end
			raw = full
		end
		if plain then return raw end
		local ok, decoded = pcall(function()
			return http:JSONDecode(raw)
		end)
		return ok and type(decoded) == "table" and decoded or nil
	end
	local function findPrompts(root: any): any
		if not root or root.Address == world.Address then
			return {}
		end
		local key = root.Address
		local cached = prompts[key]
		if cached and tick() - cached.at < 5 then
			for i = #cached.list, 1, -1 do
				if not cached.list[i].Parent then table.remove(cached.list, i) end
			end
			local parent = root.Parent
			if #cached.list == 0 and parent and (parent.Name == "SpawnedItems" or parent.Name == "WorldEventDrops")
				and tick() - (cached.probeAt or cached.at) >= 0.2 then
				cached.probeAt = tick()
				local function add(node)
					if node.Parent and node.ClassName == "ProximityPrompt" and (node.Name == "WorldItemPickup" or node.Name == "WorldEventPickup") then
						cached.list[#cached.list + 1] = node
					end
				end
				for _, node in ipairs(root:GetChildren()) do
					add(node)
					if node.ClassName == "Part" or node.ClassName == "MeshPart" or node.ClassName == "UnionOperation" or node.ClassName == "Attachment" then
						for _, nested in ipairs(node:GetChildren()) do
							add(nested)
							if nested.ClassName == "Attachment" then
								for _, prompt in ipairs(nested:GetChildren()) do add(prompt) end
							end
						end
					end
				end
			end
			return cached.list
		end
		local list = {}
		for _, node in ipairs(root:GetDescendants()) do
			if node.ClassName == "ProximityPrompt" or node.ClassName == "ClickDetector" then
				list[#list + 1] = node
			end
		end
		prompts[key] = { at = tick(), list = list }
		return list
	end
	local function getProgress(target: any): any
		local name = attr(target, "StoryProgressGui") or "GardenHoldProgress"
		local parent = target and target.Parent
		for _ = 1, 5 do
			if not parent then
				break
			end
			local panel = parent:FindFirstChild(name, true)
			if panel then
				local fill = panel:FindFirstChild("Fill", true)
				local track = fill and fill.Parent
				if fill and track then
					local a, b = fill.AbsoluteSize, track.AbsoluteSize
					if a and b and b.X > 1 then
						return math.clamp(a.X / b.X, 0, 1)
					end
				end
			end
			parent = parent.Parent
		end
		return nil
	end
	local function holdFinished(name: string, progress: any): boolean
		return name ~= "GardenGather" and name ~= "HowlerCaseOpen" and name ~= "Karaoke" and progress ~= nil and progress >= 1
	end
	local function interact(target: any): string
		if not uiReady() then
			return "blocked"
		end
		local root = getRoot()
		local point = position(target)
		if not target or not target.Parent or not root or not validPosition(point) then
			if interaction and target and interaction.address == target.Address then release(interaction.key); interaction.done = true end
			return "blocked"
		end
		local owner = attr(target, "GardenOwnerId") or attr(target, "StoryPromptOwnerId")
		if owner and owner ~= player.UserId then
			if interaction and interaction.address == target.Address then release(interaction.key); interaction.done = true end
			return "blocked"
		end
		local actor = target.Parent.Parent
		local capturedVerity = target.Name == "BountyIncident_FinishVerity" and target.Parent.Name == "HumanoidRootPart"
			and actor and actor.Name == "Berity" and actor.Parent and actor.Parent.Name == "Incident_Verity"
			and attr(target, "BountyLeaderId") == player.UserId and attr(actor, "BountyHeldBy") == player.UserId
		-- Capturing Berity disables his prompt before the finishing hold completes.
		if attr(target, "StoryPromptAvailable") == false and not capturedVerity or attr(target, "GardenPromptBlocked") then
			if interaction and interaction.address == target.Address then release(interaction.key); interaction.done = true end
			return "blocked"
		end
		if (root.Position - point).Magnitude > 7 then
			move(point + v3(0, 2.5, 2))
			return "holding"
		end
		local panel = attr(target, "StoryProgressGui")
		local bountyTalk = target.Name == "BountyIncident_TalkVerity" and tonumber(attr(target, "BountyLeaderId")) == player.UserId
		local tapped = bountyTalk and not panel and not attr(target, "ServerInteraction")
			or target.Name == "GardenWork" or target.Name == "WorldEventPickup" or target.Name == "WorldItemPickup"
		local direct = not tapped and target.Name ~= "HowlerCaseOpen" and target.Name ~= "Karaoke" and not panel
			and (not attr(target, "BountyLeaderId") or bountyTalk) and not attr(target, "GardeningPrompt") and not attr(target, "ServerInteraction")
		local fallback = interaction and interaction.address == target.Address and interaction.nativeFallback
		if target.ClassName == "ProximityPrompt" and (not direct or fallback) and not capturedVerity and not focusPrompt(target, true) then
			if interaction then release(interaction.key) end
			release(1)
			return "holding"
		end
		local address, now = target.Address, tick()
		if interaction and interaction.address ~= address then
			release(interaction.key)
			interaction = nil
		end
		if interaction and interaction.done and now - interaction.at >= 3 then
			release(interaction.key)
			interaction = nil
		end
		if interaction and interaction.retry > 0 and now >= interaction.retry then
			release(interaction.key)
			interaction = nil
		end
		if interaction and now < interaction.retry then
			return "blocked"
		end
		if target.ClassName == "ClickDetector" then
			if interaction and now - interaction.at < 2 then
				return "triggered"
			end
			local ok = pcall(fireclickdetector, target)
			interaction = { address = address, target = target, at = now, retry = 0, key = 0, done = ok }
			return ok and "triggered" or "blocked"
		end
		if target.ClassName ~= "ProximityPrompt" then
			return "blocked"
		end
		if not interaction then
			interaction = { address = address, target = target, at = now, retry = 0, key = bind("Interactables", "H") or 72 }
			if tapped then
				if tap(interaction.key) then interaction.done = true; return "triggered" end
				interaction = nil
				return "blocked"
			end
			if direct then
				local ok = pcall(fireproximityprompt, target)
				if ok then
					interaction.done = true
					return "triggered"
				end
				interaction.nativeFallback = true
				return "holding"
			end
		end
		if interaction.done then
			return now - interaction.at < 2 and "triggered" or "blocked"
		end
		if attr(player, "DialogueInputLocked") or attr(player, "GardeningInputLocked")
			or attr(player, "TabletopInputOwner") or attr(player, "JewelryInspecting") == true or attr(player, "QTEInputLocked") == true then
			release(interaction.key)
			interaction.done = true
			return "triggered"
		end
		local progress = getProgress(target)
		if not attr(target, "BountyLeaderId") and holdFinished(target.Name, progress) then
			release(interaction.key)
			interaction.done = true
			return "triggered"
		end
		if now - interaction.at > 15 then
			release(interaction.key)
			interaction.retry = now + 10
			return "blocked"
		end
		hold(interaction.key)
		return "holding"
	end
	local function pollInteraction()
		if interaction and interaction.target and not interaction.done and interaction.retry == 0 then interact(interaction.target) end
	end
	local function locked(): (boolean, string?)
		for _, name in ipairs(inputLocks) do
			local v = attr(player, name)
			if name == "PhoneInputLocked" then
				local held = decode(attr(player.Character, "QuickUseHeldItem"))
				if v == true and not child(child(world, "Effects"), "HuberPhoneDisplay") and (not held or held.Name ~= "Phone") then
					phoneMissingAt = phoneMissingAt or tick()
					if tick() - phoneMissingAt >= 0.75 then
						pcall(function() player:SetAttribute(name, false) end)
						v = attr(player, name)
					end
				else phoneMissingAt = nil end
			end
			if v ~= nil and v ~= false and v ~= "" then
				return true, name
			end
		end
		return false
	end
	local function sunIsUp(): boolean?
		local pin = attr(lighting, "LocalClockPin")
		pin = (type(pin) == "number" or type(pin) == "string") and tonumber(pin) or nil
		if pin and pin == pin and math.abs(pin) < 1000000 then pin = pin % 24; return pin >= 6 and pin < 18 end
		if attr(game.Workspace, "LahainaNoon") == true then return nil end
		local cycle = attr(lighting, "DayCycle")
		if type(cycle) ~= "string" then return nil end
		local fields = { cycle:match("^([^,]+),([^,]+),([^,]+),([^,]+)$") }
		if #fields ~= 4 then return nil end
		for i, field in ipairs(fields) do
			local n = tonumber(field)
			if not n or n ~= n or math.abs(n) > 1000000000000 then return nil end
			fields[i] = n
		end
		if fields[4] <= 0 or type(os.time) ~= "function" then return nil end
		local hour = (fields[1] + fields[2] * math.clamp((os.time() - fields[3]) / fields[4], 0, 1)) % 24
		return hour >= 6 and hour < 18
	end
	local function umbrellaOpen(character: any): boolean
		return child(character, "HeldBlackUmbrella") ~= nil
	end
	local function openUmbrella(character: any, closing: boolean?): boolean
		if not uiReady() or not isrbxactive() then
			setStatus("AutoUmbrella", "Focus Roblox to equip the umbrella")
			return false
		end
		if closing and not umbrellaOpen(character) then
			setStatus("AutoUmbrella", "Nighttime: umbrella is put away")
			return false
		end
		if not closing and umbrellaOpen(character) then
			setStatus("AutoUmbrella", "Black Umbrella is already equipped")
			return false
		end
		local root = child(character, "HumanoidRootPart")
		if root and water.Contains(root.Position) then
			setStatus("AutoUmbrella", "In water: umbrella waits until you are on dry land")
			return false
		end
		local blocked, reason = locked()
		if blocked then
			if reason == "QuickUseInventoryOpen" then
				if tick() - lastInventoryClose >= 0.5 and tap(bind("QuickUse", "V")) then
					lastInventoryClose = tick()
					setStatus("AutoUmbrella", "Closing item inventory to equip Black Umbrella")
					return true
				end
				return false
			end
			setStatus("AutoUmbrella", reason == "PhoneInputLocked" and "Close the phone to equip the umbrella"
				or "Waiting for the game's input lock to clear")
			return false
		end
		if tick() - lastUmbrella < (umbrellaRequestClosing == (closing == true) and 3 or 0.25) then
			return false
		end
		local held = closing and decode(attr(character, "QuickUseHeldItem")) or nil
		if closing and held and (held.Name ~= "Black Umbrella" or type(held.ID) ~= "string" or held.ID == "") then
			setStatus("AutoUmbrella", "Waiting for the held Black Umbrella ID"); return false
		end
		local inventory = decode(child(child(child(player, "Data"), "Stats"), "Inventory"))
		if type(inventory) ~= "table" then setStatus("AutoUmbrella", "Waiting for current umbrella inventory"); return false end
		local entry
		for _, item in ipairs(inventory) do
			if type(item) == "table" and item.Name == "Black Umbrella" and type(item.ID) == "string" and item.ID ~= ""
				and (item.Amount == nil or (finite(item.Amount) and item.Amount > 0)) and (not closing or not held or item.ID == held.ID) then
				entry = item; break
			end
		end
		if not entry then
			setStatus("AutoUmbrella", closing and "Waiting for the held Black Umbrella in current inventory" or "Black Umbrella is missing from current inventory"); return false
		end
		local remote = child(child(game.ReplicatedStorage, "Remotes"), "Item")
		if not remote or remote.ClassName ~= "RemoteEvent" then setStatus("AutoUmbrella", "Waiting for the Item remote"); return false end
		releaseAll()
		lastUmbrella, umbrellaRequestClosing = tick(), closing == true
		local ok, result = pcall(function() return remote:FireServer("Use", entry.Name, entry.ID) end)
		if not ok or result == false then setStatus("AutoUmbrella", "Unable to use Black Umbrella: " .. tostring(result)); return false end
		setStatus("AutoUmbrella", closing and "Waiting for Black Umbrella to be put away" or "Waiting for Black Umbrella equipment confirmation")
		return true
	end
	local function protectFromSun(character: any): boolean
		if currentJob and currentJob.freeHands and currentJob.freeHands() then
			if umbrellaOpen(character) and not locked() then openUmbrella(character, true); return true end
			setStatus("AutoUmbrella", "Keeping hands free for the bounty")
			return false
		end
		if not settings.AutoUmbrella then
			return false
		end
		if currentJob and currentJob.name == "Rafts" and currentJob.breaking and currentJob.breaking() then
			if not umbrellaOpen(character) then setStatus("AutoUmbrella", "Umbrella put away for raft heavy attacks") end
			return false
		end
		if attr(character, "VampireActive") ~= true then
			setStatus("AutoUmbrella", "Waiting: this character is not a vampire")
			return false
		end
		local daylight = sunIsUp()
		if daylight == nil then setStatus("AutoUmbrella", "Waiting for the game's day/night clock"); return false end
		if not daylight then return openUmbrella(character, true) end
		if umbrellaOpen(character) then
			setStatus("AutoUmbrella", "Black Umbrella is equipped")
			return false
		end
		return openUmbrella(character)
	end
	local function aimAt(model: any)
		local root, humanoid = child(model, "HumanoidRootPart"), child(model, "Humanoid")
		if not settings.AimAssist or not root or not humanoid or not model.Parent
			or not finite(humanoid.Health) or humanoid.Health <= 0 then
			aimTarget, aimHumanoid, aimCameraNeeded = nil, nil, false
			release(2)
			if settings.AimAssist then setStatus("AimAssist", "Waiting for a live aim target") end
			return
		end
		local head = child(model, "Head")
		aimTarget, aimHumanoid, aimOffset, aimUpdated = head or root, humanoid, head and v3(0, 0, 0) or v3(0, 1.5, 0), tick()
		setStatus("AimAssist", "Tracking " .. model.Name)
	end
	local function turnAimCamera()
		if worldFocus then return end
		if not settings.AimAssist or not aimAllowed or not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive()
			or not aimCameraNeeded or not aimTarget or not aimTarget.Parent or not aimHumanoid or not finite(aimHumanoid.Health)
			or aimHumanoid.Health <= 0 or tick() - aimUpdated > 0.5 then aimCameraNeeded = false; release(2); return end
		dragCamera(aimTarget.Position + aimOffset, true)
	end
	local function renderAim()
		if worldFocus then return end
		if not settings.AimAssist or not aimAllowed or not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive()
			or not aimTarget or not aimTarget.Parent or not aimHumanoid or not finite(aimHumanoid.Health)
			or aimHumanoid.Health <= 0 or tick() - aimUpdated > 0.5 then aimCameraNeeded = false; release(2); return end
		local point = aimTarget.Position + aimOffset
		if not validPosition(point) then aimCameraNeeded = false; release(2); return end
		local screen, visible = WorldToScreen(point)
		visible = visible and screen ~= nil and pointerInside(screen.X, screen.Y)
		aimCameraNeeded = not visible
		if visible then release(2) end
		if visible and screen and finite(screen.X) and finite(screen.Y) then mouseMove(screen.X, screen.Y, nil, true) end
	end
	local function combat(model: any): string
		if not uiReady() or library.Visible or library.MouseCaptured or not isrbxactive() then
			clearWorldFocus()
			releaseAll()
			return "blocked"
		end
		local root, _, character = getRoot()
		local enemy = model and child(model, "HumanoidRootPart")
		local humanoid = model and child(model, "Humanoid")
		if not root or not model or not model.Parent or not enemy or not enemy.Parent or not humanoid or not humanoid.Parent
			or not finite(humanoid.Health) or humanoid.Health <= 0 then
			clearWorldFocus()
			releaseAll()
			return "dead"
		end
		if settings.AimAssist then aimAt(model) end
		if locked() or attr(character, "Stunned") or attr(game.Workspace, "TimeScale") == 0 then
			releaseAll()
			return "blocked"
		end
		local point = enemy.Position
		if not validPosition(point) then
			return "blocked"
		end
		local mouse = player:GetMouse()
		if not pointerInside(mouse.X, mouse.Y) then
			local camera = game.Workspace.Camera
			local viewport = camera and camera.ViewportSize
			if viewport then mouseMove(viewport.X / 2, viewport.Y / 2, "Combat", true) end
			releaseAll()
			return "aiming"
		end
		local now = tick()
		local stand = value(child(child(world, "Stands"), player.Name))
		if stand and not stand.Parent then stand = nil end
		for _, holder in ipairs({character, stand}) do
			if attr(holder, "GrabbingItem") or attr(holder, "GrabRequestPending") or attr(holder, "GrabSeekActive")
				or attr(holder, "Throwing") or attr(holder, "GrabSequenceActive") then releaseAll(); return "throwing" end
		end
		local carried = child(character, "Throwable") or child(stand, "Throwable")
		local aimPart = settings.AimAssist and child(model, "Head") or child(model, "Torso") or child(model, "UpperTorso") or child(model, "Head") or enemy
		if carried and carried.Parent then
			focusPrompt(aimPart, false)
			if now - lastLight >= 0.75 and tap(1) then lastLight = now end
			return "throwing"
		end
		if (root.Position - point).Magnitude > settings.FarmDistance + 2 then
			move(point + enemy.CFrame.LookVector * -settings.FarmDistance + v3(0, 0.5, 0), point)
			return "approaching"
		end
		local facing = v3(point.X, root.Position.Y, point.Z) - root.Position
		if facing.Magnitude > 0.01 and root.CFrame.LookVector:Dot(facing.Unit) < 0.98 then
			if now - lastMove >= 0.2 then
				root.CFrame = lookAt(root.Position, root.Position + facing)
				lastMove = now
				runtime.Metrics.PositionWrites = runtime.Metrics.PositionWrites + 1
			else
				return "facing"
			end
		end
		focusPrompt(aimPart, false)
		if settings.AutoSummon and attr(character, "Summoned") ~= true and now - lastSummon > 2 then
			tap(bind("Summon", "E"))
			lastSummon = now
		end
		local active = value(child(child(player, "Data"), "SkillActive"))
		if active and active ~= "" and active ~= false then
			return "fighting"
		end
		if now - lastLight > 0.25 and tap(1) then
			lastLight = now
		end
		if settings.HeavyAttacks and now - lastHeavy > 2 then
			tap(bind("Heavy", "R"))
			lastHeavy = now
		end
		if settings.UseSkills and now - lastSkill > 0.5 then
			local skills = child(child(player, "Data"), "Skills")
			for _ = 1, 10 do
				local index = nextSkill % 10
				nextSkill = nextSkill + 1
				local skill = child(skills, "Skill" .. index) or child(skills, tostring(index))
				local equipped = value(skill)
				if type(equipped) == "string" and equipped ~= "" and equipped ~= "None" then
					tap(bind("Skill" .. index .. "Bind", tostring(index)))
					lastSkill = now
					break
				end
			end
		end
		return "fighting"
	end
	local function petyrAnswer(mode: string, answer: string): boolean
		answer = answer:lower():gsub("^%d+%.%s*", ""):gsub("[%.!?]+$", "")
		return answer == "yes" or answer == "claim" or answer == "collect" or answer == "thanks"
			or answer == "see you around"
			or (mode == "BountyReward" and answer == "claim my bounty reward")
	end
	local function dialogueStep(mode: string): boolean
		local holder = child(child(child(player, "PlayerGui"), "Dialogue"), "Holder")
		if not holder then
			return false
		end
		local title = child(holder, "Title")
		local choices = child(holder, "Choices")
		if mode == "BountyClose" then
			local list = {}
			for _, choice in ipairs(choices and choices:GetChildren() or {}) do
				if choice.ClassName == "ImageButton" then list[#list + 1] = choice end
			end
			local label = #list == 1 and child(list[1], "Box")
			local text, number = label and label.Text, #list == 1 and tonumber(list[1].Name)
			local answer = type(text) == "string" and text:lower():gsub("^%d+%.%s*", ""):gsub("[%.!?]+$", "")
			if number and number >= 1 and number <= 9 and (answer == "see you around"
				or title and title.Text == "Hospital Nurse" and answer == "thank you") then
				return tap(48 + number)
			end
			return false
		end
		if not title or title.Text ~= "Petyr" or mode == "Bounty" then
			setStatus("Bounties", "Waiting for a verified dialogue choice")
			return false
		end
		for _, choice in ipairs(choices and choices:GetChildren() or {}) do
			local label = child(choice, "Box")
			local text = label and label.Text
			local number = text and tonumber(text:match("^(%d+)%."))
			if
				number
				and number >= 1
				and number <= 9
				and petyrAnswer(mode, text)
			then
				return tap(48 + number)
			end
		end
		return false
	end
	local ctx: any = {
		player = player,
		players = players,
		world = world,
		now = tick,
		utcNow = type(os) == "table" and type(os.time) == "function" and os.time or nil,
		getRoot = getRoot,
		position = position,
		attr = attr,
		decode = decode,
		move = move,
		tap = tap,
		hold = hold,
		release = release,
		releaseAll = releaseAll,
		click = click,
		mouseMove = mouseMove,
		focusPrompt = focusPrompt,
		dialogueStep = dialogueStep,
		interact = interact,
		findPrompts = findPrompts,
		fight = combat,
		prepareRaftAttack = function(character)
			if settings.AutoUmbrella and umbrellaOpen(character) then openUmbrella(character, true); return false end
			return true
		end,
		setStatus = setStatus,
		getSetting = function(key)
			return settings[key]
		end,
		bind = bind,
		closeOwnedGrowing = function(token)
			if type(token) ~= "string" or token == "" or attr(player, "GrowingInputOwner") ~= token or not isrbxactive() then return false end
			keypress(8)
			task.spawn(function() task.wait(0.08); keyrelease(8) end)
			return true
		end,
		cancelInteraction = function()
			if interaction then release(interaction.key); interaction = nil end
		end,
		interactionBusy = function()
			return interaction ~= nil and not interaction.done and interaction.retry == 0
		end,
	}
	assert(
		_G.StandOutParts and _G.StandOutParts.Bounties and _G.StandOutParts.Resources and _G.StandOutParts.Meteors and _G.StandOutParts.PhoneEliminations,
		"Stand Out feature factories missing"
	)
	local bounties = _G.StandOutParts.Bounties(ctx)
	local resources = _G.StandOutParts.Resources(ctx)
	local meteors = _G.StandOutParts.Meteors(ctx)
	local readPhoneTarget = _G.StandOutParts.PhoneTargetReader(player, tick)
	ctx.readPhonePlayer = readPhoneTarget
	local phone = _G.StandOutParts.PhoneEliminations(ctx)
	local rafts = _G.StandOutParts.Rafts(ctx)
	runtime.Controllers.Bounties, runtime.Controllers.Resources = bounties, resources
	runtime.Controllers.Meteors, runtime.Controllers.PhoneEliminations = meteors, phone
	runtime.Controllers.Rafts = rafts
	runtime.Metrics.Resources = resources.Metrics
	runtime.Metrics.Meteors = meteors.Metrics
	runtime.Metrics.Rafts = rafts.Metrics
	local function restoreCollision()
		for _, entry in pairs(collision) do
			if entry.part.Parent then
				pcall(function()
					entry.part.CanCollide = entry.value
				end)
			end
		end
		collision = {}
	end
	local function setWalkspeed(enabled: boolean): boolean
		if not enabled then
			if speedOverride and speedOverride.object.Parent and speedOverride.object.Value == speedOverride.applied then
				speedOverride.object.Value = speedOverride.value
			end
			speedOverride = nil
			return true
		end
		local data = child(player, "Data")
		local speed = child(data, "DefaultSpeed")
		if not speed or (speed.ClassName ~= "IntValue" and speed.ClassName ~= "NumberValue")
			or not speed.Parent or speed.Parent.Address ~= data.Address or not finite(speed.Value) then
			setStatus("Walkspeed", "Waiting for native walk speed")
			return false
		end
		if not speedOverride or speedOverride.object.Address ~= speed.Address then
			setWalkspeed(false)
			speedOverride = {object = speed, value = speed.Value}
		end
		local selected = settings.WalkSpeed or 24
		if not finite(selected) then return false end
		selected = math.floor(math.clamp(selected, 4, 100))
		if speed.Value ~= selected then speed.Value = selected end
		speedOverride.applied = selected
		setStatus("Walkspeed", "Walk speed " .. tostring(selected))
		return true
	end
	local function stop()
		if not runtime.Running or runtime.Stopping then
			return
		end
		runtime.Stopping = true
		clearWorldFocus()
		pcall(bounties.Stop)
		pcall(resources.Stop)
		pcall(meteors.Stop)
		pcall(phone.Stop)
		pcall(rafts.Stop)
		runtime.Running = false
		releaseAll()
		restoreCollision()
		setWalkspeed(false)
		task.spawn(function()
			task.wait()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			for _, drawing in ipairs(drawings) do
				drawing:Remove()
			end
			if not library.Unloaded then
				library:Unload()
			end
		end)
	end
	runtime.Stop = stop
	library:OnUnload(stop)
	local window =
		library:CreateWindow({ Title = "lazyhub | STAND OUT", Size = v2(780, 800), AutoShow = true })
	local farming = window:AddTab("Farming")
	local combatTab = window:AddTab("Combat")
	local movementTab = window:AddTab("Movement")
	local espTab = window:AddTab("ESP")
	local settingsTab = window:AddTab("Settings")
	local farmGroup = farming:AddLeftGroupbox("Quests and bounties")
	local enemyGroup = farming:AddRightGroupbox("Enemies")
	local resourceGroup = farming:AddLeftGroupbox("Resources")
	local combatGroup = combatTab:AddLeftGroupbox("Combat")
	local targetGroup = combatTab:AddRightGroupbox("Player eliminations")
	local movementGroup = movementTab:AddLeftGroupbox("Movement")
	local movementOther = movementTab:AddRightGroupbox("Modifiers")
	local espGroup = espTab:AddLeftGroupbox("ESP")
	local espOptions = espTab:AddRightGroupbox("Display")
	local priorityGroup = settingsTab:AddLeftGroupbox("Farm priorities")
	local utilityGroup = settingsTab:AddRightGroupbox("Session")
	local function toggle(group: any, key: string, text: string, disabled: any, reason: any)
		settings[key] = false
		group:AddToggle(key, {
			Text = text,
			Default = false,
			Disabled = disabled == true,
			Tooltip = reason,
			Callback = function(on)
				settings[key] = on == true and disabled ~= true
				if key == "Walkspeed" then setWalkspeed(settings[key]) end
				if settings[key] then
					if key == "AutoUmbrella" then task.spawn(function() if settings[key] then protectFromSun(player.Character) end end) end
					local jobName = ({
						AutoBounties = "Bounties",
						AutoHarvest = "Harvest",
						AutoBosses = "Bosses",
						AutoMobs = "Mobs",
						AutoSupplies = "Supplies",
						AutoArrows = "Arrows",
						AutoCrates = "Crates",
						AutoMeteors = "Meteors",
						AutoRafts = "Rafts",
						PlayerEliminations = "PlayerEliminations", PhoneEliminations = "PhoneEliminations", AutoStats = "AutoStats",
						AutoSummon = "AutoSummon", Fly = "Fly", HighJump = "HighJump", InfiniteJump = "InfiniteJump",
					})[key]
					runtime.Errors[jobName or key] = nil
				end
				if not settings[key] then
					interaction = nil
					task.spawn(function() if not settings[key] then releaseAll() end end)
				end
			end,
		})
		if reason then
			setStatus(key, reason)
		end
	end
	local function slider(group: any, key: string, text: string, default: number, minimum: number, maximum: number)
		settings[key] = default
		group:AddSlider(key, {
			Text = text,
			Default = default,
			Min = minimum,
			Max = maximum,
			Rounding = 0,
			Callback = function(v)
				settings[key] = v
				if key == "WalkSpeed" and settings.Walkspeed then setWalkspeed(true) end
			end,
		})
	end
	local function dropdown(group: any, key: string, text: string, values: any, default: string, disabled: any)
		settings[key] = default
		return group:AddDropdown(key, {
			Text = text,
			Values = values,
			Default = default,
			Disabled = disabled == true,
			Callback = function(v)
				settings[key] = v
			end,
		})
	end
	toggle(farmGroup, "AutoBounties", "Auto Petyr bounties")
	farmGroup:AddLabel("this feature is still W.I.P and very buggy", true)
	dropdown(farmGroup, "BountyTier", "Bounty tier", { "Highest unlocked", "Tier 1" }, "Highest unlocked")
	local bountyValues = {}
	for index = 1, 14 do
		local name = _G.StandOutParts.BountyNames[index]
		if name then bountyValues[#bountyValues + 1] = name end
	end
	settings.BlockedBounties = {}
	farmGroup:AddDropdown("BlockedBounties", {
		Text = "Blocked bounties", Values = bountyValues, Multi = true, Default = {},
		Callback = function(v) settings.BlockedBounties = v end,
	})
	toggle(farmGroup, "AutoStory", "Auto story", true, "Unavailable: story progression has not been verified")
	toggle(farmGroup, "SkipTutorial", "Skip tutorial", true, "Unavailable: tutorial skip has not been verified")
	toggle(
		farmGroup,
		"AutoSideQuests",
		"Auto side quests",
		true,
		"Unavailable: side quest transitions have not been verified"
	)
	toggle(enemyGroup, "AutoBosses", "Farm bosses")
	dropdown(enemyGroup, "BossSelection", "Boss", { "Both", "DIO", "JOTARO" }, "Both")
	toggle(enemyGroup, "AutoMobs", "Farm mobs")
	local mobChoice = dropdown(enemyGroup, "MobSelection", "Mob", { "Any" }, "Any")
	toggle(
		enemyGroup,
		"NPCEliminations",
		"Hop for NPC eliminations",
		true,
		"Unavailable: server hopping has not been verified"
	)
	toggle(resourceGroup, "AutoSupplies", "Uncover Buried Supplies")
	toggle(resourceGroup, "SupplyCameraFocus", "Overhead collection camera")
	_G.Toggles.SupplyCameraFocus:SetValue(true)
	toggle(resourceGroup, "AutoHarvest", "Harvest and plant owned pots")
	dropdown(resourceGroup, "ReplantSeed", "Plant and replant seed", resources.SeedOptions or { "None" }, "None")
	toggle(resourceGroup, "AutoCrates", "Auto Crate")
	toggle(resourceGroup, "AutoMeteors", "Auto collect meteor drops")
	toggle(resourceGroup, "AutoRafts", "Auto Raft")
	toggle(
		resourceGroup,
		"AutoArrows",
		"Collect arrows",
		resources.Available.Arrows == false,
		resources.Available.Arrows == false and "Unavailable: arrow pickup route has not been verified" or nil
	)
	toggle(combatGroup, "AutoSummon", "Auto summon stand")
	toggle(combatGroup, "HeavyAttacks", "Use heavy attacks")
	toggle(combatGroup, "UseSkills", "Use equipped skills")
	slider(combatGroup, "FarmDistance", "Attack distance", 4, 2, 8)
	toggle(combatGroup, "AutoStats", "Auto stats")
	toggle(combatGroup, "AutoUmbrella", "Auto equip umbrella")
	combatGroup:AddButton({
		Text = "Open umbrella now",
		Func = function()
			task.spawn(function() openUmbrella(player.Character) end)
		end,
	})
	dropdown(combatGroup, "SelectedStat", "Allocate points to", { "Damage", "Ability", "Health" }, "Damage")
	toggle(combatGroup, "NoStun", "No stun", true, "Unavailable: server stun immunity is not verified")
	toggle(combatGroup, "NoCooldowns", "No cooldowns", true, "Unavailable: server cooldown removal is not verified")
	toggle(targetGroup, "PlayerEliminations", "Fight selected player")
	settings.EliminationMode = "Manual"
	local playerChoice = dropdown(targetGroup, "TargetPlayer", "Player", { "Nearest player", "None" }, "Nearest player")
	toggle(targetGroup, "PhoneEliminations", "Auto phone eliminations")
	toggle(targetGroup, "AimAssist", "Aim assist")
	dropdown(targetGroup, "AimTarget", "Manual aim target", { "Selected player", "Nearest NPC", "Nearest target" }, "Nearest target")
	toggle(targetGroup, "SilentAim", "Silent aim", true, "Unavailable: silent aim binding is not exposed")
	toggle(movementGroup, "Fly", "Fly")
	slider(movementGroup, "FlySpeed", "Fly speed", 40, 10, 100)
	toggle(movementGroup, "HighJump", "High jump")
	slider(movementGroup, "JumpVelocity", "Jump height impulse", 70, 35, 140)
	toggle(movementGroup, "InfiniteJump", "Infinite jump")
	toggle(movementOther, "Noclip", "Noclip")
	toggle(movementOther, "Walkspeed", "Walkspeed")
	slider(movementOther, "WalkSpeed", "Walk speed", 24, 4, 100)
	toggle(espGroup, "PlayerESP", "Player ESP")
	toggle(espGroup, "NpcESP", "NPC ESP")
	toggle(espGroup, "EnemyESP", "Enemy ESP")
	toggle(espGroup, "QuestESP", "Quest ESP")
	slider(espOptions, "EspDistance", "Maximum distance", 1500, 100, 4000)
	toggle(espOptions, "EspBoxes", "Boxes")
	toggle(espOptions, "EspHealth", "Health bars")
	settings.EspBoxes, settings.EspHealth = true, true
	_G.Toggles.EspBoxes:SetValue(true)
	_G.Toggles.EspHealth:SetValue(true)
	local defaults = {
		{ "Bounties", 100 },
		{ "Story", 90 },
		{ "SideQuests", 85 },
		{ "PlayerEliminations", 80 },
		{ "PhoneEliminations", 75 },
		{ "Harvest", 70 },
		{ "Bosses", 60 },
		{ "Crates", 50 },
		{ "Meteors", 45 },
		{ "Rafts", 42 },
		{ "Mobs", 40 },
		{ "Supplies", 30 },
		{ "Arrows", 20 },
	}
	for _, item in ipairs(defaults) do
		slider(priorityGroup, item[1] .. "Priority", item[1] .. " priority", item[2], 0, 100)
	end
	farmGroup:AddButton({
		Text = "Start enabled farms",
		Func = function()
			task.spawn(function() library:Hide() end)
		end,
	})
	local function chooseJob(list: any, minimum: number?): any
		local best, priority = nil, minimum or -math.huge
		for _, job in ipairs(list) do
			local score = settings[job.priority] or 0
			if score > priority and settings[job.toggle] and not runtime.Errors[job.name] and job.ready() then
				best, priority = job, score
			end
		end
		return best
	end
	local function selectedEnemy(kind: string): any
		local list = snapshot[kind]
		local root = getRoot()
		if not root then
			return nil
		end
		local best, distance = nil, math.huge
		for _, record in ipairs(list) do
			local allowed = kind == "bosses"
					and (settings.BossSelection == "Both" or record.config == settings.BossSelection)
				or kind == "mobs" and (settings.MobSelection == "Any" or record.name == settings.MobSelection)
			if allowed and record.model.Parent and record.humanoid.Parent and record.humanoid.Health > 0 and record.root.Parent and validPosition(record.root.Position) then
				local d = (root.Position - record.root.Position).Magnitude
				if d < distance then
					best, distance = record.model, d
				end
			end
		end
		if not best then setStatus(kind == "bosses" and "Bosses" or "Mobs", kind == "bosses" and "Waiting for the selected DIO or JOTARO to spawn" or "Waiting for the selected mob to stream in") end
		return best
	end
	local function selectedPlayer(): any
		if settings.TargetPlayer == "Nearest player" then
			local root, best, distance = getRoot(), nil, math.huge
			if not root then return nil end
			for _, record in ipairs(snapshot.users) do
				if record.root.Parent and record.humanoid.Health > 0 and validPosition(record.root.Position) then
					local d = (root.Position - record.root.Position).Magnitude
					if d < distance then best, distance = record.model, d end
				end
			end
			if not best then setStatus("PlayerEliminations", "Waiting for a nearby player") end
			return best
		end
		for _, record in ipairs(snapshot.users) do
			if record.name == settings.TargetPlayer then
				return record.model
			end
		end
		setStatus("PlayerEliminations", settings.TargetPlayer == "None" and "Choose a player or Nearest player" or "Waiting for the selected player to stream in")
		return nil
	end
	local crateSurvey = { points = {}, index = 1, next = 0, built = false }
	local function manualAimTarget(): any
		local mode = settings.AimTarget
		if mode == "Selected player" then return selectedPlayer() end
		local root, best, distance = getRoot(), nil, math.huge
		if not root then return nil end
		for _, list in ipairs({ snapshot.mobs, snapshot.bosses, mode == "Nearest target" and snapshot.users or {} }) do
			for _, record in ipairs(list) do
				if record.root.Parent and finite(record.humanoid.Health) and record.humanoid.Health > 0 and validPosition(record.root.Position) then
					local d = (record.root.Position - root.Position).Magnitude
					if d < distance then best, distance = record.model, d end
				end
			end
		end
		return best
	end
	local function crateSearchReady(): boolean
		local opened, now = resources.CratesProgress.Opened, tick()
		if not settings.AutoCrates or opened == nil or opened >= 10 or locked() or not getRoot() then return false end
		if not crateSurvey.built and now >= crateSurvey.next then
			local areas, seen = child(world, "Areas"), {}
			for _, area in ipairs(areas and areas:GetChildren() or {}) do
				local p, size, cf = area.Position, area.Size, area.CFrame
				if validPosition(p) and validPosition(size) and size.X > 0 and size.Z > 0 and cf then
					local nx, nz = math.min(32, math.ceil(size.X / 200)), math.min(32, math.ceil(size.Z / 200))
					for x = 1, nx do
						for z = 1, nz do
							if #crateSurvey.points >= 512 then break end
							local point = cf:PointToWorldSpace(v3((x - 0.5) * size.X / nx - size.X / 2, 0, (z - 0.5) * size.Z / nz - size.Z / 2))
							if validPosition(point) then
								local key = math.floor(point.X / 100) .. ":" .. math.floor(point.Z / 100)
								if not seen[key] then seen[key] = true; crateSurvey.points[#crateSurvey.points + 1] = point end
							end
						end
					end
				end
			end
			local origin = getRoot().Position
			table.sort(crateSurvey.points, function(a, b) return (a - origin).Magnitude < (b - origin).Magnitude end)
			crateSurvey.built, crateSurvey.next = #crateSurvey.points > 0, now + (#crateSurvey.points > 0 and 0 or 10)
			local remote = child(child(game.ReplicatedStorage, "Remotes"), "HowlerCases")
			if remote then pcall(function() remote:FireServer("Ready") end) end
		end
		return crateSurvey.built and now >= crateSurvey.next
	end
	local function crateSearchStep()
		if resources.Ready("Crates") then resources.Step("Crates"); return end
		if not crateSearchReady() then return end
		local point = crateSurvey.points[crateSurvey.index]
		if not point then
			crateSurvey.index, crateSurvey.next = 1, tick() + 10
			setStatus("Crates", "Map search finished; waiting for more cash cases to reveal")
			return
		end
		if move(point + v3(0, 3, 0)) or (getRoot().Position - point).Magnitude < 8 then
			runtime.Metrics.CrateSearchVisits = (runtime.Metrics.CrateSearchVisits or 0) + 1
			crateSurvey.index, crateSurvey.next = crateSurvey.index + 1, tick() + 1.1
			setStatus("Crates", "Searching map for cash cases: " .. (crateSurvey.index - 1) .. "/" .. #crateSurvey.points)
		end
	end
	local arrowVisits, arrowSearchNext = {}, 0
	local function arrowSearchTarget(): any
		if not settings.AutoArrows or locked() or tick() < arrowSearchNext then return nil end
		local root, nodes = getRoot(), child(child(world, "ItemSpawnNodes"), "Arrows")
		if not root or not nodes then return nil end
		local selected, distance = nil, math.huge
		for _, node in ipairs(nodes:GetChildren()) do
			local point = node.Position
			if attr(node, "Occupied") == true and attr(node, "Enabled") ~= false and validPosition(point) and tick() >= (arrowVisits[node.Address] or 0) then
				local d = (point - root.Position).Magnitude
				if d < distance then selected, distance = node, d end
			end
		end
		return selected
	end
	local function arrowSearchStep()
		if resources.Ready("Arrows") then resources.Step("Arrows"); return end
		local target = arrowSearchTarget()
		if target and (move(target.Position + v3(0, 3, 0)) or (getRoot().Position - target.Position).Magnitude < 8) then
			arrowVisits[target.Address], arrowSearchNext = tick() + 10, tick() + 1.1
			setStatus("Arrows", "Approaching the spawned arrow at " .. target.Name)
		end
	end
	local jobs: any = {
		{
			name = "Rafts", toggle = "AutoRafts", priority = "RaftsPriority",
			ready = rafts.Ready, step = rafts.Step, busy = rafts.Busy, stop = rafts.Stop,
			breaking = rafts.Breaking,
		},
		{
			name = "Bounties",
			freeHands = bounties.NeedsFreeHands,
			seated = bounties.SeatedAtPaco,
			carrying = bounties.CarryingPaco,
			toggle = "AutoBounties",
			priority = "BountiesPriority",
			ready = function()
				return bounties.Ready()
			end,
			step = function()
				bounties.Step()
			end,
			busy = function()
				return bounties.Busy()
			end,
			stop = function()
				bounties.Stop()
			end,
		},
		{
			name = "PlayerEliminations",
			toggle = "PlayerEliminations",
			priority = "PlayerEliminationsPriority",
			ready = function()
				return selectedPlayer() ~= nil
			end,
			step = function()
				setStatus("PlayerEliminations", combat(selectedPlayer()))
			end,
		},
		{
			name = "PhoneEliminations", toggle = "PhoneEliminations", priority = "PhoneEliminationsPriority",
			ready = function() return phone.Ready() end,
			step = function() phone.Step() end,
			busy = function() return phone.Busy() end,
			stop = function() phone.Stop() end,
		},
		{
			name = "Harvest",
			toggle = "AutoHarvest",
			priority = "HarvestPriority",
			ready = function()
				return resources.Ready("Harvest", true)
			end,
			step = function()
				resources.Step("Harvest")
			end,
			busy = function()
				return resources.Busy("Harvest")
			end,
			stop = function()
				resources.Stop("Harvest")
			end,
		},
		{
			name = "Bosses",
			toggle = "AutoBosses",
			priority = "BossesPriority",
			ready = function()
				return selectedEnemy("bosses") ~= nil
			end,
			step = function()
				setStatus("Bosses", combat(selectedEnemy("bosses")))
			end,
		},
		{
			name = "Mobs",
			toggle = "AutoMobs",
			priority = "MobsPriority",
			ready = function()
				return selectedEnemy("mobs") ~= nil
			end,
			step = function()
				setStatus("Mobs", combat(selectedEnemy("mobs")))
			end,
		},
		{
			name = "Supplies",
			toggle = "AutoSupplies",
			priority = "SuppliesPriority",
			ready = function()
				return resources.Ready("Supplies", true)
			end,
			step = function()
				resources.Step("Supplies")
			end,
			busy = function()
				return resources.Busy("Supplies")
			end,
			stop = function()
				resources.Stop("Supplies")
			end,
		},
		{
			name = "Meteors", toggle = "AutoMeteors", priority = "MeteorsPriority",
			ready = function() return meteors.Ready() end,
			step = function() meteors.Step() end,
			busy = function() return meteors.Busy() end,
			stop = function() meteors.Stop() end,
		},
		{
			name = "Crates", toggle = "AutoCrates", priority = "CratesPriority",
			ready = function() return resources.Ready("Crates", true) or crateSearchReady() end,
			step = crateSearchStep,
			busy = function() return resources.Busy("Crates") end,
			stop = function() resources.Stop("Crates") end,
		},
		{
			name = "Arrows",
			toggle = "AutoArrows",
			priority = "ArrowsPriority",
			ready = function()
				return resources.Ready("Arrows", true) or arrowSearchTarget() ~= nil
			end,
			step = function()
				arrowSearchStep()
			end,
			busy = function()
				return resources.Busy("Arrows")
			end,
			stop = function()
				resources.Stop("Arrows")
			end,
		},
	}
	runtime.Context = ctx
	runtime.UiReady = uiReady
	runtime.Set = function(key, v)
		local control = _G.Toggles[key] or _G.Options[key]
		if control and control.SetValue then
			control:SetValue(v)
			return true
		end
		return false
	end
	runtime.SelfTest = function()
		assert(type(ctx.focusPrompt) == "function" and type(resources.Render) == "function", "Replant integration missing")
		assert(type(phone.Read) == "function" and _G.Toggles.PhoneEliminations and settings.EliminationMode == "Manual", "Phone elimination integration missing")
		assert(petyrAnswer("BountyReward", "1. Claim my bounty reward."))
		assert(petyrAnswer("Bounties", "1. See you around."))
		assert(not petyrAnswer("BountyReward", "2. I'll collect it later."))
		assert(not petyrAnswer("Bounties", "1. Claim my bounty reward."))
		local savedCount, savedError = library.RenderCount, library.LastRenderError
		library.RenderCount = 0
		local blocksUndrawn = not uiReady()
		assert(not hold(69) and not move(v3(0, 0, 0)) and interact(nil) == "blocked")
		library.RenderCount, library.LastRenderError = 1, "render failed"
		local blocksFailure = not uiReady()
		library.LastRenderError = nil
		local allowsRendered = uiReady()
		library.RenderCount, library.LastRenderError = savedCount, savedError
		assert(blocksUndrawn and blocksFailure and allowsRendered, "UI readiness gate failed")
		assert(not holdFinished("GardenGather", 0.98), "Supplies release before server depletion")
		assert(not holdFinished("GardenGather", 1), "Supplies release at visual completion")
		assert(holdFinished("GardenWork", 1))
		assert(bind("__missing", "E") == 69 and bind("__missing", "RightControl") == 163)
		assert(decode('{"value":1}').value == 1 and decode('{"value":') == nil)
		assert(not validPosition(v3(0 / 0, 0, 0)))
		local saved = { settings.TestA, settings.TestB, settings.TestPriorityA, settings.TestPriorityB }
		settings.TestA, settings.TestB, settings.TestPriorityA, settings.TestPriorityB = true, true, 3, 8
		local a = {
			name = "TestA",
			toggle = "TestA",
			priority = "TestPriorityA",
			ready = function()
				return true
			end,
		}
		local b = {
			name = "TestB",
			toggle = "TestB",
			priority = "TestPriorityB",
			ready = function()
				return true
			end,
		}
		assert(chooseJob({ a, b }) == b)
		settings.TestPriorityB = 3
		assert(chooseJob({ a, b }) == a)
		b.ready = function()
			return false
		end
		settings.TestPriorityB = 10
		assert(chooseJob({ a, b }) == a)
		settings.TestA, settings.TestB, settings.TestPriorityA, settings.TestPriorityB =
			saved[1], saved[2], saved[3], saved[4]
		assert(bounties.SelfTest() ~= false and resources.SelfTest() ~= false and meteors.SelfTest() ~= false)
		return true
	end
	utilityGroup:AddButton({
		Text = "Run self-checks",
		Func = function()
			local ok, err = pcall(runtime.SelfTest)
			library:Notify(ok and "Self-checks passed" or tostring(err))
		end,
	})
	utilityGroup:AddButton({
		Text = "Save settings",
		Func = function()
			local saved = {}
			for key, v in pairs(settings) do
				if type(v) ~= "boolean" then
					saved[key] = v
				end
			end
			writefile("stand_out_config.json", http:JSONEncode(saved))
			library:Notify("Settings saved. Automation switches remain off on startup.")
		end,
	})
	local function loadSettings(): (boolean, string)
		if not isfile("stand_out_config.json") then return false, "No saved settings" end
		local ok, raw = pcall(readfile, "stand_out_config.json")
		local loaded = ok and type(raw) == "string" and decode(raw)
		if not loaded then return false, "Saved settings could not be read" end
		for key, v in pairs(loaded) do
			if _G.Options[key] and type(v) == type(settings[key]) and type(v) ~= "boolean" then
				_G.Options[key]:SetValue(v)
			end
		end
		return true, "Saved settings loaded. Farms remain off at startup."
	end
	utilityGroup:AddButton({
		Text = "Load settings",
		Func = function()
			local _, message = loadSettings()
			library:Notify(message)
		end,
	})
	utilityGroup:AddButton({ Text = "Stop and unload", Func = function() task.spawn(stop) end })
	local checksOk, checksError = pcall(runtime.SelfTest)
	if not checksOk then
		stop()
		assert(false, "Stand Out self-checks failed: " .. tostring(checksError))
	end
	local POOL = 64
	runtime.Metrics.EspDrawings = 0
	local function prepareEsp()
		if #targets > 0 then
			return
		end
		for i = 1, POOL do
			local box, name, bar = Drawing.new("Square"), Drawing.new("Text"), Drawing.new("Square")
			box.Thickness, box.Filled, box.Visible = 1, false, false
			name.Size, name.Center, name.Outline, name.Visible = 13, true, true, false
			bar.Filled, bar.Visible, bar.Color = true, false, rgb(92, 220, 142)
			box.Transparency, name.Transparency, bar.Transparency = 1, 1, 1
			targets[i] = { box = box, name = name, bar = bar }
			drawings[#drawings + 1] = box
			drawings[#drawings + 1] = name
			drawings[#drawings + 1] = bar
		end
		runtime.Metrics.EspDrawings = #drawings
	end
	local espCache: any = {}
	local renderRoot: any = nil
	local lastNames = ""
	local function collect()
		local espEnabled = settings.PlayerESP or settings.EnemyESP or settings.NpcESP or settings.QuestESP
		renderRoot = espEnabled and getRoot() or nil
		if espEnabled then
			prepareEsp()
		end
		local out, mobNames, userNames = { mobs = {}, bosses = {}, users = {}, quests = {} }, { "Any" }, { "Nearest player", "None" }
		local seen: any = {}
		local esps = {}
		local users = (
			settings.PlayerESP
			or settings.PlayerEliminations
			or settings.AimAssist
			or settings.AutoMobs or settings.AutoBosses or settings.EnemyESP or settings.PhoneEliminations
			or library.Visible and (window.ActiveTab == combatTab or window.ActiveTab == farming)
		)
				and players:GetPlayers()
			or {}
		for _, p in ipairs(users) do
			local character = p.Character
			if character then seen[character.Address] = true end
			if p.UserId ~= player.UserId then
				local root, head, hum =
					child(character, "HumanoidRootPart"), child(character, "Head"), child(character, "Humanoid")
				userNames[#userNames + 1] = p.Name
				if root and hum and hum.Health > 0 then
					out.users[#out.users + 1] =
						{ name = p.Name, model = character, root = root, humanoid = hum, id = p.UserId }
					seen[character.Address] = true
					if settings.PlayerESP then
						esps[#esps + 1] = {
							name = p.Name,
							root = root,
							head = head or root,
							humanoid = hum,
							color = rgb(166, 120, 220),
						}
					end
				end
			end
		end
		local modelFolder = (
			settings.AutoMobs
			or settings.AutoBosses
			or settings.EnemyESP
			or settings.AimAssist
			or library.Visible and window.ActiveTab == farming
		)
				and child(world, "Players")
			or nil
		if modelFolder then
			for _, model in ipairs(modelFolder:GetChildren()) do
				if model.ClassName == "Model" and model.Address ~= characterAddress and not seen[model.Address] then
					local root, head, hum =
						child(model, "HumanoidRootPart"), child(model, "Head"), child(model, "Humanoid")
					local nativeConfig = attr(model, "Config") or value(child(model, "Config"))
					local fightable = attr(model, "FightableNPC")
					if root and hum and finite(hum.Health) and hum.Health > 0 and fightable == true then
						local config = tostring(nativeConfig or model.Name:gsub("_%d+$", "")):upper()
						local name = model.Name:gsub("_%d+$", "")
						local record = { name = name, model = model, root = root, humanoid = hum, config = config }
						if config == "DIO" or config == "JOTARO" then
							out.bosses[#out.bosses + 1] = record
						elseif not attr(model, "PlayerBountyOwner") or attr(model, "PlayerBountyOwner") == player.UserId then
							out.mobs[#out.mobs + 1] = record
							if not seen[name] then
								mobNames[#mobNames + 1] = name
								seen[name] = true
							end
						end
						if settings.EnemyESP then
							esps[#esps + 1] = {
								name = name,
								root = root,
								head = head or root,
								humanoid = hum,
								color = rgb(255, 98, 100),
							}
						end
					end
				end
			end
		end
		local npcFolder = (settings.NpcESP or settings.QuestESP) and child(world, "NPCs") or nil
		if npcFolder then
			for _, model in ipairs(npcFolder:GetChildren()) do
				local root
				if model.ClassName == "Model" then
					root = child(model, "HumanoidRootPart")
					if not root or not validPosition(root.Position) then root = model.PrimaryPart end
					if not root or not validPosition(root.Position) then root = child(model, "Head") end
				end
				if root and validPosition(root.Position) then
					if settings.NpcESP then
						esps[#esps + 1] = {
							name = model.Name,
							root = root,
							head = child(model, "Head") or root,
							color = rgb(105, 180, 242),
						}
					end
					if settings.QuestESP then
						local giver = attr(model, "QuestGiver") == true
						for _, prompt in ipairs(findPrompts(model)) do
							if
								(prompt.ClassName == "ProximityPrompt" or giver and prompt.ClassName == "ClickDetector")
								and attr(prompt, "StoryPromptAvailable") ~= false
								and (
									giver or attr(prompt, "StoryPromptAvailable") == true and (
										attr(prompt, "StoryQuestIds") or attr(prompt, "StoryAction")
										or attr(prompt, "BountyLeaderId") or attr(prompt, "StoryServerDialogue") == true
									)
								)
							then
								local owner = attr(prompt, "StoryPromptOwnerId")
								if not owner or owner == player.UserId then
									esps[#esps + 1] = {
										name = model.Name .. " | Quest",
										root = root,
										head = root,
										color = rgb(255, 213, 105),
									}
									break
								end
							end
						end
					end
				end
			end
		end
		snapshot, espCache = out, esps
		table.sort(userNames)
		if userNames[1] ~= "None" then
			for i, v in ipairs(userNames) do
				if v == "None" then
					table.remove(userNames, i)
					break
				end
			end
			table.insert(userNames, 1, "None")
		end
		local signature = table.concat(userNames, "|") .. table.concat(mobNames, "|")
		if signature ~= lastNames then
			lastNames = signature
			if playerChoice.SetValues then
				playerChoice:SetValues(userNames)
			end
			if mobChoice.SetValues then
				mobChoice:SetValues(mobNames)
			end
		end
		if #out.bosses == 0 then
			setStatus("Bosses", "Waiting for DIO or JOTARO")
		end
		if #out.mobs == 0 then
			setStatus("Mobs", "Waiting for mobs to stream in")
		end
	end
	local shown = 0
	local function renderEsp()
		local root = renderRoot
		local rootPosition = root and root.Position
		local count = 0
		if validPosition(rootPosition) then
			for _, record in ipairs(espCache) do
				if count >= POOL then
					break
				end
				local p, head = record.root.Position, record.head.Position
				if
					validPosition(p)
					and validPosition(head)
					and (rootPosition - p).Magnitude <= settings.EspDistance
				then
					local top, a = WorldToScreen(head + v3(0, 0.9, 0))
					local bottom, b = WorldToScreen(p - v3(0, 3.2, 0))
					if
						a
						and b
						and top
						and bottom
						and finite(top.X)
						and finite(top.Y)
						and finite(bottom.X)
						and finite(bottom.Y)
						and bottom.Y > top.Y
					then
						count = count + 1
						local d = targets[count]
						local h, w = bottom.Y - top.Y, (bottom.Y - top.Y) * 0.5
						d.box.Position, d.box.Size, d.box.Color, d.box.Visible =
							v2(top.X - w / 2, top.Y), v2(w, h), record.color, settings.EspBoxes
						d.name.Position, d.name.Text, d.name.Color, d.name.Visible =
							v2(top.X, top.Y - 16), record.name, record.color, true
						local ratio = record.humanoid
								and finite(record.humanoid.Health)
								and finite(record.humanoid.MaxHealth)
								and math.clamp(record.humanoid.Health / math.max(1, record.humanoid.MaxHealth), 0, 1)
							or 0
						d.bar.Position, d.bar.Size, d.bar.Visible =
							v2(top.X - w / 2 - 5, bottom.Y - h * ratio),
							v2(3, h * ratio),
							settings.EspHealth and record.humanoid ~= nil
					end
				end
			end
		end
		for i = count + 1, shown do
			targets[i].box.Visible = false
			targets[i].name.Visible = false
			targets[i].bar.Visible = false
		end
		shown = count
	end
	connections[#connections + 1] = runService.RenderStepped:Connect(function()
		if not uiReady() then
			clearWorldFocus()
			return
		end
		local focusOk, focusError = pcall(renderWorldFocus)
		if not focusOk then clearWorldFocus(); setStatus("Harvest", "Pot focus: " .. tostring(focusError)) end
		if settings.AimAssist then
			local ok, err = pcall(renderAim)
			if not ok then
				runtime.Errors.AimAssist = tostring(err)
				_G.Toggles.AimAssist:SetValue(false)
				setStatus("AimAssist", "Paused: " .. tostring(err))
			end
		end
		if
			currentJob
			and currentJob.name == "Bounties"
			and bounties.Render
			and not library.Visible
			and not library.MouseCaptured
			and isrbxactive()
		then
			bounties.Render()
		end
		if currentJob and currentJob.name == "Harvest" and resources.Render and not library.Visible and not library.MouseCaptured and isrbxactive() then
			local ok, err = pcall(resources.Render)
			if not ok then
				runtime.Errors.Harvest = tostring(err)
				setStatus("Harvest", "Paused: " .. tostring(err))
				resources.Stop("Harvest")
				releaseAll()
				currentJob = nil
			end
		end
		local ok, err = pcall(renderEsp)
		if not ok then
			runtime.Errors.ESP = tostring(err)
			espCache, shown = {}, 0
			for _, key in ipairs({ "PlayerESP", "NpcESP", "EnemyESP", "QuestESP" }) do
				_G.Toggles[key]:SetValue(false)
			end
			for _, drawing in ipairs(drawings) do
				pcall(function()
					drawing.Visible = false
				end)
			end
			library:Notify("ESP stopped: " .. tostring(err), 8)
		end
	end)
	task.spawn(function()
		while runtime.Running do
			local mouseOk, mouseError = pcall(pollMouse)
			if not mouseOk then mouseTarget = nil; setStatus("Runtime", "Native pointer: " .. tostring(mouseError)); releaseAll() end
			local now = tick()
			local expired = {}
			for vk, deadline in pairs(keys) do
				if now >= deadline then
					expired[#expired + 1] = vk
				end
			end
			for _, vk in ipairs(expired) do
				release(vk)
			end
			task.wait(0.02)
		end
	end)
	local loadOnStart = true
	task.spawn(function()
		while runtime.Running do
			local ok, err = pcall(function()
				local root, _, character = getRoot()
				local address = character and character.Address or 0
				if characterAddress ~= address then
					releaseAll()
					restoreCollision()
					interaction = nil
					characterAddress = address
				end
				collect()
				if loadOnStart then
					loadOnStart = false
					local _, message = loadSettings()
					setStatus("Settings", message)
				end
				if uiReady() and settings.Noclip and character then
					for _, part in ipairs(character:GetChildren()) do
						if part.ClassName == "Part" or part.ClassName == "MeshPart" then
							if not collision[part.Address] then
								collision[part.Address] = { part = part, value = part.CanCollide }
							end
							if part.CanCollide then
								part.CanCollide = false
							end
						end
					end
				elseif next(collision) then
					restoreCollision()
				end
			end)
			if not ok then
				setStatus("Runtime", tostring(err))
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		local allocating = false
		while runtime.Running do
			if uiReady() and not library.Visible and isrbxactive() and settings.AutoStats and not allocating then
				local stats = child(child(player, "Data"), "Stats")
				local points = value(child(stats, "Points"))
				if type(points) == "number" and points > 0 then
					allocating = true
					local ok, err = pcall(function()
						game.ReplicatedStorage.Remotes.Data:InvokeServer(
							"Stats",
							settings.SelectedStat,
							math.floor(points)
						)
					end)
					allocating = false
					if not ok and runtime.Running then
						_G.Toggles.AutoStats:SetValue(false)
						setStatus("AutoStats", tostring(err))
					end
				end
			end
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while runtime.Running do
			local ok, err = pcall(function()
				if resources.Poll then resources.Poll() end
				local root, _, character = getRoot()
				if not uiReady() or not root or not isrbxactive() then
					aimAllowed = false
					clearWorldFocus()
					releaseAll()
					if bounties.Pause then bounties.Pause() end
					return
				end
				if protectFromSun(character) then
					aimAllowed = false
					return
				end
				if library.Visible or library.MouseCaptured then
					aimAllowed = false
					clearWorldFocus()
					releaseAll()
					if bounties.Pause then bounties.Pause() end
					return
				end
				pollInteraction()
				if settings.Fly and not locked() and not attr(character, "Stunned") and attr(game.Workspace, "TimeScale") ~= 0 then
					aimAllowed = false
					if currentJob and currentJob.stop then
						currentJob.stop()
					end
					currentJob = nil
					releaseAll()
					local camera = game.Workspace.Camera
					local direction = v3(0, 0, 0)
					if iskeypressed(87) then
						direction = direction + camera.CFrame.LookVector
					end
					if iskeypressed(83) then
						direction = direction - camera.CFrame.LookVector
					end
					if iskeypressed(68) then
						direction = direction + camera.CFrame.RightVector
					end
					if iskeypressed(65) then
						direction = direction - camera.CFrame.RightVector
					end
					if iskeypressed(32) then
						direction = direction + v3(0, 1, 0)
					end
					if iskeypressed(162) then
						direction = direction - v3(0, 1, 0)
					end
					if tick() - lastMove >= 0.2 then
						local now = tick()
						if not flyPoint or flyAddress ~= root.Address or now - flyAt > 0.5 then
							flyPoint, flyAt, flyVelocityY, flyGravity, flyAddress = root.Position, now - 0.2, nil, 196.2, root.Address
						end
						local elapsed = now - flyAt
						if flyVelocityY then
							local gravity = (flyVelocityY - root.AssemblyLinearVelocity.Y) / elapsed
							if finite(gravity) and gravity >= 0 and gravity <= 400 then flyGravity = gravity end
						end
						if (flyPoint - root.Position).Magnitude > settings.FlySpeed * elapsed * 2 then flyPoint = root.Position end
						local movement = direction.Magnitude > 0 and direction.Unit * settings.FlySpeed or v3(0, 0, 0)
						flyPoint = flyPoint + movement * elapsed
						-- Gravity continues between the five-per-second updates.
						local velocity = (flyPoint - root.Position) / elapsed + v3(0, flyGravity * elapsed / 2, 0)
						root.AssemblyLinearVelocity = velocity
						lastMove, flyAt, flyVelocityY = now, now, velocity.Y
						runtime.Metrics.PositionWrites = runtime.Metrics.PositionWrites + 1
					end
					return
				end
				flyPoint, flyVelocityY, flyAddress = nil, nil, nil
				local jumpDown = iskeypressed(32)
				if settings.HighJump or settings.InfiniteJump then
					local velocity, now = root.AssemblyLinearVelocity, tick()
					if settings.HighJump and jumpDown and not jumpWasDown then highJumpUntil = now + 0.25 end
					if not settings.HighJump or now > highJumpUntil or locked() or attr(character, "Stunned") then
						highJumpReady = false
					elseif lastJumpVelocityY and velocity.Y > 1 and velocity.Y - lastJumpVelocityY > 10 then
						highJumpReady = true
					end
					if
						(settings.InfiniteJump and jumpDown and not jumpWasDown or highJumpReady)
						and not locked()
						and not attr(character, "Stunned") and attr(game.Workspace, "TimeScale") ~= 0
						and now - lastMove >= 0.2
					then
						root.AssemblyLinearVelocity = v3(velocity.X, settings.JumpVelocity, velocity.Z)
						lastMove, highJumpUntil, highJumpReady = now, 0, false
						runtime.Metrics.PositionWrites = runtime.Metrics.PositionWrites + 1
					end
					lastJumpVelocityY = root.AssemblyLinearVelocity.Y
				else
					lastJumpVelocityY, highJumpUntil, highJumpReady = nil, 0, false
				end
				jumpWasDown = jumpDown
				if currentJob and (not settings[currentJob.toggle] or runtime.Errors[currentJob.name]) then
					if currentJob.stop then
						currentJob.stop()
					end
					currentJob = nil
					clearWorldFocus()
					releaseAll()
					interaction = nil
				end
				local busy, chosen = currentJob and currentJob.busy and currentJob.busy(), currentJob
				if attr(player, "GrowingInputOwner") ~= nil then
					if currentJob and currentJob.name ~= "Harvest" then
						if currentJob.stop then currentJob.stop() end
						releaseAll()
						clearWorldFocus()
						interaction = nil
						currentJob, chosen = nil, nil
					end
					if not currentJob and settings.AutoHarvest and not runtime.Errors.Harvest then
						for _, job in ipairs(jobs) do
							if job.name == "Harvest" and job.ready() then chosen = job; break end
						end
					end
				elseif not locked() and not attr(character, "ArmWrestlingSession") then
					chosen = chooseJob(jobs, busy and (settings[currentJob.priority] or 0) or nil)
					if busy and not chosen then chosen = currentJob end
				elseif not currentJob and settings.AutoBounties and not runtime.Errors.Bounties then
					local title = child(child(child(child(player, "PlayerGui"), "Dialogue"), "Holder"), "Title")
					local part = child(child(child(world, "NPCs"), "Petyr"), "HumanoidRootPart")
					if attr(player, "QTEInputLocked") == true and bounties.Ready()
						or attr(player, "DialogueInputLocked") == true and type(bounties.ResumeDialogue) == "function" and bounties.ResumeDialogue()
						or attr(player, "DialogueInputLocked") == true and title and title.Text == "Petyr" and part and part.Parent
						and validPosition(part.Position) and (root.Position - part.Position).Magnitude <= 8 then
						for _, job in ipairs(jobs) do if job.name == "Bounties" then chosen = job; break end end
					end
				end
				if chosen ~= currentJob then
					if currentJob and currentJob.stop then currentJob.stop() end
					releaseAll()
					clearWorldFocus()
					interaction = nil
					currentJob = chosen
					if chosen and type(setrobloxinput) == "function" then setrobloxinput(true) end
				end
				if currentJob then
					aimAllowed = settings.AimAssist and not locked() and (currentJob.name == "Bounties" or currentJob.name == "Bosses"
						or currentJob.name == "Mobs" or currentJob.name == "PlayerEliminations" or currentJob.name == "PhoneEliminations")
					if aimAllowed then turnAimCamera() end
					local success, failure = pcall(currentJob.step)
					if not success then
						aimAllowed = false
						runtime.Errors[currentJob.name] = tostring(failure)
						setStatus(currentJob.name, "Paused: " .. tostring(failure))
						if currentJob.stop then
							currentJob.stop()
						end
						releaseAll()
						currentJob = nil
					end
				elseif
					settings.AutoSummon
					and not locked()
					and attr(character, "Summoned") ~= true
					and tick() - lastSummon > 2
				then
					tap(bind("Summon", "E"))
					lastSummon = tick()
				end
				if settings.AimAssist and not currentJob and not locked() then
					aimAllowed = true
					aimAt(manualAimTarget())
					turnAimCamera()
				elseif not currentJob then
					aimAllowed = false
				end
			end)
			if not ok then
				aimAllowed = false
				setStatus("Runtime", tostring(err))
				releaseAll()
			end
			task.wait(currentJob and 0.025 or 0.05)
		end
	end)
	print("Stand Out loaded. Right Ctrl: menu. _G.StandOut.Stop(): unload. All farms off.")
	return runtime
end
_G.StandOutBootstrap = function()
	local ok, result = pcall(startStandOut)
	if not ok then
		if _G.StandOut and _G.StandOut.Stop then
			_G.StandOut.Stop()
		end
		if _G.Library and not _G.Library.Unloaded then
			_G.Library:Unload()
		end
		error(result)
	end
	return result
end
end
_G.StandOutBootstrap()
