local _, NSI = ... -- Internal namespace

function NSI:CreateInterruptDisplay()
    if not self.InterruptDisplay then
        self.InterruptDisplay = CreateFrame("Frame", "NSIInterruptDisplay", NSI.NSRTFrame)
        self.InterruptDisplay.Box = self.InterruptDisplay:CreateTexture(nil, "ARTWORK")
        self.InterruptDisplay.Box:SetColorTexture(0, 0, 0, 1)
        self.InterruptDisplay.Box:SetAllPoints()
        self.InterruptDisplay.Border = self.InterruptDisplay:CreateTexture(nil, "BACKGROUND")
        self.InterruptDisplay.Border:SetColorTexture(0, 0, 0, 1)
        self.InterruptDisplay.Border:SetPoint("TOPLEFT", self.InterruptDisplay, "TOPLEFT", -1, 1)
        self.InterruptDisplay.Border:SetPoint("BOTTOMRIGHT", self.InterruptDisplay, "BOTTOMRIGHT", 1, -1)
        self.InterruptDisplay.Number = self.InterruptDisplay:CreateFontString(nil, "OVERLAY")
        self.InterruptDisplay.Number:SetTextColor(1, 0, 0, 1)
        self.InterruptDisplay.Name = self.InterruptDisplay:CreateFontString(nil, "OVERLAY")
        self.InterruptDisplay.Name:SetTextColor(1, 1, 1, 1)
    end
    self.InterruptDisplay:ClearAllPoints()
    self.InterruptDisplay:SetSize(NSRT.InterruptSettings.Width, NSRT.InterruptSettings.Height)
    self.InterruptDisplay:SetPoint(NSRT.InterruptSettings.Point, NSI.NSRTFrame, NSRT.InterruptSettings.RelativePoint, NSRT.InterruptSettings.XOffset, NSRT.InterruptSettings.YOffset)
    self.InterruptDisplay.Number:ClearAllPoints()
    self.InterruptDisplay.Number:SetPoint(NSRT.InterruptSettings.NumberPoint, self.InterruptDisplay, NSRT.InterruptSettings.NumberRelativePoint, NSRT.InterruptSettings.NumberXOffset, NSRT.InterruptSettings.NumberYOffset)
    self.InterruptDisplay.Number:SetFont(self.LSM:Fetch("font", NSRT.InterruptSettings.NumberFont), NSRT.InterruptSettings.NumberFontSize, NSRT.InterruptSettings.NumberFontFlags)
    self.InterruptDisplay.Name:ClearAllPoints()
    self.InterruptDisplay.Name:SetPoint(NSRT.InterruptSettings.NamePoint, self.InterruptDisplay, NSRT.InterruptSettings.NameRelativePoint, NSRT.InterruptSettings.NameXOffset, NSRT.InterruptSettings.NameYOffset)
    self.InterruptDisplay.Name:SetFont(self.LSM:Fetch("font", NSRT.InterruptSettings.NameFont), NSRT.InterruptSettings.NameFontSize, NSRT.InterruptSettings.NameFontFlags)
end

function NSI:DisplayInterrupt(shouldHide)
    local unit = self.Interrupts.myTable[self.Interrupts.castCount]
    local name = unit and UnitExists(unit) and NSAPI:Shorten(unit, 8, false, "GlobalNickNames", false, false) or ""
    self:CreateInterruptDisplay()
    self.InterruptDisplay.Number:SetText(self.Interrupts.castCount or "")
    self.InterruptDisplay.Name:SetText(name)
    if self.Interrupts.castCount == self.Interrupts.myKick then -- player interrupts now
        self.InterruptDisplay.Box:SetColorTexture(0, 1, 0, 1)
    elseif (self.Interrupts.castCount+1 == self.Interrupts.myKick) or (self.Interrupts.myKick == 1 and self.Interrupts.castCount >= self.Interrupts.max) then -- player interrupts next
        self.InterruptDisplay.Box:SetColorTexture(1, 1, 0, 1)
    else
        self.InterruptDisplay.Number:SetTextColor(1, 1, 1, 1)
        self.InterruptDisplay.Box:SetColorTexture(1, 0, 0, 1)
    end
    if shouldHide and self.Interrupts.castCount > self.Interrupts.myKick then
        self:HideInterrupt()
    else
        self.InterruptDisplay:Show()
    end
end

function NSI:PlayInterruptSound()
    PlaySoundFile(NSI.LSM:Fetch("sound", NSRT.InterruptSettings.Sound), "Master")
end

function NSI:HideInterrupt()
    if self.InterruptDisplay then
        self.InterruptDisplay:Hide()
    end
end

function NSI:ResetInterrupts()
    self.Interrupts.castCount = 0
    self.Interrupts.myTrackedID = self.Interrupts.myID
    self:HideInterrupt()
end

function NSI:InterruptOnCastStart(shouldHide)
    if not self.Interrupts or self.Interrupts.disabled then return end
    if self.Interrupts.myTrackedID == 0 then return end
    self:DisplayInterrupt(unit, self.Interrupts.castCount, shouldHide)
    if self.Interrupts.castCount == self.Interrupts.myKick then
        self:PlayInterruptSound()
    end
end

function NSI:OnInterrupt(shouldHide)
    if not self.Interrupts or self.Interrupts.disabled then return end
    self.Interrupts.castCount = self.Interrupts.castCount + 1
    if self.Interrupts.myTrackedID == 0 then return end
    self:DisplayInterrupt(unit, self.Interrupts.castCount, shouldHide)
end

function NSI:ReadInterruptNote(StartNumber)
    local pers, shared = NSAPI:GetReminderString()
    if not pers then pers = "" end
    if not shared then shared = "" end
    local MRT = C_AddOns.IsAddOnLoaded("MRT") and _G.VMRT.Note.Text1 or ""
    local str = shared..pers..MRT
    local count = StartNumber or 0
    self.Interrupts = self.Interrupts or {}
    self.Interrupts.assignTable = {}
    self.Interrupts.myID = 0
    self.Interrupts.myKick = 0
    self.Interrupts.myTrackedID = 0
    self.Interrupts.castCount = 0
    self.Interrupts.disabled = false
    self.Interrupts.max = 0
    self.Interrupts.myTable = {}
    local assign = false
    for line in string.gmatch(str,'[^\r\n]+') do
        line = strtrim(line)
        if strlower(line) == "intend" then
            assign = false
            self.Interrupts.myTrackedID = self.Interrupts.myID
            self.Interrupts.myTable = self.Interrupts.assignTable[self.Interrupts.myID] or {}
            break
        elseif strlower(line) == "intstart" then
            assign = true
        elseif assign then
            local num = 0
            count = count+1
            self.Interrupts.assignTable[count] = self.Interrupts.assignTable[count] or {}
            for name in line:gmatch("%S+") do
                if UnitInRaid(name) then
                    num = num+1
                    table.insert(self.Interrupts.assignTable[count], name)
                    if UnitIsUnit(name, "player") then
                        self.Interrupts.myID = count
                        self.Interrupts.myKick = num
                    end
                    if count == self.Interrupts.myID then
                        self.Interrupts.max = #self.Interrupts.assignTable[count]
                    end
                end
            end
        end
    end
end