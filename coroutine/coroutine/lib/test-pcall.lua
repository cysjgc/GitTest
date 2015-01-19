require("pl.app").require_here("lib")

require "Tw.Core.Coroutine"

local function test(cond)
	if cond then
		return
	end
	print(debug.traceback("error"))
end

do
	local co = nil
	co = coroutine.create(function()
		for i = 1, 5 do
			test(coroutine.running() == co)
			coroutine.yield()
		end
	end)
	
	test(coroutine.running() == nil)
	coroutine.resume(co)
	test(coroutine.running() == nil)
end

do
	local co1 = nil
	co1 = coroutine.create(function()
		local co2 = nil
		co2 = coroutine.create(function()
			test(coroutine.running() == co2)
		end)
		coroutine.resume(co2)
		test(coroutine.running() == co1)
		coroutine.yield()
	end)
	
	test(coroutine.running() == nil)
	coroutine.resume(co1)
	test(coroutine.running() == nil)
end

do
	local co1 = nil
	co1 = coroutine.create(function()
		local co2 = nil
		co2 = coroutine.create(function()
			test(coroutine.running() == co1)
		end, false)
		coroutine.resume(co2)
		test(coroutine.running() == co1)
		coroutine.yield()
	end)
	
	test(coroutine.running() == nil)
	coroutine.resume(co1)
	test(coroutine.running() == nil)
end

do
	local co = nil
	local val = 0
	co = coroutine.create(function()
		pcall(function()
			test(coroutine.running() == co)
			val = 1
			coroutine.yield()
			val = 2
		end)
		test(coroutine.running() == co)
		test(val == 2)
		val = 3
	end)
	
	test(coroutine.running() == nil)
	coroutine.resume(co)
	test(val == 1)
	coroutine.resume(co)
	test(val == 3)
	test(coroutine.running() == nil)
end

do
	local co = nil
	co = coroutine.create(function()
		pcall(function()
			coroutine.yield(1)
		end)
		return 2
	end)
	
	local data = { coroutine.resume(co) }
	test(#data == 2)
	test(data[1] == true)
	test(data[2] == 1)
	
	local data = { coroutine.resume(co) }
	test(#data == 2)
	test(data[1] == true)
	test(data[2] == 2)
end

do
	local co = nil
	co = coroutine.create(function()
		pcall(function()
			error("boom")
		end)
		return 2
	end)
	
	local data = { coroutine.resume(co) }
	test(#data == 2)
	test(data[1] == true)
	test(data[2] == 2)
	test(coroutine.status(co) == "dead")
end
