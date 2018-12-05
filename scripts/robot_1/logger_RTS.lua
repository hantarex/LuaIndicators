assert(package.loadlib(getScriptPath() .. "\\iuplua51.dll", "luaopen_iuplua"))()
local inspect = require('inspect')
local jsonStorage = require('jsonStorage')
local json = require('json')
package.path = package.path .. ";../?.lua"
local TradeCondition = require("TradeCondition")

local config
local listTradeNum = {}
local startIndex, endIndex, currentDateCandle, currentIndex, labelBid, labelAsk, now, speed
local is_run = true
local DSInfo, Interval;
local logfile, logCandle, logDate, logDeal
local speed_interval = 10
local ds
local bids_count = {}
local all_trades = {}
local label_Candle ={}
local bids_count_speed = {}
local myTrade

function OnInit()
    config = jsonStorage.loadTable(getScriptPath().."/config/config_rts_f.cfg")
    message("Start " .. config.SEC_CODE .. " traiding...")
end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function OnStop()
    is_run = false
end

function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end

function getDateIndex(t)
    local newDate = copy(t)
    local minIndex = math.floor(newDate.min / Interval) * Interval
    newDate.min = minIndex
    newDate.sec = nil
    newDate.ms = nil
    newDate.mcs = nil
    return newDate
end

function serial(t)
    return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min)
end

function serialSec(t)
    return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min).. string.format("%02d",t.sec)
end

function serialDate(t)
    return string.format("%04d",t.year) .. ".".. string.format("%02d",t.month) .. ".".. string.format("%02d",t.day) .. " ".. string.format("%02d",t.hour) .. ":".. string.format("%02d",t.min) .. ":".. string.format("%02d",t.sec)
end

function fn(t)
    if t.sec_code == config.SEC_CODE and t.class_code == config.CLASS_CODE and listTradeNum[t.trade_num] == nil then
        table.sinsert(all_trades,t)
        local dateIndex = serial(getDateIndex(t.datetime))
        local dateIndexSpeed = serialSec(t.datetime)
        if bids_count[dateIndex] == nil then
            bids_count[dateIndex] = { bids = 0, asks = 0, vol = 0}
        end

        if bids_count_speed[dateIndexSpeed] == nil then
            bids_count_speed[dateIndexSpeed] = { bids = 0, asks = 0, vol = 0 }
        end

        if t.flags == 1 then
            bids_count[dateIndex].bids = bids_count[dateIndex].bids + t.qty
            bids_count_speed[dateIndexSpeed].bids = bids_count_speed[dateIndexSpeed].bids + t.qty
        elseif t.flags == 2 then
            bids_count[dateIndex].asks = bids_count[dateIndex].asks + t.qty
            bids_count_speed[dateIndexSpeed].asks = bids_count_speed[dateIndexSpeed].asks + t.qty
        end

        bids_count[dateIndex].vol = bids_count[dateIndex].vol + t.qty
        bids_count_speed[dateIndexSpeed].vol = bids_count_speed[dateIndexSpeed].vol + t.qty

        listTradeNum[t.trade_num] = true

        speed = getSpeed()

--        WriteLog(logfile, t.trade_num..";"..t.flags..";" ..t.price..";" ..t.qty..";" ..t.value..";" ..t.accruedint..";" ..t.yield..";" ..t.settlecode..";" ..t.reporate..";" ..t.repovalue..";" ..t.repo2value..";" ..t.repoterm..";" ..t.sec_code..";" ..t.class_code..";" ..dateIndex..";" ..t.period..";" ..t.open_interest..";" ..t.exchange_code..";" ..t.exec_market..";")
        return true
    else
        return false
    end

end

function cb( index )
    myTrade:setCandleIndex(index)
    myTrade:setO(ds:O(index))
    myTrade:setC(ds:C(index))
--    WriteLog(logCandle, index..";"
--            ..ds:O(index)..";"
--            ..ds:H(index)..";"
--            ..ds:L(index)..";"
--            ..ds:C(index)..";"
--            ..ds:V(index)..";"
--            ..serialDate(ds:T(index))..";"
--    )
    endIndex = getNumberOf("all_trades")-1
    if startIndex==0 then
        startIndex = endIndex
    end
    all_trades = {}
    SearchItems ("all_trades", startIndex, endIndex, fn)
    startIndex = endIndex

    local indexTime = serial(getDateIndex(ds:T(index)))

    if bids_count[indexTime] == nil then
        bids_count[indexTime] = { bids = 0, asks = 0, vol = 0}
    end


    if(label_Candle[index] == nil) then
        label_Candle[index] = {ask = 0, bid=0}
    end
    myTrade:setBids(bids_count_speed)
    myTrade:setDs(ds)
    local speed_meen =  myTrade:getSpeedMean(speed_interval)

    myTrade:appendToMeanList(speed_meen)
    myTrade:appendCandleDiff()

    --  return bids_count[indexTime].asks, 0 - bids_count[indexTime].bids, bids_count[indexTime].vol
    askSpeed = round(speed_meen.ask,2)

    bidSpeed = round(speed_meen.bid,2)

    label_Candle[index].bid = bids_count[indexTime].bids
    label_Candle[index].ask = bids_count[indexTime].asks

    myTrade:setBidSpeed(bidSpeed)
    myTrade:setAskSpeed(askSpeed)
    PrintDbgStr(tostring(myTrade:getSpeedTrade() / 2))
--    PrintDbgStr(inspect(
--        {
--            price = ds:C(index),
--            myTrade:getSpeedMean(speed_interval),
--            signal1 = myTrade:checkSignal1(),
--            signal3 = myTrade:checkSignal3(),
--            signal4 = myTrade:checkSignal4(),
--            signal5 = myTrade:checkSignal5(),
--            signal6 = myTrade:checkSignal6(),
--            signal7 = myTrade:checkSignal7(),
--            signal_sum = myTrade:signalSum(),
--        }
--    ))

    if ds:Size(index) ~= index then
        return false
    end

    local data = {
        time = os.time(os.date("!*t")),
        trades = all_trades,
        candles = {
            open = ds:O(index),
            high = ds:H(index),
            low = ds:L(index),
            close = ds:C(index),
            volume = ds:V(index),
            time = ds:T(index),
            size = ds:Size(index),
        }
    }


    local contents = json.encode(data)

    WriteLog(logfile, contents);
--    if myTrade:checkBid() and index == ds:Size() then
--        WriteLogDeal(logDeal,-1)
--    end
--    if myTrade:checkAsk() and index == ds:Size() then
--        WriteLogDeal(logDeal,1)
--    end
end

function serialSec(t)
    return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min).. string.format("%02d",t.sec)
end

function WriteLogDeal(logfile, deal)
    if deal > 0 then
        myTrade:setTrandSpeed(1)
    else
        myTrade:setTrandSpeed(-1)
    end

    local t = getParamEx(config.CLASS_CODE, config.SEC_CODE, "last")

    myTrade:setCurrentBid(t)

    PrintDbgStr("debug")

--    PrintDbgStr(inspect(
--        getSpeedMean()
--    ))


    if myTrade:isSpeedUp() then -- –астЄт
        PrintDbgStr("–астЄт " .. (myTrade:getProfit() ~= nil and myTrade:getProfit() or "nil")  .. " " .. (myTrade:getNeedProfit() ~=nil and myTrade:getNeedProfit() or "nil") .. " " .. (myTrade:getPositionPrice() ~=nil and myTrade:getPositionPrice() or "nil") .. " ".. myTrade:getLastDealMark())
        --      PrintDbgStr(inspect(
        --        myTrade
        --      ))
        if myTrade:isShort() then -- если в шорте
            if myTrade:getProfit() > myTrade:getNeedProfit() then -- если заработал то выходим из шорта
                myTrade:closePosition(t.param_value)
            elseif myTrade:checkStop() then
--                if myTrade:checkAsk(myTrade:getSpeedKoef(), true) then
--                    myTrade:goRev()
--                else
                    myTrade:closePosition(t.param_value)
--                end
--            elseif myTrade:checkRev() then
--                myTrade:goRev()
            end
        elseif myTrade:checkPosition() == false then -- если без позиции тогда заходим в лонг
            PrintDbgStr("¬ход в LONG")
            myTrade:goBuy(t.param_value)
        elseif myTrade:isLong() then -- если в лонге
            if myTrade:getProfit() > myTrade:getNeedProfit() then -- если заработал то выходим из шорта
                myTrade:closePosition(t.param_value)
            end
        end
    elseif myTrade:isSpeedDown() then -- падает
        PrintDbgStr("ѕадает " .. (myTrade:getProfit() ~= nil and myTrade:getProfit() or "nil") .. " " .. (myTrade:getNeedProfit() ~=nil and myTrade:getNeedProfit() or "nil") .. " " .. (myTrade:getPositionPrice() ~=nil and myTrade:getPositionPrice() or "nil") .. " ".. myTrade:getLastDealMark())
        if myTrade:isLong() then -- если в лонге
            if myTrade:getProfit() > myTrade:getNeedProfit() then -- если заработал то выходим из лонга
                myTrade:closePosition(t.param_value)
            elseif myTrade:checkStop() then
--                if myTrade:checkBid(myTrade:getSpeedKoef(), true) then
--                    myTrade:goRev()
--                else
                    myTrade:closePosition(t.param_value)
--                end
--            elseif myTrade:checkRev() then
--                myTrade:goRev()
            end
        elseif myTrade:checkPosition() == false then -- если без позиции тогда заходим в лонг
            PrintDbgStr("¬ход в SHORT")
            myTrade:goSell(t.param_value)
        elseif myTrade:isShort() then -- если в шорте
            if myTrade:getProfit() > myTrade:getNeedProfit() then -- если заработал то выходим из шорта
                myTrade:closePosition(t.param_value)
            end
        end
    end
    --  PrintDbgStr(inspect(
    --    myTrade
    --  ))
end;

function getSpeed()
    now=os.time()
    local speed = {bid = 0, ask = 0, vol = 0 }
    for i=0,(speed_interval-1) do
        local date = os.date("%Y%m%d%H%M%S",now-i)
        if bids_count_speed[date] == nil then
            bids_count_speed[date] = {bids = 0, asks = 0, vol = 0 }
        end
        speed.bid = speed.bid + bids_count_speed[date].bids
        speed.ask = speed.ask + bids_count_speed[date].asks
        speed.vol = speed.vol + bids_count_speed[date].vol
    end
    speed.bid = speed.bid / speed_interval
    speed.ask = speed.ask / speed_interval
    speed.vol = speed.vol / speed_interval
    --  PrintDbgStr(inspect(
    --    speed
    --  ))
    return speed
end

function WriteLog(logfile, text)
    logfile:write(text.."\n");
    logfile:flush();
end;

function OnDestroy()
    logfile:close() -- «акрывает файл
end

function main()
--    message("start")
--    dlg = iup.dialog
--        {
--            iup.vbox
--                {
--                    iup.label {title="Test iupLUA in QUIK"},
--                    iup.button{title="Button Very Long Text"},
--                    iup.button{title="short", expand="HORIZONTAL"},
--                    iup.button{title="Mid Button", expand="HORIZONTAL"}
--                }
--            ;title="IupDialog", font="Helvetica, Bold 14"
--        }
--    dlg:show()
--
--    iup.MainLoop()
    startIndex = 0
    Interval = config.interval

    if config.speed_interval ~= nil then
        speed_interval = config.speed_interval
    end

    logfile=io.open(getScriptPath() .. "/logger/logger_".. config.SEC_CODE .. "_" .. os.date("%d%m%Y")..".txt", "a+")
    myTrade = TradeCondition(config)
    myTrade:setAccount(config.ACCOUNT)
    myTrade:setDSInfo({
        class_code= config.CLASS_CODE,
        sec_code= config.SEC_CODE,
    })
--    PrintDbgStr(inspect(
--        {
--            test3 = myTrade:tableMean2({-1,-1,-1,-1,-1,5,5,5}),
--        }
--    ))
    ds = CreateDataSource(config.CLASS_CODE, config.SEC_CODE, INTERVAL_M5)
    ds: SetUpdateCallback (cb)
    PrintDbgStr(inspect(
        ds.sec_code
    ))
    while is_run do
--        message(os.date()) --раз в секунду выводит текущие дату и врем€
        sleep(1000)
    end
end
