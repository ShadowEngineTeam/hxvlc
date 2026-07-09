package hxvlc.openfl.textures;

import lime.utils.UInt8Array;

import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

/**
 * This class is a video texture that extends TextureBase for efficient video frame rendering.
 *
 * Frames are uploaded straight into a BGFX texture (lime's renderer); libVLC
 * is configured for RV32 output, which is BGRA on little-endian and matches
 * TextureBase's default BGFX format.
 *
 * @see https://github.com/openfl/openfl/blob/develop/src/openfl/display3D/textures/RectangleTexture.hx
 */
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
class VideoTexture extends TextureBase
{
	@:noCompletion
	private var __frameSize:Int = 0;

	/**
	 * Initializes a VideoTexture object.
	 *
	 * @param context The context to use for texture operations.
	 * @param width The width dimension to allocate for the texture.
	 * @param height The height dimension to allocate for the texture.
	 * @param data The pixel data to initializes the texture with.
	 */
	public function new(context:Context3D, width:Int, height:Int, ?data:UInt8Array):Void
	{
		super(context);

		__width = width;
		__height = height;
		__frameSize = width * height * 4;

		__ensureBGFXTexture();

		if (data != null)
			uploadFromTypedArray(data);
	}

	/**
	 * Updates the texture content with new data from a typed array.
	 *
	 * This method is typically used for uploading new video frames efficiently.
	 *
	 * @param data The new pixel data.
	 */
	public function uploadFromTypedArray(data:UInt8Array):Void
	{
		if (data == null || data.length != __frameSize || __bgfxTexture == -1)
			return;

		lime.graphics.bgfx.BGFX.updateTexture2D(__bgfxTexture, 0, 0, 0, 0, __width, __height, data);
	}
}
