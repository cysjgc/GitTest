local std	= require "std"
local socket= require "socket"

function try(...)
	local status = (...)
	if not status then
		error({ (select(2, ...)) }, 0)
	end
	return ...
end

function newtry(finalizer)
	return function (...)
		local status = (...)
		if not status then
			pcall(finalizer, select(2, ...))
			error({ (select(2, ...)) }, 0)
		end
		return ...
	end
end

local function statusHandler(status, ...)
	if status then
		return ...
	end

	local err = (...)
	if type(err) ~= "table" then
		error(err)
	end
	return nil, err[1]
end

function protect(func)
	return function (...)
		return statusHandler(pcall(func, ...))
	end
end

module(..., package.seeall)

local class
local singleton

function new(self, interval)

	return class:new(interval)
end

function getSingleton(self)
	assert(singleton ~= nil)
	return singleton
end

class = objectlua.Object:subclass()

function class:initialize(interval)
	assert(singleton == nil)
	singleton = self

	super.initialize(self)

	self.interval = interval or 100
	self.waitTime = 0
	self.sendt = {}
	self.recvt = {}
end

function class:dispose()
	super.dispose(self)

	assert(singleton == self)
	singleton = nil
end

function class:loop(elapsed)

	self.waitTime = self.waitTime - elapsed
	if self.waitTime > 0 then
		return
	end

	local revise = -self.waitTime
	self.waitTime = self.interval
	self:work(self.interval + revise)
end

function class:clean(skt)
	self.sendt[skt] = nil
	self.recvt[skt] = nil
end

function class:waitSend(skt, timeout)
	return self:wait(self.sendt, skt, timeout)
end

function class:waitRecv(skt, timeout)
	return self:wait(self.recvt, skt, timeout)
end

--------------------------------------------------------------------------------
-- private

function class:wait(queue, skt, timeout)
	assert(queue[skt] == nil)
	queue[skt] = { thread = coroutine.running(), timeout = timeout * 1000, }
	return coroutine.yield()
end

function class:work(time)
	if table.empty(self.sendt) and table.empty(self.recvt) then
		return
	end

	local sendAll = table.indices(self.sendt)
	local recvAll = table.indices(self.recvt)

	local recvSucc, sendSucc = socket.select(recvAll, sendAll, 0)

	for _, skt in ipairs(sendAll) do
		self:check(self.sendt, skt, time, sendSucc[skt] ~= nil)
	end

	for _, skt in ipairs(recvAll) do
		self:check(self.recvt, skt, time, recvSucc[skt] ~= nil)
	end
end

function class:check(queue, skt, time, ready)
	local data = queue[skt]
	if data == nil then
		return
	end

	data.timeout = data.timeout - time


	if not ready and data.timeout > 0 then
		return
	end

	queue[skt] = nil
	--coroutine.resume(data.thread, ready)
	local p,s = coroutine.resume(data.thread, ready)

	print(s)
end

--------------------------------------------------------------------------------
-- patch

assert(package.loaded["socket.http"] == nil)
socket.newtry = newtry
socket.protect = protect

local http   = require "socket.http"
http.TIMEOUT = 10
http.PROXY	 = false

local httpOpen = http.open
http.open = function(host, port, create)
	local create = create or require("Tw.Network.AsyncSocket").tcp
	return httpOpen(host, port, create)
end

