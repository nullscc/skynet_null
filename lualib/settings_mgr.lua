local sharedata = require "sharedata"
local log = require "base.log"

local SettingsMgr = {}

function SettingsMgr:init()
	self.Settings = sharedata.query("settings")
end

function SettingsMgr:getCfg(tabName, key)
	if type(key) == "number" then
		key = math.floor(key)
	end
    local setting = self.Settings[tabName]
    if setting then
        if key then 
            return setting[key]
        else
            return setting 
        end
    else
        log.error("Can't find the %s setting.", tabName)
    end
end

function SettingsMgr:getExploreCfg(level, type)
    local settings = self.Settings["Explore"]
    if not settings then
        return 
    end
    for _, item in pairs(settings ) do 
        if item.nType == type then
            if level >= item.levels[1] and level <= item.levels[2] then
                return item
            end
        end
    end
end

function SettingsMgr:getConfigByName(name)
    local Configs = self.Settings["Config"]
    if Configs then
        for _, config in pairs(Configs) do 
            if config.sName == name then
                return config 
            end
        end
    else
        log.error("")
    end
end


-- 获得游戏设定（int）
function SettingsMgr:getGameSetI(name)
    local setting = self:getConfigByName(name)
    return setting and setting.nValue or 0
end

-- 获得游戏设定（float）
function SettingsMgr:getGameSetF(name)
    local setting = self:getConfigByName(name)
    return setting and setting.fValue or 0.0
end

-- 获得游戏设定（string）
function SettingsMgr:getGameSetS(name)
    local setting = self:getConfigByName(name)
    return setting and setting.sValue or ""
end

function SettingsMgr:getRandomName(sex)
    local namesData = self.Settings.random_names['names']
    local surnameData = self.Settings.random_names['sexes'][sex]

    local name
    if surnameData.count > 0 and namesData.count > 0 then
        name = surnameData[math.random(surnameData.count)] .. namesData[math.random(namesData.count)]
    end

    return name
end

return SettingsMgr