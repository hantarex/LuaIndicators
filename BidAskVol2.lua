--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

SEC_CODE = "";
CLASS_CODE = ""; 
DSInfo = nil;
Vol_Coeff = 1;
--cache_VolBid={}
--cache_VolAsk={}

--InitComplete = true
--LastReadDeals = -1

Settings =
 {
   Name = "*vol2",
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
       Name = "Sell",
       Color = RGB(255, 128, 128),
       Type = TYPE_HISTOGRAM,
       Width = 3
     },
     {
       Name = "Buy",
       Color = RGB(120, 220, 135),
       Type = TYPE_HISTOGRAM,
       Width = 3
     },
     {
       Name = "DLocal",
       Color = RGB (255, 0, 0),
       Type = TYPE_LINE,
       Width = 2
     },
     {
       Name = "Delta",
       Color = RGB(0, 0, 0),
       Type = TYPE_LINE,
       Width = 1
     },
     {
       Name = "Volume",
       Color = RGB(0, 128, 255),
       Type = TYPE_HISTOGRAM,
       Width = 3
     }
   }
 }

-- Пользовательcкие функции
function WriteLog(text)
   logfile:write(tostring(os.date("%c",os.time())).." "..text.."\n");
   logfile:flush();
   LASTLOGSTRING = text;
end;

function OnDestroy()
  --logfile:close() -- Закрывает файл 
end

function toYYYYMMDDHHMMSS(datetime)
   if type(datetime) ~= "table" then
      --message("в функции toYYYYMMDDHHMMSS неверно задан параметр: datetime="..tostring(datetime))
      return ""
   else
      local Res = tostring(datetime.year)
      if #Res == 1 then Res = "000"..Res end
      local month = tostring(datetime.month)
      if #month == 1 then Res = Res.."0"..month; else Res = Res..month; end
      local day = tostring(datetime.day)
      if #day == 1 then Res = Res.."0"..day; else Res = Res..day; end
      local hour = tostring(datetime.hour)
      if #hour == 1 then Res = Res.."0"..hour; else Res = Res..hour; end
      local minute = tostring(datetime.min)
      if #minute == 1 then Res = Res.."0"..minute; else Res = Res..minute; end
      local sec = tostring(datetime.sec);
      if #sec == 1 then Res = Res.."0"..sec; else Res = Res..sec; end;
      return Res
   end
end --toYYYYMMDDHHMMSS

function isnil(a,b)
   if a == nil then
      return b
   else
      return a
   end;
end;
-- -----------------------------------------------------------------------------

 function Init()
  myVol = Vol()
  return #Settings.line
 end

-- SelectItems
-- Возвращает таблицу с номерами элементов в 'tables', удовлетворяющих 
-- набору критериев вида p = { par1=val1, par2=val2, ... }
-- s - start, e - end
--

function SelectItems(tables,s,e,p)
  local t,fields={},""
    for key,val in pairs(p) do
      fields = fields .. "," .. tostring(key)
      t[#t+1] = val
    end

  local function fn(...)
    local args = {...}
      for key,val in ipairs(args) do
        if t[key] ~= val then
          return false
        end
      end
      return true
  end

  return SearchItems (tables, s, e, fn, fields)
end

 
 function ReadTrades (index, timeFrom, timeTo, firstindex, LastReadDeals, cache_VolAsk, cache_VolBid, inverse, sum_quantity, filterString, CountQuntOfDeals, lastIndex)
   
  local trade = nil
  local datetime = nil
   -- ѕеребирает все сделки в таблице "—делки"
  
  local all_trades_count = getNumberOf("all_trades")
  --WriteLog ("all_trades_count "..tostring(all_trades_count))
  
  if all_trades_count~=0 and timeTo ~= nil then
    trade = getItem ("all_trades", 0)
    datetime = os.time(trade.datetime)
    --WriteLog ("deal 0".."; SEC_CODE: "..trade.sec_code.."; time deal "..isnil(toYYYYMMDDHHMMSS(datetime)," - "));
    if datetime> os.time(timeTo) then
      --WriteLog ("out of time");
      return
    end
  end
    
  --WriteLog("firstindex "..firstindex)
    --_start = os.clock()
  
  local endIndex = all_trades_count-1
  local beginIndex = firstindex
  
  -- если текущая сессия то ищем строки, если прошлая, то перебираем
  if lastIndex == true then 
    params = {sec_code=SEC_CODE,class_code=CLASS_CODE}
    t1 = SelectItems("all_trades", firstindex, all_trades_count-1, params)
    if t1 ~= nil then
      endIndex = #t1
    end
    beginIndex = 1
  else
    t1 = 'table'
  end

    --_end = os.clock()

    --time = _end - _start
    --WriteLog("Found: "..#t1..",time: "..string.format("%.1f",time),1)

  if (t1 ~= nil) and (endIndex > 0) then
    for i = beginIndex, endIndex, 1 do
      if lastIndex == true then 
        trade = getItem ("all_trades", t1[i])
      else
        trade = getItem ("all_trades", i)
      end
      if trade ~= nil then
        if trade.sec_code == SEC_CODE then
          datetime = os.time(trade.datetime)
          if datetime >= os.time(timeFrom) then
            if timeTo == nil or datetime < os.time(timeTo) then
              local value = 0
              if filterQuantity(trade.qty, filterString) then
                if CountQuntOfDeals == 1 then
                  value = 1
                elseif sum_quantity == 0 then
                  value = trade.value
                else
                  value = trade.qty
                end
                if tostring(trade.flags) == "1025" then --продажа
                  if inverse == 0 then
                    cache_VolAsk[index] = cache_VolAsk[index] + value
                  else
                    cache_VolAsk[index] = cache_VolAsk[index] - value
                  end
                else
                  cache_VolBid[index] = cache_VolBid[index] + value
                end
                --WriteLog ("deal ".."i("..i..")".."SEC_CODE: "..trade.sec_code.."; time deal "..isnil(toYYYYMMDDHHMMSS(datetime)," - ").."; flag "..tostring(trade.flags).."; cache_VolAsk: "..tostring(cache_VolAsk[index]).."; cache_VolBid: "..tostring(cache_VolBid[index]));
              end
            else
              if lastIndex == true then 
                LastReadDeals[index] = t1[i-1] or 0
              else
                LastReadDeals[index] = i-1
              end
              break
            end
          end
        end
      end
     end
  end
end

--[[
 function OnAllTrade(alltrade)
  if alltrade.sec_code == SEC_CODE then
    if tostring(alltrade.flags) == "1" then --продажа
      cache_VolAsk[DS:Size()] = cache_VolAsk[DS:Size()] - alltrade.value
    else
      cache_VolBid[DS:Size()] = cache_VolBid[DS:Size()] + alltrade.value
    end
  end
 end
--]]

 function OnCalculate(index)
  if index == 1 then
    DSInfo = getDataSourceInfo()
    SEC_CODE = DSInfo.sec_code
    CLASS_CODE = DSInfo.class_code
    Vol_Coeff = getLotSizeBySecCode(DSInfo.sec_code)
  end

   --if not InitComplete then return; end;

  return myVol(index, Settings)
 end

 function getLotSizeBySecCode(sec_code)
   local status = getParamEx("TQBR", sec_code, "lotsize"); -- Беру размер лота для кода класса "TQBR"
   return math.ceil(status.param_value);                   -- Отбрасываю нули после запятой
end;
 --[[
 function getStructureFromString(filterString)
 
  if filterString == nul then
    return nil
  end
  
  out = {}
  
  local S = filterString
  ind = string.find(S,",")
  while ind ~= nil  do
    
    value = tonumber(string.sub(S, 1, ind-1))
    out
    ind = string.find(S,",")
  end
  
 end
 --]]
 
 function filterQuantity(qty, filterString)
  if filterString == nul or filterString == "" then
    return true
  end
  if string.find(filterString, tostring(qty)..";") ~= nil then
    return true
  end
  return false
 end

 function Vol()
  local cache_VolBid={}
  local cache_VolAsk={}
  local LastReadDeals={}
  local Delta={}

  return function(index, Fsettings, ds)

    local Fsettings=(Fsettings or {})
    local showdelta = (Fsettings.showdelta or 0)
    local showVolume = (Fsettings.showVolume or 0)
    local inverse = (Fsettings.inverse or 0)
    local CountQuntOfDeals = (Fsettings.CountQuntOfDeals or 0)
    local sum_quantity = (Fsettings.sum_quantity or 1)
    local delta_koeff = (Fsettings.delta_koeff or 0)
    local filterString = (Fsettings.dealFilter or nil)

    if index == 1 then
      cache_VolBid={}
      cache_VolAsk={}
      LastReadDeals={} 
      Delta={}
      Delta[index]= 0
      LastReadDeals[index]= -1
    else
      LastReadDeals[index] = LastReadDeals[index-1]
      Delta[index] = Delta[index-1]
    end

    cache_VolAsk[index]= 0
    cache_VolBid[index]= 0

    if not CandleExist(index) then
      return nil
    end

    local timeTo = nil
    local tradeDate = getTradeDate()

    if index == Size() then
      timeTo = nil
    else
      nextCandle = FindExistCandle(index+1, ds)
      if nextCandle == Size()+1 then
        timeTo = nil
      else
        timeTo = T(nextCandle)
        if tradeDate.year ~= timeTo.year or tradeDate.month ~= timeTo.month or tradeDate.day ~= timeTo.day then
          if showVolume == 1 then 
            return nil, nil, nil, nil, V(index)
          else
            return nil, nil, nil, nil, nil
          end
        end
      end
    end

    --WriteLog ("------------------------------------------------------------")
    --WriteLog ("tradeDate "..isnil(toYYYYMMDDHHMMSS(tradeDate)," - "))
    --WriteLog ("OnCalc() ".."CandleExist("..index.."): "..tostring(CandleExist(index)).."; T("..index.."); "..isnil(toYYYYMMDDHHMMSS(T(index))," - ").."; LastReadDeals "..tostring(LastReadDeals[index]));
    --WriteLog ("timeFrom "..isnil(toYYYYMMDDHHMMSS(T(index))," - "))
    --WriteLog ("timeTo "..isnil(toYYYYMMDDHHMMSS(timeTo)," - "))
    ReadTrades(index, T(index), timeTo, LastReadDeals[index]+1, LastReadDeals, cache_VolAsk, cache_VolBid, inverse, sum_quantity, filterString, CountQuntOfDeals, index == Size())  
    --WriteLog ("LastReadDeals "..tostring(LastReadDeals[index]))
    --WriteLog ("cache_VolAsk "..tostring(cache_VolAsk[index]))
    --WriteLog ("cache_VolBid "..tostring(cache_VolBid[index]))

    local localDelta = 0

    if inverse == 0 then
      localDelta = cache_VolBid[index]-cache_VolAsk[index]
    else
      localDelta = cache_VolBid[index]+cache_VolAsk[index]
    end

    --WriteLog ("Delta -1 "..tostring(Delta[index-1]))

    if index > 1 then
      Delta[index] = localDelta*delta_koeff + Delta[index-1]
    else
      Delta[index] = localDelta*delta_koeff   
    end 

    --WriteLog ("Delta "..tostring(Delta[index]))   

    if showdelta == 0 then
      return cache_VolAsk[index], cache_VolBid[index], localDelta, nil, nil
    else
      return cache_VolAsk[index], cache_VolBid[index], localDelta, Delta[index], nil
    end

  end
end

function FindExistCandle(I, ds)
  local out = I
  while not CandleExist(out) and out <= ds:Size() do
    out = out +1
  end
  return out
end
