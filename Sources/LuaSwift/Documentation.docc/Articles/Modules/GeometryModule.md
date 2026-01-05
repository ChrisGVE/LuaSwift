# Geometry Module

High-performance 2D/3D geometry operations with SIMD acceleration.

## Overview

The Geometry module provides comprehensive 2D and 3D geometry operations using Apple's SIMD framework for hardware-accelerated computation. It includes vectors, quaternions, transformation matrices, and geometric algorithms.

## Installation

```swift
// Install all modules
ModuleRegistry.installModules(in: engine)

// Or install just the Geometry module
ModuleRegistry.installGeometryModule(in: engine)
```

## Basic Usage

```lua
local geo = require("luaswift.geometry")

-- 2D vectors
local v1 = geo.vec2(3, 4)
print(v1:length())          -- 5
print(v1:normalize())       -- vec2(0.6, 0.8)

-- 3D vectors
local v2 = geo.vec3(1, 0, 0)
local v3 = geo.vec3(0, 1, 0)
print(v2:cross(v3))         -- vec3(0, 0, 1)

-- Quaternions for rotation
local q = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi/2)
local rotated = q:rotate(geo.vec3(1, 0, 0))
print(rotated)              -- vec3(0, 0, -1)

-- 3D transforms
local t = geo.transform3d()
t = t:translate(1, 2, 3):rotate_y(math.pi/4):scale(2)
local point = t:apply(geo.vec3(0, 0, 0))
```

## API Reference

### Vec2 (2D Vectors)

#### geo.vec2(x, y)
Creates a 2D vector.

```lua
local v = geo.vec2(3, 4)
print(v.x, v.y)    -- 3  4
```

#### Arithmetic Operations
```lua
local a = geo.vec2(1, 2)
local b = geo.vec2(3, 4)

local c = a + b        -- vec2(4, 6)
local d = a - b        -- vec2(-2, -2)
local e = a * 2        -- vec2(2, 4)
local f = a / 2        -- vec2(0.5, 1)
local g = -a           -- vec2(-1, -2)
```

#### v:length()
Returns the magnitude (length) of the vector.

```lua
local v = geo.vec2(3, 4)
print(v:length())      -- 5
```

#### v:lengthSquared()
Returns the squared length (faster, avoids square root).

```lua
print(v:lengthSquared())   -- 25
```

#### v:normalize()
Returns a unit vector (length = 1) in the same direction.

```lua
local v = geo.vec2(3, 4)
local n = v:normalize()
print(n)               -- vec2(0.6, 0.8)
print(n:length())      -- 1
```

#### v:dot(other)
Computes the dot product.

```lua
local a = geo.vec2(1, 0)
local b = geo.vec2(0, 1)
print(a:dot(b))        -- 0 (perpendicular)
```

#### v:cross(other)
Returns the 2D cross product (scalar z-component).

```lua
local a = geo.vec2(1, 0)
local b = geo.vec2(0, 1)
print(a:cross(b))      -- 1 (counterclockwise)
```

#### v:angle()
Returns the angle from positive x-axis in radians.

```lua
local v = geo.vec2(1, 1)
print(v:angle())       -- ~0.785 (pi/4)
```

#### v:rotate(theta)
Rotates the vector by angle theta (radians).

```lua
local v = geo.vec2(1, 0)
local r = v:rotate(math.pi / 2)
print(r)               -- vec2(0, 1)
```

#### v:lerp(other, t)
Linear interpolation between vectors (t from 0 to 1).

```lua
local a = geo.vec2(0, 0)
local b = geo.vec2(10, 10)
print(a:lerp(b, 0.5))  -- vec2(5, 5)
```

#### v:project(onto)
Projects vector onto another vector.

```lua
local v = geo.vec2(3, 4)
local axis = geo.vec2(1, 0)
print(v:project(axis)) -- vec2(3, 0)
```

#### v:reflect(normal)
Reflects vector off a surface with given normal.

```lua
local v = geo.vec2(1, -1)
local normal = geo.vec2(0, 1)
print(v:reflect(normal))   -- vec2(1, 1)
```

#### v:perpendicular()
Returns a perpendicular vector (rotated 90 degrees counterclockwise).

```lua
local v = geo.vec2(1, 0)
print(v:perpendicular())   -- vec2(0, 1)
```

### Vec3 (3D Vectors)

#### geo.vec3(x, y, z)
Creates a 3D vector.

```lua
local v = geo.vec3(1, 2, 3)
print(v.x, v.y, v.z)   -- 1  2  3
```

#### Arithmetic Operations
```lua
local a = geo.vec3(1, 2, 3)
local b = geo.vec3(4, 5, 6)

local c = a + b        -- vec3(5, 7, 9)
local d = a - b        -- vec3(-3, -3, -3)
local e = a * 2        -- vec3(2, 4, 6)
local f = a / 2        -- vec3(0.5, 1, 1.5)
local g = -a           -- vec3(-1, -2, -3)
```

#### v:length(), v:lengthSquared(), v:normalize()
Same as vec2, but for 3D vectors.

```lua
local v = geo.vec3(1, 2, 2)
print(v:length())          -- 3
print(v:normalize())       -- vec3(0.333, 0.667, 0.667)
```

#### v:dot(other)
3D dot product.

```lua
local a = geo.vec3(1, 0, 0)
local b = geo.vec3(0, 1, 0)
print(a:dot(b))            -- 0
```

#### v:cross(other)
3D cross product (returns perpendicular vector).

```lua
local x = geo.vec3(1, 0, 0)
local y = geo.vec3(0, 1, 0)
print(x:cross(y))          -- vec3(0, 0, 1)
```

#### v:rotate(axis, angle)
Rotates vector around an axis by angle (radians).

```lua
local v = geo.vec3(1, 0, 0)
local axis = geo.vec3(0, 1, 0)
local rotated = v:rotate(axis, math.pi / 2)
print(rotated)             -- vec3(0, 0, -1)
```

#### v:lerp(other, t)
Linear interpolation between 3D vectors.

```lua
local a = geo.vec3(0, 0, 0)
local b = geo.vec3(10, 10, 10)
print(a:lerp(b, 0.25))     -- vec3(2.5, 2.5, 2.5)
```

#### v:project(onto), v:reflect(normal)
Same as vec2, for 3D vectors.

### Quaternion

Quaternions represent 3D rotations without gimbal lock.

#### geo.quaternion(w, x, y, z)
Creates a quaternion from components.

```lua
local q = geo.quaternion(1, 0, 0, 0)  -- Identity
```

#### geo.quaternion.identity()
Returns the identity quaternion (no rotation).

```lua
local q = geo.quaternion.identity()
```

#### geo.quaternion.from_euler(yaw, pitch, roll)
Creates a quaternion from Euler angles (radians).

```lua
local q = geo.quaternion.from_euler(0, math.pi/2, 0)
```

#### geo.quaternion.from_axis_angle(axis, angle)
Creates a quaternion for rotation around an axis.

```lua
local axis = geo.vec3(0, 1, 0)
local q = geo.quaternion.from_axis_angle(axis, math.pi/2)
```

#### q:normalize()
Returns a normalized quaternion.

```lua
local qn = q:normalize()
```

#### q:conjugate()
Returns the conjugate quaternion.

```lua
local qc = q:conjugate()
```

#### q:inverse()
Returns the inverse quaternion.

```lua
local qi = q:inverse()
```

#### q:rotate(vec3)
Applies the rotation to a 3D vector.

```lua
local q = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi/2)
local v = geo.vec3(1, 0, 0)
local rotated = q:rotate(v)
print(rotated)             -- vec3(0, 0, -1)
```

#### q:slerp(other, t)
Spherical linear interpolation between quaternions.

```lua
local q1 = geo.quaternion.identity()
local q2 = geo.quaternion.from_euler(0, math.pi, 0)
local mid = q1:slerp(q2, 0.5)
```

#### q:to_euler()
Converts quaternion to Euler angles (yaw, pitch, roll).

```lua
local angles = q:to_euler()
print(angles[1], angles[2], angles[3])  -- yaw, pitch, roll
```

#### q:to_axis_angle()
Converts quaternion to axis and angle.

```lua
local result = q:to_axis_angle()
local axis = result[1]     -- vec3
local angle = result[2]    -- radians
```

#### q:to_matrix()
Converts quaternion to 3x3 rotation matrix (9 elements, row-major).

```lua
local matrix = q:to_matrix()
```

#### q * q2
Multiplies quaternions (combines rotations).

```lua
local combined = q1 * q2
```

### Transform3D (4x4 Matrices)

#### geo.transform3d()
Creates an identity transform.

```lua
local t = geo.transform3d()
```

#### t:translate(dx, dy, dz)
Returns transform with translation applied.

```lua
local t = geo.transform3d()
t = t:translate(10, 20, 30)
```

#### t:rotate_x(angle), t:rotate_y(angle), t:rotate_z(angle)
Returns transform with rotation around axis.

```lua
local t = geo.transform3d()
t = t:rotate_y(math.pi / 4)
```

#### t:rotate_axis(axis, angle)
Returns transform with rotation around arbitrary axis.

```lua
local t = geo.transform3d()
local axis = geo.vec3(1, 1, 1):normalize()
t = t:rotate_axis(axis, math.pi / 3)
```

#### t:scale(sx, sy?, sz?)
Returns transform with scaling applied. If only sx given, scales uniformly.

```lua
local t = geo.transform3d()
t = t:scale(2)              -- Uniform scale
t = t:scale(1, 2, 3)        -- Non-uniform scale
```

#### t:apply(vec3)
Applies transform to a 3D point.

```lua
local t = geo.transform3d():translate(1, 2, 3)
local p = t:apply(geo.vec3(0, 0, 0))
print(p)                   -- vec3(1, 2, 3)
```

#### t * t2
Multiplies transforms (combines transformations).

```lua
local t1 = geo.transform3d():translate(1, 0, 0)
local t2 = geo.transform3d():rotate_y(math.pi)
local combined = t1 * t2
```

### Geometric Functions

#### geo.distance(v1, v2)
Computes distance between two points (2D or 3D).

```lua
local a = geo.vec2(0, 0)
local b = geo.vec2(3, 4)
print(geo.distance(a, b))  -- 5
```

#### geo.convex_hull(points)
Computes the convex hull of 2D points.

```lua
local points = {
    geo.vec2(0, 0),
    geo.vec2(1, 1),
    geo.vec2(2, 0),
    geo.vec2(1, 0.5)  -- Interior point
}
local hull = geo.convex_hull(points)
-- Returns vertices of convex hull in order
```

#### geo.point_in_polygon(point, polygon)
Tests if a point is inside a polygon.

```lua
local polygon = {
    geo.vec2(0, 0),
    geo.vec2(10, 0),
    geo.vec2(10, 10),
    geo.vec2(0, 10)
}
local inside = geo.point_in_polygon(geo.vec2(5, 5), polygon)
print(inside)              -- true
```

#### geo.line_intersection(line1, line2)
Finds intersection point of two lines. Each line is {point1, point2}.

```lua
local line1 = {geo.vec2(0, 0), geo.vec2(10, 10)}
local line2 = {geo.vec2(0, 10), geo.vec2(10, 0)}
local intersection = geo.line_intersection(line1, line2)
print(intersection)        -- vec2(5, 5)
```

#### geo.area_triangle(p1, p2, p3)
Computes the area of a triangle.

```lua
local a = geo.vec2(0, 0)
local b = geo.vec2(4, 0)
local c = geo.vec2(0, 3)
print(geo.area_triangle(a, b, c))  -- 6
```

#### geo.centroid(points)
Computes the centroid (center of mass) of points.

```lua
local points = {
    geo.vec2(0, 0),
    geo.vec2(3, 0),
    geo.vec2(0, 3)
}
print(geo.centroid(points))    -- vec2(1, 1)
```

#### geo.circle_from_3_points(p1, p2, p3)
Finds the circle passing through three points.

```lua
local c = geo.circle_from_3_points(
    geo.vec2(0, 1),
    geo.vec2(1, 0),
    geo.vec2(-1, 0)
)
print(c.center, c.radius)  -- vec2(0, 0), 1
```

#### geo.plane_from_3_points(p1, p2, p3)
Defines a plane from three 3D points.

```lua
local plane = geo.plane_from_3_points(
    geo.vec3(0, 0, 0),
    geo.vec3(1, 0, 0),
    geo.vec3(0, 1, 0)
)
print(plane.normal, plane.d)   -- vec3(0, 0, 1), 0
```

#### geo.point_plane_distance(point, plane)
Computes distance from point to plane.

```lua
local plane = geo.plane_from_3_points(
    geo.vec3(0, 0, 0),
    geo.vec3(1, 0, 0),
    geo.vec3(0, 1, 0)
)
local dist = geo.point_plane_distance(geo.vec3(0, 0, 5), plane)
print(dist)                    -- 5
```

#### geo.line_plane_intersection(line, plane)
Finds intersection of a line and plane.

```lua
local line = {
    origin = geo.vec3(0, 0, 5),
    direction = geo.vec3(0, 0, -1)
}
local plane = {
    normal = geo.vec3(0, 0, 1),
    d = 0
}
local point = geo.line_plane_intersection(line, plane)
print(point)                   -- vec3(0, 0, 0)
```

#### geo.sphere_from_4_points(p1, p2, p3, p4)
Finds the sphere passing through four 3D points.

```lua
local sphere = geo.sphere_from_4_points(
    geo.vec3(1, 0, 0),
    geo.vec3(-1, 0, 0),
    geo.vec3(0, 1, 0),
    geo.vec3(0, 0, 1)
)
print(sphere.center, sphere.radius)
```

## Common Patterns

### Character Movement

```lua
local geo = require("luaswift.geometry")

local position = geo.vec3(0, 0, 0)
local velocity = geo.vec3(0, 0, 0)
local facing = geo.quaternion.identity()

function update(dt)
    -- Apply velocity
    position = position + velocity * dt

    -- Rotate to face movement direction
    if velocity:length() > 0.01 then
        local target_dir = velocity:normalize()
        local current_dir = facing:rotate(geo.vec3(0, 0, 1))
        -- Smoothly rotate toward target
    end
end
```

### Camera Orbit

```lua
local camera_distance = 10
local camera_yaw = 0
local camera_pitch = 0.3

function get_camera_position(target)
    local rotation = geo.quaternion.from_euler(camera_yaw, camera_pitch, 0)
    local offset = rotation:rotate(geo.vec3(0, 0, camera_distance))
    return target + offset
end
```

### Collision Detection

```lua
-- Point in polygon test
local player_pos = geo.vec2(5, 5)
local room = {
    geo.vec2(0, 0),
    geo.vec2(10, 0),
    geo.vec2(10, 10),
    geo.vec2(0, 10)
}

if geo.point_in_polygon(player_pos, room) then
    print("Player is inside the room")
end

-- Convex hull for bounding shape
local entity_points = { ... }
local hull = geo.convex_hull(entity_points)
```

### Animation Interpolation

```lua
local start_rotation = geo.quaternion.from_euler(0, 0, 0)
local end_rotation = geo.quaternion.from_euler(0, math.pi, 0)

function animate(t)
    -- Smooth rotation interpolation
    local current = start_rotation:slerp(end_rotation, t)
    return current
end
```

## Performance Notes

- Uses Apple's SIMD framework for hardware-accelerated vector operations
- Quaternion operations are optimized for rotation calculations
- Convex hull uses Graham scan algorithm with O(n log n) complexity
- All operations use double-precision floating point

## See Also

- ``GeometryModule``
- ``LinAlgModule``
- ``MathXModule``
