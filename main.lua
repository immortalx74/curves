UI = require "ui/ui"
App = require "app"
ppp = true

function lovr.load()
	App.Init()
end

function lovr.update( dt )
	App.Update( dt )
end

function lovr.draw( pass )
	local ui_passes = App.RenderFrame( pass )
	return lovr.graphics.submit( ui_passes )
end
