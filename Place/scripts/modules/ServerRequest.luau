local ServerRequest = {}

function ServerRequest:GetData(url: string, clearBacklog: boolean): (boolean, buffer)
    local request = HttpRequestData.New() do
        request.Method = Enums.HttpRequestMethod.Get
        request.URL = url .. (clearBacklog and "?clear=1" or "")
        request.Headers = {
            ["Accept"] = "application/octet-stream"
        }
    end

    local success, response = pcall(function()
        return Http:RequestAsync(request)
    end)

    if not success or not response.Success then
        print("HTTP frame request failed")
        return false, nil
    end

    return true, response.Buffer
end

return ServerRequest
