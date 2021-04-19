-- Подключаемся к серверу
package.path = package.path .. ";C:\\Lua52\\systree\\share\\lua\\5.2\\?.lua"
package.cpath = package.cpath .. ";C:\\Lua52\\systree\\lib\\lua\\5.2\\?.dll"
-- create client:

local HOST, PORT = "172.16.177.1", 9090
local socket = require('socket')

-- Create the client and initial connection
client, err = socket.connect(HOST, PORT)
client:setoption('keepalive', true)

-- Attempt to ping the server once a second
start = os.time()
while true do
    now = os.time()
    if os.difftime(now, start) >= 1 then
        data = client:send("Hello World\t1")
        print(data, s, status, partial)
        start = now
    end
end
