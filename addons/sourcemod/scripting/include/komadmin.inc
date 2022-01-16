#if defined _komadmin_included
#endinput
#endif
#define _komadmin_included

public SharedPlugin __pl_komadmin = 
{
	name = "komadmin", 
	file = "komadmin.smx", 
	
	#if defined REQUIRE_PLUGIN
	required = 1, 
	#else
	required = 0, 
	#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_komadmin_SetNTVOptional()
{
	MarkNativeAsOptional("IsKaExist");
	MarkNativeAsOptional("IsClientKa");
	MarkNativeAsOptional("SetClientKa");
	MarkNativeAsOptional("RemoveClientKa");
	MarkNativeAsOptional("RemoveKa");
}
#endif

/*********************************************************
 * Komutçu admini kovulursa çağrılır.
 *
 *
 * @param client		Eski Komutçu Admini
 *********************************************************/
forward void OnKomAdminRemoved(int client); 

/*********************************************************
 * Yeni komutçu admini gelince çağrılır.
 *
 *
 * @param client		Yeni Komutçu Admini
 *********************************************************/
forward void OnKomAdminCreated(int client); 

/*********************************************************
 * Komutçu admini var mı diye kontrol eder.
 *
 *
 * @Return				True = Evet | False = Hayır
 *********************************************************/
native bool IsKaExist();

/*********************************************************
 * Oyuncu Komutçu admini mi diye kontrol eder.
 *
 * @param client 			Kontrol EdilecekOyuncu
 * @Return				True = Evet | False = Hayır
 *********************************************************/
native bool IsClientKa(int client);

/*********************************************************
 * Oyuncuyu Komutçu admini seçer.
 *
 * @param client 			Seçilecek Oyuncu
 * @NoReturn				Oyuncu valid değilse veya Komutçu Admini varsa çalışmaz.
 *********************************************************/
native void SetClientKa(int client);

/*********************************************************
 * Oyuncu Komutçu admini ise kovar.
 *
 * @param client 			Kovulacak Oyuncu
 * @NoReturn				Oyuncu valid değilse veya Komutçu Admini değilse çalışmaz.			
 *********************************************************/
native void RemoveClientKa(int client);

/*********************************************************
 * Komutçu adminini direk kovar.
 *
 *
 * @NoReturn				Komutçu admini yoksa çalışmaz.
 *********************************************************/
native void RemoveKa();