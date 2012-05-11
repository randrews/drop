module(..., package.seeall)

function class(mod)
   mod.instance = mod.instance or {}
   mod.mt = mod.mt or {}
   mod.mt.__index = mod.instance

   mod.new = function(t)
                t = t or {}
                setmetatable(t, mod.mt)
                if mod.instance.init then t:init() end
                return t
             end
end

function subclass(sub, super)
   sub.instance = sub.instance or {}
   setmetatable(sub.instance, {__index=super.instance})
   sub.mt = sub.mt or {}
   for k,v in pairs(super.mt) do sub.mt[k] = v end
   sub.mt.__index = sub.instance
   sub.super = super.instance
end