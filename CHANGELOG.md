# Changelog

## V0.6.5.R
- Fixed another potential arm movements crash with akimbos

## V0.6.4.R
- Added extra wrist tablet page for quick voice commands

## V0.6.3.R
- Fixed clients crashing on load, related to VR arm movements

## V0.6.2.R
- Fixed custom movement control not working
- Fixed bottom A/X button on Oculus Touch not being rebindable
- Removed bottom A/X button snap turning on Oculus Touch

## V0.6.1
- Fix the game crashing as soon as a level is loaded if no custom controls are set

## V0.6.0
- Add the control customisation system

## V0.5.5
- Fix belt constantly resetting to default when the radio is enabled in PD2 version U180 and later

## V0.5.4
- Fix crash on startup when used with the new WSOCK32.dll-based hook

## V0.5.3
- Fix crash on radio use when no other mods use XAudio - Fixes #98

## V0.5.2
- Add belt-mounted push-to-talk radio - Implements #95

## V0.5.1
- Fix the bug preventing the player from accessing their tablet - Fixes #96

## V0.5.0
- Initial compatibility with the non-beta version of PAYDAY 2 VR
- Fixes the crash bug when loading a heist with trigger-based interaction enabled
- Don't remove the DLL update when used with SuperBLT

## V0.4.8
- Fix crash bug triggeded by teleporting up ladders with mod locomotion disabled - Fixes #94

## V0.4.7
- If you fire a bullet on the same frame as being tased, your guns break - weapons on automatic mode will fire
at the maximum possible ROF of once per frame, and semiautomatic weapons will not fire at all - Fixes #87. Many thanks
to [Kane](http://steamcommunity.com/app/218620/discussions/30/1693785669845446430/) for providing an invaluable analysis
of this problem.

## V0.4.6
- Add hand meele enable/loud only/disable option
- Improve name and description for force-desktop-resolution option

## V0.4.5
- Fix #90

## V0.4.4
- Fix double-update error, making it impossible to hold your weapon with your off hand when toggle-grabbing was enabled, see #89
- Same change as above also fixes #88, which was bags making a ghost copy when picked from your inventory

## V0.4.3
- Disable slowmotion effects, hopefully fixing #87

## V0.4.2
- Remove lag removal now included in the base game, fixes #82 and #85

## V0.4.1
- Add teleport-on-untouch support - Implements #77

## V0.4.0
- Add force quality setting, for use on slower computers - Implements #81

## V0.3.9
- Fix crash when starting heist with mod locomotion disabled - Fixes #78
- Fix gadget always toggling from the right-hand side, when the player is
in left-handed mode - Fixes #76
- Fix toggle crouch button also jumping the player - Fixes #79

## V0.3.8
- Fix hand inputs not working while interacting with belt
- Add crouch button - Implements #75
- Prevent hold-to-sprint from toggling off

## V0.3.7
- Fix messiah skill not activating while jumping (Thanks, Kevin Stich)
- Add zeadzone-based sprinting/jumping option - Implements #70
- Add movement smoothing, same as that in the base game - Implements #69

## V0.3.6
- Temporaraly remove camera fade options, fixing PD2VR 1.4 crash
- Fix menu laser dot colour not matching beam colour

## V0.3.5
- Fix weapon-assist toggling - Fixes #58

## V0.3.4
- Fix movement for left-handed users

## V0.3.3
- Fix jumping in PD2VRBeta update 1.3 - Fixes #57

## V0.3.2
- Update Russian translation
- Updates for VR Beta 1.3
  - Fixed crash-on-startup
  - Disable weapon-grip-toggle as it's in the base game
  - Note snap turning is not removed, as the builtin one doesn't seem to work.

## V0.3.1
- Add endscreen speedup option - Implements #40

## V0.3.0
- Fix menu options having no effect after resetting them - Fixes #50
- Fix player slowing down while quickly moving the HMD - Fixes #51

## V0.2.9
- Set default options depending on which HMD is used

## v0.2.8
- Fix fade-to-black problem - Fixes #45

## V0.2.7
- Allow player rotation while in casing mode - Fixes #44
- Fix issues with rotation jumping the player's view the first time they use it per heist.

## V0.2.6
- Add ladder support - Fixes #42

## V0.2.5
- Fix taser crash bug

## V0.2.4
- Update Russian translations (Thanks, Sergio)
- Fix weapons lagging behind their respective hand position/rotations - Fixes #38

## V0.2.3
- Add toggle weapon grip option
- Show warning when using IPHLPAPI.dll 2.0VR5 (crash-on-startup when used in VR)

## V0.2.2
- Add Korean translation (Thanks, DreadNought_40k)
- Add Spanish translation (Thanks, Souls Alive)

## V0.2.1
- Add main-menu laser pointer customization
- Update Russian translations (Thanks, Sergio)

## V0.2.0
- Add option to rebind interact control
- Add sticky-interact option

## V0.1.9.2
- Allow users to jump while in hold-to-sprint mode - Fixes #30

## V0.1.9.1
- Add Russian translations for v0.1.9.0

## V0.1.9.0
- Add HP-on-watch option (enabled by default) - Implements #16

## V0.1.8.1
- Update Russian translations for V0.1.8.0 (Thanks, Sergio)

## V0.1.8.0
- Fix player hands lagging behing camera while moving - Issue #23
- Add movement speed cap in comfort options

## V0.1.7.0:
- Add Russian translations (Thanks, Sergio)

## V0.1.6.3:
- Remove BLT hook DLL from automatic updates
- Warn user if the mod's filename is incorrect and will cause issues while updating

## V0.1.6.2:
- Fix crash on startup caused by v0.1.6.1 and extremely inadequate testing on my part
- Note this version's mod.txt says v0.1.6.1 - I forgot to update it

## V0.1.6.1:
- Add redout effect (disabled by default), fading screen to red as your health runs low - See #21

## V0.1.6:
- Add option to disable locomotion
- Warn the user if an outdated IPHLPAPI.dll is found

## V0.1.5.3:
- Add mod icon

## V0.1.5.2:
- Split camera and control options into two different menus

## V0.1.5.1:
- Fix crash when jumping while downed - See #18

## V0.1.5:
- Adds automatic updates

## V0.1.4:
- Implement controller-relative (Onward-like) movement: #8
- Fix major movement bug: #9
- Add thumbstick/trackpad-based rotation (smooth and snapping)

## V0.1.3:
- Add jumping support.
- Fix issue #4 preventing users from moving while in casing mode (not masked up).
- Adds configuration options for what the camera does when you put your head into a wall, along with defaults far better suited to locomotion movement.

## V0.1.2:
- Add deadzone slider (mainly for Vive users)

## V0.1.1:
- Add sticky sprinting checkbox (default on)

## V0.1.0:
- Initial Release

