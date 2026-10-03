-- Disable SQLite automatic batching on the connection: this module owns transactions.
local active = {}
local function querySync(db,sql,...)
    local handle = dbQuery(db,sql,...)
    if not handle then return false end
    return dbPoll(handle,-1) ~= false
end
function writeDayZSnapshotSync(db,rows)
    local pending = active[db]
    if pending then
        pending.cancelled = true
        active[db] = nil
        if not querySync(db,"ROLLBACK") then return false end
    end
    if not querySync(db,"BEGIN IMMEDIATE") then return false end
    for _, row in ipairs(rows) do
        if not querySync(db,row.sql,unpack(row.values,1,row.values.n)) then
            querySync(db,"ROLLBACK")
            return false
        end
    end
    if not querySync(db,"COMMIT") then querySync(db,"ROLLBACK"); return false end
    return true
end
function writeDayZSnapshot(db,rows,complete)
    if active[db] then return false end
    local state = {index=0,transaction=false}
    active[db] = state
    local step
    local function finish(ok)
        active[db] = nil
        complete(ok)
    end
    local function rollback()
        local handle = dbQuery(function(q)
            dbPoll(q,0)
            if not state.cancelled then finish(false) end
        end,db,"ROLLBACK")
        if not handle then finish(false) end
    end
    step = function()
        if state.cancelled then return end
        state.index = state.index+1
        local row = rows[state.index]
        local sql = row and row.sql or "COMMIT"
        local values = row and row.values or {n=0}
        local handle = dbQuery(function(q)
            local result = dbPoll(q,0)
            if state.cancelled then return end
            if result == false then rollback()
            elseif row then step()
            else finish(true) end
        end,db,sql,unpack(values,1,values.n))
        if not handle then rollback() end
    end
    local handle = dbQuery(function(q)
        local result = dbPoll(q,0)
        if state.cancelled then return end
        if result == false then finish(false); return end
        state.transaction=true
        step()
    end,db,"BEGIN IMMEDIATE")
    if not handle then finish(false); return false end
    return true
end
