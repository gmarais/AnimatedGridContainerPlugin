tool
extends Container
# Grid variables:
export(int, 1, 1024, 1) var rows = 1 setget set_rows, get_rows
export(int, "Horizontal", "Vertical") var fill_priority setget set_fill_priority
export(int, "Begin", "End") var horizontal_fill_direction = 1 setget set_horizontal_fill_direction
export(int, "Begin", "End") var vertical_fill_direction = 1 setget set_vertical_fill_direction
export(float) var horizontal_separation setget set_horizontal_separation
export(float) var vertical_separation setget set_vertical_separation
# Animation variables:
export(float, 0, 255) var update_delay
export(float, 0, 255) var update_time
export(float, EASE) var update_ease = 1
var old_children_positions = Array();
var wanted_children_positions = Array();
var time_elapsed_since_last_change = 0.0

# SetGets:
func set_rows(new_rows):
	rows = max(1, new_rows);
	queue_sort()
	minimum_size_changed()

func get_rows():
	return rows

func set_fill_priority(new_value):
	fill_priority = new_value
	queue_sort()

func set_horizontal_fill_direction(new_value):
	horizontal_fill_direction = new_value
	queue_sort()

func set_vertical_fill_direction(new_value):
	vertical_fill_direction = new_value
	queue_sort()

func set_horizontal_separation(new_value):
	horizontal_separation = new_value
	queue_sort()

func set_vertical_separation(new_value):
	vertical_separation = new_value
	queue_sort()

# Privates:
func get_max_rows():
	var child_count = get_child_count()
	if fill_priority:
		return Vector2(ceil(float(child_count) / float(rows)), min(rows, child_count))
	else:
		return Vector2(min(rows, child_count), ceil(float(child_count) / float(rows)))

func get_grid_position(id, max_rows):
	var result = Vector2();
	if fill_priority:
		result = Vector2(int(id / rows), int(id % rows))
	else:
		result = Vector2(int(id % rows), int(id / rows))
	return result

func make_empty_main_rows_expanded(visible_controls, max_rows, row_expanded_x:PoolIntArray, row_expanded_y:PoolIntArray):
	if fill_priority:
		for i in range(visible_controls, max_rows.y):
				row_expanded_y.append(i)
	else:
		for i in range(visible_controls, max_rows.x):
				row_expanded_x.append(i)

func evaluate_row_remaining_space(size, max_min:Dictionary, row_expanded:Array, max_rows:int, separation:float):
	for k in max_min.keys():
		if row_expanded.has(k) == false:
			size -= max_min[k]
	size -= separation * max(max_rows - 1, 0)
	
	var can_fit = false
	while (can_fit == false and row_expanded.size() > 0):
		can_fit = true
		var max_value_index = row_expanded.front();
		for c in row_expanded:
			if max_min[c] > max_min[max_value_index]:
				max_value_index = c
			if can_fit and (size / row_expanded.size()) < max_min[c]:
				can_fit = false
		if can_fit == false:
			row_expanded.erase(max_value_index)
			size -= max_min[max_value_index]
	return size

# Overrides:
func _enter_tree():
	set_mouse_filter(MOUSE_FILTER_PASS)

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		var max_min_x = Dictionary();
		var max_min_y = Dictionary();
		var row_expanded_x = Array();
		var row_expanded_y = Array();
		var child_count = get_child_count()
		var max_rows = get_max_rows()

		var visible_controls = 0
		for c in get_children():
			if c is Control == false or c.visible == false:
				continue
			var in_grid_position = get_grid_position(visible_controls, max_rows)
			visible_controls += 1
			var min_size = c.get_combined_minimum_size()
			if max_min_x.has(in_grid_position.x):
				max_min_x[in_grid_position.x] = max(max_min_x[in_grid_position.x], min_size.x)
			else:
				max_min_x[in_grid_position.x] = min_size.x
			if max_min_y.has(in_grid_position.y):
				max_min_y[in_grid_position.y] = max(max_min_y[in_grid_position.y], min_size.y)
			else:
				max_min_y[in_grid_position.y] = min_size.y
			if c.size_flags_horizontal & SIZE_EXPAND:
				row_expanded_x.append(in_grid_position.x)
			if c.size_flags_vertical & SIZE_EXPAND:
				row_expanded_y.append(in_grid_position.y)
		
		make_empty_main_rows_expanded(visible_controls, max_rows, row_expanded_x, row_expanded_y)
		var remaining_space = self.rect_size;
		remaining_space.x = evaluate_row_remaining_space(remaining_space.x, max_min_x, row_expanded_x, max_rows.x, horizontal_separation)
		remaining_space.y = evaluate_row_remaining_space(remaining_space.y, max_min_y, row_expanded_y, max_rows.y, vertical_separation)

		var expand_x = 0
		if row_expanded_x.size():
			expand_x = remaining_space.x / row_expanded_x.size()
		var expand_y = 0
		if row_expanded_y.size():
			expand_y = remaining_space.y / row_expanded_y.size()

		visible_controls = 0
		old_children_positions.clear()
		wanted_children_positions.clear()
		for c in get_children():
			if c is Control == false or c.visible == false:
				continue
			var in_grid_position = get_grid_position(visible_controls, max_rows)
			visible_controls += 1

			var offsets = Vector2(0,0)
			if horizontal_fill_direction == GROW_DIRECTION_BEGIN:
				offsets.x += self.rect_size.x
				if row_expanded_x.has(in_grid_position.x):
					offsets.x -= (expand_x + horizontal_separation)
				else:
					offsets.x -= (max_min_x[in_grid_position.x] + vertical_separation)
			if vertical_fill_direction == GROW_DIRECTION_BEGIN:
				offsets.y += self.rect_size.y
				if row_expanded_y.has(in_grid_position.y):
					offsets.y -= (expand_y + horizontal_separation)
				else:
					offsets.y -= (max_min_y[in_grid_position.y] + vertical_separation)
			for i in range(max_min_x.keys().min(), in_grid_position.x):
				if row_expanded_x.has(float(i)):
					offsets.x += (expand_x + horizontal_separation) * (-1 + 2 * horizontal_fill_direction)
				else:
					offsets.x += (max_min_x[float(i)] + horizontal_separation) * (-1 + 2 * horizontal_fill_direction)
			for i in range(max_min_y.keys().min(), in_grid_position.y):
				if row_expanded_y.has(float(i)):
					offsets.y += (expand_y + vertical_separation) * (-1 + 2 * vertical_fill_direction)
				else:
					offsets.y += (max_min_y[float(i)] + vertical_separation) * (-1 + 2 * vertical_fill_direction)
			
			var p = offsets
			var s = Vector2(expand_x, expand_y)
			if row_expanded_x.has(in_grid_position.x) == false:
				s.x = max_min_x[in_grid_position.x]
			if row_expanded_y.has(in_grid_position.y) == false:
				s.y = max_min_y[in_grid_position.y]
			
			if update_delay or update_time:
				old_children_positions.append(c.get_rect())
				wanted_children_positions.append(Rect2(p, s))
			else:
				fit_child_in_rect(c, Rect2(p, s))

		time_elapsed_since_last_change = 0.0
		if update_delay or update_time:
			set_process(true)
		else:
			set_process(false)

func _process(delta):
	time_elapsed_since_last_change += delta
	if time_elapsed_since_last_change < update_delay:
		return
	var update_time_elapsed = time_elapsed_since_last_change - update_delay
	if update_time_elapsed < update_time:
		var eased_percent_done = ease(update_time_elapsed / update_time, update_ease)
		var visible_controls = 0
		for c in get_children():
			if c is Control == false or c.visible == false:
				continue
			c.set_size(lerp(old_children_positions[visible_controls].size, Rect2(wanted_children_positions[visible_controls]).size, eased_percent_done))
			c.set_position(lerp(old_children_positions[visible_controls].position, Rect2(wanted_children_positions[visible_controls]).position, eased_percent_done))
			visible_controls += 1
	else:
		var visible_controls = 0
		for c in get_children():
			if c is Control == false or c.visible == false:
				continue
			c.set_size(Rect2(wanted_children_positions[visible_controls]).size)
			c.set_position(Rect2(wanted_children_positions[visible_controls]).position)
			visible_controls += 1
		set_process(false)
