local hideseek = {}
hideseek.Name = "Hide & Seek"
if CLIENT then
	eventsystem:RegisterEvent(hideseek)
	return
end

function hunterhunted:EndEvent(forced)
	if forced then
		self:AnnounceEveryone("The Hide & Seek event was forced to end.", 5)
		return
	end

	
end

function hunterhunted:StartEvent()

end

eventsystem:RegisterEvent(hideseek)