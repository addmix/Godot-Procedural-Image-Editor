# Godot-Procedural-Image-Editor (GdPIE)
Program for procedurally editing batches of images. Made in Godot.

## Using GdPIE
1. Place engine executable or release executable in an empty folder
2. Run the program to initialize.
3. Place images you wish to edit in the `import` folder,
4. Run program again, this time, the processed images will be saved to the `export` folder, using `default.procedure`



## Example procedures
#### You must use the `save_png` or `save_exr` command somewhere in your procedure, or the processed images will not save

default.procedure:
```
crop 10 10 10 10 #crops 10 pixels from the left, top, right, and bottom respectively
save_png #saves image
```





## Command line arguments
`-a [path]` Specifies path of assets folder.

`-e [path]` Specifies path of export folder.

`-i [path]` Specifies path of import folder.

`-p [path]` Specifies path of procedure that will be used.

## Procedure commands
`crop [int left] [int top] [int right] [int bottom]` Crops the image by specified pixels on each edge.

`expand_x2_hq2x` Stretches the image and enlarges it by a factor of 2. No interpolation is done.

`flip_x` Flips the image horizontally.

`flip_y` Flips the image vertically.

`resize [int width] [int height] [int interopolation]` Resizes the image to the given width and height. New pixels are calculated using the interpolation mode defined via Godot Image Interpolation constants (see [Interpolation](https://docs.godotengine.org/en/stable/classes/class_image.html#enum-image-interpolation)).

`resize_to_po2 [bool square] [int interpolation]` Resizes the image to the nearest power of 2 for the width and height. If square is true then set width and height to be the same. New pixels are calculated using the interpolation mode defined via Godot Image Interpolation constants (see [Interpolation](https://docs.godotengine.org/en/stable/classes/class_image.html#enum-image-interpolation)).

`save_exr [bool grayscale]` Saves the image as an EXR file. If grayscale is true and the image has only one channel, it will be saved explicitly as monochrome rather than one red channel.

`save_png` Saves the image as a PNG file.

`shrink_x2` Shrinks the image by a factor of 2.

