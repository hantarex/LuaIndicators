assert(package.loadlib(getScriptPath() .. "\\iuplua51.dll", "luaopen_iuplua"))()

is_run = true

function OnInit()
--    message("start")
--    dlg = iup.dialog
--        {
--            iup.vbox
--                {
--                    iup.label {title="Test iupLUA in QUIK"},
--                    iup.button{title="Button Very Long Text"},
--                    iup.button{title="short", expand="HORIZONTAL"},
--                    iup.button{title="Mid Button", expand="HORIZONTAL"}
--                }
--            ;title="IupDialog", font="Helvetica, Bold 14"
--        }
--    dlg:show()
--
--    iup.MainLoop()
end

function OnStop()
    is_run = false
end

function main()
    message("start")
    dlg = iup.dialog
        {
            iup.vbox
                {
                    iup.label {title="Test iupLUA in QUIK"},
                    iup.button{title="Button Very Long Text"},
                    iup.button{title="short", expand="HORIZONTAL"},
                    iup.button{title="Mid Button", expand="HORIZONTAL"}
                }
            ;title="IupDialog", font="Helvetica, Bold 14"
        }
    dlg:show()

    iup.MainLoop()
    while is_run do
        message(os.date()) --раз в секунду выводит текущие дату и время
        sleep(1000)
    end
end
