#include <sourcemod>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

int KomAdmin = -1;

Handle Forward_KaCreated = null, Forward_RemoveKa = null;

public Plugin myinfo = 
{
	name = "Komutçu Admini", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_ka", Command_Ka, "Birisini komutçu admini seçmek için menü açar.");
	
	RegConsoleCmd("sm_kasil", Command_Kasil, "Komutçu adminini siler.");
	RegConsoleCmd("sm_kakov", Command_Kasil, "Komutçu adminini siler.");
	RegConsoleCmd("sm_kacik", Command_Kasil, "Komutçu adminliğinden ayrılır.");
	RegConsoleCmd("sm_kaayril", Command_Kasil, "Komutçu adminliğinden ayrılır.");
	
	HookEvent("player_team", OnClientTeamChanged);
	
	Forward_KaCreated = CreateGlobalForward("OnKomAdminCreated", ET_Ignore, Param_Cell);
	Forward_RemoveKa = CreateGlobalForward("OnKomAdminRemoved", ET_Ignore, Param_Cell);
}

public Action OnClientTeamChanged(Event event, const char[] name, bool dB)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && client == KomAdmin)
	{
		int Team = event.GetInt("team");
		bool Disconnect = event.GetBool("disconnect");
		if (Disconnect)
		{
			PrintToChatAll("[SM] \x10%N \x01oyundan ayrıldı", client);
			RemoveKa();
		}
		else
		{
			if (Team != 2)
			{
				PrintToChatAll("[SM] \x10%N \x01terörist takımından ayrıldı", client);
				RemoveKa();
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (client == KomAdmin)
	{
		PrintToChatAll("[SM] \x10%N \x01oyundan ayrıldı", client);
		RemoveKa();
	}
}

public Action Command_Ka(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "not_a_command", ADMFLAG_ROOT, true))
	{
		if (KomAdmin != -1)
		{
			ReplyToCommand(client, "[SM] \x10%N \x01zaten Komutçu admini: \x0B!kasil", client);
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(Kamenu_callback);
		menu.SetTitle("Komutçu Admini Yardımcını Belirle\n ");
		menu.AddItem("030117", "SAYFAYI YENİLE");
		menu.AddItem("711030", "Rastgele Bir Yetkiliye Sor\n ");
		int id; char displayid[16]; char name[128];
		for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2 && GetUserAdmin(i) != INVALID_ADMIN_ID)
		{
			id = GetClientUserId(i);
			GetClientName(i, name, 128);
			FormatEx(displayid, 16, "%d", id);
			menu.AddItem(displayid, name);
		}
		menu.Display(client, 15);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public int Kamenu_callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		char item[16];
		menu.GetItem(position, item, 16);
		if (StringToInt(item) == 030117)
		{
			Command_Ka(client, 0);
		}
		else if (StringToInt(item) == 711030)
		{
			int Sayi = 0;
			int Say[65] = { 0, ... };
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2 && GetUserAdmin(i) != INVALID_ADMIN_ID)
			{
				Sayi++;
				Say[i] = Sayi;
			}
			int RandomSayi = GetRandomInt(1, Sayi);
			for (int i = 1; i <= MaxClients; i++)if (IsValidClient(i) && GetClientTeam(i) == 2 && GetUserAdmin(i) != INVALID_ADMIN_ID)
			{
				if (Say[i] == RandomSayi)
				{
					SorMenu().Display(i, 15);
				}
			}
		}
		else
		{
			SorMenu().Display(GetClientOfUserId(StringToInt(item)), 15);
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

Menu SorMenu()
{
	Menu menu = new Menu(Sorumenu_callback);
	menu.SetTitle("Komutçu Admini Olmak İster Misin?\n ");
	menu.AddItem("0", "Evet");
	menu.AddItem("1", "Hayır\n ");
	menu.ExitButton = false;
	menu.ExitBackButton = false;
	return menu;
}

public int Sorumenu_callback(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_Select)
	{
		switch (position)
		{
			case 0:
			{
				if (KomAdmin != -1)
				{
					PrintToChatAll("[SM] \x10%N \x01kovuldu artık \x06Komutçu admini \x01yok", client);
					Call_StartForward(Forward_RemoveKa);
					Call_PushCell(KomAdmin);
					Call_Finish();
				}
				SetClientKa(client);
			}
			case 1:
			{
				PrintToChatAll("[SM] \x10%N \x06Komutçu admini \x01olmak istemedi.", client);
			}
		}
	}
	else if (action == MenuAction_End)
		delete menu;
	else if (action == MenuAction_Cancel && position == MenuCancel_Timeout)
		PrintToChatAll("[SM] \x10%N \x06Komutçu admini \x01sorusuna yanıt vermedi.", client);
}

public Action Command_Kasil(int client, int args)
{
	if (warden_iswarden(client) || client == KomAdmin || CheckCommandAccess(client, "not_a_command", ADMFLAG_ROOT, true))
	{
		if (KomAdmin == -1)
		{
			ReplyToCommand(client, "[SM] Zaten Komutçu admini yok: \x0B!ka", client);
			return Plugin_Handled;
		}
		
		PrintToChatAll("[SM] \x10%N \x01Komutçu admini kovdu.", client);
		RemoveKa();
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] Bu komuta erişiminiz yok.");
		return Plugin_Handled;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsKaExist", Native_IsKaExist);
	CreateNative("IsClientKa", Native_IsClientKa);
	CreateNative("SetClientKa", Native_SetClientKa);
	CreateNative("RemoveClientKa", Native_RemoveClientKa);
	CreateNative("RemoveKa", Native_RemoveKa);
	
	RegPluginLibrary("komadmin");
	
	return APLRes_Success;
}

public int Native_IsKaExist(Handle plugin, int numParams)
{
	if (KomAdmin != -1)
		return true;
	
	return false;
}

public int Native_IsClientKa(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsValidClient(client))
		ThrowNativeError(SP_ERROR_INDEX, "%i Geçerli bir kullanıcı değil", client);
	
	if (client == KomAdmin)
		return true;
	
	return false;
}

public int Native_SetClientKa(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsValidClient(client))
		ThrowNativeError(SP_ERROR_INDEX, "%i Geçerli bir kullanıcı değil", client);
	
	if (KomAdmin == -1)
		SetClientKa(client);
	else
		ThrowNativeError(SP_ERROR_INDEX, "Birisi zaten Komutçu admini");
}

void SetClientKa(int client)
{
	if (IsValidClient(client))
	{
		KomAdmin = client;
		PrintToChatAll("[SM] \x10%N \x01Yeni \x06Komutçu admini \x01oldu.", client);
		Call_StartForward(Forward_KaCreated);
		Call_PushCell(client);
		Call_Finish();
	}
}

public int Native_RemoveClientKa(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsValidClient(client))
		ThrowNativeError(SP_ERROR_INDEX, "%i Geçerli bir kullanıcı değil", client);
	
	if (KomAdmin == client)
		RemoveKa();
	else
		ThrowNativeError(SP_ERROR_INDEX, "Kullanıcı zaten Komutçu admini değil");
}

public int Native_RemoveKa(Handle plugin, int numParams)
{
	if (KomAdmin != -1)
		RemoveKa();
	else
		ThrowNativeError(SP_ERROR_INDEX, "Zaten Komutçu admini yok");
}

void RemoveKa()
{
	PrintToChatAll("[SM] \x10%N \x01kovuldu artık \x06Komutçu admini \x01yok", KomAdmin);
	Call_StartForward(Forward_RemoveKa);
	Call_PushCell(KomAdmin);
	Call_Finish();
	KomAdmin = -1;
	
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}
