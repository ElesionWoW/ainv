--Set up Constants
local ainvState = {"|cFFFF0000disabled|r","|cFF00FF00enabled|r"}

--Set up Variables
local invEnabled = 0
local invKeyword = ""
local ownRaidIndex = 0

--FRAMES & EVENTS
ainv = CreateFrame("Frame"); -- Event Frame

function ainv:OnEvent()
	if event == "CHAT_MSG_WHISPER" then
		local message = arg1
		local applicant = arg2
		
		if message == invKeyword then
			--we're alone
			if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
				InviteByName(applicant)
			--we're in a party
			elseif GetNumRaidMembers() == 0 then
				if UnitIsPartyLeader("PLAYER") == 1 then
					if GetNumPartyMembers() < 4 then
						InviteByName(applicant)
					else
						ConvertToRaid()
						InviteByName(applicant)
					end
				else
					ainv:PrintConsoleMessage("ainv", "Auto-invite failed because you are not the leader of the party.", 1)
				end
			--we're in a raid with open slots
			elseif GetNumRaidMembers() < 40 then
				if ainv:OwnRaidRank() > 0 then
					InviteByName(applicant)
				else
					ainv:PrintConsoleMessage("ainv", "Auto-invite failed because you don't have raid invite permissions (lead, assist).", 1)
				end
			--we're in a raid but it is full
			else
				--possible whisper back to applicant
			end
		end
	end
end

ainv:SetScript("OnEvent", ainv.OnEvent)


--SLASH COMMANDS
function ainvCommands(arg)
	if arg == "" then
		ainv:ReportState(1)
	elseif arg == "help" then
		ainv:PrintConsoleMessage("ainv", "This is help topic for |cFFFFFF00/ainv|r")
		ainv:PrintConsoleMessage("ainv", "Report current state: |cFFFFFF00/ainv|r")
		ainv:PrintConsoleMessage("ainv", "Set keyword: |cFFFFFF00/ainv set [keyword]|r")
		ainv:PrintConsoleMessage("ainv", "Toggle on or off: |cFFFFFF00/ainv toggle|r")
	elseif arg == "toggle" then
		if invEnabled ~= 1 then
			ainv:SetState(1)
		else
			ainv:SetState(0)
		end
		ainv:ReportState(0)
	elseif string.sub(arg,1,3) == "set" then
		if string.len(arg) > 4 then
			invKeyword = string.sub(arg,5)
			if invEnabled ~= 1 then
				ainv:SetState(1)
			end
			ainv:ReportState(0)
		else
			ainv:PrintConsoleMessage("ainv", "Keyword missing. Use the format |cFFFFFF00/ainv set [keyword]|r", 1)
		end
	else
		ainv:PrintConsoleMessage("ainv", "Unknown command. Use |cFFFFFF00/ainv help|r for a list.", 1)
	end
end

SlashCmdList['AINV'] = ainvCommands
SLASH_AINV1 = '/ainv'


--FUNCTIONS
function ainv:ReportState(help)
	local output = "Auto-invites are currently "..ainvState[invEnabled+1]
	
	if invKeyword == nil or invKeyword == "" then
		output = output..". Keyword currently not set."
	else
		output = output..". Current keyword is |cFFF281EA"..invKeyword.."|r."
	end
	
	if help == 1 then
		output = output.." Commands: |cFFFFFF00/ainv help|r."
	end
	ainv:PrintConsoleMessage("ainv", output)
end

function ainv:SetState(target)
	if target == 0 then
		invEnabled = 0
		ainv:UnregisterEvent("CHAT_MSG_WHISPER")
	end
	if target == 1 then
		if invKeyword == nil or invKeyword == "" then
			ainv:PrintConsoleMessage("ainv", "No keyword set. Use |cFFFFFF00/ainv set [keyword]|r before turning on auto-invites.", 1)
		else
			invEnabled = 1
			ainv:RegisterEvent("CHAT_MSG_WHISPER")
		end
	end
end

function ainv:OwnRaidRank()
	--if our own raid index is unknown, crawl roster until we find ourselves
	if ownRaidIndex == 0 or ainv:ValidateRaidIndex(ownRaidIndex) == 0 then
		for i=1,GetNumRaidMembers() do
			if ainv:ValidateRaidIndex(i) == 1 then
				ownRaidIndex = i
				break
			end			
		end
	end
	
	local _,rank = GetRaidRosterInfo(ownRaidIndex)
	return rank
end

function ainv:ValidateRaidIndex(raidIndex)
	if GetRaidRosterInfo(raidIndex) == UnitName("PLAYER") then
		return 1
	else
		return 0
	end
end


--OUTPUTS
function ainv:PrintConsoleMessage(prefix, message, style)
	local output = "|cFFF281EA"..prefix..":|r "..message
	if style == nil or style == 0 then --default (white)
		DEFAULT_CHAT_FRAME:AddMessage(output,1,1,1)
	elseif style == 1 then --error (red)
		DEFAULT_CHAT_FRAME:AddMessage(output,1,0,0)
	end
end


