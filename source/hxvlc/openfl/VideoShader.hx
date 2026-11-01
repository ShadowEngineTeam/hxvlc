package hxvlc.openfl;

#if openfl
import openfl.display.GraphicsShader;

/**
 * Converts planar 4:2:0 YUV video frames to RGB on the GPU.
 *
 * The luma plane is the bitmap being drawn, the chroma planes are bound to `uPlane` and `vPlane`
 * and sampled with bilinear filtering, so chroma is properly interpolated up to the luma resolution.
 */
class VideoShader extends GraphicsShader
{
	@:glFragmentSource('
		#pragma header

		uniform sampler2D uPlane;
		uniform sampler2D vPlane;

		// Maps the luma texture coordinates onto the chroma planes.
		uniform vec2 chromaScale;
		uniform vec2 chromaOffset;

		// Keeps bilinear chroma reads inside the visible part of the (padded) chroma planes.
		uniform vec2 chromaMin;
		uniform vec2 chromaMax;

		// Kr and Kb based conversion: (V to R, U to G, V to G, U to B).
		uniform vec4 yuvCoefficients;

		void main(void)
		{
			float y = texture2D(bitmap, openfl_TextureCoordv).r;

			vec2 chromaCoord = clamp(openfl_TextureCoordv * chromaScale + chromaOffset, chromaMin, chromaMax);

			float u = texture2D(uPlane, chromaCoord).r;
			float v = texture2D(vPlane, chromaCoord).r;

			// Limited (TV) range: Y in [16, 235] and UV in [16, 240].
			y = (y - 16.0 / 255.0) * (255.0 / 219.0);
			u = (u - 128.0 / 255.0) * (255.0 / 224.0);
			v = (v - 128.0 / 255.0) * (255.0 / 224.0);

			vec3 rgb = vec3(
				y + yuvCoefficients.x * v,
				y - yuvCoefficients.y * u - yuvCoefficients.z * v,
				y + yuvCoefficients.w * u
			);

			gl_FragColor = vec4(clamp(rgb, 0.0, 1.0), 1.0) * openfl_Alphav;
		}
	')
	public function new():Void
	{
		super();
	}

	/**
	 * Sets up the shader for a frame layout.
	 *
	 * @param lumaPitch Width of the luma plane texture, including padding.
	 * @param lumaLines Height of the luma plane texture.
	 * @param chromaWidth Visible width of each chroma plane.
	 * @param chromaHeight Visible height of each chroma plane.
	 * @param chromaPitch Width of each chroma plane texture, including padding.
	 * @param chromaLines Height of each chroma plane texture.
	 * @param height Visible height of the video, used to pick the BT.601 or BT.709 matrix.
	 */
	public function setLayout(lumaPitch:Int, lumaLines:Int, chromaWidth:Int, chromaHeight:Int, chromaPitch:Int, chromaLines:Int, height:Int):Void
	{
		// Chroma is co-sited with the left luma sample horizontally and centered vertically (MPEG-2 / H.264 default).
		chromaScale.value = [lumaPitch / (2 * chromaPitch), lumaLines / (2 * chromaLines)];
		chromaOffset.value = [0.25 / chromaPitch, 0];
		chromaMin.value = [0.5 / chromaPitch, 0.5 / chromaLines];
		chromaMax.value = [(chromaWidth - 0.5) / chromaPitch, (chromaHeight - 0.5) / chromaLines];

		// HD content is BT.709, SD content is BT.601, as most players assume when the stream does not say.
		yuvCoefficients.value = height >= 720 ? [1.5748, 0.187324, 0.468124, 1.8556] : [1.402, 0.344136, 0.714136, 1.772];
	}
}
#end
