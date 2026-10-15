class_name Kit
extends RefCounted
## Small helpers for building the diorama from primitives with pixel-art materials.

static var _tex_cache := {}
static var _mat_cache := {}

static func tex(name: String) -> Texture2D:
	if not _tex_cache.has(name):
		_tex_cache[name] = load("res://assets/textures/%s.png" % name)
	return _tex_cache[name]

## A lit material with a nearest-filtered pixel texture tiled `uv` times.
static func pmat(texname: String, uv := Vector2.ONE, tint := Color.WHITE, rough := 0.85) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s" % [texname, uv, tint, rough]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	if texname != "":
		m.albedo_texture = tex(texname)
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_scale = Vector3(uv.x, uv.y, 1)
	m.roughness = rough
	m.metallic_specular = 0.25
	_mat_cache[key] = m
	return m

static func cmat(color: Color, metal := 0.0, rough := 0.6, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = rough
	if emit > 0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emit
	return m

static func unshaded(color: Color, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	if transparent or color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func cyl(parent: Node3D, r: float, h: float, pos: Vector3, mat: Material, rot := Vector3.ZERO, r2 := -1.0, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r if r2 < 0 else r2
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func sphere(parent: Node3D, r: float, pos: Vector3, mat: Material, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2
	sm.radial_segments = seg
	sm.rings = seg / 2
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

## A flat textured quad facing +Z (for windows, shelves, posters).
static func quad(parent: Node3D, size: Vector2, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func sprite_mat(texname: String, emissive := 0.0, unshaded_ := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(texname)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded_:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emissive > 0:
		m.emission_enabled = true
		m.emission_texture = tex(texname)
		m.emission = Color.WHITE
		m.emission_energy_multiplier = emissive
	return m

static func omni(parent: Node3D, pos: Vector3, color: Color, energy: float, rng: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	l.shadow_enabled = shadows
	parent.add_child(l)
	return l

# ---------- Peg silhouettes (board units, y down) ----------
static func shape_poly(shape: String, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	match shape:
		"diamond":
			p = PackedVector2Array([Vector2(0, -r * 1.2), Vector2(r, 0), Vector2(0, r * 1.2), Vector2(-r, 0)])
		"square":
			p = PackedVector2Array([Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)])
		"chest":
			p = PackedVector2Array([Vector2(-r * 1.2, -r * 0.8), Vector2(r * 1.2, -r * 0.8), Vector2(r * 1.2, r * 0.9), Vector2(-r * 1.2, r * 0.9)])
		"hex":
			for i in 6:
				p.append(Vector2(cos(i * PI / 3), sin(i * PI / 3)) * r)
		"star":
			for i in 10:
				var a := -PI / 2 + i * PI / 5
				p.append(Vector2(cos(a), sin(a)) * (r * 0.5 if i % 2 else r * 1.25))
		"heart":
			for i in 28:
				var t := i / 28.0 * TAU
				var x := 16 * pow(sin(t), 3)
				var y := 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
				p.append(Vector2(x, -y) * r / 15.0)
		"bolt":
			p = PackedVector2Array([Vector2(r * 0.3, -r * 1.2), Vector2(-r * 0.8, r * 0.15), Vector2(0, r * 0.15), Vector2(-r * 0.3, r * 1.2), Vector2(r * 0.8, -r * 0.15), Vector2(0, -r * 0.15)])
		"bomb":
			for i in 8:
				var a2 := i * PI / 4 + PI / 8
				p.append(Vector2(cos(a2), sin(a2)) * r)
		"pill":
			for i in 20:
				var a3 := i / 20.0 * TAU
				p.append(Vector2(cos(a3) * r * 1.4, sin(a3) * r * 0.75))
		_:
			for i in 18:
				var a4 := i / 18.0 * TAU
				p.append(Vector2(cos(a4), sin(a4)) * r)
	return p

## Extrude a 2D polygon (board units, y down) into a prism standing out of the board along +Z.
static func extrude(poly: PackedVector2Array, depth: float, scale: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := PackedVector2Array()
	for v in poly:
		pts.append(Vector2(v.x * scale, -v.y * scale))
	if Geometry2D.is_polygon_clockwise(pts):
		pts.reverse()
	var tris := Geometry2D.triangulate_polygon(pts)
	# Top face, slightly inset so the rim catches light like a bevel.
	st.set_normal(Vector3(0, 0, 1))
	for i in tris:
		st.set_uv(pts[i] / (scale * 20.0) + Vector2(0.5, 0.5))
		st.add_vertex(Vector3(pts[i].x, pts[i].y, depth))
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var e := (b - a).normalized()
		var nn := Vector3(e.y, -e.x, 0)
		st.set_normal(nn)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(Vector3(a.x, a.y, 0))
		st.add_vertex(Vector3(b.x, b.y, 0))
		st.add_vertex(Vector3(b.x, b.y, depth))
		st.add_vertex(Vector3(a.x, a.y, 0))
		st.add_vertex(Vector3(b.x, b.y, depth))
		st.add_vertex(Vector3(a.x, a.y, depth))
	return st.commit()
