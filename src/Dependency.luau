--!strict

export type Dependency< T = any > = {
	await: () -> T,
	async: ( callback: ( T ) -> () ) -> (),
	get: () -> T?,
}


--[[
	Creates & returns a dependency in the form of an API exposing various access methods to some data.
	A callback must be provided when creating a dependency. Callbacks are passed a function which can be called with a value to initialize the dependency.
	
	@param function init
	@return Dependency
]]
return function< T >( init: ( ( T ) -> () ) -> () ): Dependency<T>
	local data: any
	local awaits: { thread }? = {}
	local initialized = false
	
	--[[
		Returns the value of the dependency, as is.
		
		@return any?
	]]
	local function get(): any
		return data
	end
	
	--[[
		Yields the current thread until the dependency is initialized.
		
		@return any: the value the dependency initialized with
	]]
	local function await(): any
		if not initialized then
			table.insert(awaits :: { thread }, coroutine.running())
			coroutine.yield()
		end
		
		return data
	end
	
	--[[
		Runs a callback asynchronously as soon as the dependency is initialized.
		
		@param function callback
	]]
	local function async( callback: ( any ) -> () )
		task.spawn(callback, if not initialized then await() else data)
	end
	
	--[[
		Initializes the value of the dependency.
		Calling this function will release any active awaits.
		
		@param any value
	]]
	local function _init( value: any )
		assert(not initialized, 'dependency has already initialized')
		initialized = true
		data = value
		
		for _, thread in awaits :: { thread } do
			coroutine.resume(thread)
		end
		awaits = nil
	end
	
	
	task.spawn(init, _init)
	
	return table.freeze {
		get = get,
		async = async,
		await = await,
	}
end
