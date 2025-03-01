local VORPcore = exports.vorp_core:GetCore()
local BccUtils = exports['bcc-utils'].initiate()
local progressbar = exports.vorp_progressbar:initiate()

local Choppedlumber = {}
local ChoppedlumberProps = false
local Distance = 11
local Chopped = false

local Toolout = false
local ToolId = nil
local CurrentItem = nil
local CurrentItemMaxUses = nil
local InTown = false
local TownName = nil

-- Axe out

RegisterNetEvent('mms-lumberjack:client:ToolOut')
AddEventHandler('mms-lumberjack:client:ToolOut',function(ItemId,UsedItem,MaxUses)
    ToolId = ItemId
    CurrentItem = UsedItem
    CurrentItemMaxUses = MaxUses
    MyPed = PlayerPedId()
    if not Toolout then
        Wait(500)
        Tool = CreateObject(Config.ToolHash, GetOffsetFromEntityInWorldCoords(MyPed, 0.0, 0.0, 0.0), true, true, true)
        AttachEntityToEntity(Tool, MyPed, GetPedBoneIndex(MyPed, 7966), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0, 0, 2, 1, 0, 0)
        Citizen.InvokeNative(0x923583741DC87BCE, MyPed, 'arthur_healthy')
        Citizen.InvokeNative(0x89F5E7ADECCCB49C, MyPed, "carry_pitchfork")
        Citizen.InvokeNative(0x2208438012482A1A, MyPed, true, true)
        ForceEntityAiAndAnimationUpdate(Tool, 1)
        Citizen.InvokeNative(0x3A50753042B6891B, MyPed, "PITCH_FORKS")
        Toolout = true
    elseif Toolout then
        Wait(500)
        DeleteObject(Tool)
        Citizen.InvokeNative(0x923583741DC87BCE, MyPed, 'arthur_healthy')
        Citizen.InvokeNative(0x2208438012482A1A, MyPed, false, false)
        Citizen.InvokeNative(0x58F7DB5BD8FA2288, PlayerPedId())
        ClearPedTasks(MyPed)
        Toolout = false
    end
end)

-- RepairTool

RegisterNetEvent('mms-lumberjack:client:RepairTool')
AddEventHandler('mms-lumberjack:client:RepairTool',function()
    if Toolout then
        TriggerServerEvent('mms-lumberjack:server:RepairTool',ToolId,CurrentItemMaxUses)
        Progressbar(Config.RepairTime * 1000 ,_U('RepairingTool'))
    else
        VORPcore.NotifyTip(_U('NoToolInHand'),5000)
    end
end)

--- Get New ToolID

RegisterNetEvent('mms-lumberjack:client:UpdateItemId')
AddEventHandler('mms-lumberjack:client:UpdateItemId',function(NewToolId)
    ToolId = NewToolId
end)

-- Main Thred

Citizen.CreateThread(function ()
    local ChoplumberPrompt = BccUtils.Prompts:SetupPromptGroup()
    local Choplumber = ChoplumberPrompt:RegisterPrompt(_U('Chop'), 0x760A9C6F, 1, 1, true, 'hold', {timedeventhash = 'MEDIUM_TIMED_EVENT'})
while true do
    Citizen.Wait(1500)

    while Toolout do
        Wait(3)
        Chopped = false
        local sleep = true
        local PlayerCoords = GetEntityCoords(PlayerPedId())
        for h,v in ipairs(Config.LumberProps) do
            local Foundlumber = Citizen.InvokeNative(0xBFA48E2FF417213F, PlayerCoords.x, PlayerCoords.y, PlayerCoords.z, 1.5,
            GetHashKey(v.Prop), 0)
            if Foundlumber then
                Closelumber = Foundlumber
            end
        end
        for h,v in ipairs(Choppedlumber) do
            Distance = #(v - PlayerCoords)
            if Distance < 5 then
                Chopped = true
            end
        end
        if Closelumber and not Chopped then
            sleep = false
            ChoplumberPrompt:ShowGroup(_U('Tree'))
            
            if Choplumber:HasCompleted() then
                if not InTown then
                    Wait(200)
                    Choppedlumber[#Choppedlumber + 1] = PlayerCoords
                    ChoppedlumberProps = true
                    Choplumber:TogglePrompt(false)
                    Wait(200)
                    Choplumber:TogglePrompt(true)
                    TriggerEvent('mms-lumberjack:client:Choplumber',ToolId)
                else
                    VORPcore.NotifyTip(_U('InHere') .. TownName .. _U('YouCantChop'),5000)
                end
            end
            Chopped = false
        end
        Closelumber = false
        if sleep then
            Wait(200)
        end
    end
end
end)

-- Getting lumber

RegisterNetEvent('mms-lumberjack:client:Choplumber')
AddEventHandler('mms-lumberjack:client:Choplumber',function(ToolId)
    Citizen.Wait(100)
    local MyPed = PlayerPedId()
    Anim(MyPed, "amb_work@world_human_tree_chop_new@working@pre_swing@male_a@trans", "pre_swing_trans_after_swing",
    -1, 7)
    Progressbar(Config.ChopTime,_U('WorkingHere'))
    TriggerServerEvent('mms-lumberjack:server:FinishChoppinglumber',ToolId,CurrentItem,CurrentItemMaxUses)
end)

--- Refresh Them

Citizen.CreateThread(function()
    while not ChoppedlumberProps do
        Citizen.Wait(5000)
        if ChoppedlumberProps then
            while true do
                Citizen.Wait(Config.ResetLumberTimer * 60000)
                for i, v in ipairs(Choppedlumber) do  -- Tabelle leeren
                    Choppedlumber[i] = nil
                    ChoppedlumberProps = false
                end
            end
        end
    end
end)

--- In Town Check

RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Citizen.Wait(10000)
    if Config.TownRestriction then
        TriggerEvent('mms-lumberjack:client:TownCheck')
    end
end)

RegisterNetEvent('mms-lumberjack:client:TownCheck')
AddEventHandler('mms-lumberjack:client:TownCheck',function()
    while true do
        local CloseTown = 0
        Citizen.Wait(3000)
        local MyCoords = GetEntityCoords(PlayerPedId())
        for h,v in ipairs(Config.Towns) do
            local Distance = #(MyCoords - v.Town)
            if Distance <= v.TownDistance then
                CloseTown = 1
                TownName = v.TownName
            end
        end
        if CloseTown > 0 then
            InTown = true
        elseif CloseTown == 0 then
            InTown = false
        end
    end
end)

if Config.Debug then
    Citizen.Wait(2000)
    TriggerEvent('mms-lumberjack:client:TownCheck')
end

----------------- Utilities -----------------


------ Progressbar

function Progressbar(Time,Text)
    progressbar.start(Text, Time, function ()
    end, 'linear')
    Wait(Time)
    ClearPedTasks(PlayerPedId())
end

------ Animation

function CrouchAnim()
    local dict = "script_rc@cldn@ig@rsc2_ig1_questionshopkeeper"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
    local MyPed = PlayerPedId()
    local coords = GetEntityCoords(MyPed)
    TaskPlayAnim(MyPed, dict, "inspectfloor_player", 0.5, 8.0, -1, 1, 0, false, false, false)
end

function Anim(actor, dict, body, duration, flags, introtiming, exittiming)
    Citizen.CreateThread(function()
        RequestAnimDict(dict)
        local dur = duration or -1
        local flag = flags or 1
        local intro = tonumber(introtiming) or 1.0
        local exit = tonumber(exittiming) or 1.0
        timeout = 5
        while (not HasAnimDictLoaded(dict) and timeout > 0) do
            timeout = timeout - 1
            if timeout == 0 then
                print("Animation Failed to Load")
            end
            Citizen.Wait(300)
        end
        TaskPlayAnim(actor, dict, body, intro, exit, dur, flag --[[1 for repeat--]], 1, false, false, false, 0, true)
    end)
end