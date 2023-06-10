--[[
=============[ NLmonitor ]============

 the coolest lua-based system monitor
 made by nologic
 last updated 10/06/2023

=[ requirements ]=====================

 *Linux system
 *Lua 5.1
 *Hardware
 *Terminal w/ ANSI support

=[ extra info ]=======================

 the code is a bit messy, but anybody
 can modify, fix, or add to the code.

 software configuration is below this
 commentblock.

======================================
]]--

--configuration
local config = {
    updateTime = 0.5,       --update time, faster = more memory
    showHardware = true,    --show additional info box (contains hardware info)
    showSoftware = true,    --show system info box (contains software info)
}



--initialize ANSI escape sequences for cursor manipulation / clear screen
local ESC = string.char(27)
local CSI = ESC .. '['
local clearScreen = CSI .. '2J'
local moveToTopLeft = CSI .. 'H'
local clearLine = CSI .. '2K'

--get software information
local currentUser = io.popen("echo $USER"):read("*l")
local currentDistro = io.popen("cat /etc/os-release | grep 'PRETTY_NAME'"):read("*l")
currentDistro = tostring(currentDistro):gsub("%PRETTY_NAME=", ""):gsub('%"',"")

--get hardware information
local cpuModel = io.popen("cat /proc/cpuinfo | grep 'model name' | uniq | awk -F ': ' '{print $2}'"):read("*l")

local cpuCores = io.popen("cat /proc/cpuinfo | grep 'processor' | wc -l"):read("*l")
local totalMemory = tonumber(io.popen("free -m | awk 'NR==2{print $2}'"):read("*a"))
local diskTotal = io.popen("df -h --output=size / | awk 'NR==2{print $1}'"):read("*l")

--initialize print function
local function printResources(freeMemory, cpuUsage, diskUsage, networkUsage, currentUser, currentDistro)
    local output =
[[
=======[ NLmonitor ]========

Free Memory:    %.2f%%
CPU Usage:      %.2f%%
Disk Usage:     %.2f%%
Network Usage:  %.2f%%

]]

    --print software if enabled in config
    if config.showSoftware then
        output = output ..
[[
=[ software ]=================

Current User:   %s
Distribution:   %s

]]
    end

    --print hardware if enabled in config
    if config.showHardware then
        output = output ..
[[
=[ hardware ]=================

CPU model:      %s
CPU cores:      %d
Memory Size:    %d MB
Disk Size:      %s

]]
    end

    --append closing lines
    output = output .. "============================\n"

    --sanitize outputs
    freeMemory = freeMemory or 0
    cpuUsage = cpuUsage or 0
    diskUsage = diskUsage or 0
    networkUsage = networkUsage or 0

    --move cursor to top left and clear previous output
    io.write(moveToTopLeft)
    io.write(clearLine)

    
    --determine the number of arguments required for string formatting
    local argCount = 4
    if config.showSoftware then argCount = argCount + 2 end
    if config.showHardware then argCount = argCount + 4 end
        -- Format and print the output
        if argCount == 4 then
            io.write(string.format(output, freeMemory, cpuUsage, diskUsage, networkUsage))
        elseif argCount == 6 then
            io.write(string.format(output, freeMemory, cpuUsage, diskUsage, networkUsage, currentUser, currentDistro))
        elseif argCount == 10 then
            io.write(string.format(output, freeMemory, cpuUsage, diskUsage, networkUsage, currentUser, currentDistro, cpuModel, cpuCores, totalMemory, diskTotal))
        end
    
        io.flush()  --flush output immediately to ensure display
    end
    
--clear console before entering loop
io.write(clearScreen)
io.flush()

--theme the terminal
io.write(ESC .. ']0;NLmonitor\7')


while true do
    --get stuff that updates
    local usedMemory = tonumber(io.popen("free -m | awk 'NR==2{print $3}'"):read("*a"))
    local freeMemory = usedMemory / totalMemory * 100
    local cpuUsage = tonumber(io.popen("top -bn1 | grep Cpu | awk '{print $2}'"):read("*a"))
    local diskUsage = tonumber(io.popen("df -h --output=pcent / | awk 'NR==2 {print substr($1, 1, length($1)-1)}'"):read("*a"))
    local networkUsage = tonumber(io.popen("ifconfig | grep 'RX packets' | awk '{print $5}'"):read("*a"))

    --final print
    printResources(freeMemory, cpuUsage, diskUsage, networkUsage, currentUser, currentDistro)

    os.execute("sleep "..config.updateTime)
end
