#include "script_component.hpp"

FUNC(loadoutIndex) = {
    
    private _newIndex = player createDiarySubject ["GearIndex", "Loadouts"];
    private _playerSide = side player;
    private _grpArray = [];
    
    allGroups select {side _x isEqualTo _playerSide} apply {
        private _grpText = "";
            private _group = _x;
            private _show = false;
            private _textToDisplay = "";
            units _group select {
                    alive _x && 
                    {
                        (isMultiplayer && {_x in playableUnits}) || 
                        (!isMultiplayer && {_x in switchableUnits})
                    }
            } apply {
                    private _unit = _x;
                    private _getPicture = {
                        params ["_name", "_dimensions", ["_type", "CfgWeapons"]];
                        if (_name isEqualTo "") exitwith {""};
                        if !(isText(configFile >> _type >> _name >> "picture")) exitwith {""};
                        private _image = getText(configFile >> _type >> _name >> "picture");
                        if (_image isEqualTo "") then {_image = "\A3\ui_f\data\map\markers\military\unknown_CA.paa";};
                        if ((_image find ".paa") isEqualTo -1) then {_image = _image + ".paa";};
                        format ["<img image='%1' width='%2' height='%3'/>", _image, _dimensions select 0, _dimensions select 1]
                    };
    
                    private _lobbyName = if !(((roleDescription _x) find "@") isEqualTo -1) then {((roleDescription _x) splitString "@") select 0} else {roleDescription _x};
                    if (_lobbyName isEqualTo "") then {_lobbyName = getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName")};
    
                    // Creating briefing text
                    private _customIcon = _unit getVariable ["ace_nametags_rankIcon", ""];
                    private _rankImage = if (_customIcon isNotEqualto "") then {
                      _rankImage = _customIcon;
                    } else {
                        format ["\A3\Ui_f\data\GUI\Cfg\Ranks\%1_gs.paa", (toLower rank _unit)]
                    };
    
                    _textToDisplay = _textToDisplay + format ["", rank _unit];
                    _textToDisplay = _textToDisplay +
                        format ["<img image='%4' width='16' height='16'/> <font size='14' color='%5'>%1 - %2</font> - %3kg<br/>",
                            name _unit,
                            _lobbyName,
                            round ((loadAbs _unit) *0.1 * 0.45359237 * 10) / 10,
                            _rankImage,
                            if (_unit isEqualTo player) then {"#5555FF"} else {"#FFFFFF"}
                        ];
    
                    private _getApparelPicture = {
                        if (_this isNotEqualto "") then {
                            private _name  = getText(configFile >> "CfgWeapons" >> _this >> "displayName");
                            if (_name isEqualTo "") then {
                                _name = getText(configFile >> "CfgVehicles" >> _this >> "displayName");
                            };
                            private _pic = [_this, [40, 40]] call _getPicture;
                            if (_pic isEqualTo "") then {
                                _pic = [_this, [40, 40], "CfgVehicles"] call _getPicture;
                            };
                            _pic + format ["<execute expression='systemChat ""%1""'>*</execute>  ", _name]
                        } else {
                            ""
                        };
                    };
                    {_textToDisplay = _textToDisplay + (_x call _getApparelPicture)} forEach [uniform _unit, vest _unit, backpack _unit, headgear _unit];
    
                    _textToDisplay = _textToDisplay + "<br/>";
    
                    //display both weapon and it's attachments
                    private _getWeaponPicture = {
                        params ["_weaponName", "_weaponItems"];
                        private _str = "";
                        if !(_weaponName isEqualTo "") then {
                            _str = _str + ([_weaponName, [80, 40]] call _getPicture);
                            {
                                if !(_x isEqualTo "") then {
                                    _str = _str + ([_x, [40, 40]] call _getPicture);
                                };
                            } forEach _weaponItems;
                        };
                        _str
                    };
    
                    //display array of magazines
                    private _displayMags = {
                        _textToDisplay = _textToDisplay + "  ";
                        _this apply {
                            private _name = _x;
                            private _itemCount = {_x isEqualTo _name} count _allMags;
                            private _displayName = getText(configFile >> "CfgMagazines" >> _name >> "displayName");
                            _textToDisplay = _textToDisplay + ([_name, [32,32], "CfgMagazines"] call _getPicture) + format ["<execute expression='systemChat ""%2""'>x%1</execute> ", _itemCount, _displayName];
                        };
                        _textToDisplay = _textToDisplay + "<br/>";
                    };
    
                    //get magazines for a weapon and it's muzzles (grenade launchers etc.)
                    private _getMuzzleMags = {
                        private _result = getArray(configFile >> "CfgWeapons" >> _this >> "magazines");
                        {
                            if (!(_x isEqualTo "this") && {!(_x isEqualTo "SAFE")}) then {
                                {_result pushBackUnique _x} forEach getArray (configFile >> "CfgWeapons" >> _this >> _x >> "magazines");
                            };
                        } forEach getArray (configFile >> "CfgWeapons" >> _this >> "muzzles");
                        _result = _result apply {toLower _x};
                        _result
                    };
    
                    private _sWeaponName = secondaryWeapon _unit;
                    private _hWeaponName = handgunWeapon _unit;
                    private _weaponName = primaryWeapon _unit;
    
                    // Primary weapon
                    if (_weaponName isNotEqualTo "") then {
                        private _name = getText(configFile >> "CfgWeapons" >> _weaponName >> "displayName");
                        _textToDisplay = _textToDisplay + format ["<font color='#FFFF00'>Primary: </font>%1<br/>", _name] + ([_weaponName, primaryWeaponItems _unit] call _getWeaponPicture);
                    };
    
                    private _allMags = magazines _unit;
                    _allMags = _allMags apply {toLower _x};
                    private _primaryMags = _allMags arrayIntersect (_weaponName call _getMuzzleMags);
    
                    _primaryMags call _displayMags;
    
                    // Secondary
                    private _secondaryMags = [];
                    if (_sWeaponName isNotEqualTo "") then {
                        private _name = getText(configFile >> "CfgWeapons" >> _sWeaponName >> "displayName");
                        _textToDisplay = _textToDisplay + format ["<font color='#FFFF00'>Launcher: </font>%1<br/>", _name];
                        _textToDisplay = _textToDisplay + ([_sWeaponName, secondaryWeaponItems _unit] call _getWeaponPicture);
                        _secondaryMags = _allMags arrayIntersect (_sWeaponName call _getMuzzleMags);
                        _secondaryMags call _displayMags;
                    };
    
                    // Handgun
                    private _handgunMags = [];
                    if (_hWeaponName isNotEqualTo "") then {
                        private _name = getText(configFile >> "CfgWeapons" >> _hWeaponName >> "displayName");
                        _textToDisplay = _textToDisplay + format ["<font color='#FFFF00'>Sidearm: </font>%1<br/>", _name];
                        _textToDisplay = _textToDisplay + ([_hWeaponName, handgunItems _unit] call _getWeaponPicture);
                        _handgunMags = _allMags arrayIntersect (_hWeaponName call _getMuzzleMags);
                        _handgunMags call _displayMags;
                    };
    
                    _allMags = _allMags - _primaryMags;
                    _allMags = _allMags - _secondaryMags;
                    _allMags = _allMags - _handgunMags;
    
                    private _radios = [];
                    private _allItems = items _unit;
    
                    {
                        if !((toLower _x) find "acre_" isEqualTo -1) then {
                            _radios pushBack _x;
                        };
                    } forEach _allItems;
                    _allItems = _allItems - _radios;
    
                    _textToDisplay = _textToDisplay + format ["<font color='#FFFF00'>Magazines and items: </font>(Click count for info.)<br/>", _x];
    
                    //display radios, then magazines, inventory items and assigned items
                    {
                        _x params ["_items", "_cfgType"];
                        while {count _items > 0} do {
                            private _name = _items select 0;
                            private _itemCount = {_x isEqualTo _name} count _items;
                            private _displayName = getText(configFile >> _cfgType >> _name >> "displayName");
                            _textToDisplay = _textToDisplay + ([_name, [32,32], _cfgType] call _getPicture) + format ["<execute expression='systemChat ""%2""'>x%1</execute>  ", _itemCount, _displayName];
                            _items = _items - [_name];
                        };
                    } forEach [[_radios, "CfgWeapons"], [_allMags, "CfgMagazines"], [_allItems, "CfgWeapons"], [assignedItems _unit, "CfgWeapons"]];
                    _textToDisplay = _textToDisplay + "<br/>============================================================<br/>";
                    _show = true;
            };
    
            if _show then {
                _grpText = _grpText + _textToDisplay;
            };
            if (_grpText isNotEqualto "") then {
                _grpArray pushBackUnique ["GearIndex", [groupID _group, _grpText]];
            };
    };
    
    reverse _grpArray;
    _grpArray apply {
        player createDiaryRecord _x;
    };
    
    GVAR(GearDiaryRecord) = player createDiaryRecord ["GearIndex", ["ORBAT", ""]];
    
    FUNC(showOrbat) = {
        private _text = "<br/><execute expression='[] call gc_clientSide_briefingKit_showOrbat'>Refresh</execute> (click to show JIPs)<br/><br/>";
    
        private _getPicture = {
            params ["_name", "_dimensions", ["_type", "CfgWeapons"]];
            if (_name isEqualTo "") exitwith {""};
            if !(isText(configFile >> _type >> _name >> "picture")) exitwith {""};
            private _image = getText(configFile >> _type >> _name >> "picture");
            if (_image isEqualTo "") then {_image = "\A3\ui_f\data\map\markers\military\unknown_CA.paa";};
            if ((_image find ".paa") isEqualTo -1) then {_image = _image + ".paa";};
            format ["<img image='%1' width='%2' height='%3'/>", _image, _dimensions select 0, _dimensions select 1]
        };
    
        allGroups select {
            ((side _x) isEqualTo (side player)) &&
            {!isNull leader _x} &&
            {(isPlayer leader _x) || !(isMultiplayer)}
        } apply {
            _text = _text + format ["<font size='20' color='#FFFF00'>%1</font>", groupID _x] + "<br/>";
            {
                private _unit = _x;
                private _radios = "";
                items _unit apply {
                    if !((toLower _x) find "acre_" isEqualTo -1) then {
                        _radios = _radios + ([_x, [28,28]] call _getPicture);
                    };
                };
    
                private _optics = "";
                private _opticsClasses = ["UK3CB_BAF_Soflam_Laserdesignator","Laserdesignator","Laserdesignator_01_khk_F","Laserdesignator_02","Laserdesignator_02_ghex_F","Laserdesignator_03","rhsusf_bino_lerca_1200_black","rhsusf_bino_lerca_1200_tan","ACE_VectorDay","ACE_Vector","rhs_pdu4","rhsusf_bino_lrf_Vector21","Rangefinder","ACE_Yardage450","ACE_MX2A","Binocular","rhsusf_bino_m24_ARD","rhsusf_bino_m24","rhsusf_bino_leopold_mk4"];
                _opticsClasses apply {
                    private _class = _x;
                    if (_class in (items _unit + assignedItems _unit)) exitwith {
                        _optics = ([_class, [28,28]] call _getPicture);
                    };
                };
    
                private _lobbyName = if !(((roleDescription _unit) find "@") isEqualTo -1) then {((roleDescription _unit) splitString "@") select 0} else {roleDescription _unit};
                if (_lobbyName isEqualTo "") then {_lobbyName = getText (configFile >> "CfgVehicles" >> typeOf _unit >> "displayName")};
    
                private _customIcon = _unit getVariable ["ace_nametags_rankIcon", ""];
                private _rankImage = if (_customIcon isNotEqualto "") then {
                  _rankImage = _customIcon;
                } else {
                    format ["\A3\Ui_f\data\GUI\Cfg\Ranks\%1_gs.paa", (toLower rank _unit)]
                };
    
                _text = _text +
                    format ["%1<img image='%2' width='15' height='15'/> <font size='16' color='%3'>%4 | %5</font> %6 | %7kg<br/>%8 %9 %10 %11<br/>",
                        if (_forEachIndex isEqualTo 0) then {""} else {"     "},
                        _rankImage,
                        if (_unit isEqualTo player) then {"#5555FF"} else {"#FFFFFF"},
                        name _unit,
                        _lobbyName,
                        _radios,
                        ((round ((loadAbs _unit) * 0.45359237)) / 10),
                        if (primaryWeapon _unit isNotEqualto "") then {[primaryWeapon _unit, [56,28]] call _getPicture} else {if (handgunWeapon _unit isNotEqualto "") then {[handgunWeapon _unit, [56,28]] call _getPicture} else {""}},
                        if (secondaryWeapon _unit isNotEqualto "") then {[secondaryWeapon _unit, [56,28]] call _getPicture} else {""},
                        if (backpack _unit isNotEqualto "") then {[backpack _unit, [28,28], "CfgVehicles"] call _getPicture} else {""},
                        _optics
                    ];
            } forEach [leader _x] + (units _x - [leader _x]);
        };
    
        player setDiaryRecordText [["GearIndex", GVAR(GearDiaryRecord)], ["ORBAT", _text]];
    };
    
    [] call FUNC(showOrbat);
};

if !(getMissionConfigValue ["MMFW_Core_Enabled",false]) then {
    [] call FUNC(loadoutIndex);
};
