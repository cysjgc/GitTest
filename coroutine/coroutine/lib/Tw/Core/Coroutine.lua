module(..., package.seeall)

local create = coroutine.create
local wrap = coroutine.wrap
local resume = coroutine.resume
local running = coroutine.running
local trace = setmetatable({}, { __mode = "kv" })

coroutine.create = function(f, root)
	local co = create(f)
	if root == false then
		trace[co] = true
	end
	return co
end

coroutine.wrap = function(f, root)
	local co = wrap(f)
	if root == false then
		trace[co] = true
	end
	return co
end

coroutine.resume = function(co, ...)
	local prev = trace[co]
	trace[co] = (prev == true and coroutine.running() or co)
	local result = { resume(co, ...) }



	trace[co] = prev
	return unpack(result, 1, table.maxn(result))
end

coroutine.running = function(co)
	return trace[running()]
end

--------------------------------------------------------------------------------

local pcall = _G.pcall
local xpcall = _G.xpcall

local performResume
local handleReturnValue

function handleReturnValue(err, co, status, ...)
	if not status then
		return false, err(debug.traceback(co, (...)), ...)
	end
	if coroutine.status(co) == "suspended" then
		return performResume(err, co, coroutine.yield(...))
	end
	return true, ...
end

function performResume(err, co, ...)
	return handleReturnValue(err, co, coroutine.resume(co, ...))
end

local function id(trace, ...)
	return ...
end

_G.pcall = function(f, ...)
	return _G.xpcall(f, id, ...)
end

_G.xpcall = function(f, err, ...)
	local res, co = pcall(coroutine.create, f, false)
	if not res then
		local params = { ... }
		local newf = function()
			return f(unpack(params, 1, table.maxn(params)))
		end
		co = coroutine.create(newf, false)
	end
	return performResume(err, co, ...)
end
