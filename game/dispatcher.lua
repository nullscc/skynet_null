local CDispatcher = class()

function CDispatcher:actor()
	self.routines = {}
end

function CDispatcher:register(pbName, cb, obj)
    if type(cb) == "function" then
        self.routines[pbName] = {cb,obj}
    else 
        print("register message[%s] callback error, cb is nil.", pbName)
    end
end

function CDispatcher:dispatch(pbName, msg)
    if not pbName or not msg then return end

    local routine = self.routines[pbName]
    if type(routine) ~= "table" then
		print("Can't find callback of message[%s]", pbName)
        return false
    end
	
	if routine[2] then
		routine[1](routine[2], msg)
	else
		routine[1](msg)
	end
end

return CDispatcher
