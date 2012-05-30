module(..., package.seeall)

require 'utils'

utils.class(_M)

instance.score = 0

function instance.init(self)
   return self
end

local function triangular(n)
   return n * (n + 1) / 2
end

-- Takes a list of points, returns score for destroying those spaces,
-- adds it to current score
function instance.drop(self, game, destroyed)
   if #destroyed >= 2 then
      self.score = triangular(#destroyed)
   end
   return 0
end
