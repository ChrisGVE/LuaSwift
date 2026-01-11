# Constants Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Global:** `math.constants` (after extend_stdlib)

Physical constants (CODATA 2018), mathematical constants, and unit conversion factors for scientific computing.

## Mathematical Constants

```lua
luaswift.extend_stdlib()

-- Standard constants
print(math.constants.pi)           -- 3.141592653589793
print(math.constants.e)            -- 2.718281828459045
print(math.constants.tau)          -- 6.283185307179586 (2π)
print(math.constants.phi)          -- 1.618033988749895 (golden ratio)

-- Other useful values
print(math.constants.euler_gamma)  -- 0.5772156649015329 (Euler-Mascheroni)
print(math.constants.sqrt2)        -- 1.4142135623730951
print(math.constants.sqrt3)        -- 1.7320508075688772
print(math.constants.ln2)          -- 0.6931471805599453
print(math.constants.ln10)         -- 2.302585092994046
```

## Physical Constants

All constants use SI units (CODATA 2018 values).

```lua
local c = math.constants

-- Speed of light
print(c.c)                         -- 299792458 (m/s)

-- Planck constants
print(c.h)                         -- 6.62607015e-34 (J⋅s)
print(c.hbar)                      -- 1.054571817e-34 (J⋅s)

-- Gravitational constant
print(c.G)                         -- 6.67430e-11 (m³/(kg⋅s²))

-- Fundamental charges and masses
print(c.e_charge)                  -- 1.602176634e-19 (C)
print(c.m_e)                       -- 9.1093837015e-31 (kg, electron)
print(c.m_p)                       -- 1.67262192369e-27 (kg, proton)
print(c.m_n)                       -- 1.67492749804e-27 (kg, neutron)

-- Thermodynamic constants
print(c.k_B)                       -- 1.380649e-23 (J/K, Boltzmann)
print(c.N_A)                       -- 6.02214076e23 (1/mol, Avogadro)
print(c.R)                         -- 8.314462618 (J/(mol⋅K), gas constant)

-- Electromagnetic constants
print(c.epsilon_0)                 -- 8.8541878128e-12 (F/m, vacuum permittivity)
print(c.mu_0)                      -- 1.25663706212e-6 (H/m, vacuum permeability)
print(c.sigma)                     -- 5.670374419e-8 (W/(m²⋅K⁴), Stefan-Boltzmann)

-- Atomic physics
print(c.alpha)                     -- 7.2973525693e-3 (fine-structure constant)
print(c.Ry)                        -- 10973731.568160 (1/m, Rydberg constant)
print(c.a_0)                       -- 5.29177210903e-11 (m, Bohr radius)
```

## Unit Conversions

### Angular Conversions (to radians)

```lua
local c = math.constants

-- Convert degrees to radians
local angle_deg = 90
local angle_rad = angle_deg * c.degree
print(angle_rad)                   -- 1.5707963267948966 (π/2)

-- Convert arcminutes and arcseconds
local arcmin_rad = 60 * c.arcmin   -- 1 degree in arcminutes
local arcsec_rad = 3600 * c.arcsec -- 1 degree in arcseconds
```

### Length Conversions (to meters)

```lua
local c = math.constants

-- Imperial units
local height_ft = 6
local height_m = height_ft * c.foot
print(height_m)                    -- 1.8288 meters

-- Other length units
print(10 * c.inch)                 -- 0.254 meters
print(100 * c.yard)                -- 91.44 meters
print(c.mile)                      -- 1609.344 meters
print(c.nautical_mile)             -- 1852 meters
```

### Mass Conversions (to kilograms)

```lua
local c = math.constants

-- Weight in pounds to kg
local weight_lb = 150
local weight_kg = weight_lb * c.pound
print(weight_kg)                   -- 68.0388555 kg

-- Other mass units
print(16 * c.ounce)                -- 0.45359236 kg (1 pound)
print(1000 * c.gram)               -- 1 kg
print(c.tonne)                     -- 1000 kg
```

### Temperature Conversions (to Kelvin)

```lua
local c = math.constants

-- Celsius to Kelvin
local temp_c = 25
local temp_k = temp_c + c.zero_Celsius
print(temp_k)                      -- 298.15 K

-- Kelvin to Celsius
local temp_k2 = 373.15
local temp_c2 = temp_k2 - c.zero_Celsius
print(temp_c2)                     -- 100 °C (boiling point of water)
```

### Time Conversions (to seconds)

```lua
local c = math.constants

-- Common time units
print(c.minute)                    -- 60 seconds
print(c.hour)                      -- 3600 seconds
print(c.day)                       -- 86400 seconds
print(c.week)                      -- 604800 seconds
print(c.year)                      -- 31557600 seconds (Julian year, 365.25 days)

-- Calculate age in seconds
local age_years = 30
local age_seconds = age_years * c.year
```

## Practical Examples

### Energy calculations

```lua
local c = math.constants

-- Calculate energy from mass (E = mc²)
local mass_kg = 1e-3  -- 1 gram
local energy_J = mass_kg * c.c * c.c
print(energy_J)                    -- 8.987551787368176e13 joules

-- Photon energy (E = hf)
local frequency_Hz = 5e14  -- Green light
local photon_energy = c.h * frequency_Hz
print(photon_energy)               -- 3.31303507e-19 joules
```

### Ideal gas law

```lua
local c = math.constants

-- PV = nRT
local n_moles = 1
local temp_K = 298.15  -- 25°C
local volume_L = 24.45
local volume_m3 = volume_L / 1000

local pressure_Pa = (n_moles * c.R * temp_K) / volume_m3
print(pressure_Pa)                 -- ~101325 Pa (1 atm)
```

### Gravitational force

```lua
local c = math.constants

-- F = G * m1 * m2 / r²
local m1 = 5.972e24    -- Earth mass (kg)
local m2 = 70          -- Human mass (kg)
local r = 6.371e6      -- Earth radius (m)

local force_N = c.G * m1 * m2 / (r * r)
print(force_N)         -- ~686 N (weight of 70 kg person)
```

## Constants Reference

### Mathematical Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `pi` | 3.14159... | π (ratio of circumference to diameter) |
| `e` | 2.71828... | Euler's number (natural logarithm base) |
| `tau` | 6.28318... | τ (2π, ratio of circumference to radius) |
| `phi` | 1.61803... | Golden ratio |
| `euler_gamma` | 0.57721... | Euler-Mascheroni constant |
| `sqrt2` | 1.41421... | √2 |
| `sqrt3` | 1.73205... | √3 |
| `ln2` | 0.69314... | Natural logarithm of 2 |
| `ln10` | 2.30258... | Natural logarithm of 10 |

### Physical Constants (SI Units, CODATA 2018)

| Constant | Value | Unit | Description |
|----------|-------|------|-------------|
| `c` | 299792458 | m/s | Speed of light in vacuum |
| `h` | 6.626e-34 | J⋅s | Planck constant |
| `hbar` | 1.055e-34 | J⋅s | Reduced Planck constant (ℏ = h/2π) |
| `G` | 6.674e-11 | m³/(kg⋅s²) | Gravitational constant |
| `e_charge` | 1.602e-19 | C | Elementary charge |
| `m_e` | 9.109e-31 | kg | Electron mass |
| `m_p` | 1.673e-27 | kg | Proton mass |
| `m_n` | 1.675e-27 | kg | Neutron mass |
| `k_B` | 1.381e-23 | J/K | Boltzmann constant |
| `N_A` | 6.022e23 | 1/mol | Avogadro constant |
| `R` | 8.314 | J/(mol⋅K) | Gas constant |
| `epsilon_0` | 8.854e-12 | F/m | Vacuum permittivity |
| `mu_0` | 1.257e-6 | H/m | Vacuum permeability |
| `sigma` | 5.670e-8 | W/(m²⋅K⁴) | Stefan-Boltzmann constant |
| `alpha` | 7.297e-3 | - | Fine-structure constant |
| `Ry` | 1.097e7 | 1/m | Rydberg constant |
| `a_0` | 5.292e-11 | m | Bohr radius |

### Conversion Factors

#### Angular (to radians)

| Constant | Value | Converts |
|----------|-------|----------|
| `degree` | π/180 | Degrees → radians |
| `arcmin` | π/10800 | Arcminutes → radians |
| `arcsec` | π/648000 | Arcseconds → radians |

#### Length (to meters)

| Constant | Value | Converts |
|----------|-------|----------|
| `inch` | 0.0254 | Inches → meters |
| `foot` | 0.3048 | Feet → meters |
| `yard` | 0.9144 | Yards → meters |
| `mile` | 1609.344 | Miles → meters |
| `nautical_mile` | 1852 | Nautical miles → meters |

#### Mass (to kilograms)

| Constant | Value | Converts |
|----------|-------|----------|
| `gram` | 0.001 | Grams → kilograms |
| `ounce` | 0.0283... | Ounces → kilograms |
| `pound` | 0.4536... | Pounds → kilograms |
| `tonne` | 1000 | Metric tons → kilograms |

#### Temperature (to Kelvin)

| Constant | Value | Converts |
|----------|-------|----------|
| `zero_Celsius` | 273.15 | Add to °C to get K |

#### Time (to seconds)

| Constant | Value | Converts |
|----------|-------|----------|
| `minute` | 60 | Minutes → seconds |
| `hour` | 3600 | Hours → seconds |
| `day` | 86400 | Days → seconds |
| `week` | 604800 | Weeks → seconds |
| `year` | 31557600 | Julian years → seconds |
