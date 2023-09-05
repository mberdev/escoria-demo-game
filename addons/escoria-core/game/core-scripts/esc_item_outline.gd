tool
extends Polygon2D
class_name ESCItemOutline, "res://addons/escoria-core/design/esc_item.svg"

export(Color) var outline = Color(0,0,0) setget set_outline_color
export(float) var width = 2.0 setget set_outline_width


func _draw():
	var poly = get_polygon()
	for i in range(1 , poly.size()):
		draw_line(poly[i - 1], poly[i], outline, width)
	draw_line(poly[poly.size() - 1], poly[0], outline, width)


func set_outline_color(color):
	outline = color
	update()


func set_outline_width(new_width):
	width = new_width
	update()
