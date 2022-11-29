function DoPointSnap()
	if settings.snap_points then
		-- Get all points in a volume (if any)
		local pts = {}
		local cx, cy, cz = crosshair.pos.x, crosshair.pos.y, crosshair.pos.z
		local sd = settings.snap_distance
		for i, lr in ipairs( layers ) do
			for j, c in ipairs( layers[ i ].curves ) do
				if lr.visible then
					local num_pts = c:getPointCount()
					if num_pts > 1 then
						for k = 1, num_pts do
							local x, y, z = c:getPoint( k )
							if PointInVolume( x, y, z, (cx - sd / 2), (cy - sd / 2), (cz - sd / 2), sd, sd, sd ) then
								if not (k == num_pts and j == #layers[ i ].curves and command_begin) then -- exclude preview point
									pts[ #pts + 1 ] = { x = x, y = y, z = z }
								end
							end
						end
					end
				end
			end
		end

		-- Found points. get the closest one
		if #pts > 0 then
			local pt_idx = 0
			local closest = math.huge
			for i, v in ipairs( pts ) do
				local v1 = vec3( v.x, v.y, v.z )
				if v1:distance( crosshair.pos ) < closest then
					pt_idx = i
					closest = v1:distance( crosshair.pos )
				end
			end
			-- snap crosshair to point
			local v = vec3( pts[ pt_idx ].x, pts[ pt_idx ].y, pts[ pt_idx ].z )
			crosshair.pos:set( v )
		end
	end
end
