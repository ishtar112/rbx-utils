--!strict
--!optimize 2

export type dependency< T > = {
	initialized: () -> boolean,
	init: ( T ) -> (),
	
	get: () -> T?,
	async: ( callback: ( T ) -> () ) -> (),
	await: () -> T,
}

--[[
	Creates & returns a dependency in the form of an API exposing various access methods to some value/data.
	
	@return dependency
]]
return function(): dependency<unknown>
	local is_initialized = false
	local value: unknown?
	local yielded: { thread } = {}
	
	--[[
		Returns the value of the dependency as is.
		Note that, because dependencies can be initialized with `nil`, this function should **not** be used to check if the dependency has initialized or not: the `initialized` member exposes behavior specifically for that.
		
		@return unknown?
	]]
	local function get(): unknown?
		return value
	end
	
	--[[
		@yields
		Yields the current thread until the dependency is initialized.
		
		@return unknown: the value the dependency initialized with
	]]
	local function await(): unknown
		if not is_initialized then
			table.insert(yielded, coroutine.running())
			coroutine.yield()
		end
		
		return value :: unknown
	end
	
	--[[
		Runs a callback asynchronously as soon as the dependency is initialized.
		The value the dependency initializes with is passed to the callback.
		
		@param function callback
	]]
	local function async( callback: ( unknown ) -> () )
		if not is_initialized then
			task.spawn(function()
				callback(await())
			end)
		else
			callback(value :: unknown)
		end
	end
	
	--[[
		Initializes the dependency with a value.
		This function can only be called once.
		
		@param unknown v: the value to initialize the dependency with
	]]
	local function init( v: unknown )
		assert(not is_initialized, 'dependency has already initialized')
		is_initialized = true
		value = v
		
		
		for i, thread in yielded do
			task.spawn(thread)
		end
		
		yielded = nil :: any
	end
	
	--[[
		Returns a boolean indicating whether or not the dependency has initialized.

		@return boolean
	]]
	local function isinit(): boolean
		return is_initialized
	end
	
	return table.freeze {
		initialized = isinit,
		init = init,
		
		get = get,
		async = async,
		await = await,
	}
end
