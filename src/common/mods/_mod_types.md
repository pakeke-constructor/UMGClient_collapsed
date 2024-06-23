
# mod types:


## Base-mods:
technical toolkit.
Unable to be selected by players.
Other mods extend base-mods.


## Playable-mods:
gamemodes / games that can be played
Players can select ONE playable mod (per world)


## Addon-mods:
Addons to playable mods.
(eg. texture pack, turtles mod)
Players can ONLY select an Addon-mod if all the
dependencies of the addon-mod are satisfied.






#### Extra addon config:
Addon-mods have an extra config value called `needs.`

`needs = {"@mod1", "@other_mod"}` <br>

The addon-mod will ONLY be available if ALL mods inside of `needs` are selected.

Note that mods within `needs` can be playable-mods OR base-mods.
(or even other add-ons.)

**Question**: What's the difference between `uses` and `needs`?
`uses`: "Load all mods in this list"
`needs`: "Only display me to user if everything in this list is selected"

We obviously don't want to display incompatible addons, so `needs`
allows us to know if a mod won't work.


----------------

**Question:**  Why do we need `needs`?
Couldn't we achieve the same by just using `uses`?

No. Take this as an example:
`addon_X`:
- adds-on to the `rgb-chess` mod.
- uses an extra base mod, `combustion`.

In this case, we only want `addon_X` to be available if `rgb-chess` is
selected; and we also want the `combustion` mod to be loaded
if `addon_X` is loaded.


