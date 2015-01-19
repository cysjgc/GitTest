module(..., package.seeall)

class = objectlua.Object:extend()

function class:initialize(socket)
	self.socket = socket
end

function class:read(size)
	if type(size) == "string" then
		local fmt = size
		return struct.unpack(fmt, self:read(struct.size(fmt)))
	end
	
	local data, err = self.socket:receive(size)
	if data == nil then
		error(err)
	end
	
	return data
end

