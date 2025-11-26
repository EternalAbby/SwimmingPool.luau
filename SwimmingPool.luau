--!strict
--!native
--!optimize 2

--[[
--------------------------------------------------------------------------------
		SwimmingPool - A Luau module for Object Pool Pattern
	
	A Luau module made as a general optimization to storing and reusing frequently
	used objects which are constantly constructed and destroyed.
	
	For initialization, this module creates a new `Pool`. You provide 2 parallel
	arrays, one for the object, and one for initializing the corresponding objects.
	These are used to map between the objects and their corresponding initializer
	function. A default initializer function is provided at index -1.
	
	For construction, this module attempts to find the specified object, which is
	unused within the specified pool. If successful, it'll return the reference
	to that object and removed from the internal pool (not the Folder,) and initializes
	it using the mapped initializer function and the default initializer function.
	Otherwise, attempts to create a new object (calling the initializer, if specified.)
	If all else fails, throws an error.
	
	For destruction, this module attempts to move the "destroyed" object into the
	specified pool. By default, this module will use a `Folder` to store these
	objects.
	
	For clearing, this module clears the internal pool and all of the children in
	the `Folder`.
	
	For clean-up, it extends clearing by also removing all of the information of
	the `PoolObject`.
	
	
	-- DOCUMENTATION --
	
	* Module
	- .new(id: string, pool_type: Pool_Type, ref_list: PoolReferenceList, init_list: PoolInitializerList, protected: boolean): PoolObject
		Creates a `PoolObject` with id `id` of type `pool_type`.
		
		It uses `ref_list` and `init_list` to create 2 maps. One for string to object
		mapping. One for object to initializer function mapping. A default initializer
		function is created on index -1.
		
		Objects will be initialized with the corresponding initializer function
		and default initializer function. It is important to note that this process
		does not clone a new object but instead directly apply it onto that object.
		
		`protected` determines whether `PoolObject` can be removed using the module.
		
		There cannot be multiple `PoolObject`s with the same `id` at a time.
		Attempting to create one will throw an error.
	
	- .destroy(id: string): nil
		Clears all values within the `PoolObject`. The `id` will be available
		after that.
		
		If the `PoolObject` is protected, throws an error.
		
		If the `PoolObject` is not found, does nothing.
	
	* PoolObject
	- :get(self: PoolObject, name: string): Instance
		Attempts to get the specified object using `name` from the pool. If there
		are no objects in the internal pool at `name`, creates a new clone. If `name`
		is not found, throws an error.
		
		Then, run the corresponding initializer function and then the default
		initializer function. This is to ensure the object's integrity via
		initializer functions.
		
		Finally, return the object. The internal pool automatically remove the object.
	
	- :put(self: PoolObject, object: Instance, original: Instance): nil
		Attempts to store the specified `object` into the internal pool at `original`.
		If `original` is not found, throws an error.
		
		This method does not check if `object` is related to `original`.
		
		This method will automatically set the `.Parent` property of `object` to `nil`.
		This will remove `object` from the `game` but not "destroyed".
	
	- :clear(self: PoolObject): nil
		Clear all objects stored in the internal pool.
	
--------------------------------------------------------------------------------
]]

-- TODO: [NOT NECESSARY] Methods to allow changes to the `PoolObject` after creation.
-- TODO: [NOT NECESSARY] Implement prototype-based objects support.

type UnknownTable = {[unknown]: unknown}
type CustomObject = setmetatable<UnknownTable, UnknownTable>

type InitializerFunction = (Instance) -> nil

type PoolReferenceList = {[number]: Instance}
type PoolInitializerList = {[number]: InitializerFunction} & {[number]: InitializerFunction}

type Pool_InternalPool = {[Instance]: {Instance}}
type Pool_InitRef = {[Instance]: InitializerFunction}
type Pool_Map = {[string]: Instance}
type Pool_Type = "Instance" --| "CustomObject"

type PoolObject_Method = {
	get: (self: PoolObject, name: string) -> Instance,
	put: (self: PoolObject, object: Instance, original: Instance) -> nil,
	clear: (self: PoolObject) -> nil,
}
type PoolObject_Meta = {
	__index: PoolObject_Method,
	__metatable: "Pool",
}
export type PoolObject = setmetatable<{
	_pool: Pool_InternalPool,
	_init_ref: Pool_InitRef,
	_map: Pool_Map,
	
	_default_init: InitializerFunction,
	
	_id: string,
	_type: Pool_Type,
	_protected: boolean
}, PoolObject_Meta>

type Module = {
	new: (id: string, pool_type: Pool_Type, ref_list: PoolReferenceList, init_list: PoolInitializerList, protected: boolean) -> PoolObject,
	destroy: (id: string) -> nil
}

local references: {[string]: PoolObject} = {}

local function IdentityFunction(_: Instance): nil
	return nil
end

local methods: PoolObject_Method = {
	get = function(self: PoolObject, name: string): Instance
		local model = self._map[name]
		
		if not model then
			error(`Failed to perform \`:get()\`: Object \`{name}\` does not exist in the reference list.`)
		end
		
		if #self._pool[model] > 0 then
			local to_remove = table.remove(self._pool[model]) :: Instance
			self._init_ref[model](to_remove)
			self._default_init(to_remove)
			return to_remove
		end
		
		return model:Clone()
	end,
	
	put = function(self: PoolObject, object: Instance, original: Instance): nil
		local p = self._pool[original]
		
		if not p then
			error(`Failed to perform \`:put()\`: Object \`{tostring(original)}\` does not exist in the pool.`)
		end
		
		table.insert(self._pool[original], object)
		object.Parent = nil
		return nil
	end,
	
	clear = function(self: PoolObject): nil
		for _, group in self._pool do
			table.clear(group)
		end
		return nil
	end
}

local meta: PoolObject_Meta = {} :: PoolObject_Meta
meta.__index = methods
meta.__metatable = "Pool"

meta = meta :: PoolObject_Meta

local module: Module = {
	new = function(id: string, pool_type: Pool_Type, ref_list: PoolReferenceList, init_list: PoolInitializerList, protected: boolean): PoolObject
		if references[id] then
			error(`Failed to perform \`.new()\`: PoolObject with id \`{id}\` has already been taken.`)
		end
		
		local default_init = rawget(init_list, -1)::InitializerFunction or IdentityFunction
		local obj: PoolObject = references[id]
		if not obj then
			local pool: Pool_InternalPool = {}
			local init_ref: Pool_InitRef = {}
			local map: Pool_Map = {}
			
			for idx = 1, rawlen(ref_list) do
				local ref, init = rawget(ref_list, idx), rawget(init_list, idx)
				
				if typeof(ref) == "Instance" then
					map[ref.Name] = ref
					pool[ref] = {}
					
					init_ref[ref] = init or IdentityFunction
					init_ref[ref](ref)
					default_init(ref)
				end
			end
			
			obj = setmetatable({
				_pool = pool,
				_init_ref = init_ref,
				_map = map,
				
				_default_init = default_init,
				
				_id = id,
				_type = pool_type,
				_protected = protected
			}, meta)
			references[id] = obj
		end
		
		return obj
	end,
	
	destroy = function(id: string): nil
		if references[id] then
			local obj = references[id]
			
			if obj._protected then
				error(`Failed to perform \`.destroy()\`: Cannot destroy PoolObject as it is protected.`)
			end
			
			table.clear(obj._pool)
			table.clear(obj._init_ref)
			table.clear(obj._map)
			
			obj._pool = nil :: any
			obj._init_ref = nil :: any
			obj._map = nil :: any
			
			obj._default_init = nil :: any
			
			obj._type = nil :: any
			obj._id = nil :: any
			obj._protected = nil :: any
			
			references[id] = nil :: any
		end
		
		return nil
	end
}

return module
