## Installation

### Add the resource
1. Place the `hejdrex_vehiclekeys` folder into your server's `resources` directory
2. Add `ensure hejdrex_vehiclekeys` to your `server.cfg` (after ox_lib, ox_target, ox_inventory)

### Add the carkey item to ox_inventory
Open `ox_inventory/data/items.lua` and add:

['carkey'] = {
    label = 'Vehicle Key',
    weight = 100,
    stack = false,
    close = true,
},

**Note:** Also add a `carkey.png` image to `ox_inventory/web/images/` for the item icon.

### Integrate with jg-advancedgarages
This is the most important step. You need to add **2 lines** to your jg-advancedgarages config so it communicates with hejdrex_vehiclekeys.

#### Option A: Custom Code Hooks (Easiest)
Open your `jg-advancedgarages/config.lua` (or `config-client.lua` depending on your version).

**Find the takeout/spawn vehicle hook** (usually called `CustomTakeoutCode`, `OnVehicleTakeout`, or similar) and add:
``TriggerServerEvent('hejdrex_carlock:server:giveKey', plate, VehToNet(vehicle))``

**Find the store/insert vehicle hook** (usually called `CustomInsertCode`, `OnVehicleStore`, or similar) and add:
``TriggerServerEvent('hejdrex_carlock:server:removeKey', plate)``

#### Option B: Framework Functions
If your jg-advancedgarages version uses `framework/cl-functions.lua`, you can add the same lines there:

In the vehicle takeout function:
``TriggerServerEvent('hejdrex_carlock:server:giveKey', plate, VehToNet(vehicle))``

In the vehicle store function:
``TriggerServerEvent('hejdrex_carlock:server:removeKey', plate)``

You can ensure both scripts in server or restart whole server via txAdmin/your server manager tool (recommended)

**DONE**, you have now installed vehicle keys into your server.
