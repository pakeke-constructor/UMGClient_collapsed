

# mods API:
Allows client to query existing mods,
and obtain information about them.

This is NOT related to loading mods!!!
It's moreso related to the config, downloading, and paths and stuff.



See `mods.lua` for the rest of the API



# types of mods:
There are 3 types of mods:
- Base mods:
- Playable mods
- Addon mods

See `_mod_types.md`




# Mod storage types:
- Mods stored in `%APPDATA%/mods/`, are "local" mods
- Mods stored in steam's UGC directory, are "downloaded" mods
- Mods shipped with UMGClient are "builtin" mods

see `constants.MOD_STORAGE_TYPES`




# Mod identifiers:
Mod identifiers are stored inside `mod_config.uses` and `mod_config.needs`.
There are 3 types:
```json
"/base" // locally installed mod (ie. %appdata%)

"dimensions:348945845"
// downloaded mod, in steam folder (translated to steam id "348945845")

"@items"  // builtin mod, built-in to the UMG client.
```

If a prefix isn't specified:
```json
"hello"
// checks for `/hello` first
// then, checks for `@hello`
```





# mod environments:

Each mod has a private `setfenv` environment. 
However, most objects and functions across the environment are shared- 
For example, `on` and `call` functions are shared across mods.

The reason this is done is so each mod can have it's own unique `require`
function, so we can require files from the base directory.




