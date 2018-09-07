--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

local inspect = require('inspect')
local logfile, logCandle, logDate, logDeal
local newCangde = false

local SEC_CODE = "";
local CLASS_CODE = "";
local DSInfo, Interval;
local Vol_Coeff = 1;
local bids_count = {}
local bids_count_speed = {}
local listTradeNum = {}
local curTrade = 0
local startIndex, endIndex, currentDateCandle, currentIndex, labelBid, labelAsk, now, speed
local speed_interval = 10
local label_params ={}
local label_Candle ={}
local char_tag = "d"
local myPosition = {position = 0, price = nil}

local dateNow = {
  day = 4,
  hour = 17,
  min = 30,
  month = 9,
  week_day = 2,
  year = 2018
}

local debugCompare
--cache_VolBid={}
--cache_VolAsk={}

--InitComplete = true
--LastReadDeals = -1

Settings =
 {
   Name = "my_db2",
   label = "TEST",
   chart_tag = "TEST",
   showVolume=1,
   inverse = 0,
   CountQuntOfDeals = 0,
   sum_quantity=1,
   showdelta=1,
   delta_koeff = 0.1,
   dealFilter = "",
   line =
   {
     {
       Name = "Asks",
       Color = RGB(24, 139, 24),
       Type = TYPE_HISTOGRAM,
       Width = 3
     },
     {
       Name = "Bids",
       Color = RGB(255, 25, 25),
       Type = TYPE_HISTOGRAM,
       Width = 3
     },
--     {
--       Name = "Vol",
--       Color = RGB(116, 119, 155),
--       Type = TYPE_HISTOGRAM,
--       Width = 3
--     }
   }
 }

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function WriteLog(logfile, text)
  logfile:write(text.."\n");
  logfile:flush();
end;

function OnDestroy()
  logfile:close() -- Закрывает файл
  logCandle:close() -- Закрывает файл
  WriteLog(logDate, inspect(
    bids_count
  ))
  logDate:close() -- Закрывает файл
end

function dateCompare(d1, d2)

  if (d1.year == d2.year)
    and (d1.month == d2.month)
    and (d1.day == d2.day)
    and (d1.hour == d2.hour)
    and (d1.min == d2.min)
    and (d1.sec == d2.sec)
    and (d1.ms == d2.ms) then
    return 0
  end

  if d1.year > d2.year then
    return 1
  elseif d1.year == d2.year and d1.month > d2.month then
    return 1
  elseif d1.month == d2.month and d1.day > d2.day then
    return 1
  elseif d1.day == d2.day and d1.hour > d2.hour then
    return 1
  elseif d1.hour == d2.hour and d1.min > d2. min then
    return 1
  elseif d1.min == d2.min and d1.sec > d2.sec then
    return 1
  elseif d1.sec == d2.sec and d1.ms > d2.ms then
    return 1
  end

  return -1
end

function getSpeedByDate(dateD)
  now=os.time(dateD)
  local speed = {bid = 0, ask = 0, vol = 0 }
  local speedMax = {bid = 0, ask = 0, vol = 0 }
  for i=now, (now+Interval*60) do
    speed = {bid = 0, ask = 0, vol = 0 }
    for b=0,(speed_interval-1) do
      local date = os.date("%Y%m%d%H%M%S",i-b)
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

    if(speed.bid > speedMax.bid) then speedMax.bid = speed.bid end
    if(speed.ask > speedMax.ask) then speedMax.ask = speed.ask end
    if(speed.vol > speedMax.vol) then speedMax.vol = speed.vol end
  end
  --  PrintDbgStr(inspect(
  --    speed
  --  ))
  return speedMax
end

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

function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

function serial(t)
  return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min)
end

function serialDate(t)
  return string.format("%04d",t.year) .. ".".. string.format("%02d",t.month) .. ".".. string.format("%02d",t.day) .. " ".. string.format("%02d",t.hour) .. ":".. string.format("%02d",t.min) .. ":".. string.format("%02d",t.sec)
end

function serialSec(t)
  return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min).. string.format("%02d",t.sec)
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

function WriteLogDeal(logfile, deal)
  local t = getParamEx(CLASS_CODE, SEC_CODE, "last")

  PrintDbgStr(inspect(
    {
      deal = deal,
      position = myPosition.position,
      price = t.param_image,
      free_position = myPosition.position == 0
    }
  ))

  if deal == 1 then
    if myPosition.position ~= 1 and myPosition.price > t.param_value then
      logfile:write("Покупка;" .. t.param_image .. ";1;0\n");
      myPosition.position = 0
      myPosition.price = nil
    elseif myPosition.position == 0 then
      logfile:write("Покупка;" .. t.param_image .. ";1;1\n");
      myPosition.position = 1
      myPosition.price = t.param_value
    end
  else -- продавать
    if myPosition.position ~= -1 and myPosition.price < t.param_value then
      logfile:write("Продажа;" .. t.param_image .. ";1;0\n");
      myPosition.position = 0
      myPosition.price = nil
    elseif myPosition.position == 0 then
      PrintDbgStr("ok")
      logfile:write("Продажа;" .. t.param_image .. ";1;-1\n");
      myPosition.position = -1
      myPosition.price = t.param_value
    end
  end
  logfile:flush();
end;

function fn(t)
  if t.sec_code == SEC_CODE and t.class_code == CLASS_CODE and listTradeNum[t.trade_num] == nil then
    local dateIndex = serial(getDateIndex(t.datetime))
    local dateIndexSpeed = serialSec(t.datetime)
--    if debugCompare > 0 then
--      PrintDbgStr("hope")
--      PrintDbgStr(inspect(
--        dateIndex
--      ))
--    end
    if bids_count[dateIndex] == nil then
      bids_count[dateIndex] = { bids = 0, asks = 0, vol = 0}
    end

    if bids_count_speed[dateIndexSpeed] == nil then
      bids_count_speed[dateIndexSpeed] = { bids = 0, asks = 0, vol = 0}
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

--    if debugCompare > 0 then
--      PrintDbgStr(inspect(
--        bids_count[dateIndex]
--      ))
--    end
    listTradeNum[t.trade_num] = true
    speed = getSpeed()
    WriteLog(logfile, t.trade_num..";"..t.flags..";" ..t.price..";" ..t.qty..";" ..t.value..";" ..t.accruedint..";" ..t.yield..";" ..t.settlecode..";" ..t.reporate..";" ..t.repovalue..";" ..t.repo2value..";" ..t.repoterm..";" ..t.sec_code..";" ..t.class_code..";" ..dateIndex..";" ..t.period..";" ..t.open_interest..";" ..t.exchange_code..";" ..t.exec_market..";")
    return true
  else
    return false
  end

end


function Init()
  logfile=io.open(getScriptPath() .. "/bid_"..os.date("%d%m%Y")..".txt", "w")
  logCandle=io.open(getScriptPath() .. "/candle_"..os.date("%d%m%Y")..".txt", "w")
  logDate=io.open(getScriptPath() .. "/dateIndex_"..os.date("%d%m%Y")..".txt", "w")
  logDeal=io.open(getScriptPath() .. "/deal_"..os.date("%d%m%Y")..".txt", "w")

  label_params.IMAGE_PATH=""
  label_params.ALIGNMENT="TOP"
  label_params.TRANSPARENCY=50
  label_params.TRANSPARENT_BACKGROUND=100
  label_params.HINT=""
  label_params.R=0
  label_params.G=0
  label_params.B=0
  label_params.FONT_FACE_NAME="Arial"
  label_params.FONT_HEIGHT='8'
  label_params.DATE = os.date("%Y%m%d")
  label_params.TIME = os.date("%H%M%S")
  label_params.YVALUE = 0
  label_params.TEXT = "init"
--  ParamRequest("TQBR", "SBER", "all_trades");
  return 2
end

--function dateConvert(t)
--  return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min) .. string.format("%02d",t.sec) .. string.format("%03d",t.ms)
--end

function getMax(table)
  local high = 0
  for i,v in pairs(table) do
    if(v > high) then
      high = v
    end
  end
  return high
end

function OnCalculate(index)
  if currentIndex ~= index then
    newCangde = true
  end
--  debugCompare = dateCompare(T(index), dateNow)
  WriteLog(logCandle, index..";"
          ..O(index)..";"
          ..H(index)..";"
          ..L(index)..";"
          ..L(index)..";"
          ..C(index)..";"
          ..V(index)..";"
          ..serialDate(T(index))..";"
  )

  if index == 1 then
    DSInfo = getDataSourceInfo()
    SEC_CODE = DSInfo.sec_code
    CLASS_CODE = DSInfo.class_code
    Interval = DSInfo.interval
    startIndex = 0
    currentIndex = index
    if labelBid == nil then
      label_params.DATE = os.date("%Y%m%d")
      label_params.TIME = os.date("%H%M%S")
      label_params.YVALUE = 0
      label_params.TEXT = "init"
      label_params.ALIGNMENT="TOP"
      label_params.R=116
      label_params.G=185
      label_params.B=116
      labelBid = AddLabel(char_tag, label_params)
    end
    if labelAsk == nil then
      label_params.DATE = os.date("%Y%m%d")
      label_params.TIME = os.date("%H%M%S")
      label_params.YVALUE = 0
      label_params.TEXT = "init"
      label_params.ALIGNMENT="BOTTOM"
      label_params.R=255
      label_params.G=0
      label_params.B=0
      labelAsk = AddLabel(char_tag, label_params)
    end
  end

  if (currentIndex ~= index) then
    currentIndex = index
  end

  currentDateCandle = T(index)

  endIndex = getNumberOf("all_trades")-1

  SearchItems ("all_trades", startIndex, endIndex, fn)


--  PrintDbgStr(startIndex .. " " .. endIndex .. " " .. getNumberOf("all_trades"))

  startIndex = endIndex

  local indexTime = serial(getDateIndex(T(index)))

--  if debugCompare > 0 then
--    PrintDbgStr("yes")
--    PrintDbgStr(inspect(
--      indexTime
--    ))
--    PrintDbgStr(inspect(
--      bids_count[indexTime]
--    ))
--  end

  if bids_count[indexTime] == nil then
    bids_count[indexTime] = { bids = 0, asks = 0, vol = 0}
  end


--    if debugCompare > 0 then
--  PrintDbgStr(inspect(
--    Size()
--  ))
--    end

  if(label_Candle[index] == nil) then
    label_Candle[index] = {ask = 0, bid=0}
  end

--  return bids_count[indexTime].asks, 0 - bids_count[indexTime].bids, bids_count[indexTime].vol
  askSpeed = round(speed.ask,2)
  label_params.DATE = os.date("%Y%m%d")
  label_params.TIME = os.date("%H%M%S")
  label_params.YVALUE = bids_count[indexTime].asks
  label_params.TEXT = tostring(askSpeed) .. " t/s"
  label_params.ALIGNMENT="TOP"
  label_params.R=116
  label_params.G=185
  label_params.B=116
  SetLabelParams(char_tag, labelAsk, label_params)

  bidSpeed = round(speed.bid,2)
  label_params.YVALUE = 0 - bids_count[indexTime].bids
  label_params.TEXT = tostring(bidSpeed) .. " t/s"
  label_params.ALIGNMENT="BOTTOM"
  label_params.R=255
  label_params.G=0
  label_params.B=0
  SetLabelParams(char_tag, labelBid, label_params)

  label_Candle[index].bid = bids_count[indexTime].bids
  label_Candle[index].ask = bids_count[indexTime].asks

--  1 - ask
--  -1 - bid
  if bidSpeed > 10 and currentIndex == Size() then WriteLogDeal(logDeal,-1) end
  if askSpeed > 10 and currentIndex == Size() then WriteLogDeal(logDeal,1) end

  if newCangde and label_Candle[index-1] ~= nil and currentIndex < Size() and currentIndex > (Size() - 20) then
    speedByDate = getSpeedByDate(T(index-1))
    label_params.YVALUE = 0 - label_Candle[index-1].bid
    label_params.TEXT = tostring(speedByDate.bid)
    label_params.ALIGNMENT="BOTTOM"
    label_params.R=255
    label_params.DATE = string.format("%04d",T(index-1).year) .. string.format("%02d",T(index-1).month) .. string.format("%02d",T(index-1).day)
    label_params.TIME = string.format("%02d",T(index-1).hour) .. string.format("%02d",T(index-1).min) .. string.format("%02d",T(index-1).sec)
    label_params.G=0
    label_params.B=0
    AddLabel(char_tag, label_params)

    label_params.YVALUE = label_Candle[index-1].ask
    label_params.TEXT = tostring(speedByDate.ask)
    label_params.ALIGNMENT="TOP"
    label_params.R=116
    label_params.G=185
    label_params.B=116
    AddLabel(char_tag, label_params)
  end

  return bids_count[indexTime].asks, 0 - bids_count[indexTime].bids
end
