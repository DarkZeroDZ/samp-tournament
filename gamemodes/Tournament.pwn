#include <a_samp>
#undef MAX_PLAYERS
#define MAX_PLAYERS 200

#include <zcmd>
#include <dini>
#include <sscanf2>
#include <foreach>
//#include <sort>
#include <sampcac>
#include <a_mysql>

#pragma unused ret_memcpy
#pragma unused CAC_INCLUDE_MAJOR
#pragma unused CAC_INCLUDE_MINOR
#pragma unused CAC_INCLUDE_PATCH

// MAX_... MIN_...
#define MAX_PING 				200
#define MIN_FPS 				30

// Sprachen
#define LANG_DE 				0
#define LANG_EN 				1


// SQL Server //
#define MYSQL_HOST        		"localhost"
#define MYSQL_USER        		"allvsall"//"root"
#define MYSQL_PASS        		"3oYe1EnIK46O"//""
#define MYSQL_DATABASE    		"allvsall"

// Farben
#define COLOR_PURPLE            0xC34AFFFF
#define COLOR_RED               0xE00000FF
#define COLOR_ADMIN             0xE9ED00FF // Gold/Gelb
#define COLOR_PARTICIPANT       0xD6D592FF
#define COLOR_BLUE              0x008CDBFF
#define COLOR_USL               0x8c0000FF // Dunkelrot
#define COLOR_AMB			   	0x7b00c2FF // Dunkellila
#define COLOR_GREEN             0x00FF00FF 
#define COLOR_LIGHTBLUE			0x00ADFFFF
#define COLOR_FIGHTZONE         0x224730AA

// Free Cam
#define ACCEL_RATE              0.03

#define CAMERA_MODE_NONE    	0
#define CAMERA_MODE_FLY     	1

#define MOVE_FORWARD    		1
#define MOVE_BACK       		2
#define MOVE_LEFT       		3
#define MOVE_RIGHT      		4
#define MOVE_FORWARD_LEFT       5
#define MOVE_FORWARD_RIGHT      6
#define MOVE_BACK_LEFT          7
#define MOVE_BACK_RIGHT         8

// Dialoge
#define DIALOG_LANGUAGE         0
#define DIALOG_LANGUAGE2        1
#define DIALOG_NOPARTICIPANT    2
#define DIALOG_REGISTER         3
#define DIALOG_LOGIN            4
#define DIALOG_NETSTATS         5
#define DIALOG_PLAYERNETSTATS   6
#define DIALOG_CONTROLPANEL     7
#define DIALOG_TOTALMINUTES     8
#define DIALOG_BREAKSTART       9
#define DIALOG_BREAKDURATION    10
#define DIALOG_WHITELIST        11

// Temporäre Player Variablen
new PlayerLanguage[MAX_PLAYERS] = LANG_DE;
new DrunkLevel[MAX_PLAYERS];
new CurrentFrames[MAX_PLAYERS];
new IsMuted[MAX_PLAYERS];
new MuteTimer[MAX_PLAYERS];
new MuteMinutes[MAX_PLAYERS];
new MuteSeconds[MAX_PLAYERS];
new SpamCounter[MAX_PLAYERS];
new BanTimer[MAX_PLAYERS];
new KickTimer[MAX_PLAYERS];
new LastHitValue[6][MAX_PLAYERS];
new TakeDmgCD[6][MAX_PLAYERS];
new Float:DamageDone[6][MAX_PLAYERS];
new IsSpectating[MAX_PLAYERS];
new BeingSpectated[MAX_PLAYERS];
new SpectatingID[MAX_PLAYERS];
new IsUsingFreeCam[MAX_PLAYERS];
new Camera[MAX_PLAYERS];
new KillingSpree[MAX_PLAYERS];
new Hitsound[MAX_PLAYERS];
new MoveSpeed[MAX_PLAYERS] = 100;
new Sync[MAX_PLAYERS];
new IsSynced[MAX_PLAYERS];
new Float:SyncCoords[MAX_PLAYERS][3];
new bool:PlayerPaused[MAX_PLAYERS] = false;
new InactiveTime[MAX_PLAYERS];

// SQL Stuff
new MySQL: Database, Corrupt_Check[MAX_PLAYERS];
    
enum SpielerDaten
{
    ID,
    Name[25],
    Passwort[65],
    Salt[11],
    PasswordFails,
	Points,
	KILLS,
	DEATHS,
	Float:DMGTAKEN,
	Float:DMGGIVEN,
	PMODE,
	Position,
 	Cache: Player_Cache,
    bool:LoggedIn
}

new pInfo[MAX_PLAYERS][SpielerDaten];

// Textdraws
new PlayerText:FPS;
new PlayerText:DoingDamage[3]; 
new PlayerText:GettingDamaged[3];
new PlayerText:TopBar;
new PlayerText:BottomBar;
new PlayerText:CountDown;
new PlayerText:Statistics;
new PlayerText:EventInfo;
new PlayerText:Map;
new PlayerText:MapBox;
new PlayerText:Map2;
new PlayerText:Map2Box;

new Text:URL[2];
new Text:TopList;
new Text:Clock;

// Globale Variablen
new Float:RandomSpawns[][] =
{
    {2020.3278,908.8595,10.3312,301.0226},
    {2020.7681,985.8326,10.8127,275.4339},
    {2011.1787,1166.5992,10.8203,270.4211},
    {1990.4406,1243.9412,10.8203,304.5753},
    {1995.9961,1329.0027,10.0156,269.4814},
    {1998.9894,1357.6315,10.0156,269.6904},
    {2003.4679,1441.2410,10.8130,270.3169},
    {2023.5908,1562.2047,10.8203,257.8883},
    {2021.1442,1721.0852,10.8203,268.5418},
    {2137.1572,1743.9656,10.8125,115.8428},
    {2131.6602,1639.1499,11.0469,102.7743},
    {2114.9275,1545.7178,10.8203,90.3454},
    {2103.5664,1450.3885,10.8203,94.5469},
    {2124.9631,1344.4160,10.8203,88.6972},
    {2115.6917,1294.0441,9.5143,89.7417},
    {2121.5544,1217.8531,10.8203,92.3521},
    {2113.4165,1152.0835,13.5318,67.2857},
    {2114.6277,1070.8141,10.7948,102.5874},
    {2108.4854,1003.0605,11.0783,89.6351},
    {2059.5776,1898.5189,11.9888,19.3858},
    {2163.8574,1850.0341,10.8203,61.0076},
    {2112.8635,1976.2983,10.8222,243.9559},
    {2178.0569,1989.9366,10.8203,76.0403},
    {2100.8137,2041.0458,10.8203,254.0119},
    {2158.6526,2085.5181,10.8233,119.2980},
    {2164.8618,2159.6892,10.8203,92.0398},
    {2110.6702,2213.4636,10.8203,311.0409},
    {2222.5640,2138.1033,10.6719,159.7323}
};

new Float:RandomSpawnsSmall[][] =
{ 
    {2020.3278,908.8595,10.3312,301.0226},
    {2020.7681,985.8326,10.8127,275.4339},
    {2011.1787,1166.5992,10.8203,270.4211},
    {1990.4406,1243.9412,10.8203,304.5753},
    {1995.9961,1329.0027,10.0156,269.4814},
    {1998.9894,1357.6315,10.0156,269.6904},
    {2003.4679,1441.2410,10.8130,270.3169},
    {2023.5908,1562.2047,10.8203,257.8883},
    {2021.1442,1721.0852,10.8203,268.5418},
    {2137.1572,1743.9656,10.8125,115.8428},
    {2131.6602,1639.1499,11.0469,102.7743},
    {2114.9275,1545.7178,10.8203,90.3454},
    {2103.5664,1450.3885,10.8203,94.5469},
    {2124.9631,1344.4160,10.8203,88.6972},
    {2115.6917,1294.0441,9.5143,89.7417},
    {2121.5544,1217.8531,10.8203,92.3521},
    {2113.4165,1152.0835,13.5318,67.2857},
    {2114.6277,1070.8141,10.7948,102.5874},
    {2108.4854,1003.0605,11.0783,89.6351}
};

new WeaponNames[55][] =
{
        {"Punch"},{"Brass Knuckles"},{"Golf Club"},{"Nite Stick"},{"Knife"},{"Baseball Bat"},{"Shovel"},{"Pool Cue"},{"Katana"},{"Chainsaw"},{"Purple Dildo"},
        {"Smal White Vibrator"},{"Large White Vibrator"},{"Silver Vibrator"},{"Flowers"},{"Cane"},{"Grenade"},{"Tear Gas"},{"Molotov Cocktail"},
        {""},{""},{""},
        {"9mm"},{"Silenced 9mm"},{"Deagle"},{"Shotgun"},{"Sawn-off"},{"Combat"},{"Micro SMG"},{"MP5"},{"AK-47"},{"M4"},{"Tec9"},
        {"Rifle"},{"Sniper"},{"Rocket"},{"HS Rocket"},{"Flamethrower"},{"Minigun"},{"Satchel Charge"},{"Detonator"},
        {"Spraycan"},{"Fire Extinguisher"},{"Camera"},{"Nightvision Goggles"},{"Thermal Goggles"},{"Parachute"}, {"Fake Pistol"},{""}, {"Vehicle"}, {"Vehicle"},
		{"Explosion"}, {""}, {"Suicide"}, {"Collision"}
};

new IsStarted = false;
new IsStarting = false;
new IsPaused = false;
new CountDownCounter;
new GlobalTimer;
new EventInfoTextDE[128] = "~w~Das Event wurde noch ~r~nicht ~w~gestartet!";
new EventInfoTextEN[128] = "~w~The event has ~r~not ~w~been started yet!";
new TotalKills;
new TotalMinutes = 59;
new Minutes;
new Seconds;
new Pause = 30;
new PauseDuration = 0;
new UseSmallField = false;
new IsChatLocked;
new FightZone;
new SmallFightZone;
new ParticipantsCounter = 0;
new ContinueCountDown = 3;
new Continue;
new CurrentLeader;

// Cam
enum FreeCamInfo
{
	cameramode,
	flyobject,
	mode,
	lrold,
	udold,
	lastmove,
	Float:accelmul
}
new FreeCam[MAX_PLAYERS][FreeCamInfo];

main(){}
public OnGameModeInit()
{
    new MySQLOpt: option_id = mysql_init_options();
	mysql_set_option(option_id, AUTO_RECONNECT, true); 

	Database = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE, option_id);

	if(Database == MYSQL_INVALID_HANDLE || mysql_errno(Database) != 0)
	{
	    new String[128];
	    format(String, sizeof(String), "Host: %s | User: %s | Passwort: %s | DB: %s",MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DATABASE);
	    print(String);
		print("I couldn't connect to the MySQL server, closing.");

		SendRconCommand("exit");
		return 1;
	}

	print("I have connected to the MySQL server.");
 //mysql_tquery(Database, "CREATE TABLE IF NOT EXISTS `SPIELERDATEN` (`ID` int(11) NOT NULL AUTO_INCREMENT,`Name` varchar(24) NOT NULL,`Passwort` char(65) NOT NULL,`SALT` char(11) NOT NULL,`POINTS` mediumint(7)
 //NOT NULL DEFAULT '0', `KILLS` mediumint(7) NOT NULL DEFAULT '0', `DEATHS` mediumint(7) NOT NULL DEFAULT '0', `DMGTAKEN` float NOT NULL DEFAULT '0', `DMGGIVEN` float NOT NULL DEFAULT '0', `PMODE` mediumint(7)
 //NOT NULL DEFAULT '0', `Position` mediumint(5) NOT NULL DEFAULT '0',PRIMARY KEY (`ID`), UNIQUE KEY `Name` (`Name`))");

	SetGameModeText("All vs All tournament");
	SendRconCommand("hostname All vs All Tournament by [USL] and [AMB]");
	SendRconCommand("mapname Las Venturas Strip");
	SendRconCommand("language German/English");
	
	EnableStuntBonusForAll(false);
	SetWorldTime(23);
	SetWeather(11);
	
	ShowPlayerMarkers(1);
	UsePlayerPedAnims();
	DisableInteriorEnterExits();
		
    GlobalTimer = SetTimer("OnGlobalTimer", 1000, 1);
		
	FightZone = GangZoneCreate(1885.6469, 821.4630, 2369.4424, 2347.437);
	SmallFightZone = GangZoneCreate(1885.6469, 821.4630, 2369.4424, 1784.7277);

	AddPlayerClass(102,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(103,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(104,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(105,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(106,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(107,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(108,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(109,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(110,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(114,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(115,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(116,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(156,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(170,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(137,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(230,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	AddPlayerClass(251,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	
	for(new i = 0; i < 311; i++)
	{
	    if((i >= 102 && i <= 110) || i == 114 || i == 115 || i == 116 || i == 156 || i == 170 || i == 137 || i == 74 || i == 230 || i == 251)
	        continue;
	        
		AddPlayerClass(i,2095.9946,1285.6730,10.8203,193.9228,0,0,0,0,0,0);
	}
	
	AddStaticVehicle(559,2037.4188,1422.6571,10.3979,179.9101,60,1); //
	AddStaticVehicle(559,2037.5001,1225.5924,10.4000,179.4433,60,1); //
	AddStaticVehicle(559,2103.8193,1397.7385,10.4766,359.8558,60,1); //
	AddStaticVehicle(559,2164.6470,1676.4146,10.4747,355.6561,60,1); //
	AddStaticVehicle(559,2185.8298,1991.7235,10.4766,270.5471,60,1); //
	AddStaticVehicle(559,2156.4084,2113.1060,10.3261,1.2193,60,1); //
	AddStaticVehicle(492,2038.9539,1547.0022,10.4537,0.7939,16,16); //
	AddStaticVehicle(492,2143.6323,1652.9706,10.5309,298.7878,16,16); //
	AddStaticVehicle(492,2094.5552,1814.8068,10.4537,333.6103,16,16); //
	AddStaticVehicle(492,2119.0383,2197.6370,10.4537,0.0750,16,16); //
	AddStaticVehicle(492,2128.1914,2357.9341,10.5249,89.9558,16,16); //
	AddStaticVehicle(535,2077.5732,1067.6465,10.5067,181.0473,123,1); //
	AddStaticVehicle(535,2077.9192,1495.6721,10.5069,357.7441,123,1); //
	AddStaticVehicle(535,2196.3000,1821.3972,10.5846,2.1574,123,1); //
	AddStaticVehicle(467,2054.9841,1738.7600,10.4822,152.8828,22,1); //
	AddStaticVehicle(467,2037.3888,1325.5059,10.4830,182.2655,22,1); //
	AddStaticVehicle(467,2110.2495,1408.8031,10.6320,355.7268,22,1); //
	AddStaticVehicle(536,2037.1110,1034.8267,10.4807,179.7262,37,1); //
	AddStaticVehicle(536,2077.4153,1084.6573,10.4809,357.1168,37,1); //
	AddStaticVehicle(536,2153.1304,1701.7408,10.4883,38.6228,37,1); //
	AddStaticVehicle(536,2117.7444,1889.1995,10.4810,359.5236,37,1); //
	AddStaticVehicle(536,2155.7356,2199.6995,10.4095,0.0545,37,1); //
	AddStaticVehicle(576,2103.6448,2052.7275,10.4317,89.9759,75,96); //
	AddStaticVehicle(576,2037.7322,1613.1396,10.3532,179.8768,75,96); //
	AddStaticVehicle(576,2077.6646,1211.9321,10.3526,183.3239,75,96); //
	AddStaticVehicle(401,2007.4036,1458.8052,10.5233,88.8590,113,113); //
	AddStaticVehicle(401,2110.6633,1538.3785,10.5219,269.7667,113,113); //
	AddStaticVehicle(401,2182.8984,1898.4226,10.5228,270.4358,113,113); //
	AddStaticVehicle(401,2181.2615,2028.2377,10.6250,91.0478,113,113); //
	AddStaticVehicle(401,2096.7317,2027.3126,10.5235,89.0696,113,113); //
	AddStaticVehicle(401,2184.3008,2155.2966,10.5236,89.9563,113,113); //

	URL[0] = TextDrawCreate(87.000000,321.000000,"USLClan.de");
	TextDrawAlignment(URL[0],2);
	TextDrawBackgroundColor(URL[0],0x000000ff);
	TextDrawFont(URL[0],2);
	TextDrawLetterSize(URL[0],0.299999,1.299999);
	TextDrawColor(URL[0],COLOR_USL);
	TextDrawSetOutline(URL[0],1);
	TextDrawSetProportional(URL[0],1);
	TextDrawSetShadow(URL[0],1);

	URL[1] = TextDrawCreate(87.000000,311.000000,"AMBizz.de");
	TextDrawAlignment(URL[1],2);
	TextDrawBackgroundColor(URL[1],0x000000ff);
	TextDrawFont(URL[1],2);
	TextDrawLetterSize(URL[1],0.299999,1.299999);
	TextDrawColor(URL[1],COLOR_AMB);
	TextDrawSetOutline(URL[1],1);
	TextDrawSetProportional(URL[1],1);
	TextDrawSetShadow(URL[1],1);

	Clock = TextDrawCreate(547.000000, 23.000000, "_");
	TextDrawBackgroundColor(Clock, 255);
	TextDrawFont(Clock, 3);
	TextDrawLetterSize(Clock, 0.55, 2.15);
	TextDrawColor(Clock, -1);
	TextDrawSetOutline(Clock, 2);
	TextDrawSetProportional(Clock, 0);
	TextDrawSetShadow(Clock, 0);

	TopList = TextDrawCreate(527.000000, 200.000000, "_");
	TextDrawAlignment(TopList,0);
	TextDrawBackgroundColor(TopList,0x000000ff);
	TextDrawFont(TopList,1);
	TextDrawLetterSize(TopList,0.179999,0.849999);
	TextDrawColor(TopList,0xffffffff);
	TextDrawSetOutline(TopList,1);
	TextDrawSetProportional(TopList,1);
	TextDrawSetShadow(TopList,1);

	UpdateTopList();
	return 1;
}

public OnGameModeExit()
{
	mysql_close(Database); // Closing the database.
	KillTimer(GlobalTimer);
	TextDrawDestroy(URL[0]);
	TextDrawDestroy(URL[1]);
	TextDrawDestroy(Clock);
	TextDrawDestroy(TopList);
	return 1;
}

forward UpdateTopList();
public UpdateTopList()
{
	SetTimer("OnUpdateTopList", 1000, 0);
	return 1;
}

forward OnUpdateTopList();
public OnUpdateTopList()
{
	new MySQLQuery[128], TString[800];
 	mysql_format(Database, MySQLQuery, sizeof(MySQLQuery), "SELECT * FROM `SPIELERDATEN` where `PMODE` = 1 order by POINTS desc");
	new Cache:result = mysql_query(Database, MySQLQuery);
 	cache_get_row_count(ParticipantsCounter);
	new leader = CurrentLeader;
    new string[128], string_en[128];

	for (new j = 0; j < ParticipantsCounter; j++)
    {
        new points;
        new name[24];
        
		cache_get_value_int(j, "POINTS", points);
		cache_get_value_name(j, "Name", name, 24);

		if(j == 0)
		{
		    SetPlayerColor(ReturnUser(name), COLOR_GREEN);
		    leader = ReturnUser(name);
		}
		else
		    SetPlayerColor(ReturnUser(name), COLOR_PARTICIPANT);
		    
		if(IsPlayerConnected(ReturnUser(name)) && pInfo[ReturnUser(name)][PMODE] == 1)
		{
			pInfo[ReturnUser(name)][Position] = j + 1;

			new tdstring[200];
			if(PlayerLanguage[ReturnUser(name)] == LANG_DE)
			    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[ReturnUser(name)][KILLS], pInfo[ReturnUser(name)][DEATHS], pInfo[ReturnUser(name)][Points], pInfo[ReturnUser(name)][DMGGIVEN], pInfo[ReturnUser(name)][DMGTAKEN], pInfo[ReturnUser(name)][Position], ParticipantsCounter);
			else
			    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[ReturnUser(name)][KILLS], pInfo[ReturnUser(name)][DEATHS], pInfo[ReturnUser(name)][Points], pInfo[ReturnUser(name)][DMGGIVEN], pInfo[ReturnUser(name)][DMGTAKEN], pInfo[ReturnUser(name)][Position], ParticipantsCounter);

			PlayerTextDrawSetString(ReturnUser(name), Statistics, tdstring);
		}

		if(j < 20)
			format(TString, sizeof(TString), "%s~n~~r~%d. ~w~%s ~p~(%d)", TString, j + 1, name, points);
 	}
 	
 	printf("Spieler %s hat den PMODE %d", GetName(leader),pInfo[leader][PMODE]);

	if(leader != CurrentLeader && IsStarted && pInfo[leader][PMODE] == 1)
	{
	    CurrentLeader = leader;
	    format(string, sizeof(string), ">> Neuer führender Spieler ist %s!", GetName(leader));
	    format(string_en, sizeof(string_en), ">> The new leading player is %s!", GetName(leader));
	    SendLanguageMessageToAll(COLOR_BLUE, string, string_en);
	}

	TextDrawSetString(TopList, TString);
 	cache_delete(result);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if(!CAC_GetStatus(playerid))
	{
  		SendLanguageMessage(playerid, COLOR_RED, "Du brauchst SAMPCAC Anticheat um am Event teilnehmen zu können!","You need to install SAMPCAC anticheat to participate to the event!");
    	SendLanguageMessage(playerid, COLOR_RED, "Du kannst SAMPCAC hier herunterladen: {FFFFFF}www.USLClan.de/ac","Download it from: {FFFFFF}www.USLClan.de/ac");
		KickPlayerEx(-1, playerid, "SAMPCAC is missing");
		return 0;
	}

	SetPlayerPos(playerid,2175.8215,1285.7275,42.2241);
	SetPlayerFacingAngle(playerid,88.6337);
	SetPlayerCameraPos(playerid,2167.547607, 1285.904418, 42.388217);
	SetPlayerCameraLookAt(playerid,2175.8215,1285.7275,42.2241);
	ApplyAnimation(playerid, "PAULNMAC", "wank_loop", 3.0, 1, 0, 0, 0, -1);
	return 1;
}

public OnPlayerConnect(playerid)
{
	IsMuted[playerid] = 0;
	MuteMinutes[playerid] = 0;
	MuteSeconds[playerid] = 0;
	SpamCounter[playerid] = 0;
	IsSpectating[playerid] = 0;
	IsSynced[playerid] = 0;
	BeingSpectated[playerid] = 0;
	SpectatingID[playerid] = 65535;
	IsUsingFreeCam[playerid] = 0;
	Camera[playerid] = 0;
	Sync[playerid] = 0;
	KillingSpree[playerid] = 0;
	
	new string[128], string_en[128];

	new IP[16];
	GetPlayerIp(playerid, IP, sizeof(IP));
		
	new IpCounter = GetNumberOfPlayersOnThisIP(IP);
	if(IpCounter > 4)
	     return BanPlayerEx(-1, playerid, "Bot flood");
	
    format(string, sizeof(string), "{008CDB}<{00FF00}+{008CDB}> {FFFFFF}%s hat den {00FF00}Server {FFFFFF}betreten.", GetName(playerid));
    format(string_en, sizeof(string_en), "{008CDB}<{00FF00}+{008CDB}> {FFFFFF}%s has {00FF00}joined {FFFFFF}the server.", GetName(playerid));
	SendLanguageMessageToAll(-1, string, string_en);

	format(string, sizeof(string), "*** IP: %s", IP);
	SendClientMessageToAdmins(-1,string, string);
	
	SetPlayerColor(playerid, COLOR_PARTICIPANT);
	ShowPlayerDialog(playerid, DIALOG_LANGUAGE2, DIALOG_STYLE_MSGBOX,
		"{32a852}Sprache/Language",
		"{FFFFFF}Please select your {32a852}language{FFFFFF}.\nBitte waehle deine {32a852}Sprache {FFFFFF}aus.",
		"Deutsch","English");

    CreatePlayerTextDraws(playerid);
	
	CurrentFrames[playerid] = 101;
	pInfo[playerid][KILLS] = 0;
	pInfo[playerid][DEATHS] = 0;
	pInfo[playerid][Points] = 0;
	pInfo[playerid][DMGGIVEN] = 0.0;
	pInfo[playerid][DMGTAKEN] = 0.0;
	pInfo[playerid][PasswordFails] = 0;
	pInfo[playerid][PMODE] = 0;
	pInfo[playerid][Position] = 0;
	Corrupt_Check[playerid]++;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
 	new string[128], string_en[128];
    switch(reason)
    {
        case 0:
        {
             format(string, sizeof(string), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s hat den {FF0000}Server {FFFFFF}verlassen. (Timeout)", GetName(playerid));
             format(string_en, sizeof(string_en), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s has {FF0000}left {FFFFFF}the server. (Timeout)", GetName(playerid));
             SendLanguageMessageToAll(-1, string, string_en);
        }
        case 1:
        {
             format(string, sizeof(string), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s hat den {FF0000}Server {FFFFFF}verlassen.", GetName(playerid));
             format(string_en, sizeof(string_en), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s has {FF0000}left {FFFFFF}the server.", GetName(playerid));
             SendLanguageMessageToAll(-1, string, string_en);
        }
        case 2:
        {
             format(string, sizeof(string), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s hat den {FF0000}Server {FFFFFF}verlassen. (Kicked/Banned)", GetName(playerid));
             format(string_en, sizeof(string_en), "{008CDB}<{FF0000}-{008CDB}> {FFFFFF}%s has {FF0000}left {FFFFFF}the server. (Kicked/Banned)", GetName(playerid));
             SendLanguageMessageToAll(-1, string, string_en);
        }
    }
    
	KillTimer(MuteTimer[playerid]);

	PlayerTextDrawDestroy(playerid, FPS);
	PlayerTextDrawDestroy(playerid, Statistics);
	PlayerTextDrawDestroy(playerid, TopBar);
	PlayerTextDrawDestroy(playerid, BottomBar);
	PlayerTextDrawDestroy(playerid, CountDown);
	PlayerTextDrawDestroy(playerid, EventInfo);
	PlayerTextDrawDestroy(playerid, Map);
	PlayerTextDrawDestroy(playerid, MapBox);
	PlayerTextDrawDestroy(playerid, Map2);
	PlayerTextDrawDestroy(playerid, Map2Box);
	
	for(new i; i < 3; i++)
	{
		PlayerTextDrawDestroy(playerid, DoingDamage[i]);
		PlayerTextDrawDestroy(playerid, GettingDamaged[i]);
	}
	
	Corrupt_Check[playerid]++;
	SavePlayer(playerid);
	pInfo[playerid][LoggedIn] = false;
	return 1;
}

forward SavePlayer(playerid);
public SavePlayer(playerid)
{
	new DB_Query[256];
	mysql_format(Database, DB_Query, sizeof(DB_Query), "UPDATE `SPIELERDATEN` SET `POINTS` = %d, `KILLS` = %d, `DEATHS` = %d, `DMGTAKEN` = %.0f, `DMGGIVEN` = %.0f, `PMODE` = %d, `Position` = %d WHERE `ID` = %d LIMIT 1",
	pInfo[playerid][Points], pInfo[playerid][KILLS], pInfo[playerid][DEATHS],pInfo[playerid][DMGTAKEN],pInfo[playerid][DMGGIVEN],pInfo[playerid][PMODE], pInfo[playerid][Position], pInfo[playerid][ID]);
	mysql_tquery(Database, DB_Query);
	print(DB_Query);
	if(cache_is_valid(pInfo[playerid][Player_Cache]))
	{
		cache_delete(pInfo[playerid][Player_Cache]);
		pInfo[playerid][Player_Cache] = MYSQL_INVALID_CACHE;
	}
	return 1;
}

forward ResetAllPlayers();
public ResetAllPlayers()
{
	new DB_Query[256];
	mysql_format(Database, DB_Query, sizeof(DB_Query), "UPDATE `SPIELERDATEN` SET `POINTS` = 0, `KILLS` = 0, `DEATHS` = 0, `DMGTAKEN` = 0.0, `DMGGIVEN` = 0.0, `Position` = 0");
	mysql_tquery(Database, DB_Query);
	print(DB_Query);
	
	foreach(new playerid : Player)
	{
		pInfo[playerid][KILLS] = 0;
		pInfo[playerid][DEATHS] = 0;
		pInfo[playerid][Points] = 0;
		pInfo[playerid][DMGGIVEN] = 0.0;
		pInfo[playerid][DMGTAKEN] = 0.0;
		pInfo[playerid][PasswordFails] = 0;
		pInfo[playerid][Position] = 0;
		
		SetPlayerScore(playerid, 0);

		if(IsPlayerConnected(playerid) && pInfo[playerid][PMODE] == 1)
		{
			new tdstring[200];
			if(PlayerLanguage[playerid] == LANG_DE)
			    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);
			else
			    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);

			PlayerTextDrawSetString(playerid, Statistics, tdstring);
		}
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetCameraBehindPlayer(playerid);

	SetPlayerColor(playerid, COLOR_PARTICIPANT);
	
	PlayerTextDrawHide(playerid, TopBar);
	PlayerTextDrawHide(playerid, BottomBar);
	PlayerTextDrawHide(playerid, CountDown);
	PlayerTextDrawShow(playerid, FPS);
	TextDrawShowForPlayer(playerid, Clock);
	PlayerTextDrawShow(playerid, EventInfo);
	TextDrawShowForPlayer(playerid, URL[0]);
	TextDrawShowForPlayer(playerid, URL[1]);

	if(PlayerLanguage[playerid] == LANG_DE)
	    PlayerTextDrawSetString(playerid, EventInfo, EventInfoTextDE);
	else
	    PlayerTextDrawSetString(playerid, EventInfo, EventInfoTextEN);

	for(new i = 0; i < 3; i++)
	{
		PlayerTextDrawShow(playerid, DoingDamage[i]);
		PlayerTextDrawShow(playerid, GettingDamaged[i]);
	}

	if(IsStarted)
		TextDrawShowForPlayer(playerid, TopList);
		
	foreach(new i : Player)
	    if(GetPlayerState(i) == PLAYER_STATE_SPECTATING && SpectatingID[i] == playerid)
	        TogglePlayerSpectating(i, 1);

	if(pInfo[playerid][PMODE] == 1)
	{
		PlayerTextDrawShow(playerid, Statistics);

		new tdstring[200];
		if(PlayerLanguage[playerid] == LANG_DE)
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);
		else
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);

		PlayerTextDrawSetString(playerid, Statistics, tdstring);

		if(IsPaused && pInfo[playerid][PMODE] == 1 && !IsUsingFreeCam[playerid] && !IsSpectating[playerid])
		    TogglePlayerControllable(playerid, 0);

		GivePlayerWeapon(playerid, WEAPON_DILDO, 9999);
		GivePlayerWeapon(playerid, WEAPON_SAWEDOFF, 9999);
		GivePlayerWeapon(playerid, WEAPON_UZI, 9999);
		GivePlayerWeapon(playerid, WEAPON_DEAGLE, 9999);
		GivePlayerWeapon(playerid, WEAPON_SNIPER, 9999);
		GivePlayerWeapon(playerid, WEAPON_M4, 9999);

		if(UseSmallField)
		{
			SetPlayerWorldBounds(playerid, 2380.437, 1885.6469, 1784.7277, 821.4630);
			GangZoneShowForPlayer(playerid, SmallFightZone, COLOR_FIGHTZONE);
			GangZoneHideForPlayer(playerid, FightZone);
		}
		else
		{
			SetPlayerWorldBounds(playerid, 2380.437, 1885.6469, 2370.4424, 821.4630);
			GangZoneShowForPlayer(playerid, FightZone, COLOR_FIGHTZONE);
			GangZoneHideForPlayer(playerid, SmallFightZone);
		}

        if(Sync[playerid])
		{
			Sync[playerid] = 0;
			SetPlayerPos(playerid, SyncCoords[playerid][0], SyncCoords[playerid][1], SyncCoords[playerid][2]);
		}
		else
		{
		    if(UseSmallField)
		    {
				new Random = random(sizeof(RandomSpawnsSmall));
			    SetPlayerPos(playerid, RandomSpawnsSmall[Random][0], RandomSpawnsSmall[Random][1], RandomSpawnsSmall[Random][2]);
			    SetPlayerFacingAngle(playerid, RandomSpawnsSmall[Random][3]);
			}
			else
			{
				new Random = random(sizeof(RandomSpawns));
			    SetPlayerPos(playerid, RandomSpawns[Random][0], RandomSpawns[Random][1], RandomSpawns[Random][2]);
			    SetPlayerFacingAngle(playerid, RandomSpawns[Random][3]);
			}

			SetPlayerInterior(playerid, 0);
		    SetPlayerHealth(playerid, 10000.0);
		    SendLanguageMessage(playerid, COLOR_RED, "Du bist für 5 Sekunden vor Spawnkill geschützt.","You have 5 seconds of Anti-Spawnkill protection");
		    SetPlayerChatBubble(playerid, "Anti-Spawnkill protected player", COLOR_RED, 100.0, 5000);
		    SetTimerEx("AntiSpawnkill",5000,0,"i",playerid);
		}
	}
	else
	{
	    if(PlayerLanguage[playerid] == LANG_DE)
			ShowPlayerDialog(playerid, DIALOG_NOPARTICIPANT, DIALOG_STYLE_MSGBOX,
				"{32a852}Willkommen",
				"{FFFFFF}Du bist nicht als Teilnehmer bei diesem Event angemeldet.\nDaher wurdest du in der Lobby gespawnt.\n\nDu kannst mit /Spec und /Freecam die Teilnehmer beobachten. Viel Spaß!",
				"Ok","");
	    else
			ShowPlayerDialog(playerid, DIALOG_NOPARTICIPANT, DIALOG_STYLE_MSGBOX,
				"{32a852}Welcome",
				"{FFFFFF}You are not registered as a participant for this tournament.\nYou have been spawned in the lobby.\n\nYou can watch the participants by using /Spec or /Freecam. Have fun!",
				"Ok","");

		SetPlayerWorldBounds(playerid, 20000.0000, -20000.0000, 20000.0000, -20000.0000);
		SetPlayerInterior(playerid, 1);
		SetPlayerPos(playerid,-794.806396,497.738037,1376.195312);
	}
	return 1;
}

public OnPlayerGiveDamage(playerid, damagedid, Float: amount, weaponid)
{
	if(Hitsound[playerid])
    	PlayerPlaySound(playerid,17802,0.0,0.0,0.0);
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float: amount, weaponid)
{
	new string[100];
	new Float:Health[3];
	
	if(issuerid != INVALID_PLAYER_ID && IsStarted)
 	{
 	    new tdstring[200];
		pInfo[playerid][DMGTAKEN] += amount;
		pInfo[issuerid][DMGGIVEN] += amount;

		if(PlayerLanguage[playerid] == LANG_DE)
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);
		else
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);

		PlayerTextDrawSetString(playerid, Statistics, tdstring);

		if(PlayerLanguage[issuerid] == LANG_DE)
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[issuerid][KILLS], pInfo[issuerid][DEATHS], pInfo[issuerid][Points], pInfo[issuerid][DMGGIVEN], pInfo[issuerid][DMGTAKEN], pInfo[issuerid][Position], ParticipantsCounter);
		else
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[issuerid][KILLS], pInfo[issuerid][DEATHS], pInfo[issuerid][Points], pInfo[issuerid][DMGGIVEN], pInfo[issuerid][DMGTAKEN], pInfo[issuerid][Position], ParticipantsCounter);

		PlayerTextDrawSetString(issuerid, Statistics, tdstring);
	}
	
	GetPlayerHealth(playerid, Health[0]);
	GetPlayerArmour(playerid, Health[1]);

	Health[2] = (Health[0] + Health[1]) - amount;
	if(Health[2] < 0)
		Health[2] = 0;
	
	if(LastHitValue[0][issuerid] == -1 && LastHitValue[1][issuerid] != playerid && LastHitValue[2][issuerid] != playerid)
		LastHitValue[0][issuerid] = playerid;
		
	if(LastHitValue[0][issuerid] == playerid)
	{
	    DamageDone[0][issuerid] += amount;
	    
  		format(string, sizeof(string), "~g~	%s~l~ / ~g~-%.0f ~g~%s", GetName(playerid), DamageDone[0][issuerid], WeaponNames[weaponid]);
        PlayerTextDrawSetString(issuerid, DoingDamage[0], string);
        
		TakeDmgCD[0][issuerid] = 1;

		if(BeingSpectated[issuerid])
		{
			foreach(new i : Player)
			{
		        if(IsSpectating[i] && SpectatingID[i] == issuerid)
				{
			        PlayerTextDrawSetString(i, DoingDamage[0], string);
					TakeDmgCD[0][i] = 1;
					LastHitValue[0][i] = i;
				}
			}
		}
	}
	else
	{
		if(LastHitValue[1][issuerid] == -1 && LastHitValue[2][issuerid] != playerid)
			LastHitValue[1][issuerid] = playerid;
			
		if(LastHitValue[1][issuerid] == playerid )
		{
		    DamageDone[1][issuerid] += amount;
			format(string, sizeof(string), "~g~	%s~l~ / ~g~-%.0f ~g~%s", GetName(playerid), DamageDone[1][issuerid], WeaponNames[weaponid]);
			PlayerTextDrawSetString(issuerid, DoingDamage[1], string);
			TakeDmgCD[1][issuerid] = 1;

			if(BeingSpectated[issuerid])
			{
			    foreach(new i : Player)
				{
			        if(IsSpectating[playerid] && SpectatingID[i] == issuerid)
					{
						PlayerTextDrawSetString(i, DoingDamage[1], string);
						TakeDmgCD[1][i] = 1;
						LastHitValue[1][i] = i;
					}
				}
			}
		}
		else
		{
			DamageDone[2][issuerid] += amount;
		   	LastHitValue[2][issuerid] = playerid;

			format(string, sizeof(string), "~g~	%s~l~ / ~g~-%.0f ~g~%s", GetName(playerid), DamageDone[2][issuerid], WeaponNames[weaponid]);
			PlayerTextDrawSetString(issuerid, DoingDamage[2], string);
			TakeDmgCD[2][issuerid] = 1;

			if(BeingSpectated[issuerid])
			{
			    foreach(new i : Player)
				{
			        if(IsSpectating[playerid] && SpectatingID[i] == issuerid)
					{
						PlayerTextDrawSetString(i, DoingDamage[2], string);
						TakeDmgCD[2][i] = 1;
						LastHitValue[2][i] = i;
					}
				}
			}
		}
	}

	if(LastHitValue[3][playerid] == -1 && LastHitValue[4][playerid] != issuerid && LastHitValue[5][playerid] != issuerid)
		LastHitValue[3][playerid] = issuerid;
	if(LastHitValue[3][playerid] == issuerid)
	{
	    DamageDone[3][playerid] += amount;

       	format(string, sizeof(string), "~r~	%s~l~ / ~r~-%.0f ~r~%s", GetName(issuerid), DamageDone[3][playerid], WeaponNames[weaponid]);
		PlayerTextDrawSetString(playerid, GettingDamaged[0], string);
		TakeDmgCD[3][playerid] = 1;

		if(BeingSpectated[playerid])
		{
		    foreach(new i : Player)
			{
		        if(IsSpectating[playerid] && SpectatingID[i] == playerid)
				{
		        	PlayerTextDrawSetString(i, GettingDamaged[0], string);
					TakeDmgCD[3][i] = 1;
					LastHitValue[3][i] = i;
				}
			}
		}
	}
	else
	{
		if(LastHitValue[4][playerid] == -1 && LastHitValue[5][playerid] != issuerid)
			LastHitValue[4][playerid] = issuerid;
		if(LastHitValue[4][playerid] == issuerid)
		{
		    DamageDone[4][playerid] += amount;

			format(string, sizeof(string), "~r~	%s~l~ / ~r~-%.0f ~r~%s", GetName(issuerid), DamageDone[4][playerid], WeaponNames[weaponid]);
        	PlayerTextDrawSetString(playerid, GettingDamaged[1], string);
			TakeDmgCD[4][playerid] = 1;

			if(BeingSpectated[playerid])
			{
			    foreach(new i : Player)
				{
			        if(IsSpectating[playerid] && SpectatingID[i] == playerid)
					{
			        	PlayerTextDrawSetString(i, GettingDamaged[1], string);
						TakeDmgCD[4][i] = 1;
						LastHitValue[4][i] = i;
					}
				}
			}
		}
		else
		{
		    DamageDone[5][playerid] += amount;
			LastHitValue[5][playerid] = issuerid;

			format(string, sizeof(string), "~r~	%s~l~ / ~r~-%.0f ~r~%s", GetName(issuerid), DamageDone[5][playerid], WeaponNames[weaponid]);
        	PlayerTextDrawSetString(playerid, GettingDamaged[2], string);
			TakeDmgCD[5][playerid] = 1;

			if(BeingSpectated[playerid])
			{
			    foreach(new i : Player)
				{
			        if(IsSpectating[playerid] && SpectatingID[i] == playerid)
					{
			        	PlayerTextDrawSetString(i, GettingDamaged[2], string);
						TakeDmgCD[5][i] = 1;
						LastHitValue[5][i] = i;
					}
				}
			}
		}
	}
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(killerid == INVALID_PLAYER_ID)
    	SendDeathMessage(INVALID_PLAYER_ID,playerid,reason);
    else
    	SendDeathMessage(killerid,playerid,reason);
    
	if(pInfo[killerid][PMODE] == 1 && IsStarted)
	{
		new string[128], string_en[128];
		
		if((GetPlayerWeapon(killerid) == WEAPON_DILDO || GetPlayerWeapon(killerid) == 0) && ! IsPlayerInAnyVehicle(killerid)) // 0 = Faust, fisten sollte schließlich auch belohnt werden
			pInfo[killerid][Points] += 3;
		else if((GetPlayerWeapon(killerid) == WEAPON_DEAGLE || GetPlayerWeapon(killerid) == WEAPON_SNIPER) && ! IsPlayerInAnyVehicle(killerid))
		    pInfo[killerid][Points] += 2;
		else if(GetPlayerWeapon(killerid) == WEAPON_SAWEDOFF || GetPlayerWeapon(killerid) == WEAPON_UZI || GetPlayerWeapon(killerid) == WEAPON_M4 || IsPlayerInAnyVehicle(killerid))
		    pInfo[killerid][Points] += 1;

		SetPlayerScore(killerid, pInfo[killerid][Points]);
		KillingSpree[killerid]++;
		KillingSpree[playerid] = 0;
  		pInfo[killerid][KILLS]++;
	    pInfo[playerid][DEATHS]++;

		if(KillingSpree[killerid] == 5)
		{
			format(string, sizeof(string), "<$>» KILLING SPREE «<#> %s tötet 5 Spieler in Folge!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» KILLING SPREE «<#> %s has killed 5 players in a row!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		else if(KillingSpree[killerid] == 10)
		{
			format(string, sizeof(string), "<$>» KILLING SPREE «<#> %s tötet 10 Spieler in Folge!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» KILLING SPREE «<#> %s has killed 10 players in a row!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		else if(KillingSpree[killerid] == 20)
		{
			format(string, sizeof(string), "<$>» KILLING SPREE «<#> %s tötet 20 Spieler in Folge!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» KILLING SPREE «<#> %s has killed 20 players in a row!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		
		if(KillingSpree[playerid] > 5)
		{
			format(string, sizeof(string), "<$>» DOMINANZ BEENDET «<#> %s hat %s's Blutrausch beendet!", GetName(killerid), GetName(playerid));
			format(string_en, sizeof(string_en), "<$>» OOPS «<#> %s has ended %s's killing spree!", GetName(killerid), GetName(playerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		
		TotalKills++;

		if(TotalKills == 1)
		{
			format(string, sizeof(string), "<$>» FIRST KILL «<#> %s tötet den ersten Spieler in diesem Event!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» FIRST KILL «<#> The first player was killed by %s!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		else if(TotalKills == 50)
		{
			format(string, sizeof(string), "<$>» First 50 «<#> %s tötet den 50. Spieler in diesem Event!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» First 50 «<#> The 50. player was killed by %s!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}
		else if(TotalKills == 100)
		{
			format(string, sizeof(string), "<$>» First 100 «<#> %s tötet den 100. Spieler in diesem Event!", GetName(killerid));
			format(string_en, sizeof(string_en), "<$>» First 100 «<#> The 100. player was killed by %s!", GetName(killerid));
			SendLanguageMessageToAll(COLOR_RED, string, string_en);
		}

 	    new tdstring[200];

		if(PlayerLanguage[playerid] == LANG_DE)
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);
		else
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[playerid][KILLS], pInfo[playerid][DEATHS], pInfo[playerid][Points], pInfo[playerid][DMGGIVEN], pInfo[playerid][DMGTAKEN], pInfo[playerid][Position], ParticipantsCounter);

		PlayerTextDrawSetString(playerid, Statistics, tdstring);

		if(PlayerLanguage[killerid] == LANG_DE)
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Tode: ~w~%d~n~~p~Punkte: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[killerid][KILLS], pInfo[killerid][DEATHS], pInfo[killerid][Points], pInfo[killerid][DMGGIVEN], pInfo[killerid][DMGTAKEN], pInfo[killerid][Position], ParticipantsCounter);
		else
		    format(tdstring, sizeof(tdstring), "~p~Kills: ~w~%d~n~~p~Deaths: ~w~%d~n~~p~Points: ~w~%d~n~~p~Damage: ~w~%.0f~n~~p~Taken: ~w~%.0f~n~~p~Position: ~w~%d/%d", pInfo[killerid][KILLS], pInfo[killerid][DEATHS], pInfo[killerid][Points], pInfo[killerid][DMGGIVEN], pInfo[killerid][DMGTAKEN], pInfo[killerid][Position], ParticipantsCounter);

		PlayerTextDrawSetString(killerid, Statistics, tdstring);
	}

	SavePlayer(killerid);
	SavePlayer(playerid);
	
    UpdateTopList();
	return 1;
}

public OnPlayerText(playerid, text[])
{
	new string[175], string_en[175];
	
	if(IsMuted[playerid] == 1)
	{
	    SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du wurdest gemuted!","<$>» Warning «<#> You are muted!");
	    return 0;
	}

    if(IsMuted[playerid] == 2)
	{
	    format(string, sizeof(string), "<$>» Warnung «<#> Du bist noch für %02d:%02d Minuten gemuted!", MuteMinutes[playerid], MuteSeconds[playerid]);
    	format(string_en,sizeof(string_en),"<$>» Warning «<#> You are muted for %02d:%02d minutes!", MuteMinutes[playerid],MuteSeconds[playerid]);
    	SendLanguageMessage(playerid, COLOR_RED, string, string_en);
    	return 0;
	}
	
	SpamCounter[playerid]++;
	SetTimerEx("ResetSpam", 3000, 0, "d", playerid);
	if(SpamCounter[playerid] > 4)
	{
		MutePlayer(playerid, 3);
		format(string, sizeof(string), "<$>» Admin «<#> %s wurde wegen Spam für 3 Minuten gemuted!", GetName(playerid));
		format(string_en,sizeof(string_en),"<$>» Admin «<#> %s was muted for spamming for 3 minutes!",GetName(playerid));
		SendLanguageMessageToAll(COLOR_ADMIN,string,string_en);
		return 0;
	}

	if(text[0] == '#' && IsPlayerAdmin(playerid))
	{
		format(string,sizeof(string),"[Adminchat] %s: %s",GetName(playerid),text[1]);
		SendChatMessageToAdmins(COLOR_BLUE, string);
	 	return 0;
	}
	
	if(IsPlayerAdmin(playerid))
	{
		format(string, sizeof(string),"%s {B5B5B5}[%d]: {FFFFFF}%s",GetName(playerid), playerid, text);
    	SendChatMessageToAll(COLOR_RED, string);
    	return 0;
	}
	
	if(IsChatLocked)
	{
	    SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Der Chat ist gesperrt!","<$>» Warning «<#> The chat is locked!");
	    return 0;
 	}
	
	new color = GetPlayerColor(playerid);
	format(string, sizeof(string),"%s {B5B5B5}[%d]: {FFFFFF}%s",GetName(playerid), playerid, text);
    SendChatMessageToAll(color, string);
    return 0;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if (!success)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Command existiert nicht, benutze /Help!","<$>» Warning «<#> This command does not exist, use /Help!");
    return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	foreach(new i : Player)
	{
    	if(GetPlayerState(i) == PLAYER_STATE_SPECTATING && SpectatingID[i] == playerid)
    	{
        	TogglePlayerSpectating(i, 1);
	    	PlayerSpectatePlayer(i, playerid);
		}
	}
	return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	if(ispassenger)
    {
        SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du darfst Fahrzeuge nicht als Beifahrer betreten!","<$>» Warning «<#> You are not allowed to enter cars as a passenger!");
        new Float: PPos[3];

	    GetPlayerPos(playerid, PPos[0], PPos[1], PPos[2]);
	    SetPlayerPos(playerid, PPos[0], PPos[1], PPos[2]);
    }
    
	foreach(new i : Player)
	{
	    if(GetPlayerState(i) == PLAYER_STATE_SPECTATING && SpectatingID[i] == playerid)
		{
	        TogglePlayerSpectating(i, 1);
	        PlayerSpectateVehicle(i, vehicleid);
		}
	}
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    if(oldstate == PLAYER_STATE_ONFOOT && newstate == PLAYER_STATE_DRIVER)
 		SetPlayerArmedWeapon(playerid, 0);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == DIALOG_CONTROLPANEL)
	{
		if(response)
		{
		    switch(listitem)
		    {
		        case 0:
		        {
		            if(IsStarted)
		            {
						SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Diese Einstellung darf nur vor dem Start des Events geändert werden!","<$>» Warning «<#> This setting can only be changed when the event has not been started yet!");
						return ShowAdminPanel(playerid);
					}

					if(PlayerLanguage[playerid] == LANG_DE)
						ShowPlayerDialog(playerid, DIALOG_TOTALMINUTES, DIALOG_STYLE_LIST, "Admin Control Panel - Eventdauer setzen", "10 Minuten\n20 Minuten\n30 Minuten\n40 Minuten\n50 Minuten\n60 Minuten", "Auswaehlen", "Abbrechen");
					else
						ShowPlayerDialog(playerid, DIALOG_TOTALMINUTES, DIALOG_STYLE_LIST, "Admin Control Panel - Set event duration", "10 minutes\n20 minutes\n30 minutes\n40 minutes\n50 minutes\n60 minutes", "Choose", "Cancel");
		        }
		        case 1:
		        {
		            if(IsPaused)
		            {
						SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Diese Einstellung darf während der Pause nicht geändert werden!","<$>» Warning «<#> This setting can only be changed before the break has started!");
						return ShowAdminPanel(playerid);
					}
					
					if(PlayerLanguage[playerid] == LANG_DE)
						ShowPlayerDialog(playerid, DIALOG_BREAKSTART, DIALOG_STYLE_LIST, "Admin Control Panel - Pausenzeit setzen", "10 Minuten\n20 Minuten\n30 Minuten\n40 Minuten\n50 Minuten\n60 Minuten", "Auswaehlen", "Abbrechen");
					else
						ShowPlayerDialog(playerid, DIALOG_BREAKSTART, DIALOG_STYLE_LIST, "Admin Control Panel - Set pause start time", "10 minutes\n20 minutes\n30 minutes\n40 minutes\n50 minutes\n60 minutes", "Choose", "Cancel");
		        }
		        case 2:
		        {
		            if(IsPaused)
		            {
						SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Diese Einstellung darf während der Pause nicht geändert werden!","<$>» Warning «<#> This setting can only be changed before the break has started!");
						return ShowAdminPanel(playerid);
					}

					if(PlayerLanguage[playerid] == LANG_DE)
						ShowPlayerDialog(playerid, DIALOG_BREAKDURATION, DIALOG_STYLE_LIST, "Admin Control Panel - Pausendauer setzen", "5 Minuten\n10 Minuten\n15 Minuten\nUnbegrenzt", "Auswaehlen", "Abbrechen");
					else
						ShowPlayerDialog(playerid, DIALOG_BREAKDURATION, DIALOG_STYLE_LIST, "Admin Control Panel - Set pause duration", "5 minutes\n10 minutes\n15 minutes\nUnlimited", "Choose", "Cancel");
		        }
		        case 3:
		        {
					PlayerTextDrawShow(playerid, Map);
					PlayerTextDrawShow(playerid, MapBox);
					PlayerTextDrawShow(playerid, Map2);
					PlayerTextDrawShow(playerid, Map2Box);
					
					SetTimerEx("SetClickable", 100, false, "i", playerid);
		        }
		        case 4:
		        {
					new string[1000];
					new counter;
					new MySQLQuery[128];
				 	mysql_format(Database, MySQLQuery, sizeof(MySQLQuery), "SELECT * FROM `WHITELIST`");
					new Cache:result = mysql_query(Database, MySQLQuery);
				 	cache_get_row_count(counter);
				    new name[24];
				 	
				 	for(new i = 0; i < counter; i++)
				 	{
						cache_get_value_name(i, "Name", name, 24);
						 
						new color[10];
					    if(IsPlayerConnected(ReturnUser(name)))
					        color = "{00FF00}";
						else
						    color = "{FFFFFF}";

						format(string, sizeof(string), "%s%s%s\n", string, color, name);
				 	}

 					cache_delete(result);
 					
					if(PlayerLanguage[playerid] == LANG_DE)
						ShowPlayerDialog(playerid, DIALOG_WHITELIST, DIALOG_STYLE_LIST, "Admin Control Panel - Whitelist", string, "Schließen","");
					else
						ShowPlayerDialog(playerid, DIALOG_WHITELIST, DIALOG_STYLE_LIST, "Admin Control Panel - Whitelist", string, "Close","");
		        }
		        case 5:
		        {
					foreach(new i : Player)
					{
					    if(!CAC_GetStatus(i))
					    {
					        new string[128], string_en[128];
					        
							format(string, sizeof(string), "<$>» Admin «<#> Anticheat konnte bei %s nicht abgefragt werden.", GetName(i));
							format(string_en, sizeof(string_en), "<$>» Admin «<#> Player %s's anticheat state couldn't be checked!", GetName(i));
					        SendLanguageMessage(playerid, COLOR_RED, string, string_en);
	        			}
					}
					
					ShowAdminPanel(playerid);
		        }
		    }
		}
	}

	if(dialogid == DIALOG_TOTALMINUTES)
	{
	    if(response)
	    {
	        new string[128], string_en[128];
	        switch(listitem)
	        {
	            case 0: TotalMinutes = 9;
	            case 1: TotalMinutes = 19;
	            case 2: TotalMinutes = 29;
	            case 3: TotalMinutes = 39;
	            case 4: TotalMinutes = 49;
	            case 5: TotalMinutes = 59;
	        }

			format(string, sizeof(string), "<$>» Admin «<#> Admin %s hat die Spielzeit auf %d Minuten gesetzt.", GetName(playerid), TotalMinutes);
			format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s has set the play time to %d minutes.", GetName(playerid), TotalMinutes);
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
			
			ShowAdminPanel(playerid);
	    }
	}
	if(dialogid == DIALOG_BREAKSTART)
	{
	    if(response)
	    {
	        new string[128], string_en[128];
	        switch(listitem)
	        {
	            case 0: Pause = 10;
	            case 1: Pause = 20;
	            case 2: Pause = 30;
	            case 3: Pause = 40;
	            case 4: Pause = 50;
	            case 5: Pause = 60;
	        }

			format(string, sizeof(string), "<$>» Admin «<#> Admin %s hat die Pausenzeit geaendert. Die Pause beginnt nach %d Minuten.", GetName(playerid), Pause);
			format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s has changed the break time. The break will start after %d minutes.", GetName(playerid), Pause);
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

			ShowAdminPanel(playerid);
	    }
	}
	if(dialogid == DIALOG_BREAKDURATION)
	{
	    if(response)
	    {
	        new string[128], string_en[128];
	        switch(listitem)
	        {
	            case 0: PauseDuration = 5;
	            case 1: PauseDuration = 10;
	            case 2: PauseDuration = 15;
	            case 3: PauseDuration = 0;
	        }

			format(string, sizeof(string), "<$>» Admin «<#> Admin %s hat die Pausendauer auf %d Minuten gesetzt.", GetName(playerid), PauseDuration);
			format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s has set the break duration to %d minutes.", GetName(playerid), PauseDuration);
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

			ShowAdminPanel(playerid);
	    }
	}
	if(dialogid == DIALOG_LANGUAGE)
 	{
 	    if(response)
 	    {
 	        PlayerLanguage[playerid] = LANG_DE;
			SendLanguageMessage(playerid, COLOR_PURPLE, "<$>» Sprache «<#> Deine Sprache wurde auf deutsch gesetzt. Incorrect? Use /language to change.","<$>» Sprache «<#> Deine Sprache wurde auf deutsch gesetzt. Incorrect? Use /language to change.");
		}
		else
		{
			PlayerLanguage[playerid] = LANG_EN;
			SendLanguageMessage(playerid, COLOR_PURPLE, "<$>» Language «<#> Your language has been changed to english. Falsch? Benutze /sprache.","<$>» Language «<#> Your language has been changed to english. Falsch? Benutze /sprache.");
		}
	}
	if(dialogid == DIALOG_LANGUAGE2)
 	{
 	    if(response)
 	        PlayerLanguage[playerid] = LANG_DE;
		else
			PlayerLanguage[playerid] = LANG_EN;
		
		SendClientMessage(playerid, -1,"");
		SendClientMessage(playerid, -1,"");
		SendClientMessage(playerid, -1,"");
		SendClientMessage(playerid,COLOR_BLUE,"-------------------------------------------------------------------------------------");
		SendLanguageMessage(playerid, -1,"Willkommen beim Las Venturas Strip All vs. All Tournament!","Welcome to the Las Venturas Strip All vs. All Tournament!");
		SendLanguageMessage(playerid, -1,"Um alle Commands zu sehen, benutze {008CDB}/Help {FFFFFF}!","To see all commands, use {008CDB}/Help {FFFFFF}!");
		SendLanguageMessage(playerid, -1,"Benutze {008CDB}/Report{FFFFFF}, um Regelbrecher zu melden!","Use {008CDB}/Report{FFFFFF} to report rulebreakers!");
		SendClientMessage(playerid, -1,"");
		SendClientMessage(playerid, -1," (C) by [USL] & [AMB] @ 2020");
		SendClientMessage(playerid, COLOR_BLUE,"------------------------------------------------------------------------------------");
		
		// SQL STUFF //
		new DB_Query[115];
		GetPlayerName(playerid, pInfo[playerid][Name], MAX_PLAYER_NAME); // Getting the player's name.
		mysql_format(Database, DB_Query, sizeof(DB_Query), "SELECT * FROM `SPIELERDATEN` WHERE `NAME` = '%e' LIMIT 1", pInfo[playerid][Name]);
		mysql_tquery(Database, DB_Query, "OnPlayerDataCheck", "ii", playerid, Corrupt_Check[playerid]);
	}
	
	if(dialogid == DIALOG_REGISTER)
	{
		if(!response)
			return KickPlayerEx(-1, playerid, "Canceled registration");
		if(strlen(inputtext) <= 3 || strlen(inputtext) > 60)
		{
	    	SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dein Passwort muss mindestens 4 Zeichen beinhalten.","<$>» Warning «<#> You need to use at least 4 characters.");

			new string[150];
			if(PlayerLanguage[playerid] == LANG_DE)
			{
   	    		format(string, sizeof(string), "{FFFFFF}Willkommen, %s.\n\n{008CDB}Du hast noch kein Passwort für deinen Account festgelegt.\n\
   	     		{008CDB}Bitte gib ein Passwort ein.\n\n", pInfo[playerid][Name]);
        		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registrieren", string, "Registrieren", "Abbrechen");
 			}
 			else
 			{
   	    		format(string, sizeof(string), "{FFFFFF}Welcome, %s.\n\n{008CDB}This account is not registered.\n\
   	     		{008CDB}Please, input your password below to proceed.\n\n", pInfo[playerid][Name]);
        		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", string, "Register", "Leave");
	   		}
		}
		else
		{
   			// Salting the player's password using SHA256 for a better security.
			for (new i = 0; i < 10; i++)
            {
            	pInfo[playerid][Salt][i] = random(79) + 47;
 			}
 			
    		pInfo[playerid][Salt][10] = 0;
	    	SHA256_PassHash(inputtext, pInfo[playerid][Salt], pInfo[playerid][Passwort], 65);
	    	new DB_Query[225];
	    	// Storing player's information if everything goes right.
	    	mysql_format(Database, DB_Query, sizeof(DB_Query), "INSERT INTO `SPIELERDATEN` (`Name`, `Passwort`, `SALT`, `POINTS`, `KILLS`, `DEATHS`)\
	    	VALUES ('%e', '%e', '%e', '0', '0', '0')", pInfo[playerid][Name], pInfo[playerid][Passwort], pInfo[playerid][Salt]);
	     	mysql_tquery(Database, DB_Query, "OnPlayerRegister", "d", playerid);
	    }
 	}

	if(dialogid == DIALOG_LOGIN)
	{
		if(!response)
			return KickPlayerEx(-1, playerid, "Canceled login");
			
		new Salted_Key[65];
		SHA256_PassHash(inputtext, pInfo[playerid][Salt], Salted_Key, 65);
		if(strcmp(Salted_Key, pInfo[playerid][Passwort]) == 0)
		{
			// Now, password should be correct as well as the strings
			// Matched with each other, so nothing is wrong until now.
			// We will activate the cache of player to make use of it e.g.
			// Retrieve their data.
			cache_set_active(pInfo[playerid][Player_Cache]);
			// Okay, we are retrieving the information now..
			cache_get_value_int(0, "ID", pInfo[playerid][ID]);
       		cache_get_value_int(0, "KILLS", pInfo[playerid][KILLS]);
       		cache_get_value_int(0, "DEATHS", pInfo[playerid][DEATHS]);
       		cache_get_value_int(0, "POINTS", pInfo[playerid][Points]);
       		cache_get_value_float(0, "DMGGIVEN", pInfo[playerid][DMGGIVEN]);
       		cache_get_value_float(0, "DMGTAKEN", pInfo[playerid][DMGTAKEN]);
       		cache_get_value_int(0, "PMODE", pInfo[playerid][PMODE]);
       		cache_get_value_int(0, "Position", pInfo[playerid][Position]);
       		
       		if(IsPlayerOnWhitelist(playerid))
       		{
				pInfo[playerid][PMODE] = 1;
				printf("%s's PMODE wurde auf 1 gesetzt.", GetName(playerid));
			}
			else
			{
				pInfo[playerid][PMODE] = 0;
				printf("%s's PMODE wurde auf 0 gesetzt.", GetName(playerid));
			}
				
			printf("%s's PMODE: %d", GetName(playerid), pInfo[playerid][PMODE]);
       		
       		SetPlayerScore(playerid, pInfo[playerid][Points]);
  			// So, we have successfully retrieved data? Now deactivating the cache.
			cache_delete(pInfo[playerid][Player_Cache]);
			pInfo[playerid][Player_Cache] = MYSQL_INVALID_CACHE;
			pInfo[playerid][LoggedIn] = true;
            SendLanguageMessage(playerid, COLOR_GREEN, "<$>» Information «<#> Du hast dich erfolgreich eingeloggt.","<$>» Information «<#> You successfully logged in to your account.");
		}
		else
		{
		    new string[128], string_en[128];
			pInfo[playerid][PasswordFails] += 1;
			
			if (pInfo[playerid][PasswordFails] >= 3)
				return KickPlayerEx(-1, playerid, "Wrong password");
			else
			{
				format(string, sizeof(string), "<$>» Warnung «<#> Falsches Passwort! (%d/3)", pInfo[playerid][PasswordFails]);
				format(string_en, sizeof(string_en), "<$>» Warning «<#> Wrong password! (%d/3)", pInfo[playerid][PasswordFails]);
				SendLanguageMessage(playerid, COLOR_RED, string, string_en);
				
				if(PlayerLanguage[playerid] == LANG_DE)
				{
	           		format(string, sizeof(string), "{FFFFFF}Willkommen zurück, %s.\n\n{008CDB}Dieser Account ist bereits registriert.\n\
	           		{008CDB}Bitte gib dein Passwort ein.\n\n", pInfo[playerid][Name]);
	           		
	           		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Abbrechen");
				}
				else
				{
	           		format(string, sizeof(string), "{FFFFFF}Welcome back, %s.\n\n{008CDB}This account is already registered.\n\
	           		{008CDB}Please, input your password below to proceed to the game.\n\n", pInfo[playerid][Name]);

	           		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login System", string, "Login", "Leave");
				}
			}
		}
	}
	
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	#define PRESSED(%0) \
		(((newkeys & (%0)) == (%0)) && ((oldkeys & (%0)) != (%0)))
		
 	if (PRESSED(KEY_JUMP))
		MoveSpeed[playerid] = 200;
	else
		MoveSpeed[playerid] = 100;
	return 1;
}

public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
	new string[128], string_en[128];
	
    if(playertextid == Map2)
    {
        UseSmallField = true;
        
        format(string, sizeof(string), "<$>» Admin «<#> Admin %s hat die Spielfeldgröße auf \"klein\" gesetzt!", GetName(playerid));
        format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s has set the play field size to \"small\"!", GetName(playerid));
        SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

		foreach(new i : Player)
		{
		    if(pInfo[i][PMODE] == 1)
		    {
				SetPlayerWorldBounds(i, 2380.437, 1885.6469, 1784.7277, 821.4630);
				GangZoneShowForPlayer(i, SmallFightZone, COLOR_FIGHTZONE);
				GangZoneHideForPlayer(i, FightZone);
			}
		}
		
        ShowAdminPanel(playerid);
    }
    if(playertextid == Map)
    {
        UseSmallField = false;

        format(string, sizeof(string), "<$>» Admin «<#> Admin %s hat die Spielfeldgröße auf \"groß\" gesetzt!", GetName(playerid));
        format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s has set the play field size to \"big\"!", GetName(playerid));
        SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

		foreach(new i : Player)
		{
		    if(pInfo[i][PMODE] == 1)
		    {
				SetPlayerWorldBounds(i, 2380.437, 1885.6469, 2370.4424, 821.4630);
				GangZoneShowForPlayer(i, FightZone, COLOR_FIGHTZONE);
				GangZoneHideForPlayer(i, SmallFightZone);
			}
		}
				
        ShowAdminPanel(playerid);
    }

	PlayerTextDrawHide(playerid, Map);
	PlayerTextDrawHide(playerid, MapBox);
	PlayerTextDrawHide(playerid, Map2);
	PlayerTextDrawHide(playerid, Map2Box);

	CancelSelectTextDraw(playerid);
    return 1;
}

public OnPlayerUpdate(playerid)
{
	if(FreeCam[playerid][cameramode] == CAMERA_MODE_FLY)
	{
		new keys,ud,lr;
		GetPlayerKeys(playerid,keys,ud,lr);

		if(FreeCam[playerid][mode] && (GetTickCount() - FreeCam[playerid][lastmove] > 100))
		{
		    MoveCamera(playerid);
		}
		if(FreeCam[playerid][udold] != ud || FreeCam[playerid][lrold] != lr)
		{
			if((FreeCam[playerid][udold] != 0 || FreeCam[playerid][lrold] != 0) && ud == 0 && lr == 0){
				StopPlayerObject(playerid, FreeCam[playerid][flyobject]);
				FreeCam[playerid][mode]      = 0;
				FreeCam[playerid][accelmul]  = 0.0;
			}
			else
			{
				FreeCam[playerid][mode] = GetMoveDirectionFromKeys(ud, lr);
				MoveCamera(playerid);
			}
		}
		FreeCam[playerid][udold] = ud; FreeCam[playerid][lrold] = lr;
	}
	
    InactiveTime[playerid] = 0;

	new drunk2 = GetPlayerDrunkLevel(playerid);
	if(drunk2 < 100)
	{
		SetPlayerDrunkLevel(playerid,2000);
	}
	else
	{
		if(DrunkLevel[playerid] != drunk2)
		{
			new fps = DrunkLevel[playerid] - drunk2;
			if((fps > 0) && (fps < 200))
				CurrentFrames[playerid] = fps;
			DrunkLevel[playerid] = drunk2;
		}
	}
	return 1;
}

// Eigene Funktionen
forward OnGlobalTimer();
public OnGlobalTimer()
{
	// Uhr
	if(IsStarted)
	{
		Seconds --;
	 	if(Seconds < 0)
	 	{
	    	Minutes --;
	    	Seconds = 59;
	    	
	    	foreach(new i : Player)
	    	{
		    	new string[128];
				new string_en[128];

				if(GetPlayerPing(i) > MAX_PING && pInfo[i][PMODE] == 1)
				{
					KickPlayerEx(-1, i, "Too high ping (Max. "#MAX_PING")");
					SendLanguageMessage(i, COLOR_RED, "Du wurdest wegen zu hohem Ping gekickt.","You have been kicked for having a too high ping.");
				}
				if(CurrentFrames[i] <= MIN_FPS && pInfo[i][PMODE] == 1)
				{
			  		SendLanguageMessage(i, COLOR_RED, "<$>» Warnung «<#> Deine FPS sind zu niedrig! Du brauchst mindestens "#MIN_FPS" FPS!","<$>» Warning «<#> Your FPS are too low! You need at least "#MIN_FPS" FPS!");

					format(string, sizeof(string), "<$>» Warnung «<#> %s's FPS sind zu niedrig! Benutze /FPS [ID] um seine Frames zu sehen.", GetName(i));
					format(string_en, sizeof(string_en), "<$>» Warning «<#> %s's FPS are too low! Use /FPS [ID] to check his frames.", GetName(i));
			  		SendClientMessageToAdmins(COLOR_ADMIN, string, string_en);
				}
			}
		}
		if(Minutes == Pause && Seconds == 0)
		{
			PauseEvent(PauseDuration);
	 	}
	 	if(Minutes == 0 && Seconds == 1)
		{
	 		IsStarted = 0;

			FinishEvent();
		}

		new string[128];
	    format(string,sizeof(string),"%02d:%02d", Minutes, Seconds);
	    TextDrawSetString(Clock, string);
	}
	
    // Playerkram
	foreach(new i : Player)
	{
	    new tdstring[20];
		format(tdstring,sizeof(tdstring),"~y~FPS: %d",CurrentFrames[i]-1);
		PlayerTextDrawSetString(i, FPS,tdstring);

		if(PlayerPaused[i] == false)
        {
            InactiveTime[i] ++;
            if(InactiveTime[i] == 20 && pInfo[i][PMODE] == 1 && IsStarted)
            {
				KickPlayerEx(-1, i, "AFK on field");
			} 
        }

	    if(TakeDmgCD[0][i] > 0)
		{
			TakeDmgCD[0][i]++;
			if(TakeDmgCD[0][i] == 5)
			{
				DamageDone[0][i] = 0;
				LastHitValue[0][i] = -1;
				PlayerTextDrawSetString(i, DoingDamage[0], "_");
				TakeDmgCD[0][i] = 0;
			}
		}
		if(TakeDmgCD[1][i] > 0)
		{
			TakeDmgCD[1][i]++;
			if(TakeDmgCD[1][i] == 5)
			{
				DamageDone[1][i] = 0;
				LastHitValue[1][i] = -1;
                PlayerTextDrawSetString(i, DoingDamage[1], "_");
				TakeDmgCD[1][i] = 0;
			}
		}
		if(TakeDmgCD[2][i] > 0)
		{
			TakeDmgCD[2][i]++;
			if(TakeDmgCD[2][i] == 5)
			{
				DamageDone[2][i] = 0;
                PlayerTextDrawSetString(i, DoingDamage[2], "_");
				LastHitValue[2][i] = -1;
				TakeDmgCD[2][i] = 0;
			}
		}
		if(TakeDmgCD[3][i] > 0)
		{
			TakeDmgCD[3][i]++;
			if(TakeDmgCD[3][i] == 5)
			{
				DamageDone[3][i] = 0;
				LastHitValue[3][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[0], "_");
				TakeDmgCD[3][i] = 0;
			}
		}
		if(TakeDmgCD[4][i] > 0)
		{
			TakeDmgCD[4][i]++;
			if(TakeDmgCD[4][i] == 5)
			{
				DamageDone[4][i] = 0;
				LastHitValue[4][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[1], "_");
				TakeDmgCD[4][i] = 0;
			}
		}
		if(TakeDmgCD[5][i] > 0)
		{
			TakeDmgCD[5][i]++;
			if(TakeDmgCD[5][i] == 5)
			{
				DamageDone[5][i] = 0;
				LastHitValue[5][i] = -1;
                PlayerTextDrawSetString(i, GettingDamaged[2], "_");
				TakeDmgCD[5][i] = 0;
			}
		}
	}
	return 1;
}

forward StartEvent();
public StartEvent()
{
	IsStarting = 1;
	
	foreach(new i : Player)
	{
	    if(pInfo[i][PMODE] == 1 && !IsUsingFreeCam[i] && !IsSpectating[i])
	    {
			PlayerTextDrawHide(i, FPS);

			PlayerTextDrawShow(i, TopBar);
			PlayerTextDrawShow(i, BottomBar);
			PlayerTextDrawShow(i, CountDown);
			PlayerTextDrawHide(i, Statistics);
			TextDrawHideForPlayer(i, URL[0]);
			TextDrawHideForPlayer(i, URL[1]);

			new Float: PPos[3];
	   		GetPlayerPos(i, PPos[0], PPos[1], PPos[2]);
	    	SetPlayerPos(i, PPos[0], PPos[1], PPos[2]+4);

			InterpolateCameraPos(i, 2062.877929, 956.348327, 161.247772, 2141.872558, 2318.531982, 136.345840, 65000);
			InterpolateCameraLookAt(i, 2062.872070, 955.912597, 156.266799, 2141.889404, 2318.967529, 131.364868, 65000);
     	}
		PlayerTextDrawHide(i, EventInfo);
		TextDrawHideForPlayer(i, Clock);
	}
	
	CountDownCounter = 60;
	SendLanguageMessageToAll(COLOR_ADMIN, "Der Chat wurde bis zum Eventstart für eine Minute geschlossen.","The that will be locked for one minute till the event has been started.");
	IsChatLocked = 1;
	SetTimer("StartCountDown",1000,0);
	return 1;
}

forward FinishEvent();
public FinishEvent()
{
	IsStarted = 0;
	IsPaused = 0;

	EventInfoTextDE = "~y~Das Event wurde beendet!";
	EventInfoTextEN = "~y~The event is finished!";

	foreach(new i : Player)
	{
		if(PlayerLanguage[i] == LANG_DE)
		    PlayerTextDrawSetString(i, EventInfo, EventInfoTextDE);
		else
		    PlayerTextDrawSetString(i, EventInfo, EventInfoTextEN);
	
		RemoveBuildingForPlayer(i, 8414, 2096.2031, 1285.4375, 19.8984, 0.25);
		RemoveBuildingForPlayer(i, 3513, 2037.4297, 1302.7422, 13.9922, 0.25);
		RemoveBuildingForPlayer(i, 3516, 2040.1719, 1283.0938, 12.9766, 0.25);
		RemoveBuildingForPlayer(i, 3509, 2057.2500, 1261.4141, 9.8281, 0.25);
		RemoveBuildingForPlayer(i, 620, 2168.7969, 1263.0781, 9.7031, 0.25);
		RemoveBuildingForPlayer(i, 3509, 2057.2500, 1323.2813, 9.7891, 0.25);
		RemoveBuildingForPlayer(i, 3509, 2057.4063, 1305.0938, 9.7813, 0.25);
		RemoveBuildingForPlayer(i, 3509, 2057.3672, 1288.8984, 9.8672, 0.25);
		RemoveBuildingForPlayer(i, 647, 2057.5703, 1298.3672, 11.1484, 0.25);
		RemoveBuildingForPlayer(i, 647, 2057.5703, 1318.1406, 11.1484, 0.25);
		RemoveBuildingForPlayer(i, 8397, 2096.2031, 1285.4375, 19.8984, 0.25);
		RemoveBuildingForPlayer(i, 9019, 2096.2031, 1286.0391, 11.4609, 0.25);
		RemoveBuildingForPlayer(i, 3509, 2057.5234, 1331.7969, 9.9063, 0.25);
	}
	
	CreateObject(16781, 2148.17, 1285.61, 2.68,   0.00, 0.00, 270.00);
	CreateObject(19840, 2139.40, 1275.45, 7.01,   0.00, 0.00, -90.84);
	CreateObject(19840, 2137.93, 1296.01, 7.01,   0.00, 0.00, -90.84);
	CreateObject(16133, 2133.68, 1253.28, -8.00,   0.00, 0.00, -80.76);
	CreateObject(16133, 2134.92, 1316.96, -8.00,   0.00, 0.00, -115.14);
	CreateObject(710, 2127.97, 1321.35, 22.07,   0.00, 0.00, 0.00);
	CreateObject(710, 2146.09, 1318.62, 22.07,   0.00, 0.00, 0.00);
	CreateObject(620, 2167.24, 1305.88, 9.56,   356.86, 0.00, 0.00);
	CreateObject(620, 2166.32, 1266.45, 9.56,   356.86, 0.00, 0.00);
	CreateObject(7978, 2067.23, 1286.06, -6.81,   0.00, 0.00, 0.00);
	CreateObject(7978, 2067.36, 1281.00, -7.76,   0.00, 0.00, 0.00);
	CreateObject(7978, 2067.30, 1291.33, -7.27,   0.00, 0.00, 0.00);
	CreateObject(5992, 2105.31, 1285.90, 12.31,   0.00, 0.00, 90.06);
	CreateObject(11420, 2089.66, 1238.12, 9.63,   0.00, 0.00, 63.60);
	CreateObject(19840, 2129.94, 1259.96, 5.96,   0.00, 0.00, -138.06);
	CreateObject(19840, 2131.49, 1307.63, 5.96,   0.00, 0.00, -38.94);
	CreateObject(7586, 2088.90, 1225.50, 4.34,   0.00, 0.00, 0.00);
	CreateObject(3819, 2089.65, 1281.48, 10.79,   0.00, 0.00, -180.12);
	CreateObject(3819, 2089.66, 1290.47, 10.79,   0.00, 0.00, -180.18);
	CreateObject(3437, 2109.64, 1299.65, 11.42,   0.00, 0.00, -90.84);
	CreateObject(3437, 2109.59, 1304.31, 10.16,   0.00, 0.00, -90.84);
	CreateObject(3437, 2109.63, 1309.09, 8.76,   0.00, 0.00, -90.84);
	CreateObject(3437, 2109.56, 1272.71, 11.36,   0.00, 0.00, -90.84);
	CreateObject(3437, 2109.57, 1267.88, 10.15,   0.00, 0.00, -90.84);
	CreateObject(3437, 2109.54, 1263.06, 8.77,   0.00, 0.00, -90.84);
	CreateObject(3508, 2110.17, 1245.96, 9.71,   0.00, 0.00, 0.00);
	CreateObject(3508, 2110.24, 1255.45, 9.71,   0.00, 0.00, -48.84);
	CreateObject(3508, 2109.63, 1316.27, 9.71,   0.00, 0.00, -126.84);
	CreateObject(11567, 2053.47, 1337.04, 6.07,   0.00, 0.00, -180.60);
	CreateObject(8619, 2096.85, 1286.03, 10.36,   0.00, 0.00, -180.24);
	CreateObject(3819, 2089.66, 1272.27, 10.79,   0.00, 0.00, -180.18);
	CreateObject(3819, 2089.64, 1299.77, 10.79,   0.00, 0.00, -179.94);
	CreateObject(620, 2127.76, 1268.92, -1.07,   356.86, 0.00, 0.00);
	CreateObject(620, 2127.42, 1302.52, -1.07,   356.86, 0.00, 0.00);
	CreateObject(1232, 2087.49, 1304.61, 12.25,   0.00, 0.00, 0.00);
	CreateObject(1232, 2087.58, 1267.39, 12.25,   0.00, 0.00, 0.00);
	CreateObject(7071, 2209.91, 1319.24, 3.21,   0.00, 0.00, -135.18);
	
	
	// Spieler spawnen
	new MySQLQuery[128], stringlb[200], counter, Float:distanceright = 1302.5850, Float:distancestraight = 2087.9441;
 	mysql_format(Database, MySQLQuery, sizeof(MySQLQuery), "SELECT * FROM `SPIELERDATEN` order by POINTS desc");
	new Cache:result = mysql_query(Database, MySQLQuery);
 	cache_get_row_count(counter);
 	
 	new tribuenencounter;
 	new winnerName[24];
 	
 	for(new i = 0; i < counter; i++)
 	{
		InterpolateCameraPos(i, 2043.183959, 1284.983398, 42.875762, 2090.961669, 1285.640625, 13.813154, 5000);
		InterpolateCameraLookAt(i, 2047.437988, 1284.922485, 40.249019, 2095.948730, 1285.651000, 13.454089, 5000);
		
        new name[24];
        new points;
		new kills;
		new deaths;
		new Float:dmggiven;
		new Float:dmgtaken;
		
		cache_get_value_name(i, "Name", name, 24);
		cache_get_value_int(i, "POINTS", points);
		cache_get_value_int(i, "KILLS", kills);
		cache_get_value_int(i, "DEATHS", deaths);
		cache_get_value_float(i, "DMGGIVEN", dmggiven);
		cache_get_value_float(i, "DMGTAKEN", dmgtaken);
		
		new playerid = ReturnUser(name);
		
		// Tribünenplätze
		switch(i)
		{
		    case 0: // Platz 1
			{
			    if(IsPlayerConnected(playerid))
			    {
					SetPlayerPos(playerid, 2106.8474,1285.6917,13.0494);
					SetPlayerFacingAngle(playerid, 86.4115);
					
					new Float:x,Float:y,Float:z,Float:angle;
					GetPlayerPos(playerid,x,y,z);
					GetPlayerFacingAngle(playerid,angle);
					x+=(0.90*floatsin(-angle,degrees));
					y+=(0.90*floatcos(-angle,degrees));
					new var, whoreid;
					
					foreach(new whore : Player)
			        {
			            if(GetPlayerScore(whore)>var)
		                {
							var=GetPlayerScore(whore);
							whoreid=whore;
		                }
					}
					
					if(whoreid != playerid)
					{
						SetPlayerPos(whoreid,x,y,z);
						SetPlayerFacingAngle(whoreid,angle+180);

						ApplyAnimation(playerid,"BLOWJOBZ","BJ_STAND_LOOP_P",4.0,true,false,false,false,0);
						ApplyAnimation(whoreid,"BLOWJOBZ","BJ_STAND_LOOP_W",4.0,true,false,false,false,0);
					}
					else
					{
						ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
						ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
					}
				}
				
				format(winnerName, sizeof(winnerName), "%s", name);
				
				format(stringlb, sizeof(stringlb), "{FF0000}%s\n{00FF00} Points: {FFFFFF}%d\n{00FF00} Kills: {FFFFFF}%d\n{00FF00} Deaths: {FFFFFF}%d\n{00FF00} DMG given: {FFFFFF}%.0f\n{00FF00} DMG taken: {FFFFFF}%.0f",
				name, points, kills, deaths, dmggiven, dmgtaken);

				Create3DTextLabel(stringlb, -1, 2106.8474,1285.6917,12.0494, 40.0, 0, 0);
			}
		    case 1: // Platz 2
			{
			    if(IsPlayerConnected(playerid))
			    {
					SetPlayerPos(playerid, 2106.0852,1291.1991,12.5862);
					SetPlayerFacingAngle(playerid, 86.4115);
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
				}

				format(stringlb, sizeof(stringlb), "{FF0000}%s\n{00FF00} Points: {FFFFFF}%d\n{00FF00} Kills: {FFFFFF}%d\n{00FF00} Deaths: {FFFFFF}%d\n{00FF00} DMG given: {FFFFFF}%.0f\n{00FF00} DMG taken: {FFFFFF}%.0f",
				name, points, kills, deaths, dmggiven, dmgtaken);

				Create3DTextLabel(stringlb, -1, 2106.0852,1291.1991,11.5862, 40.0, 0, 0);
			}
		    case 2: // Platz 3
			{
			    if(IsPlayerConnected(playerid))
			    {
					SetPlayerPos(playerid, 2106.4880,1280.7174,12.0962);
					SetPlayerFacingAngle(playerid, 86.4115);
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
				}
				
				format(stringlb, sizeof(stringlb), "{FF0000}%s\n{00FF00} Points: {FFFFFF}%d\n{00FF00} Kills: {FFFFFF}%d\n{00FF00} Deaths: {FFFFFF}%d\n{00FF00} DMG given: {FFFFFF}%.0f\n{00FF00} DMG taken: {FFFFFF}%.0f",
				name, points, kills, deaths, dmggiven, dmgtaken);

				Create3DTextLabel(stringlb, -1, 2106.4880,1280.7174,11.0962, 40.0, 0, 0);
			}
			default:
			{
			    if(IsPlayerConnected(playerid))
			    {
				    SetPlayerPos(playerid, distancestraight,distanceright,12.3883);
					SetPlayerFacingAngle(playerid, 249.0418);
					
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);
					ApplyAnimation(playerid, "ON_LOOKERS", "wave_loop", 3.0, 1, 0, 0, 0, -1);

					if(tribuenencounter == 11)
					{
					    distanceright = 1302.5850;
					    distancestraight = distancestraight + 2.000;
	    			}

					if(tribuenencounter == 22)
					{
					    distanceright = 1302.5850;
					    distancestraight = distancestraight + 2.000;
	    			}

					if(tribuenencounter == 33)
					{
					    distanceright = 1302.5850;
					    distancestraight = distancestraight + 2.000;
	    			}
					else
				    	distanceright = distanceright-3.000;
				    	
					tribuenencounter++;
   				}
			}
		}
 	}

	new string[128], string_en[128];

	format(string, sizeof(string), "Event beendet! %s hat das Tournament gewonnen!", winnerName);
	format(string_en, sizeof(string_en), "Event finished! %s has won the tournament!", winnerName);
	SendLanguageMessageToAll(COLOR_BLUE, string, string_en);

 	cache_delete(result);
	return 1;
}

forward StartCountDown();
public StartCountDown()
{
	new string[128];
	if(CountDownCounter >= 1)
	{
		foreach(new i : Player)
		{
			if(PlayerLanguage[i] == LANG_DE)
				format(string, sizeof(string), "Das Tournament beginnt in %d Sekunden...", CountDownCounter);
			else
				format(string, sizeof(string), "The tournaments will start in %d seconds...", CountDownCounter);

			PlayerTextDrawSetString(i, CountDown, string);
		}
		SetTimer("StartCountDown",1000,0);
		CountDownCounter--;

		if(CountDownCounter == 57)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Willkommen beim Tournament! Es geht in einer Minute los.","<$>» Information «<#> Welcome to the tournament! We will start in one minute.");
		if(CountDownCounter == 49)
  		{
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Sammle die meisten Punkte um zu gewinnen! Hier die Punkteverteilung:","<$>» Information «<#> Get the most points to win! This is how many points you get for each weapon:");
		    SendLanguageMessageToAll(COLOR_GREEN, "   - Dildo & Faust: 3 Punkte","   - Dildo & Fist: 3 points");
		    SendLanguageMessageToAll(COLOR_GREEN, "   - Deagle & Sniper: 2 Punkte","   - Deagle & Sniper: 2 points");
		    SendLanguageMessageToAll(COLOR_GREEN, "   - Sawnoff, M4 & UZI: 1 Punkt","   - Sawnoff, M4 & UZI: 1 points");
    	}
		if(CountDownCounter == 44)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Auf der rechten Seite werden die Top 20 Spieler angezeigt.","<$>» Information «<#> On the right side you will find the top 20 players.");
		if(CountDownCounter == 39)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Als Zuschauer kannst du mit /Spec oder /Freecam zuschauen.","<$>» Information «<#> As a spectator you can watch the fights with /Spec or /Freecam.");
		if(CountDownCounter == 33)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Wenn du nicht mehr sprinten kannst, benutze /Sync!.","<$>» Information «<#> If you can't sprint anymore, use /Sync!");
		if(CountDownCounter == 27)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Nach 30 Minuten wird es eine 5 minütige Pause geben.","<$>» Information «<#> After 30 minutes we will take a break for 5 minutes.");
		if(CountDownCounter == 19)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Jeder Spieler ist nach einem Respawn für 5 Sekunden vor Spawnkill geschützt.","<$>» Information «<#> Every player has godmode for 5 seconds after respawning to prevend spawn kill");
		if(CountDownCounter == 9)
		    SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Es geht jeden Moment los. Viel Glück! Bei Fragen stehen die Admins zur Verfügung.","<$>» Information «<#> It will start very soon. Good luck! If you have any questions, don't hesitate to ask any admin.");
	}
	else
	{
		EventInfoTextDE = "~g~Das Event wurde gestartet!";
		EventInfoTextEN = "~g~The event has been started!";

		Seconds = 59;
		Minutes = TotalMinutes;
		
		SendLanguageMessageToAll(COLOR_GREEN, "<$>» Information «<#> Los geht's! Viel Glück!","<$>» Information «<#> Let's go! Good luck!");
		IsChatLocked = 0;

		IsStarting = 0;
		IsStarted = true;

		foreach(new i : Player)
		{
			if(PlayerLanguage[i] == LANG_DE)
			    PlayerTextDrawSetString(i, EventInfo, EventInfoTextDE);
			else
			    PlayerTextDrawSetString(i, EventInfo, EventInfoTextEN);

			PlayerTextDrawShow(i, EventInfo);
			TextDrawShowForPlayer(i, Clock);
			TextDrawShowForPlayer(i, TopList);

		    if(pInfo[i][PMODE] == 1 && !IsUsingFreeCam[i] && !IsSpectating[i])
				SpawnPlayer(i);
		}
	}
	return 1;
}

forward PauseEvent(minutes);
public PauseEvent(minutes)
{
	if(minutes > 0)
		Continue = SetTimer("ContinueEvent",1000*60*minutes,1);
		
	IsStarted = 0;
	IsPaused = 1;

	ContinueCountDown = 3;

	EventInfoTextDE = "~y~Das Event wurde pausiert!";
	EventInfoTextEN = "~y~The event is paused!";

 	foreach(new i : Player)
	{
	    if(pInfo[i][PMODE] == 1 && !IsUsingFreeCam[i] && !IsSpectating[i])
			TogglePlayerControllable(i, false);

		if(PlayerLanguage[i] == LANG_DE)
		    PlayerTextDrawSetString(i, EventInfo, EventInfoTextDE);
		else
		    PlayerTextDrawSetString(i, EventInfo, EventInfoTextEN);
	}
	return 1;
}

forward ContinueEvent();
public ContinueEvent()
{
	if(ContinueCountDown == 3)
	    SendLanguageMessageToAll(COLOR_BLUE, "<$>» Event «<#> Das Event wird fortgesetzt!","<$>» Event «<#> The event will continue now!");
	
	if(ContinueCountDown > 0)
	{
	    new string[10];
	    format(string, sizeof(string), "~r~%d..", ContinueCountDown);
		GameTextForAll(string,1000,3);
		ContinueCountDown--;
		return 1;
	}

    IsStarted = 1;
    IsPaused = 0;
	IsStarting = 0;

	EventInfoTextDE = "~g~Das Event wurde gestartet!";
	EventInfoTextEN = "~g~The event has been started!";
		
	foreach(new i : Player)
	{
		TogglePlayerControllable(i, true);

		if(PlayerLanguage[i] == LANG_DE)
		{
			PlayerTextDrawSetString(i, EventInfo, EventInfoTextDE);
			GameTextForPlayer(i, "~g~LOS! LOS! LOS!",1000,3);
		}
		else
		{
		    PlayerTextDrawSetString(i, EventInfo, EventInfoTextEN);
			GameTextForPlayer(i,"~g~GO! GO! GO!",1000,3);
		}

		TextDrawShowForPlayer(i, TopList);
	}
	
	KillTimer(Continue);
	return 1;
}

forward SendLanguageMessageToAll(color,text_de[],text_en[]);
public SendLanguageMessageToAll(color,text_de[],text_en[])
{
	new string[128], string_en[128];
	ModifyMessageColor(text_de, color, string, sizeof string);
	ModifyMessageColor(text_en, color, string_en, sizeof string_en);

	if(!strlen(text_de) || !strlen(text_en))
		return false;
	foreach(new i : Player)
		SendLanguageMessage(i,color,text_de,text_en);
	return 1;
}


forward SendChatMessageToAll(color,text[]);
public SendChatMessageToAll(color,text[])
{
	new splituppart[80], mainpart[121];

	strmid(mainpart, text, 0, strlen(text));
	strmid(splituppart, text, 120, strlen(text));

	if(!strlen(text))
		return false;
	
	SendClientMessageToAll(color,mainpart);

	if(strlen(splituppart))
		SendClientMessageToAll(-1, splituppart);
		
	return 1;
}

forward SendChatMessageToAdmins(color,text[]);
public SendChatMessageToAdmins(color,text[])
{
	new splituppart[80], mainpart[105];

	strmid(mainpart, text, 0, strlen(text));
	strmid(splituppart, text, 104, strlen(text));

	if(!strlen(text))
		return false;
	foreach(new i : Player)
	{
		if(IsPlayerAdmin(i))
		{
			SendClientMessage(i,color,mainpart);

			if(strlen(splituppart))
				SendClientMessage(i, color, splituppart);
		}
	}
	return 1;
}

forward SendLanguageMessage(playerid, color, text_de[],text_en[]);
public SendLanguageMessage(playerid, color, text_de[],text_en[])
{
 	new string[155], string_en[155];
	
	ModifyMessageColor(text_de, color, string, sizeof string);
	ModifyMessageColor(text_en, color, string_en, sizeof string_en);

   	if(PlayerLanguage[playerid] == LANG_DE)
		SendClientMessageEx(playerid, color, text_de);
	else
		SendClientMessageEx(playerid, color, text_en);
		
	return 1;
}

forward SendClientMessageToAdmins(color,text_de[],text_en[]);
public SendClientMessageToAdmins(color,text_de[],text_en[])
{
	new string[155], string_en[155];

  	ModifyMessageColor(text_de, color, string, sizeof string);
	ModifyMessageColor(text_en, color, string_en, sizeof string_en);
	
	foreach(new i : Player)
	{
		if(IsPlayerAdmin(i))
		{
			if(PlayerLanguage[i] == LANG_DE)
				SendClientMessageEx(i, color, text_de);
			else
				SendClientMessageEx(i, color, text_en);
		}
	}
	return 1;
}

stock GetIP(playerid)
{
	new ip[24];
	GetPlayerIp(playerid, ip,sizeof(ip));
	return ip;
}

stock SendClientMessageEx(playerid, color, const message[])
{
	new	string[1024];

	ModifyMessageColor(message, color, string, sizeof string);
	return SendClientMessage(playerid, color, string);
}

stock GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
	GetPlayerName(playerid,name,sizeof(name));
	return name;
}

stock MutePlayer(playerid, minuten)
{
	IsMuted[playerid] = 2;
	MuteMinutes[playerid] = minuten;
  	MuteSeconds[playerid] = 0;
	OnPlayerMuted(playerid);
	return 1;
}

forward ResetSpam(playerid);
public ResetSpam(playerid)
{
	return SpamCounter[playerid] = 0;
}

forward OnPlayerMuted(playerid);
public OnPlayerMuted(playerid)
{
	if (MuteMinutes[playerid] <= 0 && MuteSeconds[playerid] <= 0)
	    UnmutePlayer(playerid);
	else
	{
		if (MuteMinutes[playerid] >= 1 && MuteSeconds[playerid] <= 0)
		{
            MuteMinutes[playerid]--;
            MuteSeconds[playerid]= 59;
		}
		else
  			MuteSeconds[playerid]--;
  			
		MuteTimer[playerid] = SetTimerEx("OnPlayerMuted", 1000, 0, "d", playerid);
	}
	return 1;
}

stock UnmutePlayer(playerid)
{
	new string[128], string_en[128];
 	if (IsPlayerConnected(playerid) && IsMuted[playerid] == 2)
  	{
 		KillTimer(MuteTimer[playerid]);
   		format(string, sizeof(string), "<$>» Admin «<#> Der Chatverbot von %s [%d] wurde vom Server aufgehoben.", GetName(playerid), playerid);
   		format(string_en, sizeof(string_en), "<$>» Admin «<#> Player %s [%d] was unmuted by the server.", GetName(playerid), playerid);
		SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
      	IsMuted[playerid] = 0;
  	}
}

stock MoveCamera(playerid)
{
	new Float:FV[3], Float:CP[3];
	GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);
    
	if(FreeCam[playerid][accelmul] <= 1)
		FreeCam[playerid][accelmul] += ACCEL_RATE;
		
	new Float:speed = MoveSpeed[playerid] * FreeCam[playerid][accelmul];
	new Float:X, Float:Y, Float:Z;
	GetNextCameraPosition(FreeCam[playerid][mode], CP, FV, X, Y, Z);
	MovePlayerObject(playerid, FreeCam[playerid][flyobject], X, Y, Z, speed);
	FreeCam[playerid][lastmove] = GetTickCount();
	return 1;
}

stock GetNextCameraPosition(move_mode, Float:CP[3], Float:FV[3], &Float:X, &Float:Y, &Float:Z)
{
    #define OFFSET_X (FV[0]*6000.0)
	#define OFFSET_Y (FV[1]*6000.0)
	#define OFFSET_Z (FV[2]*6000.0)
	switch(move_mode)
	{
		case MOVE_FORWARD:
		{
			X = CP[0]+OFFSET_X;
			Y = CP[1]+OFFSET_Y;
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_BACK:
		{
			X = CP[0]-OFFSET_X;
			Y = CP[1]-OFFSET_Y;
			Z = CP[2]-OFFSET_Z;
		}
		case MOVE_LEFT:
		{
			X = CP[0]-OFFSET_Y;
			Y = CP[1]+OFFSET_X;
			Z = CP[2];
		}
		case MOVE_RIGHT:
		{
			X = CP[0]+OFFSET_Y;
			Y = CP[1]-OFFSET_X;
			Z = CP[2];
		}
		case MOVE_BACK_LEFT:
		{
			X = CP[0]+(-OFFSET_X - OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y + OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_BACK_RIGHT:
		{
			X = CP[0]+(-OFFSET_X + OFFSET_Y);
 			Y = CP[1]+(-OFFSET_Y - OFFSET_X);
		 	Z = CP[2]-OFFSET_Z;
		}
		case MOVE_FORWARD_LEFT:
		{
			X = CP[0]+(OFFSET_X  - OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  + OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
		case MOVE_FORWARD_RIGHT:
		{
			X = CP[0]+(OFFSET_X  + OFFSET_Y);
			Y = CP[1]+(OFFSET_Y  - OFFSET_X);
			Z = CP[2]+OFFSET_Z;
		}
	}
}

stock GetMoveDirectionFromKeys(ud, lr)
{
	new direction = 0;

    if(lr < 0)
	{
		if(ud < 0) 		direction = MOVE_FORWARD_LEFT;
		else if(ud > 0) direction = MOVE_BACK_LEFT;
		else            direction = MOVE_LEFT;
	}
	else if(lr > 0)
	{
		if(ud < 0)      direction = MOVE_FORWARD_RIGHT;
		else if(ud > 0) direction = MOVE_BACK_RIGHT;
		else			direction = MOVE_RIGHT;
	}
	else if(ud < 0) 	direction = MOVE_FORWARD;
	else if(ud > 0) 	direction = MOVE_BACK;

	return direction;
}

stock GetNumberOfPlayersOnThisIP(test_ip[])
{
    new against_ip[32+1];
    new ip_count = 0;
    
    foreach(new i : Player)
	{
        GetPlayerIp(i,against_ip,32);
        if(!strcmp(against_ip,test_ip))
			ip_count++;
    }
    return ip_count;
}

stock ReturnUser(tmp[])
{
	new playerid=INVALID_PLAYER_ID;
   	if(strlen(tmp)>=3)
   	{
	    new count;
	    foreach(new i : Player)
	    {
		    if(strfind(GetName(i),tmp,true)!=-1)
		    {
		    	playerid=i;
		    	count++;
		    }
   		}
   		if(count>1)
   			playerid=INVALID_PLAYER_ID;
	}
 	return playerid;
}

forward ShowAdminPanel(playerid);
public ShowAdminPanel(playerid)
{
	new string[700];

	if(PlayerLanguage[playerid] == LANG_DE)
	{
		new field[20] = "Kleines Feld";
		
		if(!UseSmallField)
		    field = "Großes Feld";
	
	    format(string, sizeof(string), "Eventdauer\t\t\t%d Minuten\n\
	    Pausenbeginn ab\t\t%d Minuten\n\
	    Pausendauer\t\t\t%d Minuten\n\
	    Spielfläche\t\t\t%s\n\
	    Whitelist anzeigen\n\
	    Anticheat bei allen Spielern abfragen", TotalMinutes, Pause, PauseDuration, field);
	    
    	ShowPlayerDialog(playerid, DIALOG_CONTROLPANEL, DIALOG_STYLE_LIST, "Admin Control Panel", string, "Aendern", "Schließen");
	}
	else
	{
		new field[20] = "Small field";

		if(!UseSmallField)
		    field = "Big field";

	    format(string, sizeof(string), "Event duration\t\t\t%d minutes\n\
	    Break starts at\t\t\t%d minutes\n\
	    Break duration\t\t\t%d minutes\n\
	    Field size\t\t\t%s\n\
	    Show whitelist\n\
	    Check every players anticheat state", TotalMinutes, Pause, PauseDuration, field);
	    
    	ShowPlayerDialog(playerid, DIALOG_CONTROLPANEL, DIALOG_STYLE_LIST, "Admin Control Panel", string, "Change", "Close");
	}
	return 1;
}

forward AntiSpawnkill(playerid);
public AntiSpawnkill(playerid)
{
    SetPlayerHealth(playerid, 100.0);
    SendLanguageMessage(playerid, COLOR_GREEN, "<$>» Information «<#> Du bist nun nicht mehr vor Spawnkill geschützt.","<$>» Information «<#> Anti-Spawnkill protection over, you are on your own now");
    return 1;
}

forward public OnPlayerDataCheck(playerid, corrupt_check);
public OnPlayerDataCheck(playerid, corrupt_check)
{
	if (corrupt_check != Corrupt_Check[playerid])
		return Kick(playerid);
		
	new string[150];
	if(cache_num_rows() > 0)
	{
		cache_get_value(0, "Passwort", pInfo[playerid][Passwort], 65);
		cache_get_value(0, "SALT", pInfo[playerid][Salt], 11);
		pInfo[playerid][Player_Cache] = cache_save();


		if(PlayerLanguage[playerid] == LANG_DE)
		{
       		format(string, sizeof(string), "{FFFFFF}Willkommen zurück, %s.\n\n{008CDB}Dieser Account ist bereits registriert.\n\
       		{008CDB}Bitte gib dein Passwort ein.\n\n", pInfo[playerid][Name]);

       		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", string, "Login", "Abbrechen");
		}
		else
		{
      		format(string, sizeof(string), "{FFFFFF}Welcome back, %s.\n\n{008CDB}This account is already registered.\n\
      		{008CDB}Please, input your password below to proceed to the game.\n\n", pInfo[playerid][Name]);

       		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login System", string, "Login", "Leave");
		}
	}
	else
	{
		if(PlayerLanguage[playerid] == LANG_DE)
		{
   	    	format(string, sizeof(string), "{FFFFFF}Willkommen, %s.\n\n{008CDB}Du hast noch kein Passwort für deinen Account festgelegt.\n\
   	    	{008CDB}Bitte gib ein Passwort ein.\n\n", pInfo[playerid][Name]);

			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Registrieren", string, "Registrieren", "Abbrechen");
 		}
 		else
 		{
   	    	format(string, sizeof(string), "{FFFFFF}Welcome, %s.\n\n{008CDB}This account is not registered.\n\
   	    	{008CDB}Please, input your password below to proceed.\n\n", pInfo[playerid][Name]);

			ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", string, "Register", "Leave");
	   	}
	}
	return 1;
}


forward public OnPlayerRegister(playerid);
public OnPlayerRegister(playerid)
{
	SendLanguageMessage(playerid, COLOR_GREEN, "<$>» Information «<#> Du hast dich registriert und wurdest automatisch eingeloggt.", "<$>» Information «<#> You are now registered and have been logged in.");
    pInfo[playerid][LoggedIn] = true;
    return 1;
}


stock AddNameToWhitelist(name[])
{
	new DB_Query[225];
   	mysql_format(Database, DB_Query, sizeof(DB_Query), "INSERT INTO `WHITELIST` (`Name`) VALUES ('%s')", name);
    mysql_tquery(Database, DB_Query);
    return 1;
}

stock RemoveNameFromWhitelist(name[])
{
	new DB_Query[225];
   	mysql_format(Database, DB_Query, sizeof(DB_Query), "DELETE FROM `WHITELIST` WHERE `Name` = '%s'", name);
    mysql_tquery(Database, DB_Query);
	return 1;
}

forward AddPlayerToWhitelist(playerid);
public AddPlayerToWhitelist(playerid)
{
	return AddNameToWhitelist(GetName(playerid));
}

stock IsPlayerOnWhitelist(playerid)
{
	new MySQLQuery[128];
 	mysql_format(Database, MySQLQuery, sizeof(MySQLQuery), "SELECT * FROM `WHITELIST` where `Name` = '%s'", GetName(playerid));
	new Cache:result = mysql_query(Database, MySQLQuery);
 	new whitelistcounter = cache_num_rows();
 	
 	print(MySQLQuery);
 	printf("ParticipantsCounter == %d",whitelistcounter);
 	
 	if(whitelistcounter >= 1)
 	{
 		cache_delete(result);
 	    return true;
   	}

 	cache_delete(result);
	return 0;
}

forward SetClickable(playerid);
public SetClickable(playerid)
{
	SelectTextDraw(playerid, 0xA3B4C5FF);
	return 1;
}

stock StartSpectate(playerid, specplayerid)
{
	SetPlayerInterior(playerid,GetPlayerInterior(specplayerid));
	TogglePlayerSpectating(playerid, 1);

	if(IsPlayerInAnyVehicle(specplayerid))
		PlayerSpectateVehicle(playerid, GetPlayerVehicleID(specplayerid));
	else
		PlayerSpectatePlayer(playerid, specplayerid);
		
    IsSpectating[playerid] = 1;
    SpectatingID[playerid] = specplayerid;
    BeingSpectated[SpectatingID[playerid]] = 1;
	return 1;
}

stock KickPlayerEx(playerid, kickedplayerid, reason[])
{
	TogglePlayerControllable(kickedplayerid, 0);

	new string[128],
		string_en[128];
		
	if(playerid == -1)
	{
		format(string, sizeof(string), "<$>» Admin «<#> Der Server hat %s [%d] gekickt! (Grund: %s)", GetName(kickedplayerid), kickedplayerid, reason);
		format(string_en, sizeof(string_en), "<$>» Admin «<#> The server has kicked %s [%d]! (Reason: %s)", GetName(kickedplayerid), kickedplayerid, reason);
	}
	else
	{
		format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s [%d] gekickt! (Grund: %s)", GetName(playerid), playerid, GetName(kickedplayerid), kickedplayerid, reason);
		format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has kicked %s [%d]! (Reason: %s)", GetName(playerid), playerid, GetName(kickedplayerid), kickedplayerid, reason);
	}
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

	KickTimer[kickedplayerid] = SetTimerEx("KickPlayer", 300, 0, "d", kickedplayerid);
	return 1;
}

forward KickPlayer(playerid);
public KickPlayer(playerid)
{
	Kick(playerid);
	return 1;
}

stock BanPlayerEx(playerid, kickedplayerid, reason[])
{
	TogglePlayerControllable(kickedplayerid, 0);

	new string[128],
		string_en[128];

	if(playerid == -1)
	{
		format(string, sizeof(string), "<$>» Admin «<#> Der Server hat %s [%d] gebannt! (Grund: %s)", GetName(kickedplayerid), kickedplayerid, reason);
		format(string_en, sizeof(string_en), "<$>» Admin «<#> The server has banned %s [%d]! (Reason: %s)", GetName(kickedplayerid), kickedplayerid, reason);
	}
	else
	{
		format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s [%d] gebannt! (Grund: %s)", GetName(playerid), playerid, GetName(kickedplayerid), kickedplayerid, reason);
		format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has banned %s [%d]! (Reason: %s)", GetName(playerid), playerid, GetName(kickedplayerid), kickedplayerid, reason);
	}
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
	
	BanTimer[kickedplayerid] = SetTimerEx("BanPlayer", 300, 0, "d", kickedplayerid);
	return 1;
}

forward BanPlayer(playerid);
public BanPlayer(playerid)
{
	Ban(playerid);
	return 1;
}

stock CreatePlayerTextDraws(playerid)
{
	FPS = CreatePlayerTextDraw(playerid, 586.000000,1.000000, "~y~FPS: 101");
	PlayerTextDrawBackgroundColor(playerid, FPS, 255);
	PlayerTextDrawFont(playerid, FPS, 2);
	PlayerTextDrawLetterSize(playerid, FPS, 0.299999,1.900000);
	PlayerTextDrawColor(playerid, FPS, -1);
	PlayerTextDrawSetOutline(playerid, FPS, 1);
	PlayerTextDrawSetProportional(playerid, FPS, 1);
	PlayerTextDrawSetShadow(playerid, FPS, 1);

	DoingDamage[0] = CreatePlayerTextDraw(playerid,170.0,362.0 + 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[0], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[0], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[0],255);
	PlayerTextDrawColor(playerid, DoingDamage[0], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[0], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[0],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[0],0);

	DoingDamage[1] = CreatePlayerTextDraw(playerid,170.0,372.0+ 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[1], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[1], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[1],255);
	PlayerTextDrawColor(playerid, DoingDamage[1], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[1], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[1],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[1],0);

	DoingDamage[2] = CreatePlayerTextDraw(playerid,170.0,382.0+ 10,"_");
	PlayerTextDrawFont(playerid, DoingDamage[2], 1);
	PlayerTextDrawLetterSize(playerid, DoingDamage[2], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, DoingDamage[2],255);
	PlayerTextDrawColor(playerid, DoingDamage[2], 16727295);
	PlayerTextDrawSetProportional(playerid, DoingDamage[2], 1);
	PlayerTextDrawSetOutline(playerid, DoingDamage[2],1);
    PlayerTextDrawSetShadow(playerid, DoingDamage[2],0);

	GettingDamaged[0] = CreatePlayerTextDraw(playerid,380.0,362.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[0], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[0], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[0],255);
	PlayerTextDrawColor(playerid, GettingDamaged[0], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[0], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[0],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[0],0);

	GettingDamaged[1] = CreatePlayerTextDraw(playerid,380.0,372.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[1], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[1], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[1],255);
	PlayerTextDrawColor(playerid, GettingDamaged[1], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[1], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[1],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[1],0);

	GettingDamaged[2] = CreatePlayerTextDraw(playerid,380.0,382.0+ 10,"_");
	PlayerTextDrawFont(playerid, GettingDamaged[2], 1);
	PlayerTextDrawLetterSize(playerid, GettingDamaged[2], 0.18000, 0.9);
	PlayerTextDrawBackgroundColor(playerid, GettingDamaged[2],255);
	PlayerTextDrawColor(playerid, GettingDamaged[2], 16727295);
	PlayerTextDrawSetProportional(playerid, GettingDamaged[2], 1);
	PlayerTextDrawSetOutline(playerid, GettingDamaged[2],1);
	PlayerTextDrawSetShadow(playerid, GettingDamaged[2],0);
	
	BottomBar = CreatePlayerTextDraw(playerid, 0.000000,331.000000,"~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	PlayerTextDrawUseBox(playerid, BottomBar,1);
	PlayerTextDrawBoxColor(playerid, BottomBar,255);
	PlayerTextDrawTextSize(playerid, BottomBar,750.000000,0.000000);
	PlayerTextDrawAlignment(playerid, BottomBar,0);
	PlayerTextDrawBackgroundColor(playerid, BottomBar,0x000000ff);
	PlayerTextDrawFont(playerid, BottomBar,0);
	PlayerTextDrawLetterSize(playerid, BottomBar,1.000000,1.000000);
	PlayerTextDrawColor(playerid, BottomBar,0xffffffff);
	PlayerTextDrawSetOutline(playerid, BottomBar,1);
	PlayerTextDrawSetProportional(playerid, BottomBar,1);
	PlayerTextDrawSetShadow(playerid, BottomBar,1);
	
	TopBar = CreatePlayerTextDraw(playerid, 0.000000,0.000000,"~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~~n~");
	PlayerTextDrawUseBox(playerid, TopBar,1);
	PlayerTextDrawBoxColor(playerid, TopBar,255);
	PlayerTextDrawTextSize(playerid, TopBar,700.000000,0.000000);
	PlayerTextDrawAlignment(playerid, TopBar,0);
	PlayerTextDrawBackgroundColor(playerid, TopBar,0x000000ff);
	PlayerTextDrawFont(playerid, TopBar,0);
	PlayerTextDrawColor(playerid, TopBar,0xffffffff);
	PlayerTextDrawLetterSize(playerid, TopBar,1.000000,1.000000);
	PlayerTextDrawSetOutline(playerid, TopBar,1);
	PlayerTextDrawSetProportional(playerid, TopBar,1);
	PlayerTextDrawSetShadow(playerid, TopBar,1);
	
	CountDown = CreatePlayerTextDraw(playerid, 621.000000,421.000000,"_");
	PlayerTextDrawAlignment(playerid, CountDown,3);
	PlayerTextDrawBackgroundColor(playerid, CountDown,0xffffffff);
	PlayerTextDrawFont(playerid, CountDown,2);
	PlayerTextDrawLetterSize(playerid, CountDown,0.299999,1.500000);
	PlayerTextDrawColor(playerid, CountDown,0x000000ff);
	PlayerTextDrawSetOutline(playerid, CountDown,1);
	PlayerTextDrawSetProportional(playerid, CountDown,1);
	PlayerTextDrawSetShadow(playerid, CountDown,1);

	EventInfo = CreatePlayerTextDraw(playerid, 630.000000,430.000000,"_");
	PlayerTextDrawAlignment(playerid, EventInfo,3);
	PlayerTextDrawBackgroundColor(playerid, EventInfo,0x000000ff);
	PlayerTextDrawFont(playerid, EventInfo,1);
	PlayerTextDrawLetterSize(playerid, EventInfo,0.299999,1.400000);
	PlayerTextDrawColor(playerid, EventInfo,0xffffffff);
	PlayerTextDrawSetProportional(playerid, EventInfo,1);
	PlayerTextDrawSetShadow(playerid, EventInfo,1);

	Statistics = CreatePlayerTextDraw(playerid, 4.000000,395.000000,"_");
	PlayerTextDrawAlignment(playerid, Statistics,0);
	PlayerTextDrawBackgroundColor(playerid, Statistics,0x000000ff);
	PlayerTextDrawFont(playerid, Statistics,1);
	PlayerTextDrawLetterSize(playerid, Statistics,0.199999,0.799999);
	PlayerTextDrawColor(playerid, Statistics,0xffffffff);
	PlayerTextDrawSetOutline(playerid, Statistics,1);
	PlayerTextDrawSetProportional(playerid, Statistics,1);
	PlayerTextDrawSetShadow(playerid, Statistics,1);

	Map = CreatePlayerTextDraw(playerid, 121.000000,121.000000, "samaps:gtasamapbit2");
    PlayerTextDrawFont(playerid, Map, 4);
	PlayerTextDrawColor(playerid, Map, 0xFFFFFFFF);
    PlayerTextDrawTextSize(playerid, Map, 150.0, 150.0);
	PlayerTextDrawSetSelectable(playerid, Map, true);
	
	MapBox = CreatePlayerTextDraw(playerid, 240.000000,155.000000,"~n~~n~~n~~n~~n~~n~~n~~n~");
	PlayerTextDrawUseBox(playerid, MapBox,1);
	PlayerTextDrawBoxColor(playerid, MapBox, COLOR_FIGHTZONE);
	PlayerTextDrawTextSize(playerid, MapBox,214.000000,0.000000);
	PlayerTextDrawAlignment(playerid, MapBox,0);
	PlayerTextDrawBackgroundColor(playerid, MapBox,0x000000ff);
	PlayerTextDrawFont(playerid, MapBox,1);
	PlayerTextDrawLetterSize(playerid, MapBox,1.000000,1.000000);
	PlayerTextDrawColor(playerid, MapBox,0xffffffff);
	PlayerTextDrawSetOutline(playerid, MapBox,1);
	PlayerTextDrawSetProportional(playerid, MapBox,1);
	PlayerTextDrawSetShadow(playerid, MapBox,1);

	Map2 = CreatePlayerTextDraw(playerid, 341.000000,121.000000, "samaps:gtasamapbit2");
    PlayerTextDrawFont(playerid, Map2, 4);
	PlayerTextDrawColor(playerid, Map2, 0xFFFFFFFF);
    PlayerTextDrawTextSize(playerid, Map2, 150.0, 150.0);
	PlayerTextDrawSetSelectable(playerid, Map2, true);

	Map2Box = CreatePlayerTextDraw(playerid, 460.000000,182.000000,"~n~~n~~n~~n~~n~");
	PlayerTextDrawUseBox(playerid, Map2Box,1);
	PlayerTextDrawBoxColor(playerid, Map2Box, COLOR_FIGHTZONE);
	PlayerTextDrawTextSize(playerid, Map2Box,434.000000,0.000000);
	PlayerTextDrawAlignment(playerid, Map2Box,0);
	PlayerTextDrawBackgroundColor(playerid, Map2Box,0x000000ff);
	PlayerTextDrawFont(playerid, Map2Box,1);
	PlayerTextDrawLetterSize(playerid, Map2Box,1.000000,1.000000);
	PlayerTextDrawColor(playerid, Map2Box,0xffffffff);
	PlayerTextDrawSetOutline(playerid, Map2Box,1);
	PlayerTextDrawSetProportional(playerid, Map2Box,1);
	PlayerTextDrawSetShadow(playerid, Map2Box,1);
	return 1;
}

// Formattierungskram
stock StripNewLineEx(string[])
{
	new len = strlen(string);
	if (string[0]==0) return ;
	if ((string[len - 1] == '\n') || (string[len - 1] == '\r')) {
		string[len - 1] = 0;
		if (string[0]==0) return ;
		if ((string[len - 2] == '\n') || (string[len - 2] == '\r')) string[len - 2] = 0;
	}
}

stock ModifyMessageColor(const src[], color, dest[], const len = sizeof dest, invcolor = 0)
{
	new
		pos,
		rgba[4 char],
		invcolorstr[16],
		colorstr[16],
		darkcolorstr[16];

	rgba[0] = color;

	#define __modify(%0) \
		%0 = (%0 << 1) / 3
		//%0 = (3 * (%0)) >> 2

	__modify(rgba{0});
	__modify(rgba{1});
	__modify(rgba{2});
	__modify(rgba{2});

	#undef __modify

	if (invcolor == 0)
		invcolor = ~color;

	format(colorstr, sizeof colorstr, "{%06x}", color >>> 8);
	format(invcolorstr, sizeof invcolorstr, "{%06x}", rgba[0] >>> 8);
	format(darkcolorstr, sizeof darkcolorstr, "{%06x}", rgba[0] >>> 8);

	//strcpy(dest, src, len);
	format(dest, 140, src);

	pos = 0;
	while ((pos = strfind(dest, "<$>", .pos = pos)) != -1)
	{
		strdel(dest, pos, pos + 3);
		strins(dest, darkcolorstr, pos, 140);
	}

	pos = 0;
	while ((pos = strfind(dest, "<#>", .pos = pos)) != -1)
	{
		strdel(dest, pos, pos + 3);
		strins(dest, colorstr, pos, 140);
	}

	pos = 0;
	while ((pos = strfind(dest, "\"/", .pos = pos)) != -1)
	{
		strdel(dest, pos, pos + 1);
		strins(dest, invcolorstr, pos, 140);
		if ((pos = strfind(dest, "\"", .pos = pos)) != -1)
		{
			strdel(dest, pos, pos + 1);
			strins(dest, colorstr, pos, 140);
		}
		else
			break;
	}

	pos = 0;
	while ((pos = strfind(dest, "(/", .pos = pos)) != -1)
	{
		strins(dest, invcolorstr, pos + 1, 140);
		if ((pos = strfind(dest, ")", .pos = pos)) != -1)
			strins(dest, colorstr, pos, 140);
		else
			break;
	}
	#pragma unused len
}

// Commands
CMD:help(playerid, params[])
{
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	SendLanguageMessage(playerid, -1, "Alle Commands:","All commands:");
	SendLanguageMessage(playerid, -1, "/Help, /Sprache, /Credits, /Spec (off), /Freecam (off), /PM, /Sync, /Report, /Hitsound, /Piss","/Help, /Language, /Credits, /Spec (off), /Freecam (off), /PM, /Sync, /Report, /Hitsound, /Piss");
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	return 1;
}

CMD:flash(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	 	return SendClientMessage(playerid, COLOR_RED, "flash du spast, mach hier wenigstens ne abfrage rein ob admin");
	 	
	for (new j = 0; j < 40; j++)
    {
		pInfo[playerid][Points]++;
		SendClientMessage(playerid, COLOR_RED, "Punkt gewonnen!");
		SetPlayerScore(playerid, pInfo[playerid][Points]);
		SavePlayer(playerid);
		UpdateTopList();
	}
	return 1;
}

CMD:lockchat(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	new string[128], string_en[128];

	format(string,sizeof(string), "<$>» Admin «<#> %s hat den Chat gesperrt!", GetName(playerid));
	format(string_en,sizeof(string_en), "<$>» Admin «<#> %s has locked the chat!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

	IsChatLocked = 1;
	return 1;
}

CMD:unlockchat(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	new string[128], string_en[128];

	format(string,sizeof(string), "<$>» Admin «<#> %s hat den Chat entsperrt!", GetName(playerid));
	format(string_en,sizeof(string_en), "<$>» Admin «<#> %s has unlocked the chat!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

	IsChatLocked = 0;
	return 1;
}

CMD:acmds(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	    
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	SendLanguageMessage(playerid, -1, "Alle Admin Commands:","All admin commands:");
	SendLanguageMessage(playerid, -1, "/Spec, /Freecam, /Kick, /Ban, /Mute, /Unmute, /Get, /Goto","/Spec, /Freecam, /Kick, /Ban, /Mute, /Unmute, /Get, /Goto");
	SendLanguageMessage(playerid, -1, "/Add, /Remove, /Gametext, /Heal, /HealAll, /IP, /ACP","/Add, /Remove, /Gametext, /Heal, /HealAll, /IP, /ACP");
	SendLanguageMessage(playerid, -1, "/Start, /Pause, /Continue, /Lockchat, /Unlockchat, /FPS","/Start, /Pause, /Continue, /Lockchat, /Unlockchat, /FPS");
	SendLanguageMessage(playerid, -1, "#text für Adminchat!","#text for admin chat!");
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	return 1;
}

CMD:language(playerid, params[])
{
	ShowPlayerDialog(playerid, DIALOG_LANGUAGE, DIALOG_STYLE_MSGBOX, "{32a852}Sprache/Language",
		"{FFFFFF}Please select your {32a852}language{FFFFFF}.\nBitte waehle deine {32a852}Sprache {FFFFFF}aus.",
		"Deutsch","English");
	return 1;
}

CMD:piss(playerid, params[])
{
	if(!IsPlayerAdmin(playerid) && pInfo[playerid][PMODE] == 1)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist Teilnehmer des Events und kannst daher nicht pissen!","<$>» Warning «<#> You are participant of the event. You can't piss!");
		
	SetPlayerSpecialAction(playerid, 68);
	return 1;
}

CMD:hitsound(playerid, params[])
{
	if(Hitsound[playerid])
	{
	    Hitsound[playerid] = 0;
	    SendLanguageMessage(playerid, COLOR_GREEN, "<$>» Information «<#> Hitsound deaktiviert.","<$>» Information «<#> Hitsound deactivated.");
	}
	else
	{
	    Hitsound[playerid] = 1;
	    SendLanguageMessage(playerid, COLOR_GREEN, "<$>» Information «<#> Hitsound aktiviert.","<$>» Information «<#> Hitsound activated.");
	}
	return 1;
}

CMD:credits(playerid, params[])
{
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	SendLanguageMessage(playerid, -1, "Der Gamemode wurde von {008CDB}[USL]DarkZero{FFFFFF} geschrieben.","The gamemode was written by {008CDB}DarkZero{FFFFFF}.");
	SendLanguageMessage(playerid, -1, "Dazu die {008CDB}Unterstützung{FFFFFF} von [USL]Flash, [AMB]Macronix, [AMB]TightBanger, [AMB]haubitze und [USL]N1ght.","With {008CDB}help{FFFFFF} by [USL]Flash, [AMB]Macronix, [AMB]TightBanger, [AMB]haubitze and [USL]N1ght.");
	SendLanguageMessage(playerid, -1, "Tests und Ideen: [USL]Flash, [USL]N1ght, [AMB]TightBanger, [AMB]Macronix, [AMB]Im2good4you, [AMB]haubitze","Testing and ideas: [USL]Flash, [USL]N1ght, [AMB]TightBanger, [AMB]Macronix, [AMB]Im2good4you, [AMB]haubitze");
	SendLanguageMessage(playerid, -1, "Maps: [AMB]haubitze","Maps: [AMB]haubitze");
	SendLanguageMessage(playerid, -1, "Das Event wurde {008CDB}organisiert{FFFFFF} von [USL] und [AMB]","This event was {008CDB}organized{FFFFFF} by [USL] and [AMB]");
	SendLanguageMessage(playerid, -1, "[USL]: {8c0000}USLClan.de{FFFFFF} - [AMB]: {7b00c2}AMBizz.de","[USL]: {8c0000}USLClan.de{FFFFFF} - [AMB]: {7b00c2}AMBizz.de");
	SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	return 1;
}

CMD:sprache(playerid, params[])
{
	return cmd_language(playerid, params);
}

CMD:spec(playerid, params[])
{
	new giveplayerid;

	if(!IsPlayerAdmin(playerid) && pInfo[playerid][PMODE] == 1)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist Teilnehmer des Events und kannst daher nicht die Freecam nutzen!","<$>» Warning «<#> You are participant of the event. You can't use the freecam!");
		
    if(IsUsingFreeCam[playerid])
    {
        TogglePlayerSpectating(playerid, 0);
		DestroyPlayerObject(playerid, FreeCam[playerid][flyobject]);
		FreeCam[playerid][cameramode] = CAMERA_MODE_NONE;
		IsUsingFreeCam[playerid] = 0;
	}
    
    if(strfind(params, "off", true) != -1)
    {
        if(GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
        {
            TogglePlayerSpectating(playerid, 0);
            IsSpectating[playerid] = 0;
            BeingSpectated[SpectatingID[playerid]] = 65535;
            //SpawnPlayer(playerid);
		}
		else
	    	return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du spectatest zur Zeit niemanden!","<$>» Warning «<#> You are not spectating anyone!");
	}
		
	if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /Spec [Name/ID]/off","<$>» Warning «<#> /Spec [Name/ID]/off");

	if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
	{
		if(giveplayerid == playerid)
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du kannst dich nicht selbst spectaten.","<$>» Warning «<#> You can't spectate yourself.");

		if(GetPlayerState(giveplayerid) == PLAYER_STATE_SPECTATING)
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler spectatet bereits jemanden.","<$>» Warning «<#> This player is spectating someone already.");

		if(GetPlayerState(giveplayerid) != 1 && GetPlayerState(giveplayerid) != 2 && GetPlayerState(giveplayerid) != 3)
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist noch nicht gespawned.","<$>» Warning «<#> This player isn't spawned yet.");

		StartSpectate(playerid, giveplayerid);
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	return 1;
}

CMD:freecam(playerid, params[])
{
	if(!IsPlayerAdmin(playerid) && pInfo[playerid][PMODE] == 1)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist Teilnehmer des Events und kannst daher nicht die Freecam nutzen!","<$>» Warning «<#> You are participant of the event. You can't use the freecam!");
	
	if(IsSpectating[playerid] != 65535)
	{
		TogglePlayerSpectating(playerid, 0);
        IsSpectating[playerid] = 0;
        BeingSpectated[SpectatingID[playerid]] = 65535;
	}
	
 	if(strfind(params, "off", true) != -1)
    {
        if(IsUsingFreeCam[playerid])
        {
            TogglePlayerSpectating(playerid, 0);
			DestroyPlayerObject(playerid, FreeCam[playerid][flyobject]);
			FreeCam[playerid][cameramode] = CAMERA_MODE_NONE;
			IsUsingFreeCam[playerid] = 0;
		}
		else
	    	return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du benutzt die Freecam zur Zeit nicht!","<$>» Warning «<#> You are not using the freecam!");
	}
	else
	{
		SetPlayerInterior(playerid, 0);
		FreeCam[playerid][flyobject] = CreatePlayerObject(playerid, 19300, 2058.855224, 865.582397, 44.418315, 0.0, 0.0, 0.0);
		TogglePlayerSpectating(playerid, 1);
		IsUsingFreeCam[playerid] = 1;
		AttachCameraToPlayerObject(playerid, FreeCam[playerid][flyobject]);
		FreeCam[playerid][cameramode] = CAMERA_MODE_FLY;
		
		SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
		SendLanguageMessage(playerid, -1, "Freecam:","Freecam:");
		SendLanguageMessage(playerid, -1, "Benutze WASD um die Kamera zu steuern.","Use WASD to move the camera.");
		SendLanguageMessage(playerid, -1, "Um schneller zu fahren, halte die Sprungtaste gedrückt.","To move faster, hold the jump key.");
		SendLanguageMessage(playerid, -1, "Mit \"/Freecam off\" kannst du wieder ins Spiel zurückkehren.","Use \"/Freecam off\" to get back into the game.");
		SendClientMessage(playerid, COLOR_BLUE, "==========================================================");
	}
	return 1;
}

CMD:getnetstats(playerid, params[])
{
	new stats[400+1];
    GetNetworkStats(stats, sizeof(stats));
    ShowPlayerDialog(playerid, DIALOG_NETSTATS, DIALOG_STYLE_MSGBOX, "Server Network Stats", stats, "Close", "");
	return 1;
}

CMD:getplayernetstats(playerid, params[])
{
    new stats[400+1];
    GetPlayerNetworkStats(playerid, stats, sizeof(stats)); 
    ShowPlayerDialog(playerid, DIALOG_PLAYERNETSTATS, DIALOG_STYLE_MSGBOX, "My NetworkStats", stats, "Close", "");
	return 1;
}

CMD:sync(playerid)
{
	if(!IsStarted)
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Das geht jetzt noch nicht!","<$>» Warning «<#> You can not use this command now!");

	if(IsPlayerInAnyVehicle(playerid))
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du darfst diesen Command nicht in einem Auto verwenden!","<$>» Warning «<#> You are not allowed to use this command in a vehicle!");
	    
	if(IsSynced[playerid])
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du darfst diesen Command nur alle 20 Sekunden verwenden!","<$>» Warning «<#> You need to wait at least 20 seconds to use this command again!");

	GetPlayerPos(playerid, SyncCoords[playerid][0], SyncCoords[playerid][1], SyncCoords[playerid][2]);
	Sync[playerid] = 1;

    SetTimerEx("ResetSync", 20000, 0, "d", playerid);
    IsSynced[playerid] = 1;

	PlayerPlaySound(playerid,1085,0.0,0.0,0.0);
	SpawnPlayer(playerid);
	SendLanguageMessage(playerid,COLOR_GREEN,"<$>» Information «<#> Du wurdest synchronisiert!","<$>» Information «<#> Sync succeeded!");
	return 1;
}

forward ResetSync(playerid);
public ResetSync(playerid)
{
	IsSynced[playerid] = 0;
	return 1;
}

CMD:pm(playerid,params[])
{
	new gMessage[128],
		giveplayerid;

	if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>us[128]",giveplayerid,gMessage))
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /PM [Name/ID] [Nachricht]","<$>» Warning «<#> /PM [Name/ID] [Message]");

	if(!IsPlayerConnected(giveplayerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");

	if(playerid != giveplayerid)
	{
	    new string[128], string_en[128];

		if(IsMuted[playerid] == 1)
		{
		    SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du wurdest gemuted!","<$>» Warning «<#> You are muted!");
		    return 0;
		}

	    if(IsMuted[playerid] == 2)
		{
		    format(string, sizeof(string), "<$>» Warnung «<#> Du bist noch für %02d:%02d Minuten gemuted!", MuteMinutes[playerid], MuteSeconds[playerid]);
	    	format(string_en,sizeof(string_en),"<$>» Warning «<#> You are muted for %02d:%02d minutes!", MuteMinutes[playerid],MuteSeconds[playerid]);
	    	SendLanguageMessage(playerid, COLOR_RED, string, string_en);
	    	return 0;
		}

		format(string, sizeof(string), "<$>» PM «<#> Private Nachricht von %s: %s", GetName(playerid), gMessage);
		format(string_en, sizeof(string_en), "<$>» PM «<#> Private message by %s: %s", GetName(playerid), gMessage);
		SendLanguageMessage(giveplayerid, COLOR_LIGHTBLUE, string, string_en);

		format(string, sizeof(string), "<$>» PM «<#> Private Nachricht an %s: %s", GetName(giveplayerid), gMessage);
		format(string_en, sizeof(string_en), "<$>» PM «<#> Private message to %s: %s", GetName(giveplayerid), gMessage);
		SendLanguageMessage(playerid, COLOR_LIGHTBLUE, string, string_en);

		format(string, sizeof(string), "<$>» PM «<#> Private Nachricht von %s an %s: %s", GetName(playerid), GetName(giveplayerid), gMessage);
		format(string_en, sizeof(string_en), "<$>» PM «<#> Private message from %s to %s: %s", GetName(playerid), GetName(giveplayerid), gMessage);
		SendClientMessageToAdmins(COLOR_ADMIN, string, string_en);

		PlayerPlaySound(giveplayerid,1085,0.0,0.0,0.0);

		SpamCounter[playerid]++;
		SetTimerEx("ResetSpam", 3000, 0, "d", playerid);
		if(SpamCounter[playerid] > 4)
		{
			MutePlayer(playerid, 3);
			format(string, sizeof(string), "<$>» Admin «<#> %s wurde wegen PM Spam für 3 Minuten gemuted!", GetName(playerid));
			format(string_en,sizeof(string_en),"<$>» Admin «<#> %s was muted for PM spamming for 3 minutes!",GetName(playerid));
			SendLanguageMessageToAll(COLOR_ADMIN,string,string_en);
			return 1;
		}
	}
	else
    	return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du kannst dir selbst keine PM schicken!","<$>» Warning «<#> You can not send a private message to yourself!");

	return 1;
}

CMD:report(playerid,params[])
{
	new gMessage[128],
		giveplayerid;

	if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>us[128]",giveplayerid,gMessage))
	    return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /Report [Name/ID] [Grund]","<$>» Warning «<#> /Report [Name/ID] [Reason]");

	if(!IsPlayerConnected(giveplayerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");

	if(playerid != giveplayerid)
	{
	    new string[128], string_en[128];

		format(string, sizeof(string), "<$>» REPORT «<#> %s meldet %s! Grund: %s", GetName(playerid), GetName(giveplayerid), gMessage);
		format(string_en, sizeof(string_en), "<$>» REPORT «<#> %s has reported %s! Reason: %s", GetName(playerid), GetName(giveplayerid), gMessage);
		SendClientMessageToAdmins(COLOR_RED, string, string_en);

		format(string, sizeof(string), "Dein Report über %s wurde versendet. Vielen Dank!", GetName(giveplayerid));
		format(string_en, sizeof(string_en), "Your report about %s has been sent to the admins. Thank you!", GetName(giveplayerid));
		SendLanguageMessage(playerid, COLOR_GREEN, string, string_en);
	}
	else
    	return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> Du kannst dich nicht selbst reporten!","<$>» Warning «<#> You can not report yourself!");

	return 1;
}

// Admin Commands
CMD:goto(playerid, params[])
{
	new giveplayerid,
		string[128],
		string_en[128];

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Goto [Name/ID]","<$>» Warning «<#> /Goto [Name/ID]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    new Float:x, Float:y, Float:z, Float:a;
		    GetPlayerPos(giveplayerid, x,y,z);
		    GetPlayerFacingAngle(giveplayerid, a);
			SetPlayerPos(playerid,x,y+5,z);
			SetPlayerFacingAngle(playerid, a);

			format(string,sizeof(string), "<$>» Admin «<#> %s hat sich zu %s teleportiert!", GetName(playerid), GetName(giveplayerid));
			format(string_en,sizeof(string_en), "<$>» Admin «<#> %s has teleported himself to %s!", GetName(playerid), GetName(giveplayerid));
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
		}
		else
		    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	return 1;
}

CMD:get(playerid, params[])
{
	new giveplayerid,
		string[128],
		string_en[128];

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Get [Name/ID]","<$>» Warning «<#> /Get [Name/ID]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    new Float:x, Float:y, Float:z, Float:a;
		    GetPlayerPos(playerid, x,y,z);
		    GetPlayerFacingAngle(playerid, a);
			SetPlayerPos(giveplayerid,x,y+5,z);
			SetPlayerFacingAngle(giveplayerid, a);

			format(string,sizeof(string), "<$>» Admin «<#> %s hat %s zu sich teleportiert!", GetName(playerid), GetName(giveplayerid));
			format(string_en,sizeof(string_en), "<$>» Admin «<#> %s has teleported %s to himself!", GetName(playerid), GetName(giveplayerid));
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
		}
		else
		    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	return 1;
}

CMD:settime(playerid, params[])
{
	new time;
		
    if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

    if(sscanf(params,"i",time))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Settime [0-23]","<$>» Warning «<#> /Settime [0-23]");

    SetWorldTime(time);
	return 1;
}

CMD:respawn(playerid, params[])
{
	new giveplayerid,
		string[128],
		string_en[128];

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Respawn [Name/ID]","<$>» Warning «<#> /Respawn [Name/ID]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    SpawnPlayer(giveplayerid);

			format(string,sizeof(string), "<$>» Admin «<#> %s hat %s respawned!", GetName(playerid), GetName(giveplayerid));
			format(string_en,sizeof(string_en), "<$>» Admin «<#> %s has respawned %s!", GetName(playerid), GetName(giveplayerid));
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
		}
		else
		    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	return 1;
}

CMD:fps(playerid, params[])
{
	new giveplayerid,
		string[128];

	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /FPS [Name/ID]","<$>» Warning «<#> /FPS [Name/ID]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    new frames = CurrentFrames[giveplayerid]-1;
		    new color[10];
		    
			if(frames < MIN_FPS)
			    color = "{FF0000}";
			else if(frames == MIN_FPS || frames < 40)
			    color = "{FBFF00}";
			else
			    color = "{00FF00}";
			    
			format(string, sizeof(string),"*** %s: %s%d {FFFFFF}FPS", GetName(giveplayerid), color, CurrentFrames[giveplayerid]-1);
			SendClientMessage(playerid, -1, string);
		}
		else
		    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	return 1;
}

CMD:acp(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	
	ShowAdminPanel(playerid);
	return 1;
}

CMD:mute(playerid,params[])
{
	if(IsPlayerAdmin(playerid))
	{
   		new giveplayerid, string[128], string_en[128], reason[128], minuten;

	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>uis[128]",giveplayerid, minuten, reason))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Mute [Name/ID] [Minuten] [Grund]","<$>» Warning «<#> /Mute [Name/ID] [Minutes] [Reason]");
		   	
		if (giveplayerid == INVALID_PLAYER_ID || !IsPlayerConnected(giveplayerid))
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");

		if (giveplayerid == playerid)
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du kannst dich nicht selbst muten.","<$>» Warning «<#> You can't mute yourself.");
			
		if (IsMuted[giveplayerid] >= 1)
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist bereits gemuted!","<$>» Warning «<#> This player is already muted!");
			
  		if(minuten > 10 || minuten <= 0)
		  	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Die Zeit muss zwischen 1 und 10 Minuten sein!","<$>» Warning «<#> You must set a time between 1 and 10 minutes.");

	    format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s [%d] für %d Minuten gemuted! (Grund: %s)", GetName(playerid), playerid, GetName(giveplayerid), giveplayerid, minuten, reason);
	    format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has muted %s [%d] for %d minutes! (Reason: %s)", GetName(playerid), playerid, GetName(giveplayerid), giveplayerid, minuten, reason);
		SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);

		MutePlayer(giveplayerid, minuten);
		return 1;
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
}

CMD:unmute(playerid,params[])
{
	new string[128],
		string_en[128],
		giveplayerid;
	    
	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Unmute [Name/ID]","<$>» Warning «<#> /Unmute [Name/ID]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    if(!IsMuted[giveplayerid])
				return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht gemuted!","<$>» Warning «<#> This player is not muted!");
				
			IsMuted[playerid] = 0;
			
		    format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s [%d] entmuted!", GetName(playerid), playerid, GetName(giveplayerid), giveplayerid);
		    format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has unmuted %s [%d]!", GetName(playerid), playerid, GetName(giveplayerid), giveplayerid);
			SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
			
			KillTimer(MuteTimer[giveplayerid]);
		}
		else
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
	return 1;
}

CMD:add(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	new name[24], string[128], string_en[128];

	if(sscanf(params,"s[24]",name))
		return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /Add [VOLLSTÄNDIGER Spielername]","<$>» Warning «<#> /Add [COMPLETE Playername]");


	format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s als Teilnehmer hinzugefügt.",GetName(playerid) ,playerid, name);
	format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has set %s as a participant.",GetName(playerid), playerid, name);
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
	AddNameToWhitelist(name);

	new giveplayerid = ReturnUser(name);
	if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
	{
		pInfo[giveplayerid][PMODE] = 1;
		SpawnPlayer(giveplayerid);
	}
	return 1;
}

CMD:remove(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	new name[24], string[128], string_en[128];

	if(sscanf(params,"s[24]",name))
		return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /Remove [VOLLSTÄNDIGER Spielername]","<$>» Warning «<#> /Remove [COMPLETE Playername]");

	format(string, sizeof(string), "<$>» Admin «<#> Admin %s [%d] hat %s als Teilnehmer entfernt.",GetName(playerid) ,playerid, name);
	format(string_en, sizeof(string_en), "<$>» Admin «<#> Admin %s [%d] has removed %s as a participant.",GetName(playerid), playerid, name);
	SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
	RemoveNameFromWhitelist(name);

	new giveplayerid = ReturnUser(name);
	if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
	{
		pInfo[giveplayerid][PMODE] = 0;
		SpawnPlayer(giveplayerid);
	}
	return 1;
}

CMD:gametext(playerid, params[])
{
	new string[128];
	if(IsPlayerAdmin(playerid))
	{
	    if(sscanf(params,"s[128]",string))
			return SendLanguageMessage(playerid,COLOR_RED,"<$>» Warnung «<#> /Gametext [Text]","<$>» Warning «<#> /Gametext [Text]");
			
		format(string,sizeof(string), "~b~%s", string);
		GameTextForAll(string,5000,3);
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:kick(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
		new giveplayerid, reason[128];
		
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>us[128]",giveplayerid, reason))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Kick [Name/ID] [Grund]","<$>» Warning «<#> /Kick [Name/ID] [Reason]");
		   	
		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
			KickPlayerEx(playerid, giveplayerid, reason);
		else
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:ban(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
		new giveplayerid, reason[128];
		
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>us[128]",giveplayerid, reason))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Ban [Name/ID] [Grund]","<$>» Warning «<#> /Ban [Name/ID] [Reason]");

		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
			BanPlayerEx(playerid, giveplayerid, reason);
		else
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:heal(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
	    new string[128],
			string_en[128],
			giveplayerid;
			
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /Heal [Name/ID]","<$>» Warning «<#> /Heal [Name/ID]");
		   	
		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    SetPlayerHealth(giveplayerid, 100.0);

		    format(string,sizeof(string), "<$>» Admin «<#> Du hast %s geheilt!", GetName(giveplayerid));
		    format(string_en,sizeof(string_en), "<$>» Admin «<#> You healed %s!", GetName(giveplayerid));
		    SendLanguageMessage(playerid, COLOR_ADMIN, string, string_en);

		    format(string,sizeof(string), "<$>» Admin «<#> Admin %s hat dich geheilt!", GetName(playerid));
		    format(string_en,sizeof(string_en), "<$>» Admin «<#> Admin %s has healed you!", GetName(playerid));
		    SendLanguageMessage(giveplayerid, COLOR_ADMIN, string, string_en);
		}
		else
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:healall(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
	    new string[128],
			string_en[128];
			
	    foreach(new i : Player)
			SetPlayerHealth(i, 100.0);

		format(string,sizeof(string), "<$>» Admin «<#> Admin %s hat alle Spieler geheilt!", GetName(playerid));
		format(string_en,sizeof(string_en), "<$>» Admin «<#> Admin %s has healed every player!", GetName(playerid));
		SendLanguageMessageToAll(COLOR_ADMIN, string, string_en);
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:ip(playerid, params[])
{
	if(IsPlayerAdmin(playerid))
	{
		new string[128], giveplayerid;
		
	    if(sscanf(params,"?<MATCH_NAME_PARTIAL=1>u",giveplayerid))
		   	return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> /IP [Name/ID]","<$>» Warning «<#> /IP [Name/ID]");
		   	
		if(giveplayerid != INVALID_PLAYER_ID && IsPlayerConnected(giveplayerid))
		{
		    new IP[128];
		    GetPlayerIp(giveplayerid,IP,sizeof(IP));
		    format(string,sizeof(string), "<$>» Admin «<#> %s's IP: %s", GetName(giveplayerid), IP);
		    SendLanguageMessage(playerid, COLOR_ADMIN, string, string);
		}
		else
			return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Dieser Spieler ist nicht Online.","<$>» Warning «<#> This player is not online.");
	}
	else
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");
		
	return 1;
}

CMD:start(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	if(IsStarting || IsStarted || IsPaused)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Das Tournament wurde bereits gestartet!","<$>» Warning «<#> The tournament has already started!");

	ResetAllPlayers();

	new string[128], string_en[128];
	format(string, sizeof(string), "<$>» Event «<#> Admin %s hat das Tournament gestartet!", GetName(playerid));
	format(string_en, sizeof(string_en), "<$>» Event «<#> Admin %s has started the tournament!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_BLUE, string, string_en);

	StartEvent();
	return 1;
}

CMD:pause(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	if(!IsStarted)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Das Tournament wurde noch nicht gestartet!","<$>» Warning «<#> The tournament has not been started yet!");

	new string[128], string_en[128];
	format(string, sizeof(string), "<$>» Event «<#> Admin %s hat das Tournament pausiert!", GetName(playerid));
	format(string_en, sizeof(string_en), "<$>» Event «<#> Admin %s has paused the tournament!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_BLUE, string, string_en);

	PauseEvent(-1);
	return 1;
}

CMD:finish(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	if(!IsStarted)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Das Tournament wurde noch nicht gestartet!","<$>» Warning «<#> The tournament has not been started yet!");

	new string[128], string_en[128];
	format(string, sizeof(string), "<$>» Event «<#> Admin %s hat das Tournament beendet!", GetName(playerid));
	format(string_en, sizeof(string_en), "<$>» Event «<#> Admin %s has finished the tournament!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_BLUE, string, string_en);

	FinishEvent();
	return 1;
}

CMD:continue(playerid, params[])
{
	if(!IsPlayerAdmin(playerid))
	    return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Du bist kein Admin!","<$>» Warning «<#> You are not an admin!");

	if(!IsPaused)
		return SendLanguageMessage(playerid, COLOR_RED, "<$>» Warnung «<#> Das Tournament wurde noch nicht pausiert!","<$>» Warning «<#> The tournament has not been paused yet!");

	new string[128], string_en[128];
	format(string, sizeof(string), "<$>» Event «<#> Admin %s hat das Tournament fortgesetzt!", GetName(playerid));
	format(string_en, sizeof(string_en), "<$>» Event «<#> Admin %s has continued the pausiert!", GetName(playerid));
	SendLanguageMessageToAll(COLOR_BLUE, string, string_en);

	IsStarting = 1;
	IsPaused = 0;
	
	ContinueCountDown = 3;

	Continue = SetTimer("ContinueEvent", 1000, 1);
	return 1;
}
