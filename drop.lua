math.randomseed(os.time())

module(..., package.seeall)

require 'map'
require 'color'
require 'utils'

utils.class(_M)
utils.subclass(_M, map)

instance.width = 8
instance.height = 10

function instance.init(self)
   self = super.init(self)
   self:clear(0)

   -- What we select pieces to drop from
   self.drop_pool = {1,1,1,1,
                     2,2,2,2,
                     3,3,3,3,
                     4,4,4,4,
                     {wild=3}}

   -- What we select pieces in pushed rows from
   self.push_pool = {1,1,1,
                     2,2,2,
                     3,3,3,
                     4,4,4}

   for p in self:each(0, 8, 8, 2) do
      self:at(p, math.random(4))
   end

   self:refill_queue()

   return self
end

function instance.refill_queue(self)
   self.queue = {}
   for n=1,self.width do
      self.queue[n] = self:random_element(self.drop_pool)
   end
end

function instance.random_element(self, arr)
   local el = arr[math.random(#arr)]
   if type(el) == 'table' then
      local c = {}
      for k,v in pairs(el) do c[k]=v end
      return c
   else return el end
end

local function render(c)
   local colors = {0xc4, 0x28, 0xe2, 0x18}
   local bg = color.bg(0xe9)

   if type(c) == 'table' then
      if c.wild then
         return bg .. color.fg.WHITE .. c.wild .. color.reset
      elseif c.block then
         return color.bg.WHITE .. color.fg.black .. c.block .. color.reset
      end
   elseif type(c) == 'number' then
      if c == 0 then
         return bg .. ' ' .. color.reset
      else
         return bg .. color.fg(colors[c]) .. 'o' .. color.reset
      end
   end
end

function instance.to_s(self, x, y)
   return render(self:at(x, y))
end

function instance.drop(self, col, value)
   if not col or not value then error("Need a column and a value") end
   if self:at(col, 0) ~= 0 then error("Column full") end

   for y = 0, self.height-1 do
      if self:at(col, y) ~= 0 then
         self:at(col, y-1, value)
         return
      end
   end

   self:at(col, 9, value)
end

function mt.__tostring(self)
   local s = color.reset .. "\n"
   for _,q in ipairs(self.queue) do
      s = s .. render(q)
   end
   s = s .. "\n" .. ('-'):rep(self.width) .. "\n"

   return s .. map.mt.__tostring(self) .. color.reset
end

function mt.__call(self, col)
   self:turn(col)
   return self
end

function instance.region(self, start, _)
   start = type(start) == 'number' and point(start,_) or start

   local val = self:at(start)
   local open = {start}
   local closed = {}

   while #open > 0 do
      local curr = open[#open]
      open[#open] = nil

      for _, pt in ipairs(self:neighbors(curr)) do
         if self:at(pt) == val and not closed[tostring(pt)] then
            open[#open+1] = pt
         end
      end

      closed[tostring(curr)] = curr
   end

   local r = {}
   for _,p in pairs(closed) do
      r[#r+1] = p
   end

   return r
end

function instance.neighbors(self, pt, _)
   pt = type(pt) == 'number' and point(pt,_) or pt

   local n = {point(1,0),
              point(-1,0),
              point(0,1),
              point(0,-1)}
   local r = {}

   for _,p in ipairs(n) do
      if self:inside(pt+p) then table.insert(r, pt+p) end
   end

   return r
end

function instance.lost(self)
   for p in self:each(0,0,self.width,1) do
      if self:at(p) ~= 0 then return true end
   end
   return false
end

-- Drops the next piece on to a column; returns false if game over
function instance.turn(self, col)
   assert(#self.queue > 0, "No piece available to drop")
   assert(col >= 0 and col < self.width, "Column out of bounds")
   assert(self:at(col,0) == 0, "Column full")

   local val = table.remove(self.queue, 1)
   self:drop(col, val)

   if type(val) == 'table' then
      if val.wild then self:wild_drop(col) end
   else
      self:zap(col)
   end

   self:gravity()

   if #self.queue == 0 then
      self:refill_queue()
      return self:push_row()
   else
      return not self:top_row_full()
   end
end

----------------------------------------
-- Normal zaps

function instance.zap(self, col)
   assert(col >= 0 and col < self.width, "Column out of bounds")

   local start = nil
   for y=0,self.height do
      if self:at(col, y) ~= 0 then
         start = point(col, y)
         break
      end
   end
   assert(start, "Column empty")

   local group = self:region(start)
   if #group < 2 then return false
   else
      for _, p in ipairs(group) do self:at(p, 0) end
      return true
   end
end

----------------------------------------
-- Wild drops

local function is_wild(val)
   return val and type(val) == 'table' and val.wild
end

function instance.wild_drop(self, col)
   assert(col >= 0 and col < self.width, "Column out of bounds")

   local start = nil
   for y=0,self.height do
      if self:at(col, y) ~= 0 then
         start = point(col, y)
         break
      end
   end
   assert(start, "Column empty")

   local wild = self:at(start)
   local below = self:at(start+point(0,1))
   assert(is_wild(wild), "Column has no wild")

   local nbrs = self:neighbors(start)
   local zapped = false

   for _, n in ipairs(nbrs) do -- For each neighbor
      local val = self:at(n)
      -- If it's a normal cell...
      if type(val) == 'number' and val ~= 0 then
         self:at(start, val) -- put a clone here
         local reg = self:region(start) -- Zap it
         if #reg >= wild.wild then -- Did we zap enough?
            -- Remove them and don't freeze it
            for _,p in ipairs(reg) do self:at(p, 0) end
            zapped = true
         end
      end
   end

   if not zapped then -- Didn't match anything, freeze it
      self:at(start, wild)
      self:freeze_wild(start)
   end
end

function instance.freeze_wild(self, pt)
   local w = self:at(pt)
   assert(pt and is_wild(w), "Point isn't a wild")
   self:at(pt, {block = w.wild-2})
end

function instance.gravity(self)
   local moved
   repeat
      moved = false
      for p in self:each(0,0,self.width, self.height-1) do
         local v = self:at(p)
         if v ~= 0 and self:at(p+point(0,1)) == 0 then
            moved = true
            self:at(p+point(0,1), v)
            self:at(p, 0)
         end
      end
   until not moved
end

----------------------------------------
-- Pushing rows

function instance.top_row_full(self)
   for p in self:each(0, 0, self.width, 1) do
      if self:at(p) == 0 then return false end
   end
   return true
end

function instance.push_row(self)
   if self:lost() then return false end

   for p in self:each(0, 0, self.width, self.height-1) do
      self:at(p, self:at(p + point(0,1)))
   end

   for p in self:each(0, self.height-1, self.width, 1) do
      self:at(p, math.random(4))
   end

   return true
end

----------------------------------------

function test()
   local mod = _M

   -- Is it a subclass
   local dm = mod.new()
   assert(dm.width == 8)
   assert(dm.slice)

   -- drop
   local dm2 = mod.new()
   dm2:drop(2,2)
   assert(dm2:at(2, 7) == 2)

   dm2:clear(0)
   dm2:drop(5,1)
   assert(dm2:at(5, 9) == 1)

   -- neighbors
   local dm3 = mod.new()
   local n = dm3:neighbors(0,0)
   assert(#n == 2)
   assert(n[1] == point(1, 0))
   assert(n[2] == point(0, 1))
   assert(#dm3:neighbors(3,3) == 4)

   -- region
   local dm4 = mod.new()
   local r = dm4:region(0,0)
   assert(#r == 64)

   -- lost
   local dm5 = mod.new()
   for n=1, dm5.height-3 do dm5:drop(7,1) end
   assert(not dm5:lost())
   dm5:drop(7,2)
   assert(dm5:lost())

   -- push_row
   local dm6 = mod.new()
   for n=1, dm6.height-3 do dm6:push_row() end
   local g = dm6:region(0,0)
   assert(#g == dm6.width)
   dm6:push_row()
   assert(dm6:top_row_full())

   -- zap
   local dm7 = mod.new()
   dm7:clear(0)
   dm7.queue = {1, 2, 2, 3}
   dm7:turn(0)
   dm7:turn(0)
   assert(#dm7:region(0,0) == 78)
   dm7:turn(0)
   assert(#dm7:region(0,0) == 79)

   -- gravity
   local dm8 = mod.new()
   dm8:clear(0)
   dm8:at(3,3,1)
   dm8:gravity()
   assert(dm8:at(3,3) == 0)
   assert(dm8:at(3,9) == 1)

   -- Wilds
   local dw = mod.new()
   dw.queue[1] = 3
   dw.queue[2] = {wild=3}
   dw:clear(0)
   dw(0) ; dw(0)
   local r = dw:region(0,0)
   assert(#r == 78)
   assert(dw:at(0,8).block == 1)

   dw:clear(0)
   dw.queue = {3,2,3, {wild=3}, 1}
   dw(0) ; dw(1) ; dw(1) ; dw(0)
   assert(#(dw:region(0,0)) == 79)

   dw:clear(0)
   dw.queue = {2, 2, {wild=3}, 1}
   dw(0) ; dw(2) ; dw(1)
   assert(#(dw:region(0,0)) == 80)


   dw:clear(0)
   dw:at(0,9,1) ; dw:at(1,9,1)
   dw:at(3,9,2) ; dw:at(4,9,2)
   dw.queue = {{wild=3}, 1}
   dw(2)
   assert(#(dw:region(0,0)) == 80)
end

test()