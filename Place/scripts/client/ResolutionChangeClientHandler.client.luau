local LocalPlayer = Players.LocalPlayer

local Resolution: GUI = PlayerGUI:WaitChild("Resolution")
local XInput: UITextInput = Resolution:WaitChild("XInput")
local YInput: UITextInput = Resolution:WaitChild("YInput")

local SetResolution: NetworkEvent = Hidden:WaitChild("SetResolution")

Resolution.Visible = LocalPlayer.IsCreator or LocalPlayer.Name == "Player"

local oldX, oldY


local function updateResolution()
    local newX, newY  = tonumber(XInput.Text), tonumber(YInput.Text)
    
    if newX == oldX and newY == oldY then return end
    
    local msg = NetMessage.New()

    if newX and newX ~= oldX then
        oldX = newX
        msg:AddInt("x", newX)
    end
    if newY and newY ~= oldY then
        oldY = newY
        msg:AddInt("y", newY)

    end

    SetResolution:InvokeServer(msg)
end 
    
XInput.Submitted:Connect(updateResolution)
YInput.Submitted:Connect(updateResolution)