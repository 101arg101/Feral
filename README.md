# Feral
One-button cat dps addon for Turtle World of Warcraft (1.18.0). Also supports reshifting for bears. If you would like to tip, then send gold to Fryn on Nordanaar.

Author: 101arg101 (Fryn on Nordanaar)

# Prerequisites
- Install [SuperWoW](https://github.com/balakethelock/SuperWoW/releases)
- Install [SuperAPI](https://github.com/balakethelock/SuperAPI)
- Install [Cursive](https://github.com/pepopo978/Cursive)
- Install [UnitXP](https://github.com/jrc13245/UnitXP_SP3)

# Installation
In the Turtle WoW client, navigate to the Addons tab and click "Add new Addon". Paste <code>https://github.com/101arg101/Feral</code> into the text box and install. You can manually install this addon by downloading from here, unzipping this addon into WoW's Interface/Addons folder, and removing the -master from the folder name.

# Features
- Casts Reshift when you're low on energy/rage and don't have important buffs that will get wiped when reshifting.
- Scans your gear to determine cost reductions for your abilities.

# Usage
To use the Feral addon, create a macro that uses the following format
<code>/feral [name or number of rotation]</code>

# Rotations
0. "maul" - maul (for bears)
1. "multibleed" - prowl, tiger's fury, pounce, rake, rip, cycle target based on cursive's raid marks priority
2. "claw-bite" - prowl, tiger's fury, pounce, rip, rake, claw-spam, ferocious bite
3. "claw-rip" - prowl, tiger's fury, pounce, rake, claw-spam, rip
4. "shred-bite" - prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
5. "shred-rip" - prowl, tiger's fury, pounce, rake, shred-spam, rip
6. "claw-nobleed" - prowl, tiger's fury, ravage, claw-spam, ferocious bite
7. "shred-nobleed" - prowl, tiger's fury, ravage, shred-spam, ferocious bite
8. "auto-bite" - prowl, tiger's fury, pounce, claw/shred-spam, ferocious bite
9. "auto-rip" - prowl, tiger's fury, pounce, claw/shred-spam, rip
10. "auto-nobleed" - prowl, tiger's fury, ravage, claw/shred-spam, ferocious bite

# Example macro
<code>/feral clawBite</code>
