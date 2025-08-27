# Feral
One-button cat dps addon for Turtle World of Warcraft (1.18.0). Also supports reshifting for bears. If you would like to tip, then send gold to Fryn on Nordanaar.

Author: 101arg101 (Fryn on Nordanaar)

# Prerequisites
- Install SuperWoW
- Install Cursive
- Place the Attack ability somewhere on your action bars.

# Installation
In the Turtle WoW client, navigate to the Addons tab and click "Add new Addon". Paste <code>https://github.com/101arg101/Feral</code> into the text box and install. You can manually install this addon by unzipping the KittyDPS folder into WoW directory Interface/Addons folder and removing the -master from the folder name.

# Features
- Casts Reshift when you're low on energy/rage and don't have important buffs that will get wiped when reshifting.
- Scans your gear to determine cost reductions for your abilities.
- *(todo)* Intelligently casts Claw/Shred/Ferocious Bite when your target is expected to take more damage from them than from Rake/Rip.

# Usage
To use the Feral addon, create a macro that uses the following format
<code>/feral [name or number of rotation]</code>

# Rotations
1. "clawBite" - prowl, tiger's fury, pounce, rip, rake, claw-spam, ferocious bite
2. "clawBleed" - prowl, tiger's fury, pounce, rake, claw-spam, rip
3. "shredBite" - prowl, tiger's fury, pounce, rip, rake, shred-spam, ferocious bite
4. "shredBleed" - prowl, tiger's fury, pounce, rake, shred-spam, rip
5. "multiBleed" - prowl, tiger's fury, pounce, rake, rip, cycle target
6. "noBleedClaw" - prowl, tiger's fury, ravage, claw-spam, ferocious bite
7. "noBleedShred" - prowl, tiger's fury, ravage, shred-spam, ferocious bite
8. "mauler" - maul (for bears)

# Example macro
<code>/feral clawBite</code>
