extends Node

#How this program works:

#1. Have images you wish to edit in import folder
#2. Have 'gcode' like file that edits all pictures
#2.1. Allow usage of asset files (watermarks, effects) to be used, stored in assets folder
#3. Run program through exe, or if more options are desired, through batch file
#3.1 If program is run through the exe, gcode-like file named "default" will be used
#4. processed images will be output with the same name, suffixed with _edited, in an export folder

onready var exe_path : String = OS.get_executable_path().get_base_dir()
onready var import_path : String = exe_path + "/import/"
onready var export_path : String = exe_path + "/export/"
onready var procedure_path : String = exe_path + "/procedures/"
onready var asset_path : String = exe_path + "/assets/"

var assets : Dictionary = {}

func _ready() -> void:
	var args : Array = OS.get_cmdline_args()
	main(args)
	
	#close program
	get_tree().quit()

func main(args : Array) -> void:
	#allow folder paths to be overriden
	
	#check that all folders are present, if not, make new folder
	var dir := Directory.new()
	var import_folder_exists : bool = dir.dir_exists(import_path)
	if !import_folder_exists:
		var err : int = dir.make_dir(import_path)
		if err != OK:
			push_error("Error %s when making import folder." % err)
	var export_folder_exists : bool = dir.dir_exists(export_path)
	if !export_folder_exists:
		var err : int = dir.make_dir(export_path)
		if err != OK:
			push_error("Error %s when making export folder." % err)
	var procedure_folder_exists : bool = dir.dir_exists(procedure_path)
	if !procedure_folder_exists:
		var err : int = dir.make_dir(procedure_path)
		if err != OK:
			push_error("Error %s when making procedures folder" % err)
	var asset_folder_exists : bool = dir.dir_exists(asset_path)
	if !asset_folder_exists:
		var err : int = dir.make_dir(asset_path)
		if err != OK:
			push_error("Error %s when making assets folder" % err)
	
	#load procedure
	var contents : String = ""
	if args.has("-p"):
		var path_index : int = args.find("-p") + 1
		if args.size() >= path_index:
			contents = load_procedure(args[path_index])
	#no procedure specified, use default.procedure
	else:
		contents = load_procedure(procedure_path + "default.procedure")
	
	var procedure_steps : Array = []
	#format procedure
	var lines : PoolStringArray = contents.split("\n", false)
	#load commands into array
	for line in lines:
		procedure_steps.append(line.split(" ", false))
	
	#load assets
	var assets := get_contents(asset_path)
	load_assets(assets)
	
	#load images (one at a time)
	var images := get_contents(import_path)
	for path in images:
		var image : Image = Image.new()
		image.load(import_path + path)
		
		#process image through procedure steps
		for step in procedure_steps:
			image = interpreter(image, step, export_path + path)

#returns list of contents of a folder
func get_contents(path : String) -> PoolStringArray:
	var list := PoolStringArray()
	
	var dir := Directory.new()
	var err : int = dir.open(path)
	if err != OK:
		assert(false, "Error %s occurred when trying to access %s" % [err, path])
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if !dir.current_is_dir():
			list.append(file_name)
		file_name = dir.get_next()
	
	return list

func load_procedure(path : String) -> String:
	var file := File.new()
	#file not found
	if !file.file_exists(path):
		assert(false, "File not found at %s" % path)
	
	var err : int = file.open(path, File.READ)
	if err != OK:
		assert(false, "Error %s occurred when trying to access %s" % [err, path])
	var content := file.get_as_text()
	file.close()
	
	return content

#change this so that the procedure is parsed, all necessary assets are found, and load them selectively
func load_assets(files : PoolStringArray) -> int:
	for file in files:
		assets[file] = load(asset_path + file)
	return 0

func interpreter(image : Image, args : Array, path : String) -> Image:
	match args[0]:
#		"blend_image":
#			image = blend_image(image, args)
		"crop":
			if args.size() < 5:
				incorrect_number_args_error(args)
			var size := image.get_size()
			
			#crop right and bottom
			image.crop(size.x - int(args[3]), size.y - int(args[4]))
			#flip
			image.flip_x()
			image.flip_y()
			
			#crop left and top
			image.crop(size.x - int(args[1]) - int(args[3]), size.y - int(args[2]) - int(args[4]))
			#return to original orientation
			image.flip_x()
			image.flip_y()
		"expand_x2_hq2x":
			image.expand_x2_hq2x()
		"flip_x":
			image.flip_x()
		"flip_y":
			image.flip_y()
		"resize":
			if args.size() < 4:
				incorrect_number_args_error(args)
			image.resize(int(args[1]), int(args[2]), int(args[3]))
		"resize_to_po2":
			if args.size() < 3:
				incorrect_number_args_error(args)
			image.resize_to_po2(bool(args[1]), int(args[2]))
		"shrink_x2":
			image.shrink_x2()
		"save_exr":
			if args.size() < 2:
				incorrect_number_args_error(args)
			image.save_exr(path, bool(args[1]))
		"save_png":
			image.save_png(path)
		var cmd:
			push_error("Unsupported command %s" % cmd)
	
	return image

func blend_image(image : Image, args : Array) -> Image:
	return image

func incorrect_number_args_error(args : Array) -> void:
	push_error("Incorrect number of arguments at %s" % args)
