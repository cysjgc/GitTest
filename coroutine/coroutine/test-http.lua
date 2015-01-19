require("pl.app").require_here("lib")

require "std"
require "objectlua"

require "Tw.Core.Coroutine"

local service = nil
local interval = 10
local useCoroutine = true

if useCoroutine then
	service = require("Tw.Network.Service"):new(10)
end

require "socket"
require "socket.http"

function request(url, callback)
	local thread = coroutine.create(function()
		local data = socket.http.request(url)
		xpcall(function()
			callback(coroutine.running(), data)
		end, function(err)
			return err
		end)
	end)

	local succ, err = coroutine.resume(thread)
	if not succ then
		print(debug.traceback(thread, err))
	end

	return thread
end

local start = os.clock()

local count = 0

count = count + 1
request("http://opx014.9yuonline.com:80/client/serverlst/3CSoul2/1_ey/server.json", function(_, data)
	count = count - 1
	print(data)
end)

count = count + 1
request("http://opx014.9yuonline.com:80/client/serverlst/3CSoul2/1_ey/server.json", function(_, data)
	count = count - 1
	print(data)
end)

count = count + 1
request("http://opx014.9yuonline.com:80/client/serverlst/3CSoul2/1_ey/server.json", function(_, data)
	count = count - 1
	print(data)
end)

if useCoroutine then
	while count > 0 do
		local now = os.clock()
		while (os.clock() - now) * 1000 < interval do
			
		end
		service:loop((os.clock() - now) * 1000)
	end
end

print(os.clock() - start)
