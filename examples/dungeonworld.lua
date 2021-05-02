-- Dungeon World: 2d6 + mod

-- 6-: failure
-- 7-9: partial success
-- 10+: success

local rolls = {}

for mod = -3,3 do
	
	local roll = (2*d6 + mod):apply(function(x)
			
		if x <= 6 then
			return "failure"
		elseif x <= 9 then
			return "partial success"
		else
			return "success"
		end
	end)
	
	table.insert(rolls, roll)
	table.insert(rolls, tostring(mod))
end

plot_transposed(rolls)
