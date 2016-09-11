
forward OnPlayerCmdHelp(playerid);
public OnPlayerCmdHelp(playerid)
{
	new rows, fields;
	cache_get_data(rows, fields, ssys);
	if (rows)
	{
	    new capt[64], info[256];
	    cache_get_row(0, 0, capt);
	    cache_get_row(0, 1, info);
	    ShowPlayerDialog(playerid, DIALOG_CMD_COMMANDS_S, DIALOG_STYLE_MSGBOX, capt, info, "Close", "");
	}
	else ShowPlayerDialog(playerid, DIALOG_CMD_COMMANDS_F, DIALOG_STYLE_MSGBOX, "Commands", "We're sorry, this command is currently unavailable", "Close", "");
	
	return 1;
}

forward OnPlayerCmdRegister(playerid);
public OnPlayerCmdRegister(playerid)
{
	new string[128];
	format(string, sizeof(string), "Successfully registered: UserID - %d", mysql_insert_id(asys));
	SendClientMessage(playerid, -1, string);

	gPlayerInfo[playerid][level] = 1;
	gPlayerInfo[playerid][logged] = true;
	gPlayerInfo[playerid][registered] = true;
	return 1;
}

forward OnPlayerCmdLogin(playerid);
public OnPlayerCmdLogin(playerid)
{
	new rows, fields;
	cache_get_data(rows, fields, asys);
	if (rows) {
	    new temp[32];
	    cache_get_field_content(0, "userid", temp, asys); gPlayerInfo[playerid][userid] = strval(temp);
	    cache_get_field_content(0, "level", temp, asys); gPlayerInfo[playerid][level] = strval(temp);
		cache_get_field_content(0, "kills", temp, asys); gPlayerInfo[playerid][kills] = strval(temp);
		cache_get_field_content(0, "deaths", temp, asys); gPlayerInfo[playerid][deaths] = strval(temp);
		cache_get_field_content(0, "money", temp, asys); gPlayerInfo[playerid][money] = strval(temp);
		
		new string[128];
		format(string, sizeof(string), "success - data received: %d, %d, %d, %d, %d", gPlayerInfo[playerid][userid], gPlayerInfo[playerid][level], gPlayerInfo[playerid][kills], gPlayerInfo[playerid][deaths], gPlayerInfo[playerid][money]);
		SendClientMessage(playerid, -1, string);
		printf("data received: %d, %d, %d, %d, %d", gPlayerInfo[playerid][userid], gPlayerInfo[playerid][level], gPlayerInfo[playerid][kills], gPlayerInfo[playerid][deaths], gPlayerInfo[playerid][money]);
		
		gPlayerInfo[playerid][logged] = true;
	}
	else SendClientMessage(playerid, -1, "Wrong password.");
	
	return 1;
}

forward OPC_CheckIfRegistered(playerid);
public OPC_CheckIfRegistered(playerid)
{
	new rows, fields;
	cache_get_data(rows, fields, asys);
	if (rows) SendClientMessage(playerid, -1, "You're registered, please login");
	else {
	    SendClientMessage(playerid, -1, "You are not registered, /register your nick");
	    gPlayerInfo[playerid][registered] = false;
	}
	return 1;
}

forward OnVehicleLoad();
public OnVehicleLoad()
{
	new rows, fields, c;
	cache_get_data(rows, fields, ssys);
	for (new i; i != rows; i++)
	{
		new modelid[3], spawnx[12], spawny[12], spawnz[12], spawna[12], color1[4], color2[4];
		cache_get_field_content(0, "model", modelid, ssys);
		cache_get_field_content(0, "spawnx", spawnx, ssys);
		cache_get_field_content(0, "spawny", spawny, ssys);
		cache_get_field_content(0, "spawnz", spawnz, ssys);
		cache_get_field_content(0, "spawna", spawna, ssys);
		cache_get_field_content(0, "colour1", color1, ssys);
		cache_get_field_content(0, "colour2", color2, ssys);
		AddStaticVehicleEx(strval(modelid), floatstr(spawnx), floatstr(spawny), floatstr(spawnz), floatstr(spawna), strval(color1), strval(color2), 600);
	}
	printf("loaded vehs: %d", c);
	c = 0;
	new i;
	printf("i=%d", i);
	
	return 1;
}
