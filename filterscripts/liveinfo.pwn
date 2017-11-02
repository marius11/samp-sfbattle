#include a_samp
#include zcmd
#include sscanf

#define TD_UPDATE_RATE (100)

#if defined MAX_PLAYERS
    #undef MAX_PLAYERS
    #define MAX_PLAYERS (5)
#endif

#pragma tabsize 4

forward GetPlayerInfo(playerid);

new Text: LiveInfoTD[MAX_PLAYERS];
new bool: IsLiveInfoOn[MAX_PLAYERS];
new LiveInfoTimer[MAX_PLAYERS];


public OnFilterScriptInit()
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        LiveInfoTD[i] = TextDrawCreate(139.0000, 373.0000, "Loading information...");
        TextDrawBackgroundColor(LiveInfoTD[i], 255);
        TextDrawFont(LiveInfoTD[i], 1);
        TextDrawLetterSize(LiveInfoTD[i], 0.2200, 0.8999);
        TextDrawColor(LiveInfoTD[i], 0x57B1F6FF);
        TextDrawSetOutline(LiveInfoTD[i], 1);
        TextDrawSetProportional(LiveInfoTD[i], 1);
        
        IsLiveInfoOn[i] = false;
        
        CallLocalFunction("GetPlayerInfo", "i", 0);
    }
    return 1;
}

public OnFilterScriptExit()
{
    for (new i; i < MAX_PLAYERS; i++)
    {
        TextDrawDestroy(Text: LiveInfoTD[i]);
        KillTimer(LiveInfoTimer[i]);
        IsLiveInfoOn[i] = false;
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
    return 1;
}

CMD:li(playerid, cmdtext[])
{
    new id;

    if (sscanf(cmdtext, "u", id) || (id == INVALID_PLAYER_ID))
        return SendClientMessage(playerid, -1, ">> Usage: /li <id>");

    LiveInfoTimer[id] = SetTimerEx("GetPlayerInfo", TD_UPDATE_RATE, true, "d", id);

    SendClientMessage(playerid, -1, ">> Use /lioff to hide the info textdraw");
    IsLiveInfoOn[playerid] = true;

    for (new i; i < MAX_PLAYERS; i++)
        TextDrawHideForPlayer(playerid, Text: LiveInfoTD[i]);

    TextDrawShowForPlayer(playerid, Text: LiveInfoTD[id]);

    return 1;
}

CMD:lioff(playerid, cmdtext[])
{
    if (!IsLiveInfoOn[playerid])
        return SendClientMessage(playerid, -1, ">> There is nothing to hide");

    IsLiveInfoOn[playerid] = false;

    for (new i; i < MAX_PLAYERS; i++)
    {
        KillTimer(LiveInfoTimer[i]);
        TextDrawHideForPlayer(playerid, Text: LiveInfoTD[i]);
    }
    #pragma unused cmdtext
	 
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    KillTimer(LiveInfoTimer[playerid]);

    for (new i; i < MAX_PLAYERS; i++)
    {
        TextDrawHideForAll(Text: LiveInfoTD[i]);
        IsLiveInfoOn[i] = false;
    }
    #pragma unused reason

    return 1;
}

public GetPlayerInfo(playerid)
{
    if (!IsPlayerConnected(playerid))
        return 0;

    new string[256 + 64], pName[MAX_PLAYER_NAME], pIP[16], Float: Health, Float: Armour;

    GetPlayerName(playerid, pName, sizeof (pName));
    GetPlayerIp(playerid, pIP, sizeof (pIP));
    GetPlayerHealth(playerid, Health);
    GetPlayerArmour(playerid, Armour);

    format(string, sizeof (string),
        "%s (ID: %d) [%s]~n~HP/AR: %.0f/%.0f | Money: %d | Score: %d | Ping: %d~n~Weps: %s~n~",
        pName, playerid, pIP, Health, Armour, GetPlayerMoney(playerid), GetPlayerScore(playerid),
	GetPlayerPing(playerid), GetPlayerWeapons(playerid));

    if (IsPlayerInAnyVehicle(playerid))
    {
        new v[128], kString[64], keys, updown, leftright, Float: VHealth;

        GetPlayerKeys(playerid, keys, updown, leftright);

        switch (keys)
        {
            case 1: kString = "Secondary Fire";
            case 2: kString = "Horn";
            case 3: kString = "Horn SecondaryFire";
            case 6: kString = "Horn Fire";
            case 8: kString = "Accelerate";
            case 9: kString = "Accelerate SecondaryFire";
            case 10: kString = "Accelerate Horn";
            case 12: kString = "Accelerate Fire";
            case 16: kString = "Exit Vehicle";
            case 32: kString = "Brake";
            case 33: kString = "Brake SecondaryFire";
            case 34: kString = "Brake Horn";
            case 36: kString = "Brake Fire";
            case 40: kString = "Accelerate Brake";
            case 64: kString = "Look Right";
            case 65: kString = "LookRight SecondaryFire";
            case 66: kString = "LookRight Horn";
            case 72: kString = "LookRight Accelerate";
            case 96: kString = "LookRight Brake";
            case 128: kString = "Handbrake";
            case 129: kString = "HandBrake SecondaryFire";
            case 130: kString = "Handbrake Horn";
            case 131: kString = "HandBrake Horn SecondaryFire";
            case 136: kString = "Handbrake Accelerate";
            case 138: kString = "Handbrake Accelerate Horn";
            case 160: kString = "Handbrake Brake";
            case 192: kString = "LookRight Handbrake";
            case 256: kString = "Look Left";
            case 257: kString = "LookLeft SecondaryFire";
            case 258: kString = "LookLeft Horn";
            case 264: kString = "LookLeft Accelerate";
            case 288: kString = "LookLeft Brake";
            case 320: kString = "Look Behind";
            case 321: kString = "LookBehind SecondaryFire";
            case 322: kString = "LookBehind Horn";
            case 328: kString = "LookBehind Accelerate";
            case 352: kString = "LookLeft LookRight Brake";
            case 384: kString = "LookLeft Handbrake";
            case 448: kString = "LookBehind HandBrake";
            case 456: kString = "LookBehind Accelerate Handbrake";
	    default: kString = "None";
        }
        #pragma unused updown, leftright

        GetVehicleHealth(GetPlayerVehicleID(playerid), VHealth);

        format(v, sizeof (v), "VHP: %.4f | Keys: %s (%d)",
            /*(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) ? ("Driver") : ("Passenger"),*/ 
            VHealth, kString, keys);

        strcat(string, v, sizeof (string));
    }
    else
    {
        new w[128], wn[24], kString[64], keys, updown, leftright;

        GetPlayerKeys(playerid, keys, updown, leftright);

        switch (keys)
        {
            case 1: kString = "Pressing TAB";
            case 2: kString = "Crouch";
            case 4: kString = "Fire";
            case 6: kString = "Crouch Fire";
            case 8: kString = "Sprint";
            case 10: kString = "Crouch Sprint";
            case 12: kString = "Fire Sprint";
            case 16: kString = "Enter Vehicle";
            case 32: kString = "Jump";
            case 34: kString = "Jump Crouch";
            case 36: kString = "Jump Fire";
            case 40: kString = "Jump Sprint";
            case 44: kString = "Fire Sprint Jump";
            case 128: kString = "Aim";
            case 132: kString = "Aim Fire";
            case 136: kString = "Aim Sprint";
            case 140: kString = "Aim Sprint Fire";
            case 160: kString = "Aim Jump";
            case 164: kString = "Aim Fire Jump";
            case 168: kString = "Aim Sprint Jump";
            case 172: kString = "Aim Fire Sprint Jump";
            case 512: kString = "LookBehind";
            case 514: kString = "LookBehind Crouch";
            case 516: kString = "Fire LookBehind";
            case 520: kString = "Sprint LookBehind";
            case 544: kString = "Jump LookBehind";
            case 640: kString = "Aim LookBehind";
            case 644: kString = "Aim Fire LookBehind";
            case 1024: kString = "Walk";
            case 1028: kString = "Fire Walk";
            case 1056: kString = "Jump Walk";
            case 1152: kString = "Aim Walk";
            case 1156: kString = "Aim Fire Walk";
            case 1536: kString = "Walk LookBehind";
            case 1568: kString = "Walk LookBehind Jump";
            default: kString = "None";
        }
	#pragma unused updown, leftright

        GetWeaponName(GetPlayerWeapon(playerid), wn, sizeof (wn));

        switch (GetPlayerWeapon(playerid)) // GetWeaponName bug fix
        {
            case 18: wn = "Molotovs";
            case 44: wn = "Night Vision";
            case 45: wn = "Infrared Vision";
            default: wn = "Fists";
        }

        format(w, sizeof (w), "Using: %s | Keys: %s (%d)", wn, kString, keys);
        strcat(string, w, sizeof (string));
    }

    TextDrawSetString(Text: LiveInfoTD[playerid], string);
    print(string);
    return 1;
}

stock GetPlayerWeapons(playerid)
{
    new count, weapons, ammo, wepname[32], string[128];

    for (new i; i < 13; i++) // loop through the weapon slots
    {
        GetPlayerWeaponData(playerid, i, weapons, ammo);

        if (weapons != 0) 
        {
            count++;

            if (weapons <= 15 || weapons == 46) ammo = 1; // malee weapons don't have ammo

            GetWeaponName(weapons, wepname, sizeof (wepname));

            switch (weapons)
            { // Credits to [NoV]Pops for the abbreviations
                case WEAPON_BRASSKNUCKLE: wepname = "Knkls";
                case WEAPON_GOLFCLUB: wepname = "Golf";
                case WEAPON_NITESTICK: wepname = "nStick";
                case WEAPON_KNIFE: wepname = "Knife";
                case WEAPON_BAT: wepname = "Bat";
                case WEAPON_SHOVEL: wepname = "Shovl";
                case WEAPON_POOLSTICK: wepname = "pStick";
                case WEAPON_KATANA: wepname = "Katna";
                case WEAPON_CHAINSAW: wepname = "Chain";
                case WEAPON_DILDO: wepname = "Dildo";
                case WEAPON_DILDO2: wepname = "sDildo";
                case WEAPON_VIBRATOR: wepname = "LVib";
                case WEAPON_VIBRATOR2: wepname = "SilvVib";
                case WEAPON_FLOWER: wepname = "Flowr";
                case WEAPON_CANE: wepname = "Cane";
                case WEAPON_GRENADE: wepname = "Nade";
                case WEAPON_TEARGAS: wepname = "TrGas";
                case WEAPON_MOLTOV: wepname = "Moltv";
                case WEAPON_COLT45: wepname = "9mm";
                case WEAPON_SILENCED: wepname = "Slcnd";
                case WEAPON_DEAGLE: wepname = "Eagle";
                case WEAPON_SHOTGUN: wepname = "Shoty";
                case WEAPON_SAWEDOFF: wepname = "Sawns";
                case WEAPON_SHOTGSPA: wepname = "Spas";
                case WEAPON_UZI: wepname = "UZI";
                case WEAPON_MP5: wepname = "MP5";
                case WEAPON_AK47: wepname = "AK47";
                case WEAPON_M4: wepname = "M4";
                case WEAPON_TEC9: wepname = "Tec9";
                case WEAPON_RIFLE: wepname = "Rifle";
                case WEAPON_SNIPER: wepname = "Snipe";
                case WEAPON_ROCKETLAUNCHER: wepname = "Rockt";
                case WEAPON_HEATSEEKER: wepname = "Seekr";
                case WEAPON_FLAMETHROWER: wepname = "Flame";
                case WEAPON_MINIGUN: wepname = "Mnign";
                case WEAPON_SATCHEL: wepname = "Stchl";
                case WEAPON_BOMB: wepname = "Dtntr";
                case WEAPON_SPRAYCAN: wepname = "Spray";
                case WEAPON_FIREEXTINGUISHER: wepname = "Extin";
                case WEAPON_CAMERA: wepname = "Camra";
                case WEAPON_PARACHUTE: wepname = "Chute";
                default: wepname = "Fists";
            }

            if (count == 1)
            {
                format(string, sizeof (string), "%s(%d)", wepname, ammo);
            }
            else
            {
                format(string, sizeof (string), "%s, %s(%d)", string, wepname, ammo);
            }
        }
    }

    if (!count)
        string = "None";

    return string;
}

/*stock OnlineAdmins()
{
    new x;
    for (new i = GetMaxPlayers(), j; j < i; i++)
    {
        if (!IsPlayerConnected(i) && !IsPlayerAdmin(i))
            continue;
        else x++;
    }
    return x;
}*/
