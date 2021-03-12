--assert(package.loadlib(getScriptPath() .. "\\iuplua51.dll", "luaopen_iuplua"))()
package.path = package.path .. ";Z:\\LuaIndicators\\?.lua;Z:\\LuaIndicators\\scripts\\robot_1\\?.lua"
local inspect = require('inspect')
local jsonStorage = require('jsonStorage')
local json = require('json')
local TradeCondition = require("TradeCondition")
local logfile_candle, logfile_price, logfile_stock, logfile_trades
local config = "config_split.cfg"
local is_run = true

if getScriptPath==nil then
    function getScriptPath()
        return "Z:\\LuaIndicators\\scripts\\robot_1"
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
    --if AllTraiding.tablelength(AllTraiding.data) == 0 then
    --    for key_code, _ in pairs(AllTraiding.config.CLASS_CODE) do
    --        for _,val in pairs(AllTraiding.config.SEC_CODES[key_code]) do
    --            AllTraiding.data[val] = {
    --                candle = {},
    --                all_trades = {}
    --            }
    --        end
    --    end
    --end
    --table.sinsert(AllTraiding.data[sec][type],data)
    --local now = os.time(os.date("!*t"))
    --if (now - AllTraiding.time) == 0 then
    --    return
    --end
    --AllTraiding.time = now

    --for key_code, class_code in pairs(AllTraiding.config.CLASS_CODE) do
    --    for _,val in pairs(AllTraiding.config.SEC_CODES[key_code]) do
    --        AllTraiding.data[val]["price_stock"] = getQuoteLevel2(class_code,val)
    --        AllTraiding.data[val]["price"] = getParamEx2(class_code,val,"bid")
    --    end
    --end

    --    for _,val in pairs(AllTraiding.config.SEC_CODES) do
    --        for _, val1 in pairs({"all_trades", "candle"}) do
    --            if #AllTraiding.data[val][val1] == 0 then
    --                return
    --            end
    --        end
    --    end
    --PrintDbgStr(inspect(data))
    --PrintDbgStr(os.date("%A",os.time({year=AllTraiding.data[sec]["candle"][1]["year"], month=AllTraiding.data[sec]["candle"][1]["month"], day=AllTraiding.data[sec]["candle"][1]["day"], hour=AllTraiding.data[sec]["candle"][1]["hour"]})))
    --PrintDbgStr(inspect(os.time({year=data[6]["year"], month=data[6]["month"], day=data[6]["day"], hour=data[6]["hour"], min=data[6]["min"]})))
    time = os.time({year=data[6]["year"], month=data[6]["month"], day=data[6]["day"], hour=data[6]["hour"], min=data[6]["min"]})
    date = os.date("%Y-%m-%dT%H:%M:%S", time)
    logfile_candle:write(date.."\t"..data[5].."\t"..data[3].."\t"..data[4].."\t"..data[2].."\t"..data[7].."\n")
    logfile_candle:flush()
    -- Если набор данных собран, выгружаем в файл.
    --AllTraiding.data['time'] = AllTraiding.time
    --local contents = json.encode(AllTraiding.data)
    --logfile:write(contents.."\n");
    --logfile:flush();
    --AllTraiding.data={}
end

function AllTraiding.calc(start_index, end_index)
    SearchItems("all_trades", start_index, end_index, AllTraiding['dataTraiding'])
end

function AllTraiding.dataTraiding(traid)
    for key_code, class_code in pairs(AllTraiding.config.CLASS_CODE) do
        for key,val in pairs(AllTraiding.config.SEC_CODES[key_code]) do
            if traid.sec_code == val then
                time = os.time({year=traid.datetime["year"], month=traid.datetime["month"], day=traid.datetime["day"], hour=traid.datetime["hour"], min=traid.datetime["min"], sec=traid.datetime["sec"]})
                --2013-01-01T00:40:19.259000
                --date = os.date("%Y-%m-%dT%H:%M:%S", time).."."..tostring(traid.datetime["mcs"])
                date = os.date("%Y-%m-%dT%H:%M:%S", time)
                logfile_trades:write(date.."\t"..traid.qty.."\t"..traid.price.."\t"..traid.flags.."\t"..traid.open_interest.."\n")
                logfile_trades:flush()
                return true
            end
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

function DataSourceClass:write(index)
    local candle = {}
    table.sinsert(candle,index)
    for _, val in pairs({'C','H','L','O','T','V'}) do
        table.sinsert(candle,self.ds[val](self.ds, index-1))
        --        PrintDbgStr(inspect(self.ds[val](self.ds, index)))
    end
    AllTraiding.setData("candle", self.SEC_CODES, candle)
end

function DataSourceClass:data(index)
    if self.end_candle >= index then
        return
    end
    self:write(index)
    end_index = getNumberOf("all_trades")-1
    AllTraiding.calc(AllTraiding.start_index, end_index)
    AllTraiding.start_index = end_index
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
    for key_code, val_code in pairs(self.config.CLASS_CODE) do
        for key,val in pairs(self.config.SEC_CODES[key_code]) do
            PrintDbgStr(inspect({val_code, val}))
            PrintDbgStr(inspect(Subscribe_Level_II_Quotes(val_code, val)))
            PrintDbgStr(inspect(ParamRequest(val_code, val, "bid")))
            local ds = CreateDataSource(val_code, val, INTERVAL_M1)
            local data = DataSourceClass({
                ds = ds,
                SEC_CODES = val,
                CLASS_CODE = val_code
            })
            for i = 2, data.end_candle do
                data:write(i)
            end

            AllTraiding.calc(0, AllTraiding.start_index)

            ds:SetUpdateCallback(bind(data, 'data'))
            table.insert(instanse,data)
        end
    end
    self.instanse = instanse
end

function ThreadSeconds(class_code, val)
    stock = getQuoteLevel2(class_code,val)
    price = getParamEx2(class_code,val,"bid")
    time = os.time(os.date("!*t"))
    date = os.date("%Y-%m-%dT%H:%M:%S", time)
    logfile_stock:write(date.."\t"..json.encode(stock.offer).."\n")
    logfile_price:write(date.."\t"..price["param_value"].."\n")
    logfile_stock:flush()
    logfile_price:flush()
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
    logfile_candle=io.open(getScriptPath() .. "/logger/logger_split_candle_" .. os.date("%d%m%Y")..".tsv", "w+")
    logfile_candle:write("Time".."\t".."Open".."\t".."High".."\t".."Low".."\t".."Close".."\t".."Volume".."\n")
    logfile_price=io.open(getScriptPath() .. "/logger/logger_split_price_" .. os.date("%d%m%Y")..".tsv", "w+")
    logfile_price:write("Time".."\t".."Price".."\n")
    logfile_stock=io.open(getScriptPath() .. "/logger/logger_split_stock_" .. os.date("%d%m%Y")..".tsv", "w+")
    logfile_stock:write("Time".."\t".."Stock".."\n")
    logfile_trades=io.open(getScriptPath() .. "/logger/logger_split_trades_" .. os.date("%d%m%Y")..".tsv", "w+")
    logfile_trades:write("Time".."\t".."Qty".."\t".."Price".."\t".."Flag".."\t".."Open Interest".."\n")
    local logger = LoggerClass()
    logger:initData()
    while true do
        ThreadSeconds("SPBFUT", "SRH1")
        sleep(1000)
    end
--    PrintDbgStr(inspect(logger.instanse))
--    while is_run do
--        sleep(300)
--    end
end
