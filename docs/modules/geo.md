# Geometry Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.geometry` | **Global:** `math.geo` (after extend_stdlib)

High-performance 2D/3D geometry operations using SIMD and Accelerate framework. Provides vector types, quaternions, transformations, curve fitting, and geometric algorithms.

## Quick Start

```lua
local geo = require("luaswift.geometry")

-- 2D vectors
local v = geo.vec2(3, 4)
print(v:length())  -- 5.0

-- 3D vectors
local p = geo.vec3(1, 2, 3)
local q = geo.vec3(4, 5, 6)
print(p:dot(q))    -- 32.0

-- Quaternion rotations
local axis = geo.vec3(0, 1, 0)  -- Y-axis
local rot = geo.quaternion.from_axis_angle(axis, math.pi/2)
local v3 = geo.vec3(1, 0, 0)
local rotated = rot:rotate(v3)  -- vec3(0, 0, -1)

-- Circle fitting
local points = {
    geo.vec2(1, 0),
    geo.vec2(0, 1),
    geo.vec2(-1, 0)
}
local circle = geo.circle_fit(points)
print(circle.radius)  -- ~1.0
```

## Vector Types

### vec2

2D vector with x, y components.

**Constructor:**
```lua
geo.vec2(x, y) -> vec2
```

**Properties:**
- `x`, `y` - components

**Methods:**
- `v:length()` - magnitude
- `v:lengthSquared()` - squared magnitude (faster than length)
- `v:normalize()` - unit vector in same direction
- `v:dot(other)` - dot product
- `v:cross(other)` - 2D cross product (returns scalar z-component)
- `v:angle()` - angle from positive x-axis (radians)
- `v:angle(other)` - angle between this and other vector
- `v:rotate(theta)` - rotate by angle (radians)
- `v:lerp(other, t)` - linear interpolation (t in [0,1])
- `v:project(onto)` - project this onto another vector
- `v:reflect(normal)` - reflect across normal
- `v:perpendicular()` - perpendicular vector (-y, x)
- `v:distance(other)` - Euclidean distance
- `v:in_polygon(polygon)` - point-in-polygon test
- `v:to_polar()` - convert to polar coordinates `{r, theta}`
- `v:clone()` - create copy

**Operators:**
```lua
v1 + v2   -- addition
v1 - v2   -- subtraction
v * s     -- scalar multiplication
s * v     -- scalar multiplication
v / s     -- scalar division
-v        -- negation
v1 == v2  -- equality
```

**Example:**
```lua
local v = geo.vec2(3, 4)
print(v:length())              -- 5.0
print(v:angle())               -- 0.9273 (atan2(4, 3))
local u = v:normalize()        -- vec2(0.6, 0.8)
local w = v:rotate(math.pi/2)  -- vec2(-4, 3)
```

### vec3

3D vector with x, y, z components.

**Constructor:**
```lua
geo.vec3(x, y, z) -> vec3
```

**Properties:**
- `x`, `y`, `z` - components

**Methods:**
- `v:length()` - magnitude
- `v:lengthSquared()` - squared magnitude
- `v:normalize()` - unit vector
- `v:dot(other)` - dot product
- `v:cross(other)` - cross product (returns vec3)
- `v:rotate(axis, angle)` - rotate around axis by angle
- `v:lerp(other, t)` - linear interpolation
- `v:project(onto)` - project onto another vector
- `v:reflect(normal)` - reflect across normal
- `v:distance(other)` - Euclidean distance
- `v:angle(other)` - angle between vectors
- `v:to_spherical()` - convert to spherical `{r, theta, phi}`
- `v:to_cylindrical()` - convert to cylindrical `{rho, phi, z}`
- `v:clone()` - create copy

**Operators:**
```lua
v1 + v2   -- addition
v1 - v2   -- subtraction
v * s     -- scalar multiplication
s * v     -- scalar multiplication
v / s     -- scalar division
-v        -- negation
v1 == v2  -- equality
```

**Example:**
```lua
local v1 = geo.vec3(1, 0, 0)
local v2 = geo.vec3(0, 1, 0)
local cross = v1:cross(v2)  -- vec3(0, 0, 1)
local axis = geo.vec3(0, 0, 1)
local rotated = v1:rotate(axis, math.pi/2)  -- vec3(0, 1, 0)
```

## Quaternions

Quaternions for 3D rotations. Represented as `{w, x, y, z}` (scalar-first).

**Constructors:**
```lua
geo.quaternion(w, x, y, z)
geo.quaternion.identity()
geo.quaternion.from_euler(yaw, pitch, roll)
geo.quaternion.from_axis_angle(axis_vec3, angle)
```

**Methods:**
- `q:normalize()` - unit quaternion
- `q:conjugate()` - conjugate (inverse rotation for unit quaternions)
- `q:inverse()` - inverse quaternion
- `q:rotate(vec3)` - rotate vector by quaternion
- `q:slerp(other, t)` - spherical linear interpolation
- `q:dot(other)` - quaternion dot product
- `q:length()` - quaternion magnitude
- `q:to_euler()` - convert to Euler angles `{yaw, pitch, roll}`
- `q:to_axis_angle()` - convert to `{axis_vec3, angle}`
- `q:to_matrix()` - convert to 4x4 transformation matrix
- `q:clone()` - create copy

**Operators:**
```lua
q1 * q2   -- quaternion multiplication
q1 == q2  -- equality
```

**Example:**
```lua
-- Rotate 90° around Y-axis
local q = geo.quaternion.from_euler(math.pi/2, 0, 0)
local v = geo.vec3(1, 0, 0)
local rotated = q:rotate(v)  -- vec3(0, 0, -1)

-- Interpolate rotations
local q1 = geo.quaternion.identity()
local q2 = geo.quaternion.from_euler(0, math.pi, 0)
local mid = q1:slerp(q2, 0.5)
```

## Coordinate Conversions

**Polar (2D):**
```lua
geo.vec2(x, y):to_polar() -> {r, theta}
geo.from_polar(r, theta) -> vec2
```

**Spherical (3D):**
```lua
geo.vec3(x, y, z):to_spherical() -> {r, theta, phi}
geo.from_spherical(r, theta, phi) -> vec3
```

**Cylindrical (3D):**
```lua
geo.vec3(x, y, z):to_cylindrical() -> {rho, phi, z}
geo.from_cylindrical(rho, phi, z) -> vec3
```

## Geometric Shapes

### Circle

**Constructors:**
```lua
geo.circle(center_vec2, radius)
geo.circle(x, y, radius)
```

**Properties:**
- `center` - center point (vec2)
- `radius` - radius

**Methods:**
- `c:contains(point)` - point inside circle
- `c:area()` - circle area
- `c:circumference()` - perimeter
- `c:diameter()` - 2 × radius
- `c:point_at(angle)` - point on circle at angle
- `c:bounds()` - axis-aligned bounding box `{min, max}`
- `c:translate(dx, dy)` - create translated circle
- `c:scale(factor)` - create scaled circle
- `c:scale_from(factor, origin)` - scale from origin point
- `c:clone()` - create copy

**Example:**
```lua
local c = geo.circle(0, 0, 5)
print(c:area())           -- 78.54
print(c:contains(geo.vec2(3, 0)))  -- true
local p = c:point_at(0)   -- vec2(5, 0)
local c2 = c:translate(10, 10):scale(2)  -- chainable
```

### Ellipse

**Constructors:**
```lua
geo.ellipse(center_vec2, semi_major, semi_minor, [rotation])
geo.ellipse(cx, cy, semi_major, semi_minor, [rotation])
```

**Properties:**
- `center` - center point (vec2)
- `semi_major` - semi-major axis
- `semi_minor` - semi-minor axis
- `rotation` - rotation angle (radians)

**Methods:**
- `e:contains(point)` - point inside ellipse
- `e:area()` - ellipse area
- `e:circumference()` - approximate perimeter (Ramanujan)
- `e:eccentricity()` - eccentricity
- `e:point_at(t)` - point at parameter t (0 to 2π)
- `e:foci()` - focal points `{f1, f2}`
- `e:bounds()` - axis-aligned bounding box
- `e:to_conic()` - conic form coefficients `[A, B, C, D, E, F]`
- `e:translate(dx, dy)` - create translated ellipse
- `e:scale(factor)` - create scaled ellipse
- `e:rotate(angle)` - create rotated ellipse
- `e:clone()` - create copy

**Example:**
```lua
local e = geo.ellipse(0, 0, 5, 3, math.pi/4)
print(e:area())           -- 47.12
print(e:eccentricity())   -- 0.8
local f1, f2 = e:foci()   -- focal points
```

### Sphere

**Constructors:**
```lua
geo.sphere(center_vec3, radius)
geo.sphere(cx, cy, cz, radius)
```

**Properties:**
- `center` - center point (vec3)
- `radius` - radius

**Methods:**
- `s:contains(point)` - point inside sphere
- `s:volume()` - sphere volume
- `s:surface_area()` - surface area
- `s:point_at(theta, phi)` - point on sphere
- `s:bounds()` - axis-aligned bounding box
- `s:distance(point)` - signed distance to surface
- `s:translate(dx, dy, dz)` - create translated sphere
- `s:scale(factor)` - create scaled sphere
- `s:clone()` - create copy

**Example:**
```lua
local s = geo.sphere(0, 0, 0, 5)
print(s:volume())         -- 523.6
local p = s:point_at(0, math.pi/2)  -- point on equator
```

## 3D Transformations

### Transform3D

4×4 transformation matrices for 3D graphics.

**Constructors:**
```lua
geo.transform3d()           -- identity
geo.transform3d.identity()
geo.transform3d.translate(x, y, z)
geo.transform3d.rotate_x(angle)
geo.transform3d.rotate_y(angle)
geo.transform3d.rotate_z(angle)
geo.transform3d.rotate_axis(axis_vec3, angle)
geo.transform3d.scale(sx, sy, sz)
```

**Methods:**
- `t:apply(vec3)` - transform point
- `t:clone()` - create copy

**Operators:**
```lua
t1 * t2   -- matrix multiplication
```

**Example:**
```lua
local t = geo.transform3d.translate(10, 0, 0)
local r = geo.transform3d.rotate_y(math.pi/2)
local combined = t * r
local p = combined:apply(geo.vec3(1, 0, 0))
```

## Curve Fitting

### Polynomial Fitting

```lua
geo.polyfit(points, degree) -> polynomial
geo.polyfit(xs, ys, degree) -> polynomial
```

Returns polynomial object with methods:
- `p:evaluate(x)` - evaluate at x
- `p:derivative()` - polynomial derivative
- `p:roots()` - find roots
- `p.degree` - polynomial degree
- `p.coefficients` - coefficient array

**Example:**
```lua
local points = {{0, 0}, {1, 1}, {2, 4}}
local p = geo.polyfit(points, 2)  -- quadratic fit
print(p:evaluate(3))  -- 9.0
print(p.degree)       -- 2
```

### Cubic Spline

```lua
geo.cubic_spline(points, [bc_type]) -> spline
geo.cubic_spline(xs, ys, [bc_type]) -> spline
```

Cubic spline interpolation. `bc_type` can be `"natural"`, `"clamped"`, or `"not-a-knot"` (default: natural).

**Methods:**
- `s:evaluate(x)` - evaluate at x
- `s:evaluate_array(xs)` - batch evaluation
- `s:derivative()` - spline derivative
- `s:domain()` - domain `{min, max}`
- `s.knots` - knot points
- `s.values` - knot values
- `s.segments` - number of segments

**Example:**
```lua
local knots = {{0, 0}, {1, 1}, {2, 0}, {3, 1}}
local spline = geo.cubic_spline(knots)
print(spline:evaluate(1.5))  -- smooth interpolation
local deriv = spline:derivative()
```

### B-Spline

```lua
geo.bspline(degree, control_points, knots) -> bspline
```

B-spline curves with arbitrary control points.

**Methods:**
- `b:evaluate(t)` - evaluate at parameter t
- `b:sample(n)` - generate n points along curve
- `b:derivative()` - B-spline derivative
- `b:domain()` - parameter domain `{min, max}`
- `b.control_points` - control point array
- `b.degree` - spline degree

**Helper functions:**
```lua
geo.bspline_uniform_knots(n_control, degree) -> knots
geo.bspline_fit(points, degree, n_control, [options]) -> bspline
```

**Example:**
```lua
-- Fit cubic B-spline to data
local points = {
    geo.vec2(0, 0),
    geo.vec2(1, 2),
    geo.vec2(2, 1),
    geo.vec2(3, 3)
}
local spline = geo.bspline_fit(points, 3, 6)
print("RMSE:", spline._rmse)
local curve = spline:sample(50)  -- 50 points
```

### Circle Fitting

```lua
geo.circle_fit(points, [method]) -> circle
```

Fit circle to 2D points. Methods: `"algebraic"` (default) or `"taubin"`.

Returns circle with fit diagnostics:
- `c:residuals()` - residual errors
- `c:rmse()` - root mean square error
- `c:fit_points()` - original points

**Example:**
```lua
local points = {
    geo.vec2(1, 0),
    geo.vec2(0, 1),
    geo.vec2(-1, 0),
    geo.vec2(0, -1)
}
local c = geo.circle_fit(points, "taubin")
print("Center:", c.center)
print("Radius:", c.radius)
print("RMSE:", c:rmse())
```

### Ellipse Fitting

```lua
geo.ellipse_fit(points, [method]) -> ellipse
```

Fit ellipse to 2D points. Method: `"direct"` (Fitzgibbon's method).

Returns ellipse with diagnostics:
- `e:residuals()` - residual errors
- `e:rmse()` - root mean square error
- `e:fit_conic()` - conic form coefficients

**Example:**
```lua
local pts = generate_noisy_ellipse_points()
local e = geo.ellipse_fit(pts)
print("Semi-axes:", e.semi_major, e.semi_minor)
print("Rotation:", e.rotation)
```

### Sphere Fitting

```lua
geo.sphere_fit(points, [method]) -> sphere
```

Fit sphere to 3D points. Method: `"algebraic"`.

Returns sphere with diagnostics:
- `s:residuals()` - residual errors
- `s:rmse()` - root mean square error
- `s:max_error()` - maximum error

**Example:**
```lua
local points = generate_sphere_points()
local s = geo.sphere_fit(points)
print("Center:", s.center)
print("Radius:", s.radius)
```

### Unified Fitting API

```lua
geo.fit(shape, points, [options]) -> shape_object
```

Unified interface for all curve fitting. `shape` can be:
- `"line"` - linear polynomial
- `"polynomial"` - polynomial (specify `degree`)
- `"circle"` - circle
- `"ellipse"` - ellipse
- `"sphere"` - sphere
- `"spline"` - cubic spline
- `"bspline"` - B-spline (specify `degree`, `n_control`)

**Example:**
```lua
-- All equivalent to specific functions
local circle = geo.fit("circle", points)
local poly = geo.fit("polynomial", points, {degree = 3})
local bspl = geo.fit("bspline", points, {degree = 3, n_control = 10})
```

## Geometric Algorithms

### Distance

```lua
geo.distance(obj1, obj2) -> number
```

Euclidean distance between vec2, vec3, or quaternion objects.

### Angle Between

```lua
geo.angle_between(v1, v2) -> angle
geo.angle(v1, v2) -> angle  -- alias
```

Angle between two vectors (radians).

### Convex Hull

```lua
geo.convex_hull(points) -> hull_points
```

Compute convex hull of 2D points (Graham scan algorithm).

**Example:**
```lua
local points = {
    geo.vec2(0, 0),
    geo.vec2(1, 1),
    geo.vec2(2, 0),
    geo.vec2(1, 0.5)
}
local hull = geo.convex_hull(points)
```

### Point in Polygon

```lua
geo.in_polygon(point, polygon) -> boolean
point:in_polygon(polygon) -> boolean
```

Test if point is inside polygon (ray casting algorithm).

### Line Intersection

```lua
geo.line_intersection(p1, p2, p3, p4) -> point | nil
```

Find intersection of line segments (p1-p2) and (p3-p4).

### Triangle Area

```lua
geo.area_triangle(p1, p2, p3) -> area
```

Signed area of triangle (positive = counterclockwise).

### Centroid

```lua
geo.centroid(points) -> center
```

Geometric centroid of points.

### Circle from 3 Points

```lua
geo.circle_from_3_points(p1, p2, p3) -> circle | nil
```

Exact circle through three non-collinear points.

### Plane Operations

```lua
geo.plane_from_3_points(p1, p2, p3) -> {normal, d}
geo.point_plane_distance(point, plane) -> distance
geo.line_plane_intersection(p1, p2, plane) -> point | nil
geo.plane_plane_intersection(plane1, plane2) -> {point, direction} | nil
```

3D plane operations. Plane is represented as `{normal_vec3, d}` where `normal·x = d`.

### Polymorphic Intersection

```lua
geo.intersection(obj1, obj2, [obj3], [obj4]) -> result | nil
```

Intelligent intersection based on argument types:
- 4 vec2: line-line intersection
- 2 vec3 + plane: line-plane intersection
- 2 planes: plane-plane intersection

**Example:**
```lua
-- Line-line
local p = geo.intersection(
    geo.vec2(0, 0), geo.vec2(2, 2),
    geo.vec2(0, 2), geo.vec2(2, 0)
)

-- Line-plane
local plane = geo.plane_from_3_points(p1, p2, p3)
local hit = geo.intersection(line_start, line_end, plane)

-- Plane-plane
local line = geo.intersection(plane1, plane2)
```

### Sphere from 4 Points

```lua
geo.sphere_from_4_points(p1, p2, p3, p4) -> sphere | nil
```

Exact sphere through four non-coplanar points.

## Function Reference

| Function | Description |
|----------|-------------|
| **Vector Operations** | |
| `vec2(x, y)` | Create 2D vector |
| `vec3(x, y, z)` | Create 3D vector |
| `distance(a, b)` | Euclidean distance |
| `angle_between(v1, v2)` | Angle between vectors |
| `angle(v1, v2)` | Alias for angle_between |
| **Quaternions** | |
| `quaternion(w, x, y, z)` | Create quaternion |
| `quaternion.identity()` | Identity quaternion |
| `quaternion.from_euler(y, p, r)` | From Euler angles |
| `quaternion.from_axis_angle(axis, θ)` | From axis-angle |
| **Coordinate Conversions** | |
| `from_polar(r, θ)` | Polar to Cartesian (2D) |
| `from_spherical(r, θ, φ)` | Spherical to Cartesian (3D) |
| `from_cylindrical(ρ, φ, z)` | Cylindrical to Cartesian (3D) |
| **Shapes** | |
| `circle(center, r)` | Create circle |
| `circle(x, y, r)` | Create circle |
| `ellipse(center, a, b, [θ])` | Create ellipse |
| `ellipse(x, y, a, b, [θ])` | Create ellipse |
| `sphere(center, r)` | Create sphere |
| `sphere(x, y, z, r)` | Create sphere |
| **Transformations** | |
| `transform3d.identity()` | Identity matrix |
| `transform3d.translate(x, y, z)` | Translation matrix |
| `transform3d.rotate_x(θ)` | X-axis rotation |
| `transform3d.rotate_y(θ)` | Y-axis rotation |
| `transform3d.rotate_z(θ)` | Z-axis rotation |
| `transform3d.rotate_axis(axis, θ)` | Arbitrary axis rotation |
| `transform3d.scale(sx, sy, sz)` | Scale matrix |
| **Curve Fitting** | |
| `polyfit(pts, deg)` | Polynomial fitting |
| `cubic_spline(pts, [bc])` | Cubic spline interpolation |
| `bspline(deg, ctrl, knots)` | B-spline curve |
| `bspline_fit(pts, deg, n, [opt])` | Fit B-spline to points |
| `circle_fit(pts, [method])` | Fit circle |
| `ellipse_fit(pts, [method])` | Fit ellipse |
| `sphere_fit(pts, [method])` | Fit sphere |
| `fit(shape, pts, [opt])` | Unified fitting interface |
| **Geometric Algorithms** | |
| `convex_hull(points)` | Convex hull (2D) |
| `in_polygon(point, poly)` | Point in polygon test |
| `line_intersection(p1, p2, p3, p4)` | Line segment intersection |
| `area_triangle(p1, p2, p3)` | Triangle area |
| `centroid(points)` | Centroid of points |
| `circle_from_3_points(p1, p2, p3)` | Circle through 3 points |
| `plane_from_3_points(p1, p2, p3)` | Plane through 3 points |
| `point_plane_distance(pt, plane)` | Point-plane distance |
| `line_plane_intersection(p1, p2, pl)` | Line-plane intersection |
| `plane_plane_intersection(pl1, pl2)` | Plane-plane intersection |
| `intersection(...)` | Polymorphic intersection |
| `sphere_from_4_points(...)` | Sphere through 4 points |
