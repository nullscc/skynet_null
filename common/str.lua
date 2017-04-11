local cjson = require "cjson"

local _M = {}

local function isArrayTable(t)
    if type(t) ~= "table" then
        return false
    end
    if table.isarray then
        return table.isarray(t)
    end

    local n = #t
    for i,v in pairs(t) do
        if type(i) ~= "number" then
            return false
        end
        
        if i > n then
            return false
        end 
    end

    return true 
end

local function doT2S(_isarray,_i, _v)
    local str = ""
    
    if not _isarray then
        if "number" == type(_i) then
            str = str .. "[" .. string.format("%d",_i) .. "] = "
        elseif "string" == type(_i) then
            str = str .. '["' .. _i .. '"] = '
        end
    end

    if "boolean" == type(_v) then
        if _v == true then
            str = str.."true,"
        else
            str = str.."false,"
        end
    elseif "number" == type(_v) then
	str = str .. _v .. ","
    elseif "string" == type(_v) then
        local x = string.find(_v, "\n")
        if x then
            local tmp, n = string.gsub(_v, "\r\n", "\\%0")
            if n == 0 then
                tmp, n = string.gsub(_v, "\n", "\\%0")
            end
            str = str .. '"' .. tmp .. '"' .. ","
        else
            str = str .. '"' .. _v .. '"' .. ","
        end
    elseif "table" == type(_v) then
        str = str .. _M.table2Str(_v) .. ","
    else
        str = str .. "nil,"
    end
    return str
end

function _M.table2Str(_t)
    if type(_t) ~= "table" then
        return nil
    end

    local isarray = isArrayTable(_t)
    local szRet = "{"
    for i,v in pairs(_t) do
        local member_str = doT2S(isarray,i,v)
        szRet = szRet..member_str
    end
    szRet = szRet .. "}"
    return szRet
end

function _M.str2table(str)
    local f =  load("return "..str)
    
    if f then
        return f()
    end
end

-- 分割字符串
function _M.split(str, div)
    local ret = {}
    if type(str) ~= "string" or str == "" then
        print(string.format("Split target must be string. error type:%s", type(str)))
        return ret
    end
    if type(div) ~= "string" then
        print("Split div msut be string.")
        return {str}
    end
    local begin = 1
    local walk = string.find(str, div, begin)
    while(walk) do
        local subStr = string.sub(str, begin, walk - 1)
        table.insert(ret, subStr)
        begin = walk + 1
        walk = string.find(str, div, begin)
    end
    local subStr = string.sub(str, begin, -1)
    if subStr then
        table.insert(ret, subStr)
    end
    return ret
end
-- 时间解析成字符串
function _M.time2Str(tm)
    local str = ""
    str = str .. os.date("%y") .. "-" .. os.date("%m") .. "-" .. os.date("%d")
        .. " " .. os.date("%H") .. ":" .. os.date("%M")  .. ":" .. os.date("%S")
    return str
end

-- 时间解析成字符串(XXXX-XX-XX XX:XX:XX)
function _M.dateTimeToString(time)
    local str = ""
    str = str .. os.date("%Y", time) .. "-" .. os.date("%m", time) .. "-" .. os.date("%d", time)
        .. " " .. os.date("%H", time) .. ":" .. os.date("%M", time)  .. ":" .. os.date("%S", time)
    return str
    -- return os.date("%Y-%m-%d %X", time)
end

-- 时间字符串(XXXX-XX-XX XX:XX:XX)解析成时间(os.time())
function _M.stringToDateTime(strTime)
    if type(strTime) ~= "string" then
        print("transfer format must be string. error type:%s %s", type(strTime), strTime)
        return 0
    end
    local split = _M.split
    local timeTable = {}
    local t = split(strTime, " ")
    if #t ~= 2 then
        print("transfer data must be [XXXX-XX-XX XX:XX:XX][%s]", strTime)
    end

    for k, v in pairs(t) do
        if k == 1 then
             local t2 = split(v, "-")
             if #t2 ~= 3 then
                print("transfer data must be [XXXX-XX-XX XX:XX:XX][%s]", strTime)
             end
             timeTable.year = t2[1] or 2000
             timeTable.month = t2[2] or 1
             timeTable.day = t2[3] or 1
        elseif k == 2 then
            local t2 = split(v, ":")
            if #t2 ~= 3 then
                print("transfer data must be [XXXX-XX-XX XX:XX:XX][%s]", strTime)
            end
            timeTable.hour = t2[1] or 0
            timeTable.min = t2[2] or 0
            timeTable.sec = t2[3] or 0
        end
    end

    return os.time(timeTable)
end

-- 根据时间字符串(XX:XX:XX)获得完整时间(os.time())
function _M.getFullTime(strDayTime)
    local time = os.time()
    if type(strDayTime) ~= "string" then
        print("getFullTime strDayTime must be string. error type:%s %s", type(strDayTime), strDayTime)
        return time
    end

    local t = split(strDayTime, ":")
    if #t ~= 3 then
        print("getFullTime strDayTime must be [XX:XX:XX][%s]", strDayTime)
    end

    local hour = tonumber(os.date("%H", time))
    local min = tonumber(os.date("%M", time))
    local sec = tonumber(os.date("%S", time))

    local hour2 = tonumber(t[1]) or 0
    local min2 = tonumber(t[2]) or 0
    local sec2 = tonumber(t[3]) or 0

    return time - (hour - hour2) * 3600 - (min - min2) * 60 - sec + sec2
end

-- 将一个字符串table中的每一个字符元素转换为number
function _M.strTab2Num(strTab)
    local ret = {}
    for _, str in pairs(strTab or {}) do
        table.insert(ret, tonumber(str))
    end
    return ret
end


-- mode "id|id|id"
function _M.str2tab_1(str,split_str)
	if not split_str then
		split_str = "|"
	end
    local strs = _M.split(str, split_str)
    return _M.strTab2Num(strs)
end
-- mode "id*count|id*count|id*count"
function _M.str2tab_2(str, type1, type2)
    local ret = {}
    local strGroups = _M.split(str, type1)
    for _, group in pairs(strGroups) do 
        local group_info = _M.split(group, type2)
        group_info = _M.strTab2Num(group_info)
        table.insert(ret, group_info)
    end
    return ret
end

function _M.str2tab_3(str, type1, type2, type3)
    local ret = {}
    local strGroups = _M.split(str, type1)
    for _, group in pairs(strGroups) do 
        local group_info = _M.str2tab_2(group, type2, type3)
        table.insert(ret, group_info)
    end
    return ret
end


function _M.table2JsonEscapeStr(tab)
    local str = cjson.encode(tab)
    return core.escapeString(str)
end

function _M.dprint(tab, dep)
    local dep = dep or 0
    local preStr = ""
    for k=1, dep do
        preStr = preStr .. "  "
    end
    if type(tab) == "table" then
        for k, v in pairs(tab) do 
            print(preStr .. k .. ":" .. tostring(v))
            if type(v) == "table" then
                _M.dprint(v, dep+1)
            end
        end
    end
end

function _M.parseUrl(url)
    t1=_M.split(url,'&')
    local res = {}  
    for k,v in pairs(t1) do  
        i = 1  
        t1 = _M.split(v,'=')  
        res[t1[1]]={}  
        res[t1[1]]=t1[2]  
        i=i+1  
    end  
    return res  
end  
return _M
