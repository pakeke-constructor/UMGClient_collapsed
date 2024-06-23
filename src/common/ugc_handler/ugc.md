

# UGCs:


All UGC items have a unique u64 id, assigned by steam.

-------------------

UGC items are stored automatically in some directory managed by steam.

However, we also store mods in our own directory.
- Mods in development are stored in `mods/`
- Downloaded mods are stored in steam's directory



### IMPORTANT IDEAS:

- We want to be able to create copies of downloaded UGC worlds
(Maybe add an option in the `host` menu to create a copy of an existing world?)

- We want to ensure that downloaded mods aren't modifiable

- We want to have preview file just sitting in the folder `preview.png`


mod_folder/
    ... mod data
    ugc_config.json
    mod_config.json




## Central config file: ugc_config.json

`ugc_config.json`:
```json
{
    "name": "light_mod",
    "description": "This mod will LIGHT UP ur day",
    "type": "mod", // or "world"
    "version": "1.0.0"
}

```


When we drag a directory into `publish` file dropper,
the publisher will first check for a `ugc_config.json`, and populate
the UI with those values first.




# UGC Storage:
UGCs are stored in steams directory, AND in our own directories.

Terminology:
- steam_dir:  Steams directory for holding subscribed workshop items
- local_dir:  Our own directories (i.e. `worlds/`, `mods/`)

UMG-client automatically copies UGCs from steam_dir to local_dir
on start-up.

If the `version` value in `ugc_config.json` in the steam directory
is greater than the `version`, then a copy-over will happen.






# UGC Updating / Dep resolution planning:

We probably just want a coroutine that we can call continuously,
that goes an updates everything and downloads everything.


