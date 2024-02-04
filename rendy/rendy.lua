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

-- { color = <vec4> }
local message_set_clear_color = hash("set_clear_color")

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local rendy = {}

rendy.cameras = {}

rendy.resize_modes = {}
rendy.resize_modes.stretch = hash("stretch")
rendy.resize_modes.expand = hash("expand")
rendy.resize_modes.center = hash("center")

rendy.window_width = nil
rendy.window_height = nil

rendy.resolution_width = nil
rendy.resolution_height = nil

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function rendy.create_camera(id)
	if rendy.cameras[id] then
		return
	end
	local camera_url = msg.url(nil, id, "camera")
	local script_url = msg.url(nil, id, "script")
	msg.post(camera_url, message_acquire_camera_focus)
	rendy.cameras[id] =
	{
		active = true,
		url = camera_url,
		near_z = -1,
		far_z = 1,
		resize_mode = rendy.resize_modes.stretch,
		viewport_percent_x = 0,
		viewport_percent_y = 0,
		viewport_percent_width = 1,
		viewport_percent_height = 1,
		viewport_pixel_x = nil,
		viewport_pixel_y = nil,
		viewport_pixel_width = nil,
		viewport_pixel_height = nil,
		view_transform = nil,
		projection_transform = nil
	}
end

function rendy.destroy_camera(id)
	if not rendy.cameras[id] then
		return
	end
	msg.post(rendy.cameras[id].url, message_release_camera_focus)
	rendy.cameras[id] = nil
end

function rendy.toggle_camera(id, flag)
	if not rendy.cameras[id] then
		return
	end
	rendy.cameras[id].active = flag
end

function rendy.set_camera_frustum(id, near_z, far_z)
	if not rendy.cameras[id] then
		return
	end
	rendy.cameras[id].near_z = near_z
	rendy.cameras[id].far_z = far_z
end

function rendy.set_camera_resize_mode(id, mode)
	if not rendy.cameras[id] then
		return
	end
	rendy.cameras[id].resize_mode = mode
end

function rendy.set_camera_viewport(id, x, y, width, height)
	if not rendy.cameras[id] then
		return
	end
	rendy.cameras[id].viewport_percent_x = x
	rendy.cameras[id].viewport_percent_y = y
	rendy.cameras[id].viewport_percent_width = width
	rendy.cameras[id].viewport_percent_height = height
end

function rendy.set_resolution_size(width, height)
	rendy.resolution_width = width
	rendy.resolution_height = height
end

function rendy.set_clear_color(color)
	msg.post("@render:", message_set_clear_color, { color = color })
end

return rendy