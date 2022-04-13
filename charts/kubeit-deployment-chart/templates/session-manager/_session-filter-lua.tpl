{{- define "filter.lua" -}}

typed_config:
  '@type': type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
  inlineCode: |
    sessidCookieName = "onegateway_sessid";
    sessionManagerNS = {{ .namespace | quote }};
    returnUrlCookieName = "onegateway_returnurl";
    sessionManagerRoutePrefix = "/session";
    tokenRefresherRoutePrefix = "/tokens";
    authCallbackRoutePrefix = sessionManagerRoutePrefix .. "/auth-callback/";
    sessionManagerLoginRoute = sessionManagerRoutePrefix .. "/login";
    sessionManagerLogoutRoute = sessionManagerRoutePrefix .. "/logout";
    tokenRefresherRouteSuffix = "/refresh";
    tokenRefresherKeepAliveRouteSuffix = "/envoykeepalive";
    function startsWith(strToCheck, strSubsection)
      local sub = strToCheck:sub(1, strSubsection:len())
      return sub == strSubsection
    end
    function endsWith(str, ending)
      return ending == "" or str:sub(-#ending) == ending
    end
    function logDebug(logger, message)
{{- if .debugEnvoyFilters }}
        logger:logWarn(message)
{{- else }}
        logger:logDebug(message)
{{- end }}
    end

    function trim(s)
      return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
    function stringSplit(inputstr, sep)
      if sep == nil then
        sep = "%s"
      end
      local t={}
      for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, trim(str))
      end
      return t
    end
    function getMapFromString(str, separator)
      local map = {}
      if(str ~= nil) then
        local kvPairs = stringSplit(str, separator)
        for _, v in pairs(kvPairs) do
          local i, j = string.find(v, "=")
          if(j ~= nil) then
            local key = string.sub(v, 1, j - 1)
            local value = string.sub(v, j + 1)
            map[key] = value
          end
        end
      end
      return map
    end
    function computeSessionManagerClusterName(handle, hostname)
      local escapedHost = string.gsub(hostname, "[.]", "-")
      local clusterName = "outbound|80||session-manager-"..escapedHost.."."..sessionManagerNS..".svc.cluster.local"
      logDebug(handle, clusterName)
      return clusterName
    end
    function requestSessionData(handle, key)
      local origRequestHost = handle:headers():get(":authority")
      local sessionManagerClusterName = computeSessionManagerClusterName(handle, origRequestHost)
      local headers, body = handle:httpCall(sessionManagerClusterName,
      {
        [":authority"] = origRequestHost,
        [":path"] = tokenRefresherRoutePrefix .."/"..key..tokenRefresherKeepAliveRouteSuffix,
        [":method"] = "POST",
      },  nil, 5000)
      if(startsWith(headers[":status"], "2")) then
        return body
      end
      return nil
    end

    function requestRefreshedToken(handle, sessionId)
      local origRequestHost = handle:headers():get(":authority")
      local sessionManagerClusterName = computeSessionManagerClusterName(handle, origRequestHost)
      logDebug(handle, "Requesting token refresh from "..sessionManagerClusterName)
      local headers, body = handle:httpCall(sessionManagerClusterName,
      {
        [":authority"] = origRequestHost,
        [":path"] = tokenRefresherRoutePrefix .. "/".. sessionId .. tokenRefresherRouteSuffix,
        [":method"] = "POST",
      },  nil, 15000)
      return headers, body
    end
    function handleInternalRedirect(request, relativePath, setCookie)
      local url = "https://" .. request:headers():get(":authority") .. relativePath
      local headers = {
            [":status"] = "302",
            ["Location"] = url,
            ["Content-Security-Policy"] = "default-src 'none'"
            };
      if(setCookie ~= nil) then
        headers["Set-Cookie"] = setCookie;
      end
      logDebug(request, "Redirecting to " .. url)
      request:respond(headers, nil)
    end
    function handleNoAuthHeader(request_handle, requestPath, headers)
      -- Use session cookie if prvovided to lookup up token
      local cookies = getMapFromString(request_handle:headers():get("cookie"), ";")
      local sessid = cookies[sessidCookieName]
      local error = nil
      if(sessid ~= nil) then
        local sessionData = requestSessionData(request_handle, sessid)
        if(sessionData ~= nil) then
          local currentTime = os.time() + 30 -- add 30 seconds to ensure token is valid when it reaches the intended destination
          local session = getMapFromString(sessionData, ";")
          local accessToken = nil
          if(tonumber(session["AccessTokenExpirationTime"]) > currentTime) then
            accessToken = session["AccessToken"]
          else
            -- if token invalid, ask for refresh and wait
            local responseHeaders, responseBody = requestRefreshedToken(request_handle, sessid)
            if(startsWith(responseHeaders[":status"] , "2")) then
              accessToken = responseBody
            else
              error = responseBody
            end
          end
          if(accessToken ~= nil) then
            request_handle:headers():add("Authorization", "Bearer ".. accessToken) -- add access token to Authorization header
          end
        end
{{- if .redirect }}
      else
        -- No session token, redirect to login
        if(endsWith(requestPath, ".js") == true) then
          logDebug(request_handle, "Request for .js resource - doing nothing. (passthru)")
        else
          logDebug(request_handle, "No session or access token. Redirecting to login.")
          handleInternalRedirect(request_handle, sessionManagerLoginRoute, returnUrlCookieName .. "=https://"..headers:get(":authority")..requestPath.."; HttpOnly; Secure; Path=/; SameSite=Lax")
        end
{{- end }}
      end
      return error
    end
    function envoy_on_request(request_handle)
      local headers = request_handle:headers()
      local authz = headers:get("authorization")
      local path = headers:get(":path")
      local originalPath = headers:get("x-envoy-original-path") -- this holds the path for rewritten routes
      if(originalPath ~= nil) then
        path = originalPath
      end
      local error = nil

      if(path == "/login") then
        handleInternalRedirect(request_handle, sessionManagerLoginRoute, nil)
      elseif(path == "/logout") then
        handleInternalRedirect(request_handle, sessionManagerLogoutRoute, nil)
      elseif(startsWith(path, authCallbackRoutePrefix)) then
        logDebug(request_handle, "Authentication callback request detected - doing nothing (passthru)")
      elseif(authz == nil) then
        error = handleNoAuthHeader(request_handle, path, headers)
      else
        logDebug(request_handle, "Authorization header detected - doing nothing (passthru)")
      end
      if(error ~= nil) then
        request_handle:logErr("Error while processing request: "..error)
        request_handle:respond({[":status"] = "503"}, nil)
      end
    end
{{- end}}
