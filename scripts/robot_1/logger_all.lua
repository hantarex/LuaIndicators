--assert(package.loadlib(getScriptPath() .. "\\iuplua51.dll", "luaopen_iuplua"))()
package.path = package.path .. ";C:\\QUIK_AD\\Quik\\LuaIndicators\\?.lua;C:\\QUIK_AD\\Quik\\LuaIndicators\\scripts\\robot_1\\?.lua"
local inspect = require('inspect')
local jsonStorage = require('jsonStorage')
local json = require('json')
local TradeCondition = require("TradeCondition")

local config = "config_all.cfg"
local is_run = true

if getScriptPath==nil then
    function getScriptPath()
        return "C:\\QUIK_AD\\Quik\\LuaIndicators\\scripts\\robot_1"
    end
end

if PrintDbgStr == nil then
    function PrintDbgStr(arg)
        return print(arg)
    end
end

function OnStop()
    is_run = false
end

DataSourceClass = {}
DataSourceClass.__index = DataSourceClass
setmetatable(DataSourceClass, {
    __call = function(cls,...)
        return cls:create(...)
    end,
})

function DataSourceClass:create(options)
    local init = {
        ds = options.ds,
        SEC_CODES = options.SEC_CODES,
        end_candle = options.ds:Size()
    }
    return setmetatable(init, { __index = DataSourceClass })
end

function DataSourceClass:data(index)
    if self.end_candle > index then
        return
    end
    PrintDbgStr(inspect(index))
    self.end_candle = self.ds:Size()
end

LoggerClass = {}
LoggerClass.__index = LoggerClass

setmetatable(LoggerClass, {
    __call = function(cls,...)
        return cls:create(...)
    end,
})


function LoggerClass:create(options)
    local init = {
        config = jsonStorage.loadTable(getScriptPath().."/config/"..config)
    }
    return setmetatable(init, { __index = LoggerClass })
end

function LoggerClass:initData()
    local instanse = {}
    for key,val in pairs(self.config.SEC_CODES) do
        local ds = CreateDataSource(self.config.CLASS_CODE, val, INTERVAL_M5)
        local data = DataSourceClass({
            ds = ds,
            SEC_CODES = val
        })
        ds:SetUpdateCallback(bind(data, 'data'))
        table.insert(instanse,data)
    end
    self.instanse = instanse
end

function bind(cls, method)
    return function(...) cls[method](cls,...) end
end

function main()
    local logger = LoggerClass()
    logger:initData()

--    PrintDbgStr(inspect(logger.instanse))
    while is_run do
        sleep(1000)
    end
end
