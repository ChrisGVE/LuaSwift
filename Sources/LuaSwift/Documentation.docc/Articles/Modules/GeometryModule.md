# Geometry Module

High-performance 2D/3D geometry with SIMD acceleration: vectors, shapes, coordinate conversions, splines, and curve fitting.

> Important: This module requires the **NumericSwift** optional dependency. It is **off by default**. Build with `LUASWIFT_INCLUDE_NUMERICSWIFT=1` to enable it.

## Overview

The Geometry module provides 2D and 3D geometry operations backed by Apple's SIMD framework and the Accelerate/LAPACK stack via NumericSwift. It covers:

- Vec2 / Vec3 types with full arithmetic and metamethods
- Circle, ellipse, and sphere first-class types with chainable transforms
- Quaternion for gimbal-lock-free 3D rotation
- Transform3D (4×4 matrix) for 3D scene transforms
- Coordinate conversions: polar, spherical, cylindrical
- Geometric algorithms: convex hull, point-in-polygon, area, centroid, intersections
- Curve fitting: circle (Kåsa/Taubin), ellipse (Fitzgibbon direct), sphere, B-spline, polynomial
- Spline types: cubic spline object and B-spline object with evaluate/derivative/sample

## Installation

```swift
// Install all modules
try ModuleRegistry.install(in: engine)

// Or install just the Geometry module (requires LUASWIFT_INCLUDE_NUMERICSWIFT=1)
try GeometryModule.install(in: engine)
```

Build with NumericSwift enabled:

```bash
LUASWIFT_INCLUDE_NUMERICSWIFT=1 swift build
```

## Basic Usage

```lua
local geo = require("luaswift.geometry")

-- 2D vectors
local v1 = geo.vec2(3, 4)
print(v1:length())          -- 5.0
print(v1:normalize())       -- vec2(0.6000, 0.8000)

-- 3D vectors
local v2 = geo.vec3(1, 0, 0)
local v3 = geo.vec3(0, 1, 0)
print(v2:cross(v3))         -- vec3(0.0000, 0.0000, 1.0000)

-- Quaternion rotation
local q = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi / 2)
print(q:rotate(geo.vec3(1, 0, 0)))  -- vec3(0, 0, -1) approx

-- 3D transform
local t = geo.transform3d()
t = t:translate(1, 2, 3):rotate_y(math.pi / 4):scale(2)
local point = t:apply(geo.vec3(0, 0, 0))

-- Circle
local c = geo.circle(geo.vec2(0, 0), 5)
print(c:area())             -- ~78.5398

-- B-spline
local ctrl = {geo.vec2(0,0), geo.vec2(1,2), geo.vec2(3,2), geo.vec2(4,0)}
local bs = geo.bspline(ctrl, 3)
print(bs:evaluate(0.5))     -- point on curve at t=0.5
```

## API Reference

### Vec2 (2D Vectors)

#### geo.vec2(x, y)

Creates a 2D vector. Fields `.x` and `.y` are accessible directly.

```lua
local v = geo.vec2(3, 4)
print(v.x, v.y)    -- 3  4
print(tostring(v)) -- vec2(3.0000, 4.0000)
```

#### Arithmetic operators

All standard arithmetic operators are defined via metamethods.

```lua
local a = geo.vec2(1, 2)
local b = geo.vec2(3, 4)

local c = a + b        -- vec2(4, 6)
local d = a - b        -- vec2(-2, -2)
local e = a * 2        -- vec2(2, 4)   (scalar on either side)
local f = a / 2        -- vec2(0.5, 1)
local g = -a           -- vec2(-1, -2)
local eq = (a == a)    -- true
```

#### v:length()

Returns the Euclidean length of the vector.

```lua
print(geo.vec2(3, 4):length())  -- 5.0
```

#### v:lengthSquared()

Returns squared length — avoids the square root when a relative comparison is sufficient.

```lua
print(geo.vec2(3, 4):lengthSquared())  -- 25.0
```

#### v:normalize()

Returns a unit vector in the same direction. Returns `vec2(0, 0)` for a zero vector.

```lua
local n = geo.vec2(3, 4):normalize()
print(n:length())  -- 1.0
```

#### v:dot(other)

Dot product.

```lua
print(geo.vec2(1, 0):dot(geo.vec2(0, 1)))  -- 0.0
```

#### v:cross(other)

Returns the scalar 2D cross product (z-component of the 3D cross product).

```lua
print(geo.vec2(1, 0):cross(geo.vec2(0, 1)))  -- 1.0 (counterclockwise)
```

#### v:angle()  /  v:angle(other)

With no argument, returns the angle from the positive x-axis (radians, via `atan2`). With `other`, returns the signed angle between the two vectors.

```lua
print(geo.vec2(1, 1):angle())              -- ~0.7854 (pi/4)
print(geo.vec2(1, 0):angle(geo.vec2(0, 1))) -- ~1.5708 (pi/2)
```

#### v:rotate(theta)

Returns the vector rotated by `theta` radians counterclockwise.

```lua
local r = geo.vec2(1, 0):rotate(math.pi / 2)
-- r ≈ vec2(0, 1)
```

#### v:lerp(other, t)

Linear interpolation; `t = 0` returns `self`, `t = 1` returns `other`.

```lua
local mid = geo.vec2(0, 0):lerp(geo.vec2(10, 10), 0.5)
-- mid = vec2(5, 5)
```

#### v:project(onto)

Projects `self` onto `onto`.

```lua
local p = geo.vec2(3, 4):project(geo.vec2(1, 0))
-- p = vec2(3, 0)
```

#### v:reflect(normal)

Reflects `self` about a surface with the given unit normal.

```lua
local r = geo.vec2(1, -1):reflect(geo.vec2(0, 1))
-- r = vec2(1, 1)
```

#### v:perpendicular()

Returns the vector rotated 90° counterclockwise: `(-y, x)`.

```lua
print(geo.vec2(1, 0):perpendicular())  -- vec2(0, 1)
```

#### v:to_polar()

Returns a table `{r, theta}` with the polar coordinates of the vector.

```lua
local p = geo.vec2(1, 1):to_polar()
print(p.r, p.theta)  -- ~1.4142, ~0.7854
```

#### v:distance(other)

Euclidean distance from `self` to `other` (sugar for `geo.distance`).

```lua
print(geo.vec2(0, 0):distance(geo.vec2(3, 4)))  -- 5.0
```

#### v:angle_to(other)

Angle between `self` and `other` (sugar for `geo.angle_between`).

#### v:in_polygon(polygon)

Returns `true` if the vector (as a point) is inside the given polygon (array of `vec2`).

#### v:circle(radius)

Creates a `circle` centered at this point (sugar for `geo.circle(self, radius)`).

#### v:clone()

Returns a copy of the vector.

---

### Vec3 (3D Vectors)

#### geo.vec3(x, y, z)

Creates a 3D vector. Fields `.x`, `.y`, `.z`.

```lua
local v = geo.vec3(1, 2, 3)
print(v.x, v.y, v.z)  -- 1  2  3
```

#### Arithmetic operators

Same set as `vec2`: `+`, `-`, `*` (scalar), `/`, unary `-`, `==`.

#### v:length(), v:lengthSquared(), v:normalize()

Same semantics as the `vec2` counterparts.

```lua
print(geo.vec3(1, 2, 2):length())  -- 3.0
```

#### v:dot(other)

3D dot product.

#### v:cross(other)

Returns the 3D cross product as a new `vec3`.

```lua
local x = geo.vec3(1, 0, 0)
local y = geo.vec3(0, 1, 0)
print(x:cross(y))  -- vec3(0, 0, 1)
```

#### v:rotate(axis, angle)

Rotates `self` around `axis` (unit or non-unit) by `angle` radians using quaternion math.

```lua
local v = geo.vec3(1, 0, 0)
local r = v:rotate(geo.vec3(0, 1, 0), math.pi / 2)
-- r ≈ vec3(0, 0, -1)
```

#### v:lerp(other, t)

Linear interpolation.

#### v:project(onto), v:reflect(normal)

Same semantics as `vec2`.

#### v:to_spherical()

Returns a table `{r, theta, phi}` using physics convention: `theta` = azimuthal angle from x-axis, `phi` = polar angle from z-axis.

```lua
local s = geo.vec3(0, 0, 1):to_spherical()
print(s.r, s.theta, s.phi)  -- 1, 0, 0
```

#### v:to_cylindrical()

Returns a table `{rho, theta, z}`.

```lua
local c = geo.vec3(1, 0, 2):to_cylindrical()
print(c.rho, c.theta, c.z)  -- 1, 0, 2
```

#### v:distance(other), v:angle_to(other), v:angle(other), v:clone()

Convenience aliases matching the `vec2` sugar methods.

---

### Circle

A 2D circle with a `vec2` center and a scalar radius. Constructed in two forms.

#### geo.circle(center, radius)  /  geo.circle(x, y, radius)

```lua
local c1 = geo.circle(geo.vec2(0, 0), 5)
local c2 = geo.circle(0, 0, 5)   -- equivalent
print(tostring(c1))  -- circle(center=vec2(0.0000, 0.0000), radius=5.0000)
```

Fields: `.center` (vec2), `.radius`.

#### c:translate(dx, dy)

Returns a new circle translated by `(dx, dy)`.

#### c:scale(factor)

Returns a new circle with radius multiplied by `factor`, center unchanged.

#### c:scale_from(factor, origin)

Scales both center and radius from an optional origin point (defaults to `(0, 0)`).

#### c:contains(point)

Returns `true` if `point` is inside or on the circle.

```lua
print(geo.circle(0, 0, 5):contains(geo.vec2(3, 4)))  -- true
```

#### c:area()

```lua
print(geo.circle(0, 0, 1):area())  -- ~3.14159
```

#### c:circumference()

#### c:diameter()

#### c:point_at(angle)

Returns the `vec2` on the circumference at the given angle (radians from positive x-axis).

```lua
local pt = geo.circle(0, 0, 1):point_at(0)
-- pt ≈ vec2(1, 0)
```

#### c:bounds()

Returns `{min = vec2, max = vec2}` axis-aligned bounding box.

#### c:clone()

---

### Ellipse

A 2D ellipse with a `vec2` center, semi-major axis `a` ≥ semi-minor axis `b`, and rotation angle `theta` (radians). Constructor normalises so `a ≥ b`.

#### geo.ellipse(center, a, b, [theta])  /  geo.ellipse(cx, cy, a, b, [theta])

```lua
local e = geo.ellipse(geo.vec2(0, 0), 4, 2)
local e2 = geo.ellipse(0, 0, 4, 2, math.pi / 6)
print(tostring(e))  -- ellipse(center=vec2(0.0000, 0.0000), a=4.0000, b=2.0000, θ=0.0000)
```

Fields: `.center` (vec2), `.semi_major`, `.semi_minor`, `.rotation`.

#### e:translate(dx, dy), e:scale(factor), e:rotate(angle)

Chainable transforms; each returns a new ellipse.

#### e:contains(point)

Point-in-ellipse test accounting for rotation.

#### e:area()

`π * semi_major * semi_minor`

#### e:circumference()

Ramanujan's approximation.

#### e:eccentricity()

#### e:point_at(t)

Returns the `vec2` on the ellipse boundary at parameter `t` (0 to 2π).

#### e:foci()

Returns two `vec2` values for the focal points.

#### e:bounds()

Returns `{min = vec2, max = vec2}` axis-aligned bounding box for the rotated ellipse.

#### e:to_conic()

Returns the 6-element array `{A, B, C, D, E, F}` of the general conic form `Ax² + Bxy + Cy² + Dx + Ey + F = 0`.

#### e:clone()

---

### Sphere

A 3D sphere with a `vec3` center and scalar radius.

#### geo.sphere(center, radius)  /  geo.sphere(cx, cy, cz, radius)

```lua
local s = geo.sphere(geo.vec3(0, 0, 0), 1)
local s2 = geo.sphere(0, 0, 0, 1)  -- equivalent
```

Fields: `.center` (vec3), `.radius`.

#### s:translate(dx, dy, dz), s:scale(factor)

Chainable transforms.

#### s:contains(point)

#### s:volume()

`(4/3) * π * r³`

#### s:surface_area()

`4 * π * r²`

#### s:point_at(theta, phi)

Returns the `vec3` on the surface at azimuthal angle `theta` and polar angle `phi`.

#### s:bounds()

Returns `{min = vec3, max = vec3}`.

#### s:distance(point)

Returns signed distance from `point` to the surface (positive = outside, negative = inside).

#### s:clone()

---

### Quaternion

Represents a 3D rotation without gimbal lock.

#### geo.quaternion(w, x, y, z)

Creates a quaternion from components. Fields `.w`, `.x`, `.y`, `.z`.

```lua
local q = geo.quaternion(1, 0, 0, 0)  -- identity
```

#### geo.quaternion.identity()

#### geo.quaternion.from_euler(yaw, pitch, roll)

Converts ZYX Euler angles (radians) to a quaternion.

```lua
local q = geo.quaternion.from_euler(0, math.pi / 2, 0)
```

#### geo.quaternion.from_axis_angle(axis, angle)

```lua
local q = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi / 2)
```

#### q:normalize()

#### q:conjugate()

#### q:inverse()

#### q:rotate(vec3)

Rotates a `vec3` by this quaternion.

```lua
local v = geo.quaternion.from_axis_angle(geo.vec3(0, 1, 0), math.pi / 2):rotate(geo.vec3(1, 0, 0))
-- v ≈ vec3(0, 0, -1)
```

#### q:slerp(other, t)

Spherical linear interpolation.

```lua
local q1 = geo.quaternion.identity()
local q2 = geo.quaternion.from_euler(0, math.pi, 0)
local mid = q1:slerp(q2, 0.5)
```

#### q:to_euler()

Returns an array `{yaw, pitch, roll}` in radians.

```lua
local angles = q:to_euler()
print(angles[1], angles[2], angles[3])  -- yaw, pitch, roll
```

#### q:to_axis_angle()

Returns an array `{axis_vec3, angle}`.

```lua
local result = q:to_axis_angle()
local axis  = result[1]   -- vec3
local angle = result[2]   -- radians
```

#### q:to_matrix()

Returns a flat 9-element array (row-major 3×3 rotation matrix).

#### q:dot(other)

Quaternion dot product.

#### q:length()

Quaternion norm.

#### q:distance(other)

Euclidean distance in 4D component space.

#### q:clone()

#### q * q2

Multiplies (composes) two quaternions via the `*` metamethod.

```lua
local combined = q1 * q2
```

---

### Transform3D (4×4 Matrix)

An affine transform in homogeneous coordinates. All methods return a new transform (immutable, chainable).

#### geo.transform3d()

Creates the identity transform.

#### t:translate(dx, dy, dz)

```lua
local t = geo.transform3d():translate(1, 2, 3)
```

#### t:rotate_x(angle), t:rotate_y(angle), t:rotate_z(angle)

Rotate around the respective world axis.

#### t:rotate_axis(axis, angle)

Rotate around an arbitrary `vec3` axis.

```lua
local t = geo.transform3d():rotate_axis(geo.vec3(1, 1, 1):normalize(), math.pi / 3)
```

#### t:scale(sx, [sy, sz])

Scales uniformly when only `sx` is given; non-uniformly with three values.

```lua
local t = geo.transform3d():scale(2)       -- uniform
local t = geo.transform3d():scale(1, 2, 3) -- non-uniform
```

#### t:apply(vec3)

Applies the transform to a 3D point and returns a `vec3`.

```lua
local p = geo.transform3d():translate(1, 2, 3):apply(geo.vec3(0, 0, 0))
-- p = vec3(1, 2, 3)
```

#### t:clone()

#### t * t2

Multiplies (combines) two transforms via the `*` metamethod.

---

### Coordinate Conversions

#### geo.from_polar(r, theta)

Creates a `vec2` from polar coordinates.

```lua
local v = geo.from_polar(1, math.pi / 2)
-- v ≈ vec2(0, 1)
```

#### geo.from_spherical(r, theta, phi)

Creates a `vec3` from spherical coordinates (`theta` = azimuthal, `phi` = polar from z-axis).

```lua
local v = geo.from_spherical(1, 0, math.pi / 2)
-- v ≈ vec3(1, 0, 0)
```

#### geo.from_cylindrical(rho, theta, z)

Creates a `vec3` from cylindrical coordinates.

#### Raw scalar aliases

These return bare numbers instead of vector objects, useful for math pipelines:

| Function | Returns |
|---|---|
| `geo.cart_to_polar(x, y)` | `r, theta` |
| `geo.polar_to_cart(r, theta)` | `x, y` |
| `geo.cart_to_spherical(x, y, z)` | `r, theta, phi` |
| `geo.spherical_to_cart(r, theta, phi)` | `x, y, z` |

---

### Geometric Algorithms

#### geo.distance(v1, v2)

Euclidean distance between two points. Works with `vec2`, `vec3`, or quaternion (4D Euclidean).

```lua
print(geo.distance(geo.vec2(0, 0), geo.vec2(3, 4)))  -- 5.0
```

#### geo.angle_between(v1, v2)

Angle between two vectors. Returns a signed angle (via `atan2`) for 2D, unsigned (via `acos`) for 3D. Aliased as `geo.angle`.

```lua
local a = geo.angle_between(geo.vec2(1, 0), geo.vec2(0, 1))  -- ~1.5708
```

#### geo.convex_hull(points)

Graham scan O(n log n) convex hull of a `vec2` array. Returns the hull vertices in order.

```lua
local pts = {geo.vec2(0,0), geo.vec2(1,0), geo.vec2(1,1), geo.vec2(0,1), geo.vec2(0.5,0.5)}
local hull = geo.convex_hull(pts)
```

#### geo.in_polygon(point, polygon)

Ray-casting point-in-polygon test. Aliased as `geo.point_in_polygon`.

```lua
local polygon = {geo.vec2(0,0), geo.vec2(10,0), geo.vec2(10,10), geo.vec2(0,10)}
print(geo.in_polygon(geo.vec2(5, 5), polygon))  -- true
```

#### geo.line_intersection(line1, line2)

Intersection of two 2D line segments. Each line is an array `{p1, p2}` of `vec2`. Returns `nil` if parallel or non-intersecting.

```lua
local p = geo.line_intersection(
    {geo.vec2(0, 0), geo.vec2(10, 10)},
    {geo.vec2(0, 10), geo.vec2(10, 0)}
)
-- p = vec2(5, 5)
```

#### geo.area_triangle(p1, p2, p3)

Signed area of a 2D triangle.

```lua
print(geo.area_triangle(geo.vec2(0,0), geo.vec2(4,0), geo.vec2(0,3)))  -- 6.0
```

#### geo.centroid(points)

Centroid of a `vec2` or `vec3` array (auto-detected from the first element).

```lua
local c = geo.centroid({geo.vec2(0,0), geo.vec2(6,0), geo.vec2(3,6)})
-- c = vec2(3, 2)
```

#### geo.circle_from_3_points(p1, p2, p3)

Returns the unique `circle` passing through three `vec2` points.

```lua
local c = geo.circle_from_3_points(geo.vec2(0,1), geo.vec2(1,0), geo.vec2(-1,0))
-- c.center ≈ vec2(0, 0), c.radius ≈ 1
```

#### geo.plane_from_3_points(p1, p2, p3)

Returns a table `{normal = vec3, d = number}` for the plane through three `vec3` points using the equation `n·x + d = 0`.

#### geo.point_plane_distance(point, plane)

Returns the absolute distance from a `vec3` point to a plane `{normal, d}`.

#### geo.line_plane_intersection(line, plane)

Returns the `vec3` intersection of a line `{origin = vec3, direction = vec3}` and a plane. Returns `nil` if the line is parallel.

```lua
local pt = geo.line_plane_intersection(
    {origin = geo.vec3(0, 0, 5), direction = geo.vec3(0, 0, -1)},
    {normal = geo.vec3(0, 0, 1), d = 0}
)
-- pt = vec3(0, 0, 0)
```

#### geo.plane_plane_intersection(plane1, plane2)

Returns a line `{origin = vec3, direction = vec3}` for the intersection of two planes. Returns `nil` if the planes are parallel.

#### geo.intersection(a, b)

Polymorphic dispatcher. Accepts any two of: 2D line arrays `{p1, p2}`, line tables `{origin, direction}`, or plane tables `{normal, d}`. Auto-detects and routes to the appropriate function. Returns a `vec2`, `vec3`, or line table depending on the inputs.

```lua
-- Line-line (2D)
local p = geo.intersection({geo.vec2(0,0), geo.vec2(2,2)}, {geo.vec2(0,2), geo.vec2(2,0)})
-- p = vec2(1, 1)
```

#### geo.sphere_from_4_points(p1, p2, p3, p4)

Returns the unique `sphere` passing through four `vec3` points.

---

### Splines and Curves

#### geo.cubic_spline(points, [options])  /  geo.cubic_spline(xs, ys, [options])

Constructs a piecewise cubic spline through data points. The default boundary condition is `"natural"` (second derivative = 0 at endpoints) backed by a fast LAPACK implementation. For `"clamped"` or `"not-a-knot"` boundary conditions, the call delegates to `math.interpolate.CubicSpline`.

**Options:**
- `bc_type`: `"natural"` (default) | `"clamped"` | `"not-a-knot"`

```lua
local sp = geo.cubic_spline({geo.vec2(0,0), geo.vec2(1,1), geo.vec2(2,0), geo.vec2(3,1)})
-- or with separate arrays:
local sp = geo.cubic_spline({0, 1, 2, 3}, {0, 1, 0, 1})

print(sp:evaluate(1.5))  -- ~0.5 (smooth interpolation)
```

**Cubic spline object methods:**

| Method | Description |
|---|---|
| `sp:evaluate(x)` | Interpolated y at x (extrapolates outside domain) |
| `sp:derivative(x)` | First derivative S'(x) |
| `sp:second_derivative(x)` | Second derivative S''(x) |
| `sp:evaluate_array(xs)` | Batch evaluate; returns array of y values |
| `sp:domain()` | Returns `x_min, x_max` (two values) |
| `sp:knots()` | Returns the knot array (input x values) |
| `sp:values()` | Returns the value array (input y values) |
| `sp:segments()` | Number of piecewise segments |
| `sp:segment_coeffs(i)` | Table `{a, b, c, d}` for segment i (1-indexed) |

---

#### geo.bspline(control_points, [degree], [knot_vector])

Constructs a B-spline curve from an array of `vec2` or `vec3` control points. Degree defaults to 3 (cubic). If no knot vector is provided, a clamped uniform knot vector is generated automatically.

- Degree must be in [1, 5].
- Requires at least `degree + 1` control points.
- Knot vector must have exactly `n + degree + 1` elements.

```lua
local ctrl = {geo.vec2(0,0), geo.vec2(1,2), geo.vec2(3,2), geo.vec2(4,0)}
local bs = geo.bspline(ctrl)          -- cubic (default)
local bs3d = geo.bspline(
    {geo.vec3(0,0,0), geo.vec3(1,1,0), geo.vec3(2,0,0), geo.vec3(3,1,0)}, 3)
```

**B-spline object methods:**

| Method | Description |
|---|---|
| `bs:evaluate(t)` | Point on curve at parameter t; returns `vec2` or `vec3` |
| `bs:derivative(t, [order])` | Derivative at t; `order` defaults to 1 |
| `bs:sample(n)` | Returns array of n uniformly spaced points; n defaults to 100 |
| `bs:domain()` | Returns `t_min, t_max` (two values) |
| `bs:control_points()` | Returns array of `vec2`/`vec3` control points |
| `bs:knots()` | Returns the knot vector array |
| `bs:degree()` | Returns the polynomial degree |
| `bs:basis(i, t)` | Evaluates basis function N_{i,p}(t) (1-indexed i) |
| `bs:is_3d()` | Returns true for 3D splines |

---

#### geo.bspline_basis(knots, i, p, t)

Standalone evaluation of basis function N_{i,p}(t) (1-indexed i) without creating a spline object.

#### geo.bspline_uniform_knots(n, p)

Generates a clamped uniform knot vector for `n` control points and degree `p`. Returns an array of `n + p + 1` values.

---

### Curve Fitting

#### geo.circle_fit(points, [method])

Fits a circle to an array of `vec2` points using least squares.

- `method`: `"algebraic"` (default, Kåsa method) or `"taubin"` (more accurate for noisy data, Taubin's method)
- Requires at least 3 points.

Returns a `circle` object augmented with fit diagnostics:
- `circle:residuals()` — array of per-point signed residuals
- `circle:rmse()` — root mean squared error
- `circle:fit_method()` — the method string
- `.cx`, `.cy`, `.r` — numeric aliases for center and radius

```lua
local pts = {}
for i = 1, 20 do
    local a = 2 * math.pi * i / 20
    pts[i] = geo.vec2(math.cos(a) + (math.random() - 0.5) * 0.1,
                      math.sin(a) + (math.random() - 0.5) * 0.1)
end
local c = geo.circle_fit(pts, "taubin")
print(c.radius, c:rmse())
```

---

#### geo.ellipse_fit(points, [method])

Fits an ellipse using Fitzgibbon's direct algebraic least squares method.

- `method`: `"direct"` (default and only option)
- Requires at least 5 points.

Returns an `ellipse` object augmented with:
- `ellipse:residuals()`, `ellipse:rmse()`, `ellipse:fit_method()`, `ellipse:fit_conic()`
- `.cx`, `.cy`, `.a`, `.b`, `.theta` — numeric aliases

---

#### geo.sphere_fit(points, [method])

Fits a sphere to an array of `vec3` points.

- `method`: `"algebraic"` (default)
- Requires at least 4 points.

Returns a `sphere` object augmented with:
- `sphere:residuals()`, `sphere:rmse()`, `sphere:max_error()`, `sphere:fit_method()`
- `.cx`, `.cy`, `.cz`, `.r` — numeric aliases

---

#### geo.bspline_fit(points, degree, n_control_points, [options])

Fits a B-spline to data using least squares.

**Parameters:**
- `points` — array of `{x, y}` or `{x, y, z}` points
- `degree` — B-spline degree (1–5)
- `n_control_points` — number of control points (≥ degree + 1)
- `options` — table; `options.parameterization` = `"chord"` (default) | `"uniform"` | `"centripetal"`

Returns a `bspline` object with extra fields accessible as `spline._rmse`, `spline._max_error`, `spline._residuals`, `spline._parameters`.

```lua
local data = {}
for i = 1, 30 do
    local t = i / 30
    data[i] = {x = t, y = math.sin(2 * math.pi * t)}
end
local bs = geo.bspline_fit(data, 3, 8)
print(bs:evaluate(0.5))
```

---

#### geo.polynomial(coeffs)

Constructs a polynomial from an array of coefficients `{a_0, a_1, ..., a_n}` in ascending degree order: a_0 + a_1·x + a_2·x² + …

```lua
local p = geo.polynomial({1, -2, 1})  -- 1 - 2x + x² = (x-1)²
```

**Polynomial object methods:**

| Method | Description |
|---|---|
| `p:evaluate(x)` | Evaluates the polynomial at x |
| `p:degree()` | Returns the degree |
| `p:coefficients()` | Returns a copy of the coefficient array |
| `p:derivative()` | Returns the derivative as a new polynomial |
| `p:roots([options])` | Newton's method root finding; options: `tol`, `max_iter` |
| `p:clone()` | Returns a copy |

---

#### geo.polyeval(coeffs, x)

Evaluates a polynomial from a raw coefficient array without constructing an object.

```lua
print(geo.polyeval({1, -2, 1}, 3))  -- 1 - 6 + 9 = 4
```

---

#### geo.polyfit(points, degree)  /  geo.polyfit(xs, ys, degree)

Fits a polynomial of the given degree to data using least squares via the `luaswift.linalg` module (which must be loaded).

Returns a `polynomial` object with additional fields:
- `.r_squared` — coefficient of determination
- `.residual_sum` — sum of squared residuals
- `.xs`, `.ys` — copies of the input arrays

```lua
local p = geo.polyfit({0, 1, 2, 3}, {0, 1, 4, 9}, 2)  -- fit quadratic
print(p:evaluate(1.5))  -- ~2.25
print(p.r_squared)      -- ~1.0
```

---

#### geo.fit(points, shape, [options])

Unified dispatcher for all fitting operations.

| `shape` | Calls | Key options |
|---|---|---|
| `"line"` or `"linear"` | `geo.polyfit(points, 1)` | — |
| `"polynomial"` or `"poly"` | `geo.polyfit(points, degree)` | `options.degree` (default 2) |
| `"circle"` | `geo.circle_fit(points, method)` | `options.method` |
| `"ellipse"` | `geo.ellipse_fit(points, method)` | `options.method` |
| `"sphere"` | `geo.sphere_fit(points, method)` | `options.method` |
| `"spline"` or `"cubic_spline"` | `geo.cubic_spline(points)` | — |
| `"bspline"` | `geo.bspline(points, degree, knots)` | `options.degree`, `options.knots` |

```lua
local c = geo.fit(noisy_points, "circle", {method = "taubin"})
local p = geo.fit(data_points, "polynomial", {degree = 3})
```

---

## Common Patterns

### 3D Character Movement

```lua
local geo = require("luaswift.geometry")

local position = geo.vec3(0, 0, 0)
local velocity = geo.vec3(0, 0, 0)
local facing   = geo.quaternion.identity()

function update(dt)
    position = position + velocity * dt
    if velocity:length() > 0.01 then
        local current_dir = facing:rotate(geo.vec3(0, 0, 1))
        local target_dir  = velocity:normalize()
        local axis  = current_dir:cross(target_dir)
        local angle = current_dir:angle_to(target_dir)
        if axis:length() > 1e-6 then
            facing = facing * geo.quaternion.from_axis_angle(axis:normalize(), angle * dt * 10)
        end
    end
end
```

### Smooth Camera Orbit

```lua
local dist  = 10
local yaw   = 0
local pitch = 0.3

function get_camera_pos(target)
    local q      = geo.quaternion.from_euler(yaw, pitch, 0)
    local offset = q:rotate(geo.vec3(0, 0, dist))
    return target + offset
end
```

### Polar Coordinate Sweep

```lua
local geo = require("luaswift.geometry")
local points = {}
for i = 1, 36 do
    local theta = 2 * math.pi * i / 36
    points[i] = geo.from_polar(5, theta)
end
local hull = geo.convex_hull(points)
```

### B-Spline Path

```lua
local geo = require("luaswift.geometry")
local waypoints = {
    geo.vec3(0, 0, 0),
    geo.vec3(5, 3, 1),
    geo.vec3(10, 0, 2),
    geo.vec3(15, 5, 0),
    geo.vec3(20, 0, 0),
}
local path = geo.bspline(waypoints, 3)
local samples = path:sample(100)
for _, pt in ipairs(samples) do
    -- pt is a vec3
end
```

### Fitting a Circle to Sensor Data

```lua
local geo = require("luaswift.geometry")
-- Build noisy circle data
local pts = {}
for i = 1, 50 do
    local a = 2 * math.pi * i / 50
    pts[i] = geo.vec2(
        3 * math.cos(a) + (math.random() - 0.5) * 0.2,
        3 * math.sin(a) + (math.random() - 0.5) * 0.2
    )
end
local c = geo.circle_fit(pts, "taubin")
print(string.format("center=(%.3f, %.3f) r=%.3f rmse=%.4f",
    c.center.x, c.center.y, c.radius, c:rmse()))
```

---

## Performance Notes

- All vector and matrix operations use Apple's SIMD framework (double precision).
- Curve fitting uses Accelerate/LAPACK via NumericSwift.
- Convex hull uses Graham scan at O(n log n).
- `geo.distance`, `geo.angle_between` dispatch on argument type at runtime (vec2 / vec3 / quaternion).
- For high-throughput paths prefer `v:lengthSquared()` over `v:length()` when only comparison is needed.
- `cubic_spline:evaluate_array` is more efficient than calling `evaluate` in a loop.

## See Also

- ``GeometryModule``
- ``LinAlgModule``
- ``MathXModule``
