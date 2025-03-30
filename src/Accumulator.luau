--!strict

export type Accumulator< S = { [any]: () -> number } > = {
	contributors: S,
	
	sum: ( init: number? ) -> number,
	compound: ( init: number? ) -> number,
}



--[[
	Constructs & returns a new Accumulator.
	
	@return Accumulator
]]
return function(): Accumulator<>
	local contributors: { [any]: () -> number } = {}
	local object = {
		contributors = contributors,
	}
	
	--[[
		Sums the returned values of all registered contributors.
	
		@param number? init: an optional amount to initialize the sum as
		@return number
	]]
	function object.sum( init: number? ): number
		assert((init == nil) or (type(init) == 'number'), 'first argument must be a number')
		
		local sum = init or 0
		for _, contributor in contributors do
			local value = contributor()
			assert(type(value) == 'number', 'function must return a number')
			
			sum += value
		end
		
		return sum
	end
	
	--[[
		Sums the returned values of all registered contributors, with compounding.
	
		@param number? init: an optional amount to initialize the sum as
		@return number
	]]
	function object.compound( init: number? ): number
		assert((init == nil) or (type(init) == 'number'), 'first argument must be a number')
		
		local sum = init or 0
		for _, contributor in object.contributors do
			local value = contributor()
			assert(type(value) == 'number', 'function must return a number')
			
			sum += sum * value
		end
		
		return sum
	end
	
	return table.freeze(object)
end
