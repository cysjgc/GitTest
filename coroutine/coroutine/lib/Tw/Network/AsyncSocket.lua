local socket	= require "socket"
local Service	= require "Tw.Network.Service"

module(..., package.seeall)

local internal

function tcp()
	return internal.class:new()
end

class = objectlua.Object:subclass()

function class:initialize()
	self.skt = socket.tcp()
	self.skt:settimeout(0)
	self.timeout = math.huge
end

function class:close()
	Service:getSingleton():clean(self.skt)
	return self.skt:close()
end

function class:connect(address, port)
	local succ, err = self.skt:connect(internal:toip(address), port)
	if err ~= "timeout" then
		return succ, err
	end
	
	if not Service:getSingleton():waitSend(self.skt, self.timeout) then
		return nil, "timeout"
	end
	
	return 1
end

function class:getpeername()
	return self.skt:getpeername()
end

function class:getsockname()
	return self.skt:getsockname()
end

function class:getstats()
	return self.skt:getstats()
end

function class:receive(pattern, prefix)
	repeat
		local succ, err, part = internal:receive(self.skt, pattern, prefix)
		if succ or err ~= "timeout" then
			return succ, err, part
		end
		
		if type(pattern) == "number" then
			pattern = pattern - (#part - #(prefix or ""))
		end
		
		prefix = part
		
		if not Service:getSingleton():waitRecv(self.skt, self.timeout) then
			return nil, "timeout", part
		end
	until false
end

function class:send(data, i, j)
	repeat
		local succ, err, idx = self.skt:send(data, i, j)
		if succ or err ~= "timeout" then
			return succ, err, idx
		end
		
		i = idx + 1
		
		if not Service:getSingleton():waitSend(self.skt, self.timeout) then
			return nil, "timeout", idx
		end
	until false
end

function class:setoption(option, value)
	return self.skt:setoption(option, value)
end

function class:setstats(received, sent, age)
	return self.skt:setstats(received, sent, age)
end

function class:settimeout(value, mode)
	self.timeout = value
	
	if value == nil or value < 0 then
		self.timeout = math.huge
	end
	
	return true
end

function class:shutdown(mode)
	return self.skt:shutdown(mode)
end

--------------------------------------------------------------------------------
-- internal

internal = 
{
	class = class, 
	hosts = {}, 
}

function internal:toip(address)
	if self.hosts[address] == nil then
		if string.match(address, "%d+%.%d+%.%d+%.%d+") then
			self.hosts[address] = address
		else
			self.hosts[address] = socket.dns.toip(address)
		end
	end
	return self.hosts[address] or address
end

-- luajit + luasocket = bug?
function internal:receive(skt, pattern, prefix)
	local succ, err, part = skt:receive(pattern)
	
	local data = (prefix or "") .. (succ or part)
	
	if succ then
		succ = data
	else
		part = data
	end
	
	return succ, err, part
end

