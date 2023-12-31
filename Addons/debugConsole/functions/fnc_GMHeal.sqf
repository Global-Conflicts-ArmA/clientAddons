params ["_type"];

disableSerialization;
_unitbox = ((findDisplay 951230) displayCtrl 2100);
_execUnitname = _unitbox lbData (lbCurSel _unitbox);

switch (_type) do {
	case 1: {
		{
			if (name _x == _execUnitname) exitWith {
				if!(isNil "FNC_alive")then{
					if!(_x call FNC_alive)then{
						_x setVariable ["FW_Dead", false, true];
						_x setVariable ["FW_Spectating", false, true];	
						[_x,false] remoteExec ["setCaptive", 0];
						[_x,false] remoteExec ["hideObject", 0];
						[_x,false] remoteExec ["hideObjectGlobal", 2];
						["Terminate"] remoteExec ["BIS_fnc_EGSpectator",_x];
						[false] remoteExec ["acre_api_fnc_setSpectator",_x];
						[_x, {[player, (player getVariable ["FW_Loadout", ""])] call FNC_GearScript}] remoteExec ["call", _x];
						_x remoteExec ["FNC_TrackUnit", 2];
						_x setPosATL (getPosATL player);
					};
				};
				[objNull, _x] call ace_medical_treatment_fnc_fullHeal;
			};
		} forEach playableUnits;


		hint "Player was fully healed";

		_msg = text format ["[UO ADMIN]: %1 fully healed %2 with GM heal", name player, _execUnitname];
		_msg remoteExecCall ["diag_log", 2];
	};
	case 2: {
		{
			[objNull, _x] call ace_medical_treatment_fnc_fullHeal;
		} forEach playableUnits;

		hint "All players were fully healed";

		_msg = text format ["[UO ADMIN]: %1 fully healed everybody with GM heal", name player];
		_msg remoteExecCall ["diag_log", 2];
	};
};

