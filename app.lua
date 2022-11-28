App = {}
local UI = require "ui/ui"
local vcb = require "vcb"
require "curves"

local e_tool = { names = { "Select", "Line", "PolyLine", "Curve", "Circle" } }
e_tool.select = 1
e_tool.line = 2
e_tool.polyline = 3
e_tool.curve = 4
e_tool.circle = 5

local mdl_gizmo
local is_dragging = false
scene = { transform = lovr.math.newMat4( 0, 0.6, -0.3 ), offset = lovr.math.newMat4(), scale = 1.0, c_distance = 0, last_transform = lovr.math.newMat4(),
	point_list = {} }
layers = { display_names = {} }
local command_begin = false
local mdl_controller_l
local modal_windows = { new_layer = false, delete_layer = false, rename_layer = false }
local hands = { dominant = "hand/right", non_dominant = "hand/left" }
local layers_text = {}
local active_tool = e_tool.select
local active_layer_idx = 1
local tool_window_m = lovr.math.newMat4( 0, 1.2, -0.5 )
local layers_window_m = lovr.math.newMat4( 0.3, 1.2, -0.5 )
local settings_window_m = lovr.math.newMat4( -0.3, 1.2, -0.5 )
local info_window_m = lovr.math.newMat4( 0, 1.5, -0.5 )
local input = {}
local tred = lovr.graphics.newTexture( "res/textures/tred.png" )
local crosshair = { pos = lovr.math.newVec3( 0, 0, 0 ), ori = lovr.math.newQuat() }
input.pressed = lovr.headset.wasPressed
input.down = lovr.headset.isDown
input.released = lovr.headset.wasReleased
local colors = {
	background = { 0.09, 0.09, 0.09 },
	points = { 0.8, 0.8, 0.8 },
	curves = { 1, 1, 0 },
	cage = { 0.3, 0.3, 0.3 },
	grid1 = { 0.35, 0.35, 0.35 },
	grid2 = { 0.14, 0.14, 0.14 },
	axisX = { 0, 1, 0 },
	axisY = { 1, 0, 0 },
	axisZ = { 0, 0, 1 },
}

local settings = {
	grid_size = 1,
	grid_sections = 10,
	show_grid = true,
	show_axis = true,
}

local function SceneGetPosition()
	return vec3( scene.transform )
end

local function SceneGetOrientation()
	return quat( scene.transform )
end

local function SceneSetPose( v, q )
	scene.transform:set( v, q )
end

function App.Init()
	vcb.Init( input )
	-- UI.Init( "hand/left", "thumbstick", true, 0 )
	UI.Init()

	-- Layers
	local l
	l = { name = "one", visible = true, curves = {} }
	table.insert( layers, l )
	l = { name = "two", visible = true, curves = {} }
	table.insert( layers, l )
	l = { name = "three", visible = false, curves = {} }
	table.insert( layers, l )

	for i, v in ipairs( layers ) do
		local vis
		if v.visible then
			vis = "✔ "
		else
			vis = "  "
		end
		table.insert( layers.display_names, vis .. v.name )
	end

	-- Shaders
	local vs = lovr.filesystem.read( "phong.vs" )
	local fs = lovr.filesystem.read( "phong.fs" )
	phong_shader = lovr.graphics.newShader( vs, fs )

	local vs = lovr.filesystem.read( "point.vs" )
	local fs = lovr.filesystem.read( "point.fs" )
	point_shader = lovr.graphics.newShader( vs, fs )

	-- Load models
	mdl_controller_l = lovr.graphics.newModel( "res/models/controller.glb" )
	mdl_gizmo = lovr.graphics.newModel( "res/models/gizmo.glb" )

	--NOTE test curves
	local curve = lovr.math.newCurve( -0.2, 1.2, -0.3, 0, 1.2, 0.9, 0.2, 1.2, 0, 0.6, 1.2, 0.1 )
	table.insert( layers[ active_layer_idx ].curves, curve )
	local curve = lovr.math.newCurve( -0.2, 0, -0.3, 0, 0, -0.9, 0.2, 0, 0, 0.6, 0, 0.1 )
	table.insert( layers[ active_layer_idx ].curves, curve )
end

function App.Update( dt )
	vcb.Update()
	UI.InputInfo()

	if input.pressed( "hand/left", "grip" ) then
		scene.offset:set( mat4( lovr.headset.getPose( "hand/left" ) ):invert() * scene.transform )
		scene.last_transform:set( scene.transform )
		SavePointList()
	end

	if input.pressed( "hand/right", "grip" ) then
		scene.old_distance = vec3( lovr.headset.getPosition( "hand/left" ) ):distance( vec3( lovr.headset.getPosition( "hand/right" ) ) )
	end

	if input.down( "hand/left", "grip" ) then
		scene.transform:set( mat4( lovr.headset.getPose( "hand/left" ) ) * (scene.offset) )

		local v_old = vec3( scene.last_transform )
		local v_new = vec3( scene.transform )
		local q_old = quat( scene.last_transform )
		local q_new = quat( scene.transform )
		local q = q_new * q_old:conjugate()

		local scale_diff = 0
		if input.down( "hand/right", "grip" ) then
			local cur_distance = vec3( lovr.headset.getPosition( "hand/left" ) ):distance( vec3( lovr.headset.getPosition( "hand/right" ) ) )
			scale_diff = cur_distance - scene.old_distance
		end

		for i, lr in ipairs( layers ) do
			for j, c in ipairs( layers[ i ].curves ) do
				local num_pts = c:getPointCount()
				if num_pts > 1 then
					for k = 1, num_pts do
						local v = vec3( scene.point_list[ i ][ j ][ k ].x - v_old.x, scene.point_list[ i ][ j ][ k ].y - v_old.y, scene.point_list[ i ][ j ][ k ].z - v_old.z )
						v:mul( 1 + scale_diff, 1 + scale_diff, 1 + scale_diff )
						v = q:mul( v )
						v:set( v.x + v_new.x, v.y + v_new.y, v.z + v_new.z )
						c:setPoint( k, v.x, v.y, v.z )
					end
				end
			end
		end
	end


	if input.released( "hand/left", "grip" ) then
		scene.point_list = {}
	end

	if lovr.headset.wasPressed( "hand/left", "trigger" ) then
		hands.dominant = "hand/left"
		hands.non_dominant = "hand/right"
	end

	if lovr.headset.wasPressed( "hand/right", "trigger" ) then
		hands.dominant = "hand/right"
		hands.non_dominant = "hand/left"
	end

	local m = mat4( lovr.headset.getPosition( hands.dominant ) )
	local ori = quat( lovr.headset.getOrientation( hands.dominant ) )
	m:rotate( ori )
	m:translate( 0, -0.1, 0 )
	crosshair.pos:set( m )
	crosshair.ori:set( m )
end

function App.RenderUI( pass )
	pass:setShader()
	UI.NewFrame( pass )

	-- Tools window
	UI.Begin( "tools_window", tool_window_m )
	UI.Label( "Tools" )
	UI.Separator()
	for i, v in ipairs( e_tool.names ) do
		if UI.ImageButton( "res/textures/icons/" .. i .. ".png", 64, 64, v ) then
			active_tool = i
		end
	end
	UI.End( pass )

	-- Info window
	UI.Begin( "info_window", info_window_m )
	UI.Label( "Info" )
	UI.Separator()
	UI.Dummy( 500, 0 )
	UI.Label( "Active tool: " .. e_tool.names[ active_tool ], true )
	local x = string.format( "%.3f", tostring( crosshair.pos.x ) )
	UI.Label( "X: " .. x, true )
	local y = string.format( "%.3f", tostring( crosshair.pos.y ) )
	UI.Label( "Y: " .. y, true )
	local z = string.format( "%.3f", tostring( crosshair.pos.z ) )
	UI.Label( "Z: " .. z, true )
	UI.End( pass )

	-- Settings window
	UI.Begin( "settings_window", settings_window_m )
	UI.Label( "Settings" )
	UI.Separator()
	local _
	_, settings.grid_size = UI.SliderFloat( "Grid size", settings.grid_size, 1, 5 )
	if UI.Button( "-" ) then
		settings.grid_sections = (settings.grid_sections > 2 and settings.grid_sections - 2) or 2
	end
	UI.SameLine()
	if UI.Button( "+" ) then
		settings.grid_sections = (settings.grid_sections < 20 and settings.grid_sections + 2) or 20
	end
	UI.SameLine()
	if settings.grid_sections < 10 then
		UI.Label( " " .. tostring( settings.grid_sections ) )
	else
		UI.Label( tostring( settings.grid_sections ) )
	end
	UI.SameLine()
	UI.Dummy( 18, 0 )
	UI.SameLine()
	UI.Label( "Grid sections" )
	if UI.CheckBox( "Show Grid", settings.show_grid ) then
		settings.show_grid = not settings.show_grid
	end
	if UI.CheckBox( "Show Axis", settings.show_axis ) then
		settings.show_axis = not settings.show_axis
	end

	UI.End( pass )

	-- Layers window
	UI.Begin( "layers_window", layers_window_m )
	UI.Label( "Layers" )
	UI.Separator()
	local _, idx = UI.ListBox( "layers_listbox", 11, 20, layers.display_names )
	if active_tool == e_tool.select then -- prevent changing layer when drawing
		active_layer_idx = idx
	end

	UI.SameLine()
	if UI.Button( "New", 240, 92 ) then
		modal_windows.new_layer = true
	end
	UI.SameColumn()
	if UI.Button( "Delete", 240, 92 ) then
		modal_windows.delete_layer = true
	end
	UI.SameColumn()
	if UI.Button( "Show/Hide", 240, 92 ) then
		layers[ active_layer_idx ].visible = not layers[ active_layer_idx ].visible
		local name = layers[ active_layer_idx ].name
		layers.display_names[ active_layer_idx ] = (layers[ active_layer_idx ].visible and "✔ " .. name or "  " .. name)
	end
	UI.SameColumn()
	if UI.Button( "Rename", 240, 92 ) then
		modal_windows.rename_layer = true
	end
	UI.End( pass )

	-- Modal windows
	if modal_windows.new_layer then
		local m = lovr.math.newMat4( layers_window_m )
		m:translate( 0, 0, 0.02 )
		UI.Begin( "new_layer_window", m, true )
		UI.Label( "New Layer" )

		local _, changed, id, txt = UI.TextBox( "Name", 12, "Layer" .. #layers + 1 )
		if UI.Button( "OK" ) then
			local l = { name = txt, visible = true, curves = {} }
			table.insert( layers, l )
			table.insert( layers.display_names, "✔ " .. txt )
			modal_windows.new_layer = false
			UI.EndModalWindow()
			if not changed then
				UI.SetTextBoxText( id, "Layer" .. #layers + 1 )
			end
		end
		UI.SameLine()
		if UI.Button( "Cancel" ) then
			modal_windows.new_layer = false
			UI.EndModalWindow()
		end
		UI.End( pass )
	end

	if modal_windows.delete_layer then
		local m = lovr.math.newMat4( layers_window_m )
		m:translate( 0, 0, 0.02 )
		UI.Begin( "delete_layer_window", m, true )

		if #layers > 1 then
			UI.Label( "Delete Layer?" )
			if UI.Button( "OK" ) then
				table.remove( layers, active_layer_idx )
				table.remove( layers.display_names, active_layer_idx )
				modal_windows.delete_layer = false
				UI.EndModalWindow()
			end
			UI.SameLine()
			if UI.Button( "Cancel" ) then
				modal_windows.delete_layer = false
				UI.EndModalWindow()
			end
		else
			UI.Label( "Can't delete last Layer!" )
			if UI.Button( "OK" ) then
				modal_windows.delete_layer = false
				UI.EndModalWindow()
			end
		end
		UI.End( pass )
	end

	if modal_windows.rename_layer then
		local m = lovr.math.newMat4( layers_window_m )
		m:translate( 0, 0, 0.02 )
		UI.Begin( "rename_layer_window", m, true )
		UI.Label( "Rename Layer" )
		local old_name = layers[ active_layer_idx ].name
		local _, changed, id, txt = UI.TextBox( "Name", 12, old_name )

		-- if txt ~= layers[ active_layer_idx ].name then
		-- 	-- UI.SetTextBoxText( id, layers[ active_layer_idx ].name )
		-- else
		-- 	-- UI.SetTextBoxText( id, txt )
		-- end

		if not changed then
			UI.SetTextBoxText( id, layers[ active_layer_idx ].name )
		else
			layers[ active_layer_idx ].name = txt
			layers.display_names[ active_layer_idx ] = (layers[ active_layer_idx ].visible and "✔ " .. txt or "  " .. txt)
		end

		if UI.Button( "OK" ) then
			layers[ active_layer_idx ].name = txt
			layers.display_names[ active_layer_idx ] = (layers[ active_layer_idx ].visible and "✔ " .. txt or "  " .. txt)
			modal_windows.rename_layer = false
			UI.EndModalWindow()
		end
		UI.SameLine()
		if UI.Button( "Cancel" ) then
			layers[ active_layer_idx ].name = old_name
			layers.display_names[ active_layer_idx ] = (layers[ active_layer_idx ].visible and "✔ " .. old_name or "  " .. old_name)
			UI.SetTextBoxText( id, old_name )
			modal_windows.rename_layer = false
			UI.EndModalWindow()
		end
		UI.End( pass )
	end

	return UI.RenderFrame( pass )
end

function App.SetPhongShader( pass )
	pass:setShader( phong_shader )
	pass:send( 'lightColor', { 1.0, 1.0, 1.0, 1.0 } )
	pass:send( 'lightPos', { 2.0, 5.0, 0.0 } )
	pass:send( 'ambience', { 0.2, 0.2, 0.2, 1.0 } )
	pass:send( 'specularStrength', 0.8 )
	pass:send( 'metallic', 32.0 )
end

function App.RenderGrid( pass )
	lovr.graphics.setBackgroundColor( colors.background )
	if settings.show_grid then
		pass:setColor( colors.grid1 )
		local m = mat4( SceneGetPosition(), vec3( settings.grid_size, settings.grid_size, 1 ), SceneGetOrientation() ):rotate( math.pi / 2, 1, 0, 0 )
		pass:plane( m, 'line', settings.grid_sections, settings.grid_sections )

		pass:setColor( colors.grid2 )
		local m = mat4( SceneGetPosition() + vec3( 0, -0.001, 0 ), vec3( settings.grid_size, settings.grid_size, 1 ), SceneGetOrientation() ):rotate( math.pi / 2, 1, 0
			, 0 )
		pass:plane( m, 'line', settings.grid_sections * 10, settings.grid_sections * 10 )
	end
end

function App.RenderAxis( pass )
	if settings.show_axis then
		pass:setColor( colors.axisX )
		local a = SceneGetPosition() + vec3( 0, 0.001, 0 )
		local b = mat4( a ):rotate( SceneGetOrientation() ):translate( settings.grid_size / 2, 0, 0 )
		pass:line( a, vec3( b ) )

		pass:setColor( colors.axisY )
		local a = SceneGetPosition()
		local b = mat4( a ):rotate( SceneGetOrientation() ):translate( 0, settings.grid_size / 2, 0 )
		pass:line( a, vec3( b ) )

		pass:setColor( colors.axisZ )
		local a = SceneGetPosition()
		local b = mat4( a ):rotate( SceneGetOrientation() ):translate( 0, 0, -settings.grid_size / 2 )
		pass:line( a, vec3( b ) )
	end
end

function App.RenderControllers( pass )
	pass:setColor( 1, 1, 1 )
	pass:draw( mdl_controller_l, mat4( lovr.headset.getPose( "hand/left" ) ) )
	local m = mat4( lovr.headset.getPose( "hand/right" ) )
	m:scale( -1, 1, 1 )
	pass:draw( mdl_controller_l, m )

	pass:setMaterial( tred )
	pass:sphere( crosshair.pos, 0.01 )
	pass:setMaterial()

	pass:setColor( 1, 1, 1 )
	local v1 = vec3( lovr.headset.getPosition( "head" ) )
	-- local v2 = vec3( 0, 1, -0.4 )
	local v2 = SceneGetPosition()
	local dist = v1:distance( v2 )
	pass:draw( mdl_gizmo, mat4( v2, vec3( dist * 4 ) ) )
end

function App.RenderCurves( pass )
	pass:setShader()
	for i, lr in ipairs( layers ) do
		for j, c in ipairs( layers[ i ].curves ) do
			if lr.visible then
				local num_pts = c:getPointCount()
				if num_pts > 1 then
					pass:setColor( colors.curves )
					local pts = c:render( num_pts * 6 )
					pass:line( pts )

					pass:setShader( point_shader )
					pass:setColor( colors.points )
					local t = {}
					for k = 1, num_pts do
						local x, y, z = c:getPoint( k )
						pass:points( x, y, z )
						table.insert( t, x )
						table.insert( t, y )
						table.insert( t, z )
					end

					pass:setShader()
					pass:setColor( colors.cage )
					pass:line( t )
				end
			end
		end
	end

end

function App.RenderFrame( pass )
	-- app drawing here
	if active_tool == e_tool.curve then
		if input.pressed( hands.dominant, "trigger" ) then
			if not command_begin then
				local curve = lovr.math.newCurve( crosshair.pos, crosshair.pos )
				command_begin = true
				table.insert( layers[ active_layer_idx ].curves, curve )
			else
				local curve = layers[ active_layer_idx ].curves[ #layers[ active_layer_idx ].curves ]
				curve:addPoint( crosshair.pos )
			end
		else -- Set preview point
			if command_begin then
				local curve = layers[ active_layer_idx ].curves[ #layers[ active_layer_idx ].curves ]
				local idx = curve:getPointCount()
				curve:setPoint( idx, crosshair.pos )
			end
		end
	end

	--NOTE: finalize curve test
	if input.pressed( "hand/right", "a" ) and command_begin then
		local curve = layers[ active_layer_idx ].curves[ #layers[ active_layer_idx ].curves ]
		local idx = curve:getPointCount()
		curve:removePoint( idx )
		command_begin = false
		active_tool = e_tool.select
	end

	local ui_passes = App.RenderUI( pass )
	App.RenderCurves( pass )
	App.SetPhongShader( pass )
	App.RenderGrid( pass )
	App.RenderAxis( pass )
	App.RenderControllers( pass )
	table.insert( ui_passes, pass )
	return ui_passes
end

return App
