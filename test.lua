local inspect = require('inspect')

print(10,000)

now=os.time()
print(now)
tableDate =os.date("*t", now)
print(inspect(
    tableDate
))

print(os.time(tableDate))

print(os.date("%c",now-1))

print(math.floor(10.333, 2))
for i=1,10 do print(i) end