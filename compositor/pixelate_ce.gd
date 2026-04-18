@tool
class_name PixelateCE extends BaseCompositorEffect

const SHADER_PATH := "res://compositor/shaders/post_process_shader.glsl"

var context : StringName = "PixelateCE"

var pp_shader : RID
var pp_pipeline : RID

const PALETTE1_IMAGE_BINDING := 0
const PALETTE2_IMAGE_BINDING := 1
const PALETTE3_IMAGE_BINDING := 2
const PALETTE4_IMAGE_BINDING := 3
const PALETTE5_IMAGE_BINDING := 4
const PALETTE6_IMAGE_BINDING := 5
var palette1_image_uniform : RDUniform
var palette2_image_uniform : RDUniform
var palette3_image_uniform : RDUniform
var palette4_image_uniform : RDUniform
var palette5_image_uniform : RDUniform
var palette6_image_uniform : RDUniform

var texture_dirty := true
var settings_dirty := false

# Called from _init().
func _initialize_resource() -> void:
	access_resolved_color = true
	access_resolved_depth = true
	needs_normal_roughness = true

# Called on render thread after _init().
func _initialize_render() -> void:
	# Pipelines will have specialization constants attached,
	# so we will create them later.
	pp_shader = create_shader(SHADER_PATH)

# Called at beginning of _render_callback(), after updating/validating rd references.
# Use this function to setup textures or uniforms that do not depend on the view.
func _render_setup() -> void:
	if settings_dirty:
		create_pp_pipeline()

	if not rd.compute_pipeline_is_valid(pp_pipeline):
		create_pp_pipeline()
		
	if texture_dirty:
		create_textures()
		texture_dirty = false
		
# Called for each view. Setup uniforms that depend on view,
# and run compute shaders from here.
func _render_view(p_view : int) -> void:
	var scene_uniform_set : Array[RDUniform] = get_scene_uniform_set(p_view)

	var uniform_sets : Array[Array]
	
	# PP PASS
	uniform_sets = [
		scene_uniform_set,
		[palette1_image_uniform,
		 palette2_image_uniform,
		 palette3_image_uniform,
		 palette4_image_uniform,
		 palette5_image_uniform,
		 palette6_image_uniform]
	]

	run_compute_shader(
		"PP",
		pp_shader,
		pp_pipeline,
		uniform_sets,
	)

# ---------------------------------------------------------------------------

func _render_size_changed() -> void:
	# Clear all textures under this context.
	# This will trigger creation of new textures.
	render_scene_buffers.clear_context(context)
	make_settings_dirty()

func create_pp_pipeline() -> void:
	if rd.compute_pipeline_is_valid(pp_pipeline):
		rd.free_rid(pp_pipeline)

	pp_pipeline = create_pipeline(
			pp_shader
	)
	
func create_palette_texture(palette_index : int) -> RDUniform:
	var sampler_state := RDSamplerState.new()
	var sampler = rd.sampler_create(sampler_state)
	
	var palette_path = "res://textures/palette_" + str(palette_index) + ".png"
	var image_file : Texture2D = load(palette_path)
	var image := image_file.get_image()
	image.convert(Image.FORMAT_RGBA8)
	
	var fmt = RDTextureFormat.new()
	fmt.width = image.get_width()
	fmt.height = image.get_height()
	fmt.mipmaps = 1
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	var view = RDTextureView.new()
	var tex = rd.texture_create(fmt, view, [image.get_data()])
	
	var result : RDUniform
	match palette_index:
		1:
			result = get_sampler_uniform(tex, sampler, PALETTE1_IMAGE_BINDING)
		2:
			result = get_sampler_uniform(tex, sampler, PALETTE2_IMAGE_BINDING)
		3:
			result = get_sampler_uniform(tex, sampler, PALETTE3_IMAGE_BINDING)
		4:
			result = get_sampler_uniform(tex, sampler, PALETTE4_IMAGE_BINDING)
		5:
			result = get_sampler_uniform(tex, sampler, PALETTE5_IMAGE_BINDING)
		6:
			result = get_sampler_uniform(tex, sampler, PALETTE6_IMAGE_BINDING)
			
			
			
	return result
	
func create_textures() -> void:
	palette1_image_uniform = create_palette_texture(1)
	palette2_image_uniform = create_palette_texture(2)
	palette3_image_uniform = create_palette_texture(3)
	palette4_image_uniform = create_palette_texture(4)
	palette5_image_uniform = create_palette_texture(5)
	palette6_image_uniform = create_palette_texture(6)

	texture_dirty = false

func make_settings_dirty() -> void:
	settings_dirty = true
