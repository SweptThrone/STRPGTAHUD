--[[
    SweptRP HUD / GTA Online HUD
    by SweptThrone
    Contact: https://sweptthr.one/contact

    Made for DarkRP.  Unknown support in anything else.

    This HUD shows:
        - Health bar (no number), flashes when low
        - Armor bar (no number)
        - Hunger bar (no number)
        - Player name and job
        - Player money and salary
        - Weapon ammo bar (no number), flashes when low
        - Weapon reserve ammo and ammo type
        - Lockdown border
        - Agenda window
        - Wanted icon
        - License icon
        - STGarbageCollector held garbage icon (hidden if you have none (if the addon is not installed))

    This HUD manually implements DarkRP's default notify system.
    DarkRP's notify code has not changed since April 30, 2022 as of May 14, 2023.
]]--

hook.Remove( "ScoreboardShow", "FAdmin_scoreboard" )
hook.Remove( "ScoreboardHide", "FAdmin_scoreboard" )
concommand.Remove( "+FAdmin_menu" )
concommand.Remove( "-FAdmin_menu" )

local plyMeta = FindMetaTable( "Player" )
function plyMeta:drawWantedInfo()
    return false
end
function plyMeta:drawPlayerInfo()
    return false 
end

local hideHUD = {
    [ "CHudHealth" ] = true,
    [ "CHudBattery" ] = true,
    [ "CHudSuitPower" ] = true,
    [ "CHudAmmo" ] = true,
    [ "DarkRP_Hungermod" ] = true,
    [ "DarkRP_LocalPlayerHUD" ] = true,
    [ "DarkRP_LockdownHUD" ] = true,
    [ "DarkRP_ArrestedHUD" ] = true,
    [ "DarkRP_ChatReceivers" ] = true
}

hook.Add("HUDShouldDraw", "HideDefaultDarkRPHud", function(name)
    return not hideHUD[ name ]
end)

surface.CreateFont( "SweptRP6HUD", {
	font = "Roboto",
	size = 18,
    weight = 2000
})

surface.CreateFont( "SweptRP6Lockdown", {
	font = "coolvetica",
	size = 36,
    weight = 2000
})

local HP_COLOR = Color( 84, 156, 84 )
local HP_COLOR_BG = Color( 42, 78, 42 )
local AP_COLOR = Color( 72, 160, 212 )
local AP_COLOR_BG = Color( 36, 80, 106 )
local LOW_COLOR = Color( 162, 30, 30 )
local LOW_COLOR_BG = Color( 81, 15, 15 )
local HUNGER_COLOR = Color( 178, 170, 32 )
local HUNGER_COLOR_BG = Color( 89, 85, 16 )
local AMMO_COLOR = Color( 255, 255, 255 )
local AMMO_COLOR_BG = Color( 127, 127, 127 )
local AIR_COLOR = Color( 125, 156, 169 )
local AIR_COLOR_BG = Color( 71, 95, 106 )

local licenseMat = Material( "icon16/page_white_text.png" )
local wantedMat = Material( "icon16/exclamation.png" )
local trashMat = Material( "icon16/bin.png" )
local jailMat = Material( "icon16/lock.png" )

local jailTimer = 0

local ammoTypeLookups = {
    "Assault Ammo",
    "ar2alt",
    "Pistol Ammo",
    "SMG Ammo",
    "Heavy Pistol Ammo",
    "crossbow",
    "Buckshot",
    "rocket", "smgnade", "grenade", "slam",
    "Medium Pistol Ammo",
    "Heavy Rifle Ammo",
    "Heavy Sniper Ammo",
    [-1] = "???"
}

local notificationSound = GM.Config.notificationSound
local function DisplayNotify(msg)
    local txt = msg:ReadString()
    GAMEMODE:AddNotify(txt, msg:ReadShort(), msg:ReadLong())
    surface.PlaySound(notificationSound)

    -- Log to client console
    MsgC(Color(255, 20, 20, 255), "[DarkRP] ", Color(200, 200, 200, 255), txt, "\n")
end
usermessage.Hook("_Notify", DisplayNotify)

usermessage.Hook( "GotArrested", function()
    jailTimer = CurTime() + 300
end )

local darkrpvars = {
    "money", "salary", "rpname", "job", "Energy"
}

hook.Add( "HUDPaint", "DrawSweptRP6HUD", function()
	if not GetConVar( "cl_drawhud" ):GetBool() then return end
    if not DarkRP then return end
    local ply = LocalPlayer()
	if IsValid( ply:GetActiveWeapon() ) and ply:GetActiveWeapon():GetClass() == "gmod_camera" then return end

    surface.SetDrawColor( 0, 0, 0, 224 )
    surface.DrawRect( 10, ScrH() - 76, 306, 66 )

    if ply:Health() <= 25 then
        surface.SetDrawColor( LOW_COLOR_BG:Unpack() )
        surface.DrawRect( 10, ScrH() - 24, 150, 10 )
        surface.SetDrawColor( LOW_COLOR.r, LOW_COLOR.g, LOW_COLOR.b, ( math.floor( CurTime() ) - CurTime() + 1 ) * 255 )
        surface.DrawRect( 10, ScrH() - 24, math.min( ( ply:Health() / ply:GetMaxHealth() ) * 150, 150 ), 10 )
    else
        surface.SetDrawColor( HP_COLOR_BG:Unpack() )
        surface.DrawRect( 10, ScrH() - 24, 150, 10 )
        surface.SetDrawColor( HP_COLOR:Unpack() )
        surface.DrawRect( 10, ScrH() - 24, math.min( ( ply:Health() / ply:GetMaxHealth() ) * 150, 150 ), 10 )
        if ply:Health() > ply:GetMaxHealth() then
            surface.SetDrawColor( 255, 255, 255, TimedSin( 0.5, 64, 192, 0 ) )
            surface.DrawRect( 10, ScrH() - 24, 150, 10 )
        end
    end

    for k,v in pairs( darkrpvars ) do
        if not ply:getDarkRPVar( v ) then return end
    end

    if not DarkRP.disabledDefaults.modules.hungermod or ( ply.IsLosingAir and ply:WaterLevel() == 3 ) then
        surface.SetDrawColor( AP_COLOR_BG:Unpack() )
        surface.DrawRect( 166, ScrH() - 24, 72, 10 )
        surface.SetDrawColor( AP_COLOR:Unpack() )
        surface.DrawRect( 166, ScrH() - 24, math.min( ( ply:Armor() / ply:GetMaxArmor() ) * 72, 72 ), 10 )

        if ply:WaterLevel() == 3 or ply:GetOxygen() < 60 then
            surface.SetDrawColor( AIR_COLOR_BG:Unpack() )
            surface.DrawRect( 244, ScrH() - 24, 72, 10 )
            surface.SetDrawColor( AIR_COLOR:Unpack() )
            surface.DrawRect( 244, ScrH() - 24, math.min( ( ply:GetOxygen() / 60 ) * 72, 72 ), 10 )
            if ply:GetOxygen() <= 15 then
                surface.SetDrawColor( 255, 128, 128, ( ( math.floor( 0.5 + ( 2 * CurTime() ) ) - ( 2 * CurTime() ) ) + 0.5 ) * 128 )
                surface.DrawRect( 244, ScrH() - 24, math.min( ( ply:GetOxygen() / 60 ) * 72, 72 ), 10 )
            end
        else
            surface.SetDrawColor( HUNGER_COLOR_BG:Unpack() )
            surface.DrawRect( 244, ScrH() - 24, 72, 10 )
            surface.SetDrawColor( HUNGER_COLOR:Unpack() )
            surface.DrawRect( 244, ScrH() - 24, math.min( ( ply:getDarkRPVar( "Energy" ) / 100 ) * 72, 72 ), 10 )
        end
    else
        surface.SetDrawColor( AP_COLOR_BG:Unpack() )
        surface.DrawRect( 166, ScrH() - 24, 150, 10 )
        surface.SetDrawColor( AP_COLOR:Unpack() )
        surface.DrawRect( 166, ScrH() - 24, math.min( ( ply:Armor() / ply:GetMaxArmor() ) * 150, 150 ), 10 )
    end

    surface.SetFont( "SweptRP6HUD" )
    surface.SetTextColor( 255, 255, 255, 255 )
    surface.SetTextPos( 15, ScrH() - 48 )
    surface.DrawText( DarkRP.formatMoney( ply:getDarkRPVar( "money" ) ) )
    
    if ply:isArrested() then
        surface.SetTextPos( 311 - surface.GetTextSize( string.FormattedTime( jailTimer - CurTime(), "%02i:%02i:%02i" ):sub( 1, 5 ) ), ScrH() - 48 )
        surface.DrawText( string.FormattedTime( jailTimer - CurTime(), "%02i:%02i:%02i" ):sub( 1, 5 ) )
    elseif ply:getDarkRPVar( "salary" ) > 0 then
        surface.SetTextPos( 311 - surface.GetTextSize( "+" .. DarkRP.formatMoney( ply:getDarkRPVar( "salary" ) ) ), ScrH() - 48 )
        surface.DrawText( "+" .. DarkRP.formatMoney( ply:getDarkRPVar( "salary" ) ) )
    end
    
    surface.SetTextPos( 15, ScrH() - 70 )
    surface.DrawText( ply:getDarkRPVar( "rpname" ) )
    
    surface.SetTextPos( 311 - surface.GetTextSize( ply:getDarkRPVar( "job" ) ), ScrH() - 70 )
    surface.DrawText( ply:getDarkRPVar( "job" ) )


    if ply:getDarkRPVar( "HasGunlicense" ) then
        surface.SetDrawColor( 0, 0, 0, 224 )
        surface.DrawRect( 326, ScrH() - 58, 48, 48 )
        surface.SetDrawColor( color_white:Unpack() )
        surface.SetMaterial( licenseMat )
        surface.DrawTexturedRect( 334, ScrH() - 50, 32, 32 )
        if ply:isArrested() then
            surface.SetDrawColor( 0, 0, 0, 224 )
            surface.DrawRect( 384, ScrH() - 58, 48, 48 )
            surface.SetDrawColor( color_white:Unpack() )
            surface.SetMaterial( jailMat )
            surface.DrawTexturedRect( 392, ScrH() - 50, 32, 32 )
        elseif ply:getDarkRPVar( "wanted" ) then
            surface.SetDrawColor( 0, 0, 0, 224 )
            surface.DrawRect( 384, ScrH() - 58, 48, 48 )
            surface.SetDrawColor( color_white:Unpack() )
            surface.SetMaterial( wantedMat )
            surface.DrawTexturedRect( 392, ScrH() - 50, 32, 32 )
        end
    elseif ply:isArrested() then
        surface.SetDrawColor( 0, 0, 0, 224 )
        surface.DrawRect( 326, ScrH() - 58, 48, 48 )
        surface.SetDrawColor( color_white:Unpack() )
        surface.SetMaterial( jailMat )
        surface.DrawTexturedRect( 334, ScrH() - 50, 32, 32 )
    elseif ply:getDarkRPVar( "wanted" ) then
        surface.SetDrawColor( 0, 0, 0, 224 )
        surface.DrawRect( 326, ScrH() - 58, 48, 48 )
        surface.SetDrawColor( color_white:Unpack() )
        surface.SetMaterial( wantedMat )
        surface.DrawTexturedRect( 334, ScrH() - 50, 32, 32 )
    end

    if ply:GetNWInt( "HeldTrash", 0 ) > 0 then
        surface.SetDrawColor( 0, 0, 0, 224 )
        surface.DrawRect( 10, ScrH() - 134, 48, 48 )
        surface.SetDrawColor( color_white:Unpack() )
        surface.SetMaterial( trashMat )
        surface.DrawTexturedRect( 18, ScrH() - 126, 32, 32 )
        surface.SetTextColor( 255, 255, 255, 255 )
        surface.SetTextPos( 12, ScrH() - 132 )
        surface.DrawText( ply:GetNWInt( "HeldTrash", 0 ) )
    end

    -----------------------------------------------------
    
    local wep = ply:GetActiveWeapon()

    if IsValid( wep ) and wep:GetMaxClip1() > 0 and not ply:InVehicle() then

        surface.SetDrawColor( 0, 0, 0, 224 )
        surface.DrawRect( ScrW() - 310, ScrH() - 76, 300, 66 )

        surface.SetDrawColor( AMMO_COLOR_BG:Unpack() )
        surface.DrawRect( ScrW() - 310, ScrH() - 24, 300, 10 )
        surface.SetDrawColor( AMMO_COLOR.r, AMMO_COLOR.g, AMMO_COLOR.b, ( wep:Clip1() <= math.ceil( 0.25 *  wep:GetMaxClip1() ) and TimedSin( 2, 127, 384, 0 ) or 255 ) )
        surface.DrawRect( ScrW() - 310, ScrH() - 24, math.min( ( wep:Clip1() / wep:GetMaxClip1() ) * 300, 300 ), 10 )

        surface.SetTextPos( ScrW() - 10 - 150 - surface.GetTextSize( wep:GetPrintName() ) / 2, ScrH() - 70 )
        surface.DrawText( wep:GetPrintName() )

        if game.GetAmmoName( wep:GetPrimaryAmmoType() ) then
            surface.SetTextPos( ScrW() - 10 - 150 - surface.GetTextSize( ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) .. "x " .. game.GetAmmoName( wep:GetPrimaryAmmoType() ) ) / 2, ScrH() - 48 )
            surface.DrawText( ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) .. "x " .. game.GetAmmoName( wep:GetPrimaryAmmoType() ) )
        end

    end

    if ply:getAgendaTable() then
        surface.SetDrawColor( 0, 0, 0, 182 )
        surface.DrawRect( ScrW() - 510, 10, 500, 200 )

        surface.SetTextColor( 255, 255, 255, 255 )
        surface.SetTextPos( ScrW() - 505, 15 )
        surface.DrawText( ply:getAgendaTable().Title )
        
        local txt = ply:getDarkRPVar( "agenda" ) or ""
        txt = string.gsub( txt, "//", "\n" )
        txt = string.gsub( txt, "\\n", "\n" )
        txt = DarkRP.textWrap( txt, "SweptRP6HUD", 480 )
        draw.DrawNonParsedText( txt, "SweptRP6HUD", ScrW() - 505, 40, Color( 192, 192, 192, 255 ), 0)
    end

    if GetGlobalBool("DarkRP_LockDown") then
        surface.SetDrawColor( TimedSin( 0.33, 127, 384, 0 ), 0, 0, 255 )
        surface.DrawLine( 0, 0, ScrW() - 1, 0 )
        surface.DrawLine( ScrW() - 1, 0, ScrW() - 1, ScrH() - 1 )
        surface.DrawLine( ScrW() - 1, ScrH() - 1, 0, ScrH() - 1 )
        surface.DrawLine( 0, ScrH() - 1, 0, 0 )

        surface.SetFont( "SweptRP6Lockdown" )
        surface.DrawRect( ScrW() / 2 - surface.GetTextSize( "LOCKDOWN" ) / 2 - 20, ScrH() - 36, surface.GetTextSize( "LOCKDOWN" ) + 40, 36 )
        surface.SetTextPos( ScrW() / 2 - surface.GetTextSize( "LOCKDOWN" ) / 2, ScrH() - 32 )
        surface.SetTextColor( 255, 255, 255, 255 )
        surface.DrawText( "LOCKDOWN" )
    end

end )