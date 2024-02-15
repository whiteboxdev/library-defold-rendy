--------------------------------------------------------------------------------
-- License
--------------------------------------------------------------------------------

-- Copyright (c) 2024 Klayton Kowalski

-- This software is provided 'as-is', without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the use of this software.

-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it freely,
-- subject to the following restrictions:

-- 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
--    If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.

-- 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.

-- 3. This notice may not be removed or altered from any source distribution.

--------------------------------------------------------------------------------
-- Information
--------------------------------------------------------------------------------

-- GitHub: https://github.com/klaytonkowalski/library-defold-rendy

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

local message_acquire_camera_focus = hash("acquire_camera_focus")
local message_release_camera_focus = hash("release_camera_focus")

local message_acquire_input_focus = hash("acquire_input_focus")
local message_release_input_focus = hash("release_input_focus")

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local rendy = {}

-- The following `rendy._` variables should not be directly accessed or manipulated by the user.
-- They are only exposed because the rendy.render_script file needs write-access to them.

-- Contains all cameras except the GUI camera, which is stored in the rendy.render_script file.
-- { [camera_id] = <data>, ... }
rendy.cameras = {}

-- Initial width and height of the window, specified in the game.project file.
rendy.display_width = nil
rendy.display_height = nil

-- Current width and height of the window.
rendy.window_width = nil
rendy.window_height = nil

-- Checks if a screen position in within a camera's viewport.
local function is_within_viewport(camera, screen_x, screen_y)
	return
		camera.viewport_pixel_x <= screen_x and
		screen_x <= camera.viewport_pixel_x + camera.viewport_pixel_width and
		camera.viewport_pixel_y <= screen_y and
		screen_y <= camera.viewport_pixel_y + camera.viewport_pixel_height
end

-- Checks if an NDC position is within the OpenGL NDC cube.
local function is_within_ndc_cube(ndc_position)
	return
		-1 <= ndc_position.x and ndc_position.x <= 1 and
		-1 <= ndc_position.y and ndc_position.y <= 1 and
		-1 <= ndc_position.z and ndc_position.z <= 1
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

-- Creates a camera.
-- This function is called automatically by the rendy.go game object.
function rendy.create_camera(camera_id)
	local camera_url = msg.url(nil, camera_id, "camera")
	local script_url = msg.url(nil, camera_id, "script")
	rendy.cameras[camera_id] =
	{
		camera_id = camera_id,
		camera_url = msg.url(nil, camera_id, "camera"),
		script_url = msg.url(nil, camera_id, "script"),
		viewport_pixel_x = 0,
		viewport_pixel_y = 0,
		viewport_pixel_width = 0,
		viewport_pixel_height = 0,
		view_transform = vmath.matrix4(),
		projection_transform = vmath.matrix4(),
		frustum = vmath.matrix4(),
		shake_timer = nil,
		shake_position = nil,
		active = go.get(script_url, "active"),
		orthographic = go.get(script_url, "orthographic"),
		resize_mode_center = go.get(script_url, "resize_mode_center"),
		resize_mode_expand = go.get(script_url, "resize_mode_expand"),
		resize_mode_stretch = go.get(script_url, "resize_mode_stretch"),
		experimental_controls = go.get(script_url, "experimental_controls"),
		render_order = go.get(script_url, "render_order"),
		viewport_x = go.get(script_url, "viewport_x"),
		viewport_y = go.get(script_url, "viewport_y"),
		viewport_width = go.get(script_url, "viewport_width"),
		viewport_height = go.get(script_url, "viewport_height"),
		resolution_width = go.get(script_url, "resolution_width"),
		resolution_height = go.get(script_url, "resolution_height"),
		z_min = go.get(script_url, "z_min"),
		z_max = go.get(script_url, "z_max"),
		zoom = go.get(script_url, "zoom"),
		field_of_view = go.get(script_url, "field_of_view")
	}
	msg.post(camera_url, message_acquire_camera_focus)
	if rendy.cameras[camera_id].experimental_controls then
		msg.post(script_url, message_acquire_input_focus)
	end
end

-- Destroys a camera.
-- This function is called automatically by the rendy.go game object.
function rendy.destroy_camera(camera_id)
	msg.post(rendy.cameras[camera_id].camera_url, message_release_camera_focus)
	if rendy.cameras[camera_id].experimental_controls then
		msg.post(rendy.cameras[camera_id].script_url, message_release_input_focus)
	end
	rendy.cameras[camera_id] = nil
end

-- Sets a camera's active state.
-- If a camera is inactive, then its configuration remains in memory, but it is not drawn by the render script.
function rendy.set_active(camera_id, flag)
	go.set(rendy.cameras[camera_id].script_url, "active", flag)
	rendy.cameras[camera_id].active = flag
end

-- Sets a camera's projection transform to orthographic or perspective.
function rendy.set_orthographic(camera_id, flag)
	go.set(rendy.cameras[camera_id].script_url, "orthographic", flag)
	rendy.cameras[camera_id].orthographic = flag
end

-- Sets a camera's resize mode to center.
function rendy.set_resize_mode_center(camera_id)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", true)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", false)
	rendy.cameras[camera_id].resize_mode_center = true
	rendy.cameras[camera_id].resize_mode_expand = false
	rendy.cameras[camera_id].resize_mode_stretch = false
end

-- Sets a camera's resize mode to expand.
function rendy.set_resize_mode_expand(camera_id)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", true)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", false)
	rendy.cameras[camera_id].resize_mode_center = false
	rendy.cameras[camera_id].resize_mode_expand = true
	rendy.cameras[camera_id].resize_mode_stretch = false
end

-- Sets a camera's resize mode to stretch.
function rendy.set_resize_mode_stretch(camera_id)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", true)
	rendy.cameras[camera_id].resize_mode_center = false
	rendy.cameras[camera_id].resize_mode_expand = false
	rendy.cameras[camera_id].resize_mode_stretch = true
end

-- Sets a camera's experimental controls state.
function rendy.set_experimental_controls(camera_id, flag)
	go.set(rendy.cameras[camera_id].script_url, "experimental_controls", flag)
	rendy.cameras[camera_id].experimental_controls = flag
	msg.post(script_url, flag and message_acquire_input_focus or message_release_input_focus)
end

-- Sets a camera's experimental speed.
function rendy.set_experimental_speed(camera_id, speed)
	go.set(rendy.cameras[camera_id].script_url, "experimental_speed", speed)
	rendy.cameras[camera_id].experimental_speed = speed
end

-- Sets a camera's render order.
function rendy.set_render_order(camera_id, render_order)
	go.set(rendy.cameras[camera_id].script_url, "render_order", render_order)
	rendy.cameras[camera_id].render_order = render_order
end

-- Sets a camera's viewport.
function rendy.set_viewport(camera_id, x, y, width, height)
	go.set(rendy.cameras[camera_id].script_url, "viewport_x", x)
	go.set(rendy.cameras[camera_id].script_url, "viewport_y", y)
	go.set(rendy.cameras[camera_id].script_url, "viewport_width", width)
	go.set(rendy.cameras[camera_id].script_url, "viewport_height", height)
	rendy.cameras[camera_id].viewport_x = viewport_x
	rendy.cameras[camera_id].viewport_y = viewport_y
	rendy.cameras[camera_id].viewport_width = viewport_width
	rendy.cameras[camera_id].viewport_height = viewport_height
end

-- Sets a camera's resolution.
function rendy.set_resolution(camera_id, width, height)
	go.set(rendy.cameras[camera_id].script_url, "resolution_width", width)
	go.set(rendy.cameras[camera_id].script_url, "resolution_height", height)
	rendy.cameras[camera_id].resolution_width = width
	rendy.cameras[camera_id].resolution_height = height
end

-- Sets a camera's near and far clipping planes.
function rendy.set_range(camera_id, z_min, z_max)
	go.set(rendy.cameras[camera_id].script_url, "z_min", z_min)
	go.set(rendy.cameras[camera_id].script_url, "z_max", z_max)
	rendy.cameras[camera_id].z_min = z_min
	rendy.cameras[camera_id].z_max = z_max
end

-- Sets an orthographic camera's zoom factor.
-- If the zoom factor is < 1, then the camera will zoom in.
-- If the zoom factor is > 1, then the camera will zoom out.
function rendy.set_zoom(camera_id, zoom)
	go.set(rendy.cameras[camera_id].script_url, "zoom", zoom)
	rendy.cameras[camera_id].zoom = zoom
end

-- Sets a perspective camera's field of view.
function rendy.set_field_of_view(camera_id, field_of_view)
	go.set(rendy.cameras[camera_id].script_url, "field_of_view", field_of_view)
	rendy.cameras[camera_id].field_of_view = field_of_view
end

-- Gets the initial window size specified in the game.project file.
function rendy.get_display_size()
	return vmath.vector3(rendy.display_width, rendy.display_height, 0)
end

-- Gets the current window size.
function rendy.get_window_size()
	return vmath.vector3(rendy.window_width, rendy.window_height, 0)
end

-- Gets camera ids whose viewports intersect with a screen position.
function rendy.get_stack(screen_x, screen_y)
	local camera_ids = {}
	for camera_id, camera in pairs(rendy.cameras) do
		if is_within_viewport(camera, screen_x, screen_y) then
			camera_ids[#camera_ids + 1] = camera_id
		end
	end
	return camera_ids
end

-- Starts a camera shake animation.
-- If the camera is already shaking, then the animation is cancelled and restarted.
-- The radius is increased or decreased over time if the scaler argument is ~= 1.
function rendy.shake(camera_id, radius, intensity, duration, scaler)
	if rendy.cameras[camera_id].shake_timer then
		rendy.cancel_shake(camera_id)
	end
	rendy.cameras[camera_id].shake_position = go.get_position(camera_id)
	local shake_duration = duration / intensity
	local animate = function()
		local milliseconds = socket.gettime() * 1000
		local position_offset_x = math.sin(milliseconds)
		local position_offset_y = math.cos(milliseconds)
		local position_offset_z = not rendy.cameras[camera_id].orthographic and position_offset_x * position_offset_y or 0
		local to = rendy.cameras[camera_id].shake_position + vmath.vector3(position_offset_x, position_offset_y, position_offset_z) * radius
		go.set_position(rendy.cameras[camera_id].shake_position, camera_id)
		go.animate(camera_id, "position", go.PLAYBACK_ONCE_PINGPONG, to, go.EASING_LINEAR, shake_duration)
	end
	animate()
	local animation_loop = function()
		intensity = intensity - 1
		radius = radius * (scaler or 1)
		if intensity > 0 then
			animate()
		else
			rendy.cancel_shake(camera_id)
		end
	end
	rendy.cameras[camera_id].shake_timer = timer.delay(shake_duration, true, animation_loop)
end

-- Cancels an ongoing camera shake animation.
function rendy.cancel_shake(camera_id)
	if not rendy.cameras[camera_id].shake_timer then
		return
	end
	timer.cancel(rendy.cameras[camera_id].shake_timer)
	go.cancel_animations(camera_id, "position")
	go.set_position(rendy.cameras[camera_id].shake_position, camera_id)
	rendy.cameras[camera_id].shake_timer = nil
	rendy.cameras[camera_id].shake_position = nil
end

-- Converts a screen position to a world position.
-- The screen position's z component maps to the camera frustum's z component.
function rendy.screen_to_world(camera_id, screen_position)
	if not is_within_viewport(rendy.cameras[camera_id], screen_position.x, screen_position.y) then
		return
	end
	local inverse_frustum = vmath.inv(rendy.cameras[camera_id].frustum)
	local clip_x = (screen_position.x - rendy.cameras[camera_id].viewport_pixel_x) / rendy.cameras[camera_id].viewport_pixel_width * 2 - 1
	local clip_y = (screen_position.y - rendy.cameras[camera_id].viewport_pixel_y) / rendy.cameras[camera_id].viewport_pixel_height * 2 - 1
	local near_world_position = vmath.vector4(inverse_frustum * vmath.vector4(clip_x, clip_y, -1, 1))
	local far_world_position = vmath.vector4(inverse_frustum * vmath.vector4(clip_x, clip_y, 1, 1))
	near_world_position = near_world_position / near_world_position.w
	far_world_position = far_world_position / far_world_position.w
	local frustum_z = (screen_position.z - rendy.cameras[camera_id].z_min) / (rendy.cameras[camera_id].z_max - rendy.cameras[camera_id].z_min)
	local world_position = vmath.lerp(frustum_z, near_world_position, far_world_position)
	return vmath.vector3(world_position.x, world_position.y, world_position.z)
end

-- Converts a world position to a screen position.
-- The world position's z component maps to the camera frustum's z component.
function rendy.world_to_screen(camera_id, world_position)
	local ndc_position = rendy.cameras[camera_id].frustum * vmath.vector4(world_position.x, world_position.y, world_position.z, 1) / rendy.cameras[camera_id].frustum.m3.w
	if not is_within_ndc_cube(ndc_position) then
		return
	end
	local screen_x = (ndc_position.x + 1) * rendy.cameras[camera_id].viewport_pixel_width * 0.5
	local screen_y = (ndc_position.y + 1) * rendy.cameras[camera_id].viewport_pixel_height * 0.5
	return vmath.vector3(screen_x, screen_y, 0)
end

return rendy