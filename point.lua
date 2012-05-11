module('point', package.seeall)

local instance = {__index={}}

function new(x,y)
   local tbl = {x=x, y=y}
   return setmetatable(tbl, instance)
end

local mt = getmetatable(_M)
mt.__call=function(t,x,y)
             return t.new(x,y)
          end

function instance.__index.copy(pt)
   return new(pt.x, pt.y)
end

function instance.__index.ortho(pt, pt2)
   return pt.x == pt2.x or pt.y == pt2.y
end

function instance.__index.toward(pt, pt2)
   if not pt:ortho(pt2) then error(pt .. ' not in a straight line with ' .. pt2)
   else
      local v = pt2 - pt
      if v.x > 0 then v.x=1 end
      if v.x < 0 then v.x=-1 end
      if v.y > 0 then v.y=1 end
      if v.y < 0 then v.y=-1 end
      return v
   end
end

function instance.__index.adjacent(pt, pt2)
   local d = pt2-pt
   return (d.x == 0 or d.y == 0) and (math.abs(d.x+d.y) == 1)
end

function instance.__add(pt1, pt2)
   return new(pt1.x+pt2.x, pt1.y+pt2.y)
end

function instance.__sub(pt1, pt2)
   return new(pt1.x-pt2.x, pt1.y-pt2.y)
end

instance.__index.translate = instance.__add

function instance.__tostring(pt)
   return string.format('(%d, %d)', pt.x, pt.y)
end

function instance.__call(pt)
   return pt.x, pt.y
end

function instance.__eq(pt1, pt2)
   return pt1.x == pt2.x and pt1.y == pt2.y
end

-- A point is "less than" a point if each
-- coord is less than the corresponding one
function instance.__lt(pt1, pt2)
   return pt1.x < pt2.x and pt1.y < pt2.y
end

function instance.__le(pt1, pt2)
   return pt1.x <= pt2.x and pt1.y <= pt2.y
end

function test()
   local p = point(2,3)
   assert(p.x == 2 and p.y == 3)
   assert(tostring(p) == "(2, 3)")
   p = p + point(1,1)
   assert(tostring(p) == "(3, 4)")
   local p2 = p:copy()
   p2.y = p2.y-1
   assert(tostring(p) == "(3, 4)")
   assert(tostring(p2) == "(3, 3)")
   assert(p2 + point(1, 1) == point(4, 4))

   local o1, o2 = point(3, 3), point(3, 5)
   assert(o1:ortho(o2))
   assert(o2-o1 == point(0, 2))
   assert(o1:toward(o2) == point(0, 1))

   local a1, a2, a3 = point(2, 2), point(1, 2), point(3, 3)
   assert(a1:adjacent(a2))
   assert(a2:adjacent(a1))
   assert(not a2:adjacent(a3))
   assert(not a1:adjacent(a3))
   assert(not a1:adjacent(a1))

   assert(a2 <= a1)
   assert(a1 < a3)
   assert(a3 > a1)
   assert(not(a2 < a1))
end

test() -- Run the tests on load, error if any fail