--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

local inspect = require('inspect')


local SEC_CODE = "";
local CLASS_CODE = "";
local DSInfo, Interval;
local Vol_Coeff = 1;
local bids_count = { bids = 0, asks = 0}
local startIndex, endIndex, currentDateCandle, currentIndex
--cache_VolBid={}
--cache_VolAsk={}

--InitComplete = true
--LastReadDeals = -1

Settings =
 {
   Name = "my_db",
   showVolume=0,
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
       Color = RGB(24, 139, 24),
       Color = RGB(255, 25, 25),
       Type = TYPE_HISTOGRAM,
       Width = 3
     }
   }
 }

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

function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

function fn(t)
  local currentDateCandlePlus = copy(currentDateCandle)
  currentDateCandlePlus.min = currentDateCandlePlus.min + Interval
--  if currentIndex > 3000 then
--    PrintDbgStr(inspect(
--      currentDateCandle
--    ))
--    PrintDbgStr("-------")
--    PrintDbgStr(inspect(
--      currentDateCandlePlus
--    ))
--    PrintDbgStr("-------")
--    PrintDbgStr(inspect(
--      t.datetime
--    ))
--    PrintDbgStr(
--      inspect(
--        dateCompare(t.datetime, currentDateCandle)
--      )
--              .. " " ..
--              inspect(
--                dateCompare(t.datetime, currentDateCandlePlus)
--              )
--    )
--  end
  if (t.sec_code == SEC_CODE) and t.class_code == CLASS_CODE and dateCompare(t.datetime, currentDateCandle) >=1 and dateCompare(t.datetime, currentDateCandlePlus) < 0 then
    if t.flags == 1 then
      bids_count.bids = bids_count.bids + t.qty
    elseif t.flags == 2 then
      bids_count.asks = bids_count.asks + t.qty
    end
    return true
  else
    return false
  end

end

function Init()
  ParamRequest("TQBR", "SBER", "all_trades");
  return 2
end

--function dateConvert(t)
--  return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min) .. string.format("%02d",t.sec) .. string.format("%03d",t.ms)
--end

function OnCalculate(index)
  if index == 1 then
    DSInfo = getDataSourceInfo()
    SEC_CODE = DSInfo.sec_code
    CLASS_CODE = DSInfo.class_code
    Interval = DSInfo.interval
    startIndex = 0
    currentIndex = index
  end

  if (currentIndex ~= index) then
    bids_count = { bids = 0, asks = 0 }
    currentIndex = index
  end

  currentDateCandle = T(index)

  endIndex = getNumberOf("all_trades")-1
--  endIndex = 100

  SearchItems ("all_trades", startIndex, endIndex, fn)

  PrintDbgStr(inspect(
    bids_count
  ))

--  PrintDbgStr(inspect(
--    T(index)
--  ))

  PrintDbgStr(startIndex .. " " .. endIndex .. " " .. getNumberOf("all_trades"))

  startIndex = endIndex

  return bids_count.asks, 0 - bids_count.bids
end