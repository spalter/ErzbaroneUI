local discovery = [[powershell -NoProfile -NonInteractive -Command "$ErrorActionPreference = 'Stop'; Get-ChildItem -LiteralPath 'tests' -File -Filter '*_test.lua' | Select-Object -ExpandProperty Name"]]
local pipe = assert(io.popen(discovery), "Could not start test discovery")
local tests = {}
for name in pipe:lines() do
    assert(name:match("^[%w_%-]+_test%.lua$"), "Unsupported test filename: " .. name)
    if name:lower() ~= "run_test.lua" then
        tests[#tests + 1] = name
    end
end
local discovered = pipe:close()
assert(discovered, "Test discovery failed")
assert(#tests > 0, "No test files found in tests")
table.sort(tests)

local interpreter = arg[-1] or "lua"
local failures = 0
for _, name in ipairs(tests) do
    print("\nRunning " .. name)
    io.stdout:flush()
    -- Separate Lua processes prevent the WoW mocks and globals from leaking between tests.
    local success = os.execute('""' .. interpreter .. '" "tests\\' .. name .. '""')
    if success ~= true and success ~= 0 then
        failures = failures + 1
        io.stderr:write("FAILED: " .. name .. "\n")
    end
end

if failures > 0 then
    io.stderr:write(failures .. " of " .. #tests .. " test files failed\n")
    os.exit(1)
end
print("\nAll " .. #tests .. " test files passed")
