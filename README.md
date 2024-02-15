# Defold Rendy

Defold Rendy provides a versatile camera suite and render pipeline in a Defold game engine project.

Please click the ☆ button on GitHub if this repository is useful or interesting. Thank you!

![thumbnail.png](https://github.com/klaytonkowalski/library-defold-rendy/blob/main/assets/images/thumbnail.png?raw=true)

## Installation

Add the latest version to your project's dependencies:  
https://github.com/klaytonkowalski/library-defold-rendy/archive/main.zip

## Usage

Under the game.project file's Bootstrap section, tell Defold to use the custom /rendy/rendy.render file, which points to the rendy.render_script file:

![example_bootstrap](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/9f6fea97-de67-4938-8730-5ce204f3b526)

Rendy provides a pre-packaged game object that we can add to our scene. The game object contains a camera component and a script component, which communicate with the rendy.lua module and the rendy.render_script file. Multiple cameras may be active simultaneously, all with their own viewports, resolutions, and other properties.

Let's take a look at its configuration options:

![example_properties](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/c7e6a155-40f4-47a9-a441-4adf168e3eef)

* **Path**, **Id**, and **Url** are all used internally and should not be modified. To differentiate between multiple cameras, change the name of the Rendy game object instead of its internal components.
* **Active** determines if the camera is rendered to the screen.
* **Orthographic** toggles between an orthographic or perspective projection. Orthographic projections are used for 2D visuals, while perspective projections are used for 3D visuals.
* (See the next paragraph for details regarding **Resize Mode Center**, **Resize Mode Expand**, and **Resize Mode Stretch**.)
* **Experimental Controls** toggles very basic built-in controller mechanics. If the camera uses an orthographic projection, then the WASD keys can be used to move on the x and y axes. If the camera uses a perspective projection, then the WASD keys can be used to move on the x and z axes, and the mouse can be used to look around.
* **Experimental Speed** sets the speed of the camera when using experimental controls, in pixels per second.
* **Render Order** determines in which order the camera is rendered, relative to other cameras. For example, if *camera_main* has a render order of 1, and *camera_minimap* has a render order of 2, then *camera_minimap* will be rendered after (or on top of) *camera_main*.
* **Viewport X** and **Viewport Y** set the bottom-left pixel position of the viewport, relative to the initial window size specified in the game.project file.
* **Viewport Width** and **Viewport Height** set the pixel width and pixel height of the viewport, relative to the initial window size specified in the game.project file.
* **Resolution Width** and **Resolution Height** set the target pixel resolution of the viewport. These should probably be equal or proportional to the **Viewport Width** and **Viewport Height** to achieve a normal aspect ratio.
* **Near** and **Far** set the z position of the frustum's near and far planes. If a game object's z position falls outside these boundaries, then it is not rendered. Orthographic projections usually set these to \[-1, 1], while perspective projections usually set these to \[0.1, 1000].
* **Zoom** sets the zoom factor for an orthographic projection. For example, if the zoom factor is 0.5, then the camera will zoom in and game objects will appear 2x as large. If the zoom factor is 2, then the camera will zoom out and game objects will appear 0.5x as large.
* **Field Of View** effectively sets the zoom factor for a perspective projection, but more precisely, it sets the degrees in width that the camera can see of the game world. For example, if the field of view is 45, then then camera can see a 45-degree window of game objects in front of it. A human's field of view is roughly 135 degrees, however we tend to use lower values in video games.

One of the most common problems every game developer must confront is what to do when the user resizes the window. It's highly unlikely that we are developing for just a single screen size! Rendy offers three *resize modes* to solve this problem.

The following images show a window whose width has increased by a couple hundred pixels. Its original size was 960 x 540. The camera is positioned at (0, 27). The bottom-left of the viewport has a screen position of (0, 0). While showing the original area of the game world, the center of the viewport has a screen position of (480, 270). The cursor position label is not important to these examples.

**Resize Mode Center** maximizes the size of the viewport, but centers it on screen, maintains its aspect ratio (and therefore avoids stretching game objects), and shows the same area of the game world.

![example_center](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/7ca5a3bb-1aa1-4487-8abd-30cbb686b98d)

**Resize Mode Expand** resizes the viewport along with the window, but maintains the size of game objects and shows more or less of the game world.

![example_expand](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/7e6925ac-8a73-477f-a386-1e64137e2922)

**Resize Mode Stretch** resizes of the viewport along with the window. It employs no additional measures for intelligently resizing the viewport or game objects, which has the effect of stretching the game world when the new viewport size does not match the target resolution.

![example_stretch](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/fa4bbabd-37e3-44c3-b497-adb2cc813aad)

Import Rendy into script files that need to interact with a camera:

```
local rendy = require "rendy.rendy"
```

Do not modify Rendy script properties using the standard game object API. Instead, Rendy provides the following analogous functions that maintain synchronization between properties in the rendy.script file and variables in the rendy.lua module:

| Standard API | Rendy API |
| ---------- | --------- |
| go.set()   | rendy.set() |
| go.animate() | rendy.animate() |
| go.cancel_animations() | rendy.cancel_animations() |

Here is an example of setting and animating two different properties:

```
rendy.set(hash("/my_rendy_object"), "viewport_width", 480)
rendy.animate(hash("/my_rendy_object"), "zoom", go.PLAYBACK_LOOP_PINGPONG, 2, go.EASING_INOUTQUAD, 3, 0, function() print("I ping-ponged!") end)
```

The standard `go.get()` function may be used to retrieve property values, however the analogous `rendy.get()` function is provided for consistency.

Shaking the camera is a widely loved feature by developers and players alike. It's just so fun! The camera's z component is not animated when using an orthographic projection, however it is animated when using a perspective projection. Here is a slow and exaggerated example:

```
rendy.shake(hash("/my_rendy_object"), radius = 200, intensity = 10, duration = 2 [, scaler = 0.75])
```

![example_shake](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/4927285a-100d-4f45-9604-fe1522c315e0)

The camera moves `radius` units in random directions, ping-pongs between its original position and radius-defined position `intensity` times, over a period of `duration` seconds, where each ping-pong distance is multiplied by an optional `scaler`. This scaler value is what allows the shake to "calm down" and come to a smooth finish. Here is an example of a perspective camera taking on a scaler value > 1:

```
rendy.shake(hash("/my_rendy_object"), radius = 0.1, intensity = 10, duration = 2 [, scaler = 1.5])
```

![example_shake_perspective](https://github.com/klaytonkowalski/library-defold-rendy/assets/70988652/aac9e0a9-fe3f-47fd-8701-cf174def05e6)

It is often useful to convert between screen coordinates and world coordinates. One practical use-case is clicking on the screen, casting a ray into the game world along that particular line, then retrieving all of the game objects which intersect the ray. To accomplish tasks like this one, Rendy provides `screen_to_world()` and `world_to_screen()` functions.

Defold passes an `action` table to its `on_input()` functions. The `action.x` variable does not reflect changes to the window's size relative to its initial size specified in the game.project file. The `action.screen_x` *does* reflect changes to the window's size. For example, if a 960 x 540 window is resized to 1920 x 1080, then moving the cursor to the middle of the screen will show `action.xy = (480, 270)` and `action.screen_xy = (960, 540)`. Rendy expects these reflective screen variables when passing screen positions.

If your project requires you to modify the pre-packaged Rendy render script, then remember to change the Render box in the game.project file's Bootstrap section. Rendy's render script is thoroughly commented, which will hopefully assist you in adding your own render predicates, swapping OpenGL states, and implementing more advanced graphics features.

Building and maintaining a library like Rendy is not a simple task. If you notice any bugs, incorrect documentation, or features that could be helpful to your use-case, please consider contributing to this project, drafting an issue, or mentioning your thoughts on the Defold forums.

## API

### rendy.create_camera(camera_id)

Creates a camera. This function is called automatically by the rendy.go game object.

### rendy.destroy_camera(camera_id)

Destroys a camera. This function is called automatically by the rendy.go game object.

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

Gets the initial window size specified in the game.project file.

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

Converts a world position to a screen position. The world position's z component maps to the camera frustum's z component.
