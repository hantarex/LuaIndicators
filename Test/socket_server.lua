package.path = package.path .. ";C:\\Lua54\\systree\\share\\lua\\5.4\\?.lua"
package.cpath = package.cpath .. ";C:\\Lua54\\systree\\lib\\lua\\5.4\\?.dll"
-- load namespace
local socket = require("socket")
-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("0.0.0.0", 9091))
-- find out which port the OS chose for us
local ip, port = server:getsockname()
-- print a message informing what's up
print("Please telnet to localhost on port " .. port)
print("After connecting, you have 10s to enter a line to be echoed")
-- loop forever waiting for clients
while 1 do
    -- wait for a connection from any client
    local client = server:accept()
    -- make sure we don't block waiting for this client's line
    client:settimeout(1000)
    -- receive the line
    local line, err = client:receive()
    -- if there was no error, send it back to the client
    if not err then client:send(line .. "\n") end
    -- done with client, close the object
    client:close()
end
