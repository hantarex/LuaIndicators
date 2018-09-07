--logfile=io.open("C:\\SBERBANK\\QUIK_SMS\\LuaIndicators\\qlua_log.txt", "w")

local inspect = require('inspect')


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
   Name = "myTest",
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

function fn(t)
  --  if t.class_code == DSInfo.class_code and t.sec_code == DSInfo.sec_code then
--  PrintDbgStr(t.sec_code .. " " ..  DSInfo.sec_code)
  if (c < 100) and (t.sec_code == DSInfo.sec_code) then
    PrintDbgStr(inspect(
      t
    ))
    c = c + 1
    return true
  else
    return false
  end

end

function Init()
  c=0
  return 1
end

function OnCalculate(index)
  if index == 1 then
    DSInfo = getDataSourceInfo()
    startIndex = 0

    PrintDbgStr(inspect(
      DSInfo
    ))
--    ParamRequest("TQBR", "SBER", "tradingstatus")
--    PrintDbgStr(inspect(
--      getParamEx ("TQBR", "SBER", "tradingstatus")
--    ))
--
--    PrintDbgStr(inspect(
--      getParamEx(DSInfo.class_code, DSInfo.sec_code, "QTY")
--    ))

    PrintDbgStr(inspect(
      SearchItems ("all_trades", 0, getNumberOf("all_trades"), fn)
    ))

--    PrintDbgStr(inspect(
--      getItem ("all_trades", 1)
--    ))
  end
--    DSInfo = getDataSourceInfo()
--    PrintDbgStr(inspect(DSInfo))
--    DSInfo = getDataSourceInfo()
--    SEC_CODE = DSInfo.sec_code
--    CLASS_CODE = DSInfo.class_code

--    local status = getParamEx(CLASS_CODE, SEC_CODE, "LOTSIZE");
--    t1 = SearchItems("all_trades", 0, getNumberOf("all_trades")-1, fn)
--    PrintDbgStr(inspect(t1))
end