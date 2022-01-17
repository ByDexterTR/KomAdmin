#include <sourcemod>
#include <komadmin>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[KomAdmin] - Dokunulmazlık", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ConVar Immunity = null, Immunity_ban = null, Immunity_kick = null;

int Oldim = 0;

public void OnPluginStart()
{
	AddCommandListener(ListenerBan, "sm_ban");
	AddCommandListener(ListenerBan, "sm_banip");
	AddCommandListener(ListenerBan, "sm_addban");
	AddCommandListener(ListenerKick, "sm_kick");
	Immunity = CreateConVar("sm_komadmin_immunity", "100", "Komutçu admini olan kişinin dokunulmazlığı kaç olsun", 0, true, 1.0, true, 100.0);
	Immunity_kick = CreateConVar("sm_komadmin_immunity_kick", "0", "Komutçu admini verilen dokunulmazlık ile mi kick atsın? [ 0 = Hayır | 1 = Evet ]", 0, true, 0.0, true, 1.0);
	Immunity_ban = CreateConVar("sm_komadmin_immunity_ban", "0", "Komutçu admini verilen dokunulmazlık ile mi ban atsın? [ 0 = Hayır | 1 = Evet ]", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "komadmin_immunity", "ByDexter");
}

public Action ListenerKick(int client, const char[] command, int argc)
{
	if (!Immunity_kick.BoolValue)
	{
		char Arg[256];
		GetCmdArgString(Arg, 256);
		SetAdminImmunityLevel(GetUserAdmin(client), Oldim);
		ClientCommand(client, "%s %s", command, Arg);
		SetAdminImmunityLevel(GetUserAdmin(client), Immunity.IntValue);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action ListenerBan(int client, const char[] command, int argc)
{
	if (!Immunity_ban.BoolValue)
	{
		char Arg[256];
		GetCmdArgString(Arg, 256);
		SetAdminImmunityLevel(GetUserAdmin(client), Oldim);
		ClientCommand(client, "%s %s", command, Arg);
		SetAdminImmunityLevel(GetUserAdmin(client), Immunity.IntValue);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void OnKomAdminCreated(int client)
{
	Oldim = GetAdminImmunityLevel(GetUserAdmin(client));
	SetAdminImmunityLevel(GetUserAdmin(client), Immunity.IntValue);
}

public void OnKomAdminRemoved(int client)
{
	SetAdminImmunityLevel(GetUserAdmin(client), Oldim);
} 