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

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local rendy = {}

rendy.cameras = {}

rendy.window_width = nil
rendy.window_height = nil

local function is_within_viewport(camera, screen_x, screen_y)
	return
		camera.viewport_pixel_x <= screen_x and
		screen_x <= camera.viewport_pixel_x + camera.viewport_pixel_width and
		camera.viewport_pixel_y <= screen_y and
		screen_y <= camera.viewport_pixel_y + camera.viewport_pixel_height
end

local function is_within_ndc_cube(ndc_position)
	return
		-1 <= ndc_position.x and ndc_position.x <= 1 and
		-1 <= ndc_position.y and ndc_position.y <= 1 and
		-1 <= ndc_position.z and ndc_position.z <= 1
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function rendy.create_camera(camera_id)
	if rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.create_camera() -> Camera already exists: " .. camera_id)
		return
	end
	local camera_url = msg.url(nil, camera_id, "camera")
	local script_url = msg.url(nil, camera_id, "script")
	rendy.cameras[camera_id] =
	{
		camera_url = msg.url(nil, camera_id, "camera"),
		script_url = msg.url(nil, camera_id, "script"),
		viewport_pixel_x = 0,
		viewport_pixel_y = 0,
		viewport_pixel_width = 0,
		viewport_pixel_height = 0,
		view_transform = vmath.matrix4(),
		projection_transform = vmath.matrix4(),
		frustum = vmath.matrix4(),
		active = go.get(script_url, "active"),
		orthographic = go.get(script_url, "orthographic"),
		resize_mode_center = go.get(script_url, "resize_mode_center"),
		resize_mode_expand = go.get(script_url, "resize_mode_expand"),
		resize_mode_stretch = go.get(script_url, "resize_mode_stretch"),
		viewport_fraction_x = go.get(script_url, "viewport_fraction_x"),
		viewport_fraction_y = go.get(script_url, "viewport_fraction_y"),
		viewport_fraction_width = go.get(script_url, "viewport_fraction_width"),
		viewport_fraction_height = go.get(script_url, "viewport_fraction_height"),
		z_min = go.get(script_url, "z_min"),
		z_max = go.get(script_url, "z_max"),
		resolution_width = go.get(script_url, "resolution_width"),
		resolution_height = go.get(script_url, "resolution_height"),
		zoom = go.get(script_url, "zoom"),
		field_of_view = go.get(script_url, "field_of_view")
	}
	msg.post(camera_url, message_acquire_camera_focus)
end

function rendy.destroy_camera(camera_id)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.destroy_camera() -> Camera does not exist: " .. camera_id)
		return
	end
	msg.post(rendy.cameras[camera_id].camera_url, message_release_camera_focus)
	rendy.cameras[camera_id] = nil
end

function rendy.set_camera_active(camera_id, flag)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_active() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "active", flag)
	rendy.cameras[camera_id].active = flag
end

function rendy.set_camera_orthographic(camera_id, flag)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_orthographic() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "orthographic", flag)
	rendy.cameras[camera_id].orthographic = flag
end

function rendy.set_camera_resize_mode_center(camera_id)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_resize_mode_center() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", true)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", false)
	rendy.cameras[camera_id].resize_mode_center = true
	rendy.cameras[camera_id].resize_mode_expand = false
	rendy.cameras[camera_id].resize_mode_stretch = false
end

function rendy.set_camera_resize_mode_expand(camera_id)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_resize_mode_expand() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", true)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", false)
	rendy.cameras[camera_id].resize_mode_center = false
	rendy.cameras[camera_id].resize_mode_expand = true
	rendy.cameras[camera_id].resize_mode_stretch = false
end

function rendy.set_camera_resize_mode_stretch(camera_id)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_resize_mode_stretch() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_center", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_expand", false)
	go.set(rendy.cameras[camera_id].script_url, "resize_mode_stretch", true)
	rendy.cameras[camera_id].resize_mode_center = false
	rendy.cameras[camera_id].resize_mode_expand = false
	rendy.cameras[camera_id].resize_mode_stretch = true
end

function rendy.set_camera_viewport(camera_id, x, y, width, height)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_viewport() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "viewport_fraction_x", x)
	go.set(rendy.cameras[camera_id].script_url, "viewport_fraction_y", y)
	go.set(rendy.cameras[camera_id].script_url, "viewport_fraction_width", width)
	go.set(rendy.cameras[camera_id].script_url, "viewport_fraction_height", height)
	rendy.cameras[camera_id].viewport_fraction_x = viewport_fraction_x
	rendy.cameras[camera_id].viewport_fraction_y = viewport_fraction_y
	rendy.cameras[camera_id].viewport_fraction_width = viewport_fraction_width
	rendy.cameras[camera_id].viewport_fraction_height = viewport_fraction_height
end

function rendy.set_camera_range(camera_id, z_min, z_max)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_range() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "z_min", z_min)
	go.set(rendy.cameras[camera_id].script_url, "z_max", z_max)
	rendy.cameras[camera_id].z_min = z_min
	rendy.cameras[camera_id].z_max = z_max
end

function rendy.set_camera_resolution(camera_id, width, height)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_resolution() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "resolution_width", width)
	go.set(rendy.cameras[camera_id].script_url, "resolution_height", height)
	rendy.cameras[camera_id].resolution_width = width
	rendy.cameras[camera_id].resolution_height = height
end

function rendy.set_camera_zoom(camera_id, zoom)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_zoom() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "zoom", zoom)
	rendy.cameras[camera_id].zoom = zoom
end

function rendy.set_camera_field_of_view(camera_id, field_of_view)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.set_camera_field_of_view() -> Camera does not exist: " .. camera_id)
		return
	end
	go.set(rendy.cameras[camera_id].script_url, "field_of_view", field_of_view)
	rendy.cameras[camera_id].field_of_view = field_of_view
end

function rendy.get_camera_ids(screen_x, screen_y)
	local camera_ids = {}
	for camera_id, camera in pairs(rendy.cameras) do
		if is_within_viewport(camera, screen_x, screen_y) then
			camera_ids[#camera_ids + 1] = camera_id
		end
	end
	return camera_ids
end

function rendy.screen_to_world(camera_id, screen_x, screen_y)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.screen_to_world() -> Camera does not exist: " .. camera_id)
		return
	end
	if not is_within_viewport(rendy.cameras[camera_id], screen_x, screen_y) then
		return
	end
	local camera_world_position = go.get_world_position(camera_id)
	local dx_from_viewport = screen_x - rendy.cameras[camera_id].viewport_pixel_x
	local dy_from_viewport = screen_y - rendy.cameras[camera_id].viewport_pixel_y
	local viewport_width_compression = 1 / rendy.cameras[camera_id].viewport_fraction_width
	local viewport_height_compression = 1 / rendy.cameras[camera_id].viewport_fraction_height
	local world_x = (dx_from_viewport - rendy.cameras[camera_id].viewport_pixel_width * 0.5) * viewport_width_compression * rendy.cameras[camera_id].zoom + camera_world_position.x
	local world_y = (dy_from_viewport - rendy.cameras[camera_id].viewport_pixel_height * 0.5) * viewport_height_compression * rendy.cameras[camera_id].zoom + camera_world_position.y
	return  world_x, world_y
end

function rendy.world_to_screen(camera_id, world_position)
	if not rendy.cameras[camera_id] then
		print("Defold Rendy: rendy.world_to_screen() -> Camera does not exist: " .. camera_id)
		return
	end
	local ndc_position = rendy.cameras[camera_id].frustum * vmath.vector4(world_position.x, world_position.y, world_position.z, 0)
	if not is_within_ndc_cube(ndc_position) then
		return
	end
	local screen_x = (ndc_position.x + 1) * rendy.cameras[camera_id].viewport_pixel_width * 0.5
	local screen_y = (ndc_position.y + 1) * rendy.cameras[camera_id].viewport_pixel_height * 0.5
	return screen_x, screen_y
end

return rendy