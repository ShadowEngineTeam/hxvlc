package hxvlc.openfl;

#if openfl
import lime.utils.UInt8Array;

import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

/**
 * This class is a texture that extends TextureBase for efficient video frame rendering.
 */
@:access(openfl.display3D.Context3D)
class Texture extends TextureBase
{
	@:noCompletion
	private var __frameSize:Int = 0;

	/**
	 * Initializes a Texture object.
	 * 
	 * @param context The context to use for texture operations.
	 * @param width The width dimension to allocate for the texture.
	 * @param height The height dimension to allocate for the texture.
	 */
	public function new(context:Context3D, width:Int, height:Int):Void
	{
		super(context);

		__width = width;

		__height = height;

		__frameSize = width * height * 4;

		#if lime_bgfx
		if (__context.isBGFX)
		{
			__textureID = __context.bgfx.createTexture2D(__width, __height, false, 1, __internalFormat, __context.bgfx.TEXTURE_RT, null);
			return;
		}
		#end

		#if (lime_opengl || lime_opengles)
		__textureTarget = __context.gl.TEXTURE_2D;

		__context.__bindGLTexture2D(__textureID);

		__context.gl.texImage2D(__textureTarget, 0, __internalFormat, __width, __height, 0, __format, __context.gl.UNSIGNED_BYTE, new UInt8Array(__frameSize));

		@:nullSafety(Off)
		__context.__bindGLTexture2D(null);

		__getFramebuffer(false, 0, 0);
		#end
	}

	/**
	 * Updates the texture content with new data from a typed array.
	 * 
	 * @param data The new pixel data.
	 */
	public function uploadFromTypedArray(data:UInt8Array):Void
	{
		if (data.length != __frameSize)
			return;

		#if lime_bgfx
		if (__context.isBGFX)
		{
			__context.bgfx.updateTexture2D(__textureID, 0, 0, 0, 0, __width, __height, __context.bgfx.copy(data));
			return;
		}
		#end

		#if (lime_opengl || lime_opengles)
		__context.__bindGLTexture2D(__textureID);

		__context.gl.texSubImage2D(__textureTarget, 0, 0, 0, __width, __height, __format, __context.gl.UNSIGNED_BYTE, data);

		@:nullSafety(Off)
		__context.__bindGLTexture2D(null);
		#end
	}

	@:noCompletion
	private override function __setSamplerState(state:openfl.display._internal.SamplerState):Bool
	{
		if (super.__setSamplerState(state))
		{
			#if lime_bgfx
			if (__context.isBGFX)
			{
				if (state != null && state.filter != null)
				{
					switch (state.filter)
					{
						case ANISOTROPIC2X, ANISOTROPIC4X, ANISOTROPIC8X, ANISOTROPIC16X:
							__samplerStateFlags |= __context.bgfx.SAMPLER_MAG_ANISOTROPIC;
							__samplerStateFlags |= __context.bgfx.SAMPLER_MIN_ANISOTROPIC;
						default:
					}
				}

				return true;
			}
			#end

			#if (lime_opengl || lime_opengles)
			if (__context.__maxTextureMaxAnisotropy != 0)
			{
				var aniso:Float = -1;

				if (state != null && state.filter != null)
				{
					switch (state.filter)
					{
						case ANISOTROPIC2X:
							aniso = 2;
						case ANISOTROPIC4X:
							aniso = 4;
						case ANISOTROPIC8X:
							aniso = 8;
						case ANISOTROPIC16X:
							aniso = 16;
						default:
							aniso = 1;
					}
				}

				if (aniso > __context.__maxTextureMaxAnisotropy)
					aniso = __context.__maxTextureMaxAnisotropy;

				__context.gl.texParameterf(__context.gl.TEXTURE_2D, __context.__textureMaxAnisotropy, aniso);
			}
			#end

			return true;
		}

		return false;
	}
}
#end
