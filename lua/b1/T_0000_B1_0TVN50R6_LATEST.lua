----B1_大烤箱协议解析
----author: yanhan.liang
----email ：yanhan.liang@midea.com
----date  : 2018/11/15

-- 这份lua主要针对微蒸烤新协议数据的解析
-- lua测试工具地址：http://118.31.237.230:3000

-- 修改注意事项：
-- 1 原key_value不得随意更改。
-- 2 需要新增key_value的情况，需要保证后面的所有遵循同一个电控协议的微蒸烤profile和lua都沿用新增的key_value。
-- 2 关于新增的work_mode的取名规范，请遵守《厨电串口协议_业务部分_烹饪类统一》的附录1的列表。

-- 发布注意事项：
-- 1 文件顶端 a文件介绍 b作者邮件 c日期 是否已经更改
-- 2 BYTE_DEVICE_TYPE 是否已经配置为相应的品类
-- 3 bit 引用是否正确（根据使用对象）
-- 4 底部的两种测试用例是否能跑通
-- 5 请抄送iot的负责维护lua开源项目和大数据的同事。
-- bifeng.zhang@midea.com;tiancheng.shi@midea.com;shufa.zhong@midea.com

local JSON = require "cjson"
--未知
local VALUE_UNKNOWN="unknown"
--无效
local VALUE_INVALID="invalid"

-----------------JSON相关key值变量-----------------
--版本号
local KEY_VERSION = "version"

--设备
local BYTE_DEVICE_TYPE = 0xB1
--框架协议版本
local BYTE_PROTOCOL_VERSION = 0x03
--消息类型
local BYTE_CONTROL_REQUEST = 0x02
local BYTE_QUERY_REQUEST = 0x03
--协议头及长度
local BYTE_PROTOCOL_HEAD = 0xAA
local BYTE_PROTOCOL_LENGTH = 0x0A

----------------JSON相关value值变量----------------
--版本号
 local VALUE_VERSION = 4

-- 环境为lua5.1（智慧云_测试环境）
local bit = require "bit" -- openresty可以直接使用bit

-- 环境为lua5.2
-- local bit = require "bit32"

-- 环境为lua5.3（智慧云_工具环境）
-- 不添加bit声明

-----------根据电控协议不同，需要改变的函数-------------
--根据传入的json，对应相应的协议值
function devicetocloud(luatable)
    local mode
    -- 大烤箱
    if luatable["work_mode"]=="double_tube" then --上下烧烤
        mode=0x4C
    elseif luatable["work_mode"]=="hot_wind_bake" then  --热风对流
        mode=0x41
    elseif luatable["work_mode"]=="double_tube_fan" then  --上下烧烤+风扇
		mode=0x52
    elseif luatable["work_mode"]=="underside_tube" then  --下管烧烤
        mode=0x49
    elseif luatable["work_mode"]=="double_upside_tube_fan" then  --双上管+风扇
		mode=0x51
    elseif luatable["work_mode"]=="core_baking" then -- 双上管烧烤
        mode=0x46
    elseif luatable["work_mode"]=="total_baking" then  --红外烧烤
        mode=0x47
	elseif luatable["work_mode"]=="underside_tube_hot_wind_bake" then  --下管烧烤+热风对流
		mode=0x42
    elseif luatable["work_mode"]=="zymosis" then --发酵
        mode=0xB0
    -- 蒸箱
    elseif luatable["work_mode"]=="auto_menu" then --自动菜单
        mode=0xE0
    elseif luatable["work_mode"]=="pure_steam" then  --蒸汽
        mode=0x20
    elseif luatable["work_mode"]=="dry" then  --烘干
        mode=0xC4
    elseif luatable["work_mode"]=="zymosis" then --发酵
        mode=0xB0
    elseif luatable["work_mode"]=="scale_clean" then --清洁
        mode=0xC1
    -- 微蒸烤
    elseif luatable["work_mode"]=="above_tube" then --烧烤
        mode=0x40
    elseif luatable["work_mode"]=="fast_baking" then --组合
        mode=0x70
    elseif luatable["work_mode"]=="microwave" then -- 微波
        mode=0x01
    -- else
    --	mode=0x00
	elseif luatable["work_mode"]=="unfreeze" then -- 按重解冻
        mode=0xa0
    end
    return mode
end

function firepower(luatable)
    local power = 0x00
    if luatable["fire_power"]=="high_power" then -- 高火
        power=0x0A
    elseif luatable["fire_power"]=="medium_high_power" then  --中高火
        power=0x08
    elseif luatable["fire_power"]=="medium_power" then  --中火
		power=0x05
    elseif luatable["fire_power"]=="medium_low_power" then  --中低火
        power=0x03
    elseif luatable["fire_power"]=="low_power" then  --低火
		power=0x01
	end
    return power
end

function getfirepowertype(meg)
    local power_type
    if(meg=="0A") then
        power_type="high_power" -- 高火
    elseif(meg=="08") then
        power_type="medium_high_power"  -- 中高火
    elseif(meg=="05") then
        power_type="medium_power" -- 中火
    elseif(meg=="03") then
        power_type="medium_low_power" -- 中低火
    elseif(meg=="01") then
        power_type="low_power" -- 低火
    end
    return power_type
end

--json转二进制，可传入原状态
function string_split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end
    return sub_str_tab;
end
function jsonToData(jsonCmdStr)
    if (#jsonCmdStr == 0) then
        return nil
    end
    local msgBytes
    local json = decodeJsonToTable(jsonCmdStr)

    --TODO 根据设备子类型来处理协议差异
    local deviceSubType = json["deviceinfo"]["deviceSubType"]
    if (deviceSubType == 1) then
    end


    local query = json["query"]
    local control = json["control"]

    -- print("power:"..control["power"])
    -- print("mode:"..control["mode"])
    local status = json["status"]
    --将用户控制 转换为profile文件中对应属性
    if (control) then
        local bodyBytes = {}
        if(control["year"]~=nil) then
            bodyBytes[0]=0x23
            bodyBytes[1]=control["year"]-2000  ---需要转换至16进制
            bodyBytes[2]=control["month"]
            bodyBytes[3]=control["day"]
            bodyBytes[4]=control["work_hour"]
            bodyBytes[5]=control["work_minute"]
            bodyBytes[6]=control["work_second"]
            bodyBytes[7]=control["week"]
        --预约控制
        elseif(control["reservation"]~=nil) then
            bodyBytes[0]=0x24
            bodyBytes[1]=control["reservation"]
            bodyBytes[2]=control["pre_hour"]
            bodyBytes[3]=control["pre_minutes"]
            bodyBytes[4]=control["pre_second"]
            if control["cloudmenuid"]~=nil then
                local cloudmenuidn = tonumber(control["cloudmenuid"])
                local cloundMenuIdNHH = math.modf(cloudmenuidn/(16^4))
                local cloundMenuIdNHHLeft = math.fmod(cloudmenuidn,(16^4))

                local cloundMenuIdNH = math.modf(cloundMenuIdNHHLeft/(16^2))
                local cloundMenuIdNL = math.fmod(cloundMenuIdNHHLeft,(16^2))

                bodyBytes[5] = cloundMenuIdNHH
                bodyBytes[6] = cloundMenuIdNH
                bodyBytes[7] = cloundMenuIdNL
                if control["totalstep"]~=nil then
                    bodyBytes[8] = control["totalstep"]
                else
                    bodyBytes[8] = 0x11
                end
                -- return ''
            else
                bodyBytes[5] = 0x00
                bodyBytes[6] = 0x00
                bodyBytes[7] = 0x00
                bodyBytes[8] = 0x11
            end
            -- bodyBytes[5] = 0x00
            -- bodyBytes[6] = 0x00
            -- bodyBytes[7] = 0x00
            -- bodyBytes[8] = 0x00
            if(control["pre_heat"]~=nil)then
                if(control["pre_heat"]=="off")then
                    bodyBytes[9] = 0x00
                elseif(control["pre_heat"]=="on")then
                    bodyBytes[9] = 0x01
                --elseif(control["probo_mode"]=="2")then
                --bodyBytes[9] = 0x02
                end
            else
                bodyBytes[9]=0x00
            end
            if(control["work_hour"]~=nil) then
                bodyBytes[10] = control["work_hour"]
            else
                bodyBytes[10] =0x00
            end
            if(control["work_minute"]~=nil) then
                bodyBytes[11] = control["work_minute"]
            else
                bodyBytes[11] =0x00
            end
            if(control["work_second"]~=nil) then
                bodyBytes[12] = control["work_second"]
            else
                bodyBytes[12] =0x00
            end
            bodyBytes[13] = devicetocloud(control)
            if(control["temperature"]~=nil)then
                bodyBytes[14] = 0x00
                bodyBytes[15] = control["temperature"]
            else
                bodyBytes[14] = 0x00
                bodyBytes[15] = 0x00
            end
            if(control["temperature"]~=nil)then
                bodyBytes[16] = 0x00
                bodyBytes[17] = control["temperature"]
            else
                bodyBytes[16] = 0x00
                bodyBytes[17] = 0x00
            end
            if(control["fire_power"]~=nil)then
                bodyBytes[18] = firepower(control)
            else
                bodyBytes[18]=0xff
            end
            if(control["weight"]~=nil) then
                bodyBytes[19] = control["weight"]/10
            else
                bodyBytes[19] = 0xff
            end
            if(control["workend"]==nil) then
                bodyBytes[20]=0xff
            else
                bodyBytes[20] = control["workend"]
            end
            -- bodyBytes[18] = control["fire_power"]
            -- bodyBytes[19] = control["weight"]
            -- bodyBytes[20] = control["workend"]
            if(control["probo_value"]~=nil)then
                bodyBytes[21] = control["probo_value"]
            else
                bodyBytes[21] = 0x00
            end
        --翻页控制
        elseif(control["page_choose"]~=nil) then
            bodyBytes[0]=0x26
            bodyBytes[1]=control["page_choose"]
        --菜谱推荐设置
        elseif(control["receipe_set"]~=nil) then
            bodyBytes[0]=0x29
            bodyBytes[1]=control["totalmenu"]
            bodyBytes[2]=0x01
            bodyBytes[3]=control["totalmenu"]
            local idl={}
            local idl_str=control["receipe_set"]
            idl=string_split(idl_str,",")
            local idlen=#idl
            for i=1,idlen do
                local cloudmenuidn = tonumber(idl[i])
                local idlh = math.modf(cloudmenuidn/(16^4))
                local idlLeft = math.fmod(cloudmenuidn,(16^4))
                local idlc = math.modf(idlLeft/(16^2))
                local idll = math.fmod(idlLeft,(16^2))
                bodyBytes[1+3*i] = idlh
                bodyBytes[2+3*i] = idlc
                bodyBytes[3+3*i] = idll
            end
        --普通工作模式控制
        else
            if(control["work_mode"]~=nil) then
                bodyBytes[0]=0x22
                bodyBytes[1]=0x01
                -- 云菜谱
                if control["cloudmenuid"]~=nil then
                    local cloudmenuidn = tonumber(control["cloudmenuid"])
                    local cloundMenuIdNHH = math.modf(cloudmenuidn/(16^4))
                    local cloundMenuIdNHHLeft = math.fmod(cloudmenuidn,(16^4))

                    local cloundMenuIdNH = math.modf(cloundMenuIdNHHLeft/(16^2))
                    local cloundMenuIdNL = math.fmod(cloundMenuIdNHHLeft,(16^2))

                    bodyBytes[2] = cloundMenuIdNHH
                    bodyBytes[3] = cloundMenuIdNH
                    bodyBytes[4] = cloundMenuIdNL
                    if control["totalstep"]~=nil then
                        bodyBytes[5] = control["totalstep"]
                    else
                        bodyBytes[5] = 0x11
                    end
                    -- return ''
                else
                    bodyBytes[2] = 0x00
                    bodyBytes[3] = 0x00
                    bodyBytes[4] = 0x00
                    bodyBytes[5] = 0x11
                end
                -- bodyBytes[2]=0x00
                -- bodyBytes[3]=0x00
                -- bodyBytes[4]=0x00
                -- bodyBytes[5] = 0x00
                -- bodyBytes[5] = 0x11
                if(control["pre_heat"]~=nil) then
                    if(control["pre_heat"]=="off")then
                        bodyBytes[6] = 0x00
                    elseif(control["pre_heat"]=="on")then
                        bodyBytes[6] = 0x01
                    --elseif(control["probo_mode"]=="2") then
                        --bodyBytes[6] = 0x02
                    end
                else
                    bodyBytes[6] = 0x00
                end
                if(control["work_hour"]~=nil) then
                    bodyBytes[7] = control["work_hour"]
                else
                    bodyBytes[7] =0x00
                end
                if(control["work_minute"]~=nil) then
                    bodyBytes[8] = control["work_minute"]
                else
                    bodyBytes[8] =0x00
                end
                if(control["work_second"]~=nil) then
                    bodyBytes[9] = control["work_second"]
                else
                    bodyBytes[9] =0x00
                end
                bodyBytes[10] = devicetocloud(control)
                if(control["temperature"]~=nil)then
                    bodyBytes[11] = 0x00
                    bodyBytes[12] = control["temperature"]
                else
                    bodyBytes[11] = 0x00
                    bodyBytes[12] = 0x00
                end
                if(control["temperature"]~=nil)then
                    bodyBytes[13] = 0x00
                    bodyBytes[14] = control["temperature"]
                else
                    bodyBytes[13] = 0x00
                    bodyBytes[14] = 0x00
                end
                -- bodyBytes[13] = 0x00
                -- bodyBytes[14] = 0x00
                if(control["fire_power"]~=nil)then
                    bodyBytes[15] = firepower(control)
                else
                    bodyBytes[15]=0xff
                end
                if(control["weight"]~=nil) then
                    bodyBytes[16] = control["weight"]/10
                else
                    bodyBytes[16] = 0xff
                end
                if(control["workend"]==nil) then
                    bodyBytes[17]=0xff
                else
                    bodyBytes[17] = control["workend"]
                end
                if(control["probo_value"]~=nil)then
                    bodyBytes[18] = control["probo_value"]
                else
                    bodyBytes[18] = 0x00
                end
            --童锁/暂停/取消等非烹饪工作控制
            elseif(control["work_status"]~=nil  or control["lock"]~=nil or control["furnace_light"]~=nil ) then
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x02
                bodyBytes[2] = 0xff
                bodyBytes[3] = 0xff
                bodyBytes[4] = 0xff

                if(control["work_status"]=="save_power")then
                    bodyBytes[2]=0x01
                elseif(control["work_status"]=="standby")then
                    bodyBytes[2]=0x02
                elseif(control["work_status"]=="work")then
                    bodyBytes[2]=0x03
                elseif(control["work_status"]=="pause")then
                    bodyBytes[2]=0x06
                end
                if(control["lock"]=="off")then
                    bodyBytes[3]=0x00
                elseif(control["lock"]=="on")then
                    bodyBytes[3]=0x01
                end
                if(control["furnace_light"]=="off") then
                    bodyBytes[4]=0x00
                elseif(control["furnace_light"]=="on")then
                    bodyBytes[4]=0x01
                end
                if(control["camera"]=="off") then
                    bodyBytes[5]=0x00
                elseif(control["camera"]=="on")then
                    bodyBytes[5]=0x01
                end
                if(control["door"]=="close") then
                    bodyBytes[6]=0x00
                elseif(control["door"]=="open")then
                    bodyBytes[6]=0x01
                end
            elseif(control["hour_inc"]~=nil or control["minute_inc"]~=nil or control["second_inc"]~=nil or control["temp_inc"]~=nil) then
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x03
                bodyBytes[2] = 0xff
                bodyBytes[3] = 0xff
                bodyBytes[4] = 0xff
                bodyBytes[5] = 0xff
                bodyBytes[6] = 0xff
                if(control["hour_inc"]~=nil) then
                    bodyBytes[7] = tonumber(control["hour_inc"])
                else
                    bodyBytes[7] = 0xff
                end
                if(control["minute_inc"]~=nil) then
                    bodyBytes[8] = tonumber(control["minute_inc"])
                else
                    bodyBytes[8] = 0xff
                end
                if(control["second_inc"]~=nil) then
                    bodyBytes[9] =tonumber(control["second_inc"])
                else
                    bodyBytes[9] = 0xff
                end
                bodyBytes[10] = 0xff
                bodyBytes[11] = 0xff
                if(control["temp_inc"]~=nil) then
                    bodyBytes[12] = tonumber(control["temp_inc"])
                else
                    bodyBytes[12] = 0xff
                end
                bodyBytes[13] = 0xff
                bodyBytes[14] = 0xff
                bodyBytes[15] = 0xff
                bodyBytes[16] = 0xff
                bodyBytes[17] = 0xff
                bodyBytes[18] = 0xff
            elseif(control["hour_red"]~=nil or control["minute_red"]~=nil or control["second_red"]~=nil or control["temp_red"]~=nil) then
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x05
                bodyBytes[2] = 0xff
                bodyBytes[3] = 0xff
                bodyBytes[4] = 0xff
                bodyBytes[5] = 0xff
                bodyBytes[6] = 0xff
                if(control["hour_red"]~=nil) then
                    bodyBytes[7] = tonumber(control["hour_red"])
                else
                    bodyBytes[7] = 0xff
                end
                if(control["minute_red"]~=nil) then
                    bodyBytes[8] = tonumber(control["minute_red"])
                else
                    bodyBytes[8] = 0xff
                end
                if(control["second_red"]~=nil) then
                    bodyBytes[9] =tonumber(control["second_red"])
                else
                    bodyBytes[9] = 0xff
                end
                bodyBytes[10] = 0xff
                bodyBytes[11] = 0xff
                if(control["temp_red"]~=nil) then
                    bodyBytes[12] = tonumber(control["temp_red"])
                else
                    bodyBytes[12] = 0xff
                end
                bodyBytes[13] = 0xff
                bodyBytes[14] = 0xff
                bodyBytes[15] = 0xff
                bodyBytes[16] = 0xff
                bodyBytes[17] = 0xff
                bodyBytes[18] = 0xff
            elseif(control["hour_set"]~=nil or control["minute_set"]~=nil or control["second_set"]~=nil or control["temp_set"]~=nil) then
                bodyBytes[0] = 0x22
                bodyBytes[1] = 0x04
                bodyBytes[2] = 0xff
                bodyBytes[3] = 0xff
                bodyBytes[4] = 0xff
                bodyBytes[5] = 0xff
                bodyBytes[6] = 0xff
                if(control["hour_set"]~=nil or control["minute_set"]~=nil or control["second_set"]~=nil) then
                    if(control["hour_set"]~=nil) then
                        bodyBytes[7] = tonumber(control["hour_set"])
                    else
                        bodyBytes[7] = 0x00
                    end
                    if(control["minute_set"]~=nil) then
                        bodyBytes[8] = tonumber(control["minute_set"])
                    else
                        bodyBytes[8] = 0x00
                    end

                    if(control["second_set"]~=nil) then
                        bodyBytes[9] =tonumber(control["second_set"])
                    else
                        bodyBytes[9] = 0x00
                    end
                else
                    bodyBytes[7] = 0xff
                    bodyBytes[8] = 0xff
                    bodyBytes[9] = 0xff
                end
                -- bodyBytes[9] = 0x00
                bodyBytes[10] = 0xff
                -- bodyBytes[10] = devicetocloud(control)
                -- bodyBytes[11] = 0xff
                if(control["temp_set"]~=nil) then
                    bodyBytes[11] = 0x00
                    bodyBytes[12] = tonumber(control["temp_set"])
                else
                    bodyBytes[11] = 0xff
                    bodyBytes[12] = 0xff
                end
                bodyBytes[13] = 0xff
                bodyBytes[14] = 0xff
                bodyBytes[15] = 0xff
                bodyBytes[16] = 0xff
                bodyBytes[17] = 0xff
                bodyBytes[18] = 0xff
            end
        end
        msgBytes = assembleUart(bodyBytes, BYTE_CONTROL_REQUEST)
        --将原始状态 转换为属性
        -- if (status) then
        --     devicetocloud(status)
        -- end
        -- msgBytes = assembleUart(bodyBytes, uptable["BYTE_CONTROL_REQUEST"])
    --查询指令
    elseif (query) then
        --构造消息 body 部分
        local bodyLength = 2
        local bodyBytes = {}
        if(query["query_type"]=="31") then
            bodyBytes[0]=0x31
        elseif(query["query_type"]=="32")then
            bodyBytes[0]=0x32
        elseif(query["query_type"]=="33")then
            bodyBytes[0]=0x33
        elseif(query["query_type"]=="34")then
            bodyBytes[0]=0x34
        elseif(query["query_type"]=="35")then
            bodyBytes[0]=0x35
        else
            bodyBytes[0]=0x31
        end

        for i = 1, bodyLength - 1 do
            bodyBytes[i] = 0x00
        end
        msgBytes = assembleUart(bodyBytes, BYTE_QUERY_REQUEST)
    end

    --lua table 索引从 1 开始，因此此处要重新转换一次
    local infoM = {}

    local length = #msgBytes + 1

    for i = 1, length do
        infoM[i] = msgBytes[i - 1]
    end

    --table 转换成 string 之后返回
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
--从设备发出的AA指令获取profile中对应的工作模式
function getmodetype(meg)
    local modetype
    -- 下面中文部分为协议中文解释，与APP功能中文兼容
    if(meg=="01") then
        modetype="microwave" -- 普通微波 / 微波
    elseif(meg=="02") then
        modetype="brittle"  -- 复脆
    elseif(meg=="20") then
        modetype="pure_steam" -- 蒸汽 / 纯蒸汽
    elseif(meg=="21") then
        modetype="hot_steam" -- 高温蒸气 / 脱脂减盐
    elseif(meg=="40") then
        modetype="above_tube" -- 烧烤 / 上外烧烤 /普通烧烤
    elseif(meg=="41") then
        modetype="hot_wind_bake" -- 热风对流
    elseif(meg=="42") then
        modetype="underside_tube_hot_wind_bake" -- 底部烧烤+热风对流
    elseif(meg=="44") then
        modetype="cube_baking"  -- 立体烧烤
    elseif(meg=="46") then
        modetype="core_baking" -- 中心烧烤/(上内(红外)烧烤 + 上外烧烤)
    elseif(meg=="47") then
        modetype="total_baking" -- 全烧烤/上内(红外)烧烤 /红外烧烤
    elseif(meg=="49") then
        modetype="underside_tube" -- 底部烧烤/下管烧烤
    elseif(meg=="4C" or meg=="4c") then
        modetype="double_tube" -- 上下烧烤
    elseif(meg=="4E" or meg=="4e") then
        modetype="revolve_bake" -- 旋转烧烤
    elseif(meg=="51") then
        modetype="double_upside_tube_fan" -- 上内(红外)+上外+风扇
    elseif(meg=="52") then
        modetype="double_tube_fan" -- 上下烧烤 + 风扇
    elseif(meg=="70") then
        modetype="fast_baking"  -- 微波 + 烧烤 / 微波 + 上外烧烤 /微波 +普通烧烤/ 变频烧烤 / 变频快烤？
    elseif(meg=="90") then
        modetype="fast_steam" -- 微波 + 蒸汽 / 快蒸
    elseif(meg=="A0" or meg=="a0") then
        modetype="unfreeze" -- 按重解冻
    elseif(meg=="A1" or meg=="a1") then
        modetype="unfreeze_t"
    elseif(meg=="B0" or meg=="b0") then
        modetype="zymosis" -- 发酵
    elseif(meg=="C0" or meg=="c0") then
        modetype="smart_clean" -- 高温自清洁
    elseif(meg=="C1" or meg=="c1") then
        modetype="scale_clean"   -- 锅炉除垢/清洁
    elseif(meg=="C2" or meg=="c2") then
        modetype="metal_sterilize" -- 金属杀菌
    elseif(meg=="C3" or meg=="c3") then
        modetype="remove_odor" -- 除味
    elseif(meg=="C4" or meg=="c4") then
        modetype="dry"  -- 烘干/干燥
    elseif(meg=="D0" or meg=="d0") then
        modetype="warm"  -- 保温
    elseif(meg=="E0" or meg=="e0") then
        modetype="auto_menu"  -- 普通菜单
    end
    return modetype
end

function getbytebit(bytes,bitIndex)
    local bytes_high=tonumber(string.sub(bytes,1,1),16)
    local bytes_low=tonumber(string.sub(bytes,2,2),16)
    if bitIndex>3  and bitIndex < 8 then
        if bitIndex == 7 then
            if bit.band(bytes_high,8)==8 then
                return '1'
            end
        elseif bitIndex == 6 then
            if bit.band(bytes_high,4)==4 then
                return '1'
            end
        elseif bitIndex == 5 then
            if bit.band(bytes_high,2)==2 then
                return '1'
            end
        elseif bitIndex == 4 then
            if bit.band(bytes_high,1)==1 then
                return '1'
            end
        end
        return '0'
    elseif bitIndex >= 0 and bitIndex <=3 then
        if bitIndex == 3 then
            if bit.band(bytes_low,8)==8 then
                return '1'
            end
        elseif bitIndex == 2 then
            if bit.band(bytes_low,4)==4 then
                return '1'
            end
        elseif bitIndex == 1 then
            if bit.band(bytes_low,2)==2 then
                return '1'
            end
        elseif bitIndex == 0 then
            if bit.band(bytes_low,1)==1 then
                return '1'
            end
        end
        return '0'
    end

    return '2'
end
--解析设备上报的指令，对应到profile文件中的属性值
function cloudtodevice(megBodys)
    local jsonTable={}
    jsonTable["version"]=VALUE_VERSION
    if (megBodys[9]=="02") then
        if (megBodys[10]=="22") then
            if (megBodys[11]=="01") then
                jsonTable["cloudmenuid"]=tonumber(megBodys[12],16)*(16^4)+ tonumber(megBodys[13],16)*(16^2)+ tonumber(megBodys[14],16)
                jsonTable["totalstep"]=math.modf(tonumber(megBodys[15],16)/16)
                jsonTable["stepnum"]=math.fmod(tonumber(megBodys[15],16),16)
                if tonumber(megBodys[16],16)=="0" then
                    jsonTable["pre_heat"]="off"
                elseif tonumber(megBodys[16],16)=="1" then
                    jsonTable["pre_heat"]="on"
                end
                jsonTable["work_hour"]=tonumber(megBodys[17],16)
                jsonTable["work_minute"]=tonumber(megBodys[18],16)
                jsonTable["work_second"]=tonumber(megBodys[19],16)
                jsonTable["work_mode"]= getmodetype(megBodys[20])
                jsonTable["temperature"]= tonumber(megBodys[22],16)
                -- jsonTable["temperature"]= tonumber(megBodys[24],16)
                -- jsonTable["cur_temperature_underside"]= getmodetype(megBodys[22])

                -- if(megBodys[16]~="FF" and megBodys[16]~="ff")then
                --     jsonTable["probo_mode"]=tonumber(megBodys[16],16)
                -- end
                -- if(megBodys[17]~="FF" and megBodys[17]~="ff")then
                --     jsonTable["work_hour"]=tonumber(megBodys[17],16)
                -- end
                -- if(megBodys[18]~="FF" and megBodys[18]~="ff")then
                --     jsonTable["work_minute"]=tonumber(megBodys[18],16)
                -- end
                -- if(megBodys[19]~="FF" and megBodys[19]~="ff")then
                --     jsonTable["work_second"]=tonumber(megBodys[19],16)
                -- end
                -- if(megBodys[20]~="FF" and megBodys[20]~="ff") then
                --     jsonTable["work_mode"]= getmodetype(megBodys[20])
                -- end
                -- if(megBodys[22]~="FF" and megBodys[22]~="ff") then
                --     jsonTable["cur_temperature_above"]= getmodetype(megBodys[21])
                -- end
                -- if(megBodys[24]~="FF" and megBodys[24]~="ff") then
                --     jsonTable["cur_temperature_underside"]= getmodetype(megBodys[22])
                -- end
                -- if(megBodys[25]~="FF" and megBodys[25]~="ff")then
                --     jsonTable["fire_power"]=tonumber(megBodys[25],16)
                -- end
                if(megBodys[25]~="FF" and megBodys[25]~="ff" and megBodys[25]~="00")then
                    jsonTable["fire_power"]=getfirepowertype(megBodys[25])
                end
                if(megBodys[26]~="FF" and megBodys[26]~="ff")then
                    jsonTable["weight"]=tonumber(megBodys[26],16)*10
                end
                if(megBodys[27]~="FF" and megBodys[27]~="ff")then
                    jsonTable["workend"]=tonumber(megBodys[27],16)
                end
                if(megBodys[28]~="FF" and megBodys[28]~="ff")then
                    jsonTable["probo_value"]=tonumber(megBodys[28],16)
                end
            elseif(megBodys[11]=="02") then
                if(megBodys[12]=="01") then
                    -- jsonTable["power"]="off"
                    jsonTable["work_status"]="save_power"
                elseif(megBodys[12]=="02") then
                    -- jsonTable["power"]="on"
                    jsonTable["work_status"]="standby"
                elseif(megBodys[12]=="03") then
                    jsonTable["work_status"]="work"
                elseif(megBodys[12]=="06") then
                    jsonTable["work_status"]="pause"
                end

                if(megBodys[13]=="00") then
                    jsonTable["lock"]="off"
                elseif(megBodys[13]=="01") then
                    jsonTable["lock"]="on"
                end

                if(megBodys[14]=="00") then
                    jsonTable["furnace_light"]="off"
                elseif(megBodys[14]=="01") then
                    jsonTable["furnace_light"]="on"
                end

            elseif(megBodys[11]=="03") then
                if(megBodys[18]~="FF" or megBodys[18]~="ff") then
                    jsonTable["minutes_inc"]=tonumber(megBodys[18],16)
                end
                if(megBodys[19]~="ff" or megBodys[19]~="FF") then
                    jsonTable["second_inc"]=tonumber(megBodys[19],16)
                end
            -- 仅针对错误时的上行
            elseif(megBodys[11]=="FE" or megBodys[11]=="fe") then
            -- if(megBodys[11]=="FE" or megBodys[11]=="fe") then
                jsonTable["fail_resp_reason"]=tonumber(megBodys[13],16)
            end
        elseif(megBodys[10]=="23") then
            jsonTable["year"]=tonumber(megBodys[11],16)+2000
            jsonTable["month"]=tonumber(megBodys[12],16)
            jsonTable["day"]=tonumber(megBodys[13],16)
            jsonTable["work_hour"]=tonumber(megBodys[14],16)
            jsonTable["work_minute"]=tonumber(megBodys[15],16)
            jsonTable["work_second"]=tonumber(megBodys[16],16)
            jsonTable["week"]=tonumber(megBodys[17],16)
        elseif(megBodys[10]=="24") then
            jsonTable["reservation"]=tonumber(megBodys[11],16)
            jsonTable["pre_hour"]=tonumber(megBodys[12],16)
            jsonTable["pre_minutes"]=tonumber(megBodys[13],16)
            jsonTable["pre_second"]=tonumber(megBodys[14],16)
            jsonTable["cloudmenuid"]=tonumber(megBodys[15],16)*(16^4)+ tonumber(megBodys[16],16)*(16^2)+ tonumber(megBodys[17],16)
            jsonTable["totalstep"]=math.modf(tonumber(megBodys[18],16)/16)
            jsonTable["stepnum"]=math.fmod(tonumber(megBodys[18],16),16)
            if(megBodys[19]~="FF" and megBodys[19]~="ff")then
                if tonumber(megBodys[19],16)=="0" then
                    jsonTable["pre_heat"]="off"
                elseif tonumber(megBodys[19],16)=="1" then
                    jsonTable["pre_heat"]="on"
                end
            end
            if(megBodys[20]~="FF" and megBodys[20]~="ff")then
                jsonTable["work_hour"]=tonumber(megBodys[20],16)
            end
            if(megBodys[21]~="FF" and megBodys[21]~="ff")then
                jsonTable["work_minute"]=tonumber(megBodys[21],16)
            end
            if(megBodys[22]~="FF" and megBodys[22]~="ff")then
                jsonTable["work_second"]=tonumber(megBodys[22],16)
            end
            if(megBodys[23]~="FF" and megBodys[23]~="ff") then
                jsonTable["work_mode"]= getmodetype(megBodys[23])
            end
            if(megBodys[25]~="FF" and megBodys[25]~="ff") then
                jsonTable["temperature"]= getmodetype(megBodys[25])
            end
            if(megBodys[27]~="FF" and megBodys[27]~="ff") then
                jsonTable["temperature"]= getmodetype(megBodys[27])
            end
            -- if(megBodys[28]~="FF" and megBodys[28]~="ff")then
            --     jsonTable["fire_power"]=tonumber(megBodys[28],16)
            -- end
            if(megBodys[28]~="FF" and megBodys[28]~="ff" and megBodys[28]~="00")then
                    jsonTable["fire_power"]=getfirepowertype(megBodys[28])
                end
            if(megBodys[29]~="FF" and megBodys[29]~="ff")then
                jsonTable["weight"]=tonumber(megBodys[29],16)*10
            end
            if(megBodys[30]~="FF" and megBodys[30]~="ff")then
                jsonTable["workend"]=tonumber(megBodys[30],16)
            end
            if(megBodys[31]~="FF" and megBodys[31]~="ff")then
                jsonTable["probo_value"]=tonumber(megBodys[31],16)
            end
        elseif(megBodys[10]==0x26) then
            jsonTable["page_choose"]=tonumber(megBodys[11],16)
        elseif(megBodys[10]==0x29) then
            jsonTable["receipe_set_value"]=tonumber(megBodys[11],16)
        end
    elseif (megBodys[9]=="03" or megBodys[9]=="04") then
    -- if (megBodys[9]=="03" or megBodys[9]=="04") then
        if(megBodys[11]=="01") then
            -- jsonTable["power"]="off"
            jsonTable["work_status"]="save_power"
        elseif(megBodys[11]=="02") then
            -- jsonTable["power"]="on"
            jsonTable["work_status"]="standby"
        elseif(megBodys[11]=="03") then
            jsonTable["work_status"]="work"
        elseif(megBodys[11]=="04") then
            jsonTable["work_status"]="work_finish"
        elseif(megBodys[11]=="05") then
            jsonTable["work_status"]="order"
        elseif(megBodys[11]=="06") then
            jsonTable["work_status"]="pause"
        elseif(megBodys[11]=="07") then
            jsonTable["work_status"]="pause_c"
        elseif(megBodys[11]=="08") then
            jsonTable["work_status"]="three"
        end
        jsonTable["cloudmenuid"]=tonumber(megBodys[12],16)*(16^4)+ tonumber(megBodys[13],16)*(16^2)+ tonumber(megBodys[14],16)
        jsonTable["totalstep"]=math.modf(tonumber(megBodys[15],16)/16)
        jsonTable["stepnum"]=math.fmod(tonumber(megBodys[15],16),16)
        if(megBodys[16]~="FF" and megBodys[16]~="ff")then
            jsonTable["work_hour"]=tonumber(megBodys[16],16)
        end
        if(megBodys[17]~="FF" and megBodys[17]~="ff")then
            jsonTable["work_minute"]=tonumber(megBodys[17],16)
        end
        if(megBodys[18]~="FF" and megBodys[18]~="ff")then
            jsonTable["work_second"]=tonumber(megBodys[18],16)
        end
        if(megBodys[19]~="FF" and megBodys[19]~="ff") then
            jsonTable["work_mode"]= getmodetype(megBodys[19])
        end
        if(megBodys[21]~="FF" and megBodys[21]~="ff") then
            jsonTable["cur_temperature_above"]= tonumber(megBodys[21],16)
        end
        if(megBodys[23]~="FF" and megBodys[23]~="ff") then
            jsonTable["cur_temperature_underside"]= tonumber(megBodys[23],16)
        end
        -- if(megBodys[24]~="FF" and megBodys[24]~="ff")then
        --     jsonTable["fire_power"]=tonumber(megBodys[24],16)
        -- end
        if(megBodys[24]~="FF" and megBodys[24]~="ff" and megBodys[24]~="00")then
                    jsonTable["fire_power"]=getfirepowertype(megBodys[24])
        end
        if(megBodys[25]~="FF" and megBodys[25]~="ff")then
            jsonTable["weight"]=tonumber(megBodys[25],16)*10
        end
        local b26=megBodys[26]
        local b27=megBodys[27]
        local lock=getbytebit(b26,0)
        if (lock=="1") then
            jsonTable["lock"]="on"
        elseif(lock=="0")then
            jsonTable["lock"]="off"
        end
        local door=getbytebit(b26,1)
        if (door=="1") then
            jsonTable["door_open"]="on"
        elseif(door=="0")then
            jsonTable["door_open"]="off"
        end
        local water_box=getbytebit(b26,2)
        local water_state=getbytebit(b26,3)
        local changewater=getbytebit(b26,4)
        local preheat=getbytebit(b26,5)
        local preheatvalue=getbytebit(b26,6)
        local error_code=getbytebit(b26,7)
        local fanmian=getbytebit(b27,0)
        local ganying=getbytebit(b27,1)
        local ludeng=getbytebit(b27,2)
        local tanzhen=getbytebit(b27,6)

        if(water_box=="1") then
            jsonTable["tips_code"]=6
        end
        if(water_state=="1")then
            jsonTable["tips_code"]=2
        end
        if(changewater=="1")then
            jsonTable["tips_code"]=7
        end
        if(preheat=="1")then
            jsonTable["tips_code"]=8
        end
        if(preheatvalue=="1")then
            jsonTable["tips_code"]=9
        end
        if(error_code=="1")then
            jsonTable["error_code"]=1
        end
        if(fanmian=="1")then
            jsonTable["tips_code"]=4
        end
        if(ganying=="1")then
            jsonTable["work_status"]="reaction"
        end
        if(ludeng=="1")then
            jsonTable["furnace_light"]="on"
        elseif(ludeng=="0")then
            jsonTable["furnace_light"]="off"
        end
        if(tanzhen=="1")then
            jsonTable["probo_on"]=1
        elseif(tanzhen=="0")then
            jsonTable["probo_on"]=0
        end
        if(megBodys[29]~="FF" and megBodys[29]~="ff") then
            jsonTable["temperature"]= tonumber(megBodys[29],16)
        end
        -- if(megBodys[31]~="FF" and megBodys[31]~="ff") then
        --     jsonTable["temperature"]= tonumber(megBodys[31],16)
        -- end
        -- if(megBodys[32]~="FF" and megBodys[32]~="ff") then
        --     jsonTable["probo_real_value"]= tonumber(megBodys[32],16)
        -- end
        -- if(megBodys[33]~="FF" and megBodys[33]~="ff") then
        --     jsonTable["probo_value"]= tonumber(megBodys[33],16)
        -- end
    end

    return jsonTable
end

--二进制转json
function dataToJson(jsonStr)
    if (not jsonStr) then
        return nil
    end

    local json = decodeJsonToTable(jsonStr)

    local deviceinfo = json["deviceinfo"]

    --根据设备子类型来处理协议差异
    local deviceSubType = deviceinfo["deviceSubType"]
    if (deviceSubType == 1) then
    end

    local binData = json["msg"]["data"]
    local status = json["status"]
    local retTable = {}
    retTable["status"]={}
    -- if (status) then
    --    retTable["status"] = status
    -- end


    --包括Uart头
    local bodyBytes = string2table(binData)
    --将二进制状态解析为属性值
    retTable["status"] = cloudtodevice(bodyBytes)
    local ret = encodeTableToJson(retTable)
    return ret
end



---------------公共的函数---------------
-- 1.将bodyBytes 组装上Uart头部信息和尾部校验码。
-- 2.传入的 bodyBytes 为索引从0开始。
-- 3.返回的 table 索引也从0开始。
function assembleUart(bodyBytes, type)
    local bodyLength = #bodyBytes + 1
    if bodyLength == 0 then
        return nil
    end
    -- print("a")
    local msgLength = (bodyLength + BYTE_PROTOCOL_LENGTH + 1)
    local msgBytes = {}
    for i = 0, msgLength - 1 do
        msgBytes[i] = 0
    end
    --构造消息部分
    msgBytes[0] = BYTE_PROTOCOL_HEAD
    msgBytes[1] = msgLength - 1
    msgBytes[2] = BYTE_DEVICE_TYPE
    msgBytes[7] = BYTE_PROTOCOL_VERSION
    msgBytes[8] = 0x00
    msgBytes[9] = type
    for i = 0, bodyLength - 1 do
        msgBytes[i + BYTE_PROTOCOL_LENGTH] = bodyBytes[i]
        -- print("bodyBytes["..i.."]:".. bodyBytes[i])
        -- print("msgBytes["..i + BYTE_PROTOCOL_LENGTH.."]:"..msgBytes[i + BYTE_PROTOCOL_LENGTH])

    end
    msgBytes[msgLength - 1] = makeSum(msgBytes,msgLength - 1)

    return msgBytes
end

--sum校验
function makeSum(tmpbuf, msgLenByteNumber)
    local resVal = 0
    for si=1, (msgLenByteNumber-1) do
        resVal = resVal+tmpbuf[si]
    end
    resVal=bit.bnot(resVal)
    resVal=bit.band(resVal,0x000000FF)
    resVal=resVal+1
    resVal=math.fmod(resVal,256)
    return resVal
end

--CRC表
local crc8_854_table =
{
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65,
    157, 195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220,
    35, 125, 159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98,
    190, 224, 2, 92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255,
    70, 24, 250, 164, 39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7,
    219, 133, 103, 57, 186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154,
    101, 59, 217, 135, 4, 90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36,
    248, 166, 68, 26, 153, 199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185,
    140, 210, 48, 110, 237, 179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205,
    17, 79, 173, 243, 112, 46, 204, 146, 211, 141, 111, 49, 178, 236, 14, 80,
    175, 241, 19, 77, 206, 144, 114, 44, 109, 51, 209, 143, 12, 82, 176, 238,
    50, 108, 142, 208, 83, 13, 239, 177, 240, 174, 76, 18, 145, 207, 45, 115,
    202, 148, 118, 40, 171, 245, 23, 73, 8, 86, 180, 234, 105, 55, 213, 139,
    87, 9, 235, 181, 54, 104, 138, 212, 149, 203, 41, 119, 244, 170, 72, 22,
    233, 183, 85, 11, 136, 214, 52, 106, 43, 117, 151, 201, 74, 20, 246, 168,
    116, 42, 200, 150, 21, 75, 169, 247, 182, 232, 10, 84, 215, 137, 107, 53
}

--CRC校验
function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0

    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end

    return crc
end

--将json字符串转换为 lua中的table
function decodeJsonToTable(cmd)
    local tb

    if JSON == nil then
        JSON = require "cjson"
    end

    tb = JSON.decode(cmd)

    return tb
end

--将lua中的table 转换为json字符串
function encodeTableToJson(luaTable)
    local jsonStr


    if JSON == nil then
        JSON = require "cjson"
    end

    jsonStr = JSON.encode(luaTable)

    return jsonStr
end

--十六进制 string 转 table
function string2table(hexstr)
    local tb = {}
    local i = 1
    local j = 0

    for i = 1, #hexstr - 1, 2 do
        local doublebytestr = string.sub(hexstr, i, i + 1)
        tb[j] = doublebytestr
        j = j + 1
    end

    return tb
end

--十六进制 string 输出
function string2hexstring(str)
    local ret = ""

    for i = 1, #str do
        ret = ret .. string.format("%02x", str:byte(i))
    end

    return ret
end

--table 转 string
function table2string(cmd)
    local ret = ""
    local i

    for i = 1, #cmd do
        ret = ret .. string.char(cmd[i])
    end

    return ret
end

--检查data的值是否超过边界
function checkBoundary(data, min, max)
    if (not data) then
        data = 0
    end

    data = tonumber(data)

    if ((data >= min) and (data <= max)) then
        return data
    else
        if (data < min) then
            return min
        else
            return max
        end
    end
end

--String转int
function string2Int(data)
	if (not data) then
        data = tonumber("0")
    end
    data = tonumber(data)
    if(data == nil) then
        data = 0
    end
	return data
end

--int转String
function int2String(data)
	if (not data) then
        data = tostring(0)
    end
    data = tostring(data)
    if(data == nil) then
        data = "0"
    end
	return data
end

--打印 table 表
function print_lua_table(lua_table, indent)
    indent = indent or 0

    for k, v in pairs(lua_table) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end

        local szSuffix = ""

        if type(v) == "table" then
            szSuffix = "{"
        end

        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix

        if type(v) == "table" then
            print(formatting)

            print_lua_table(v, indent + 1)

            print(szPrefix .. "},")
        else
            local szValue = ""

            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end

            print(formatting .. szValue .. ",")
        end
    end
end





-- local  t2 = "{\"deviceinfo\":{\"deviceSubType\":1},\"status\":{},\"msg\":{\"data\":\"AA22B40000000000000341022304084202010201000000000302030100000000000061\"}}"
-- print(dataToJson(t2))
-- local  t2 = "{\"deviceinfo\":{\"deviceSubType\":1},\"status\":{},\"msg\":{\"data\":\"AA1DB4A9000000000102220100000011000024004000960000FFFFFF0058\"}}"
-- print(dataToJson(t2))

-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_mode":"zymosis","temperature":"32","work_minute":"40"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"receipe_set":"1818,1819,1820,1821,1822","totalmenu":"5"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"year":"2017","month":"12","day":"11","hour":"11","minutes":"32","second":"55","week":"4"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"reservation":"01","weight":"200","mode":"microwave","hour":"11","minutes":"32","second":"55","pre_hour":"12","pre_minutes":"55","pre_second":"22"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"page_choose":"5"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"power":"off","work_status":"cancel","lock":"off","furnace_light":"off"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"second_inc":"5","minutes_inc":"9","temp_inc":"200"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"temp_inc":"220"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"query":{"query_type":"31"}}]]
-- print(t)
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_mode":"pure_steam","temperature":"250","work_minute":"100","work_hour":"2"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"hour_set":"7","minute_set":"25"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_mode":"auto_menu","cloudmenuid":"20","work_minute":"1","work_second":"59"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_mode":"microwave","work_second":"11","fire_power":"high_power"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"temp_set":"235"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_mode":"unfreeze","weight":"101"}}]]
-- local t=[[{"deviceinfo": {"deviceType": 172, "deviceSubType": 1, "deviceID": "17592186984567"},"control":{"work_status":"save_power"}}]]
-- print(jsonToData(t))
