local EVENT_META = {}
EVENT_META.__index = EVENT_META

if SERVER then
	function EVENT_META:End(...)
		return eventsystem.End(self:GetIdentifier(), ...)
	end
end

function EVENT_META:GetEventName()
	return self.EventName
end

function EVENT_META:GetName()
	return self.Name
end

function EVENT_META:GetIdentifier()
	return self.Identifier
end

function EVENT_META:GetStart()
	return self.Start
end

function EVENT_META:Announce(message, time, recipients)
	return eventsystem.Announce(message, time, recipients)
end

function EVENT_META:AddHook(name, unique, func)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Hooks[name] then
		self.Hooks[name] = {}
	end

	self.Hooks[name][unique] = true
	hook.Add(name, unique, function(...)
		return func(self, ...)
	end)
end

function EVENT_META:RemoveHook(name, unique)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Hooks[name] or not self.Hooks[name][unique] then
		return
	end

	self.Hooks[name][unique] = nil
	hook.Remove(name, unique)
end

function EVENT_META:RemoveHooks(name)
	if name and not self.Hooks[name] then
		return
	end

	if name then
		for unique, _ in pairs(self.Hooks[name]) do
			hook.Remove(name, unique)
		end

		self.Hooks[name] = nil
	else
		for name, list in pairs(self.Hooks) do
			for unique, _ in pairs(list) do
				hook.Remove(name, unique)
			end
		end

		self.Hooks = {}
	end
end

function EVENT_META:AddTimerSimple(delay, func)
	timer.Simple(delay, function()
		func(self)
	end)
end

function EVENT_META:AddTimer(unique, delay, reps, func)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)

	self.Timers[unique] = true
	timer.Create(unique, delay, reps, function()
		func(self)
	end)
end

function EVENT_META:RemoveTimer(unique)
	unique = ("eventsystem_%s%i_%s"):format(self.EventName, self.Identifier, unique)
	if not self.Timers[unique] then
		return
	end

	self.Timers[unique] = nil
	timer.Remove(unique)
end

function EVENT_META:RemoveTimers()
	for unique, _ in pairs(self.Timers) do
		timer.Remove(unique)
	end

	self.Timers = {}
end

function eventsystem.Wrap(tbl)
	return setmetatable(tbl, EVENT_META)
end