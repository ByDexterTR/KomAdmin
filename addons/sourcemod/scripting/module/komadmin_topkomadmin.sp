#include <sourcemod>
#include <sdktools>
#include <komadmin>

#pragma semicolon 1
#pragma newdecls required

int g_iPlayTimeWeek[65] = 0;
bool g_bChecked[65], g_bIsMySQl;
char g_sSQLBuffer[3096];

Handle g_hDB = null;
int g_iHours, g_iMinutes, g_iSeconds;

public Plugin myinfo = 
{
	name = "Top Komutçu Admin", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_topka", Command_TopKomAdmin);
	RegConsoleCmd("sm_topkomadmin", Command_TopKomAdmin);
	RegConsoleCmd("sm_kasurem", Command_KaSurem);
	RegConsoleCmd("sm_komadminsurem", Command_KaSurem);
	RegAdminCmd("sm_topkareset", Command_TopKomAdminReset, ADMFLAG_ROOT);
	SQL_TConnect(OnSQLConnect, "topkomadmin");
}

public void OnMapStart()
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	char Filename[256];
	GetPluginFilename(INVALID_HANDLE, Filename, 256);
	if (strncmp(map, "workshop/", 9, false) == 0)
	{
		if (StrContains(map, "/jb_", false) == -1 && StrContains(map, "/jail_", false) == -1 && StrContains(map, "/ba_jail", false) == -1)
			ServerCommand("sm plugins unload %s", Filename);
	}
	else if (strncmp(map, "jb_", 3, false) != 0 && strncmp(map, "jail_", 5, false) != 0 && strncmp(map, "ba_jail", 3, false) != 0)
		ServerCommand("sm plugins unload %s", Filename);
	
	CreateTimer(1.0, PlayTimeTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public int OnSQLConnect(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == null)
	{
		LogError("Database failure: %s", error);
		SetFailState("Databases dont work");
	}
	else
	{
		g_hDB = hndl;
		
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDB), g_sSQLBuffer, sizeof(g_sSQLBuffer));
		g_bIsMySQl = StrEqual(g_sSQLBuffer, "mysql", false) ? true : false;
		
		if (g_bIsMySQl)
		{
			SQL_FastQuery(g_hDB, "SET NAMES UTF8");
			SQL_FastQuery(g_hDB, "SET CHARACTER SET utf8mb4_unicode_ci");
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS `topkomadmin` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) PRIMARY KEY NOT NULL, `weekly` INT(16))");
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
		else
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS topkomadmin (playername varchar(128) NOT NULL, steamid varchar(32) PRIMARY KEY NOT NULL, weekly INTEGER)");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
	}
}

public int OnSQLConnectCallback(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == null)
	{
		if (StrContains(error, "Duplicate", false) != -1)
		{
			LogError("Query failure: %s", error);
			return;
		}
	}
	else
	{
		for (int client = 1; client <= MaxClients; client++)if (IsClientInGame(client) && !IsFakeClient(client))
			OnClientPostAdminCheck(client);
	}
}

public void OnClientDisconnect(int client)
{
	if (!IsFakeClient(client) && g_bChecked[client])
		SaveSQLCookies(client);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
		CheckSQLSteamID(client);
}

public Action Command_TopKomAdmin(int client, int args)
{
	ShowTotal(client);
	Command_KaSurem(client, 0);
	return Plugin_Handled;
}

public Action Command_KaSurem(int client, int args)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	char buffer[128];
	Format(buffer, sizeof(buffer), "SELECT weekly FROM topkomadmin WHERE steamid = '%s'", steamid);
	SQL_TQuery(g_hDB, SQLShowWasteTime, buffer, client);
	return Plugin_Handled;
}

public Action Command_TopKomAdminReset(int client, int args)
{
	Menu menu = new Menu(ConfirmHandle);
	menu.SetTitle("Top KomAdmin Sıfırlansın Mı?\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿");
	menu.AddItem("Yes", "Evet");
	menu.AddItem("No", "İptal Et\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿");
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ConfirmHandle(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		switch (position)
		{
			case 0:
			{
				if (g_hDB != null)
				{
					for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
					{
						OnClientDisconnect(i);
						OnClientPostAdminCheck(i);
					}
					char buffer[3096];
					Format(buffer, sizeof(buffer), "SELECT playername, weekly, steamid FROM topkomadmin ORDER BY weekly DESC LIMIT 999");
					SQL_TQuery(g_hDB, SendLog, buffer);
					PrintToChat(client, "[SM] \x01Başarıyla anlık süre bilgisi \x0EPanele \x01kaydedildi!");
					
					Format(buffer, sizeof(buffer), "DELETE FROM topkomadmin;");
					SQL_TQuery(g_hDB, SaveSQLPlayerCallback, buffer);
					for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
					{
						OnClientDisconnect(i);
						OnClientPostAdminCheck(i);
					}
					PrintToChatAll("[SM] \x0E%N \x01top komutçu admin sürelerini sıfırladı!", client);
				}
				else
				{
					LogError("Sifirlama islemi basarisiz database baglantisi yok!");
				}
			}
			case 1:
			{
				Command_TopKomAdminReset(client, 0);
				PrintHintText(client, "Sıfırlama işlemi başarıyla iptal edildi");
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

public int SaveSQLPlayerCallback(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == null)
	{
		if (StrContains(error, "Duplicate", false) != -1)
		{
			LogError("Query failure: %s", error);
			return;
		}
	}
}

public void CheckSQLSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	Format(query, sizeof(query), "SELECT weekly FROM topkomadmin WHERE steamid = '%s'", steamid);
	SQL_TQuery(g_hDB, CheckSQLSteamIDCallback, query, GetClientUserId(client));
}

public int CheckSQLSteamIDCallback(Handle owner, Handle hndl, char[] error, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client == 0)
	{
		return;
	}
	
	if (hndl == null)
	{
		LogError("Query failure: %s", error);
		return;
	}
	if (!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl))
	{
		InsertSQLNewPlayer(client);
		return;
	}
	
	g_iPlayTimeWeek[client] = SQL_FetchInt(hndl, 0);
	g_bChecked[client] = true;
}

public void InsertSQLNewPlayer(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH + 1];
	char SafeName[(sizeof(Name) * 2) + 1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}
	
	Format(query, sizeof(query), "INSERT INTO topkomadmin(playername, steamid, weekly) VALUES('%s', '%s', '0');", SafeName, steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, query, userid);
	g_iPlayTimeWeek[client] = 0;
	g_bChecked[client] = true;
}

public void SaveSQLCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	char Name[MAX_NAME_LENGTH + 1];
	char SafeName[(sizeof(Name) * 2) + 1];
	if (!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}
	
	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE topkomadmin SET playername = '%s', weekly = '%i' WHERE steamid = '%s';", SafeName, g_iPlayTimeWeek[client], steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, buffer);
	g_bChecked[client] = false;
}

public Action PlayTimeTimer(Handle timer)
{
	if (IsKaExist())
	{
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && IsClientKa(i))
		{
			g_iPlayTimeWeek[i]++;
			OnClientDisconnect(i);
			OnClientPostAdminCheck(i);
		}
	}
}

public int SendLog(Handle owner, Handle hndl, char[] error, any data)
{
	if (hndl == null)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	int order = 0;
	char name[64], textbuffer[128], steamid[128];
	int nazim = 999;
	
	char g_LogPath[256], Formatlama[20];
	
	FormatTime(Formatlama, 20, "%d_%b_%Y", GetTime());
	BuildPath(Path_SM, g_LogPath, sizeof(g_LogPath), "logs/topkomadmin_%s.txt", Formatlama);
	
	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			if (order <= nazim--)
			{
				order++;
				SQL_FetchString(hndl, 0, name, sizeof(name));
				SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
				g_iHours = 0;
				g_iMinutes = 0;
				g_iSeconds = 0;
				ShowTimer2(SQL_FetchInt(hndl, 1));
				
				Format(textbuffer, sizeof(textbuffer), "%i | %s - %d Saat %d Dakika %d Saniye - Steamid: %s", order, name, g_iHours, g_iMinutes, g_iSeconds, steamid);
				if (g_iHours == 0 && g_iMinutes == 0 && g_iSeconds == 0) { /* DO NOTHING */ }
				else
					LogToFileEx(g_LogPath, textbuffer);
			}
			else
				break;
		}
	}
}

public void ShowTotal(int client)
{
	if (g_hDB != null)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, weekly, steamid FROM topkomadmin ORDER BY weekly DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowTotalCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Top Komutçu Admin sistemi veritabanı şu anda çalışmıyor :(");
	}
}

public int ShowTotalCallback(Handle owner, Handle hndl, char[] error, any client)
{
	if (hndl == null)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = new Menu(DIDMenuHandler2);
	menu2.SetTitle("Top Komutçu Admin\n＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿\n ");
	
	int order = 0;
	char name[64];
	char textbuffer[128];
	char steamid[32];
	
	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			g_iHours = 0;
			g_iMinutes = 0;
			g_iSeconds = 0;
			ShowTimer2(SQL_FetchInt(hndl, 1));
			Format(textbuffer, 128, "%i | %s - %d Saat %d Dk. %d Sn.", order, name, g_iHours, g_iMinutes, g_iSeconds);
			if (g_iHours == 0 && g_iMinutes == 0 && g_iSeconds == 0) { /* DO NOTHING*/ }
			else
				menu2.AddItem(steamid, textbuffer);
		}
	}
	if (order < 1)
		menu2.AddItem("empty", "TopKomAdmin Boş!", ITEMDRAW_DISABLED);
	
	menu2.Display(client, MENU_TIME_FOREVER);
}

public int DIDMenuHandler2(Menu menu2, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		char info[128], community[128];
		
		menu2.GetItem(itemNum, info, sizeof(info));
		GetCommunityID(info, community, sizeof(community));
		
		Format(community, sizeof(community), "http://steamcommunity.com/profiles/%s", community);
		PrintToChat(client, " \x02%s", community);
		PrintToConsole(client, community);
	}
	else if (action == MenuAction_Cancel)
	{
		if (itemNum == MenuCancel_NoDisplay)
			PrintToChat(client, "[SM] \x01Top Komutçu Admin kayıtlarında bir karışıklık olmuş.");
	}
	else if (action == MenuAction_End)
		delete menu2;
}

int ShowTimer(int Time, char[] buffer, int sizef)
{
	g_iHours = 0;
	g_iMinutes = 0;
	g_iSeconds = Time;
	
	while (g_iSeconds > 3600)
	{
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while (g_iSeconds > 60)
	{
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if (g_iHours >= 1)
	{
		Format(buffer, sizef, "%d Saat %d Dakika %d Saniye", g_iHours, g_iMinutes, g_iSeconds);
	}
	else if (g_iMinutes >= 1)
	{
		Format(buffer, sizef, "%d Dakika %d Saniye", g_iMinutes, g_iSeconds);
	}
	else
	{
		Format(buffer, sizef, "%d Saniye", g_iSeconds);
	}
}

void ShowTimer2(int Time)
{
	g_iHours = 0;
	g_iMinutes = 0;
	g_iSeconds = Time;
	
	while (g_iSeconds > 3600)
	{
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while (g_iSeconds > 60)
	{
		g_iMinutes++;
		g_iSeconds -= 60;
	}
}

bool GetCommunityID(char[] AuthID, char[] FriendID, int size)
{
	if (strlen(AuthID) < 11 || AuthID[0] != 'S' || AuthID[6] == 'I')
	{
		FriendID[0] = 0;
		return false;
	}
	int iUpper = 765611979;
	int iFriendID = StringToInt(AuthID[10]) * 2 + 60265728 + AuthID[8] - 48;
	int iDiv = iFriendID / 100000000;
	int iIdx = 9 - (iDiv ? iDiv / 10 + 1:0);
	iUpper += iDiv;
	IntToString(iFriendID, FriendID[iIdx], size - iIdx);
	iIdx = FriendID[9];
	IntToString(iUpper, FriendID, size);
	FriendID[9] = iIdx;
	return true;
}

public int SQLShowWasteTime(Handle owner, Handle hndl, char[] error, int client)
{
	if (hndl == null)
	{
		if (StrContains(error, "Duplicate", false) != -1)
		{
			LogError("Query failure: %s", error);
			return;
		}
	}
	
	while (SQL_FetchRow(hndl))
	{
		char buffer[124];
		ShowTimer(SQL_FetchInt(hndl, 0), buffer, sizeof(buffer));
		if (IsClientInGame(client) && !IsFakeClient(client))
			PrintToChat(client, "[SM] Toplam \x04%s \x01komadmin olmuşsun!", buffer);
	}
	
	delete hndl;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
		OnClientDisconnect(i);
} 