local AsyncSocket = require "Tw.Network.AsyncSocket"
local SocketStream = require "Tw.Network.SocketStream"

module(..., package.seeall)

class = objectlua.Object:extend()

function class:initialize(host, port, listener)
	super.initialize(self)
	
	self.listener = listener
	self.socket = AsyncSocket.tcp()
	self.dataSend = ""
	self.dataRecv = ""
	
	coroutine.resume(coroutine.create(function()
		if not self.socket:connect(host, port) then
			return
		end
		
		self.threadSend = coroutine.create(bind(self.routineSend, self))
		self.listener:onReady()
		coroutine.resume(coroutine.create(bind(self.routineRecv, self)))
	end))
end

function class:dispose()
	self:cleanup()
	super.dispose(self)
end

function class:send(data)
	assert(self.threadSend ~= nil)
	
	local waiting = (#self.dataSend == 0)
	
	self.dataSend = self.dataSend .. data
	
	if waiting then
		assert(coroutine.status(self.threadSend) == "suspended")
		coroutine.resume(self.threadSend)
	end
end

--------------------------------------------------------------------------------
-- private

function class:cleanup()
	if self.socket ~= nil then
		self.socket:close()
		self.socket = nil
	end
	
	self.dataSend = ""
	self.dataRecv = ""
	self.threadSend = nil
end

function class:routineSend()
	repeat
		if #self.dataSend == 0 then
			coroutine.yield()
		end
		
		local succ, err, idx = self.socket:send(self.dataSend)
		if not succ then
			self.listener:onClosed()
			break
		end
		
		idx = succ
		self.dataSend = string.sub(self.dataSend, idx + 1)
	until false
end

function class:routineRecv()
	local stream = SocketStream.class:new(self.socket)
	xpcall(function()
		repeat
			self.listener:onReceive(stream)
		until false
	end, function(err)
		self.listener:onClosed()
	end)
end

