	Constants { float size; };
	
	vec4 lovrmain()
    {
		// PointSize = 6.0f;
        // return Projection * View * Transform * VertexPosition;
    
		vec4 clip = Projection * View * Transform * VertexPosition;
		// PointSize = size / clip.w;
		PointSize = 6.0f;
		return clip;
	}