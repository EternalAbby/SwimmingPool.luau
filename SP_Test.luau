--!strict

local SwimmingPool = require("./SwimmingPool")

local PERFORM_TEST_BENCHMARK_TIME = true

local performed_test_benchmark: {[number]: number} = {}
local total_tests_amount = 0
local total_tests_passed = 0
local total_tests_failed = 0

-- HELPER FUNCTIONS --

local function FormatPercentage(n: number): number
	return math.round(n * 10000) / 100
end

local function PerformTest(func: () -> boolean): nil
	total_tests_amount += 1
	
	local success, result = pcall(function()
		if PERFORM_TEST_BENCHMARK_TIME then
			local startTime = os.clock()
			local res = func()
			local finishTime = os.clock()
			
			table.insert(performed_test_benchmark, finishTime - startTime)
			return res
			
		else
			return func()
		end
	end)
	
	if not success then
		print()
		warn(`-- TEST {total_tests_amount} ERRORED --`)
		warn(`Test case performed at line {debug.info(2, "l")}`)
		warn(result)
		print()
		
		total_tests_failed += 1
		
	elseif not result then
		print()
		warn(`-- TEST {total_tests_amount} FAILED --`)
		warn(`Test case performed at line {debug.info(2, "l")}`)
		print()
		
		total_tests_failed += 1
		
	else
		print()
		print(`-- TEST {total_tests_amount} PASSED --`)
		print(`Test case performed at line {debug.info(2, "l")}`)
		print()
		
		total_tests_passed += 1
	end
	
	return nil
end

local function DisplayDetails(obj: SwimmingPool.PoolObject): nil
	print()
	print(`-- POOL OBJECT INFO --`)
	print(`POOL OBJECT ID: {obj._id}`)
	print(`POOL OBJECT TYPE: {obj._type}`)
	print(`POOL OBJECT PROTECTED: {obj._protected}`)
	print("INTERNAL POOL:", obj._pool, `(count: {#obj._pool})`)
	print("INTERNAL MAPPING LIST:", obj._map)
	print("INTERNAL INITIALIZER REFERENCE LIST:", obj._init_ref)
	print("INTERNAL DEFAULT INITIALIZER:", obj._default_init)
	print()
	
	return nil
end

local function DisplayResults(init_timeTaken: number?, test_timeTaken: number?): nil
	local pass_percentage = FormatPercentage(total_tests_passed / total_tests_amount)
	local fail_percentage = FormatPercentage(total_tests_failed / total_tests_amount)
	
	print()
	print(`-- TEST RESULT --`)
	print(`Total tests performed: {total_tests_amount}`)
	print(`Total tests passed: {total_tests_passed} ({pass_percentage}%)`)
	print(`Total tests failed: {total_tests_failed} ({fail_percentage}%)`)
	print()
	print(`-- ADDITIONAL INFO --`)
	
	if init_timeTaken and test_timeTaken then
		local total_time = init_timeTaken + test_timeTaken
		local init_percentage = FormatPercentage(init_timeTaken / total_time)
		local test_percentage = FormatPercentage(test_timeTaken / total_time)
		
		print(`<< TOTAL TIME >>`)
		print(`Total time taken: {total_time} seconds.`)
		print(`Total time to init: {init_timeTaken} seconds. ({init_percentage}%)`)
		print(`Total time to test: {test_timeTaken} seconds. ({test_percentage}%)`)
		print()
	end
	
	if PERFORM_TEST_BENCHMARK_TIME then
		print(`<< TEST CASE BENCHMARK >>`)
		for test_idx, seconds in ipairs(performed_test_benchmark) do
			print(`TEST {test_idx} executed in: {seconds} seconds.`)
		end
	end
	print()
	
	return nil
end



-- INITIALIZE VARIABLES --

print()
print(`-- INITIALIZING VARIABLES --`)
print()

local init_startTime = os.clock()

local instance_1 = Instance.new("Part")
instance_1.Name = "Part_1"

local instance_2 = Instance.new("Part")
instance_2.Name = "Part_2"

local instance_3 = Instance.new("Part")
instance_3.Name = "Part_3"

local instance_4 = Instance.new("Part")
instance_4.Name = "Part_4"

local instance_5 = Instance.new("Part")
instance_5.Name = "Part_5"

local PoolObject_1 = SwimmingPool.new("PoolA", "Instance", {
	instance_1,
	instance_2,
	instance_3
}, {
	[-1] = function(part: Instance): nil
		part = part :: Part
		part:SetAttribute("Organic", true)
		return nil
	end,
	
	function(part: Instance): nil
		part = part :: Part
		part.Size = Vector3.one
		part.Color = Color3.new(0.8, 0, 0)
		return nil
	end,
	
	function(part: Instance): nil
		part = part :: Part
		part.Size = Vector3.new(1, 4, 1)
		part.Color = Color3.new(1, 0.9, 0)
		return nil
	end,
	
	function(part: Instance): nil
		part = part :: Part
		part.Size = Vector3.new(4, 4, 4)
		part.Color = Color3.new(0, 0.5, 0)
		return nil
	end
}, true)

local PoolObject_2 = SwimmingPool.new("PoolB", "Instance", {
	instance_1,
	instance_2
}, {
	function(part: Instance): nil
		part = part :: Part
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * 4
		part.Color = Color3.new(0.5, 0.5, 0.5)
		return nil
	end,
	
	function(part: Instance): nil
		part = part :: Part
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.one * 4
		part.Color = Color3.new(0.5, 1, 0.5)
		return nil
	end
}, true)

local init_finishTime = os.clock()



-- TESTS --

print()
print(`-- PERFORMING TESTS --`)
print()

local test_startTime = os.clock()

-- TEST 1
-- Testing the basic methods of a PoolObject.
-- Task: Gets an object, puts the object.
-- Result: Both should have the same references to the same objects.
do
	local pool_obj1_1: Instance = PoolObject_1:get("Part_1")
	PoolObject_1:put(pool_obj1_1, instance_1)
	
	PerformTest(function()
		return pool_obj1_1 == PoolObject_1:get("Part_1")
	end)
end


-- TEST 2
-- Testing clear method.
-- Task: Perform clear.
-- Result: Internal pool is empty.
do
	PoolObject_1:clear()
	PerformTest(function()
		return #PoolObject_1._pool == 0
	end)
end



-- TEST 3
-- Testing reuse object.
-- Task: Perform multiple get and then put methods.
-- Result: Internal pool has 1 object.
do
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PoolObject_1:put(PoolObject_1:get("Part_1"), instance_1)
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 1
	end)
end



-- TEST 4
-- Testing with another object
-- Task: Get a new object, put the object. Perform one more time.
-- Result: `Part_2` object is created, internal pool has 2 objects.
do
	PoolObject_1:put(PoolObject_1:get("Part_2"), instance_2)
	PoolObject_1:put(PoolObject_1:get("Part_2"), instance_2)
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 1 and #PoolObject_1._pool[instance_2] == 1
	end)
end



-- TEST 5, 6, AND 7
-- Testing reuse and integrity.
-- Task: Internal pool and integrity checks.
-- Result: Internal pool is empty, integrity check passes, internal pool has 3 objects.
do
	local p1 = PoolObject_1:get("Part_1")
	local p2 = PoolObject_1:get("Part_2")
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0 and #PoolObject_1._pool[instance_2] == 0
	end)
	
	
	local new_p1 = PoolObject_1:get("Part_1")
	PerformTest(function()
		return p1 ~= new_p1
	end)
	
	
	PoolObject_1:put(p1, instance_1)
	PoolObject_1:put(p2, instance_2)
	PoolObject_1:put(new_p1, instance_1)
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 2 and #PoolObject_1._pool[instance_2] == 1
	end)
end



-- TEST 8, 9, 10, AND 11
-- Testing reuse
-- Task: Gets `Part_1` 3 times. Puts back those objects. Internal pool checks.
-- Result: Internal pool has 2 -> 1 -> 1 -> 3 elements.
do
	-- TEST 8
	local p1 = PoolObject_1:get("Part_1")
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 1 and #PoolObject_1._pool[instance_2] == 1
	end)
	
	-- TEST 9
	local p2 = PoolObject_1:get("Part_1")
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0 and #PoolObject_1._pool[instance_2] == 1
	end)
	
	-- TEST 10
	local p3 = PoolObject_1:get("Part_1")
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0 and #PoolObject_1._pool[instance_2] == 1
	end)
	
	-- TEST 11
	PoolObject_1:put(p1, instance_1)
	PoolObject_1:put(p2, instance_1)
	PoolObject_1:put(p3, instance_1)
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 3 and #PoolObject_1._pool[instance_2] == 1
	end)
end



-- TEST 12
-- Clear Pool
-- Task: Clear the internal pool
-- Result: Internal pool is empty
do
	PoolObject_1:clear()
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0 and #PoolObject_1._pool[instance_2] == 0
	end)
end



-- TEST 13, 14, AND 15
-- Testing initializer function on `Part_1`
-- Task: Gets a `Part_1` object. Perform changes (that the initializer changes.) Check internal pool and those properties.
-- Result: Object has the same properties as initialized.
do
	local p1 = PoolObject_1:get("Part_1") :: Part
	p1.Name = "A"
	p1.Size = Vector3.one * 2
	p1.Color = Color3.new(1, 1, 1)
	p1:SetAttribute("Organic", false)
	
	PoolObject_1:put(p1, instance_1)
	
	local new_p1 = PoolObject_1:get("Part_1") :: Part
	
	-- TEST 13
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0
	end)
	
	-- TEST 14
	PerformTest(function()
		return new_p1 == p1
			and new_p1.Size == Vector3.one
			and new_p1.Color == Color3.new(0.8, 0, 0)
	end)
	
	-- TEST 15
	PerformTest(function()
		return new_p1:GetAttribute("Organic") == true
	end)
end



-- TEST 16, 17, AND 18
-- TODO: Add description
do
	PoolObject_1:clear()
	
	-- TEST 16
	local p1_1 = PoolObject_1:get("Part_1")
	local p1_2 = PoolObject_2:get("Part_1")
	PerformTest(function()
		return p1_1 ~= p1_2
	end)
	
	-- TEST 17
	PoolObject_1:put(p1_1, instance_1)
	PoolObject_2:put(p1_2, instance_1)
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 1 and #PoolObject_2._pool[instance_1] == 1
	end)
	
	-- TEST 18
	p1_1 = PoolObject_1:get("Part_1")
	p1_2 = PoolObject_2:get("Part_1")
	PerformTest(function()
		return #PoolObject_1._pool[instance_1] == 0 and #PoolObject_2._pool[instance_1] == 0
	end)
	
	PoolObject_1:put(p1_1, instance_1)
	PoolObject_2:put(p1_2, instance_1)
end



-- TEST 19
-- TODO: Add description
do
	local p1_1 = PoolObject_1:get("Part_1")
	local p1_2 = PoolObject_2:get("Part_1")
	PoolObject_1:put(p1_2, instance_1)
	PoolObject_2:put(p1_1, instance_1)
	
	local new_ref_p1_2 = PoolObject_1:get("Part_1")
	local new_ref_p1_1 = PoolObject_2:get("Part_1")
	
	PerformTest(function()
		return p1_1 == new_ref_p1_1 and p1_2 == new_ref_p1_2
	end)
	
	PoolObject_1:put(new_ref_p1_1, instance_1)
	PoolObject_2:put(new_ref_p1_2, instance_1)
end

local test_finishTime = os.clock()

DisplayResults(
	init_finishTime - init_startTime,
	test_finishTime - test_startTime
)