#include "script_component.hpp"

if !(hasInterface) exitWith {};

["ace_settingsInitialized", {
    TRACE_3("Settings Initialized",GVAR(enabled),GVAR(timeWithoutWater),GVAR(timeWithoutFood));

    if !(GVAR(enabled)) exitWith {};

    // Add Advanced Fatigue duty factor
    if (missionNamespace getVariable [QACEGVAR(advanced_fatigue,enabled), false]) then {
        LOG("Adding Duty Factor");
        [QUOTE(ADDON), {
            (linearConversion [75, 0, _this getVariable [QGVAR(thirst), 100], 1, 2, true]) * (linearConversion [60, 0, _this getVariable [QGVAR(hunger), 100], 1, 1.5, true])
        }] call ACEFUNC(advanced_fatigue,addDutyFactor);
    };

    // HUD variables
    GVAR(hudInteractionHover) = false;
    GVAR(hudIsShowing) = false;

    // Add water source helpers
    ["ace_interactMenuOpened", {call FUNC(addWaterSourceInteractions)}] call CBA_fnc_addEventHandler;
    
    // Compile water source actions
    private _mainAction = [
        QGVAR(waterSource),
        localize LSTRING(WaterSource),
        QPATHTOF(ui\icon_water_tap.paa),
        {true},
        {
            private _waterSource = _target getVariable [QGVAR(waterSource), objNull];
            alive _waterSource
            && {_waterSource call FUNC(getRemainingWater) != REFILL_WATER_DISABLED}
            && {[_player, _waterSource] call ACEFUNC(common,canInteractWith)}
        },
        {},
        [],
        {[0, 0, 0]}, 
        5.5, 
        [false, false, false, false, true]
    ] call ACEFUNC(interact_menu,createAction);

    private _subActions = [
        [
            QGVAR(checkWater),
            localize LSTRING(CheckWater),
            QPATHTOF(ui\icon_water_tap.paa),
            {
                private _waterSource = _target getVariable [QGVAR(waterSource), objNull];
                [_player, _waterSource] call FUNC(checkWater);},
            {
                private _waterSource = _target getVariable [QGVAR(waterSource), objNull];
                (_waterSource call FUNC(getRemainingWater)) != REFILL_WATER_INFINITE
            }
        ] call ACEFUNC(interact_menu,createAction),
        [
            QGVAR(drinkDirectly),
            localize LSTRING(DrinkDirectly),
            QPATHTOF(ui\icon_water_tap.paa),
            {systemChat "x"},
            {true}
        ] call ACEFUNC(interact_menu,createAction),
        [
            QGVAR(refill),
            localize LSTRING(Refill),
            QPATHTOF(ui\icon_water_tap.paa),
            {},
            {true},
            {
                private _waterSource = _target getVariable [QGVAR(waterSource), objNull];
                [_waterSource, _player] call FUNC(getRefillChildren);
            }
        ] call ACEFUNC(interact_menu,createAction)
    ];

    // Add refill water actions to water sources from compiled list
    [QGVAR(helper), 0, [], _mainAction] call ACEFUNC(interact_menu,addActionToClass);
    {
        [QGVAR(helper), 0, [QGVAR(waterSource)], _x] call ACEFUNC(interact_menu,addActionToClass);
    } forEach _subActions;

    // Start update loop with 10 second interval and 60 second MP sync
    [LINKFUNC(update), CBA_missionTime + MP_SYNC_INTERVAL, 10] call CBA_fnc_waitAndExecute;

    // Add event to hide HUD if it was shown through interact menu hover
    ["ace_interactMenuClosed", {
        if (GVAR(hudInteractionHover)) then {
            GVAR(hudInteractionHover) = false;
            [3] call FUNC(showHud);
        };
    }] call CBA_fnc_addEventHandler;

    // Add respawn eventhandler to reset necessary variables, done through script so only added if field rations is enabled
    ["CAManBase", "respawn", LINKFUNC(handleRespawn)] call CBA_fnc_addClassEventHandler;

    #ifdef DEBUG_MODE_FULL
        ["ACE_player thirst", {ACE_player getVariable [QGVAR(thirst), 100]}, [true, 0, 100]] call ACEFUNC(common,watchVariable);
        ["ACE_player hunger", {ACE_player getVariable [QGVAR(hunger), 100]}, [true, 0, 100]] call ACEFUNC(common,watchVariable);
    #endif
}] call CBA_fnc_addEventHandler;
