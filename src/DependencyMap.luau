--!strict

local Dependency = require('./Dependency')

type Dependency< T = any > = Dependency.Dependency<T>

export type DependencyMap< K = any, V = any > = {
	all: () -> { [K]: V },
	get: ( key: K ) -> V?,
	async: ( key: K, callback: ( V ) -> () ) -> (),
	await: ( key: K ) -> V,
}



--[[
	Creates & returns an API which maps keys to dependencies.
	A callback must be provided when calling this function. Callbacks are passed a function which can be called with a key and a value to initialize a dependency.
	
	@param function init
	@return DependencyMap: the public-facing API
]]
return function< K, V >( init: ( ( K, V ) -> () ) -> () ): DependencyMap<K,V>
	local dependencies: { [K]: Dependency<V> } = {}
	local initialized: { [K]: true } = {}
	local inits: { [K]: ( V ) -> () } = {}
	local values: { [K]: V } = {}
	
	local function get_dependency( key: K ): Dependency<V>
		local dependency = dependencies[key]
		if dependency == nil then
			dependency = Dependency(function( init: ( V ) -> () )
				inits[key] = init
			end)
			
			dependencies[key] = dependency
		end
		
		return dependency
	end
	
	--[[
		Immediately returns the values of all currently initialized dependencies.
		
		@return { [any]: Dependency }
	]]
	local function all(): { [K]: V }
		return table.clone(values)
	end
	
	--[[
		Immediately returns the value of the dependency according to the given key, as is.
		
		@param any key
		@return any?
	]]
	local function get( key: K ): V?
		return get_dependency(key).get()
	end
	
	--[[
		Runs a callback asynchronously as soon as the dependency according to the given key initializes.
		
		@param any key
		@param function callback
	]]
	local function async( key: K, callback: ( V ) -> () )
		get_dependency(key).async(callback)
	end
	
	--[[
		Yields the current thread until the dependency according to the given key initializes.
		
		@param any key
		@return any: the value the dependency initialized with
	]]
	local function await( key: K ): V
		return get_dependency(key).await()
	end
	
	--[[
		Initializes the value for the dependency according to the given key.
		Calling this function will release any active awaits for the key-dependency pair.
		This function can only be called once per key.
		
		@param any key
		@param any value
	]]
	local function _init( key: any, value: any )
		assert(not initialized[key], 'dependency has already initialized')
		initialized[key] = true
		values[key] = value
		
		inits[key](value)
		inits[key] = nil
	end
	
	
	task.spawn(init, _init)
	
	return table.freeze {
		all = all,
		get = get,
		async = async,
		await = await,
	}
end
