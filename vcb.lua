local vcb = { devices = { [ "hand/left" ] = 0, [ "hand/right" ] = 4 },
	buttons = { [ "trigger" ] = 1, [ "grip" ] = 2, [ "x" ] = 3, [ "a" ] = 3, [ "y" ] = 4, [ "b" ] = 4 } }

function vcb.Init( input )
	if lovr.headset.getDriver() == "desktop" then
		input.down = vcb.Down
		input.pressed = vcb.Pressed
		input.released = vcb.Released

		for i = 1, 8 do
			vcb[ i ] = { false, false, 0 } -- prev,cur, state (idle, pressed, down, released)
		end
	end
end

function vcb.Pressed( device, button )
	if vcb[ vcb.devices[ device ] + vcb.buttons[ button ] ][ 3 ] == 1 then
		return true
	end
	return false
end

function vcb.Released( device, button )
	if vcb[ vcb.devices[ device ] + vcb.buttons[ button ] ][ 3 ] == 3 then
		return true
	end
	return false
end

function vcb.Down( device, button )
	if vcb[ vcb.devices[ device ] + vcb.buttons[ button ] ][ 3 ] == 2 then
		return true
	end
	return false
end

function vcb.Update()
	if lovr.headset.getDriver() == "desktop" then
		for i = 1, 8 do
			vcb[ i ][ 3 ] = 0
			if lovr.system.isKeyDown( tostring( i ) ) then
				if vcb[ i ][ 1 ] == false and vcb[ i ][ 2 ] == false then -- pressed
					vcb[ i ][ 1 ] = true
					vcb[ i ][ 2 ] = true
					vcb[ i ][ 3 ] = 1
					-- print( i .. " pressed " ..  vcb[ i ][ 3 ])
				elseif vcb[ i ][ 1 ] == true and vcb[ i ][ 2 ] == true then -- down
					vcb[ i ][ 3 ] = 2
					-- print( i .. " down " .. vcb[ i ][ 3 ])
				end
			else
				if vcb[ i ][ 1 ] == true and vcb[ i ][ 2 ] == true then -- released
					vcb[ i ][ 1 ] = false
					vcb[ i ][ 2 ] = false
					vcb[ i ][ 3 ] = 3
					-- print( i .. " released " .. vcb[ i ][ 3 ] )
				end
			end
		end

		if lovr.headset.wasPressed( "hand/left", "trigger" ) then
			vcb[ 1 ][ 1 ] = true
			vcb[ 1 ][ 2 ] = true
			vcb[ 1 ][ 3 ] = 1
		elseif lovr.headset.isDown( "hand/left", "trigger" ) then
			vcb[ 1 ][ 1 ] = true
			vcb[ 1 ][ 2 ] = true
			vcb[ 1 ][ 3 ] = 2
		elseif lovr.headset.wasReleased( "hand/left", "trigger" ) then
			vcb[ 1 ][ 1 ] = false
			vcb[ 1 ][ 2 ] = false
			vcb[ 1 ][ 3 ] = 3
		end
	end
end

return vcb
