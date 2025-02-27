local addonName, addonTable = ...;

local mod = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0")


-- GLOBAL_enhancedroll = addonTable	-- debug

local AceConfig = 	LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB =		LibStub("AceDB-3.0")
local AceGUI = 		LibStub("AceGUI-3.0");

local CMD = "ms"
local CMD_2 = "marktschreier"
local db

local MyGlobalFrameName = addonName .. "_GlobalFrame"
local _, addon_title = GetAddOnInfo(addonName)
local addon_version = GetAddOnMetadata(addonName, "Version") 

local colors = addonTable.Colors
local func = addonTable.Functions
local colText = func.colText


local UI = {}
addonTable.UI = UI


local default_options = { 
	global = { 
		["options"] = {
			["channelName"] = "world",
			["watchString"] = "ðesert",
			["timeInterval"] = 3,
		},
		["message"] = "{rt2} Ulduar 25 von Ðesert/Wulfo jeden DO 19:00 am FP {rt2} \124cffff8000\124Hitem:45038:0:0:0:0:0:0:0:80\124h[Fragment von Val'anyr]\124h\124r nach Anwesenheitsliste {rt2} Enhanced Roll auf \124cffa335ee\124Hitem:45693:0:0:0:0:0:0:0:0\124h[Mimirons Kopf]\124h\124r\n\n",
	},
}

local interval_list = {str = {}, num = {10, 20, 30, 60} }
for k,v in ipairs(interval_list.num) do
	interval_list.str[k] = string.format("%imin",v)
end


function mod:print(...)
	local tmp={}
	local n=1
	tmp[n] = colText(colors.orange, "MS:")
	
	for i=1, select("#", ...) do
		n=n+1
		tmp[n] = tostring(select(i, ...))
	end
	DEFAULT_CHAT_FRAME:AddMessage( table.concat(tmp," ",1,n) )
end


function mod:OnInitialize()
	mod:GetDB()
end

function mod:OnEnable()
    mod:RegisterEvent("PLAYER_ENTERING_WORLD")
    mod:RegisterEvent("CHAT_MSG_CHANNEL")
	
	mod:RegisterChatCommand(CMD, "OnSlashCommand")
	mod:RegisterChatCommand(CMD_2, "OnSlashCommand")
	mod:CreateUI()
	UI.main_frame:Hide()
end

function mod:OnDisable()
end



function mod:CHAT_MSG_CHANNEL(event,...)
	-- if not UI.main_frame:IsShown() then return end
	local msg, author,_,_,_,_,_,chNum,chName = ...
	-- msg = string.gsub(msg,"\124H.+\124h","")
	msg = string.lower(msg)
	chName = string.lower(chName)
	if chName == db.options.channelName then
		if string.find(msg, db.options.watchString) then
			mod:print(string.format("[%s]: %s",author, msg) )
			addonTable.epochMsgFlag = false
			mod:UnregisterEvent("CHAT_MSG_CHANNEL")
		end
	end
end



function mod:PLAYER_ENTERING_WORLD(event)
	mod:UnregisterEvent("PLAYER_ENTERING_WORLD");
	
	mod:ScheduleTimer("WelcomeMessage", 3) -- wait 3 secs after changing zones
end

function mod:WelcomeMessage()
	mod:print("Martschreier by Telkar@Rising-Gods (/"..colText(colors.lightblue, CMD)..")")
	mod:checkIfInChannel(db.options.channelName)
end



function mod:GetDB()
	addonTable.db = AceDB:New(addonName.."_DB", default_options, true)
	db = addonTable.db.global
	
	db.options.channelName = db.options.channelName or "world"
	db.options.watchString = db.options.watchString or "ulduar"
	db.options.timeInterval = db.options.timeInterval or 1
	db.options.timeInterval = max( min(db.options.timeInterval, #(interval_list.num) ), 1)
	
	db.message = db.message or ""
	
	
end


local function text_split(txtIn)
	-- mod:print("text_split")
	local temp = txtIn
	local t = {}
	
	local cnt = 1
	while cnt > 0 do
		txtIn, cnt = string.gsub(txtIn, "\n\n", "\n")
	end
	
	local maxLen = 256
	-- if string.len(txtIn) <= maxLen then
		-- return {txtIn}
	-- end
	
	local contFlag = true
	while contFlag do
		-- print("--/n",string.find(temp,"\n"))
		local cut
		local res
		for i=maxLen, 1, -1 do 
			res = string.find(temp, "\n")
			if res and res <= maxLen then
				-- MPrint("found a newline at",res)
				cut = res
				break
			end
			
			res = string.find(temp, " ", i, 1)
			if not res then 
				cut = maxLen
				break
			end
			if res <= maxLen then
				-- MPrint("found a space at",res)
				cut = res
				break
			end
		end
		table.insert(t, strtrim(string.sub(temp, 1, cut-1)) )
		temp = strtrim(string.sub(temp, cut+1))
		
		if string.len(temp) <= maxLen then 	contFlag = false end
		if string.find(temp, "\n") then		contFlag = true end
	end
	table.insert(t, temp)
	
	return t
end

local function txtbox_handler(textTBL)
	local txtIn = textTBL:GetText()
	
	txtIn = tostring(txtIn):trim()	
	
	local t = text_split(txtIn)
	txtIn = table.concat(t, "\n\n")
	db.message = txtIn
	textTBL:SetText(txtIn)
	-- mod:print("txtbox_handler")
end

local function txt_handler_channelName(textTBL)
	-- mod:print(textTBL)
	local txtIn = textTBL:GetText()
	txtIn = ( tostring(txtIn):trim() ):lower()
	if txtIn == "" then
		txtIn = db.options.channelName or "world"
	end
	txtIn = mod:checkIfInChannel(txtIn)
	txtIn = txtIn or db.options.channelName or "world"
	
	db.options.channelName = txtIn
	textTBL:SetText(txtIn)
	-- mod:print("txt_handler_channelName:", txtIn)
end

function mod:checkIfInChannel(channelName)
	local chList = {GetChannelList()}
	for i,v in ipairs(chList) do
		if type(v)=="string" and v==channelName then
			addonTable.channelNumber = chList[i-1]
			mod:print(string.format("Will use Channel [%i. %s] for messages", addonTable.channelNumber, v) )
			return channelName
		end
	end
end


local function txt_handler_watchString(textTBL)
	-- mod:print(textTBL)
	local txtIn = textTBL:GetText()
	txtIn = ( tostring(txtIn):trim() ):lower()
	if string.len(txtIn) < 3 then
		txtIn = db.options.watchString or "ulduar"
		mod:print("Watch string must be at least 3 characters!")
	end
	db.options.watchString = txtIn
	textTBL:SetText(txtIn)
	-- mod:print("txt_handler_watchString:", txtIn)
end




-- UI
function mod:CreateUI()
	UI.main_frame = AceGUI:Create("Frame", addonName)
	
	UI.main_frame:SetTitle( format("%s (%s)", tostring(addon_title), tostring(addon_version)) )
	UI.main_frame:SetLayout("Flow")
	UI.main_frame:SetFullWidth(true)
	UI.main_frame:SetFullHeight(true)
	UI.main_frame:SetWidth(600)
	UI.main_frame:SetHeight(400)
	UI.main_frame:SetCallback("OnClose", function() UI.main_frame:Hide() end)

	-- splitting the main frame
	UI.simple_group_1 = AceGUI:Create("SimpleGroup")
	UI.simple_group_1:SetLayout("Flow")
	UI.simple_group_1:SetFullHeight(true)
	UI.simple_group_1:SetFullWidth(true)
	
	-- options grp
	UI.SimpleGroup_options = AceGUI:Create("SimpleGroup")
	UI.SimpleGroup_options:SetLayout("Flow")
	-- UI.SimpleGroup_options:SetFullHeight(true)
	UI.SimpleGroup_options:SetFullWidth(true)



	UI.head_separator = AceGUI:Create("Heading")
	UI.head_separator:SetText("")
	UI.head_separator:SetFullWidth(true)

	UI.editbox_channelName = AceGUI:Create("EditBox")
	UI.editbox_channelName:SetLabel("Channel Name")
	UI.editbox_channelName:SetText(db.options.channelName or "")
	UI.editbox_channelName:SetWidth(150)
	UI.editbox_channelName:SetCallback("OnEnterPressed", txt_handler_channelName )

	UI.editbox_watchWord = AceGUI:Create("EditBox")
	UI.editbox_watchWord:SetLabel("Watch for Keyword")
	UI.editbox_watchWord:SetText(db.options.watchString or "")
	UI.editbox_watchWord:SetWidth(150)
	UI.editbox_watchWord:SetCallback("OnEnterPressed", txt_handler_watchString )

	-- UI.slider_interval_LIST = {"15min", "30min", "1h    "}
	UI.slider_interval = AceGUI:Create("Slider")
	UI.slider_interval:SetSliderValues(1, #(interval_list.num), 1) 
	UI.slider_interval:SetValue( db.options.timeInterval or 1 )
	UI.slider_interval:SetLabel("Interval: "..tostring(interval_list.str[db.options.timeInterval or 1]) )
	UI.slider_interval:SetWidth(100)
	UI.slider_interval:SetCallback("OnValueChanged", 
	function(val) 
		local selVal = max( min(val.value, #(interval_list.num) ), 1)
		db.options.timeInterval = selVal
		UI.slider_interval:SetLabel("Interval: "..tostring(interval_list.str[selVal]) ) 
	end)

	UI.button_start = AceGUI:Create("Button")
	UI.button_start:SetText("Start")
	UI.button_start:SetWidth(75)
	UI.button_start:SetDisabled(false)
	UI.button_start:SetCallback("OnClick", function() 
		UI.button_start:SetDisabled(true)
		UI.button_stop:SetDisabled(false)
		mod:startTimerNextEpoch()
		mod:print("Start") 
	end )

	UI.button_stop = AceGUI:Create("Button")
	UI.button_stop:SetText("Stop")
	UI.button_stop:SetWidth(75)
	UI.button_stop:SetDisabled(true)
	UI.button_stop:SetCallback("OnClick", function()
		UI.button_start:SetDisabled(false)
		UI.button_stop:SetDisabled(true)
		mod:CancelAllTimers()
		mod:print("Stop")
	end )
	


	UI.MultiLineEditBox_TXT = AceGUI:Create("MultiLineEditBox")
	UI.MultiLineEditBox_TXT:SetLabel("Message Text (max 255 Zeichen pro Zeile, mehrere Zeilen-Nachricht möglich)")
	UI.MultiLineEditBox_TXT:SetText("")
	UI.MultiLineEditBox_TXT:SetFullWidth(true)
	UI.MultiLineEditBox_TXT:SetFullHeight(true)
	UI.MultiLineEditBox_TXT:SetCallback("OnEnterPressed", txtbox_handler)
	-- UI.MultiLineEditBox_TXT:SetCallback("OnEnter", function() 
			-- UI.main_frame:SetStatusText("Addon Info Text") 
		-- end )
	-- UI.MultiLineEditBox_TXT:SetCallback("OnLeave", function() UI.main_frame:SetStatusText("") end )


	-- create the frame
	UI.main_frame:AddChild(UI.simple_group_1)
	
	UI.SimpleGroup_options:AddChild(UI.editbox_channelName)
	UI.SimpleGroup_options:AddChild(UI.editbox_watchWord)
	UI.SimpleGroup_options:AddChild(UI.slider_interval)
	UI.SimpleGroup_options:AddChild(UI.button_start)
	UI.SimpleGroup_options:AddChild(UI.button_stop)
	
	UI.simple_group_1:AddChild(UI.SimpleGroup_options)
	
	
	UI.simple_group_1:AddChild(UI.head_separator)
	
	
	UI.simple_group_1:AddChild(UI.MultiLineEditBox_TXT)
	
	-- add to UISpecialFrames, so it closes on ESC key
	_G[MyGlobalFrameName] = UI.main_frame.frame 	-- Add the frame as a global variable
	tinsert(UISpecialFrames, MyGlobalFrameName)
end


function mod:ShowUI()
	local msg = db.message or ""
	local t = text_split(msg)
	msg = table.concat(t, "\n\n")
	UI.MultiLineEditBox_TXT:SetText(msg)
	
	UI.main_frame:Show()
end


function mod:startTimerNextEpoch()
	if not addonTable.channelNumber then
		mod:checkIfInChannel(db.options.channelName)
		
		if not addonTable.channelNumber then
			mod:print("aborted, no channel number." )
			mod:CancelAllTimers()
			return
		end
	end
	
	local intervalIdx = db.options.timeInterval or 1
	local epoch =  60 * interval_list.num[intervalIdx]
	local t = date("*t",time())
	local secs = t.sec + 60*t.min
	local timeToEpoch = (-secs)%epoch - 60
	if timeToEpoch < 10 then
		timeToEpoch = timeToEpoch + epoch
	end
	-- ScheduleTimer(callback, delay, arg)
	mod:ScheduleTimer("startEpochCheck", timeToEpoch)
	if DBM then DBM:CreatePizzaTimer(timeToEpoch-1, "Marktschreier") end
	-- if DBM then SlashCmdList["DEADLYBOSSMODS"](format("timer %.0f Marktschreier",timeToEpoch-1)) end
	mod:print("Next Check in: "..SecondsToTime(timeToEpoch) )
	-- mod:print("channel nr: "..tostring(addonTable.channelNumber) )
end

function mod:startEpochCheck()
	mod:startTimerNextEpoch()
	
	local checkTime = random(60,2*60)
	-- ScheduleTimer(callback, delay, arg)
	addonTable.epochMsgFlag = true
    mod:RegisterEvent("CHAT_MSG_CHANNEL")
	
	if DBM then DBM:CreatePizzaTimer(checkTime, "Msg in") end
	-- if DBM then SlashCmdList["DEADLYBOSSMODS"](format("timer %.0f Msg in",checkTime)) end
	mod:ScheduleTimer("sendEpochMsg", checkTime)
	mod:print("Try to send Message in: "..SecondsToTime(checkTime) )
end

function mod:sendEpochMsg()
	if addonTable.epochMsgFlag and addonTable.channelNumber then
		mod:UnregisterEvent("CHAT_MSG_CHANNEL")
		local t = text_split(db.message)
		for i,txt in ipairs(t) do
			SendChatMessage(txt, "CHANNEL", nil, addonTable.channelNumber);
		end
		mod:print("msg send to channel success")
	end
end


function mod:OnSlashCommand(input)
	-- MPrint("OnSlashCommand:", input)	-- DEBUG
	
	if input then input = strlower(input):trim() end
	
	local t = {}
	for str in string.gmatch(input, "%S+") do table.insert(t, str) end
	local argCmd, arg1, arg2 = t[1], t[2], t[3]
	
	if (not argCmd) then	-- no cmd args
		mod:ShowUI()
		
	elseif (argCmd == "start") then
		
	else
		
	end
end

