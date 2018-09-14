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

function TradeCondition:create(fees, needProfit, stopOrder, speed, isTraiding)
    local init = {
        positionPrice = nil,
        DSInfo = nil,
        position = 0,
        transactionPrefix = os.time(os.date("!*t")),
        transactionPostfix = 1,
        isTraiding = false,
        logfile = nil
    }
    init.transactionMarket = {
        ["TRANS_ID"]   = tostring(init.transactionPostfix),
        ["ACTION"]     = "NEW_ORDER",
--        ["OPERATION"]  = "S", -- покупка (BUY)
        ["TYPE"]       = "M", -- по рынку (MARKET)
        ["QUANTITY"]   = "10", -- количество
        ["ACCOUNT"]    = "L01-00000F00",
        ["CLIENT_CODE"]    = "108191/001",
        ["PRICE"]      = "0"
    }
    if fees ~= nil then
        init.fees = fees
    end

    if isTraiding ~= nil then
        if isTraiding == 1 then
            init.isTraiding = true
        else
            init.isTraiding = false
        end
    end

    if needProfit ~= nil then
        init.needProfit = needProfit
    end

    if stopOrder ~= nil then
        init.stopOrder = stopOrder
    end

    if speed ~= nil then
        init.speed = speed
        init.startSpeed = speed
    else
        init.speed = 2000
        init.startSpeed = init.speed
    end


    return setmetatable(init, { __index = TradeCondition })
end

function TradeCondition:getSpeedTrade()
    return self.speed
end

function TradeCondition:iterateTransaction()
    self.transactionMarket["TRANS_ID"] = tostring(self.transactionMarket["TRANS_ID"] + 1)
end

function TradeCondition:getDSInfo()
    return self.DSInfo
end

function TradeCondition:getIsTraiding()
    return self.isTraiding
end

function TradeCondition:setDSInfo(ds)
    self.DSInfo = ds
    self.transactionMarket.CLASSCODE = self:getDSInfo().class_code
    self.transactionMarket.SECCODE = self:getDSInfo().sec_code
    self.logfile = io.open(getScriptPath() .. "/deal_".. self.transactionMarket.SECCODE .."_"..os.date("%d%m%Y")..".txt", "w")
end

function TradeCondition:getStartSpeedTrade()
    return self.startSpeed
end

function TradeCondition:setSpeedTrade(speed)
    self.speed = speed
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

function TradeCondition:getColorCandle()
    if O(self:getCandleIndex()) > C(self:getCandleIndex()) then
        return -1
    else
        return 1
    end
end

function TradeCondition:setTrandSpeed(trand)
    self.trandSpeed = trand
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

function TradeCondition:closePosition(price)
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    PrintDbgStr("Закрытие позиции!")
--    self:getDebug(self:getProfit())
    if self:getProfit() < self:getNeedProfit() then
        self.logfile:write(dateDeal..";Закрытие в минус\n");
    end
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    if self:isShort() then
        self:goBuy(price)
    elseif self:isLong() then
        self:goSell(price)
    end
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
    PrintDbgStr("Стоп? " .. (0 - self:getProfit()) .." ".. self:getStopOrder())

    if (0 - self:getProfit()) > self:getStopOrder() then
        return true
    else
        return false
    end
end

function TradeCondition:goBuy(price)
    PrintDbgStr("Покупка!")
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    if self:getColorCandle() ~= 1 then -- цена идёт вниз по свече
        PrintDbgStr("Цена идёт вниз по свече\n");
--        self.logfile:flush()
        return false
    end
    if self:getPosition() == 0 then
        self:setPositionPrice(price)
        self:setPosition(1)
        self:setSpeedTrade(self:getSpeedTrade() / 3)
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self.logfile:write(dateDeal..";Покупка;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
    elseif self:getPosition() == -1 then
        self:setPosition(0)
        self:setSpeedTrade(self:getStartSpeedTrade())
        if self:getIsTraiding() then
            self:transactionBuy()
        end
        self.logfile:write(dateDeal..";Покупка;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
        self:setPositionPrice(nil)
    end
    self.logfile:flush()
    return false
end

function TradeCondition:transactionSell()
    self.transactionMarket["OPERATION"]  = "S"
    local res = sendTransaction(self.transactionMarket)
--    PrintDbgStr(inspect(
--        self.transactionMarket
--    ))
    self:iterateTransaction()
    if res ~= "" then
        message("Транзакция %s не прошла проверку на стороне терминала QUIK")
    else
        message("Транзакция отправлена")
    end
end

function TradeCondition:transactionBuy()
    self.transactionMarket["OPERATION"]  = "B"
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
    if(self:getColorCandle() ~= -1) then -- цена идёт вверх по свече
        PrintDbgStr("Цена идёт вверх по свече\n");
--        self.logfile:flush()
        return false
    end
    if self:getPosition() == 0 then
        self:setPositionPrice(price)
        self:setPosition(-1)
        self:setSpeedTrade(self:getSpeedTrade() / 3)
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self.logfile:write(dateDeal..";Продажа;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");

    elseif self:getPosition() == 1 then
        self:setPosition(0)
        self:setSpeedTrade(self:getStartSpeedTrade())
        if self:getIsTraiding() then
            self:transactionSell()
        end
        self.logfile:write(dateDeal..";Продажа;" .. (self:getCurrentPrice() ~= nil and self:getCurrentPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
        self:setPositionPrice(nil)
    end
    self.logfile:flush()
    return false
end

function TradeCondition:setCurrentBid(bid)
    self.bid = bid
end

function TradeCondition:getNeedProfit()
    if self:getPositionPrice() == nil then
        return nil
    end
    local need = self.round(tonumber(self:getPositionPrice()) / 100, 2) * self.needProfit
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

return TradeCondition