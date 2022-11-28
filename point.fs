	vec4 lovrmain()
    {
        // return Color * getPixel(ColorTexture, UV);

		vec2 uv = PointCoord - vec2(.5);

		if (length(uv) >= .5) discard;
		return DefaultColor;

		// float fw = length(fwidth(uv));
		// float alpha = 1. - smoothstep(.5 - fw, .5, length(uv));
		// if (alpha <= 0.) discard;
		// vec4 color = DefaultColor;
		// color.a = alpha;
		// return color;
    }