# Geometry Module

[← Module Index](index.md) | [Documentation](../index.md)

---

**Namespace:** `luaswift.geometry` | **Global:** `math.geo` (after extend_stdlib)

High-performance 2D/3D geometry operations using SIMD and Accelerate framework. Provides vector types, quaternions, transformations, curve fitting, and geometric algorithms.

## Function Reference

| Function | Description |
|----------|-------------|
| **Vector Operations** | |
| [vec2(x, y)](#vec2) | Create 2D vector |
| [vec3(x, y, z)](#vec3) | Create 3D vector |
| [distance(a, b)](#distance) | Euclidean distance |
| [angle_between(v1, v2)](#angle_between) | Angle between vectors |
| [angle(v1, v2)](#angle) | Alias for angle_between |
| **Quaternions** | |
| [quaternion(w, x, y, z)](#quaternion) | Create quaternion |
| [quaternion.identity()](#quaternion) | Identity quaternion |
| [quaternion.from_euler(y, p, r)](#quaternion) | From Euler angles |
| [quaternion.from_axis_angle(axis, θ)](#quaternion) | From axis-angle |
| **Coordinate Conversions** | |
| [from_polar(r, θ)](#from_polar) | Polar to Cartesian (2D) |
| [from_spherical(r, θ, φ)](#from_spherical) | Spherical to Cartesian (3D) |
| [from_cylindrical(ρ, φ, z)](#from_cylindrical) | Cylindrical to Cartesian (3D) |
| **Shapes** | |
| [circle(center, r)](#circle) | Create circle |
| [ellipse(center, a, b, θ?)](#ellipse) | Create ellipse |
| [sphere(center, r)](#sphere) | Create sphere |
| **Transformations** | |
| [transform3d.identity()](#transform3d) | Identity matrix |
| [transform3d.translate(x, y, z)](#transform3d) | Translation matrix |
| [transform3d.rotate_x(θ)](#transform3d) | X-axis rotation |
| [transform3d.rotate_y(θ)](#transform3d) | Y-axis rotation |
| [transform3d.rotate_z(θ)](#transform3d) | Z-axis rotation |
| [transform3d.rotate_axis(axis, θ)](#transform3d) | Arbitrary axis rotation |
| [transform3d.scale(sx, sy, sz)](#transform3d) | Scale matrix |
| **Curve Fitting** | |
| [polyfit(pts, deg)](#polyfit) | Polynomial fitting |
| [cubic_spline(pts, bc?)](#cubic_spline) | Cubic spline interpolation |
| [bspline(deg, ctrl, knots)](#bspline) | B-spline curve |
| [bspline_fit(pts, deg, n, opt?)](#bspline_fit) | Fit B-spline to points |
| [circle_fit(pts, method?)](#circle_fit) | Fit circle |
| [ellipse_fit(pts, method?)](#ellipse_fit) | Fit ellipse |
| [sphere_fit(pts, method?)](#sphere_fit) | Fit sphere |
| [fit(shape, pts, opt?)](#fit) | Unified fitting interface |
| **Geometric Algorithms** | |
| [convex_hull(points)](#convex_hull) | Convex hull (2D) |
| [in_polygon(point, poly)](#in_polygon) | Point in polygon test |
| [line_intersection(p1, p2, p3, p4)](#line_intersection) | Line segment intersection |
| [area_triangle(p1, p2, p3)](#area_triangle) | Triangle area |
| [centroid(points)](#centroid) | Centroid of points |
| [circle_from_3_points(p1, p2, p3)](#circle_from_3_points) | Circle through 3 points |
| [plane_from_3_points(p1, p2, p3)](#plane_from_3_points) | Plane through 3 points |
| [point_plane_distance(pt, plane)](#point_plane_distance) | Point-plane distance |
| [line_plane_intersection(p1, p2, pl)](#line_plane_intersection) | Line-plane intersection |
| [plane_plane_intersection(pl1, pl2)](#plane_plane_intersection) | Plane-plane intersection |
| [intersection(...)](#intersection) | Polymorphic intersection |
| [sphere_from_4_points(...)](#sphere_from_4_points) | Sphere through 4 points |

---

## vec2

```
geo.vec2(x, y) -> vec2
```

Create 2D vector with x, y components.

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

```lua
local v = geo.vec2(3, 4)
print(v:length())              -- 5.0
print(v:angle())               -- 0.9273 (atan2(4, 3))
local u = v:normalize()        -- vec2(0.6, 0.8)
local w = v:rotate(math.pi/2)  -- vec2(-4, 3)
```

---

## vec3

```
geo.vec3(x, y, z) -> vec3
```

Create 3D vector with x, y, z components.

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

```lua
local v1 = geo.vec3(1, 0, 0)
local v2 = geo.vec3(0, 1, 0)
local cross = v1:cross(v2)  -- vec3(0, 0, 1)
local axis = geo.vec3(0, 0, 1)
local rotated = v1:rotate(axis, math.pi/2)  -- vec3(0, 1, 0)
```

---

## quaternion

```
geo.quaternion(w, x, y, z) -> quaternion
geo.quaternion.identity() -> quaternion
geo.quaternion.from_euler(yaw, pitch, roll) -> quaternion
geo.quaternion.from_axis_angle(axis_vec3, angle) -> quaternion
```

Create quaternions for 3D rotations. Represented as `{w, x, y, z}` (scalar-first).

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

---

## from_polar

```
geo.from_polar(r, theta) -> vec2
```

Convert polar coordinates to Cartesian 2D vector.

**Parameters:**
- `r` - radius
- `theta` - angle in radians

```lua
local v = geo.from_polar(5, math.pi/4)  -- vec2(3.54, 3.54)
```

---

## from_spherical

```
geo.from_spherical(r, theta, phi) -> vec3
```

Convert spherical coordinates to Cartesian 3D vector.

**Parameters:**
- `r` - radius
- `theta` - azimuthal angle (radians)
- `phi` - polar angle (radians)

```lua
local v = geo.from_spherical(5, math.pi/4, math.pi/3)
```

---

## from_cylindrical

```
geo.from_cylindrical(rho, phi, z) -> vec3
```

Convert cylindrical coordinates to Cartesian 3D vector.

**Parameters:**
- `rho` - radial distance
- `phi` - azimuthal angle (radians)
- `z` - height

```lua
local v = geo.from_cylindrical(3, math.pi/2, 4)
```

---

## circle

```
geo.circle(center_vec2, radius) -> circle
geo.circle(x, y, radius) -> circle
```

Create circle shape.

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

```lua
local c = geo.circle(0, 0, 5)
print(c:area())           -- 78.54
print(c:contains(geo.vec2(3, 0)))  -- true
local p = c:point_at(0)   -- vec2(5, 0)
local c2 = c:translate(10, 10):scale(2)  -- chainable
```

---

## ellipse

```
geo.ellipse(center_vec2, semi_major, semi_minor, rotation?) -> ellipse
geo.ellipse(cx, cy, semi_major, semi_minor, rotation?) -> ellipse
```

Create ellipse shape.

**Properties:**
- `center` - center point (vec2)
- `semi_major` - semi-major axis
- `semi_minor` - semi-minor axis
- `rotation` - rotation angle (radians, default: 0)

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

```lua
local e = geo.ellipse(0, 0, 5, 3, math.pi/4)
print(e:area())           -- 47.12
print(e:eccentricity())   -- 0.8
local f1, f2 = e:foci()   -- focal points
```

---

## sphere

```
geo.sphere(center_vec3, radius) -> sphere
geo.sphere(cx, cy, cz, radius) -> sphere
```

Create sphere shape.

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

```lua
local s = geo.sphere(0, 0, 0, 5)
print(s:volume())         -- 523.6
local p = s:point_at(0, math.pi/2)  -- point on equator
```

---

## transform3d

```
geo.transform3d() -> transform3d
geo.transform3d.identity() -> transform3d
geo.transform3d.translate(x, y, z) -> transform3d
geo.transform3d.rotate_x(angle) -> transform3d
geo.transform3d.rotate_y(angle) -> transform3d
geo.transform3d.rotate_z(angle) -> transform3d
geo.transform3d.rotate_axis(axis_vec3, angle) -> transform3d
geo.transform3d.scale(sx, sy, sz) -> transform3d
```

4×4 transformation matrices for 3D graphics.

**Methods:**
- `t:apply(vec3)` - transform point
- `t:clone()` - create copy

**Operators:**
```lua
t1 * t2   -- matrix multiplication
```

```lua
local t = geo.transform3d.translate(10, 0, 0)
local r = geo.transform3d.rotate_y(math.pi/2)
local combined = t * r
local p = combined:apply(geo.vec3(1, 0, 0))
```

---

## polyfit

```
geo.polyfit(points, degree) -> polynomial
geo.polyfit(xs, ys, degree) -> polynomial
```

Polynomial fitting to data points.

**Parameters:**
- `points` - array of `{x, y}` tables or vec2
- `xs`, `ys` - separate arrays of x and y values
- `degree` - polynomial degree

**Returns:** Polynomial object with:
- `p:evaluate(x)` - evaluate at x
- `p:derivative()` - polynomial derivative
- `p:roots()` - find roots
- `p.degree` - polynomial degree
- `p.coefficients` - coefficient array

```lua
local points = {{0, 0}, {1, 1}, {2, 4}}
local p = geo.polyfit(points, 2)  -- quadratic fit
print(p:evaluate(3))  -- 9.0
print(p.degree)       -- 2
```

---

## cubic_spline

```
geo.cubic_spline(points, bc_type?) -> spline
geo.cubic_spline(xs, ys, bc_type?) -> spline
```

Cubic spline interpolation.

**Parameters:**
- `points` - array of `{x, y}` tables or vec2
- `xs`, `ys` - separate arrays of x and y values
- `bc_type` - boundary condition: `"natural"`, `"clamped"`, or `"not-a-knot"` (default: natural)

**Returns:** Spline object with:
- `s:evaluate(x)` - evaluate at x
- `s:evaluate_array(xs)` - batch evaluation
- `s:derivative()` - spline derivative
- `s:domain()` - domain `{min, max}`
- `s.knots` - knot points
- `s.values` - knot values
- `s.segments` - number of segments

```lua
local knots = {{0, 0}, {1, 1}, {2, 0}, {3, 1}}
local spline = geo.cubic_spline(knots)
print(spline:evaluate(1.5))  -- smooth interpolation
local deriv = spline:derivative()
```

---

## bspline

```
geo.bspline(degree, control_points, knots) -> bspline
```

Create B-spline curve with arbitrary control points.

**Parameters:**
- `degree` - spline degree
- `control_points` - array of vec2 or vec3 control points
- `knots` - knot vector

**Returns:** B-spline object with:
- `b:evaluate(t)` - evaluate at parameter t
- `b:sample(n)` - generate n points along curve
- `b:derivative()` - B-spline derivative
- `b:domain()` - parameter domain `{min, max}`
- `b.control_points` - control point array
- `b.degree` - spline degree

**Helper function:**
```lua
geo.bspline_uniform_knots(n_control, degree) -> knots
```

```lua
local ctrl = {geo.vec2(0, 0), geo.vec2(1, 2), geo.vec2(2, 0)}
local knots = geo.bspline_uniform_knots(3, 2)
local spline = geo.bspline(2, ctrl, knots)
local curve = spline:sample(50)
```

---

## bspline_fit

```
geo.bspline_fit(points, degree, n_control_points, options?) -> bspline
```

Fit B-spline curve to data points using least squares.

**Parameters:**
- `points` - array of vec2 or vec3 data points
- `degree` - spline degree
- `n_control_points` - number of control points
- `options` (optional) - table with:
  - `parameterization` - `"chord"` (default), `"uniform"`, or `"centripetal"`

**Returns:** B-spline object with additional fit diagnostics:
- `_residuals` - distance errors at each data point
- `_rmse` - root mean square error
- `_max_error` - maximum fitting error
- `_parameters` - parameter values assigned to data points

```lua
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

---

## circle_fit

```
geo.circle_fit(points, method?) -> circle
```

Fit circle to 2D points.

**Parameters:**
- `points` - array of vec2 points
- `method` - `"algebraic"` (default) or `"taubin"`

**Returns:** Circle object with fit diagnostics:
- `c:residuals()` - residual errors
- `c:rmse()` - root mean square error
- `c:fit_points()` - original points

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

---

## ellipse_fit

```
geo.ellipse_fit(points, method?) -> ellipse
```

Fit ellipse to 2D points using Fitzgibbon's direct method.

**Parameters:**
- `points` - array of vec2 points
- `method` - `"direct"` (Fitzgibbon's method)

**Returns:** Ellipse object with diagnostics:
- `e:residuals()` - residual errors
- `e:rmse()` - root mean square error
- `e:fit_conic()` - conic form coefficients

```lua
local pts = generate_noisy_ellipse_points()
local e = geo.ellipse_fit(pts)
print("Semi-axes:", e.semi_major, e.semi_minor)
print("Rotation:", e.rotation)
```

---

## sphere_fit

```
geo.sphere_fit(points, method?) -> sphere
```

Fit sphere to 3D points.

**Parameters:**
- `points` - array of vec3 points
- `method` - `"algebraic"`

**Returns:** Sphere object with diagnostics:
- `s:residuals()` - residual errors
- `s:rmse()` - root mean square error
- `s:max_error()` - maximum error

```lua
local points = generate_sphere_points()
local s = geo.sphere_fit(points)
print("Center:", s.center)
print("Radius:", s.radius)
```

---

## fit

```
geo.fit(shape, points, options?) -> shape_object
```

Unified interface for all curve fitting.

**Parameters:**
- `shape` - shape type: `"line"`, `"polynomial"`, `"circle"`, `"ellipse"`, `"sphere"`, `"spline"`, `"bspline"`
- `points` - array of data points
- `options` (optional) - shape-specific options:
  - `degree` - for `"polynomial"` and `"bspline"`
  - `n_control` - for `"bspline"`
  - `bc_type` - for `"spline"`
  - `method` - for `"circle"`, `"ellipse"`, `"sphere"`

```lua
-- All equivalent to specific functions
local circle = geo.fit("circle", points)
local poly = geo.fit("polynomial", points, {degree = 3})
local bspl = geo.fit("bspline", points, {degree = 3, n_control = 10})
```

---

## distance

```
geo.distance(obj1, obj2) -> number
```

Euclidean distance between vec2, vec3, or quaternion objects.

```lua
local v1 = geo.vec2(0, 0)
local v2 = geo.vec2(3, 4)
print(geo.distance(v1, v2))  -- 5.0
```

---

## angle_between

```
geo.angle_between(v1, v2) -> angle
```

Angle between two vectors in radians.

```lua
local v1 = geo.vec2(1, 0)
local v2 = geo.vec2(0, 1)
print(geo.angle_between(v1, v2))  -- π/2
```

---

## angle

```
geo.angle(v1, v2) -> angle
```

Alias for `angle_between`.

---

## convex_hull

```
geo.convex_hull(points) -> hull_points
```

Compute convex hull of 2D points using Graham scan algorithm.

**Parameters:**
- `points` - array of vec2 points

**Returns:** Array of vec2 points forming the convex hull (counterclockwise).

```lua
local points = {
    geo.vec2(0, 0),
    geo.vec2(1, 1),
    geo.vec2(2, 0),
    geo.vec2(1, 0.5)
}
local hull = geo.convex_hull(points)
```

---

## in_polygon

```
geo.in_polygon(point, polygon) -> boolean
```

Test if point is inside polygon using ray casting algorithm.

**Parameters:**
- `point` - vec2 point
- `polygon` - array of vec2 vertices

```lua
local poly = {geo.vec2(0, 0), geo.vec2(2, 0), geo.vec2(1, 2)}
local inside = geo.in_polygon(geo.vec2(1, 0.5), poly)  -- true
```

---

## line_intersection

```
geo.line_intersection(p1, p2, p3, p4) -> point | nil
```

Find intersection of line segments (p1-p2) and (p3-p4).

**Parameters:**
- `p1`, `p2` - vec2 endpoints of first segment
- `p3`, `p4` - vec2 endpoints of second segment

**Returns:** vec2 intersection point or nil if segments don't intersect.

```lua
local p = geo.line_intersection(
    geo.vec2(0, 0), geo.vec2(2, 2),
    geo.vec2(0, 2), geo.vec2(2, 0)
)  -- vec2(1, 1)
```

---

## area_triangle

```
geo.area_triangle(p1, p2, p3) -> area
```

Signed area of triangle (positive = counterclockwise).

**Parameters:**
- `p1`, `p2`, `p3` - vec2 triangle vertices

```lua
local area = geo.area_triangle(
    geo.vec2(0, 0),
    geo.vec2(2, 0),
    geo.vec2(1, 2)
)  -- 2.0
```

---

## centroid

```
geo.centroid(points) -> center
```

Geometric centroid of points.

**Parameters:**
- `points` - array of vec2 or vec3 points

**Returns:** vec2 or vec3 centroid point.

```lua
local points = {geo.vec2(0, 0), geo.vec2(2, 0), geo.vec2(1, 2)}
local center = geo.centroid(points)  -- vec2(1, 0.67)
```

---

## circle_from_3_points

```
geo.circle_from_3_points(p1, p2, p3) -> circle | nil
```

Exact circle through three non-collinear points.

**Parameters:**
- `p1`, `p2`, `p3` - vec2 points

**Returns:** Circle object or nil if points are collinear.

```lua
local c = geo.circle_from_3_points(
    geo.vec2(1, 0),
    geo.vec2(0, 1),
    geo.vec2(-1, 0)
)
print(c.center, c.radius)
```

---

## plane_from_3_points

```
geo.plane_from_3_points(p1, p2, p3) -> {normal, d}
```

Plane through three non-collinear 3D points.

**Parameters:**
- `p1`, `p2`, `p3` - vec3 points

**Returns:** Plane representation `{normal_vec3, d}` where `normal·x = d`.

```lua
local plane = geo.plane_from_3_points(
    geo.vec3(1, 0, 0),
    geo.vec3(0, 1, 0),
    geo.vec3(0, 0, 1)
)
```

---

## point_plane_distance

```
geo.point_plane_distance(point, plane) -> distance
```

Signed distance from point to plane.

**Parameters:**
- `point` - vec3 point
- `plane` - plane `{normal_vec3, d}`

**Returns:** Signed distance (positive = same side as normal).

```lua
local plane = {geo.vec3(0, 0, 1), 0}  -- xy-plane
local dist = geo.point_plane_distance(geo.vec3(0, 0, 5), plane)  -- 5.0
```

---

## line_plane_intersection

```
geo.line_plane_intersection(p1, p2, plane) -> point | nil
```

Find intersection of line segment with plane.

**Parameters:**
- `p1`, `p2` - vec3 endpoints of line segment
- `plane` - plane `{normal_vec3, d}`

**Returns:** vec3 intersection point or nil if parallel/no intersection.

```lua
local plane = {geo.vec3(0, 0, 1), 0}
local hit = geo.line_plane_intersection(
    geo.vec3(0, 0, -5),
    geo.vec3(0, 0, 5),
    plane
)  -- vec3(0, 0, 0)
```

---

## plane_plane_intersection

```
geo.plane_plane_intersection(plane1, plane2) -> {point, direction} | nil
```

Find intersection line of two planes.

**Parameters:**
- `plane1`, `plane2` - planes `{normal_vec3, d}`

**Returns:** Table `{point, direction}` where point is vec3 on the line and direction is vec3 line direction, or nil if planes are parallel.

```lua
local pl1 = {geo.vec3(1, 0, 0), 0}
local pl2 = {geo.vec3(0, 1, 0), 0}
local line = geo.plane_plane_intersection(pl1, pl2)
-- line.point, line.direction
```

---

## intersection

```
geo.intersection(obj1, obj2, obj3?, obj4?) -> result | nil
```

Polymorphic intersection based on argument types.

**Supported combinations:**
- 4 vec2: line-line intersection → vec2 or nil
- 2 vec3 + plane: line-plane intersection → vec3 or nil
- 2 planes: plane-plane intersection → `{point, direction}` or nil

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

---

## sphere_from_4_points

```
geo.sphere_from_4_points(p1, p2, p3, p4) -> sphere | nil
```

Exact sphere through four non-coplanar points.

**Parameters:**
- `p1`, `p2`, `p3`, `p4` - vec3 points

**Returns:** Sphere object or nil if points are coplanar.

```lua
local s = geo.sphere_from_4_points(
    geo.vec3(1, 0, 0),
    geo.vec3(0, 1, 0),
    geo.vec3(0, 0, 1),
    geo.vec3(-1, 0, 0)
)
print(s.center, s.radius)
```

---

## Examples

### Quick Start

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
