local root = (... or ".") .. "\\"

local function RunRunner(names, failingTest, discoverySucceeded)
    local commands, messages = {}, {}
    local env = setmetatable({}, { __index = _G })
    env.arg = { [-1] = "C:\\Program Files\\Lua\\lua.exe" }
    env.print = function(...) end
    env.io = {
        popen = function()
            local index = 0
            return {
                lines = function()
                    return function()
                        index = index + 1
                        return names[index]
                    end
                end,
                close = function() return discoverySucceeded end,
            }
        end,
        stdout = { flush = function() end },
        stderr = { write = function(_, message) messages[#messages + 1] = message end },
    }
    env.os = {
        execute = function(command)
            commands[#commands + 1] = command
            return not failingTest or not command:find(failingTest, 1, true)
        end,
        exit = function(code) error("exit:" .. code, 0) end,
    }
    local run = assert(loadfile(root .. "tests\\run_test.lua", "t", env))
    local ok, err = pcall(run)
    return ok, err, commands, messages
end

local names = { "z_test.lua", "run_test.lua", "a_test.lua" }
local ok, err, commands = RunRunner(names, nil, true)
assert(ok, err)
assert(#commands == 2 and commands[1]:find("a_test.lua", 1, true)
    and commands[2]:find("z_test.lua", 1, true), "Run all discovered tests in order, excluding the runner")
assert(commands[1]:find('"C:\\Program Files\\Lua\\lua.exe"', 1, true), "Quote the Lua executable path")

local messages
ok, err, commands, messages = RunRunner(names, "a_test.lua", true)
assert(not ok and err == "exit:1" and #commands == 2, "Continue after failures and exit unsuccessfully")
assert(messages[1]:find("a_test.lua", 1, true), "Identify the failed test")

ok, err = RunRunner({ "run_test.lua" }, nil, true)
assert(not ok and err:find("No test files found", 1, true), "An empty suite must fail")
ok, err = RunRunner({}, nil, false)
assert(not ok and err:find("Test discovery failed", 1, true), "Discovery failures must fail")

print("runner tests passed")
