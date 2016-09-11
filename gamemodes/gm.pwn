#include <a_samp>
#include <a_mysql>
//#include <streamer>
#include <sscanf2>
#include <zcmd>

// Whirlpool.dll
native WP_Hash(buffer[], len, const str[]);

#define MAX_STRING 128
//--- GENERAL DEFINES ----------------------------------------------------------
#define GAME_MODE_TEXT "SF Battle v1.0.0a"

#define TEAM_LAW_ENFORCEMENTS 	(0) // Server-side team
#define TEAM_CIVILIANS 		  	(1) // Players can form their own gang
#define MAX_TEAMS 				(30)

#define COLOUR_LAW_ENFORCEMENT (0x0080C074)
#define COLOUR_CIVILIAN 	   (0xAFAFAFAA)
#define COLOUR_WHITE           (0xFFFFFFFF)

#define TEXT_WHITE		(0xFFFFFFFF) // white showing other notes
#define TEXT_BLUE		(0x0080FFB3) // blue showing the restaurant's name
#define TEXT_GREEN		(0x00FF0048) // green showing the product price
#define TEXT_RED		(0xFF000054) // red showing the product id
#define TEXT_YELLOW		(0xFFFF0052) // yellow showing the product name

#define DIALOG_LOGIN (100)
//--- mysql --------------------------------------------------------------------
#define ssys_host      "localhost"
#define ssys_user      "ssys"
#define ssys_database  "a_sfb"
#define ssys_password  "serverabc"

#define asys_host 	   "localhost"
#define asys_user 	   "asys"
#define asys_database  "a_admin"
#define asys_password  "adminabc"

#define THREAD_USER_LOGIN 			(1)
#define THREAD_USER_REGISTER 		(2)
#define THREAD_SERVER_CMD_HELP      (3)
#define THREAD_SERVER_CMD_COMMANDS 	(4)
#define THREAD_SERVER_CMD_RULES 	(5)

new ssys, asys;

//--- textdraw system ----------------------------------------------------------
#define ENABLE_DEATH_SCREEN true

#define TD_ALIGNMENT_LEFT (1)
#define TD_ALIGNMENT_CENTER (2)
#define TD_ALIGNMENT_RIGHT (3)

new Text: TDpolice;
new Text: TDcivilian;
new Text: TDweapons;
new Text: TDintro[2];
new Text: TDrestaurant[6];
new Text: TDammunation[6];


#if ENABLE_DEATH_SCREEN
	new Text: dscreen;
#endif

//--- dialog system ------------------------------------------------------------
#define DIALOG_CMD_HELP (1)
#define DIALOG_CMD_COMMANDS_S (3)
#define DIALOG_CMD_COMMANDS_F (4)
#define DIALOG_CMD_RULES_S (5)
#define DIALOG_CMD_RULES_F (6)

//--- sound system -------------------------------------------------------------
#define SOUND_ID_PURCHASE_SUCCESS 	(1054)
#define SOUND_ID_PURCHASE_FAIL_1 	(1085) // Blip
#define SOUND_ID_PURCHASE_FAIL_2    (5406) // Casino Woman: Sorry sir, you do not have enough money
#define SOUND_ID_SERVER_NEWS        (0)
#define SOUND_ID_ADMIN_NEWS         (0)
#define SOUND_ID_SLAP               (1190)
#define SOUND_ID_AIR_HORN           (3200)
#define SOUND_ID_AIR_HORN_LONGER    (3201)

//--- turf war system ----------------------------------------------------------
#define ENABLE_TURF_WAR false


#if ENABLE_TURF_WAR

    #define MAX_TURFS (78)
	#define MAX_GANG_NAME (32) // this shouldn't be here

	enum E_TURF_DATA
	{
		turfid,
		owner[MAX_GANG_NAME],
		Float: minx,
		Float: miny,
		Float: maxx,
		Float: maxy,
		colour,
		bool: twip // turf war in progess?
	} new gTurfInfo[MAX_TURFS][E_TURF_DATA];

	new Text: TWARgzowner[MAX_PLAYERS];
	new Text: TWARnewsbox;

	forward turfwar_AddGangZoneDelayed();
	forward turfwar_ShowGangZoneDelayed(playerid);
	forward turfwar_UpdateGangZone();
#endif

//--- anti cheats system -------------------------------------------------------
#define ENABLE_ANTI_CHEAT true

#if ENABLE_ANTI_CHEAT

	#define MAX_WEAPON_SLOTS 13
	#define MAX_PLAYER_HEALTH 100.0
	#define MAX_PLAYER_ARMOUR 100.0
	#define MAX_VEHICLE_HEALTH 1000.0

	/*enum ac_data
	{
	    bool: ac_weapon_check = true,
	    bool: ac_health_check = true, // health and armour
	    bool: ac_vehicle_check = true,
	    bool: ac_ping_check = true
	}; new AntiCheat[MAX_PLAYERS][ac_data]

	new BannedWeapons[] = {WEAPON_MINIGUN}*/

#endif

//--- constants ----------------------------------------------------------------
#define MAX_CHECKPOINTS (32)

#define MAX_IP_LENGHT (16)

#if defined MAX_PLAYERS
	#undef MAX_PLAYERS
	#define MAX_PLAYERS (20)
#endif

#define FLOAT_INFINITY (Float:0x7F800000)

/*#if defined MAX_VEHICLES
	#undef MAX_VEHICLES
	#define MAX_VEHICLES (180)
#endif*/

//--- forward ------------------------------------------------------------------
forward HideIntroTextDraw(playerid, Text: IntroText[2]);
forward DelayedKick(playerid);

//--- vars ---------------------------------------------------------------------
//new Checkpoint[MAX_CHECKPOINTS];

enum E_PLAYER_DATA
{
	userid,
	userpass[129],
	level,
	kills,
	deaths,
	money,
	clanid,
	registerdate[64],
	lastlogin[64],
	bool: pA, // is player in an ammunation pickup ?
	bool: pA2, // is player in an armoury pickup ?
	bool: pCB, // is player in a cluckin bell purchase pickup ?
	bool: pPS, // is player in a pizza stack purchase pickup ?
	bool: pBS, // is player in a burger shop purchase pickup ?
	bool: logged,
	bool: registered,
	pip[MAX_IP_LENGHT],
	loginattempts,
} new gPlayerInfo[MAX_PLAYERS][E_PLAYER_DATA];

#define MAX_PASSWORD_ATTEMPTS (4)

new bool: gIsPlayerUsingJoypadConfig[MAX_PLAYERS];
/*enum vData
{
	vid,
	bool: engine = true,
	bool: lights = true,
	bool: alarm = true,
	bool: doors = true,
	bool: bonnet = true,
	bool: boot = true,
	bool: objective = true
};
new VehicleInfo[MAX_VEHICLES][vData];*/


new const Float: PoliceSpawn[/*aici ar trebui sa fie 3, pentru ca atatea sunt deocamdata*/][3] = {
	{-1806.115234, 533.696044, 35.166793},
	{-2132.741210, 224.338165, 36.062934},
	{-2220.458496, -304.335418, 44.287994}
};

new const Float: CivilianSpawn[/*nu am de gand sa numar cate sunt*/][3] = {
    {-1806.115234, 533.696044, 35.166793},
	{-2132.741210, 224.338165, 36.062934},
	{-2146.041015, -242.062500, 36.515625},
	{-2155.399902, -407.423126, 38.758804},
	{-2220.458496, -304.335418, 44.287994},
	{-2319.466552, -248.999465, 43.012039},
	{-2547.815185, -308.183746, 26.55381},
	{-2721.499023, -318.073272, 7.843750},
	{-2665.918945, -1.433841, 6.132812},
	{-2574.324707, -1.382138, 8.015625},
	{-2482.057373, 64.920494, 26.073856},
	{-2581.821777, 310.162750, 5.179687},
	{-2705.868652, 638.196594, 14.454549},
	{-2641.951904, 636.851440, 14.453125},
  	{-2547.323730, 659.408569, 14.459196},
	{-2643.211425, 844.333679, 62.297370},
	{-2552.028808, 981.558898, 78.273437},
	{-2360.888671, 1129.205688, 55.726562},
	{-1835.459594, 1427.900146, 7.187500},
	{-1551.499389, 1168.065307, 7.187500},
	{-1551.837158, 1061.516113, 7.187500},
	{-1678.231567, 413.820404, 7.179687},
	{-1658.733886, 43.253170, 3.554687},
	{-2026.691772, -93.939773, 35.164062}
};

new gPickupSFAmmunation[3];
new gPickupSFCluckinBell[6];
new gPickupSFCustomAmmu[3];

//------------------------------------------------------------------------------

main()
{
}

#include "../gm/mysql_forwards.pwn"
//------------------------------------------------------------------------------
CMD:help(playerid, cmdtext[])
{
	mysql_function_query(ssys, "SELECT `caption`, `info` FROM `command_help` WHERE `enable` = '1';", true, "OnPlayerCmdHelp", "i", playerid);
	return 1;
}

CMD:commands(playerid, cmdtext[])
{
	return 1;
}

CMD:rules(playerid, cmdtext[])
{
	return 1;
}

CMD:givemoney(playerid, cmdtext[])
{
	new receiver, cash;

	if (sscanf(cmdtext, "ii", receiver, cash) && (!IsPlayerConnected(receiver)) || (playerid == receiver))
	    return SendClientMessage(playerid, -1, "Usage: /givemoney <id> <amount>");

	if (cash >= GetPlayerMoney(playerid))
	    return SendClientMessage(playerid, -1, "You don't have money to transfer");

	GivePlayerMoney(playerid, (0 - cash));
	GivePlayerMoney(receiver, cash);

	new string[128];
	format(string, sizeof (string), "You've sent %d to %s", cash, pName(receiver));
	SendClientMessage(playerid, -1, string);
	format(string, sizeof (string), "You've received %d from %s", cash, pName(playerid));
	SendClientMessage(receiver, -1, string);

	return 1;
}

CMD:kill(playerid, cmdtext[])
{
	SetPlayerHealth(playerid, 0);
	return 1;
}

CMD:register(playerid, cmdtext[])
{
	if (gPlayerInfo[playerid][logged])
	    return SendClientMessage(playerid, -1, "You're already registered");
	
	if (isnull(cmdtext))
	    return SendClientMessage(playerid, -1, "Usage: /register <password>");

	new password[128];
	sscanf(cmdtext, "s[128]", password);

	new hash_pass[129];
	WP_Hash(hash_pass, sizeof (hash_pass), password);

	new query[512];
	mysql_format(asys, query, "INSERT INTO `users` (`username`, `password`, `level`, `kills`, `deaths`, `money`, `clanid`, `registerip`, `registerdate`, `lastlogin`, `lastip`, `banned`) VALUES ('%s', '%e', '1', '0', '0', '0', '0', '%s', '1337', '0', '0', '0');", pName(playerid), hash_pass, gPlayerInfo[playerid][pip]);
	mysql_function_query(asys, query, true, "OnPlayerCmdRegister", "i", playerid);

	return 1;
}

CMD:login(playerid, cmdtext[])
{
    if (gPlayerInfo[playerid][logged])
	    return SendClientMessage(playerid, -1, "You're already logged in");
	
	if (isnull(cmdtext))
	    return SendClientMessage(playerid, -1, "Usage: /login <password>");

	new password[64];
	sscanf(cmdtext, "s[64]", password);
	
	new query[128];
	mysql_format(asys, query, "SELECT * FROM `users` WHERE `username` = '%s' AND `password` = '%s' LIMIT 1;", pName(playerid), password);
	mysql_function_query(asys, query, true, "OnPlayerCmdLogin", "i", playerid);
	return 1;
}

CMD:yes( playerid, cmdtext[] ) GivePlayerMoney( playerid, 5000 );
CMD:no( playerid, cmdtext[] ) GivePlayerMoney( playerid, -5000 );
CMD:dam( playerid, cmdtext[] ) SetPlayerHealth( playerid, 50 );
CMD:add(playerid, cmdtext[])
{
	/*new netstats[1024];
	GetPlayerNetworkStats(0, netstats, sizeof (netstats));
	print(netstats);*/
	//c_AddPlayerMoney(playerid, 500);
}
CMD:tellme(playerid, cmdtext[])
{
	new string[128];
	format(string, sizeof (string), "Yes, you %s", gIsPlayerUsingJoypadConfig[playerid] ? ("are using the joypad configuration.") : ("are not using the joypad configuration."));
	SendClientMessage(playerid, -1, string);
	return 1;
}

CMD:cheat(playerid, cmdtext[])
{
	new type;
	sscanf(cmdtext, "i", type);
	SendClientMessage(playerid, -1, "1. Health, 2. Armour, 3. Veh health, 4. Jetpack");
	
	switch (type)
	{
	    case 1:
	    {
	        SetPlayerHealth(playerid, FLOAT_INFINITY);
 		}
 		case 2:
 		{
 		    SetPlayerArmour(playerid, 102);
		}
		case 3:
		{
		    if (IsPlayerInAnyVehicle(playerid)) {
		    	SetVehicleHealth(GetPlayerVehicleID(playerid), 1002);
			}
			else {
			    return 0;
   			}
  		}
  		case 4:
  		{
  		    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
  		}
  		default:
  		{
			SendClientMessage(playerid, -1, "Unknown cheat type");
		}
	}
	return 1;
}

CMD:drunk(playerid, cmdtext[])
{
	new drunklevel;
	sscanf(cmdtext, "i", drunklevel);
	SetPlayerDrunkLevel(playerid, drunklevel);
	return 1;
}

CMD:veh( playerid, cmdtext[] )
{
	if ( !IsPlayerInAnyVehicle( playerid ) )
		return SendClientMessage( playerid, -1, "You must be in a vehicle" );

	new Float: pos[4];
	GetVehiclePos( GetPlayerVehicleID( playerid ), pos[ 0 ], pos[ 1 ], pos[ 2 ] );
	GetVehicleZAngle( GetPlayerVehicleID( playerid ), pos[ 3 ] );

	new query[ 512 ];
	format( query, sizeof (query), "INSERT INTO `vehicles` (`vehicleid`, `model`, `spawnx`, `spawny`, `spawnz`, `spawna`, `colour1`, `colour2`, `respawn`) VALUES ('2', '%d', '%f', '%f', '%f', '%f', '1', '1', '600');", GetVehicleModel( GetPlayerVehicleID( playerid ) ), pos[ 0 ], pos[ 1 ], pos[ 2 ], pos[ 3 ] );
	mysql_query( query, -1, -1, ssys );
	SendClientMessage( playerid, -1, "vehicle saved" );

	return 1;
}

CMD:dveh( playerid, cmdtext[] )
{
	DestroyVehicle( GetPlayerVehicleID( playerid ) );
	return 1;
}
CMD:rowner( playerid, cmdtext[] )
{
	#if ENABLE_TURF_WAR
	new nowner[ 50 ];
	if ( sscanf( cmdtext, "s[50]", nowner ) )
	    return SendClientMessage( playerid, -1, "/rowner <name>");
	    
	gTurfInfo[ 0 ][ owner ] = EOS;
	gTurfInfo[ 0 ][ owner ] = nowner;
	#endif
	return 1;
}

CMD:rcolor(playerid, cmdtext[])
{
    #if ENABLE_TURF_WAR
	new turf, color;
	if (sscanf(cmdtext, "dd", turf, color))
	    return SendClientMessage(playerid, -1, "/rcolor <turfid> <color>");

	GangZoneHideForAll(gTurfInfo[turf][turfid]);
	//gTurfInfo[turf][colour] = color;
	GangZoneShowForAll(gTurfInfo[turf][turfid], color/*gTurfInfo[turf][colour]*/);
	#endif
	return 1;
}
CMD:getturf(playerid, cmdtext[])
{
    #if ENABLE_TURF_WAR
	new turf;
	if (sscanf(cmdtext, "d", turf))
	    return SendClientMessage(playerid, -1, "/getturf <turfid>");
	    
	new string[128];
	format(string, sizeof (string), "id: %d, minx: %f, miny: %f, maxx: %f, maxy: %f", gTurfInfo[turf][turfid], gTurfInfo[turf][minx], gTurfInfo[turf][miny], gTurfInfo[turf][maxx], gTurfInfo[turf][maxy]);
	SendClientMessage(playerid, -1, string);
	#endif
	return 1;
}
CMD:showturf(playerid, cmdtext[])
{
    #if ENABLE_TURF_WAR
	for (new i; i < MAX_TURFS; i++)
	{
	    GangZoneShowForAll(gTurfInfo[i][turfid], gTurfInfo[i][colour]);
	}
	#endif
	return 1;
}
CMD:flashturf(playerid, cmdtext[])
{
    #if ENABLE_TURF_WAR
	new turf;
	sscanf(cmdtext, "i", turf);
	GangZoneFlashForAll(gTurfInfo[turf][turfid], 0xFFFFFFFF);
	#endif
	return 1;
}

CMD:stopflash(playerid, cmdtext[])
{
    #if ENABLE_TURF_WAR
	new turf;
	sscanf(cmdtext, "i", turf);
	GangZoneStopFlashForAll(gTurfInfo[turf][turfid]);
	#endif
	return 1;
}
CMD:msg(playerid, cmdtext[])
{
	SendPlayerMessageToAll(playerid, "hello :D");
	return 1;
}
/*CMD:ident(playerid, cmdtext[])
{
	new id;
	sscanf(cmdtext, "u", id);

	if (isnull(id))
	    return SendClientMessage(playerid, -1, "Usage: ident <id/part of name>");
	    
	if (IsPlayerConnected(id)) {
		new name[MAX_PLAYER_NAME];
		GetPlayerName(id, name, sizeof (name));
		
		new query[256];
		format(query, sizeof (query), "SELECT *, FROM_UNIXTIME(`Uregisterdate`, '%%D %%b %%Y %%h:%%i:%%s') AS `Dregisterdate` FROM `users` WHERE `username` = '%s' LIMIT 1;", name);
		mysql_query(query, -1, -1, asys);
		mysql_store_result(asys);
		if (mysql_num_rows(asys)) {
		    // ...
		}
	}
	else {
	    // ...
	}
	return 1;
}*/

// LEVEL 2 ADMIN COMMANDS
CMD:say(playerid, cmdtext[])
{
	new text[128];
	sscanf(cmdtext, "s[128]", text);

	if (isnull(text))
	    return SendClientMessage(playerid, -1, "Usage: /say <text>");

	else if (gPlayerInfo[playerid][level] < 2)
	    return 0;

	else
	{
		new string[128];
		format(string, sizeof (string), "Admin >> %s: %s", pName(playerid), text);
		SendClientMessageToAll(-1, string);
	}

	return 1;
}

CMD:goto(playerid, cmdtext[])
{
	new id;
	
	if (sscanf(cmdtext, "i", id) || !IsPlayerConnected(id))
	    return SendClientMessage(playerid, -1, "Usage: /goto <id>");

	else if (gPlayerInfo[playerid][level] < 2)
	    return 0;

	/*else if (GetPlayerState(id) != PLAYER_STATE_SPAWNED)
	    return SendClientMessage(playerid, -1, "Cannot teleport, player is not spawned");*/
	    
	else
	{
		new Float: coords[4];
		GetPlayerPos(id, coords[0], coords[1], coords[2]);
		GetPlayerFacingAngle(id, coords[3]);
		
		if (GetPlayerInterior(id))
		{
		    SetPlayerInterior(playerid, GetPlayerInterior(id));
		    SetPlayerPos(playerid, coords[0], (floatadd(coords[1], 1.0)), (floatadd(coords[2], 1.0)));
		    SetPlayerFacingAngle(playerid, coords[3]);
		}
		else if (IsPlayerInAnyVehicle(id) && GetPlayerInterior(id) && GetPlayerVirtualWorld(id) && GetPlayerState(id) == PLAYER_STATE_DRIVER)
		{
			LinkVehicleToInterior(GetPlayerVehicleID(playerid), GetPlayerInterior(id));
			SetVehicleVirtualWorld(GetPlayerVehicleID(playerid), GetPlayerVirtualWorld(id));
			SetVehiclePos(GetPlayerVehicleID(playerid), coords[0], coords[1], (floatadd(coords[3], 3.5)));
			SetVehicleZAngle(GetPlayerVehicleID(playerid), coords[3]);
		}
		else if (IsPlayerInAnyVehicle(id) && GetPlayerState(id) == PLAYER_STATE_DRIVER)
		{
		    SetVehiclePos(GetPlayerVehicleID(playerid), coords[0], coords[1], (floatadd(coords[2], 3.5)));
		    SetVehicleZAngle(GetPlayerVehicleID(playerid), coords[3]);
		}
		else
		{
			SetPlayerPos(playerid, (floatadd(coords[0], 1.25)), coords[1], (floatadd(coords[2], 2.85)));
			SetPlayerFacingAngle(playerid, coords[3]);
		}
	}

	return 1;
}

/*CMD:info(playerid, cmdtext[])
{
	new id;
	sscanf(cmdtext, "i", id);
	
	if (isnull(id))
	    return SendClientMessage(playerid, -1, "Usage: /info <id>");

	else if (gPlayerInfo[playerid][level] < 2)
	    return 0;

	else {
	    new Float: healthdata[2];
	    GetPlayerHealth(id, healthdata[0]);
	    GetPlayerArmour(id, healthdata[1]);

	    SendFormattedMessage(playerid, -1, ">> %s (%d)  (IP: %s):", pName(id), id, gPlayerInfo[id][pip]);
	    SendFormattedMessage(playerid, -1, ">> Health: %.f | Armour: %.f | Money: $%d | Score: %d | Ping: %dms", healthdata[0], healthdata[1], GetPlayerMoney(id), GetPlayerScore(id), GetPlayerPing(id));
	    // Weapons data here, soon

	    if (IsPlayerInAnyVehicle(id)) {
	        new Float: vehiclehealth;
	        GetVehicleHealth(GetPlayerVehicleID(id), vehiclehealth);

			SendFormattedMessage(playerid, -1, "Vehicle: %.4f", vehiclehealth);
		}
	}

	return 1;
}*/

CMD:kick(playerid, cmdtext[])
{
    if (gPlayerInfo[playerid][level] < 2)
	    return 0;

    new id, reason[50];
	sscanf(cmdtext, "is[50]", id, reason);
	
	if (isnull(cmdtext) || !IsPlayerConnected(id))
	    return SendClientMessage(playerid, -1, "Usage: /kick <id> <reason>");

	new string[128];
	format(string, sizeof (string), "Admin >> %s kicked %s (%s)", pName(playerid), pName(id), reason);
	SendClientMessageToAll(-1, string);
	Kick(id);

	return 1;
}

CMD:baninfo(playerid, cmdtext[])
{
    if (gPlayerInfo[playerid][level] >= 3)
	    return 0;

	if (isnull(cmdtext))
	    return SendClientMessage(playerid, -1, "Usage: /baninfo <nickname>");

	new name[MAX_PLAYER_NAME];
	sscanf(cmdtext, "s[24]", name);
	
	/*new query[128];
	mysql_format(asys, query, "SELECT `ip`, `admin`, `reason`, `date` FROM `banlist` WHERE `user` = '%s';", name);
	mysql_query(query, -1, -1, asys);
	mysql_store_result(asys);
	if (mysql_num_rows(asys)) {
	    new data[256], ip[16], admin[MAX_PLAYER_NAME], reason[64], date[64];
	    mysql_fetch_row_format(data, "|", asys);
	    sscanf(data, "s[16]s[24]s[64]s[64]", ip, admin, reason, date);
	    new string[128];
	    format(string, sizeof (string), "** Ban info for %s: Reason: %s - Admin: %s", name, reason, admin);
	    SendClientMessage(playerid, -1, string);
	    format(string, sizeof (string), "** IP: %s - Date: %s", ip, date);
	    SendClientMessage(playerid, -1, string);
		mysql_free_result(asys);
 	}
 	else {
 	    new string[128];
 	    format(string, sizeof (string), "Admin: %s has not been found in the ban list", name);
 	    SendClientMessage(playerid, -1, string);
 	    mysql_free_result(asys);
	}*/

	return 1;
}

CMD:slap(playerid, cmdtext[])
{
	if (gPlayerInfo[playerid][level] >= 3)
		return 0;
	if (isnull(cmdtext))
	    return SendClientMessage(playerid, -1, "Usage: /slap <id>");
	    
	new id;
	sscanf(cmdtext, "i", id);
	
	new Float: pX, Float: pY, Float: pZ;
	GetPlayerPos(playerid, pX, pY, pZ);
	SetPlayerPos(playerid, pX, pY, floatadd(pZ, 15.0));
	
	return 1;
}
//------------------------------------------------------------------------------
public OnGameModeInit()
{
	SetGameModeText(GAME_MODE_TEXT);
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(false);
	UsePlayerPedAnims();

	TDpolice = TextDrawCreate(416.000000, 302.000000, "law enforcement");
	TextDrawBackgroundColor(TDpolice, 65535);
	TextDrawFont(TDpolice, 3);
	TextDrawLetterSize(TDpolice, 0.599999, 2.200000);
	TextDrawColor(TDpolice, -1);
	TextDrawSetOutline(TDpolice, 1);
	TextDrawSetProportional(TDpolice, 1);

	TDcivilian = TextDrawCreate(416.000000, 302.000000, "civilian");
	TextDrawBackgroundColor(TDcivilian, -16776961);
	TextDrawFont(TDcivilian, 3);
	TextDrawLetterSize(TDcivilian, 0.599999, 2.200000);
	TextDrawColor(TDcivilian, -1);
	TextDrawSetOutline(TDcivilian, 1);
	TextDrawSetProportional(TDcivilian, 1);

    TDweapons = TextDrawCreate(18.000000, 269.000000, "_");
	TextDrawBackgroundColor(TDweapons, 255);
	TextDrawFont(TDweapons, 1);
	TextDrawLetterSize(TDweapons, 0.380000, 1.199999);
	TextDrawColor(TDweapons, -1);
	TextDrawSetOutline(TDweapons, 1);
	TextDrawSetProportional(TDweapons, 1);

    TDintro[0] = TextDrawCreate(36.000000, 160.000000, "~p~~h~welcome to san fierro ~r~madness");
	TextDrawBackgroundColor(TDintro[0], 255);
	TextDrawFont(TDintro[0], 3);
	TextDrawLetterSize(TDintro[0], 0.639999, 2.899998);
	TextDrawColor(TDintro[0], -1);
	TextDrawSetOutline(TDintro[0], 1);
	TextDrawSetProportional(TDintro[0], 1);

	TDintro[1] = TextDrawCreate(228.000000, 203.000000, "Type /help to get started~n~Type /commands to see your commands, ~n~and /rules for server's rules");
	TextDrawAlignment(TDintro[1], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDintro[1], 255);
	TextDrawFont(TDintro[1], 0);
	TextDrawLetterSize(TDintro[1], 0.500000, 1.399999);
	TextDrawColor(TDintro[1], -1);
	TextDrawSetOutline(TDintro[1], 1);
	TextDrawSetProportional(TDintro[1], 1);

	TDrestaurant[0] = TextDrawCreate(180.000000, 126.000000, ".~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~.");
	TextDrawBackgroundColor(TDrestaurant[0], 255);
	TextDrawFont(TDrestaurant[0], 1);
	TextDrawLetterSize(TDrestaurant[0], 0.070000, 1.100000);
	TextDrawColor(TDrestaurant[0], 100);
	TextDrawSetOutline(TDrestaurant[0], 0);
	TextDrawSetProportional(TDrestaurant[0], 1);
	TextDrawSetShadow(TDrestaurant[0], 1);
	TextDrawUseBox(TDrestaurant[0], 1);
	TextDrawBoxColor(TDrestaurant[0], 100);
	TextDrawTextSize(TDrestaurant[0], 446.000000, 0.000000);

	TDrestaurant[1] = TextDrawCreate(313.000000, 137.000000, "_");
	TextDrawAlignment(TDrestaurant[1], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDrestaurant[1], 255);
	TextDrawFont(TDrestaurant[1], 0);
	TextDrawLetterSize(TDrestaurant[1], 0.839998, 3.000000);
	TextDrawColor(TDrestaurant[1], -1);
	TextDrawSetOutline(TDrestaurant[1], 1);
	TextDrawSetProportional(TDrestaurant[1], 1);

	TDrestaurant[2] = TextDrawCreate(311.000000, 179.000000, "_");
	TextDrawAlignment(TDrestaurant[2], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDrestaurant[2], 255);
	TextDrawFont(TDrestaurant[2], 1);
	TextDrawLetterSize(TDrestaurant[2], 0.340000, 0.999998);
	TextDrawColor(TDrestaurant[2], TEXT_YELLOW);
	TextDrawSetOutline(TDrestaurant[2], 1);
	TextDrawSetProportional(TDrestaurant[2], 1);

	TDrestaurant[3] = TextDrawCreate(218.000000, 179.000000, "1.~n~~n~2.~n~~n~3.~n~~n~4.");
	TextDrawAlignment(TDrestaurant[3], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDrestaurant[2], 255);
	TextDrawFont(TDrestaurant[3], 1);
	TextDrawLetterSize(TDrestaurant[3], 0.290000, 1.000000);
	TextDrawColor(TDrestaurant[3], TEXT_RED);
	TextDrawSetOutline(TDrestaurant[3], 1);
	TextDrawSetProportional(TDrestaurant[3], 1);

	TDrestaurant[4] = TextDrawCreate(401.000000, 179.000000, "_");
	TextDrawAlignment(TDrestaurant[4], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDrestaurant[3], 255);
	TextDrawFont(TDrestaurant[4], 1);
	TextDrawLetterSize(TDrestaurant[4], 0.280000, 1.000000);
	TextDrawColor(TDrestaurant[4], TEXT_GREEN);
	TextDrawSetOutline(TDrestaurant[4], 1);
	TextDrawSetProportional(TDrestaurant[4], 1);

    TDrestaurant[5] = TextDrawCreate(312.000000, 260.000000, "To make a purchase, type the product ~r~ID ~w~in chat.~n~If you've finished eating, press ~r~~k~~PED_JUMPING~ ~w~to close the box.");
 	TextDrawAlignment(TDrestaurant[5], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDrestaurant[5], 255);
	TextDrawFont(TDrestaurant[5], 2);
	TextDrawLetterSize(TDrestaurant[5], 0.160000, 1.000000);
	TextDrawColor(TDrestaurant[5], TEXT_WHITE);
	TextDrawSetOutline(TDrestaurant[5], 0);
	TextDrawSetProportional(TDrestaurant[5], 1);
	TextDrawSetShadow(TDrestaurant[5], 0);

    TDammunation[0] = TextDrawCreate(227.000000, 106.000000, ".~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~.");
	TextDrawBackgroundColor(TDammunation[0], 255);
	TextDrawFont(TDammunation[0], 1);
	TextDrawLetterSize(TDammunation[0], 0.009999, 1.000000);
	TextDrawColor(TDammunation[0], 255);
	TextDrawSetOutline(TDammunation[0], 0);
	TextDrawSetProportional(TDammunation[0], 1);
	TextDrawSetShadow(TDammunation[0], 1);
	TextDrawUseBox(TDammunation[0], 1);
	TextDrawBoxColor(TDammunation[0], 150);
	TextDrawTextSize(TDammunation[0], 403.000000, 0.000000);

    TDammunation[1] = TextDrawCreate(311.000000, 111.000000, "_");
	TextDrawAlignment(TDammunation[1], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDammunation[1], 255);
	TextDrawFont(TDammunation[1], 0);
	TextDrawLetterSize(TDammunation[1], 0.799998, 2.999999);
	TextDrawColor(TDammunation[1], TEXT_WHITE);
	TextDrawSetOutline(TDammunation[1], 0);
	TextDrawSetProportional(TDammunation[1], 1);
	TextDrawSetShadow(TDammunation[1], 0);

    TDammunation[2] = TextDrawCreate(248.000000, 150.000000, "_");
	TextDrawAlignment(TDammunation[2], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDammunation[2], 255);
	TextDrawFont(TDammunation[2], 1);
	TextDrawLetterSize(TDammunation[2], 0.280000, 1.000000);
	TextDrawColor(TDammunation[2], TEXT_RED);
	TextDrawSetOutline(TDammunation[2], 0);
	TextDrawSetProportional(TDammunation[2], 1);
	TextDrawSetShadow(TDammunation[2], 0);

	TDammunation[3] = TextDrawCreate(308.000000, 150.000000, "_");
	TextDrawAlignment(TDammunation[3], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDammunation[3], 255);
	TextDrawFont(TDammunation[3], 1);
	TextDrawLetterSize(TDammunation[3], 0.280000, 1.000000);
	TextDrawColor(TDammunation[3], TEXT_WHITE);
	TextDrawSetOutline(TDammunation[3], 0);
	TextDrawSetProportional(TDammunation[3], 1);
	TextDrawSetShadow(TDammunation[3], 0);

	TDammunation[4] = TextDrawCreate(376.000000, 150.000000, "_");
	TextDrawAlignment(TDammunation[4], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDammunation[4], 255);
	TextDrawFont(TDammunation[4], 1);
	TextDrawLetterSize(TDammunation[4], 0.280000, 1.000000);
	TextDrawColor(TDammunation[4], TEXT_GREEN);
	TextDrawSetOutline(TDammunation[4], 0);
	TextDrawSetProportional(TDammunation[4], 1);
	TextDrawSetShadow(TDammunation[4], 0);
	
	TDammunation[5] = TextDrawCreate(315.000000, 278.000000, "_");
	TextDrawAlignment(TDammunation[5], TD_ALIGNMENT_CENTER);
	TextDrawBackgroundColor(TDammunation[5], 255);
	TextDrawFont(TDammunation[5], 1);
	TextDrawLetterSize(TDammunation[5], 0.170000, 0.899999);
	TextDrawColor(TDammunation[5], -1);
	TextDrawSetOutline(TDammunation[5], 0);
	TextDrawSetProportional(TDammunation[5], 1);
	TextDrawSetShadow(TDammunation[5], 0);
	
	#if ENABLE_TURF_WAR
		for (new i; i < MAX_PLAYERS; i++)
		{
	    	TWARgzowner[i] = TextDrawCreate(86.000000, 326.000000, "_");
			TextDrawAlignment(TWARgzowner[i], TD_ALIGNMENT_CENTER);
			TextDrawBackgroundColor(TWARgzowner[i], 255);
			TextDrawFont(TWARgzowner[i], 1);
			TextDrawLetterSize(TWARgzowner[i], 0.240000, 1.100000);
			TextDrawColor(TWARgzowner[i], -1);
			TextDrawSetOutline(TWARgzowner[i], 1);
			TextDrawSetProportional(TWARgzowner[i], 1);
			//TextDrawSetShadow(TWARgzowner[i], 0);
		}

		TWARnewsbox = TextDrawCreate(2.000000, 428.000000, ".~n~.");
		TextDrawBackgroundColor(TWARnewsbox, 255);
		TextDrawFont(TWARnewsbox, 1);
		TextDrawLetterSize(TWARnewsbox, 0.470000, 1.000000);
		TextDrawColor(TWARnewsbox, 0);
		TextDrawSetOutline(TWARnewsbox, 0);
		TextDrawSetProportional(TWARnewsbox, 1);
		TextDrawSetShadow(TWARnewsbox, 0);
		TextDrawUseBox(TWARnewsbox, 1);
		TextDrawBoxColor(TWARnewsbox, 150);
		TextDrawTextSize(TWARnewsbox, 635.000000, 0.000000);

		SetTimer("turfwar_UpdateGangZone", 1000, true);
	#endif
	
	#if ENABLE_DEATH_SCREEN
		dscreen = TextDrawCreate(2.000000, 450.000000, ".~n~.");
		TextDrawBackgroundColor(dscreen, 255);
		TextDrawFont(dscreen, 1);
		TextDrawLetterSize(dscreen, 0.050000, -25.100009);
		TextDrawColor(dscreen, 100);
		TextDrawSetOutline(dscreen, 0);
		TextDrawSetProportional(dscreen, 1);
		TextDrawSetShadow(dscreen, 0);
		TextDrawUseBox(dscreen, 1);
		TextDrawBoxColor(dscreen, 100);
		TextDrawTextSize(dscreen, 629.000000, 0.000000);
	#endif

	AddPlayerClassEx(TEAM_LAW_ENFORCEMENTS, 166, 0.0, 0.0, 0.0, 0.0, WEAPON_NITESTICK, 0, WEAPON_COLT45, 150, WEAPON_SHOTGUN, 110);
	AddPlayerClassEx(TEAM_LAW_ENFORCEMENTS, 281, 0.0, 0.0, 0.0, 0.0, WEAPON_NITESTICK, 0, WEAPON_DEAGLE, 95, WEAPON_UZI, 250);
	AddPlayerClassEx(TEAM_LAW_ENFORCEMENTS, 285, 0.0, 0.0, 0.0, 0.0, WEAPON_KNIFE, 0, WEAPON_SILENCED, 100, WEAPON_SHOTGSPA, 95);
	AddPlayerClassEx(TEAM_LAW_ENFORCEMENTS, 287, 0.0, 0.0, 0.0, 0.0, WEAPON_KNIFE, 0, WEAPON_MP5, 125, WEAPON_M4, 150);

	for (new i; i < 289; i++)
	{
	    if (IsSkinValid(i) && i != 0 && i != 165 && i != 280 && i != 282 && i != 283 && i != 284 && i != 286 && i != 288)
		{
     		AddPlayerClassEx(TEAM_CIVILIANS, i, 0.0, 0.0, 0.0, 0.0, WEAPON_DEAGLE, 90, 0, 0, 0, 0);
		}
	}

    mysql_debug(true);

	ssys = mysql_connect("localhost", "ssys", "a_sfb", "serverabc");
	/*for (new i; i < 78; i++)
	{
	    new q[128];
	    format(q, sizeof (q), "UPDATE `turfs` SET `colour` = '150' WHERE `turfid` = '%d';", i);
	    mysql_query(q, -1, -1, ssys );
	}*/

	if (mysql_ping(ssys) == 1)
	{
		printf("User \"%s\" successfully connected", ssys_user);
		new z;
		printf("z=%d", z);
		mysql_function_query(ssys, "SELECT `model`, `spawnx`, `spawny`, `spawnz`, `spawna`, `colour1`, `colour2` FROM `vehicles`;", true, "OnVehicleLoad", "");
		/*mysql_query("SELECT `x`, `y`, `z`, `size`, `worldid`, `interiorid` FROM `checkpoints`;", -1, -1, ssys);
		mysql_store_result(ssys);
		if (mysql_num_rows(ssys)) {
		    printf("** Created checkpoints: %d", mysql_num_rows(ssys));
		    new data[128];
		    static count = -1;
            while (mysql_retrieve_row(ssys)) {
                mysql_fetch_row_format(data, "|", ssys);
           		count++;
           		printf("%d", count);
   				sscanf(data, "e<p<|>iffffii>", CheckpointInfo[count]);
			}
			SetTimer("AddDynamicCheckpointDelayed", 2000, false);
			mysql_free_result(ssys);
		}
		else {
		    print("No data found in table `checkpoints`");
		}*/

		/*mysql_query("SELECT `model`, `x`, `y`, `z` FROM `pickups`;", -1, -1, ssys);
		mysql_store_result(ssys);
		if (mysql_num_rows(ssys)) {
		    printf("** Created pickups: \t%d", mysql_num_rows(ssys));
	    	new data[64], pmodel, Float: p_coords[3];
			while (mysql_fetch_row_format(data, "|", ssys)) {
				sscanf(data, "p<|>ifff", pmodel, p_coords[0], p_coords[1], p_coords[2]);
				CreateDynamicPickup(pmodel, 2, p_coords[0], p_coords[1], p_coords[2], -1, -1, -1, 75.0);
			}
			mysql_free_result(ssys);
		}
		else {
		    print("No data found in table `pickups`");
		    mysql_free_result(ssys);
		}*/

		/*mysql_query("SELECT `x`, `y`, `z`, `type` FROM `mapicons`;", -1, -1, ssys);
		mysql_store_result(ssys);
		if (mysql_num_rows(ssys)) {
  			printf("** Created mapicons: \t%d", mysql_num_rows(ssys));
    		new data[256], Float: m_coords[3], mtype;
	    	while (mysql_fetch_row_format(data, "|", ssys)) {
     			sscanf(data, "p<|>fffi", m_coords[0], m_coords[1], m_coords[2], mtype);
       			CreateDynamicMapIcon(m_coords[0], m_coords[1], m_coords[2], mtype, -1, -1, -1, -1, 75.0);
			}
			mysql_free_result(ssys);
		}
		else {
		    print("No data found in table `mapicons`");
		}*/

		/*mysql_query("SELECT `model`, `x`, `y`, `z`, `rx`, `ry`, `rz`, `worldid`, `interiorid` FROM `objects`;", -1, -1, ssys);
		mysql_store_result(ssys);
		if (mysql_num_rows(ssys)) {
		    printf("** Created objects: \t%d", mysql_num_rows(ssys));
	    	new data[256], omodel, Float: o_coords[6], oworldid, ointid;
	    	while (mysql_fetch_row_format(data, "|", ssys)) {
 	 			sscanf(data, "p<|>iffffffii", omodel, o_coords[0], o_coords[1], o_coords[2], o_coords[3], o_coords[4], o_coords[5], oworldid, ointid);
  				CreateDynamicObject(omodel, o_coords[0], o_coords[1], o_coords[2], o_coords[3], o_coords[4], o_coords[5], oworldid, ointid, -1);
			}
			mysql_free_result(ssys);
		}
		else {
		    print("No data found in table `objects`");
			mysql_free_result(ssys);
		}*/

		/*#if ENABLE_TURF_WAR
		    mysql_query("SELECT `turfid`, `owner`, `minx`, `miny`, `maxx`, `maxy`, `colour` FROM `turfs`;", -1, -1, ssys);
		    mysql_store_result(ssys);
		    if (mysql_num_rows(ssys)) {
		        printf("** Loading turfs: \t%d", mysql_num_rows(ssys));
		        new data[256];
	        	static gzone = -1;
		        while (mysql_fetch_row_format(data, "|", ssys)) {
		            gzone++;
          			sscanf(data, "e<p<|>is[50]ffffi{l}>", gTurfInfo[gzone]);
				}
				mysql_free_result(ssys);
			}
			else {
			    print("No data found in table `turfs`");
			    mysql_free_result(ssys);
			}
			SetTimer("turfwar_AddGangZoneDelayed", 5000, false);
		#endif*/

		//print( "MySQL >> Data has been loaded\n" );
	}
	else
	{
		printf("User \"%s\" failed to connect\n\n", ssys_user);
		SendRconCommand("exit"); // not worth opening the server without its important elements
	}

    asys = mysql_connect("localhost", "asys", "a_admin", "adminabc");
    if (mysql_ping(asys) == 1)
	{
        printf("User \"%s\" successfully connected", asys_user);
	}
	else
	{
		printf("User \"%s\" failed to connect\n\n", asys_user);
		SendRconCommand("exit"); // not worth opening the server without an admin system
	}
	
	// entrance
	gPickupSFAmmunation[0] = CreatePickup(1318, 1, -2625.909912, 208.977188, 4.614942, 0);
	// purchase
	gPickupSFAmmunation[1] = CreatePickup(1239, 1, 296.163024, -38.168479, 1001.515625, 1);
	// exit
	gPickupSFAmmunation[2] = CreatePickup(1318, 1, 286.111175, -41.414520, 1001.515625, 1);
	
	// entrance
	gPickupSFCustomAmmu[0] = CreatePickup(1318, 1, -2442.550292, 754.371276, 35.171875, 0);
	// purchase
	gPickupSFCustomAmmu[1] = CreatePickup(1239, 1, -10.633464, -178.031692, 1003.546875, 1);
	// exit
	gPickupSFCustomAmmu[2] = CreatePickup(1318, 1, -25.942188, -187.647003, 1003.546875, 1);
	
	// entrance
	gPickupSFCluckinBell[0] = CreatePickup(1318, 1, -2671.546386, 258.272491, 4.632812, 0);
	// purchase
	gPickupSFCluckinBell[1] = CreatePickup(1239, 1, 370.897399, -6.492502, 1001.858886, 1);
	// exit
	gPickupSFCluckinBell[2] = CreatePickup(1318, 1, 364.906707, -11.038316, 1001.851562, 1);

    /*new query[1024];
	format(query, sizeof (query), "INSERT INTO `users_test` (`userid`, `username`, `password`, `adminlevel`, `kills`, `deaths`, `money`, `clanid`, `registerip`, `Uregisterdate`, `Dregisterdate`, `Dlastlogin`, `lastip`, `banned`) VALUES ('1', '[NoV]LaZ', 'oldtimer', '5', '0', '0', '100', '0', '127.0.0.1', '%d', CURRENT_TIMESTAMP, '0', '127.0.0.1', '0')", gettime());
	mysql_query(query, -1, -1, asys);

	mysql_query("SELECT *, FROM_UNIXTIME(`Uregisterdate`, '%%y-%%M-%%D %%h:%%i:%%s') AS `Dregisterdate` FROM `users_test` WHERE `username` = '[NoV]LaZ' LIMIT 1;", -1, -1, asys);
	mysql_store_result(asys);
	new regdate[128], data[126];
	mysql_fetch_row_format(data, "|", asys);
	mysql_fetch_field_row(regdate, "Dregisterdate", asys);
	printf("regdate: %s", regdate);
	mysql_free_result(asys);
	return 1;*/
}

public OnGameModeExit()
{
    #if ENABLE_TURF_WAR
	    for (new i; i < MAX_TURFS; i++)
	    {
	        GangZoneDestroy(gTurfInfo[i][turfid]);
		}
	#endif
	mysql_close(ssys);
	mysql_close(asys);
	return 1;
}

public OnPlayerConnect(playerid)
{
	// send a beautiful welcome message and play the pilot award sound track :)
    SendClientMessage(playerid, -1, "{00CC00}Welcome {0099FF}to {FF0099}San Fierro {CC0033}Battle{FFFFFF}!");
	PlayerPlaySound(playerid, 1187, 0.0, 0.0, 0.0);

    new ip[MAX_IP_LENGHT];
	GetPlayerIp(playerid, ip, sizeof (ip));
	gPlayerInfo[playerid][pip] = ip;
    gPlayerInfo[playerid][pA] = false;
    gPlayerInfo[playerid][pA2] = false;
    gPlayerInfo[playerid][pCB] = false;
    gPlayerInfo[playerid][pPS] = false;
    gPlayerInfo[playerid][pBS] = false;
 	gPlayerInfo[playerid][logged] = false;
 	gPlayerInfo[playerid][registered] = false;
 	gPlayerInfo[playerid][loginattempts] = 0;

    SetPlayerColor(playerid, COLOUR_WHITE);

	new query[128];
	mysql_format(asys, query, "SELECT NULL FROM `users` WHERE `username` = '%s';", pName(playerid));
	mysql_function_query(asys, query, true, "OPC_CheckIfRegistered", "i", playerid);

	TextDrawShowForPlayer(playerid, TDintro[0]);
 	TextDrawShowForPlayer(playerid, TDintro[1]);

    #if ENABLE_TURF_WAR
    	SetTimerEx("turfwar_ShowGangZoneDelayed", 5000, false, "i", playerid);

    	TextDrawShowForPlayer(playerid, TWARnewsbox);
	#endif

	SetTimerEx("HideIntroTextDraw", 15000, false, "iii", playerid, _:TDintro[0], _:TDintro[1]);

	for (new i = 0, j = GetMaxPlayers(); j < i; i++)
	{
 		if (!IsPlayerConnected(i) && playerid != i) continue;

		new string[128];
		format(string, sizeof (string), "*** %s (%d) joined the server.", pName(playerid), playerid);
		SendClientMessage(i, -1, string);
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	gPlayerInfo[playerid][pA] = false;
	gPlayerInfo[playerid][pA2] = false;
	gPlayerInfo[playerid][pCB] = false;
	gPlayerInfo[playerid][pPS] = false;
	gPlayerInfo[playerid][pBS] = false;
 	gPlayerInfo[playerid][pip] = 0;
 	gPlayerInfo[playerid][loginattempts] = 0;

    #if ENABLE_TURF_WAR
	    /*TextDrawHideForPlayer(playerid, TWARgzowner[playerid]);
	    TextDrawHideForPlayer(playerid, TWARnewsbox);*/
	    
	    TextDrawDestroy(TWARgzowner[playerid]);
		TextDrawHideForPlayer(playerid, TWARnewsbox);
	#endif

    new reasonmsg[8];
	switch (reason)
	{
	    case 0: reasonmsg = "Timeout";
		case 1: reasonmsg = "Leaving";
		case 2: reasonmsg = "Kicked";
	}

	new string[128];
	format(string, sizeof (string), "*** %s (%d) left the server. (%s)", pName(playerid), playerid, reasonmsg);
	SendClientMessageToAll(-1, string);

	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerInterior(playerid, 1);
	SetPlayerPos(playerid, 956.6526, 2119.0784, 1011.0234);
	SetPlayerFacingAngle(playerid, 134.5664);
	SetPlayerCameraPos(playerid, 953.9003, 2116.2626, 1012.5300);
	SetPlayerCameraLookAt(playerid, 958.5950, 2125.0922, 1008.9463);

    TextDrawShowForPlayer(playerid, TDweapons);

	switch (GetPlayerTeam(playerid))
	{
	    case 0:	TextDrawShowForPlayer(playerid, TDpolice), TextDrawHideForPlayer(playerid, TDcivilian);
 		case 1:	TextDrawShowForPlayer(playerid, TDcivilian), TextDrawHideForPlayer(playerid, TDpolice);
	}

	switch (classid)
	{
	    case 0: TextDrawSetString(TDweapons, "~g~Weapons~w~:~n~  - ~b~Nitestick~n~  ~w~- ~b~Colt45~n~  ~w~- ~b~Shotgun");
		case 1: TextDrawSetString(TDweapons, "~g~Weapons~w~:~n~  - ~b~Nitestick~n~  ~w~- ~b~Deagle~n~  ~w~- ~b~UZI");
		case 2: TextDrawSetString(TDweapons, "~g~Weapons~w~:~n~  - ~b~Knife~n~  ~w~- ~b~Silence 9mm~n~  ~w~- ~b~Combat Shotgun");
		case 3: TextDrawSetString(TDweapons, "~g~Weapons~w~:~n~  - ~b~Knife~n~  ~w~- ~b~MP5~n~  ~w~- ~b~M4");
		default: TextDrawSetString(TDweapons, "~g~Weapons~w~:~n~  - ~b~-~n~  ~w~- ~b~Deagle~n~  ~w~- ~b~-");
	}

	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	if (!gPlayerInfo[playerid][logged])
	    return SendClientMessage(playerid, -1, "Please log in before spawning"), 0;

	return 1;
}

public OnPlayerSpawn(playerid)
{
	TextDrawHideForPlayer(playerid, TDpolice);
	TextDrawHideForPlayer(playerid, TDcivilian);
	TextDrawHideForPlayer(playerid, TDweapons);
	TextDrawHideForPlayer(playerid, TDintro[0]);
	TextDrawHideForPlayer(playerid, TDintro[1]);

	// stop playing the pilot award track sound
	PlayerPlaySound(playerid, 1188, 0.0, 0.0, 0.0);

	if (!gPlayerInfo[playerid][logged])
	{
	    SendClientMessage(playerid, -1, "It's not possible to spawn without logging in unless you're a smart joe");
	    Kick(playerid);
	}

	if (GetPlayerTeam(playerid) == TEAM_LAW_ENFORCEMENTS)
	{
	    //SetPlayerInterior(playerid, 10);
	    //SetPlayerVirtualWorld(playerid, 1);
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
		SetPlayerColor(playerid, COLOUR_LAW_ENFORCEMENT);

	    new rand = random(sizeof (PoliceSpawn));
	    SetPlayerPos(playerid, PoliceSpawn[rand][0], PoliceSpawn[rand][1], PoliceSpawn[rand][2]);
	    SetPlayerFacingAngle(playerid, 270.0);
	}
	else
	{
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
	    SetPlayerColor(playerid, COLOUR_CIVILIAN);
	    
	    new rand = random(sizeof (CivilianSpawn));
	    SetPlayerPos(playerid, CivilianSpawn[rand][0], CivilianSpawn[rand][1], CivilianSpawn[rand][2]);
	    SetPlayerFacingAngle(playerid, 270.0);
	}

	#if ENABLE_DEATH_SCREEN
	    TextDrawHideForPlayer(playerid, dscreen);
	#endif

	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	SendDeathMessage(killerid, playerid, reason);

	if (killerid != INVALID_PLAYER_ID) {
	    if (GetPlayerTeam(killerid) != GetPlayerTeam(playerid))
	        SetPlayerScore(killerid, GetPlayerScore(killerid) + 1);
		else SetPlayerScore(killerid, GetPlayerScore(killerid) - 1);
	}

	gPlayerInfo[playerid][deaths]++;
	gPlayerInfo[killerid][kills]++;

    new query[128];

	if (IsPlayerConnected(killerid) && gPlayerInfo[killerid][level] >= 1) {
		mysql_format(asys, query, "UPDATE `users` SET `kills` = `kills` + 1 WHERE `username` = '%s';", pName(killerid));
		mysql_query(query, -1, -1, asys);
	}

	if (gPlayerInfo[playerid][level] >= 1) {
		mysql_format(asys, query, "UPDATE `users` SET `deaths` = `deaths` + 1 WHERE `username` = '%s';", pName(playerid));
		mysql_query(query, -1, -1, asys);
	}


	#if ENABLE_DEATH_SCREEN
	    TextDrawShowForPlayer(playerid, dscreen);
	#endif

	#if ENABLE_TURF_WAR
	// turf war code
	#endif

	return 1;
}

public OnPlayerText(playerid, text[])
{
	if (GetPlayerInterior(playerid) && gPlayerInfo[playerid][pA]) {
	    if (!strcmp(text, "1", true)) {
			new Float: pArmour;
			GetPlayerArmour(playerid, pArmour);

			if (floatcmp(pArmour, 100.0) != 0) {
	        	if (GetPlayerMoney(playerid) >= 250) {
				 	SetPlayerArmour(playerid, 100);
		 			GivePlayerMoney(playerid, -250);
		 			PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You don't have enough money");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You already have armour!");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "2", true)) {
		    if (GetPlayerMoney(playerid) >= 650) {
		        GivePlayerWeapon(playerid, WEAPON_SILENCED, 15); // I don't know the amount it gives in singleplayer...
		        GivePlayerMoney(playerid, -650);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "3", true)) {
		    if (GetPlayerMoney(playerid) >= 250) {
		        GivePlayerWeapon(playerid, WEAPON_COLT45, 15);
		        GivePlayerMoney(playerid, -250);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "4", true)) {
		    if (GetPlayerMoney(playerid) >= 1250) {
		        GivePlayerWeapon(playerid, WEAPON_DEAGLE, 15);
		        GivePlayerMoney(playerid, -1250);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "5", true)) {
		    if (GetPlayerMoney(playerid) >= 350) {
		        GivePlayerWeapon(playerid, WEAPON_TEC9, 15);
		        GivePlayerMoney(playerid, -350);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "6", true)) {
		    if (GetPlayerMoney(playerid) >= 550) {
		        GivePlayerWeapon(playerid, WEAPON_UZI, 15);
		        GivePlayerMoney(playerid, -550);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "7", true)) {
		    if (GetPlayerMoney(playerid) >= 2100) {
		        GivePlayerWeapon(playerid, WEAPON_UZI, 15);
		        GivePlayerMoney(playerid, -2100);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "8", true)) {
		    if (GetPlayerMoney(playerid) >= 650) {
		        GivePlayerWeapon(playerid, WEAPON_SHOTGUN, 15);
		        GivePlayerMoney(playerid, -650);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "9", true)) {
		    if (GetPlayerMoney(playerid) >= 1150) {
		        GivePlayerWeapon(playerid, WEAPON_SHOTGSPA, 15);
		        GivePlayerMoney(playerid, -1150);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "10", true)) {
		    if (GetPlayerMoney(playerid) >= 950) {
		        GivePlayerWeapon(playerid, WEAPON_SAWEDOFF, 15);
		        GivePlayerMoney(playerid, -950);
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "11", true)) {
		    if (GetPlayerMoney(playerid) >= 3650) {
		        GivePlayerWeapon(playerid, WEAPON_AK47, 15);
		        GivePlayerMoney(playerid, -3650);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		else if (!strcmp(text, "12", true)) {
		    if (GetPlayerMoney(playerid) >= 4750) {
		        GivePlayerWeapon(playerid, WEAPON_M4, 15);
		        GivePlayerMoney(playerid, -4750);
		        PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
		}
		//else SendClientMessage(playerid, -1, "Invalid item number");
	}
	else if (GetPlayerInterior(playerid) && gPlayerInfo[playerid][pA2]) // ammo stock purchase check
	{
	    new weapons, ammo;
	    for (new i = 0; i < MAX_WEAPON_SLOTS; i++)
	        GetPlayerWeaponData(playerid, i, weapons, ammo);

	    if (!strcmp(text, "1", true)) {
	        if (GetPlayerMoney(playerid) >= 150) {
	            GivePlayerWeapon(playerid, WEAPON_KNIFE, 1);
	            GivePlayerMoney(playerid, -150);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
 			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
			    PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "2", true)) {
			if (GetPlayerMoney(playerid) >= 300) {
			    GivePlayerWeapon(playerid, WEAPON_CHAINSAW, 1);
			    GivePlayerMoney(playerid, -300);
			    PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "3", true)) {
	        if (GetPlayerMoney(playerid) >= 400) {
				if (weapons == WEAPON_SILENCED) {
					SetPlayerAmmo(playerid, WEAPON_SILENCED, 15);
					GivePlayerMoney(playerid, -400);
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a Silenced 9mm to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "4", true)) {
	        if (GetPlayerMoney(playerid) >= 150) {
	            if (weapons == WEAPON_COLT45) {
					SetPlayerAmmo(playerid, WEAPON_COLT45, 15);
					GivePlayerMoney(playerid, -150);
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a 9mm to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "5", true)) {
	        if (GetPlayerMoney(playerid) >= 1000) {
	            if (weapons == WEAPON_DEAGLE) {
					SetPlayerAmmo(playerid, WEAPON_DEAGLE, 15);
					GivePlayerMoney(playerid, -150);
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a Desert Eagle to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "6", true)) {
	        if (GetPlayerMoney(playerid) >= 300) {
	            if (weapons == WEAPON_TEC9) {
					SetPlayerAmmo(playerid, WEAPON_TEC9, 15);
					GivePlayerMoney(playerid, -300);
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a TEC9 to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "7", true)) {
	        if (GetPlayerMoney(playerid) >= 450) {
	            if (weapons == WEAPON_UZI) {
	                SetPlayerAmmo(playerid, WEAPON_UZI, 15);
	                GivePlayerMoney(playerid, -450);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need an UZI to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "8", true)) {
	        if (GetPlayerMoney(playerid) >= 1750) {
				if (weapons == WEAPON_MP5) {
				    SetPlayerAmmo(playerid, WEAPON_MP5, 15);
				    GivePlayerMoney(playerid, -1750);
                    PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need an MP5 to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "9", true)) {
	        if (GetPlayerMoney(playerid) >= 600) {
	            if (weapons == WEAPON_SHOTGUN) {
	                SetPlayerAmmo(playerid, WEAPON_SHOTGUN, 15);
	                GivePlayerMoney(playerid, -600);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a Shotgun to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "10", true)) {
	        if (GetPlayerMoney(playerid) > 950) {
	            if (weapons == WEAPON_SHOTGSPA) {
	                SetPlayerAmmo(playerid, WEAPON_SHOTGSPA, 15);
	                GivePlayerMoney(playerid, -950);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a Combat Shotgun to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "11", true)) {
	        if (GetPlayerMoney(playerid) >= 900) {
	            if (weapons == WEAPON_SAWEDOFF) {
	                SetPlayerAmmo(playerid, WEAPON_SAWEDOFF, 15);
	                GivePlayerMoney(playerid, -900);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need a Sawnoff Shotgun to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "12", true)) {
	        if (GetPlayerMoney(playerid) >= 3400) {
	            if (weapons == WEAPON_AK47) {
	                SetPlayerAmmo(playerid, WEAPON_AK47, 15);
	                GivePlayerMoney(playerid, -3400);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need an AK47 to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "13", true)) {
	        if (GetPlayerMoney(playerid) >= 4300) {
	            if (weapons == WEAPON_M4) {
	                SetPlayerAmmo(playerid, WEAPON_M4, 15);
	                GivePlayerMoney(playerid, -4300);
	                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
					SendClientMessage(playerid, -1, "You need an M4 to purchase ammo for");
					PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    //else SendClientMessage(playerid, -1, "Invalid item id");
	}
	else if (GetPlayerInterior(playerid) && gPlayerInfo[playerid][pCB]) // Cluckin bell purchase check
	{
	    new Float: pHealth;

	    if (!strcmp(text, "1", true)) {
	        if (GetPlayerMoney(playerid) >= 2) {
	            GetPlayerHealth(playerid, pHealth);
	            if (floatcmp(pHealth, 95.0) == 0 || floatcmp(pHealth, 95.0) == 1) {
	            	SetPlayerHealth(playerid, 100);
	            	GivePlayerMoney(playerid, -2);
	            	PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
				else {
				    SetPlayerHealth(playerid, floatadd(pHealth, 5.0));
				    GivePlayerMoney(playerid, -2);
				    PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
				}
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "2", true)) {
	        if (GetPlayerMoney(playerid) >= 6) {
	            //new Float: pHealth;
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 10.0));
	            GivePlayerMoney(playerid, -6);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "3", true)) {
	        if (GetPlayerMoney(playerid) >= 10) {
	            //new Float: pHealth;
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 15.0));
	            GivePlayerMoney(playerid, -10);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "4", true)) {
	        if (GetPlayerMoney(playerid) >= 12) {
	            //new Float: pHealth;
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 25.0));
	            GivePlayerMoney(playerid, -12);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    //else SendClientMessage(playerid, -1, "Invalid item id");
	}
	else if (GetPlayerInterior(playerid) && gPlayerInfo[playerid][pPS]) // pizza stack purchase check
	{
	    new Float: pHealth;

	    if (!strcmp(text, "1", true)) {
	        if (GetPlayerMoney(playerid) >= 2) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 5.0));
	            GivePlayerMoney(playerid, -2);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "2", true)) {
	        if (GetPlayerMoney(playerid) >= 5) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 10.0));
	            GivePlayerMoney(playerid, -5);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "3", true)) {
	        if (GetPlayerMoney(playerid) >= 10) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 15.0));
	            GivePlayerMoney(playerid, -10);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    else if (!strcmp(text, "4", true)) {
	        if (GetPlayerMoney(playerid) >= 12) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 20.0));
	            GivePlayerMoney(playerid, -12);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    //else SendClientMessage(playerid, -1, "Invalid item id");
	}
	else if (GetPlayerInterior(playerid) && gPlayerInfo[playerid][pBS]) // burger shot purchase check
	{
	    new Float: pHealth;

	    if (!strcmp(text, "1", true)) {
	        if (GetPlayerMoney(playerid) >= 2) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 10.0));
	            GivePlayerMoney(playerid, -2);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    if (!strcmp(text, "2", true)) {
	        if (GetPlayerMoney(playerid) >= 6) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 15.0));
	            GivePlayerMoney(playerid, -6);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    if (!strcmp(text, "3", true)) {
	        if (GetPlayerMoney(playerid) >= 10) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 20.0));
	            GivePlayerMoney(playerid, -10);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
		 		SendClientMessage(playerid, -1, "You don't have enough money");
                PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    if (!strcmp(text, "4", true)) {
	        if (GetPlayerMoney(playerid) >= 15) {
	            GetPlayerHealth(playerid, pHealth);
	            SetPlayerHealth(playerid, floatadd(pHealth, 30.0));
	            GivePlayerMoney(playerid, -15);
	            PlayerPlaySound(playerid, SOUND_ID_PURCHASE_SUCCESS, 0.0, 0.0, 0.0);
			}
			else {
				SendClientMessage(playerid, -1, "You don't have enough money");
				PlayerPlaySound(playerid, SOUND_ID_PURCHASE_FAIL_2, 0.0, 0.0, 0.0);
			}
	    }
	    //else SendClientMessage(playerid, -1, "Invalid item id");
	}

	new textv2[128];
	format(textv2, sizeof (textv2), "%d >> %s: {FFFFFF}%s", playerid, pName(playerid), text);
	//SendPlayerMessageToAll(playerid, textv2);
	SendClientMessageToAll(GetPlayerColor(playerid), textv2);

	return 0; // don't process the default text
}

public OnPlayerGiveDamage(playerid, damagedid, Float: amount, weaponid)
{
	new string[128];
	format(string, sizeof (string), "%d damaged %d, amount %f with %d", playerid, damagedid, amount, weaponid);
	SendClientMessageToAll(-1, string);
	return 1;
}
public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid)
{
	new string[128];
	if (issuerid == INVALID_PLAYER_ID) {
		format(string, sizeof (string), "OnPlayerTakeDamage - playerid: %d, amount: %f, reasonid: %d", playerid, amount, weaponid);
		SendClientMessage(playerid, -1, string);
	}
	else {
	    format(string, sizeof (string), "OnPlayerTakeDamage - playerid: %d, issuerid: %d, amount: %f, weaponid: %d", playerid, issuerid, amount, weaponid);
		SendClientMessage(playerid, -1, string);
	}
	
	new Float: fHealth;
	GetPlayerHealth(playerid, fHealth);
	
	if (fHealth == fHealth - amount) SendClientMessage(playerid, -1, "OPTD if");
	else SendClientMessage(playerid, -1, "OPTD else");

	return 1;
}

public OnPlayerClickMap(playerid, Float: fX, Float: fY, Float: fZ)
{
	if (!IsPlayerAdmin(playerid)) return 0;
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if (GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
	{
	    printf("Jetpack\nplayerid: %d", playerid);
	    Kick(playerid);
	}

	static Float: health, Float: armour;
	GetPlayerHealth(playerid, health);
	GetPlayerArmour(playerid, armour);
	
	if ((floatcmp(health, MAX_PLAYER_HEALTH) == 1) || (floatcmp(armour, MAX_PLAYER_ARMOUR) == 1))
	{
	    if (gPlayerInfo[playerid][pCB] && gPlayerInfo[playerid][pPS] && gPlayerInfo[playerid][pBS])
	    {
	    	printf("Health: %.f\nArmour: %.f\nplayerid: %d\n", health, armour, playerid);
	    	Kick(playerid);
		}
	}

	if (IsPlayerInAnyVehicle(playerid))
	{
		static Float: vhealth;
		GetVehicleHealth(GetPlayerVehicleID(playerid), vhealth);
		
		if (floatcmp(vhealth, MAX_VEHICLE_HEALTH) == 1)
		{
		    printf("Vehicle health: %.f\nvehicleid: %d\nplayerid: %d", vhealth, GetPlayerVehicleID(playerid), playerid);
			Kick(playerid);
		}
	}

	static keys, UpDown, LeftRight;
	GetPlayerKeys(playerid, keys, UpDown, LeftRight);
	
	if ((UpDown != KEY_DOWN && UpDown != 0 && UpDown != KEY_UP) || (LeftRight != KEY_RIGHT && LeftRight != 0 && LeftRight != KEY_LEFT))
	    gIsPlayerUsingJoypadConfig[playerid] = true;
	else gIsPlayerUsingJoypadConfig[playerid] = false;
	
	/*if (GetPlayerAnimationIndex(playerid))
	{
		static animLib[32], animName[32], string[128];
	    GetAnimationName(GetPlayerAnimationIndex(playerid), animLib, sizeof (animLib), animName, sizeof (animName));
	    format(string, sizeof (string), "Animation name: \'%s\', library: \'%s\'", animLib, animName);
	    SendClientMessage(playerid, -1, string);
	}*/
	/*new string[128];
	format(string, sizeof (string), "IsVehicleUpsideDown: %d", IsVehicleUpsideDown(GetPlayerVehicleID(playerid)));
	SendClientMessageToAll(-1, string);*/
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	// check if player has entered the vehicle as a driver
	// from his previous state, ONFOOT
	if ((newstate == PLAYER_STATE_DRIVER || newstate == PLAYER_STATE_PASSENGER) && oldstate == PLAYER_STATE_ONFOOT)
	{
	    // he's in the vehicle, now get its health and compare it
	    // if the car's health value is bigger than 1000.0000 then
	    // set it back to 1000.0000 (max) to avoid innocent players
		// getting banned
		new Float: vHealth;
		GetVehicleHealth(GetPlayerVehicleID(playerid), vHealth);
		if (floatcmp(vHealth, 1000.00000) == 1)
		{
		    // set it back to its default health
		    SetVehicleHealth(GetPlayerVehicleID(playerid), 1000.0);
		}
	}
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	#if ENABLE_TURF_WAR
		if (newinteriorid)
		{
		    for (new i = GetMaxPlayers(), j; j < i; i++)
			{
			    if (!IsPlayerConnected(i))
			        continue;

				TextDrawHideForPlayer(playerid, TWARgzowner[i]);
			}
		}
	#endif

	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	// check if the player pressed KEY_JUMP while
	// inside the specific pickup (ammu nation and gun depo)
	if (GetPlayerInterior(playerid) && (gPlayerInfo[playerid][pA] || gPlayerInfo[playerid][pA2]) && newkeys & KEY_JUMP) {
		// if the player has done shopping, let him free
	    TogglePlayerControllable(playerid, true);

		// put the player a bit further away from the icon, since OnPlayerPickUpPickup gets
		// called once every 3 seconds while the player stays in the icon, preventing him to leave
	    if (gPlayerInfo[playerid][pA]) { // if the player is in the ammunation
	        SetPlayerPos(playerid, 292.815460, -36.109130, 1001.515625);
	        SetPlayerFacingAngle(playerid, 128.582473);
	        SetCameraBehindPlayer(playerid);

	        gPlayerInfo[playerid][pA] = false;
		}
		else { // if the player is in the gun depo (supa save)
		    SetPlayerPos(playerid, -15.774486, -176.394683, 1003.546875);
		    SetPlayerFacingAngle(playerid, 138.862014);
		    SetCameraBehindPlayer(playerid);

		    gPlayerInfo[playerid][pA2] = false;
		}

		// he's done his shopping, hide the textdraw menu
	    for (new i = 0; i < 6; i++)
	        TextDrawHideForPlayer(playerid, TDammunation[i]);
	}
	// check if the player pressed KEY_JUMP while buying
	// from a restaurant (Cluckin Bell, Pizza Stack or Burger Shot)
	else if (GetPlayerInterior(playerid) && (gPlayerInfo[playerid][pCB] || gPlayerInfo[playerid][pPS] || gPlayerInfo[playerid][pBS]) && newkeys & KEY_JUMP) {
	    // he's done eating, let him free
	    TogglePlayerControllable(playerid, true);

		if (gPlayerInfo[playerid][pCB]) { // player is in Cluckin Bell purchase pickup
		    SetPlayerPos(playerid, 369.457855, -7.066358, 1001.851562);
		    SetPlayerFacingAngle(playerid, 130.277999);
		    SetCameraBehindPlayer(playerid);

		    gPlayerInfo[playerid][pCB] = false;
		}
		else if (gPlayerInfo[playerid][pPS]) { // player is in Pizza Stack purchase pickup
		    SetCameraBehindPlayer(playerid);

		    gPlayerInfo[playerid][pPS] = false;
		}
		else { // player is in Burger Shot purchase pickup
			SetCameraBehindPlayer(playerid);

		    gPlayerInfo[playerid][pBS] = false;
		}
		// mark the player as not in the pickup
          

		// he has done eating and wants to leave, so we'll
		// hide the textdraw menu for him
	    for (new i = 0; i < 6; i++)
	        TextDrawHideForPlayer(playerid, TDrestaurant[i]);
 	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	if (pickupid == gPickupSFAmmunation[0]) { // Ammunation entrance
 		SetPlayerInterior(playerid, 1);
		SetPlayerVirtualWorld(playerid, 1);
		SetPlayerPos(playerid, 285.776306, -39.627403, 1001.515625);
		SetPlayerFacingAngle(playerid, 0.619604);
		SetCameraBehindPlayer(playerid);
	}
	else if (pickupid == gPickupSFAmmunation[1]) { // Ammunation purchase
		SetPlayerPos(playerid, 295.891235, -38.289405, 1001.515625);
  		SetPlayerFacingAngle(playerid, 180.909576);
  		SetCameraBehindPlayer(playerid);
		TogglePlayerControllable(playerid, false);

  		TextDrawSetString(TDammunation[1], "Ammunation");
		TextDrawSetString(TDammunation[2], "1.~n~2.~n~3.~n~4.~n~5.~n~6.~n~7.~n~8.~n~9.~n~10.~n~11.~n~12.");
		TextDrawSetString(TDammunation[3], "Armour~n~Silenced Pistol~n~9mm~n~Desert Eagle~n~Tec9~n~UZI~n~MP5~n~Shotgun~n~Combat Shotgun~n~Sawnoff Shotgun~n~AK47~n~M4");
		TextDrawSetString(TDammunation[4], "$250~n~$650~n~$250~n~$1250~n~$350~n~$550~n~$2100~n~$650~n~$1150~n~$950~n~$3650~n~$4750");
		TextDrawSetString(TDammunation[5], "To buy a weapon, enter its ~r~ID ~w~in chat in order to purchase it.~n~After you finished your purchases, use ~r~~k~~PED_JUMPING~ ~w~to close the box");

		gPlayerInfo[playerid][pA] = true;

		for (new i; i < 6; i++)
			TextDrawShowForPlayer(playerid, TDammunation[i]);
	}
	else if (pickupid == gPickupSFAmmunation[2]) { // Ammunation exit
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
	    SetPlayerPos(playerid, -2625.989746, 210.984558, 4.614346);
	    SetPlayerFacingAngle(playerid, 2.488606);
	    SetCameraBehindPlayer(playerid);
	}
	else if (pickupid == gPickupSFCluckinBell[0]) { // Cluckin bell entrance (near ammunation)
	    SetPlayerInterior(playerid, 9);
	    SetPlayerVirtualWorld(playerid, 1);
	    SetPlayerPos(playerid, 365.6165, -8.5820, 1001.8515);
	    SetPlayerFacingAngle(playerid, 1.7773);
	    SetCameraBehindPlayer(playerid);
	}
	else if (pickupid == gPickupSFCluckinBell[1]) { // Cluckin bell purchase
		SetPlayerPos(playerid, 370.897399, -6.492502, 1001.858886);
	    SetPlayerFacingAngle(playerid, 359.980224);
	    SetCameraBehindPlayer(playerid);
		TogglePlayerControllable(playerid, false);

	    TextDrawSetString(TDrestaurant[1], "- Cluckin' Bell menu -");
		TextDrawSetString(TDrestaurant[2], "Cluckin' Little Meal~n~~n~Cluckin' Big Meal~n~~n~Cluckin' Huge Meal~n~~n~Cluckin' Salad Meal");
		TextDrawSetString(TDrestaurant[4], "$2~n~~n~$6~n~~n~$10~n~~n~$12");

		gPlayerInfo[playerid][pCB] = true;

		for (new i = 0; i < 6; i++)
			TextDrawShowForPlayer(playerid, TDrestaurant[i]);
	}
	else if (pickupid == gPickupSFCluckinBell[2]) { // Cluckin bell exit
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
	    SetPlayerPos(playerid, -2671.4560, 263.8777, 4.6328);
	    SetPlayerFacingAngle(playerid, 358.1870);
	    SetCameraBehindPlayer(playerid);
	}
	else if (pickupid == gPickupSFCustomAmmu[0]) { // Custom Ammu entrance
	    SetPlayerInterior(playerid, 17);
	    SetPlayerVirtualWorld(playerid, 1);
	    SetPlayerPos(playerid, -24.918478, -185.938858, 1003.546875);
	    SetPlayerFacingAngle(playerid, 309.036376);
	    SetCameraBehindPlayer(playerid);
	}
	else if(pickupid == gPickupSFCustomAmmu[1]) { // Custom ammu purchase
	    SetPlayerPos(playerid, 370.897399, -6.492502, 1001.858886);
	    SetPlayerFacingAngle(playerid, 182.520263);
	    SetCameraBehindPlayer(playerid);
	    TogglePlayerControllable(playerid, false);
	    
        TextDrawSetString(TDammunation[1], "Supa Save");
	    TextDrawSetString(TDammunation[2], "1.~n~2.~n~3.~n~4.~n~5.~n~6.~n~7.~n~8.~n~9.~n~10.~n~11.~n~12.~n~13.");
	    TextDrawSetString(TDammunation[3], "Knife~n~Chainsaw~n~Silenced Pistol~n~9mm~n~Desert Deagle~n~Tec9~n~UZI~n~MP5~n~Shotgun~n~Combat Shotgun~n~Sawnoff Shotgun~n~AK47~n~M4");
	    TextDrawSetString(TDammunation[4], "$150~n~$300~n~$500~n~$150~n~$1000~n~$300~n~$450~n~$1750~n~$600~n~$950~n~$900~n~$3400~n~$4300");
		TextDrawSetString(TDammunation[5], "Here you can buy ammo for you weapons~n~~y~NOTE: you must own the weapon to buy ammo for~w~~n~After you finished your purchases, use ~r~~k~~PED_JUMPING~ ~w~to close the box");

	    gPlayerInfo[playerid][pCB] = true;
	    
	    for (new i = 0; i < 6; i++)
			TextDrawShowForPlayer(playerid, TDammunation[i]);
	}
	else if (pickupid == gPickupSFCustomAmmu[2]) { // Custom ammu exit
	    SetPlayerInterior(playerid, 0);
	    SetPlayerVirtualWorld(playerid, 0);
	    //SetPlayerPos
	    SetPlayerFacingAngle(playerid, 182.912033);
	    SetCameraBehindPlayer(playerid);
	}
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	#if ENABLE_ANTI_CHEAT
		if (!GetPlayerInterior(playerid)) {
	    	SendClientMessage(playerid, -1, "OnVehicleMod: Busted");
		}
		//SendFormattedMessage(playerid, TEXT_RED, "OnVehicleMod - pid: %d, vid: %d, cid: %d", playerid, vehicleid, componentid);
	#endif

	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	#if ENABLE_ANTI_CHEAT
		if (!GetPlayerInterior(playerid)) {
	    	SendClientMessage(playerid, -1, "OnVehiclePaintJob: Busted");
		}
		//SendFormattedMessage(playerid, TEXT_GREEN, "OnVehiclePaintjob - pid: %d, vid: %d, pjid: %d", playerid, vehicleid, paintjobid);
	#endif

	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	#if ENABLE_ANTI_CHEAT
		if (!GetPlayerInterior(playerid)) {
	    	SendClientMessage(playerid, -1, "OnVehicleRespray: Busted");
		}
    	//SendFormattedMessage(playerid, TEXT_BLUE, "OnVehicleRespray - pid: %d, vid: %d, c1: %d, c2: %d", playerid, vehicleid, color1, color2);
    #endif

    return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
	return 1;
}

public OnVehicleDeath(vehicleid)
{
	new string[128];
	format(string, sizeof (string), "OnVehicleDeath: vehicleid: %d", vehicleid);
	SendClientMessageToAll(-1, string);
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	return 1;
}

public OnQueryError(errorid, error[], callback[], query[], connectionHandle)
{
	return 1;
}
//==============================================================================

public DelayedKick(playerid)
{
	Kick(playerid);
}

public HideIntroTextDraw(playerid, Text: IntroText[2])
{
	TextDrawHideForPlayer(playerid, IntroText[0]);
 	TextDrawHideForPlayer(playerid, IntroText[1]);
}

#if ENABLE_TURF_WAR
	public turfwar_AddGangZoneDelayed()
	{
    	for (new i; i < MAX_TURFS; i++)
 			gTurfInfo[i][turfid] = GangZoneCreate(gTurfInfo[i][minx], gTurfInfo[i][miny], gTurfInfo[i][maxx], gTurfInfo[i][maxy]);

		print("** Turfs created...");
	}

	public turfwar_ShowGangZoneDelayed(playerid)
	{
		for (new i; i < MAX_TURFS; i++)
			GangZoneShowForPlayer(playerid, gTurfInfo[i][turfid], gTurfInfo[i][colour]);
		printf("showing turfs for id %d", playerid);
	}

	stock turfwar_GetGangZoneOwner(playerid, zone[], lenght)
	{
	    new Float: xpos[3];
	    GetPlayerPos(playerid, xpos[0], xpos[1], xpos[2]); // we're not using the z coordonate

	    for (new i; i < sizeof (gTurfInfo); i++)
		{
 			if ((xpos[0] >= gTurfInfo[i][minx]) && (xpos[0] <= gTurfInfo[i][maxx]) && (xpos[1] >= gTurfInfo[i][miny]) && (xpos[1] <= gTurfInfo[i][maxy])) {
   				return format(zone, lenght, gTurfInfo[i][owner]);
			}
		}
		return 0;
	}

	public turfwar_UpdateGangZone()
	{
	    for (new i; i < MAX_PLAYERS; i++)
		{
 			if (!IsPlayerConnected(i))
 		    	continue;

			new zone[MAX_GANG_NAME], string[64];
			turfwar_GetGangZoneOwner(i, zone, MAX_GANG_NAME);

			format(string, sizeof (string), "%s", zone);
			TextDrawSetString(TWARgzowner[i], string);
			TextDrawShowForPlayer(i, TWARgzowner[i]);
		}
		return 1;
	}
#endif

stock IsVehicleUpsideDown(vehicleid)
{
	new Float: w, Float: x, Float: y, Float: z;
	GetVehicleRotationQuat(vehicleid, w, x, y, z);

	#pragma unused w, y, z

	return !(x < 0.5 && x > -0.5);
}

stock FormatTimestamp(timestamp)
{
	new days, hours, minutes;
	
	timestamp -= gettime();
	
	days = floatround(timestamp / (60 * 60 * 24), floatround_floor);
	timestamp %= 60 * 60 * 24;
	
	hours = floatround(timestamp / (60 * 60), floatround_floor);
	timestamp %= 60 * 60;
	
	minutes = floatround(timestamp / 60, floatround_floor);
	
	new string[128];
	format(string, sizeof (string), "%d days, %d hours, %d minutes", days, hours, minutes);
	return string;
}
#include "../sfb/stock.pwn"

stock IsValidSkin(skinid)
{
    switch(skinid)
    {
        case 3, 4, 5, 6, 8, 42, 53, 65, 74, 86, 91, 119, 149, 208, 273, 289: return 0;
    }
    return 1;
}
// EOF
#include "../gm/mysql_forwards.pwn"
