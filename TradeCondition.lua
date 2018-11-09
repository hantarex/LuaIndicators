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
        rev_mult = 20, -- delimiter speed for rev
        askSpeed = 0,
        isClose = 0,
        closeToMinus = false,
        badDeal = 0,
        bidSpeed =0,
        speedKoef = 7,
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

function TradeCondition:getRevMult()
    return self.rev_mult
end

function TradeCondition:getSpeedTwoInterval()
    return self.speed_two_interval
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

--    if self:isShort() then
    --        local delta = tonumber(self:getCurrentPrice()) - tonumber(self:getPositionPrice())
    --        local procent = round(tonumber(delta) / tonumber(self:getPositionPrice()), 2) * 100
    --        if procent > self:getStopOrder() then
    --            return true
    --        else
    --            return false
    --        end
    --    end
    --    if self:isLong() then
    --        local delta =  tonumber(self:getPositionPrice()) -  tonumber(self:getCurrentPrice())
    --        local procent = round(tonumber(delta) / tonumber(self:getPositionPrice()), 2) * 100
    --        if procent > self:getStopOrder() then
    --            return true
    --        else
    --            return false
    --        end
    --    end
    PrintDbgStr("Стоп? " .. (0 - self:getProfit()) .." ".. self:getStopOrder() .. " " .. self:getStopOrderAbs())

    if (0 - self:getProfit()) > self:getStopOrder() then
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
    if self:getColorCandle() ~= 1 and self:getPositionPrice() ~= nil then -- цена идёт вниз по свече
        PrintDbgStr("Цена идёт вниз по свече " .. (self:getNeedBestProfit() ~=nil and self:getNeedBestProfit() or "nil") .. "\n");
        if (self:getBidSpeed() * 1.5) < self:getAskSpeed() and self:getProfit() > self:getNeedBestProfit() then
            PrintDbgStr("Скорость взлёта больше падения! И достигнут бестпрофит!\n");
--        elseif self:checkIndex() and self:getProfit() > self:getNeedBestProfit() then
--            PrintDbgStr("Достигнут бестпрофит в индексе!\n");
        elseif self:checkIndex() and self:getIsClose() and self:getBidSpeed() < self:getAskSpeed() then
            PrintDbgStr("Закрытие в индексе!\n");
        else
            return false
        end
    end

    if self:getCloseToMinus() == true then
        self:setLastDealMark(false);
    else
        self:setLastDealMark(true);
    end

    PrintDbgStr("Проверка позиции!\n");
    if self:getPosition() == 0 and (self:getBidSpeed() * 1.5) < self:getAskSpeed() and self:checkPause() then
        PrintDbgStr("Без позиции!\n");
        self:setPositionPrice(price)
        self:setPosition(1)
        self:setSpeedTrade(self:getSpeedTrade() / self:getSpeedKoef())
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self.logfile:write(dateDeal..";Покупка;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .."\n");
    elseif self:getPosition() == -1 then
        PrintDbgStr("В позиции!\n");
        self:setSpeedTrade(self:getStartSpeedTrade() + self:getLastDealMark()*0.2*self:getStartSpeedTrade())
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self:updateTimePause()
        self.logfile:write(dateDeal..";Покупка;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .."\n");
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
    if self:getColorCandle() ~= -1 and self:getPositionPrice() ~= nil then -- цена идёт вверх по свече
        PrintDbgStr("Цена идёт вверх по свече " .. (self:getNeedBestProfit() ~=nil and self:getNeedBestProfit() or "nil") .. "\n");
        if self:getBidSpeed() > (self:getAskSpeed() * 1.5)
                and self:getProfit() > self:getNeedBestProfit() then
            PrintDbgStr("Скорость падения больше взлёта! И достигнут бестпрофит!\n");
--        elseif self:checkIndex() and self:getProfit() > self:getNeedBestProfit() then
--            PrintDbgStr("Достигнут бестпрофит в индексе!\n");
        elseif self:checkIndex() and self:getIsClose() and self:getBidSpeed() > self:getAskSpeed() then
            PrintDbgStr("Закрытие в индексе!\n");
        else
            return false
        end
    end
    if self:getPosition() == 0 and self:getBidSpeed() > (self:getAskSpeed() * 1.5) and self:checkPause() then
        self:setPositionPrice(price)
        self:setPosition(-1)
        self:setSpeedTrade(self:getSpeedTrade() / self:getSpeedKoef())
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self.logfile:write(dateDeal..";Продажа;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .."\n");

    elseif self:getPosition() == 1 then
        self:setSpeedTrade(self:getStartSpeedTrade() + self:getLastDealMark()*0.2*self:getStartSpeedTrade())
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self:updateTimePause()
        self.logfile:write(dateDeal..";Продажа;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. ";" .. self:getProfitAbs().. ";".. inspect(self:getSpeedMean(self:getSpeedInterval())) .. ";" .. inspect(self:getSpeedMean(self:getSpeedTwoInterval())) .."\n");
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

function TradeCondition:checkBid()
    if round(self:getSpeedMean(self:getSpeedInterval()).bid,2) > self:getSpeedTrade() and
            round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) > (self:getSpeedTrade() / 2) and
            round(self:getSpeedMean(self:getSpeedInterval()).bid,2) > round(self:getSpeedMean(self:getSpeedInterval()).ask,2) and
            round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) > round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) then
        return true
    end
    return false
end

function TradeCondition:checkAsk()
    if round(self:getSpeedMean(self:getSpeedInterval()).ask,2) > self:getSpeedTrade() and
            round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) > (self:getSpeedTrade() / 2) and
            round(self:getSpeedMean(self:getSpeedInterval()).ask,2) > round(self:getSpeedMean(self:getSpeedInterval()).bid,2) and
            round(self:getSpeedMean(self:getSpeedTwoInterval()).ask,2) > round(self:getSpeedMean(self:getSpeedTwoInterval()).bid,2) then
        return true
    end
    return false
end

function TradeCondition:checkRev()
    local ask = self:getSpeedMean(self:getSpeedTwoInterval()).ask < 2 and 2 or self:getSpeedMean(self:getSpeedTwoInterval()).ask
    local bid = self:getSpeedMean(self:getSpeedTwoInterval()).bid < 2 and 2 or self:getSpeedMean(self:getSpeedTwoInterval()).bid
    PrintDbgStr("Reward?")
    PrintDbgStr(inspect(
        {(round(ask,2) / round(bid,2)) , (round(self:getSpeedMean(self:getSpeedTwoInterval()).bid + 1,2) / round(ask,2))}
    ))
    if self:isShort() then
        if (round(ask, 2) / round(bid, 2)) > self:getRevMult() and self:checkAsk() then
            return true
        end
    end
    if self:isLong() then
        if (round(bid, 2) / round(ask, 2)) > self:getRevMult() and self:checkBid() then
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



return TradeCondition