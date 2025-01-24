class_name AimAssist

var _agent: RigidBody2D
var _dbg: Array[Callable]
static var _nodbg: Array[Callable] = [] as Array[Callable]

signal debug_aim(agentPos: Vector2, targetPos: Vector2, agentVel: Vector2, targetVel: Vector2, bulletSpeed: float, aimPos: Vector2)
var debug: bool = false

func _init(agent: RigidBody2D) -> void:
	_agent = agent
	_dbg = [Callable.create(debug_aim, "emit")]

func leadShot(target: RigidBody2D, bulletSpeed: float) -> Vector2:
	return LeadShot(_agent.global_position, target.global_position, _agent.linear_velocity, target.linear_velocity, bulletSpeed, _dbg if debug else _nodbg)



static func DebugPrint(tag: String, dataPrecision: int = 0, tagPadding: int = 14) -> Callable:
	return func(agentPos: Vector2, targetPos: Vector2, agentVel: Vector2, targetVel: Vector2, bulletSpeed: float, aimPos: Vector2):
		print("{tag} | Tgt {abspos} | Rel {relpos} | T.Vel {absvel} | Rel {relvel} | B.Spd {bspd} || Aim {absaim} | Lead {relaim} | Off {aimoff}° | Dist {hdist} ({htime}s)".format({
			"tag": "%-*s"%[tagPadding, tag],
			"abspos": "%.*v"%[dataPrecision, targetPos],
			"relpos": "%.*v"%[dataPrecision, targetPos-agentPos],
			"absvel": "%.*v"%[dataPrecision, targetVel],
			"relvel": "%.*v"%[dataPrecision, targetVel-agentVel],
			"bspd": "%.*f"%[dataPrecision, bulletSpeed],
			"absaim": "%.*v"%[dataPrecision, aimPos],
			"relaim": "%.*v"%[dataPrecision, aimPos-targetPos],
			"aimoff": "%+.*f"%[dataPrecision, rad_to_deg((targetPos-agentPos).angle_to(aimPos-agentPos))],
			"hdist": "%.*f"%[dataPrecision, agentPos.distance_to(aimPos)],
			"htime": "%.2f"%(agentPos.distance_to(aimPos)/bulletSpeed),
			}))

static func DebugDraw(debugCanvas: Node2D, radius: float, color: Color, filled: bool = false, width: float = -1.0, antialiased: bool = false) -> Callable:
	return func(agentPos: Vector2, targetPos: Vector2, agentVel: Vector2, targetVel: Vector2, bulletSpeed: float, aimPos: Vector2):
		var drawFunc = func():
			debugCanvas.draw_circle(aimPos, radius, color, filled, width, antialiased)
			debugCanvas.draw_line(agentPos, aimPos, color, width, antialiased)
		debugCanvas.draw.connect(drawFunc, ConnectFlags.CONNECT_ONE_SHOT)
		debugCanvas.queue_redraw()

static func LeadShot(agentPos: Vector2, targetPos: Vector2, agentVel: Vector2, targetVel: Vector2, bulletSpeed: float, debuggers: Array[Callable] = []) -> Vector2:
	if !debuggers.is_empty():
		var aimVec = LeadShot(agentPos, targetPos, agentVel, targetVel, bulletSpeed)
		for debugger in debuggers:
			if debugger.is_valid():
				debugger.call(agentPos, targetPos, agentVel, targetVel, bulletSpeed, agentPos + (aimVec * agentPos.distance_to(targetPos)))
		return aimVec

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
