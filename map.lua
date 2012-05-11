require 'point'

module('map', package.seeall)

require 'utils'

utils.class(_M)

-- Set these on init:
instance.width = 1
instance.height = 1

-- Used to tostring a single cell
function instance.to_s(m, x, y)
   return tostring(m:at(x,y))
end

function instance.init(self)
   self.size = point(self.width, self.height)
   return self
end

function instance.at(self, pt, val, _)
   if type(pt) == 'number' then -- they passed a point as two args:
      return self:at(point(pt, val), _)
   elseif self:inside(pt) then
      if val then self[pt.x+pt.y*self.width] = val end
      return self[pt.x+pt.y*self.width]
   else
      return nil
   end
end

function instance.each(self, start, w, h, _)
   -- Handle the first arg not being a pt
   if type(start) == 'number' then return self:each(point(start,w), h, _) end

   local maxx, maxy

   if w then maxx = start.x + w-1 else maxx = self.width-1 end
   if h then maxy = start.y + h-1 else maxy = self.height-1 end

   start = start or point(0, 0)
   local p = start

   return function()
             local r = p -- return this one...

             -- Decide what the next one will be:
             p = p + point(1, 0)
             if p.x > maxx then p = point(start.x, p.y+1) end

             if r.y > maxy then return nil
             else return r end
          end
end

function instance.clamp(self, pt)
   pt = pt:copy()
   if pt.x < 0 then pt.x = 0 end
   if pt.x > self.width-1 then pt.x = self.width-1 end
   if pt.y < 0 then pt.y = 0 end
   if pt.y > self.height-1 then pt.y = self.height-1 end
   return pt
end

function instance.inside(self, pt)
   return pt >= point(0, 0) and pt < self.size
end

function instance.clear(self, value)
   for p in self:each() do
      self:at(p, value)
   end
end

function instance.slice(self, start, w, h, _)
   if type(start) == 'number' then return self:slice(point(start, w), h, _) end

   local s = _M.new{width=w, height=h, to_s = self.to_s}

   for p in s:each() do
      s:at(p, self:at(p+start))
   end

   return s
end

function mt.__tostring(self)
   local s = ''

   for y = 0, self.height-1 do
      for x = 0, self.width-1 do
         s = s .. self:to_s(x, y)
      end
      s = s .. "\n"
   end

   return s
end

----------------------------------------

function test()
   -- Constructor
   local m = map.new{width=8, height=10}
   assert(m.width == 8)
   assert(m:inside(point(3,3)))
   assert(not m:inside(point(8,10)))

   -- clear / set
   m:clear(' ')
   m:at(point(3,2),'r')

   -- at
   assert(m:at(1,1) == ' ')
   assert(m:at(3,2) == 'r')

   assert(m:at(10,10) == nil)
   assert(m:at(point(3,2)) == m:at(3,2))

   -- each
   local n = 0
   for p in m:each() do n = n + 1 end
   assert(n == 80)

   local n2 = 0
   for p in m:each(point(2, 2), 4, 4) do n2 = n2 + 1 end
   assert(n2 == 16)

   local n3 = 0
   for p in m:each(4, 5) do n3 = n3 + 1 end
   assert(n3 == 20)

   -- slice
   local s = m:slice(point(3,2), 3, 3)
   assert(s.width == 3)
   assert(s:at(0,0) == 'r')
   assert(s:at(1,1) == ' ')
   s:clear(' ')
   assert(m:at(3,2) == 'r')
end

test()