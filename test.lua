TradeCondition = require('TradeCondition')

local inspect = require('inspect')



position = {
    position = 0,
    price = 12
}

--print(10,000)
--
--now=os.time()
--print(now)
tableDate =os.time(os.date("!*t"))
print(inspect(
    tableDate
))

print(math.floor(12.213123))
--
--function T()
--    print "T"
--end
--
--print(os.time(tableDate))
--
--print(os.date("%c",now-1))
--
--print(math.floor(10.333, 2))
--for i=1,10 do print(i) end
--
--function TradeCondition:T()
--    T()
--end
--myTrade = TradeCondition(12)

--myTrade:setPosition(1)
--
--print(inspect(myTrade))