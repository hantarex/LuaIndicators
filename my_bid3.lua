--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

local inspect = require('inspect')
local logfile, logCandle, logDate


local SEC_CODE = "";
local CLASS_CODE = "";
local DSInfo, Interval;
local Vol_Coeff = 1;
local bids_count = {}
local listTradeNum = {}
local curTrade = 0
local startIndex, endIndex, currentDateCandle, currentIndex, labelBid, labelAsk
local label_params ={}
local char_tag = "delta"

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
   Name = "my_db3",
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

function serialSec(t)
  return string.format("%04d",t.year) .. string.format("%02d",t.month) .. string.format("%02d",t.day) .. string.format("%02d",t.hour) .. string.format("%02d",t.min).. string.format("%02d",t.sec)
end

function serialDate(t)
  return string.format("%04d",t.year) .. ".".. string.format("%02d",t.month) .. ".".. string.format("%02d",t.day) .. " ".. string.format("%02d",t.hour) .. ":".. string.format("%02d",t.min) .. ":".. string.format("%02d",t.sec)
end

function getDateIndex(t, interval)
  local newDate = copy(t)
  local minIndex = math.floor(newDate.min / interval) * interval
  newDate.min = minIndex
  newDate.sec = nil
  newDate.ms = nil
  newDate.mcs = nil
  return newDate
end

function getDateIndexSec(t, interval)
  local newDate = copy(t)
  local minIndex = math.floor(newDate.sec / interval) * interval
  newDate.sec = minIndex
  newDate.ms = nil
  newDate.mcs = nil
  return newDate
end

function fn(t)
  if t.sec_code == SEC_CODE and t.class_code == CLASS_CODE and listTradeNum[t.trade_num] == nil then
    local dateIndex = serial(getDateIndex(t.datetime, Interval))
    local dateIndexSpeed = serialSec(getDateIndexSec(t.datetime, 2))
--    if debugCompare > 0 then
--      PrintDbgStr("hope")
--      PrintDbgStr(inspect(
--        dateIndex
--      ))
--    end
    if bids_count[dateIndex] == nil then
      bids_count[dateIndex] = { bids = 0, asks = 0, vol = 0}
    end

    if bids_count[dateIndexSpeed] == nil then
      bids_count[dateIndexSpeed] = { bids = 0, asks = 0, vol = 0}
    end

    if t.flags == 1 then
      bids_count[dateIndex].bids = bids_count[dateIndex].bids + t.qty
      bids_count[dateIndexSpeed].bids = bids_count[dateIndexSpeed].bids + t.qty
    elseif t.flags == 2 then
      bids_count[dateIndex].asks = bids_count[dateIndex].asks + t.qty
      bids_count[dateIndexSpeed].asks = bids_count[dateIndexSpeed].asks + t.qty
    end

    bids_count[dateIndex].vol = bids_count[dateIndex].vol + t.qty
    bids_count[dateIndexSpeed].vol = bids_count[dateIndexSpeed].vol + t.qty

--    if debugCompare > 0 then
--      PrintDbgStr(inspect(
--        bids_count[dateIndex]
--      ))
--    end
    listTradeNum[t.trade_num] = true
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

  label_params.IMAGE_PATH=""
  label_params.ALIGNMENT="TOP"
  label_params.TRANSPARENCY=50
  label_params.TRANSPARENT_BACKGROUND=100
  label_params.HINT=""
  label_params.R=0
  label_params.G=0
  label_params.B=0
  label_params.FONT_FACE_NAME="Arial"
  label_params.FONT_HEIGHT='10'
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

function OnCalculate(index)
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

  local indexTime = serial(getDateIndex(T(index), Interval))

  local dateIndexSpeed = os.date("%Y%m%d%H%M") .. math.floor(os.date("%S") / 2) * 2

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

  if bids_count[dateIndexSpeed] == nil then
    bids_count[dateIndexSpeed] = { bids = 0, asks = 0, vol = 0}
  end

--    if debugCompare > 0 then
--      PrintDbgStr(inspect(
--        bids_count[indexTime]
--      ))
--    end
--  return bids_count[indexTime].asks, 0 - bids_count[indexTime].bids, bids_count[indexTime].vol
  label_params.DATE = os.date("%Y%m%d")
  label_params.TIME = os.date("%H%M%S")
  label_params.YVALUE = bids_count[indexTime].asks
  label_params.TEXT = tostring(bids_count[dateIndexSpeed].asks / 2)
  label_params.ALIGNMENT="TOP"
  label_params.R=116
  label_params.G=185
  label_params.B=116
  SetLabelParams(char_tag, labelAsk, label_params)

  label_params.YVALUE = 0 - bids_count[indexTime].bids
  label_params.TEXT = tostring(bids_count[dateIndexSpeed] / 2)
  label_params.ALIGNMENT="BOTTOM"
  label_params.R=255
  label_params.G=0
  label_params.B=0
  SetLabelParams(char_tag, labelBid, label_params)

  return bids_count[indexTime].asks, 0 - bids_count[indexTime].bids
end