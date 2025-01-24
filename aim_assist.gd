class_name AimAssist
extends Node


func shotLead(agentPos: Vector2, targetPos: Vector2, agentVel: Vector2, targetVel: Vector2, bulletSpeed: float) -> Vector2:
	if targetVel - agentVel == Vector2.ZERO:
		return (targetPos - agentPos).normalized()

	var p = targetPos - agentPos
	var v = targetVel - agentVel
	var s = bulletSpeed
	# given time t and bullet velocity u, bullet will reach relative displacement u*t
	# and target will reach relative displacement p + v*t
	# u*t = p + v*t
	# the dot product of u and u is the same as the bullet speed squared
	# u.u = s^2
	# squaring the first equation gives us a way to replace u (unknown) with s (known)
	# (u*t)^2 = (p + v*t)^2
	# (u.u) * t^2 = (p.p) + (2 * t * p.v) + (v.v * t^2)
	# substituting u.u for s^2
	# s^2 * t^2 = (p.p) + (2 * t * p.v) + v.v
	# rearranging in terms of t
	# (s^2 - v.v)*t^2 - (2*p.v)*t - v.v = 0
	# applying quadratic formula
	var a = s*s - v.dot(v)
	var b = -2 * p.dot(v)
	var c = -v.dot(v)
	# discriminant: d = b^2 - 4ac
	var d = b*b - 4*a*c
	if d < 0: # negative discriminant means no solutions to the quadratic equation
		return Vector2.INF
	# solving for time can give up to two solutions; we want the shorter solution that is positive
	# (as negative time would be in the past)
	var t = (-b - sqrt(d))/(2*a)
	if t < 0:
		t = (-b + sqrt(d))/(2*a)
	# using new value for time in first equation, we can solve for bullet velocity
	# u = p/t + v
	var u = p/t + v
	return u.normalized()
