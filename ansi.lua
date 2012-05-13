math.randomseed(os.time())

module(..., package.seeall)

require 'drop'
require 'color'
require 'utils'
require 'kb'

utils.class(_M)

instance.column = 0

function instance.init(self)
   self.game = drop.new()
   return self
end

function instance.run(self)
   local cmd = nil

   repeat
      self:redraw()
      cmd = self:readkey()
      if cmd == 'l' and self.column > 0 then
         self.column = self.column - 1
      elseif cmd == 'r' and self.column < self.game.width-1 then
         self.column = self.column + 1
      elseif cmd == 'd' then
         self.game(self.column)
      end
   until cmd == 'q'
end

function instance.redraw(self)
   local s = color.clear .. color.home
   s = s .. tostring(self.game)
   s = s .. self:cursor()
   s = s:gsub("\n", "\r\n")
   print(s)
end

function instance.cursor(self)
   local total = self.game.width
   return (' '):rep(self.column) .. '^' .. (' '):rep(total-self.column-1)
end

function instance.readkey(self)
   local key = kb.getch()

   if key == 260 then return 'l'
   elseif key == 261 then return 'r'
   elseif key == 10 then return 'd'
   elseif key == 27 then return 'q'
   else return nil end
end