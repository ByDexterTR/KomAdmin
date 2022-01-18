#include <sourcemod>
#include <sdktools>
#include <komadmin>

#pragma semicolon 1
#pragma newdecls required

int r1 = 255, g1 = 0, b1 = 0, g_Beam = -1, g_Halo = -1, KomAdmin = -1;

public Plugin myinfo = 
{
	name = "[KomAdmin] - Oyuncu Efektleri", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnMapStart()
{
	g_Beam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_Halo = PrecacheModel("materials/sprites/light_glow02.vmt");
}

public void OnPluginStart()
{
	CreateTimer(0.1, Timer_Aura, _, TIMER_REPEAT);
}

public void OnKomAdminCreated(int client)
{
	KomAdmin = client;
}

public void OnKomAdminRemoved(int client)
{
	if (IsPlayerAlive(client))
	{
		SetEntityRenderColor(client, 255, 255, 255);
		KomAdmin = -1;
	}
}

public void OnGameFrame()
{
	if (KomAdmin != -1 && IsPlayerAlive(KomAdmin))
	{
		if (r1 > 0 && b1 == 0)
		{
			r1--;
			g1++;
		}
		if (g1 > 0 && r1 == 0)
		{
			g1--;
			b1++;
		}
		if (b1 > 0 && g1 == 0)
		{
			b1--;
			r1++;
		}
		SetEntityRenderColor(KomAdmin, r1, g1, b1, 150);
	}
}

public Action Timer_Aura(Handle timer, any data)
{
	if (KomAdmin != -1 && IsPlayerAlive(KomAdmin))
	{
		float loc[3];
		loc[2] += 8.0;
		int Color[4];
		Color[0] = r1;
		Color[1] = g1;
		Color[2] = b1;
		Color[3] = 255;
		GetClientAbsOrigin(KomAdmin, loc);
		TE_SetupBeamRingPoint(loc, 59.0, 69.0, g_Beam, g_Halo, 0, 10, 0.1, 3.0, 0.0, Color, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(loc, 49.0, 59.0, g_Beam, g_Halo, 0, 10, 0.1, 3.0, 0.0, Color, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(loc, 39.0, 49.0, g_Beam, g_Halo, 0, 10, 0.1, 3.0, 0.0, Color, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(loc, 29.0, 39.0, g_Beam, g_Halo, 0, 10, 0.1, 3.0, 0.0, Color, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(loc, 19.0, 29.0, g_Beam, g_Halo, 0, 10, 0.1, 3.0, 0.0, Color, 0, 0);
		TE_SendToAll();
	}
} 