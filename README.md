# Defold Rendy

Defold Rendy provides a versatile camera suite and render pipeline in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful or interesting. Thank you!

![thumbnail.png](https://github.com/klaytonkowalski/library-defold-rendy/blob/main/assets/images/thumbnail.png?raw=true)

## Installation

Add the latest version to your project's dependencies:  
https://github.com/klaytonkowalski/library-defold-rendy/archive/main.zip

## Usage

## API

### rendy.create_camera(camera_id)

Creates a camera. This function is called automatically by the rendy.go game object.

### rendy.destroy_camera(camera_id)

Destroys a camera. This function is called automatically by the rendy.go game object.

### rendy.set_camera_active(camera_id, flag)

Sets a camera's active state. If a camera is inactive, then its configuration remains in memory, but it is not drawn by the render script.

### rendy.set_camera_orthographic(camera_id, flag)

Sets a camera's projection transform to orthographic or perspective.

### rendy.set_camera_resize_mode_center(camera_id)

Sets a camera's resize mode to center.

### rendy.set_camera_resize_mode_expand(camera_id)

Sets a camera's resize mode to expand.

### rendy.set_camera_resize_mode_stretch(camera_id)

Sets a camera's resize mode to stretch.

### rendy.set_camera_order(camera_id, order)

Sets a camera's render order.

### rendy.set_camera_viewport(camera_id, x, y, width, height)

Sets a camera's viewport.

### rendy.set_camera_resolution(camera_id, width, height)

Sets a camera's resolution.

### rendy.set_camera_range(camera_id, z_min, z_max)

Sets a camera's near and far clipping planes.

### rendy.set_camera_zoom(camera_id, zoom)

Sets an orthographic camera's zoom factor. If the zoom factor is < 1, then the camera will zoom in. If the zoom factor is > 1, then the camera will zoom out.

### rendy.set_camera_field_of_view(camera_id, field_of_view)

Sets a perspective camera's field of view.

### rendy.get_camera_stack(screen_x, screen_y)

Gets camera ids whose viewports intersect with a screen position.

### rendy.shake_camera(camera_id, radius, intensity, duration [, scaler])

Starts a camera shake animation. If the camera is already shaking, then the animation is cancelled and restarted. The radius can be increased or decreased over time if the scaler argument is ~= 1.

### rendy.cancel_camera_shake(camera_id)

Cancels an ongoing camera shake animation.

### rendy.screen_to_world(camera_id, screen_position)

Converts a screen position to a world position. The screen position's z component maps to the camera frustum's z component.

### rendy.world_to_screen(camera_id, world_position)

Converts a world position to a screen position. The world position's z component maps to the camera frustum's z component.

### rendy.get_display_size()

Gets the initial window size specified in the game.project file.

### rendy.get_window_size()

Gets the current window size.