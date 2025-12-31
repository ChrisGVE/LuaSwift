-- geometry.lua - 2D/3D Geometry Module for Lua 5.4.7
-- Copyright (c) 2025 LuaSwift Project
-- Licensed under the MIT License
--
-- A pure Lua module for 2D and 3D geometric operations.
-- Includes vectors, transformations, and quaternions.
-- Designed for educational apps on iOS/macOS via LuaSwift wrapper.

local geo = {}

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

local function isNumber(x)
    return type(x) == "number"
end

local function assertNumber(x, name)
    if not isNumber(x) then
        error(name .. " must be a number, got " .. type(x), 3)
    end
end

local function clamp(x, minVal, maxVal)
    return math.max(minVal, math.min(maxVal, x))
end

local EPSILON = 1e-10

local function nearZero(x)
    return math.abs(x) < EPSILON
end

--------------------------------------------------------------------------------
-- 2D Vector
--------------------------------------------------------------------------------

local Vec2 = {}
Vec2.__index = Vec2

function geo.vec2(x, y)
    assertNumber(x, "x")
    assertNumber(y, "y")
    return setmetatable({x = x, y = y}, Vec2)
end

function Vec2:__tostring()
    return string.format("vec2(%.6g, %.6g)", self.x, self.y)
end

function Vec2:__eq(other)
    return self.x == other.x and self.y == other.y
end

function Vec2:__add(other)
    return geo.vec2(self.x + other.x, self.y + other.y)
end

function Vec2:__sub(other)
    return geo.vec2(self.x - other.x, self.y - other.y)
end

function Vec2:__mul(scalar)
    if isNumber(scalar) then
        return geo.vec2(self.x * scalar, self.y * scalar)
    elseif isNumber(self) then
        return geo.vec2(self * other.x, self * other.y)
    else
        error("vec2 can only be multiplied by a scalar", 2)
    end
end

function Vec2:__div(scalar)
    assertNumber(scalar, "divisor")
    if nearZero(scalar) then
        error("Division by zero", 2)
    end
    return geo.vec2(self.x / scalar, self.y / scalar)
end

function Vec2:__unm()
    return geo.vec2(-self.x, -self.y)
end

function Vec2:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vec2:lengthSquared()
    return self.x * self.x + self.y * self.y
end

function Vec2:normalize()
    local len = self:length()
    if nearZero(len) then
        return geo.vec2(0, 0)
    end
    return geo.vec2(self.x / len, self.y / len)
end

function Vec2:dot(other)
    return self.x * other.x + self.y * other.y
end

-- Cross product for 2D returns scalar (z-component of 3D cross product)
function Vec2:cross(other)
    return self.x * other.y - self.y * other.x
end

function Vec2:angle()
    return math.atan(self.y, self.x)
end

function Vec2:rotate(theta)
    assertNumber(theta, "theta")
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    return geo.vec2(
        self.x * cosT - self.y * sinT,
        self.x * sinT + self.y * cosT
    )
end

function Vec2:lerp(other, t)
    assertNumber(t, "t")
    return geo.vec2(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t
    )
end

function Vec2:project(other)
    local dotProduct = self:dot(other)
    local lenSq = other:lengthSquared()
    if nearZero(lenSq) then
        return geo.vec2(0, 0)
    end
    local scalar = dotProduct / lenSq
    return geo.vec2(other.x * scalar, other.y * scalar)
end

function Vec2:reflect(normal)
    local d = 2 * self:dot(normal)
    return geo.vec2(self.x - d * normal.x, self.y - d * normal.y)
end

function Vec2:perpendicular()
    return geo.vec2(-self.y, self.x)
end

function Vec2:clone()
    return geo.vec2(self.x, self.y)
end

--------------------------------------------------------------------------------
-- 3D Vector
--------------------------------------------------------------------------------

local Vec3 = {}
Vec3.__index = Vec3

function geo.vec3(x, y, z)
    assertNumber(x, "x")
    assertNumber(y, "y")
    assertNumber(z, "z")
    return setmetatable({x = x, y = y, z = z}, Vec3)
end

function Vec3:__tostring()
    return string.format("vec3(%.6g, %.6g, %.6g)", self.x, self.y, self.z)
end

function Vec3:__eq(other)
    return self.x == other.x and self.y == other.y and self.z == other.z
end

function Vec3:__add(other)
    return geo.vec3(self.x + other.x, self.y + other.y, self.z + other.z)
end

function Vec3:__sub(other)
    return geo.vec3(self.x - other.x, self.y - other.y, self.z - other.z)
end

function Vec3:__mul(scalar)
    if isNumber(scalar) then
        return geo.vec3(self.x * scalar, self.y * scalar, self.z * scalar)
    elseif isNumber(self) then
        return geo.vec3(self * other.x, self * other.y, self * other.z)
    else
        error("vec3 can only be multiplied by a scalar", 2)
    end
end

function Vec3:__div(scalar)
    assertNumber(scalar, "divisor")
    if nearZero(scalar) then
        error("Division by zero", 2)
    end
    return geo.vec3(self.x / scalar, self.y / scalar, self.z / scalar)
end

function Vec3:__unm()
    return geo.vec3(-self.x, -self.y, -self.z)
end

function Vec3:length()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function Vec3:lengthSquared()
    return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vec3:normalize()
    local len = self:length()
    if nearZero(len) then
        return geo.vec3(0, 0, 0)
    end
    return geo.vec3(self.x / len, self.y / len, self.z / len)
end

function Vec3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

-- Cross product for 3D returns a vector
function Vec3:cross(other)
    return geo.vec3(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

function Vec3:angle()
    -- Returns azimuthal angle (phi) and polar angle (theta)
    local r = self:length()
    if nearZero(r) then
        return 0, 0
    end
    local theta = math.acos(clamp(self.z / r, -1, 1))
    local phi = math.atan(self.y, self.x)
    return phi, theta
end

function Vec3:rotate(axis, theta)
    -- Rodrigues' rotation formula
    assertNumber(theta, "theta")
    local k = axis:normalize()
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)
    local dotKV = k:dot(self)
    local crossKV = k:cross(self)

    return geo.vec3(
        self.x * cosT + crossKV.x * sinT + k.x * dotKV * (1 - cosT),
        self.y * cosT + crossKV.y * sinT + k.y * dotKV * (1 - cosT),
        self.z * cosT + crossKV.z * sinT + k.z * dotKV * (1 - cosT)
    )
end

function Vec3:lerp(other, t)
    assertNumber(t, "t")
    return geo.vec3(
        self.x + (other.x - self.x) * t,
        self.y + (other.y - self.y) * t,
        self.z + (other.z - self.z) * t
    )
end

function Vec3:project(other)
    local dotProduct = self:dot(other)
    local lenSq = other:lengthSquared()
    if nearZero(lenSq) then
        return geo.vec3(0, 0, 0)
    end
    local scalar = dotProduct / lenSq
    return geo.vec3(other.x * scalar, other.y * scalar, other.z * scalar)
end

function Vec3:reflect(normal)
    local d = 2 * self:dot(normal)
    return geo.vec3(
        self.x - d * normal.x,
        self.y - d * normal.y,
        self.z - d * normal.z
    )
end

function Vec3:clone()
    return geo.vec3(self.x, self.y, self.z)
end

--------------------------------------------------------------------------------
-- 2D Geometry Functions
--------------------------------------------------------------------------------

function geo.distance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    local dz = (p2.z or 0) - (p1.z or 0)
    if p1.z or p2.z then
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    return math.sqrt(dx * dx + dy * dy)
end

function geo.angle(p1, p2, p3)
    -- Angle at p2 formed by p1-p2-p3
    local v1 = geo.vec2(p1.x - p2.x, p1.y - p2.y)
    local v2 = geo.vec2(p3.x - p2.x, p3.y - p2.y)

    local dot = v1:dot(v2)
    local len1 = v1:length()
    local len2 = v2:length()

    if nearZero(len1) or nearZero(len2) then
        return 0
    end

    local cosAngle = clamp(dot / (len1 * len2), -1, 1)
    return math.acos(cosAngle)
end

function geo.area_triangle(p1, p2, p3)
    -- Using cross product formula
    local v1x = p2.x - p1.x
    local v1y = p2.y - p1.y
    local v2x = p3.x - p1.x
    local v2y = p3.y - p1.y
    return math.abs(v1x * v2y - v1y * v2x) / 2
end

function geo.centroid(points)
    if #points == 0 then
        return nil
    end

    local sumX, sumY, sumZ = 0, 0, 0
    local has3D = false

    for _, p in ipairs(points) do
        sumX = sumX + p.x
        sumY = sumY + p.y
        if p.z then
            has3D = true
            sumZ = sumZ + p.z
        end
    end

    local n = #points
    if has3D then
        return geo.vec3(sumX / n, sumY / n, sumZ / n)
    end
    return geo.vec2(sumX / n, sumY / n)
end

function geo.point_in_polygon(point, polygon)
    -- Ray casting algorithm
    local x, y = point.x, point.y
    local n = #polygon
    local inside = false

    local j = n
    for i = 1, n do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > y) ~= (yj > y)) and
           (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

function geo.line_intersection(l1, l2)
    -- l1 and l2 are tables with {p1, p2} or {start, finish} or {x1,y1,x2,y2}
    local x1, y1, x2, y2, x3, y3, x4, y4

    -- Support different line formats
    if l1.p1 then
        x1, y1 = l1.p1.x, l1.p1.y
        x2, y2 = l1.p2.x, l1.p2.y
    elseif l1[1] and type(l1[1]) == "table" then
        x1, y1 = l1[1].x, l1[1].y
        x2, y2 = l1[2].x, l1[2].y
    else
        x1, y1, x2, y2 = l1.x1 or l1[1], l1.y1 or l1[2], l1.x2 or l1[3], l1.y2 or l1[4]
    end

    if l2.p1 then
        x3, y3 = l2.p1.x, l2.p1.y
        x4, y4 = l2.p2.x, l2.p2.y
    elseif l2[1] and type(l2[1]) == "table" then
        x3, y3 = l2[1].x, l2[1].y
        x4, y4 = l2[2].x, l2[2].y
    else
        x3, y3, x4, y4 = l2.x1 or l2[1], l2.y1 or l2[2], l2.x2 or l2[3], l2.y2 or l2[4]
    end

    local denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)

    if nearZero(denom) then
        return nil  -- Lines are parallel
    end

    local t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom

    local px = x1 + t * (x2 - x1)
    local py = y1 + t * (y2 - y1)

    return geo.vec2(px, py)
end

function geo.convex_hull(points)
    -- Graham scan algorithm
    if #points < 3 then
        return points
    end

    -- Find the point with lowest y (and leftmost if tie)
    local start = 1
    for i = 2, #points do
        if points[i].y < points[start].y or
           (points[i].y == points[start].y and points[i].x < points[start].x) then
            start = i
        end
    end

    local pivot = points[start]

    -- Sort points by polar angle with respect to pivot
    local sorted = {}
    for i, p in ipairs(points) do
        if i ~= start then
            table.insert(sorted, p)
        end
    end

    table.sort(sorted, function(a, b)
        local angleA = math.atan(a.y - pivot.y, a.x - pivot.x)
        local angleB = math.atan(b.y - pivot.y, b.x - pivot.x)
        if math.abs(angleA - angleB) < EPSILON then
            local distA = (a.x - pivot.x)^2 + (a.y - pivot.y)^2
            local distB = (b.x - pivot.x)^2 + (b.y - pivot.y)^2
            return distA < distB
        end
        return angleA < angleB
    end)

    -- Build hull
    local hull = {pivot}

    for _, p in ipairs(sorted) do
        while #hull >= 2 do
            local v1 = geo.vec2(
                hull[#hull].x - hull[#hull - 1].x,
                hull[#hull].y - hull[#hull - 1].y
            )
            local v2 = geo.vec2(
                p.x - hull[#hull].x,
                p.y - hull[#hull].y
            )
            if v1:cross(v2) <= 0 then
                table.remove(hull)
            else
                break
            end
        end
        table.insert(hull, p)
    end

    return hull
end

function geo.circle_from_3_points(p1, p2, p3)
    -- Calculate circumcircle of triangle
    local ax, ay = p1.x, p1.y
    local bx, by = p2.x, p2.y
    local cx, cy = p3.x, p3.y

    local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))

    if nearZero(d) then
        return nil  -- Points are collinear
    end

    local aSq = ax * ax + ay * ay
    local bSq = bx * bx + by * by
    local cSq = cx * cx + cy * cy

    local centerX = (aSq * (by - cy) + bSq * (cy - ay) + cSq * (ay - by)) / d
    local centerY = (aSq * (cx - bx) + bSq * (ax - cx) + cSq * (bx - ax)) / d

    local radius = math.sqrt((ax - centerX)^2 + (ay - centerY)^2)

    return {
        center = geo.vec2(centerX, centerY),
        radius = radius
    }
end

--------------------------------------------------------------------------------
-- 2D Transformation Matrix
--------------------------------------------------------------------------------

local Transform2D = {}
Transform2D.__index = Transform2D

function geo.transform2d()
    -- Create identity matrix [a b tx; c d ty; 0 0 1]
    -- Stored as {a, b, c, d, tx, ty}
    return setmetatable({
        a = 1, b = 0,
        c = 0, d = 1,
        tx = 0, ty = 0
    }, Transform2D)
end

function Transform2D:__tostring()
    return string.format("transform2d([%.4g, %.4g, %.4g], [%.4g, %.4g, %.4g])",
        self.a, self.b, self.tx, self.c, self.d, self.ty)
end

function Transform2D:clone()
    local t = geo.transform2d()
    t.a, t.b = self.a, self.b
    t.c, t.d = self.c, self.d
    t.tx, t.ty = self.tx, self.ty
    return t
end

function Transform2D:translate(dx, dy)
    assertNumber(dx, "dx")
    assertNumber(dy, "dy")
    self.tx = self.tx + self.a * dx + self.b * dy
    self.ty = self.ty + self.c * dx + self.d * dy
    return self
end

function Transform2D:rotate(theta)
    assertNumber(theta, "theta")
    local cosT = math.cos(theta)
    local sinT = math.sin(theta)

    local a = self.a * cosT + self.b * sinT
    local b = self.a * (-sinT) + self.b * cosT
    local c = self.c * cosT + self.d * sinT
    local d = self.c * (-sinT) + self.d * cosT

    self.a, self.b = a, b
    self.c, self.d = c, d
    return self
end

function Transform2D:scale(sx, sy)
    assertNumber(sx, "sx")
    sy = sy or sx
    assertNumber(sy, "sy")

    self.a = self.a * sx
    self.b = self.b * sy
    self.c = self.c * sx
    self.d = self.d * sy
    return self
end

function Transform2D:apply(point)
    local x = self.a * point.x + self.b * point.y + self.tx
    local y = self.c * point.x + self.d * point.y + self.ty
    return geo.vec2(x, y)
end

function Transform2D:multiply(other)
    local result = geo.transform2d()
    result.a = self.a * other.a + self.b * other.c
    result.b = self.a * other.b + self.b * other.d
    result.c = self.c * other.a + self.d * other.c
    result.d = self.c * other.b + self.d * other.d
    result.tx = self.a * other.tx + self.b * other.ty + self.tx
    result.ty = self.c * other.tx + self.d * other.ty + self.ty
    return result
end

function Transform2D:inverse()
    local det = self.a * self.d - self.b * self.c
    if nearZero(det) then
        return nil
    end

    local result = geo.transform2d()
    result.a = self.d / det
    result.b = -self.b / det
    result.c = -self.c / det
    result.d = self.a / det
    result.tx = (self.b * self.ty - self.d * self.tx) / det
    result.ty = (self.c * self.tx - self.a * self.ty) / det
    return result
end

--------------------------------------------------------------------------------
-- Quaternion (for 3D rotations)
--------------------------------------------------------------------------------

local Quaternion = {}
Quaternion.__index = Quaternion

function geo.quaternion(w, x, y, z)
    assertNumber(w, "w")
    assertNumber(x, "x")
    assertNumber(y, "y")
    assertNumber(z, "z")
    return setmetatable({w = w, x = x, y = y, z = z}, Quaternion)
end

geo.quaternion.identity = function()
    return geo.quaternion(1, 0, 0, 0)
end

geo.quaternion.from_euler = function(yaw, pitch, roll)
    -- Yaw (Z), Pitch (Y), Roll (X) - in radians
    assertNumber(yaw, "yaw")
    assertNumber(pitch, "pitch")
    assertNumber(roll, "roll")

    local cy = math.cos(yaw * 0.5)
    local sy = math.sin(yaw * 0.5)
    local cp = math.cos(pitch * 0.5)
    local sp = math.sin(pitch * 0.5)
    local cr = math.cos(roll * 0.5)
    local sr = math.sin(roll * 0.5)

    return geo.quaternion(
        cr * cp * cy + sr * sp * sy,
        sr * cp * cy - cr * sp * sy,
        cr * sp * cy + sr * cp * sy,
        cr * cp * sy - sr * sp * cy
    )
end

geo.quaternion.from_axis_angle = function(axis, angle)
    assertNumber(angle, "angle")
    local normAxis = axis:normalize()
    local halfAngle = angle * 0.5
    local s = math.sin(halfAngle)

    return geo.quaternion(
        math.cos(halfAngle),
        normAxis.x * s,
        normAxis.y * s,
        normAxis.z * s
    )
end

function Quaternion:__tostring()
    return string.format("quaternion(%.6g, %.6g, %.6g, %.6g)",
        self.w, self.x, self.y, self.z)
end

function Quaternion:__eq(other)
    return self.w == other.w and self.x == other.x and
           self.y == other.y and self.z == other.z
end

function Quaternion:__mul(other)
    if getmetatable(other) == Quaternion then
        -- Quaternion multiplication (Hamilton product)
        return geo.quaternion(
            self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
            self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
            self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
            self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w
        )
    elseif isNumber(other) then
        return geo.quaternion(
            self.w * other,
            self.x * other,
            self.y * other,
            self.z * other
        )
    else
        error("Quaternion can only be multiplied by quaternion or scalar", 2)
    end
end

function Quaternion:__add(other)
    return geo.quaternion(
        self.w + other.w,
        self.x + other.x,
        self.y + other.y,
        self.z + other.z
    )
end

function Quaternion:__sub(other)
    return geo.quaternion(
        self.w - other.w,
        self.x - other.x,
        self.y - other.y,
        self.z - other.z
    )
end

function Quaternion:__unm()
    return geo.quaternion(-self.w, -self.x, -self.y, -self.z)
end

function Quaternion:length()
    return math.sqrt(self.w * self.w + self.x * self.x +
                     self.y * self.y + self.z * self.z)
end

function Quaternion:lengthSquared()
    return self.w * self.w + self.x * self.x +
           self.y * self.y + self.z * self.z
end

function Quaternion:normalize()
    local len = self:length()
    if nearZero(len) then
        return geo.quaternion(1, 0, 0, 0)
    end
    return geo.quaternion(
        self.w / len,
        self.x / len,
        self.y / len,
        self.z / len
    )
end

function Quaternion:conjugate()
    return geo.quaternion(self.w, -self.x, -self.y, -self.z)
end

function Quaternion:inverse()
    local lenSq = self:lengthSquared()
    if nearZero(lenSq) then
        return geo.quaternion(1, 0, 0, 0)
    end
    local conj = self:conjugate()
    return geo.quaternion(
        conj.w / lenSq,
        conj.x / lenSq,
        conj.y / lenSq,
        conj.z / lenSq
    )
end

function Quaternion:rotate(vec)
    -- Rotate a vec3 by this quaternion
    -- v' = q * v * q^-1
    local qv = geo.quaternion(0, vec.x, vec.y, vec.z)
    local result = self * qv * self:inverse()
    return geo.vec3(result.x, result.y, result.z)
end

function Quaternion:slerp(other, t)
    assertNumber(t, "t")

    local dot = self.w * other.w + self.x * other.x +
                self.y * other.y + self.z * other.z

    -- Handle negative dot (take shorter path)
    local q2 = other
    if dot < 0 then
        dot = -dot
        q2 = -other
    end

    -- Clamp dot to avoid numerical issues with acos
    dot = clamp(dot, -1, 1)

    local theta = math.acos(dot)

    if nearZero(theta) then
        return self:clone()
    end

    local sinTheta = math.sin(theta)
    local w1 = math.sin((1 - t) * theta) / sinTheta
    local w2 = math.sin(t * theta) / sinTheta

    return geo.quaternion(
        self.w * w1 + q2.w * w2,
        self.x * w1 + q2.x * w2,
        self.y * w1 + q2.y * w2,
        self.z * w1 + q2.z * w2
    )
end

function Quaternion:to_euler()
    -- Returns yaw, pitch, roll
    local sinr_cosp = 2 * (self.w * self.x + self.y * self.z)
    local cosr_cosp = 1 - 2 * (self.x * self.x + self.y * self.y)
    local roll = math.atan(sinr_cosp, cosr_cosp)

    local sinp = 2 * (self.w * self.y - self.z * self.x)
    local pitch
    if math.abs(sinp) >= 1 then
        pitch = (sinp >= 0 and 1 or -1) * math.pi / 2
    else
        pitch = math.asin(sinp)
    end

    local siny_cosp = 2 * (self.w * self.z + self.x * self.y)
    local cosy_cosp = 1 - 2 * (self.y * self.y + self.z * self.z)
    local yaw = math.atan(siny_cosp, cosy_cosp)

    return yaw, pitch, roll
end

function Quaternion:to_axis_angle()
    local q = self:normalize()
    local angle = 2 * math.acos(clamp(q.w, -1, 1))
    local s = math.sqrt(1 - q.w * q.w)

    if nearZero(s) then
        return geo.vec3(1, 0, 0), 0
    end

    return geo.vec3(q.x / s, q.y / s, q.z / s), angle
end

function Quaternion:to_matrix()
    -- Returns 3x3 rotation matrix as table of tables
    local q = self:normalize()
    local w, x, y, z = q.w, q.x, q.y, q.z

    local xx = x * x
    local xy = x * y
    local xz = x * z
    local xw = x * w
    local yy = y * y
    local yz = y * z
    local yw = y * w
    local zz = z * z
    local zw = z * w

    return {
        {1 - 2 * (yy + zz), 2 * (xy - zw), 2 * (xz + yw)},
        {2 * (xy + zw), 1 - 2 * (xx + zz), 2 * (yz - xw)},
        {2 * (xz - yw), 2 * (yz + xw), 1 - 2 * (xx + yy)}
    }
end

function Quaternion:clone()
    return geo.quaternion(self.w, self.x, self.y, self.z)
end

function Quaternion:dot(other)
    return self.w * other.w + self.x * other.x +
           self.y * other.y + self.z * other.z
end

--------------------------------------------------------------------------------
-- 3D Geometry Functions
--------------------------------------------------------------------------------

function geo.plane_from_3_points(p1, p2, p3)
    -- Returns plane as {normal, d} where normal.x*x + normal.y*y + normal.z*z + d = 0
    local v1 = geo.vec3(p2.x - p1.x, p2.y - p1.y, p2.z - p1.z)
    local v2 = geo.vec3(p3.x - p1.x, p3.y - p1.y, p3.z - p1.z)

    local normal = v1:cross(v2):normalize()
    local d = -(normal.x * p1.x + normal.y * p1.y + normal.z * p1.z)

    return {normal = normal, d = d}
end

function geo.point_plane_distance(point, plane)
    return math.abs(
        plane.normal.x * point.x +
        plane.normal.y * point.y +
        plane.normal.z * point.z +
        plane.d
    )
end

function geo.line_plane_intersection(line, plane)
    -- line = {point, direction} or {p1, p2}
    local p, dir
    if line.point and line.direction then
        p = line.point
        dir = line.direction
    else
        p = line.p1 or line[1]
        local p2 = line.p2 or line[2]
        dir = geo.vec3(p2.x - p.x, p2.y - p.y, p2.z - p.z)
    end

    local denom = plane.normal:dot(dir)
    if nearZero(denom) then
        return nil  -- Line is parallel to plane
    end

    local t = -(plane.normal.x * p.x + plane.normal.y * p.y +
               plane.normal.z * p.z + plane.d) / denom

    return geo.vec3(
        p.x + t * dir.x,
        p.y + t * dir.y,
        p.z + t * dir.z
    )
end

function geo.sphere_from_4_points(p1, p2, p3, p4)
    -- Calculate circumsphere of tetrahedron
    -- Using determinant method
    local a = {
        {p1.x, p1.y, p1.z, 1},
        {p2.x, p2.y, p2.z, 1},
        {p3.x, p3.y, p3.z, 1},
        {p4.x, p4.y, p4.z, 1}
    }

    -- Calculate 4x4 determinant (helper)
    local function det4(m)
        local result = 0
        for i = 1, 4 do
            local sub = {}
            for j = 2, 4 do
                local row = {}
                for k = 1, 4 do
                    if k ~= i then
                        table.insert(row, m[j][k])
                    end
                end
                table.insert(sub, row)
            end
            local sign = (i % 2 == 1) and 1 or -1
            result = result + sign * m[1][i] * (
                sub[1][1] * (sub[2][2] * sub[3][3] - sub[2][3] * sub[3][2]) -
                sub[1][2] * (sub[2][1] * sub[3][3] - sub[2][3] * sub[3][1]) +
                sub[1][3] * (sub[2][1] * sub[3][2] - sub[2][2] * sub[3][1])
            )
        end
        return result
    end

    local d = det4(a)
    if nearZero(d) then
        return nil  -- Points are coplanar
    end

    local sq1 = p1.x^2 + p1.y^2 + p1.z^2
    local sq2 = p2.x^2 + p2.y^2 + p2.z^2
    local sq3 = p3.x^2 + p3.y^2 + p3.z^2
    local sq4 = p4.x^2 + p4.y^2 + p4.z^2

    local dx = det4({
        {sq1, p1.y, p1.z, 1},
        {sq2, p2.y, p2.z, 1},
        {sq3, p3.y, p3.z, 1},
        {sq4, p4.y, p4.z, 1}
    })

    local dy = -det4({
        {sq1, p1.x, p1.z, 1},
        {sq2, p2.x, p2.z, 1},
        {sq3, p3.x, p3.z, 1},
        {sq4, p4.x, p4.z, 1}
    })

    local dz = det4({
        {sq1, p1.x, p1.y, 1},
        {sq2, p2.x, p2.y, 1},
        {sq3, p3.x, p3.y, 1},
        {sq4, p4.x, p4.y, 1}
    })

    local centerX = dx / (2 * d)
    local centerY = dy / (2 * d)
    local centerZ = dz / (2 * d)

    local radius = math.sqrt(
        (p1.x - centerX)^2 + (p1.y - centerY)^2 + (p1.z - centerZ)^2
    )

    return {
        center = geo.vec3(centerX, centerY, centerZ),
        radius = radius
    }
end

--------------------------------------------------------------------------------
-- 3D Transformation Matrix
--------------------------------------------------------------------------------

local Transform3D = {}
Transform3D.__index = Transform3D

function geo.transform3d()
    -- Create 4x4 identity matrix stored as flat array
    return setmetatable({
        m = {
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        }
    }, Transform3D)
end

function Transform3D:__tostring()
    local m = self.m
    return string.format(
        "transform3d(\n  [%.4g, %.4g, %.4g, %.4g]\n  [%.4g, %.4g, %.4g, %.4g]\n  [%.4g, %.4g, %.4g, %.4g]\n  [%.4g, %.4g, %.4g, %.4g])",
        m[1], m[2], m[3], m[4],
        m[5], m[6], m[7], m[8],
        m[9], m[10], m[11], m[12],
        m[13], m[14], m[15], m[16]
    )
end

function Transform3D:clone()
    local t = geo.transform3d()
    for i = 1, 16 do
        t.m[i] = self.m[i]
    end
    return t
end

function Transform3D:translate(dx, dy, dz)
    assertNumber(dx, "dx")
    assertNumber(dy, "dy")
    assertNumber(dz, "dz")

    -- Multiply by translation matrix
    local m = self.m
    m[4] = m[1] * dx + m[2] * dy + m[3] * dz + m[4]
    m[8] = m[5] * dx + m[6] * dy + m[7] * dz + m[8]
    m[12] = m[9] * dx + m[10] * dy + m[11] * dz + m[12]
    m[16] = m[13] * dx + m[14] * dy + m[15] * dz + m[16]

    return self
end

function Transform3D:rotate_x(theta)
    assertNumber(theta, "theta")
    local c = math.cos(theta)
    local s = math.sin(theta)
    local m = self.m

    local m2, m3 = m[2], m[3]
    local m6, m7 = m[6], m[7]
    local m10, m11 = m[10], m[11]
    local m14, m15 = m[14], m[15]

    m[2] = m2 * c + m3 * s
    m[3] = m2 * (-s) + m3 * c
    m[6] = m6 * c + m7 * s
    m[7] = m6 * (-s) + m7 * c
    m[10] = m10 * c + m11 * s
    m[11] = m10 * (-s) + m11 * c
    m[14] = m14 * c + m15 * s
    m[15] = m14 * (-s) + m15 * c

    return self
end

function Transform3D:rotate_y(theta)
    assertNumber(theta, "theta")
    local c = math.cos(theta)
    local s = math.sin(theta)
    local m = self.m

    local m1, m3 = m[1], m[3]
    local m5, m7 = m[5], m[7]
    local m9, m11 = m[9], m[11]
    local m13, m15 = m[13], m[15]

    m[1] = m1 * c + m3 * (-s)
    m[3] = m1 * s + m3 * c
    m[5] = m5 * c + m7 * (-s)
    m[7] = m5 * s + m7 * c
    m[9] = m9 * c + m11 * (-s)
    m[11] = m9 * s + m11 * c
    m[13] = m13 * c + m15 * (-s)
    m[15] = m13 * s + m15 * c

    return self
end

function Transform3D:rotate_z(theta)
    assertNumber(theta, "theta")
    local c = math.cos(theta)
    local s = math.sin(theta)
    local m = self.m

    local m1, m2 = m[1], m[2]
    local m5, m6 = m[5], m[6]
    local m9, m10 = m[9], m[10]
    local m13, m14 = m[13], m[14]

    m[1] = m1 * c + m2 * s
    m[2] = m1 * (-s) + m2 * c
    m[5] = m5 * c + m6 * s
    m[6] = m5 * (-s) + m6 * c
    m[9] = m9 * c + m10 * s
    m[10] = m9 * (-s) + m10 * c
    m[13] = m13 * c + m14 * s
    m[14] = m13 * (-s) + m14 * c

    return self
end

function Transform3D:rotate_axis(axis, theta)
    assertNumber(theta, "theta")
    local q = geo.quaternion.from_axis_angle(axis, theta)
    local rot = q:to_matrix()

    -- Multiply self by rotation matrix
    local m = self.m
    local r = {
        rot[1][1], rot[1][2], rot[1][3], 0,
        rot[2][1], rot[2][2], rot[2][3], 0,
        rot[3][1], rot[3][2], rot[3][3], 0,
        0, 0, 0, 1
    }

    local result = {}
    for i = 0, 3 do
        for j = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + m[i * 4 + k + 1] * r[k * 4 + j + 1]
            end
            result[i * 4 + j + 1] = sum
        end
    end

    self.m = result
    return self
end

function Transform3D:scale(sx, sy, sz)
    assertNumber(sx, "sx")
    sy = sy or sx
    sz = sz or sx
    assertNumber(sy, "sy")
    assertNumber(sz, "sz")

    local m = self.m
    m[1] = m[1] * sx
    m[2] = m[2] * sy
    m[3] = m[3] * sz
    m[5] = m[5] * sx
    m[6] = m[6] * sy
    m[7] = m[7] * sz
    m[9] = m[9] * sx
    m[10] = m[10] * sy
    m[11] = m[11] * sz
    m[13] = m[13] * sx
    m[14] = m[14] * sy
    m[15] = m[15] * sz

    return self
end

function Transform3D:apply(point)
    local m = self.m
    local x = m[1] * point.x + m[2] * point.y + m[3] * point.z + m[4]
    local y = m[5] * point.x + m[6] * point.y + m[7] * point.z + m[8]
    local z = m[9] * point.x + m[10] * point.y + m[11] * point.z + m[12]
    local w = m[13] * point.x + m[14] * point.y + m[15] * point.z + m[16]

    if not nearZero(w - 1) then
        x = x / w
        y = y / w
        z = z / w
    end

    return geo.vec3(x, y, z)
end

function Transform3D:multiply(other)
    local a = self.m
    local b = other.m
    local result = geo.transform3d()
    local r = result.m

    for i = 0, 3 do
        for j = 0, 3 do
            local sum = 0
            for k = 0, 3 do
                sum = sum + a[i * 4 + k + 1] * b[k * 4 + j + 1]
            end
            r[i * 4 + j + 1] = sum
        end
    end

    return result
end

return geo
