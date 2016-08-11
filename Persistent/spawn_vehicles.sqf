/*

	Remove the comments on the MARMA logs if you want to log the spawns to MARMA.

	The _uid variable MUST be changed to a valid UID that already exists in the account table.

	How it works -

	On server init, the script will count AllMissionObjects (X) on a per vehicle basis listed in the array below. If there is less than the defined amount the server will spawn a persistent vehicle with a random pin number
	UNLOCKED at the defined or random road position.

	This script can be used to replace the standard EXILE world vehicle spawns, so that the vehicles that are spawned are persistent. Players will not know the pin number, but its still a "benefit" to them as the vehicle they find
	is persistent. And hey, they might just guess the number..

	This script accounts for ALL vehicles, purchased or other wise. So if players have bought vehicles, and those vehicles exceed the maximum defined number in tbe below array, the server wont spawn anymore.

*/

uiSleep 30;

diag_log ["ExileServer - Spawning persistent vehicle spawns"];
//["ExileServer - Spawning world persistent vehicles"] call MAR_fnc_log;

private ["_count","_uid","_debugForSP","_vehicle","_vehicleArray","_count","_vehicleClass","_position","_positionCount","_pinCode","_vehicleObject","_nearVehicles","_nearVechicleCount","_marker","_cancelSpawn","_isRandomRoadPos","_road","_scriptComplete"];

_scriptComplete = false;
_debugForSP = false;  // If true , when the script is run in the editor it will create markers on the vehicle spawns.

_uid = "1234"; // Needs to be a valid UID that exists in the account table (best to use a server owners uid)

/*
	How the vehicle array works -

	Select 0 - Vehicle class name
	Select 1 - Number - amount limit, will only maintain this many vehicles on the server
	Select 2 - Array of positions EG [[0,0,0].[0,0,0]] - Will randomly select one of the positions per vehicle, if the position is occupied it will try for the other positions
	Select 3 - Boolean - If true, will spawn the vehicle on a random road, if false, will look to the positions above.

*/

_vehicleArray = 
[
	// Quads
	["Exile_Bike_QuadBike_Black",3,[],true],
	["Exile_Bike_QuadBike_Csat",3,[],true],
	// Vans
	["Exile_Car_Van_Box_Black",2,[],true],
	// Offroads
	["Exile_Car_Offroad_White",2,[],true], 
	["Exile_Car_Offroad_Rusty1",2,[],true], 
	["Exile_Car_Offroad_Armed_Guerilla01",1,[],true],
	// Hatchbacks
	["Exile_Car_MB4WDOpen",2,[],true],
	["Exile_Car_MB4WD",2,[],true],
	// Hatchback sports
	["Exile_Car_Hatchback_Sport_Red",1,[],true],
	["Exile_Car_ProwlerLight",1,[],true],
	["Exile_Car_ProwlerUnarmed",1,[],true],
	// SUV
	["Exile_Car_QilinUnarmed",1,[],true],
	["Exile_Car_SUV_Black",1,[],true],
	["Exile_Car_SUV_Grey",1,[],true],
	["Exile_Car_SUV_Orange",1,[],true],
	// Volha
	["Exile_Car_Volha_Blue",1,[],true],
	["Exile_Car_Volha_White",1,[],true],
	["Exile_Car_Volha_Black",1,[],true],
	// Bus
	["Exile_Car_Ikarus_Blue",1,[],true],
	// Zamak
	["Exile_Car_Zamak",1,[],true],
	// Urals
	["Exile_Car_Ural_Covered_Blue",1,[],true],
	["Exile_Car_Ural_Covered_Yellow",1,[],true],
	["Exile_Car_Ural_Covered_Worker",1,[],true],
	["Exile_Car_Ural_Covered_Military",1,[],true],
	// Land rovers
	["Exile_Car_LandRover_Red",1,[],true],
	["Exile_Car_LandRover_Urban",1,[],true],
	["Exile_Car_LandRover_Green",1,[],true],
	["Exile_Car_LandRover_Sand",1,[],true],
	["Exile_Car_LandRover_Desert",1,[],true]
	// Choppers
	/*
	["Exile_Chopper_Hellcat_Green",1,[[23483.9,21144.8,0],[25240.1,21828.6,0]],false],		
	["Exile_Chopper_Hummingbird_Green",1,[[12834.2,16735.8,0],[23079.8,7299.1,0]],false],
	["Exile_Chopper_Mohawk_FIA",1,[[17550.5,13240.5,0],[26783.6,24673,0]],false],						
	["Exile_Chopper_Orca_CSAT",1,[[3732.07,12976.3,20]],false]*/
];

{
	for "_i" from 0 to (_x select 1) do
	{	
		_cancelSpawn = false;
		_obj = _x select 0;
		_count = count allMissionObjects _obj;
		_positionCount = (count (_x select 2));
		_isRandomRoadPos = _x select 3;

		if !(_count >= _x select 1) then
		{
			_vehicleClass = _x select 0;
			_position = selectRandom (_x select 2);

			if !(_isRandomRoadPos) then
			{
				_foundSafePos = false;
				_failSafe = 15;
				_checks = 0;
				waitUntil 
				{ 
					_position = selectRandom (_x select 2);
					_nearVehicles = nearestObjects [_position, ["car","air"], 10];
					_nearVechicleCount = count _nearVehicles;
					if (!(_position isEqualTo LastPosition) && (_nearVechicleCount == 0)) then
					{
						_foundSafePos = true;
					};
					_checks = _checks + 1;
					if (_checks >= _failSafe) then {_cancelSpawn = true; _foundSafePos = true;};
					_foundSafePos
				};		
			}
			else
			{
				_foundSafePos = false;
				waitUntil 
				{
					_spawnCenter = getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition"); 	//Center of your map 
					_min = 15; 																				// minimum distance from the center position (Number) in meters
					_max = 30000; 																			// maximum distance from the center position (Number) in meters
					_mindist = 5; 																			// minimum distance from the nearest object (Number) in meters, ie. spawn at least this distance away from anything within x meters..
					_water = 0; 																			// water mode 0: cannot be in water , 1: can either be in water or not , 2: must be in water
					_shoremode = 0; 																		// 0: does not have to be at a shore , 1: must be at a shore
					_blackList = [[[0, 0],[0,0]]]; 

					_startPosRoad = [_spawnCenter,_min,_max,_mindist,_water,10,_shoremode,_blackList] call BIS_fnc_findSafePos; //Find random spot on the map
					_onRoadCheck = _startPosRoad nearRoads 100; 											//Find road objects 100m from spot
					_countPossibleRoads = count _onRoadCheck; 												// count road objects

					if (_countPossibleRoads == 0) then 
					{
					}
					else
					{
						_road = _onRoadCheck select 0;
						_position = getPos _road;
						_foundSafePos = true;
					};
					uiSleep 0.1;
					_foundSafePos
				};
			};	
			if !(_cancelSpawn) then
			{	
				if !(_debugForSP) then
				{
					_pinCode = format ["%1%2%3%4",round (random 8 +1),round (random 8 +1),round (random 8 +1),round (random 8 +1)];
					_vehicleObject = [_vehicleClass, _position, (random 360), true,_pinCode] call ExileServer_object_vehicle_createPersistentVehicle;
					_vehicleObject setDamage 0.8;
					_vehicleObject setFuel 0;

					if !((_x select 0) isKindOf "AIR") then
					{
						_wheels = ["HitLF2Wheel","HitLFWheel","HitRFWheel","HitRF2Wheel"];
						{
							if (random 1 > 0.5) then
							{	
								_vehicleObject setHitPointDamage [_x,1];
							};	
						} forEach _wheels;
					};	
					_vehicleObject setVariable ["ExileOwnerUID", _uid];
					_vehicleObject setVariable ["ExileIsLocked",0];
					_vehicleObject lock 0;
					_vehicleObject call ExileServer_object_vehicle_database_insert;
					_vehicleObject call ExileServer_object_vehicle_database_update;

					diag_log format ["[Event: Persistent Spawns] -- Spawned a %1 at location: %2 -- Max allowed: %3",_x select 0,_position, _x select 1];
					//[format["[Event: Persistent Spawns] -- Spawned a %1 at location: %2 -- Max allowed: %3",_x select 0,_position, _x select 1]] call MAR_fnc_log;
				}
				else
				{
					_vehicleObject = createVehicle [_vehicleClass,_position,[], 0, "NONE"];

					if !((_x select 0) isKindOf "AIR") then
					{
						_wheels = ["HitLF2Wheel","HitLFWheel","HitRFWheel","HitRF2Wheel"];
						{
							_vehicleObject setHitPointDamage [_x,1];
						} forEach _wheels;
					};

					_marker = createMarker [format["HeliCrash%1", diag_tickTime], _position];
					_marker setMarkerType "mil_dot";
					_marker setMarkerText "Vehicle";
				};
			}
			else
			{
				if !(_debugForSP) then
				{
					//[format["[Event: Persistent Spawns] -- Could not find valid spawn position for %1 at position %2 -- exiting try for this vehicle",_x select 0,_position]] call MAR_fnc_log;
					diag_log format["[Event: Persistent Spawns] -- Could not find valid spawn position for %1 at position %2 -- exiting try for this vehicle",_x select 0,_position];
				}
				else
				{
					hint format["[Event: Persistent Spawns] -- Could not find valid spawn position for %1 at position %2 -- exiting try for this vehicle",_x select 0,_position];
				};	
			};		
		};
	};		
	
} forEach _vehicleArray;

_scriptComplete = true;

waitUntil 
{
	diag_log format ["ExileServer - Finished spawning world vehicles"];
	//["ExileServer - Finished spawning world vehicles"] call MAR_fnc_log;
	_scriptComplete
};