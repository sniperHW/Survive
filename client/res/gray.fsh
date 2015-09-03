
varying vec4 v_fragmentColor;	
varying vec2 v_texCoord;	
//uniform sampler2D CC_Texture0;	
		
void main()			
{
	vec4 v_orColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
	float gray = dot(v_orColor.rgb, vec3(0.299, 0.587, 0.114));
	gl_FragColor = vec4(gray, gray, gray, v_orColor.a);
	//gl_FragColor = vec4(1, 1, 1, 1);
}				
