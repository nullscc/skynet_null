local cjson = require "cjson"
local str = require "str"
local filePath = "settings/"

local Settings = {}
local SettingsMgr = {}
-- 配置
SettingsMgr.settingsCfg = 
{
    -- {tabName = "Item", key = "nId", file = "Item.json"},        -- 道具
    -- {tabName = "Drop", key = "nBonusId", file = "Bonus.json", loadFn = "loadDrop"},  -- 掉落
    -- {tabName = "Config", key = "nId", file = "Config.json"},       -- 全局配置
}

SettingsMgr.checkSettingsCfg = 
{
	-- {tabName = "Item", key = "nId", beMappedTbale = "Dungeon,nDungeonComeFrom"},
	-- {tabName = "Drop", key = "nBonusId", beMappedTbale = "Item,sBonusId,|"},
}

-- 保存配置数据的总表
function SettingsMgr:init()
    local preTm = os.time()
    for _, cfg in ipairs(self.settingsCfg) do 
        print("Start load [%s]", cfg.tabName)
        local f = io.open(filePath..cfg.file, "r")
        if f then
            local setting = {}
            local settingStr = f:read("*all")
            local settings = cjson.decode(settingStr or "")
            local key = cfg.key
            if cfg.loadFn then
                local fun = SettingsMgr[cfg.loadFn]
                if fun then
                    print(cfg.loadFn)
                    setting = fun(settings, cfg) 
                else
                    print("load fun[%s] is not exist.", cfg.loadFn)
                end
            else
                setting = self:defaultLoad(settings, cfg)
            end
            Settings[cfg.tabName] = setting

            f:close()
        else
            print("Can't load the file[%s]", cfg.file)
        end
    end
    -- json数据关联检测
    self:checkCfgs()
    print("Load settings, used time:%d", os.time() - preTm)
end

function SettingsMgr:checkCfgs()
	for _, cfg in pairs(self.checkSettingsCfg) do
		print("Check [%s] association data", cfg.tabName)

		local setting = self:getCfg(cfg.tabName)

		for id, data in pairs(setting) do
			local associations = str.split(cfg.beMappedTbale, ";")
			for _, s in pairs(associations) do
				local keys = str.split(s, ",")
				if keys[1] and keys[2] then
					local assValue = data[keys[2]]
                    if assValue then
                        local tempTable = {}
                        if type(assValue) == "string" and assValue ~= "" then
                            local temp = str.split(assValue, keys[3])
                            if keys[4] then
                                for _, v in pairs(temp) do
                                    local temp2 = str.split(v, keys[4])
                                    table.insert(tempTable, temp2[1])
                                end
                            else
                                tempTable = temp
                            end
                        elseif type(assValue) == "number" and assValue ~= 0 and assValue ~= -1 then
                            tempTable[1] = assValue
                        end

                        for _, v in pairs(tempTable) do
                            v = tonumber(v)
                            if v and v ~= 0 and not self:getCfg(keys[1], v) then
                                --print("check error! %s nId[%s] [%s] => %s[%d]\n", cfg.tabName, id, keys[2], keys[1], v)
                                -- file:write(string.format("error %s nId[%s] [%s] => %s[%d]\n", cfg.tabName, id, keys[2], keys[1], v))

                            else
                                --print("id[%s] v[%s]", id, v)
                            end
                        end
                    end
				else
					print("check keys must three param!")
				end
			end
		end
	end
end

function SettingsMgr:getCfg(tabName, key)
    local setting = Settings[tabName]
    if setting then
        if key then 
            return setting[key]
        else
            return setting 
        end
    else
        print("Can't find the %s setting.", tabName)
    end
end

function SettingsMgr:defaultLoad(settings, cfg)
    local setting = {}
    local key = cfg.key

    for k, item in pairs(settings or {}) do 
        if item[key] then
            local id = item[key]
            if not setting[id] then
                setting[id] = item
            else
                print("Repeated id[%d] in [%s]", id, cfg.file)
            end
        else
            print("%s don't have  key[%s]", cfg.file, cfg.key)
            break
        end
    end

    return setting
end

function SettingsMgr.loadDrop(settings, cfg)
    local setting = {}
    local key = cfg.key

    for k, item in pairs(settings or {}) do 
        local id = item[key]
        if id then
            if setting[id] then
                print("Load drop error, repeated id[%d].", id)
            else
                local ids = str.str2tab_1(item.sBonusId) 
                local nums = str.str2tab_1(item.sBonusNum)
                local rates = str.str2tab_1(item.sBonusRate)                
                if #ids == #nums and #ids == #rates then
                    item.ids = ids 
                    item.nums = nums 
                    item.rates = rates
                    setting[id] = item
                else
                    print("Load drop error, count of id-num-rate is not consistent of id[%d]", id)
                end
            end
        else
            print("")
        end
    end
    return setting
end

function SettingsMgr:getConfigByName(name)
    local Configs = Settings["Config"]
    if Configs then
        for _, config in pairs(Configs) do 
            if config.sName == name then
                return config 
            end
        end
    else
        print("")
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

Settings["random_names"] = {}
function SettingsMgr.loadName(settings, cfg)
    local setting = {}
    local key = cfg.key

    local sexes = {}
    sexes[0] = {}
    sexes[1] = {}
    sexes[0].count = 0
    sexes[1].count = 0
    -- {0 = {count = 0}, 1 = {count = 0}}
    local names = {count = 0}
    local count = false
    for _, item in pairs(settings or {}) do
        local id = item[key]
        if id then
            if setting[id] then
                print("Repeated nameId[%s]", id)
            end

            local name = item.sName
            if not name then
                print(string.format("Name.json id:%d sName error!", id))
            end

            local surname = item.sSurname
            if not surname then
                print(string.format("Name.json id:%d sSurname error!", id))
            end

            local sex = item.nSex
            if sex ~= 0 and sex ~= 1 then
                print(string.format("Name.json id:%d nSex error!", id))
            end

            table.insert(names, name)
            names.count = names.count + 1

            sexes[sex].count = sexes[sex].count + 1
            table.insert(sexes[sex], surname)

            setting[id] = item
        else
            print("")
        end
    end
    print("namesCount:%d  sexes[0].count:%d sexes[1].count:%d", names.count, sexes[0].count, sexes[1].count)
    Settings.random_names['names'] = names
    Settings.random_names['sexes'] = sexes
    return setting
end

function SettingsMgr:getRandomName(sex)
    local namesData = random_names['names']
    local surnameData = random_names['sexes'][sex]

    local name
    if surnameData.count > 0 and namesData.count > 0 then
        name = surnameData[math.random(surnameData.count)] .. namesData[math.random(namesData.count)]
    end

    return name
end

SettingsMgr:init()

return Settings
