local Counter = script.Parent

local HighestDrawTimeValue = Hidden:WaitChild("HighestDrawTime")

HighestDrawTimeValue.Changed:Connect(function()
    local value = HighestDrawTimeValue.Value
    Counter.Text = value
end)