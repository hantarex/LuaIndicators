--assert(package.loadlib(getScriptPath() .. "\\iuplua51.dll", "luaopen_iuplua"))()
package.path = package.path .. ";C:\\QUIK_AD\\Quik\\LuaIndicators\\?.lua;C:\\QUIK_AD\\Quik\\LuaIndicators\\scripts\\robot_1\\?.lua"
local inspect = require('inspect')
local jsonStorage = require('jsonStorage')
local json = require('json')
local TradeCondition = require("TradeCondition")
local logfile
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

function OnDestroy()
    logfile:close() -- Закрывает файл
end

AllTraiding = {
    start_index = getNumberOf("all_trades")-1,
    active = {},
    data = {},
    time = os.time(os.date("!*t"))
}

function AllTraiding.tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function AllTraiding.setData(type, sec, data)
    if AllTraiding.tablelength(AllTraiding.data) == 0 then
        for _,val in pairs(AllTraiding.config.SEC_CODES) do
            AllTraiding.data[val] = {
                candle = {},
                all_trades = {}
            }
        end
    end
    table.sinsert(AllTraiding.data[sec][type],data)
    local now = os.time(os.date("!*t"))
    if (now - AllTraiding.time) == 0 then
        return
    end
    AllTraiding.time = now

    for _,val in pairs(AllTraiding.config.SEC_CODES) do
        AllTraiding.data[val]["price_stock"] = getQuoteLevel2(AllTraiding.config.CLASS_CODE,val)
        AllTraiding.data[val]["price"] = getParamEx2(AllTraiding.config.CLASS_CODE,val,"bid")
    end
--    for _,val in pairs(AllTraiding.config.SEC_CODES) do
--        for _, val1 in pairs({"all_trades", "candle"}) do
--            if #AllTraiding.data[val][val1] == 0 then
--                return
--            end
--        end
--    end

    -- Если набор данных собран, выгружаем в файл.
    AllTraiding.data['time'] = AllTraiding.time
    local contents = json.encode(AllTraiding.data)
    AllTraiding.data={}
    logfile:write(contents.."\n");
    logfile:flush();
end

function AllTraiding.calc()
    if #AllTraiding.active == 0 then
        table.sinsert(AllTraiding.active,1,1)
        local end_index = getNumberOf("all_trades")-1
        local table_index = SearchItems ("all_trades", AllTraiding.start_index, end_index, AllTraiding['dataTraiding'])
--        PrintDbgStr(inspect(AllTraiding.start_index .. " " .. end_index))
    --    PrintDbgStr(inspect(table_index))
        AllTraiding.start_index = end_index+1
    end
    table.sremove(AllTraiding.active,1)
end

function AllTraiding.dataTraiding(traid)
    for key,val in pairs(AllTraiding.config.SEC_CODES) do
        if traid.sec_code == val then
--            PrintDbgStr(inspect(traid.qty))
            AllTraiding.setData("all_trades", val, traid)
            return true
        end
    end
    return false
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
        CLASS_CODE = options.CLASS_CODE,
        end_candle = options.ds:Size(),
    }
--    PrintDbgStr(inspect(ParamRequest(init.CLASS_CODE, init.SEC_CODES,"qty")))
--    PrintDbgStr(inspect(getParamEx2(init.CLASS_CODE, init.SEC_CODES,"qty")))
    return setmetatable(init, { __index = DataSourceClass })
end

function DataSourceClass:data(index)
    if self.end_candle > index then
        return
    end
    local candle = {}
    table.sinsert(candle,index)
    for _, val in pairs({'C','H','L','O','T','V'}) do
        table.sinsert(candle,self.ds[val](self.ds, index))
--        PrintDbgStr(inspect(self.ds[val](self.ds, index)))
    end
    AllTraiding.setData("candle", self.SEC_CODES, candle)
    AllTraiding.calc()
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
        config = jsonStorage.loadTable(getScriptPath().."/config/"..config),
    }
    init.start_index = getNumberOf("all_trades")-1;
    return setmetatable(init, { __index = LoggerClass })
end

function LoggerClass:initData()
    local instanse = {}
    AllTraiding.start_index = getNumberOf("all_trades")-1;
    AllTraiding.config = self.config
    for key,val in pairs(self.config.SEC_CODES) do
        PrintDbgStr(inspect(Subscribe_Level_II_Quotes(self.config.CLASS_CODE, val)))
        PrintDbgStr(inspect(ParamRequest(self.config.CLASS_CODE, val, "bid")))
        local ds = CreateDataSource(self.config.CLASS_CODE, val, INTERVAL_M5)
        local data = DataSourceClass({
            ds = ds,
            SEC_CODES = val,
            CLASS_CODE = self.config.CLASS_CODE
        })
        ds:SetUpdateCallback(bind(data, 'data'))
        table.insert(instanse,data)
    end
    self.instanse = instanse
end

--function LoggerClass:startTraidingMonitoring()
--    local end_index = getNumberOf("all_trades")-1
--    PrintDbgStr(inspect(end_index))
--    SearchItems ("all_trades", self.start_index, end_index, bind(self,'dataTraiding'))
--    self.start_index = end_index
--end

function bind(cls, method)
    return function(...) cls[method](cls,...) end
end

function main()
    logfile=io.open(getScriptPath() .. "/logger/logger_all_" .. os.date("%d%m%Y")..".json", "a+")
    local logger = LoggerClass()
    logger:initData()

--    PrintDbgStr(inspect(logger.instanse))
    while is_run do
        sleep(1000)
    end
end
