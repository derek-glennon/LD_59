@tool
class_name PixelateCE extends BaseCompositorEffect

const SHADER_PATH := "res://compositor/shaders/post_process_shader.glsl"

var context : StringName = "PixelateCE"

#var pp_data_ubo : RID
#var pp_data_ubo_uniform : RDUniform

var pp_shader : RID
var pp_pipeline : RID

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
	
# Called for each view. Setup uniforms that depend on view,
# and run compute shaders from here.
func _render_view(p_view : int) -> void:
	var scene_uniform_set : Array[RDUniform] = get_scene_uniform_set(p_view)

	var uniform_sets : Array[Array]
	
	# PP PASS
	uniform_sets = [
		scene_uniform_set
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

func make_settings_dirty() -> void:
	settings_dirty = true
