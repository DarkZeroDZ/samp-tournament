/*
+-------------------------------------------------------------------------------+
¦                               Double-O-Seven's                                ¦
¦                        Surface-to-Air-Missile Script                          ¦
¦                                                                               ¦
¦ This script allows you to activate the SAMs in Area 69 and the carrier in SF  ¦
¦ and to add more SAMs all over San Andreas.                                    ¦
¦ It's meant to attack aircrafts but I've added functions to attack everything! ¦
¦ You decide which SAM station should attack what and what not.                 ¦
¦ I was inspired by Awaran's SAM script but it did not work very well for me.   ¦
¦ So I decided to create my own SAM script and here we are.                     ¦
¦                                                                               ¦
¦ Feel free to use. Do NOT:                                                     ¦
¦ - Re-release this script                                                      ¦
¦ - Sell this script                                                            ¦
¦ - Tell other guys that it was your creation                                   ¦
+-------------------------------------------------------------------------------+
*/

#include <a_samp>
#include <Buttons>

#define MAX_SAMS 64
#define MAX_BUTTONS 100
#define DEFAULT_SPEED (75.0)
#define DEFAULT_RANGE (300.0)
#define NO_SAM_OPTION (-1)
#define SAM_LAUNCHER 3267
#define SAM_MISSILE 345
#define Z_ANGLE_TO_ADD (-90.0)
#define SAM_MISSILE_EXPLOSION_DISTANCE 8
#define MAX_SAM_MISSILE_EXPLOSION_DISTANCE 500
#define MISSILE_LIFE_TIME 30 // 30 seconds until missile explodes automatically
#define SAM_RELOAD_TIME 4 // 4 seconds to reload.
#define MISSILE_MOVE_POS_OFFSET (17.0)

/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

forward OnSAMUpdate(playerid,vehicleid,samid,lifetime,playerinvehicle);
forward OnSAMFire(playerid,vehicleid,samid,killersam);
forward OnSAMMissileExplosion(playerid,vehicleid,samid,targethit);

/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

new SAM_Aircrafts[]=
{
    413,417,425,447,460,469,476,487,488,497,511,512,513,519,520,548,553,563,577,592,593
};

enum samInfo
{
	Float:samPos[3],
	Float:samRot[3],
	Float:samSpeed,
	Float:samRange,
	samMissile,
	samLauncher,
	samChasingVehicle,
	samChasingPlayer,
	samFiring,
	samMissileLifeTime,
	samKillerSAM,//Kills not only aircrafts: Kills players and other vehicles, too.
	samReloading,
	samOnline,
	samOption
};

static stock 
	SAMCount,
	SAM[MAX_SAMS][samInfo],
	SAMButton[MAX_BUTTONS char],
	SAMButtonOption[MAX_BUTTONS] = {NO_SAM_OPTION, ...},
	SAMDebug=false;

/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

stock AddSAM(Float:x,Float:y,Float:z,Float:rx,Float:ry,Float:rz,useobject,Float:speed=DEFAULT_SPEED,Float:range=DEFAULT_RANGE,killersam=false,option = NO_SAM_OPTION)
{
	if(SAMCount>=MAX_SAMS)
	{
	    print("[sam] Cannot create more SAMs. Limit ("#MAX_SAMS") reached!");
	    return -1;
	}

	SAM[SAMCount][samPos][0]=x;
	SAM[SAMCount][samPos][1]=y;
	SAM[SAMCount][samPos][2]=z;
	SAM[SAMCount][samRot][0]=rx;
	SAM[SAMCount][samRot][1]=ry;
	SAM[SAMCount][samRot][2]=rz;
	SAM[SAMCount][samSpeed]=speed;
	SAM[SAMCount][samRange]=range;
	SAM[SAMCount][samMissile]=INVALID_OBJECT_ID;
	if(useobject)
	    SAM[SAMCount][samLauncher]=CreateDynamicObject(SAM_LAUNCHER,x,y,z,rx,ry,rz);
	else
	    SAM[SAMCount][samLauncher]=INVALID_OBJECT_ID;
    SAM[SAMCount][samChasingVehicle]=INVALID_OBJECT_ID;
    SAM[SAMCount][samChasingPlayer]=INVALID_PLAYER_ID;
    SAM[SAMCount][samKillerSAM]=killersam;
	SAM[SAMCount][samOnline]=true;
	SAM[SAMCount][samOption]=option;
	return SAMCount++;
}

stock GetSAMCount()
{
	return SAMCount;
}

stock AddSAMButton(Float:x, Float:y, Float:z, Float:angle, option = NO_SAM_OPTION)
{
	new buttonid;
	if ((buttonid = CreateButton(x, y, z, angle)) != INVALID_BUTTON_ID)
	{
		SAMButton{buttonid} = true;
		SAMButtonOption[buttonid] = option;
	}
	return buttonid;
}

stock IsSAMButton(buttonid)
{
	return SAMButton{buttonid};
}

stock GetSAMButtonOption(buttonid)
{
	return SAMButtonOption[buttonid];
}

stock SetSAMState(samid, set)
{
	if(!IsValidSAM(samid))
		return 0;
		
	SAM[samid][samOnline] = set;
	return 1;
}

stock GetSAMState(samid)
{
	if(!IsValidSAM(samid))
		return false;
		
	return SAM[samid][samOnline];
}

stock ChangeSAMState(samid)
{
	if(!IsValidSAM(samid))
		return false;
		
	return (SAM[samid][samOnline] = !SAM[samid][samOnline]);
}

stock GetSAMOption(samid)
{
	if(!IsValidSAM(samid))
		return -1;
		
	return SAM[samid][samOption];
}

forward StopSAMMissile(samid);
public StopSAMMissile(samid)
{
	if(!IsValidSAM(samid))
	    return 0;

	if(!SAM[samid][samFiring])
	    return 0;

    SAM[samid][samFiring]=false;
    SAM[samid][samMissileLifeTime]=0;
    SAM[samid][samReloading]=SAM_RELOAD_TIME*2;
	DestroyDynamicObject(SAM[samid][samMissile]);
	SAM[samid][samMissile]=INVALID_OBJECT_ID;
	SAM[samid][samChasingVehicle]=INVALID_VEHICLE_ID;
    SAM[samid][samChasingPlayer]=INVALID_PLAYER_ID;
	return 1;
}

forward ExplodeMissile(samid);
public ExplodeMissile(samid)
{
    if(!IsValidSAM(samid))
	    return 0;

	if(!SAM[samid][samFiring])
	    return 0;

	new Float:x,Float:y,Float:z;
	GetDynamicObjectPos(SAM[samid][samMissile],x,y,z);
	CreateExplosion(x,y,z,6,15.0);
	SetTimerEx("SAM_Explosion",300,false,"fff",x,y,z);
	SetTimerEx("SAM_Explosion",600,false,"fff",x,y,z);
	return StopSAMMissile(samid);
}

forward SAM_Explosion(Float:x,Float:y,Float:z);
public SAM_Explosion(Float:x,Float:y,Float:z)
	return CreateExplosion(x,y,z,6,15.0);

forward SAMUpdate();
public SAMUpdate()
{
	if(SAMCount)
	{
	    new t=GetTickCount();
	    new vehicleid;
	    new Float:x,Float:y,Float:z;
	    new Float:x2,Float:y2,Float:z2;
	    new Float:rx,Float:rz,Float:sqdis,pstate;
	    for(new i=0;i<SAMCount;i++)
	    {
	        if(SAM[i][samFiring])
	        {
	            if(SAM[i][samMissileLifeTime])
	                SAM[i][samMissileLifeTime]--;
	                
				if(!SAM[i][samMissileLifeTime])
				{
				    OnSAMMissileExplosion(SAM[i][samChasingPlayer],SAM[i][samChasingVehicle],i,false);
				    ExplodeMissile(i);
				}
				else
				{
		            SAM_GetTargetPos(i,x,y,z);
		            GetDynamicObjectPos(SAM[i][samMissile],x2,y2,z2);
		            sqdis=SAM_GetSquareDistance(x,y,z,x2,y2,z2);
		            if(sqdis<=(SAM_MISSILE_EXPLOSION_DISTANCE*SAM_MISSILE_EXPLOSION_DISTANCE))
		            {
		                OnSAMMissileExplosion(SAM[i][samChasingPlayer],SAM[i][samChasingVehicle],i,true);
			            ExplodeMissile(i);
					}
					else if(sqdis>(MAX_SAM_MISSILE_EXPLOSION_DISTANCE*MAX_SAM_MISSILE_EXPLOSION_DISTANCE))
					{
					    OnSAMMissileExplosion(SAM[i][samChasingPlayer],SAM[i][samChasingVehicle],i,false);
	                    ExplodeMissile(i);
					}
		            else
		            {
			            GetMissileMoveData(i,x,y,z,x2,y2,z2,rx,rz,x,y,z);
			            SetDynamicObjectRot(SAM[i][samMissile],rx,0.0,rz);
						StopDynamicObject(SAM[i][samMissile]);
			            MoveDynamicObject(SAM[i][samMissile],x,y,z,SAM[i][samSpeed]);
			            OnSAMUpdate(SAM[i][samChasingPlayer],SAM[i][samChasingVehicle],i,SAM[i][samMissileLifeTime],(SAM[i][samChasingVehicle]!=INVALID_VEHICLE_ID && GetPlayerVehicleID(SAM[i][samChasingPlayer])==SAM[i][samChasingVehicle]));
					}
				}
	        }
	        else if (SAM[i][samOnline])
	        {
	            if(SAM[i][samReloading])
	                SAM[i][samReloading]--;
				else
				{
		            for(new j=0;j<MAX_PLAYERS;j++)
		            {
						if(IsPlayerConnected(j) && !IsPlayerNPC(j) && !SAM[i][samFiring])
						{
						    pstate=GetPlayerState(j);
						    if((pstate==PLAYER_STATE_DRIVER || (pstate==PLAYER_STATE_ONFOOT && SAM[i][samKillerSAM])) && IsPlayerInRangeOfPoint(j,SAM[i][samRange],SAM[i][samPos][0],SAM[i][samPos][1],SAM[i][samPos][2]))
							{
							    if(pstate==PLAYER_STATE_DRIVER)
							    	vehicleid=GetPlayerVehicleID(j);
								else
								    vehicleid=INVALID_VEHICLE_ID;
								    
							    if((SAM_IsAircraft(GetVehicleModel(vehicleid)) || SAM[i][samKillerSAM]))
							    {
							        if(OnSAMFire(j,vehicleid,i,SAM[i][samKillerSAM]))
							        {
								        SAM[i][samChasingVehicle]=vehicleid;
			    						SAM[i][samChasingPlayer]=j;
			    						SAM[i][samFiring]=true;
			    						SAM[i][samMissileLifeTime]=MISSILE_LIFE_TIME*2;
								        SAM_GetTargetPos(i,x,y,z);
								        GetMissileMoveData(i,x,y,z,SAM[i][samPos][0],SAM[i][samPos][1],SAM[i][samPos][2],rx,rz,x,y,z);
								        SAM[i][samMissile]=CreateDynamicObject(SAM_MISSILE,SAM[i][samPos][0],SAM[i][samPos][1],SAM[i][samPos][2],rx,0.0,rz);
										StopDynamicObject(SAM[i][samMissile]);
								        MoveDynamicObject(SAM[i][samMissile],x,y,z,SAM[i][samSpeed]);
										break;
									}
							    }
							}
						}
		            }
				}
	        }
	    }

		if(SAMDebug)
			printf("SAMUpdate(): %dms",GetTickCount()-t);
	    return 1;
	}
	return 0;
}

stock IsValidSAM(samid)
	return (samid>=0 && samid<SAMCount);

/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

SAM_OnPlayerCommandText(playerid,cmdtext[])
{
	if(IsPlayerAdmin(playerid))
	{
	    if(!strcmp("/samdebug",cmdtext,false))
	    {
	        if(SAMDebug)
	        {
	            SendClientMessage(playerid,0xFF0000FF,"[SAM] Debug ausgeschaltet!");
	            SAMDebug=false;
	        }
	        else
	        {
	            SendClientMessage(playerid,0x00FF00FF,"[SAM] Debug eingeschaltet!");
	            SAMDebug=true;
	        }
	        return 1;
	    }
	}
	return 0;
}

SAM_OnGameModeInit()
{
	SetTimer("SAMUpdate",500,true);
}

SAM_OnPlayerDisconnect(playerid)
{
	for(new i=0;i<SAMCount;i++)
	    if(playerid==SAM[i][samChasingPlayer])
	        StopSAMMissile(i);
}

SAM_OnDynamicObjectMoved(objectid)
{
    for(new i=0;i<SAMCount;i++)
    {
        if(SAM[i][samMissile]!=INVALID_OBJECT_ID && SAM[i][samMissile]==objectid)
        {
		    new Float:x,Float:y,Float:z;
		    new Float:x2,Float:y2,Float:z2;
		    new Float:rx,Float:rz;
            SAM_GetTargetPos(i,x,y,z);
            GetDynamicObjectPos(SAM[i][samMissile],x2,y2,z2);
            GetMissileMoveData(i,x,y,z,x2,y2,z2,rx,rz,x,y,z);
            SetDynamicObjectRot(SAM[i][samMissile],rx,0.0,rz);
			StopDynamicObject(SAM[i][samMissile]);
            MoveDynamicObject(SAM[i][samMissile],x,y,z,SAM[i][samSpeed]);
			break;
        }
    }
}

/*-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*/

stock GetMissileMoveData(samid,Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2,&Float:rx,&Float:rz,&Float:mx,&Float:my,&Float:mz)
{
	if(!SAM_GetTargetSpeed(samid,mx,my,mz))
	    return 0;
	    
    mx=(mx*MISSILE_MOVE_POS_OFFSET)+x1;
	my=(my*MISSILE_MOVE_POS_OFFSET)+y1;
	mz=(mz*MISSILE_MOVE_POS_OFFSET)+z1;
	x1-=x2;
	y1-=y2;
	z1-=z2;
	
	if(x1==0.0 && y1==0.0 && z1==0.0)
	    return 0;

	new Float:normxy=floatsqroot(x1*x1+y1*y1);
	if(normxy==0.0)
	{
	    if(z1>0.0)
			rx=90.0;
		else if(z1<0.0)
		    rx=-90.0;
	}
	else
		rx=atan(z1/normxy);
		
	if(x1==0.0)
	{
	    if(y1>0.0)
			rz=90.0;
		else if(y1<0.0)
		    rz=-90.0;
	}
	else
    	rz=atan(y1/x1)+Z_ANGLE_TO_ADD;
    	
	if(x1<0.0)
	    rz+=180.0;
	return 1;
}

stock SAM_GetTargetPos(samid,&Float:x,&Float:y,&Float:z)
{
    if(!IsValidSAM(samid))
	{
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}
	    
	if(SAM[samid][samKillerSAM])
	{
	    if(IsPlayerConnected(SAM[samid][samChasingPlayer]))
	        return GetPlayerPos(SAM[samid][samChasingPlayer],x,y,z);
	}
	else if(SAM[samid][samChasingVehicle]!=INVALID_VEHICLE_ID)
	    return GetVehiclePos(SAM[samid][samChasingVehicle],x,y,z);
	
    return 0;
}

stock SAM_GetTargetSpeed(samid,&Float:x,&Float:y,&Float:z)
{
    if(!IsValidSAM(samid))
	{
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}

    if(SAM[samid][samKillerSAM])
        return SAM_GetTargetPlayerVelocity(samid,x,y,z);

	return SAM_GetTargetVehicleVelocity(samid,x,y,z);
}

stock SAM_GetTargetVehicleVelocity(samid,&Float:x,&Float:y,&Float:z)
{
    if(!IsValidSAM(samid))
	{
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}
	    
	if(SAM[samid][samChasingVehicle]==INVALID_VEHICLE_ID)
	{
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}

    return GetVehicleVelocity(SAM[samid][samChasingVehicle],x,y,z);
}

stock SAM_GetTargetPlayerVelocity(samid,&Float:x,&Float:y,&Float:z)
{
    if(!IsValidSAM(samid))
    {
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}

	if(!IsPlayerConnected(SAM[samid][samChasingPlayer]))
	{
        x=0.0;
        y=0.0;
        z=0.0;
	    return 0;
	}

    if(IsPlayerInAnyVehicle(SAM[samid][samChasingPlayer]))
		return GetVehicleVelocity(GetPlayerVehicleID(SAM[samid][samChasingPlayer]),x,y,z);
	else
		return GetPlayerVelocity(SAM[samid][samChasingPlayer],x,y,z);
}

stock SAM_GetSquareDistance(Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2)
{
	x1-=x2;
	y1-=y2;
	z1-=z2;
	x1*=x1;
	y1*=y1;
	z1*=z1;
	return floatround(x1+y1+z1);
}

stock SAM_IsAircraft(modelid)
{
    for(new i=0;i<sizeof(SAM_Aircrafts);i++)
	    if(modelid==SAM_Aircrafts[i])
	        return true;
	return false;
}
