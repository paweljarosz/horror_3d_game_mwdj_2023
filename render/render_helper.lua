local M = {}

function M.create_render_target(name)
	local color_params = {
		format = render.FORMAT_RGBA,
		width = render.get_window_width(),
		height = render.get_window_height(),
		min_filter = render.FILTER_LINEAR,
		mag_filter = render.FILTER_LINEAR,
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}

	local depth_params = {
		format = render.FORMAT_DEPTH,
		width = render.get_window_width(),
		height = render.get_window_height(),
		u_wrap = render.WRAP_CLAMP_TO_EDGE,
		v_wrap = render.WRAP_CLAMP_TO_EDGE
	}

	return render.render_target(name, {
		[render.BUFFER_COLOR_BIT] = color_params,
		[render.BUFFER_DEPTH_BIT] = depth_params
	})
end

function M.draw_to_render_target(rt, fn)
	render.enable_render_target(rt)
	fn()
	render.disable_render_target(rt)
end

function M.set_default_state()
	render.set_blend_func(render.BLEND_SRC_ALPHA, render.BLEND_ONE_MINUS_SRC_ALPHA)
	render.enable_state(render.STATE_BLEND)
	render.enable_state(render.STATE_CULL_FACE)
	render.enable_state(render.STATE_DEPTH_TEST)
	render.set_depth_mask(true)
end

function M.draw_to_quad_for_fullscreen_postprocessing(quad_material, fn, color_tex0)

	render.enable_material(quad_material)
	render.enable_texture(0, color_tex0, render.BUFFER_COLOR0_BIT)

	fn()

	render.disable_texture(0)
	render.disable_material()
end

function M.draw_shadows(light_rt, light_proj, light_transform, fn)
	local w = render.get_render_target_width(light_rt, render.BUFFER_DEPTH_BIT)
	local h = render.get_render_target_height(light_rt, render.BUFFER_DEPTH_BIT)

	render.set_projection(light_proj)
	render.set_view(light_transform)
	render.set_viewport(0, 0, w, h)

	render.set_depth_mask(true)
	render.set_depth_func(render.COMPARE_FUNC_LEQUAL)
	render.enable_state(render.STATE_DEPTH_TEST)
	render.disable_state(render.STATE_BLEND)
	render.disable_state(render.STATE_CULL_FACE)

	-- This is something I would like to do to fix the "peter panning" issue,
	-- but it doesn't really work. Need to flip the normal on the plane I guess.
	-- render.set_cull_face(render.FACE_FRONT)
	-- render.enable_state(render.STATE_CULL_FACE)

	render.set_render_target(light_rt, { transient = {render.BUFFER_DEPTH_BIT} })
	render.clear({[render.BUFFER_COLOR_BIT] = vmath.vector4(0,0,0,1), [render.BUFFER_DEPTH_BIT] = 1})
	render.enable_material("shadow")
	fn()
	render.disable_material()
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

function M.create_depth_buffer(w,h)
	local color_params = {
		format     = render.FORMAT_RGBA,
		width      = w,
		height     = h,
		min_filter = render.FILTER_NEAREST,
		mag_filter = render.FILTER_NEAREST,
		u_wrap     = render.WRAP_CLAMP_TO_EDGE,
		v_wrap     = render.WRAP_CLAMP_TO_EDGE }

	local depth_params = { 
		format        = render.FORMAT_DEPTH,
		width         = w,
		height        = h,
		min_filter    = render.FILTER_NEAREST,
		mag_filter    = render.FILTER_NEAREST,
		u_wrap        = render.WRAP_CLAMP_TO_EDGE,
		v_wrap        = render.WRAP_CLAMP_TO_EDGE }

	return render.render_target("shadow_buffer", {[render.BUFFER_COLOR_BIT] = color_params, [render.BUFFER_DEPTH_BIT] = depth_params })
end

return M