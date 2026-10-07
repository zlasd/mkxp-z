/* Shader for approximating the way RMXP does bitmap
 * blending via DirectDraw */

uniform sampler2D source;
uniform sampler2D destination;

uniform vec4 subRect;

uniform lowp float opacity;
uniform bool tktkMultiply;

varying vec2 v_texCoord;

void main()
{
	vec2 coor = v_texCoord;
	vec2 dstCoor = (coor - subRect.xy) * subRect.zw;

	vec4 srcFrag = texture2D(source, coor);
	vec4 dstFrag = texture2D(destination, dstCoor);

	if (tktkMultiply) {
		// The legacy mode 3 premultiplies each input with integer truncation,
		// multiplies the resulting bytes, writes opaque alpha and ignores the
		// separate opacity parameter. It is not source-over alpha blending.
		highp vec4 s = floor(texture2D(source, coor) * 255.0 + 0.5);
		highp vec4 d = floor(texture2D(destination, dstCoor) * 255.0 + 0.5);
		highp vec3 sp = floor(s.rgb * s.a / 255.0 + 0.0001);
		highp vec3 dp = floor(d.rgb * d.a / 255.0 + 0.0001);
		gl_FragColor = vec4(floor(sp * dp / 255.0 + 0.0001) / 255.0, 1.0);
		return;
	}

	vec4 resFrag;

	float co1 = srcFrag.a * opacity;
	float co2 = dstFrag.a * (1.0 - co1);
	resFrag.a = co1 + co2;

	if (resFrag.a == 0.0)
		resFrag.rgb = srcFrag.rgb;
	else
		resFrag.rgb = (co1*srcFrag.rgb + co2*dstFrag.rgb) / resFrag.a;

	gl_FragColor = resFrag;
}
