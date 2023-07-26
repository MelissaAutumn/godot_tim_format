# import_plugin.gd
@tool
extends EditorImportPlugin


func _get_importer_name():
	return "melissaautumn.timimport"
	
func _get_visible_name():
	return "TIM Import"

func _get_recognized_extensions():
	return ["tim"]

func _get_save_extension():
	return "tex"
	
func _get_resource_type():
	return "Texture2D"
	
func _get_priority():
	return 1.0

func _get_import_order():
	return 1
	
func _get_import_options(path, preset_index):
	return [
		{
			'name': 'Process Transparency',
			'default_value': false,
		},
		{
			'name': 'Palette Index',
			'default_value': 0,
		},
	]
	
func _get_option_visibility(path, option_name, options):
	return true
	
func _get_preset_count():
	return 0

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	
	var loader = preload("tim_loader.gd").new()
	var tim_loader = loader.TIM.new()
	tim_loader.read(file)
	var texture = tim_loader.create_texture(options.get('Palette Index', 0), options.get('Process Transparency', false))
	
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(texture, filename)
