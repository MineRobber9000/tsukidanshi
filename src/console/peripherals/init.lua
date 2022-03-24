local peripherals = {}

peripherals.controller = require"console.peripherals.controller"
peripherals.reserved_memory = require"console.peripherals.reserved_memory"
peripherals.render = require"console.peripherals.render"
peripherals.rng = require"console.peripherals.rng"
peripherals.sound = require"console.peripherals.sound"

return peripherals
