-- takes the index and newindex functions as arguments
-- if you weren't aware of how those work:
-- `t[k]` calls `index(t,k)`
-- `t[k]=v` calls `newindex(t,k,v)`
-- by setting this metatable on an empty table, they will always get called
-- when reading values from the table or writing values to the table
-- this can be used to implement restrictions like the ones used in the
-- environment proxy
local function callabletable(index,newindex)
    return setmetatable({},{
        ["__index"]=index,
        ["__newindex"]=newindex,
        ["__metatable"]=false
    })
end

return callabletable
