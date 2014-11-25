local hideseek = {}

eventsystem:Register("hide_and_seek", hideseek)

if CLIENT then
	return
end

function hideseek:EndEvent(forced)
	if forced then
		self:Announce("The Hide & Seek event was forced to end.", 5)
		return
	end

	
end

function hideseek:StartEvent()

end