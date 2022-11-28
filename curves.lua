function SavePointList()
	for i, lr in ipairs( layers ) do
		local layer_curves = {}
		for j, c in ipairs( layers[ i ].curves ) do
			local num_pts = c:getPointCount()
			if num_pts > 1 then
				local curve_copy = {}
				for k = 1, num_pts do
					local x, y, z = c:getPoint( k )
					local pt = { x = x, y = y, z = z }
					curve_copy[ #curve_copy + 1 ] = pt
				end
				layer_curves[ #layer_curves + 1 ] = curve_copy
			end
		end
		scene.point_list[ #scene.point_list + 1 ] = layer_curves
	end
end
