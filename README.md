# Defold Rendy

Defold Rendy provides a versatile camera suite and render pipeline in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful or interesting. Thank you!

![thumbnail.png](https://github.com/klaytonkowalski/library-defold-rendy/blob/main/assets/images/thumbnail.png?raw=true)

## Installation

Add the latest version to your project's dependencies:  
https://github.com/klaytonkowalski/library-defold-rendy/archive/main.zip

## Tutorial

### Initialization (1 of 7)

In the *game.project* file's Bootstrap section, set the active Render component to *rendy.render* file:

![example_bootstrap](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/9f6fea97-de67-4938-8730-5ce204f3b526)

Rendy provides a pre-packaged *rendy.go* game object that contains a camera component and a script component, which communicate with the *rendy.lua* file and the *rendy.render_script* file. Multiple cameras may be active simultaneously, all with their own projection, viewports, and other properties.

---

### Configuration (2 of 7)

Let's take a look at the camera's default configuration:

![example_properties](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/c7e6a155-40f4-47a9-a441-4adf168e3eef)

* **Path**, **Id**, and **Url** are all used internally and should not be modified. To differentiate between multiple cameras, change the name of the *rendy.go* game object instead of its internal components.
* **Active** determines if the camera is rendered to the screen.
* **Orthographic** toggles between an orthographic and perspective projection. Orthographic projections are used for 2D graphics whose dimensions and location on the viewport are not affected by their z position. Perspective projections are used for 3D graphics whose dimensions and location on the viewport are affected by their z positions, similar to how humans see the world through the *perspective* of their eyes.
* (See the next paragraph for details regarding **Resize Mode Center**, **Resize Mode Expand**, and **Resize Mode Stretch**.)
* **Experimental Controls** toggles very basic built-in controller mechanics. If the camera uses an orthographic projection, then the WASD keys can be used to move on the x and y axes. If the camera uses a perspective projection, then the WASD keys can be used to move on the x and z axes, and the mouse can be used to look around.
* **Experimental Speed** sets the speed of the camera if experimental controls are enabled, in pixels per second.
* **Render Order** determines in which order the camera is rendered relative to other cameras. For example, if `camera_main.render_order = 1` and `camera_minimap.render_order = 2`, then the `camera_minimap` will be rendered *after* or *on top of* `camera_main`.
* **Viewport X** and **Viewport Y** set the bottom-left pixel position of the viewport relative to the initial window size specified in the *game.project* file.
* **Viewport Width** and **Viewport Height** set the pixel width and pixel height of the viewport relative to the initial window size specified in the *game.project* file.
* **Resolution Width** and **Resolution Height** set the pixel resolution of the viewport. These should probably be equal or proportional to the **Viewport Width** and **Viewport Height** to achieve a normal aspect ratio.
* **Near** and **Far** set the z position of the frustum's near and far planes. If a game object's z position falls outside these boundaries, then it is not rendered. Orthographic projections usually set these to \[-1, 1], while perspective projections usually set these to \[0.1, 1000].
* **Zoom** sets the zoom factor for an orthographic projection. For example, if the `zoom = 0.5`, then the camera will zoom in and game objects will appear 2x as large. If `zoom = 2`, then the camera will zoom out and game objects will appear 0.5x as large. (This may seem counterintuitive, however it saves us from coding an extra division operation and I truthfully cannot think of a better term for "opposite of zoom". Please submit a pull request if you come up with something!)
* **Field Of View** effectively sets the zoom factor for a perspective projection, but more precisely, it sets the degrees in width that the camera can see of the game world. For example, if `field_of_view = 45`, then then camera can see a 45-degree window of game objects. A human's field of view is roughly 135 degrees, however we tend to use lower values in video games.

---

### Resize Modes (3 of 7)

One of the most common problems every game developer must confront is what to do when the user resizes the window. Developing for just one specific screen size is highly unlikely in today's world of running the same software on multiple different devices, resolutions, screen orientations, etc. Rendy offers three *resize modes* to solve this problem.

The following images show a window whose width has increased by a couple hundred pixels. Its original size was 960 x 540. The camera's viewport size is 100% of the window size, or 960 x 540. The camera's position is defined by the centerpoint of its viewport, which is (480, 270) + an offset of (0, 27) = a final position of (480, 297). The bottom-left of the viewport has a screen position of (0, 0). The Cursor World Position label is not relevant to these examples.

**Resize Mode Center** centers the viewport on screen, maintains its aspect ratio, and shows a consistent area of the game world regardless of the viewport size.

![example_center](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/7ca5a3bb-1aa1-4487-8abd-30cbb686b98d)

**Resize Mode Expand** maintains the original size of graphics regardless of the viewport size, and shows more or less of the game world.

![example_expand](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/7e6925ac-8a73-477f-a386-1e64137e2922)

**Resize Mode Stretch** employs no intelligent measures for resizing graphics or the viewport. This leads to graphical stretching when the current viewport size does not match the target resolution.

![example_stretch](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/fa4bbabd-37e3-44c3-b497-adb2cc813aad)

---

### Setting and Animating Properties (4 of 7)

Import Rendy into script files that need to interact with a camera:

```
local rendy = require "rendy.rendy"
```

Do not modify *rendy.script* properties using the standard game object API. Instead, Rendy provides the following analogous functions that maintain synchronization between the *rendy.script* and *rendy.lua* files:

| Standard API | Rendy API |
| ---------- | --------- |
| go.set()   | rendy.set() |
| go.animate() | rendy.animate() |
| go.cancel_animations() | rendy.cancel_animations() |
| go.get() | rendy.get() |

Here is an example of setting and animating two different properties:

```
rendy.set(hash("/my_rendy_object"), "viewport_width", 480)
rendy.animate(hash("/my_rendy_object"), "zoom", go.PLAYBACK_LOOP_PINGPONG, 2, go.EASING_INOUTQUAD, 3, 0, function() print("Ping Pong!") end)
```

The standard `go.get()` function can be safely used to retrieve property values, however the analogous `rendy.get()` function is provided for consistency.

---

### Shake Effect (5 of 7)

Shaking the camera is a widely loved feature by developers and players alike. It's just so fun! The camera's x and y positions are always animated, however its z position is only animated if using a perspective projection. Here is a rather slow and exaggerated example of an orthographic camera shake:

```
rendy.shake(hash("/my_rendy_object"), radius = 200, intensity = 10, duration = 2 [, scaler = 0.75])
```

![example_shake](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/4927285a-100d-4f45-9604-fe1522c315e0)

The camera moves `radius` units in random directions, ping-pongs between its original position and radius-defined position `intensity` times, over a period of `duration` seconds, where each ping-pong distance is multiplied by `scaler`. This optional scaler value is what allows the shake to "calm down" and come to a smooth finish.

---

### Coordinate Conversions (6 of 7)

(This section needs more documentation effort.)

It is often useful to convert between screen coordinates and world coordinates. One practical use-case is clicking on the screen, casting a ray into the game world, then retrieving all of the game object ids which intersect that ray. To accomplish tasks like this one, Rendy provides `screen_to_world()` and `world_to_screen()` functions.

Defold passes an `action` table to its `on_input()` functions. The `action.x` variable does not reflect changes to the window's size relative to its initial size specified in the game.project file. The `action.screen_x` *does* reflect changes to the window's size. For example, if a 960 x 540 window is resized to 1920 x 1080, then moving the cursor to the middle of the screen will show `action.xy = (480, 270)` and `action.screen_xy = (960, 540)`. Rendy expects these reflective screen variables when passing screen positions.

---

### Render Script (7 of 7)

If your project requires you to modify the pre-packaged *rendy.render_script* file, then remember to change the Render component in the *game.project* file's Bootstrap section. Rendy's render script is thoroughly commented, which will hopefully assist you in adding your own render predicates, swapping OpenGL states, and implementing more advanced graphics features.

The most likely use-case is adding a custom render predicate. The following table is located near the top of the render script:

```
-- Contains all render predicates.
-- Each predicate consists of a table formatted like so:
-- <predicate_name> = { tags = { hash("<predicate_name>"), ... }, object = nil }
-- The `object` entry will store the actual predicate, which is created by calling `render.predicate()`.
local predicates =
{
	-- Declare predicates that come shipped with default Defold components.
	model =
	{
		tags = { hash("model") },
		object = nil
	},
	tile =
	{
		tags = { hash("tile") },
		object = nil
	},
	particle =
	{
		tags = { hash("particle") },
		object = nil
	},
	gui =
	{
		tags = { hash("gui") },
		object = nil
	},
	text =
	{
		tags = { hash("text") },
		object = nil
	},
	-- Declare custom predicates.
}
```

Each predicate in this table is created in the `init()` function. The ordering of each predicate does not matter, however to maintain readability, custom predicates should be added to the bottom of the table. As mentioned by the comments, the `object` entry of each predicate table will reference the actual predicate, which can be drawn in the `update()` function:

```
render.draw(predicates.tile.object, { frustum = camera.frustum })
```

## API

### rendy.create_camera(camera_id)

Creates a camera. This function is called automatically by the *rendy.go* game object.

### rendy.destroy_camera(camera_id)

Destroys a camera. This function is called automatically by the *rendy.go* game object.

---

### function rendy.set(camera_id, property, value)

Sets a camera property. This function replaces the standard `go.set()`.

### function rendy.animate(camera_id, property, playback, to, easing, duration \[, delay] \[, complete_function])

Animates a camera property. This function replaces the standard `go.animate()`.

### function rendy.cancel_animations(camera_id, property)

Cancels a camera property animation. This function replaces the standard `go.cancel_animations()`.

### function rendy.get(camera_id, property)

Gets a camera property. This function is equivalent to the standard `go.get()`.

---

### function rendy.get_display_size()

Gets the initial window size specified in the *game.project* file.

### function rendy.get_window_size()

Gets the current window size.

### function rendy.get_stack(screen_x, screen_y)

Gets camera ids whose viewports intersect a screen position.

### function rendy.shake(camera_id, radius, intensity, duration \[, scaler])

Starts a camera shake animation. If the camera is already shaking, then the animation is cancelled and restarted. The radius is increased or decreased over time if the scaler argument is ~= 1.

### function rendy.cancel_shake(camera_id)

Cancels an ongoing camera shake animation.

### function rendy.screen_to_world(camera_id, screen_position)

Converts a screen position to a world position. The screen position's z component maps to the camera frustum's z component.

### function rendy.world_to_screen(camera_id, world_position)

Converts a world position to a screen position.
