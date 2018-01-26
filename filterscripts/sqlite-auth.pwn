#include a_samp
#define dcmd(%1,%2,%3) \
  if (!strcmp((%3)[1], #%1, true, (%2)) && ((((%3)[(%2) + 1] == '\0') && (dcmd_%1(playerid, ""))) || (((%3)[(%2) + 1] == ' ') && (dcmd_%1(playerid, (%3)[(%2) + 2]))))) return 1
	
#define CMD: dcmd_
#define FormatQuery(%0, %1, %2) format((%0), sizeof(%0), (%1), %2)

enum P_ENUM_DATA
{
  Scor,
  Bani,
  PlayerIP,
  bool: Logged
}

new 
  P_DATA[MAX_PLAYERS][P_ENUM_DATA],
  DB: Database;
	
public OnFilterScriptInit()
{
  Database = db_open("Conturi.db");
  db_free_result(db_query(Database, "CREATE TABLE Users (id integer primary key autoincrement, house integer)"));
  return 1;
}

public OnFilterScriptExit()
{
  db_close(Database);
  return 1;
}

CMD:register(playerid,params[])
{
  if (P_DATA[playerid][Logged]) return SendClientMessage(playerid, ~1, "Esti deja logat!");
  
  new Query[256], DBResult: Result;
	
  format(Query, sizeof(Query), "SELECT * FROM `Users` WHERE `Nume` = '%s'", Name(playerid));
  Result = db_query(Database, Query);
  
  if (!db_num_rows(Result))
  {
    if (strlen(params))
    {
      if (strlen(params) > 5 && strlen(params) < 24)
      {
        FormatQuery(Query, "INSERT INTO `Users` (`IP`,`Nume`,`Parola`,`Bani`,`Scor`) VALUES ('%s','%s','%s','%d','%d')",
          GetPlayerIPEx(playerid), Name(playerid), params, GetPlayerMoney(playerid), GetPlayerScore(playerid));
          
        db_free_result(db_query(Database, Query));
        
        SendClientMessage(playerid, ~1, "Te-ai inregistrat cu success!");
        format(Query, 256, "Parola ta este: %s.", params);
        SendClientMessage(playerid, ~1, Query);
      }
      else return SendClientMessage(playerid, ~1, "Parola trebuie sa contina minimum 5 caractere si maximum 24.");
    }
    else return SendClientMessage(playerid, ~1, "Sintaxa invalida! Foloseste /register <parola>");
  }
  else return SendClientMessage(playerid, ~1, "Contul tau deja exista, foloseste /login <parola>");
  return 1;
}
  
CMD:login(playerid,params[])
{
  if (P_DATA[playerid][Logged]) return SendClientMessage(playerid, ~1, "Esti deja logat!");
  
  if (strlen(params))
  {
    new Query[256], DBResult: Result;
    
    FormatQuery(Query, "SELECT * FROM `Users` WHERE `Nume` = '%s'", Name(playerid));
    Result = db_query(Database, Query);
    
    if(db_num_rows(Result))
    {
      FormatQuery(Query, "SELECT * FROM `Users` WHERE `Nume` = '%s' AND `Parola` = '%s'", Name(playerid), params);
      Result = db_query(Database, Query);
      
      if (db_num_rows(Result))
      {
        new Field[30];
        
        P_DATA[playerid][Logged] = true;
        
        db_get_field_assoc(Result, "Bani", Field, 30);
        P_DATA[playerid][Bani] = strval(Field);
        
        db_get_field_assoc(Result, "Scor", Field, 30);
        P_DATA[playerid][Scor] = strval(Field);
        
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, P_DATA[playerid][Bani]);
        SetPlayerScore(playerid, P_DATA[playerid][Scor]);
        
        new Str[129];
        format(Str, sizeof(Str), "Te-ai logat cu success! Ai %d bani si %d scor", P_DATA[playerid][Bani], P_DATA[playerid][Scor]);
        SendClientMessage(playerid, ~1, Str);
      }
      else
      {
        SendClientMessage(playerid, ~1, "Parola nu coincide cu parola din baza de date! Te rog mai incearca!");
      }
    }
    else
    {
      new Str[129];
      format(Str, sizeof(Str), "Contul %s nu exista in baza de date! Inregistreaza-te cu /register <parola>", Name(playerid));
      SendClientMessage(playerid, ~1, Str);
    }
    db_free_result(Result);
  }
  else
  {
    SendClientMessage(playerid, ~1, "Sintaxa invalida! Foloseste /login <parola>");
  }
  return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
  /*
  dcmd(login, 5, cmdtext);
  dcmd(register, 8, cmdtext);
  return 0;
  */
}

public OnPlayerConnect(playerid)
{
  new Query[256], DBResult: Result;
  
  db_query(Database, "INSERT INTO `Users` ('house') VALUES ('120')");
  format(Query, sizeof(Query), "SELECT * FROM `Users` WHERE `Nume` = '%s'", Name(playerid));
  Result = db_query(Database, Query);
  
  if (db_num_rows(Result))
  {
    SendClientMessage(playerid, ~1, "Acest nume este inregistrat! Te rog sa te loghezi! Foloseste /login <parola>");
  }
  else
  {
    SendClientMessage(playerid, ~1, "Acest nume nu este inregistrat! Te rog sa te inregistrezi, foloseste /register <parola>");
  }
  db_free_result(Result);
  P_DATA[playerid][Logged] = false;
  return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
  if (P_DATA[playerid][Logged])
  {
    new Query[256];
    format(Query, sizeof(Query), "UPDATE `Users` SET (`Bani` = '%d', `Scor` = '%d') WHERE `Nume` = '%s'",
      P_DATA[playerid][Bani], P_DATA[playerid][Scor], Name(playerid));
      
    db_free_result(db_query(Database, Query));
    P_DATA[playerid][Logged] = false;
  }
  return 1;
}

GetPlayerIPEx(playerid) {
  new IP[24];
  GetPlayerIp(playerid, IP, 24);
  return IP;
}

Name(i) {
  new n[24];
  GetPlayerName(i, n, 24);
  return n;
}
