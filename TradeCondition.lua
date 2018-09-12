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

function TradeCondition:create(fees, needProfit, stopOrder)
    local init = {
        positionPrice = nil,
        position = 0
    }
    if fees ~= nil then
        init.fees = fees
    end
    if needProfit ~= nil then
        init.needProfit = needProfit
    end

    if stopOrder ~= nil then
        init.stopOrder = stopOrder
    end
    init.logfile = io.open(getScriptPath() .. "/deal_"..os.date("%d%m%Y").."_new.txt", "w")
    return setmetatable(init, { __index = TradeCondition })
end

function TradeCondition:isLong()
    if self.position == 1 and self.positionPrice ~= nil then
        return true
    end
    return false
end

function TradeCondition:getStopOrder()
    return self.stopOrder
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
    PrintDbgStr("�������� �������!")
    if self:getProfit() < myTrade:getNeedProfit() then
        self.logfile:write(dateDeal..";�������� � �����\n");
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

    if self:isShort() then
        local delta = tonumber(self:getCurrentPrice()) - tonumber(self:getPositionPrice())
        local procent = round(tonumber(delta) / tonumber(self:getPositionPrice()), 2) * 100
        if procent > self:getStopOrder() then
            return true
        else
            return false
        end
    end
    if self:isLong() then
        local delta =  tonumber(self:getPositionPrice()) -  tonumber(self:getCurrentPrice())
        local procent = round(tonumber(delta) / tonumber(self:getPositionPrice()), 2) * 100
        if procent > self:getStopOrder() then
            return true
        else
            return false
        end
    end
end

function TradeCondition:goBuy(price)
    PrintDbgStr("�������!")
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    if self:getColorCandle() ~= 1 then -- ���� ��� ���� �� �����
        self.logfile:write(dateDeal..";�������;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";0;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
        self.logfile:flush()
        return false
    end
    if self:getPosition() == 0 then
        self:setPositionPrice(price)
        self:setPosition(1)
    elseif self:getPosition() == -1 then
        self:setPositionPrice(nil)
        self:setPosition(0)
    end
    self.logfile:write(dateDeal..";�������;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
    self.logfile:flush()
    return false
end

function TradeCondition:goSell(price)
    PrintDbgStr("�������!")
    local dateDeal = os.date("%d.%m.%Y %H:%M:%S");
    if(self:getColorCandle() ~= -1) then -- ���� ��� ����� �� �����
        self.logfile:write(dateDeal..";�������;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";0;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
        self.logfile:flush()
        return false
    end
    if self:getPosition() == 0 then
        self:setPositionPrice(price)
        self:setPosition(-1)
    elseif self:getPosition() == 1 then
        self:setPositionPrice(nil)
        self:setPosition(0)
    end
    self.logfile:write(dateDeal..";�������;" .. (self:getPositionPrice() ~= nil and self:getPositionPrice() or "nil") .. ";1;" .. (self:getPosition() ~= nil and self:getPosition() or "nil") .. "\n");
    self.logfile:flush()
    return false
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

function TradeCondition:getDebug()
    PrintDbgStr(inspect(
      self
    ))
end

function TradeCondition:getPosition()
    return self.position
end

return TradeCondition