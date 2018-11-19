--
-- Created by IntelliJ IDEA.
-- User: ashikov
-- Date: 10.09.2018
-- Time: 18:26
-- To change this template use File | Settings | File Templates.
--
local inspect = require('inspect')

TradeCondition = {}
TradeCondition.__index = TradeCondition

setmetatable(TradeCondition, {
    __call = function(cls,...)
        return cls:create(...)
    end,
})

--function TradeCondition:create(fees, needProfit, stopOrder, speed, isTraiding, needBestProfit, numTraiding, speedKoef)
function TradeCondition:create(options)
    local init = {
        positionPrice = nil,
        DSInfo = nil,
        position = 0,
        bids = 0,
        ds = nil,
        pause = 5, -- set Interval after close position
        transactionPrefix = os.time(os.date("!*t")),
        transactionPostfix = 1,
        isTraiding = false, -- is traiding
        logfile = nil,
        speed_interval = 10, -- first interval for condition
        speed_two_interval = 20, -- two interval for condition
        speed_three_interval = 50, -- three interval for condition
        rev_mult = 20, -- delimiter speed for rev
        askSpeed = 0,
        isClose = 0,
        closeToMinus = false,
        badDeal = 0,
        meanList = {bid = {}, ask = {}, vol = {}},
        bidSpeed =0,
        speedKoef = 7,
        candleDiff = {},
        timePause = os.time(os.date("!*t")),
        isIndex = false,
        O,
        C,
        numTraiding = 1,
        rev = false
    }
    if options.fees ~= nil then
        init.fees = options.fees
    end

    if options.speed_interval ~= nil then
        init.speed_interval = options.speed_interval
    end

    if options.rev_mult ~= nil then
        init.rev_mult = options.rev_mult
    end

    if options.speed_two_interval ~= nil then
        init.speed_two_interval = options.speed_two_interval
    end

    if options.speed_three_interval ~= nil then
        init.speed_three_interval = options.speed_three_interval
    end

    if options.pause ~= nil then
        init.pause = options.pause
    end

    if options.isTraiding ~= nil then
        if options.isTraiding == 1 then
            init.isTraiding = true
        else
            init.isTraiding = false
        end
    end

    if options.isIndex ~= nil then
        if options.isIndex == 1 then
            init.isIndex = true
        else
            init.isIndex = false
        end
    end

    if options.needProfit ~= nil then
        init.needProfit = options.needProfit
    end

    if options.numTraiding ~= nil then
        init.numTraiding = options.numTraiding
    end

    if options.speedKoef ~= nil then
        init.speedKoef = options.speedKoef
    end

    if options.needBestProfit ~= nil then
        init.needBestProfit = options.needBestProfit
    end

    if options.stopOrder ~= nil then
        init.stopOrder = options.stopOrder
    end

    if options.speedTrade ~= nil then
        init.speed = options.speedTrade
        init.startSpeed = options.speedTrade
    else
        init.speed = 2000
        init.startSpeed = init.speed
    end

    init.transactionMarket = {
        ["TRANS_ID"]   = tostring(init.transactionPostfix),
        ["ACTION"]     = "NEW_ORDER",
        --        ["OPERATION"]  = "S", -- покупка (BUY)
        ["TYPE"]       = "M", -- по рынку (MARKET)
        ["QUANTITY"]   = tostring(init.numTraiding), -- количество
        ["ACCOUNT"]    = "L01-00000F00",
        ["CLIENT_CODE"]    = "108191/001",
        ["PRICE"]      = "0"
    }
    return setmetatable(init, { __index = TradeCondition })
end

function TradeCondition:getSpeedTrade()
    return self.speed
end

function TradeCondition:getMeanList()
    return self.meanList
end

function TradeCondition:getCandleDiff()
    return self.candleDiff
end

function TradeCondition:appendToMeanList(val)
    table.sinsert(self:getMeanList().ask, val.ask)
    table.sinsert(self:getMeanList().bid, val.bid)
    table.sinsert(self:getMeanList().vol, val.vol)
end

function TradeCondition:appendCandleDiff()
    if #self:getCandleDiff() == 0 then
        table.sinsert(self:getCandleDiff(), 0)
    else
        local diff = self:getDs():C(self:getCandleIndex()) - self.lastPriceCandle
        table.sinsert(self:getCandleDiff(), diff)
    end
--    PrintDbgStr(inspect(
--        {
--            self.lastPriceCandle,
--            self:getDs():C(self:getCandleIndex())
--        }
--    ))
    self.lastPriceCandle = self:getDs():C(self:getCandleIndex())
end

function TradeCondition:getLastCandleDiff()
    if #self:getCandleDiff() == 0 then
        return 0
    else
        return self:getCandleDiff()[#self:getCandleDiff()]
    end
end

function TradeCondition:getRevMult()
    return self.rev_mult
end

function TradeCondition:getSpeedTwoInterval()
    return self.speed_two_interval
end

function TradeCondition:getSpeedThreeInterval()
    return self.speed_three_interval
end

function TradeCondition:getSpeedInterval()
    return self.speed_interval
end

function TradeCondition:getIsClose()
    return self.isClose
end

function TradeCondition:setIsClose(set)
    self.isClose = set
end

function TradeCondition:setBids(bids)
    self.bids = bids
end

function TradeCondition:setDs(ds)
    self.ds = ds
end

function TradeCondition:getDs()
    return self.ds
end

function TradeCondition:getBids()
    return self.bids
end

function TradeCondition:updateTimePause()
    self.timePause = os.time(os.date("!*t"))
end

function TradeCondition:getNumTraiding()
    return self.numTraiding
end

function TradeCondition:checkIndex()
    return self.isIndex
end

function TradeCondition:getSpeedKoef()
    return self.speedKoef
end

function TradeCondition:setSpeedKoef(k)
    self.speedKoef = k
end

function TradeCondition:setAccount(account)
    self.transactionMarket["ACCOUNT"] = account
end

function TradeCondition:getCloseToMinus()
    return self.closeToMinus
end

function TradeCondition:setCloseToMinus(set)
    self.closeToMinus = set
end

function TradeCondition:setO(O)
    self.O = O
end

function TradeCondition:setC(C)
    self.C = C
end

function TradeCondition:iterateTransaction()
    self.transactionMarket["TRANS_ID"] = tostring(self.transactionMarket["TRANS_ID"] + 1)
end

function TradeCondition:getDSInfo()
    return self.DSInfo
end

function TradeCondition:getNeedBestProfit()
    if self:getPositionPrice() == nil then
        return nil
    end
    local need = self:round(tonumber(self:getPositionPrice()) / 100, 2) * self.needBestProfit
    return need
end

function TradeCondition:getIsTraiding()
    return self.isTraiding
end

function TradeCondition:setDSInfo(ds)
    self.DSInfo = ds
    self.transactionMarket.CLASSCODE = self:getDSInfo().class_code
    self.transactionMarket.SECCODE = self:getDSInfo().sec_code
    self.logfile = io.open(getScriptPath() .. "/log/deal_".. self.transactionMarket.SECCODE .."_"..os.date("%d%m%Y%H%M%S")..".txt", "w")
end

function TradeCondition:getStartSpeedTrade()
    return self.startSpeed
end

function TradeCondition:setSpeedTrade(speed)
    self.speed = speed
end

function TradeCondition:getProfitAbs()
    local profit = 0
    if self:getPositionPrice() == nil then
        return profit
    end
    if self:isShort() then
        profit = self:getPositionPrice() - self:getCurrentPrice()
    end
    if self:isLong() then
        profit = self:getCurrentPrice() - self:getPositionPrice()
    end
    return profit
end

function TradeCondition:getProfit()
    if self:getPositionPrice() == nil then
        return nil
    end
    if self:isShort() then
        local tax = self:round(tonumber(self:getPositionPrice()) / 100, 2) * self:getFees()
        local profit = self:getPositionPrice() - self:getCurrentPrice()
        return profit - tax
    end
    if self:isLong() then
        local tax = self:round(tonumber(self:getPositionPrice()) / 100, 2) * self:getFees()
        local profit = self:getCurrentPrice() - self:getPositionPrice()
        return profit - tax
    end
    return 0
end

function TradeCondition:isLong()
    if self.position == 1 and self.positionPrice ~= nil then
        return true
    end
    return false
end

function TradeCondition:getStopOrder()
    return self:round(tonumber(self:getPositionPrice()) / 100 * (self.stopOrder + self:getFees()) , 2)
end

function TradeCondition:getStopOrderAbs()
    abs = self:round(tonumber(self:getPositionPrice()) / 100 * (self.stopOrder + self:getFees()) , 2)

    if self:isShort() then
        return tonumber(self:getPositionPrice()) + abs
    else
        return tonumber(self:getPositionPrice()) - abs
    end
end

function TradeCondition:getO()
    return self.O
end

function TradeCondition:getC()
    return self.C
end

function TradeCondition:getColorCandle()
    PrintDbgStr(inspect(
        self:getO()
    ))
    PrintDbgStr(inspect(
        self:getC()
    ))
    if self:getO() > self:getC() then
        return -1
    else
        return 1
    end
end

function TradeCondition:setTrandSpeed(trand)
    self.trandSpeed = trand
end

function TradeCondition:setBidSpeed(speed)
    self.bidSpeed = speed
end

function TradeCondition:setAskSpeed(speed)
    self.askSpeed = speed
end

function TradeCondition:round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function TradeCondition:isSpeedUp()
    if self.trandSpeed == 1 then
        return true
    end
    return false
end

function TradeCondition:isSpeedDown()
    if self.trandSpeed == -1 then
        return true
    end
    return false
end

function TradeCondition:getPositionPrice()
    return self.positionPrice
end

function TradeCondition:checkPosition()
    if self.position ~= 0 then
        return true
    end
    return false
end

function TradeCondition:setPositionPrice(price)
    self.positionPrice = price
end

function TradeCondition:isShort()
    if self.position == -1 and self.positionPrice ~= nil then
        return true
    end
    return false
end

function TradeCondition:setLastDealMark(success)
    if success == false then
        PrintDbgStr("Добавление множителя!")
        self.badDeal = self.badDeal + 1
    else
        self.badDeal = 0
    end
end

function TradeCondition:getLastDealMark()
    return self.badDeal
end

function TradeCondition:checkSignal2()
    return { mean = {
        self:getSpeedMean2(self:getBids(), self:getSpeedInterval()),
        self:getSpeedMean2(self:getBids(), self:getSpeedTwoInterval()),
        self:getSpeedMean2(self:getBids(), self:getSpeedThreeInterval()),
    }
}
end

function TradeCondition:checkSignal3()
    local t = {ask = 0, bid = 0, vol = 0}
    local myTable = {
        self:getSpeedMean(self:getSpeedInterval()),
        self:getSpeedMean(self:getSpeedTwoInterval()),
        self:getSpeedMean(self:getSpeedThreeInterval()),
    }
--        PrintDbgStr(inspect(
--            myTable
--        ))
    for key,value in pairs(myTable) do
        --        PrintDbgStr(inspect(
        --            value
        --        ))
        t.ask = t.ask + value.ask
        t.bid = t.bid + value.bid
        t.vol = t.vol + value.vol
    end
    t.ask = t.ask / #myTable
    t.bid = t.bid / #myTable
    t.vol = t.vol / #myTable

    return t
end

function TradeCondition:checkSignal4()
    local candleDiff = self:getCandleDiff()
    return self:sigmoid2(self:getMedianSimple(candleDiff, 50, true))
end

function TradeCondition:checkSignal7()
    local candleDiff = self:getCandleDiff()
    return self:sigmoid2(self:getMeanOfTable(self:getSortMedian(candleDiff, 10)))
end

function TradeCondition:checkSignal5()
    local tbl = self:tableMean2(self:tableMean(self:getSortMedian(self:getCandleDiff(), 49)))
    local zeros = 0
--    PrintDbgStr(inspect(
--        tbl
--    ))
    for key,value in pairs(tbl) do
        if value == 0 then zeros = zeros + 1 end
    end
    zeros = math.floor(zeros / 2)
    local key_zero = self:stats_search(tbl, 0)
    if key_zero == false then return false end
    local center = key_zero + zeros
    if center / (#tbl/2) > 1 then
        return self:sigmoid(math.abs((#tbl/2) - center))
    else
        return self:sigmoid(0 - math.abs((#tbl/2) - center))
    end
end

function TradeCondition:sigmoid(x)
    if math.abs(x) < 0.5 then
        return 0
    end
    return round(x / ( 1 + math.abs(x)),0)
end

function TradeCondition:sigmoid2(x , add)
    if math.abs(x) < 0.2 then
        return 0
    end
    return round(math.tanh (x) * (add ~= nil and add or 1),0)
end

function TradeCondition:checkSignal6()
    local sign = self:checkSignal1()
    local x
--    PrintDbgStr(inspect(
--        {
--            test= sign,
--            speed = self:getStartSpeedTrade()
--        }
--    ))
    if sign.vol < self:getStartSpeedTrade() then
        return 0
    end
    sign.ask = tonumber(sign.ask)
    sign.bid = tonumber(sign.bid)
    if sign.ask > sign.bid then
        x = math.log(math.floor(sign.ask / sign.bid))
    else
        x = 0 - math.log(math.floor(sign.bid / sign.ask))
    end
    return self:sigmoid2(x*2, 2)
--    return round(3 * x / ( 2 + math.abs(x)),0)
end

function TradeCondition:checkSignal1()
    local t = {ask = 0, bid = 0, vol = 0}
    local myTable = {
        self:getSpeedMean2(self:getBids(), self:getSpeedInterval()),
        self:getSpeedMean2(self:getBids(), self:getSpeedTwoInterval()),
        self:getSpeedMean2(self:getBids(), self:getSpeedThreeInterval()),
    }
--    PrintDbgStr(inspect(
--        myTable
--    ))
    for key,value in pairs(myTable) do
--        PrintDbgStr(inspect(
--            value
--        ))
        t.ask = t.ask + value.ask
        t.bid = t.bid + value.bid
        t.vol = t.vol + value.vol
    end
    t.ask = t.ask / #myTable
    t.bid = t.bid / #myTable
    t.vol = t.vol / #myTable

    return t
end

function TradeCondition:getSpeedMean2(t, lenght)
    local now=os.time()
    local speed = {bid = 0, ask = 0, vol = 0 }
    for i=0,(lenght-1) do
        local date = os.date("%Y%m%d%H%M%S",now-i)
        if t[date] == nil then
            t[date] = {bids = 0, asks = 0, vol = 0 }
        end
        speed.bid = speed.bid + t[date].bids
        speed.ask = speed.ask + t[date].asks
        speed.vol = speed.vol + t[date].vol
    end
    speed.bid = speed.bid / lenght
    speed.ask = speed.ask / lenght
    speed.vol = speed.vol / lenght
    --  PrintDbgStr(inspect(
    --    speed
    --  ))
    return speed
end

function TradeCondition:closePosition(price)
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    PrintDbgStr("Закрытие позиции!")
--    self:getDebug(self:getProfit())
    if self:getProfit() < self:getNeedProfit()
            and ((self:getColorCandle() ~= 1 and self:isLong()) or (self:getColorCandle() ~= -1 and self:isShort())) and
            self:checkPause()
    then
--        self.logfile:write(dateDeal..";Закрытие в минус\n");
        PrintDbgStr("Закрытие в минус")
        self:setCloseToMinus(true)
    elseif self:checkPause() then
        self:setCloseToMinus(false)
    end
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    self:setIsClose(1)
    if self:isShort() then
        self:goBuy(price)
    elseif self:isLong() then
        self:goSell(price)
    end
    self:setIsClose(0)
    return false
end

--function TradeCondition:checkStop()
--    if self:getPositionPrice() == nil or self:getCurrentPrice() == nil then
--        return false
--    end
--
----    PrintDbgStr(inspect(
----        self:getCurrentPrice()
----    ))
----
----    PrintDbgStr(inspect(
----        self:getPositionPrice()
----    ))
--    local mean = self:getMedian(self:getMeanList(), 10);
--    local stopMean = false
--    if self:isShort() then
--        if round(mean.ask + 1,2) / round(mean.bid + 1,2) > 2 then
--            stopMean = true
--        end
--    end
--    if self:isLong() then
--        if round(mean.bid + 1,2) / round(mean.ask + 1,2) > 2 then
--            stopMean = true
--        end
--    end
--    PrintDbgStr("Стоп? " .. (0 - self:getProfit()) .." ".. self:getStopOrder() .. " " .. self:getStopOrderAbs())
--    if (0 - self:getProfit()) > self:getStopOrder() or stopMean
--    then
--        return true
--    else
--        return false
--    end
--end

function TradeCondition:checkStop()
    if self:getPositionPrice() == nil or self:getCurrentPrice() == nil then
        return false
    end

    --    PrintDbgStr(inspect(
    --        self:getCurrentPrice()
    --    ))
    --
    --    PrintDbgStr(inspect(
    --        self:getPositionPrice()
    --    ))
    local stopMean = false
    if self:isShort() then
        if self:signalSum() > 1 then
            stopMean = true
        end
    end
    if self:isLong() then
        if self:signalSum() < -1 then
            stopMean = true
        end
    end
    PrintDbgStr("Стоп? " .. (0 - self:getProfit()) .." ".. self:getStopOrder() .. " " .. self:getStopOrderAbs())
    if (0 - self:getProfit()) > self:getStopOrder() or stopMean
    then
        return true
    else
        return false
    end
end

function TradeCondition:checkPause()
    PrintDbgStr("Проверка паузы!\n");
    if self.rev == true then
        PrintDbgStr("REV!");
        PrintDbgStr(inspect(
            self.rev
        ))
        return true
    end
    return os.time(os.date("!*t")) - self.timePause > self.pause
end

function TradeCondition:goBuy(price)
    PrintDbgStr("Покупка!")
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
--    if self:getColorCandle() ~= 1 and self:getPositionPrice() ~= nil then -- цена идёт вниз по свече
--        PrintDbgStr("Цена идёт вниз по свече " .. (self:getNeedBestProfit() ~=nil and self:getNeedBestProfit() or "nil") .. "\n");
--        if (self:getBidSpeed() * 1.5) < self:getAskSpeed() and self:getProfit() > self:getNeedBestProfit() then
--            PrintDbgStr("Скорость взлёта больше падения! И достигнут бестпрофит!\n");
----        elseif self:checkIndex() and self:getProfit() > self:getNeedBestProfit() then
----            PrintDbgStr("Достигнут бестпрофит в индексе!\n");
--        elseif self:checkIndex() and self:getIsClose() and self:getBidSpeed() < self:getAskSpeed() then
--            PrintDbgStr("Закрытие в индексе!\n");
--        else
--            return false
--        end
--    end

    if self:getCloseToMinus() == true and self:getPosition() ~= 0 then
        self:setLastDealMark(false);
    else
        self:setLastDealMark(true);
    end

    PrintDbgStr("Проверка позиции!\n");
    if self:getPosition() == 0 and self:checkPause() then
        PrintDbgStr("Без позиции!\n");
        self:setPositionPrice(price)
        self:setPosition(1)
        self:setSpeedTrade(self:getSpeedTrade() / self:getSpeedKoef())
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self.logfile:write(dateDeal..";Покупка;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .. ";" .. inspect(self:checkSignal1()) .. ";" .. inspect(self:checkSignal3()) .. ";" .. inspect(self:checkSignal4()).. ";" .. inspect(self:checkSignal5()).. ";" .. inspect(self:checkSignal6()).. ";" .. inspect(self:checkSignal7()).. "\n");
    elseif self:getPosition() == -1 then
        PrintDbgStr("В позиции!\n");
        self:setSpeedTrade(self:getStartSpeedTrade() + self:getLastDealMark()*0.2*self:getStartSpeedTrade())
        PrintDbgStr(self:getStartSpeedTrade() .." + "..self:getLastDealMark().." * 0.2 * "..self:getStartSpeedTrade());
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self:updateTimePause()
        self.logfile:write(dateDeal..";Покупка;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .. ";" .. inspect(self:checkSignal1()) .. ";" .. inspect(self:checkSignal3()) .. ";" .. inspect(self:checkSignal4()).. ";" .. inspect(self:checkSignal5()).. ";" .. inspect(self:checkSignal6()).. ";" .. inspect(self:checkSignal7()).. "\n");
        self:setPosition(0)
        self:setPositionPrice(nil)
    end
    self.logfile:flush()
    return false
end

function TradeCondition:transactionSell()
    self.transactionMarket["OPERATION"]  = "S"
    PrintDbgStr(inspect(
        self.transactionMarket
    ))
    local res = sendTransaction(self.transactionMarket)
    self:iterateTransaction()
    if res ~= "" then
        message("Транзакция %s не прошла проверку на стороне терминала QUIK")
    else
        message("Транзакция отправлена")
    end
end

function TradeCondition:transactionBuy()
    self.transactionMarket["OPERATION"]  = "B"
    PrintDbgStr(inspect(
        self.transactionMarket
    ))
    local res = sendTransaction(self.transactionMarket)
    self:iterateTransaction()
    if res ~= "" then
        message("Транзакция %s не прошла проверку на стороне терминала QUIK")
    else
        message("Транзакция отправлена")
    end
end

function TradeCondition:goSell(price)
    PrintDbgStr("Продажа!")
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
--    if self:getColorCandle() ~= -1 and self:getPositionPrice() ~= nil then -- цена идёт вверх по свече
--        PrintDbgStr("Цена идёт вверх по свече " .. (self:getNeedBestProfit() ~=nil and self:getNeedBestProfit() or "nil") .. "\n");
--        if self:getBidSpeed() > (self:getAskSpeed() * 1.5)
--                and self:getProfit() > self:getNeedBestProfit() then
--            PrintDbgStr("Скорость падения больше взлёта! И достигнут бестпрофит!\n");
----        elseif self:checkIndex() and self:getProfit() > self:getNeedBestProfit() then
----            PrintDbgStr("Достигнут бестпрофит в индексе!\n");
--        elseif self:checkIndex() and self:getIsClose() and self:getBidSpeed() > self:getAskSpeed() then
--            PrintDbgStr("Закрытие в индексе!\n");
--        else
--            return false
--        end
--    end

    if self:getCloseToMinus() == true and self:getPosition() ~= 0 then
        self:setLastDealMark(false);
    else
        self:setLastDealMark(true);
    end

    if self:getPosition() == 0 and self:checkPause() then
        self:setPositionPrice(price)
        self:setPosition(-1)
        self:setSpeedTrade(self:getSpeedTrade() / self:getSpeedKoef())
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self.logfile:write(dateDeal..";Продажа;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .. ";" .. inspect(self:checkSignal1()) .. ";" .. inspect(self:checkSignal3()) .. ";" .. inspect(self:checkSignal4()).. ";" .. inspect(self:checkSignal5()).. ";" .. inspect(self:checkSignal6()).. ";" .. inspect(self:checkSignal7()) .."\n");

    elseif self:getPosition() == 1 then
        self:setSpeedTrade(self:getStartSpeedTrade() + self:getLastDealMark()*0.2*self:getStartSpeedTrade())
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self:updateTimePause()
        self.logfile:write(dateDeal..";Продажа;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .. ";" .. inspect(self:checkSignal1()) .. ";" .. inspect(self:checkSignal3()) .. ";" .. inspect(self:checkSignal4()).. ";" .. inspect(self:checkSignal5()).. ";" .. inspect(self:checkSignal6()).. ";" .. inspect(self:checkSignal7()).. "\n");
        self:setPosition(0)
        self:setPositionPrice(nil)
    end
    self.logfile:flush()
    return false
end

function TradeCondition:setCurrentBid(bid)
    self.bid = bid
end

function TradeCondition:getCurrentBid()
    return self.bid
end

function TradeCondition:getAskSpeed()
    return self.askSpeed
end

function TradeCondition:getBidSpeed()
    return self.bidSpeed
end

--function TradeCondition:checkBid(speedKoef, rev)
--    if speedKoef == nil then
--        speedKoef =1
--    end
--    if rev == nil then
--        rev =false
--    end
--    local mean = self:getMedian(self:getMeanList(), 10);
--    if round(self:getSpeedMean(self:getSpeedInterval()).bid,2) > (self:getSpeedTrade()*speedKoef) and
--            round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) > ((self:getSpeedTrade()*speedKoef) / 2) and
--            round(self:getSpeedMean(self:getSpeedInterval()).bid,2) > round(self:getSpeedMean(self:getSpeedInterval()).ask,2) and
--            round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) > round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) or
----            round(self:getSpeedMean(self:getSpeedThreeInterval()).bid,2) > round(self:getSpeedMean(self:getSpeedThreeInterval()).ask,2) or
--            (rev == false and self:checkPosition() ~= false and round(mean.bid + 1,2) / round(mean.ask + 1,2) > 2) and round(mean.bid,2) ~= 0 and round(mean.ask,2) ~= 0 then
--        return true
--    end
--    return false
--end

function TradeCondition:signalSum()
   return (self:checkSignal4() + self:checkSignal5() + self:checkSignal6() + self:checkSignal7())
end

function TradeCondition:checkBid(speedKoef, rev)
    if speedKoef == nil then
        speedKoef =1
    end
    if rev == nil then
        rev =false
    end
    if self:checkPosition() == false or rev == true  then
        if self:signalSum() < -3
        then
            return true
        else
            return false
        end
    else
        if self:signalSum() < -1
        then
            return true
        else
            return false
        end
    end
    return false
end

--function TradeCondition:checkAsk(speedKoef, rev)
--    if speedKoef == nil then
--        speedKoef =1
--    end
--    if rev == nil then
--        rev =false
--    end
--    local mean = self:getMedian(self:getMeanList(), 10);
--    if round(self:getSpeedMean(self:getSpeedInterval()).ask,2) > (self:getSpeedTrade()*speedKoef) and
--            round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) > ((self:getSpeedTrade()*speedKoef) / 2) and
--            round(self:getSpeedMean(self:getSpeedInterval()).ask,2) > round(self:getSpeedMean(self:getSpeedInterval()).bid,2) and
--            round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) > round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) or
----            round(self:getSpeedMean(self:getSpeedThreeInterval()).ask,2) > round(self:getSpeedMean(self:getSpeedThreeInterval()).bid,2) or
--            (rev == false and self:checkPosition() ~= false and round(mean.ask + 1,2) > round(mean.bid + 1,2) > 2) and round(mean.bid,2) ~= 0 and round(mean.ask,2) ~= 0 then
--        return true
--    end
--    return false
--end

function TradeCondition:checkAsk(speedKoef, rev)
    if speedKoef == nil then
        speedKoef =1
    end
    if rev == nil then
        rev =false
    end
    if self:checkPosition() == false or rev == true  then
        if self:signalSum() > 3
        then
            return true
        else
            return false
        end
    else
        if self:signalSum() > 1
        then
            return true
        else
            return false
        end
    end
    return false
end

--function TradeCondition:checkRev()
--    local ask = self:getSpeedMean(self:getSpeedTwoInterval()).ask < 2 and 2 or self:getSpeedMean(self:getSpeedTwoInterval()).ask
--    local bid = self:getSpeedMean(self:getSpeedTwoInterval()).bid < 2 and 2 or self:getSpeedMean(self:getSpeedTwoInterval()).bid
--    PrintDbgStr("Reward?")
--    PrintDbgStr(inspect(
--        {(round(ask,2) / round(bid,2)) , (round(self:getSpeedMean(self:getSpeedTwoInterval()).bid + 1,2) / round(ask,2))}
--    ))
--    if self:isShort() then
--        if (round(ask, 2) / round(bid, 2)) > self:getRevMult() and self:checkAsk() then
--            return true
--        end
--    end
--    if self:isLong() then
--        if (round(bid, 2) / round(ask, 2)) > self:getRevMult() and self:checkBid() then
--            return true
--        end
--    end
--    return false
--end

function TradeCondition:checkRev()
    PrintDbgStr("Reward?")
    if self:isShort() then
        if self:checkAsk(self:getSpeedKoef(), true) then
            return true
        end
    end
    if self:isLong() then
        if self:checkBid(self:getSpeedKoef(), true) then
            return true
        end
    end
    return false
end

function TradeCondition:goRev()
    print("Go Rev!!!")
    self.rev = true
    if self:isShort() then
        self:closePosition(self:getCurrentBid().param_value)
        self:goBuy(self:getCurrentBid().param_value)
    end
    if self:isLong() then
        self:closePosition(self:getCurrentBid().param_value)
        self:goSell(self:getCurrentBid().param_value)
    end
    self.rev = false
end

function TradeCondition:getNeedProfit()
    if self:getPositionPrice() == nil then
        return nil
    end
    local need = self:round(tonumber(self:getPositionPrice()) / 100, 2) * self.needProfit
    return need
end

function TradeCondition:getCurrentPrice()
    if self.bid ~=nil and self.bid.param_value ~= nil then
        return self.bid.param_value
    end
end


function TradeCondition:setPosition(position)
    self.position = position
end

function TradeCondition:getFees()
    if self.fees ~= nil then
        return self.fees
    else
        return 0.2
    end
end

function TradeCondition:setCandleIndex(index)
    self.candleIndex = index
end

function TradeCondition:getCandleIndex()
    return self.candleIndex
end

function TradeCondition:getDebug(dbg)
    PrintDbgStr(inspect(
      self
    ))
    if dbg ~= nil then
        PrintDbgStr(inspect(
            dbg
        ))
    end
end

function TradeCondition:getPosition()
    return self.position
end

function TradeCondition:stats_mean( t )
    local sum = 0
    local count= 0

    for k,v in pairs(t) do
        if type(v) == 'number' then
            sum = sum + v
            count = count + 1
        end
    end

    return (sum / count)
end

function TradeCondition:stats_search(items, val)
    for key,v in pairs(items) do
        if v == val then
            return key - 1
        end
    end
    return false
end

function TradeCondition:stats_standardDeviation( t )
    local m
    local vm
    local sum = 0
    local count = 0
    local result

    m = self:stats_mean( t )

    for k,v in pairs(t) do
        if type(v) == 'number' then
            vm = v - m
            sum = sum + (vm * vm)
            count = count + 1
        end
    end
    result = math.sqrt(sum / (count-1))

    return result
end

function TradeCondition:tableMean(t)
    local mean = self:stats_mean( t )

    local tbl = {}
    for k,v in pairs(t) do
        if type(v) == 'number' then
            v = v - mean
            table.insert( tbl, round(v , 2) )
        end
    end
    return tbl
end

function TradeCondition:tableMean2(t)
    local mean = self:stats_standardDeviation( t )
    local tbl = {}
    for k,v in pairs(t) do
        if type(v) == 'number' then
            local t = v / mean
            v = t > 0 and math.floor(t) or math.ceil(t)
            table.insert( tbl, round(v , 2) )
        end
    end
    return tbl
end

function TradeCondition:meanFactory(length)
    local list = self:getBids()
    local temp={bid = {}, ask = {}, vol = {} }
    local mean = {bid = 0, ask = 0, vol = 0}
    local now=os.time()
    local speed = {bid = 0, ask = 0, vol = 0 }

    for i=0,(length-1) do
        local date = os.date("%Y%m%d%H%M%S",now-i)
        if list[date] == nil then
            list[date] = {bids = 0, asks = 0, vol = 0 }
        end
        table.insert( temp.bid, list[date].bids )
        table.insert( temp.ask, list[date].asks )
        table.insert( temp.vol, list[date].vol )
    end

    table.sort( temp.bid )
    table.sort( temp.ask )
    table.sort( temp.vol )
    return temp
end

function TradeCondition:getSpeedMean(length)
    local temp = self:meanFactory(length)
    local mean = {bid = 0, ask = 0, vol = 0}
--    now=os.time()
--    local speed = {bid = 0, ask = 0, vol = 0 }

--    PrintDbgStr(inspect(
--        math.fmod(#temp.bid,2)
--    ))

    if math.fmod(#temp.bid,2) == 0 then
        mean.bid = ( temp.bid[#temp.bid/2] + temp.bid[(#temp.bid/2)+1] ) / 2
        mean.ask = ( temp.ask[#temp.ask/2] + temp.ask[(#temp.ask/2)+1] ) / 2
        mean.vol = ( temp.vol[#temp.vol/2] + temp.vol[(#temp.vol/2)+1] ) / 2
        return mean
    else
        -- return middle element
        mean.bid = temp.bid[math.ceil(#temp.bid/2)]
        mean.ask = temp.ask[math.ceil(#temp.ask/2)]
        mean.vol = temp.vol[math.ceil(#temp.vol/2)]
        return mean
    end
    --  PrintDbgStr(inspect(
    --    speed
    --  ))
    return mean
end

function TradeCondition:tableSlice(tbl, first, last, step)
--    PrintDbgStr(inspect(
--        {
--            first,
--            last,
--            step
--        }
--    ))
    local sliced = {bid = {}, ask = {}, vol = {}}

    for i = first or 1, last or #tbl.ask, step or 1 do
        sliced.bid[#sliced.bid+1] = tbl.bid[i]
        sliced.ask[#sliced.ask+1] = tbl.ask[i]
        sliced.vol[#sliced.vol+1] = tbl.vol[i]
    end

    return sliced
end

function TradeCondition:tableSliceSimple(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
        sliced[#sliced+1] = tbl[i]
    end

    return sliced
end

function TradeCondition:getMedian(t, length)
    local temp = self:tableSlice(t, #t.ask-length > 0 and #t.ask-length or 1, #t.ask)

    table.sort( temp.bid )
    table.sort( temp.ask )
    table.sort( temp.vol )

    local mean = {bid = 0, ask = 0, vol = 0}
    --    now=os.time()
    --    local speed = {bid = 0, ask = 0, vol = 0 }

--    PrintDbgStr(inspect(
--        temp
--    ))

    if math.fmod(#temp.bid,2) == 0 then
        mean.bid = ( temp.bid[#temp.bid/2] + temp.bid[(#temp.bid/2)+1] ) / 2
        mean.ask = ( temp.ask[#temp.ask/2] + temp.ask[(#temp.ask/2)+1] ) / 2
        mean.vol = ( temp.vol[#temp.vol/2] + temp.vol[(#temp.vol/2)+1] ) / 2
        return mean
    else
        -- return middle element
        mean.bid = temp.bid[math.ceil(#temp.bid/2)]
        mean.ask = temp.ask[math.ceil(#temp.ask/2)]
        mean.vol = temp.vol[math.ceil(#temp.vol/2)]
        return mean
    end
    --  PrintDbgStr(inspect(
    --    speed
    --  ))
    return mean
end

function TradeCondition:getSortMedian(t, length)
    local temp = self:tableSliceSimple(t, #t-length > 0 and #t-length or 1, #t)

    table.sort( temp )
    return temp
end

function TradeCondition:removeZeros(t)
    local temp = {}

    for key,v in pairs(t) do
        if v ~= 0 then
            table.sinsert(temp,v)
        end
    end

    return temp
end

function TradeCondition:getMedianSimple(t, length, zeros)
    if zeros == nil then
        zeros = false
    end
    local temp = self:getSortMedian(t, length)
--    PrintDbgStr(inspect(
--        t
--    ))

    if zeros == true then
        temp = self:removeZeros(temp)
    end

    local mean = {}

    if math.fmod(#temp,2) == 0 then
        mean = ( temp[#temp/2] + temp[(#temp/2)+1] ) / 2
        return mean
    else
        mean = temp[math.ceil(#temp/2)]
        return mean
    end
    return mean

end

function TradeCondition:getMeanOfTable(t)
    local mean = 0
--    PrintDbgStr(inspect(
--        t
--    ))
    for k,v in pairs(t) do
        mean = mean + v
    end

    mean = mean / #t

    return mean
end

return TradeCondition