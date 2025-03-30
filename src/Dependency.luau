--!strict

export type Dependency< T = any > = {
	get: () -> T?,
	async: ( callback: ( T ) -> () ) -> (),
	await: () -> T,
}


--[[
	Creates & returns a dependency in the form of an API exposing various access methods to some data.
	A callback must be provided when creating a dependency. Callbacks are passed a function which can be called with a value to initialize the dependency.
	
	@param function init
	@return Dependency
]]
return function< T >( init: ( ( T ) -> () ) -> () ): Dependency<T>
	local data: T?
	local awaits: { thread } = {}
	local initialized = false
	
	--[[
		Immediately returns the value of the dependency, as is.
		
		@return any?
	]]
	local function get(): T?
		return data
	end
	
	--[[
		Yields the current thread until the dependency is initialized.
		
		@return any: the value the dependency initialized with
	]]
	local function await(): T
		if not initialized then
			table.insert(awaits, coroutine.running())
			coroutine.yield()
		end
		
		return data :: T
	end
	
	--[[
		Runs a callback asynchronously as soon as the dependency is initialized.
		The value the dependency initializes with is passed to the callback.
		
		@param function callback
	]]
	local function async( callback: ( T ) -> () )
		task.spawn(callback, (if not initialized then await() else data) :: T)
	end
	
	--[[
		Initializes the dependency with a value.
		Calling this function will release any active awaits.
		This function can only be called once.
		
		@param any value
	]]
	local function _init( value: T )
		assert(not initialized, 'dependency has already initialized')
		initialized = true
		data = value
		
		for i, thread in awaits do
			coroutine.resume(thread)
			awaits[i] = nil
		end
	end
	
	
	task.spawn(init, _init)
	
	return table.freeze {
		get = get,
		async = async,
		await = await,
	}
end
