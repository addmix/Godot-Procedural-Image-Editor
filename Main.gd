extends Node

#How this program works:

#1. Place images you wish to edit in import folder.
#2. Create a procedure file that edits all pictures.
#2.1. Allow usage of asset files (watermarks, effects) to be used, stored in assets folder.
#3. Run program directly, or through the command line if more options are desired.
#3.1 If program is run directly, procedure file named "default.gdpie" will be used
#4. processed images will be output with the same name, in an export folder

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
	
	var import_path_supplied : bool = args.has("-i")
	
	if import_path_supplied:
		var path_index : int = args.find("-i") + 1
		if args.size() >= path_index:
			import_path = args[path_index]
	
	var import_folder_exists : bool = dir.dir_exists(import_path)
	if !import_folder_exists:
		var err : int = dir.make_dir(import_path)
		if err != OK:
			push_error("Error %s when making import folder." % err)
	
	var export_path_supplied : bool = args.has("-e")
	
	if export_path_supplied:
		var path_index : int = args.find("-e") + 1
		if args.size() >= path_index:
			export_path = args[path_index]
	
	var export_folder_exists : bool = dir.dir_exists(export_path)
	if !export_folder_exists:
		var err : int = dir.make_dir(export_path)
		if err != OK:
			push_error("Error %s when making export folder." % err)
	
	var procedure_path_supplied : bool = args.has("-p")
	
	var procedure_folder_exists : bool = dir.dir_exists(procedure_path)
	if !procedure_folder_exists:
		var err : int = dir.make_dir(procedure_path)
		if err != OK:
			push_error("Error %s when making procedures folder" % err)
	
	var asset_path_supplied : bool = args.has("-a")
	if export_path_supplied:
		var path_index : int = args.find("-a") + 1
		if args.size() >= path_index:
			export_path = args[path_index]
	
	if !export_folder_exists:
		var err : int = dir.make_dir(export_path)
		if err != OK:
			push_error("Error %s when making export folder." % err)
	
	var asset_folder_exists : bool = dir.dir_exists(asset_path)
	if !asset_folder_exists:
		var err : int = dir.make_dir(asset_path)
		if err != OK:
			push_error("Error %s when making assets folder" % err)
	
	
	#load procedure
	var contents : String = ""
	if procedure_path_supplied:
		var path_index : int = args.find("-p") + 1
		if args.size() >= path_index:
			contents = load_procedure(args[path_index])
	#no procedure specified, use default.procedure
	else:
		#check that default procedure exists
		var file := File.new()
		if !file.file_exists(procedure_path + "default.gdpie"):
			create_default_procedure()
		contents = load_procedure(procedure_path + "default.gdpie")
	
	
	var procedure_steps : Array = []
	#format procedure
	var lines : PoolStringArray = contents.split("\n", false)
	#load commands into array
	for line in lines:
		var comment : Array = line.split("#", false, 1)
		procedure_steps.append(comment[0].split(" ", false))
	
	#load assets
	var assets := get_contents(asset_path)
	load_assets(assets)
	
	#load images (one at a time)
	var images := get_contents(import_path)
	for path in images:
		#get name of file without any overlapping filetypes
		var base_path : String = path.left(path.find("."))
		var image : Image = Image.new()
		image.load(import_path + path)
		
		#process image through procedure steps
		for step in procedure_steps:
			image = interpreter(image, step, export_path + base_path)

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
		"save_exr":
			if args.size() < 2:
				incorrect_number_args_error(args)
			image.save_exr(path, bool(args[1]))
		"save_png":
			image.save_png(path)
		"save_png_as_gif":
			image.save_png(path + ".gif")
		"shrink_x2":
			image.shrink_x2()
		var cmd:
			push_error("Unsupported command %s" % cmd)
	
	return image

func blend_image(image : Image, args : Array) -> Image:
	return image

func incorrect_number_args_error(args : Array) -> void:
	push_error("Incorrect number of arguments at %s" % args)

func create_default_procedure() -> void:
	var file = File.new()
	
	file.open(procedure_path + "default.gdpie", File.WRITE)
	file.store_line("crop 10 10 10 10 #crops 10 pixels from the left, top, right, and bottom respectively")
	file.store_line("save_png #saves image")
