package hxvlc.impl.output;

import cpp.CastCharStar;
import cpp.Function;
import cpp.NativeArray;
import cpp.RawPointer;
import cpp.Stdlib;
import cpp.UInt32;
import cpp.VoidStarConstStar;

import haxe.io.BytesData;

import hxvlc.impl.externs.LibVLC;

import sys.thread.Mutex;

/** Represents a LibVLC video output handler that receives decoded frames through native callbacks. */
class VideoOutput
{
	/** Called when video frame data is ready to be displayed. */
	public var onDisplay:Null<(pixels:Null<BytesData>) -> Void>;

	/** Called when the video format is set up with dimensions. */
	public var onFormatSetup:Null<(width:Int, height:Int) -> Void>;

	@:noCompletion
	private var mutex:Mutex;

	@:noCompletion
	private var width:Null<Int>;

	@:noCompletion
	private var height:Null<Int>;

	@:noCompletion
	private var pixels:Null<BytesData>;

	/** Byte offset of each plane inside the frame buffer. */
	public var planeOffsets(default, null):Array<Int> = [];

	/** Row size in bytes of each plane, padded for alignment. */
	public var planePitches(default, null):Array<Int> = [];

	/** Row count of each plane. */
	public var planeLines(default, null):Array<Int> = [];

	@:noCompletion
	private var outputWidth:Null<Int>;

	@:noCompletion
	private var outputHeight:Null<Int>;

	@:noCompletion
	private var chroma:Null<String>;

	@:noCompletion
	private var bytesPerPixel:Int;

	@:noCompletion
	private var nativeMediaPlayer:RawPointer<LibVLC_Media_Player_T>;

	/**
	 * Creates a new VideoOutput instance for rendering video frames.
	 * 
	 * NOTE: In order to force the output size, you need to set both `outputWidth` and `outputHeight`, otherwise itll be ignored.
	 * 
	 * @param mediaPlayer The media player to attach LibVLC video callbacks to.
	 * @param width (Optional) Pixel width to force the LibVLC output to.
	 * @param height (Optional) Pixel height to force the LibVLC output to.
	 * @param chroma Pixel chroma string (e.g. "RV32", or "I420" for planar 4:2:0 YUV).
	 * @param bytesPerPixel Number of bytes per pixel for the chosen chroma (bytes per luma sample for planar chromas).
	 */
	public function new(mediaPlayer:MediaPlayer, ?outputWidth:Int, ?outputHeight:Int, chroma:String, bytesPerPixel:Int):Void
	{
		if (mediaPlayer.nativeMediaPlayer == null)
			return;

		this.mutex = new Mutex();
		this.outputWidth = outputWidth;
		this.outputHeight = outputHeight;
		this.chroma = chroma;
		this.bytesPerPixel = bytesPerPixel;
		this.nativeMediaPlayer = mediaPlayer.nativeMediaPlayer;

		LibVLC.video_set_callbacks(nativeMediaPlayer, Function.fromStaticFunction(VideoOutputCallbacks.videoLock),
			Function.fromStaticFunction(VideoOutputCallbacks.videoUnlock), Function.fromStaticFunction(VideoOutputCallbacks.videoDisplay),
			untyped __cpp__('this'));

		@:nullSafety(Off)
		LibVLC.video_set_format_callbacks(nativeMediaPlayer, Function.fromStaticFunction(VideoOutputCallbacks.videoFormatSetup), null);
	}
}

@:access(hxvlc.impl.output.VideoOutput)
@:unreflective
private class VideoOutputCallbacks
{
	@:noCompletion
	@:noDebug
	@:unreflective
	public static function videoLock(data:RawPointer<cpp.Void>, p_pixels:RawPointer<RawPointer<cpp.Void>>):cpp.RawPointer<cpp.Void>
	{
		final videoOutput:VideoOutput = untyped __cpp__('reinterpret_cast<VideoOutput_obj *>({0})', data);

		if (videoOutput != null)
		{
			untyped __cpp__('int stackBase');

			untyped __cpp__('hx::SetTopOfStack(&stackBase, true)');

			videoOutput.mutex.acquire();

			if (videoOutput.pixels != null)
			{
				final base:RawPointer<cpp.Void> = untyped NativeArray.getBase(videoOutput.pixels).getBase();

				for (i in 0...videoOutput.planeOffsets.length)
					p_pixels[i] = untyped __cpp__('(void *)((unsigned char *){0} + {1})', base, videoOutput.planeOffsets[i]);
			}

			untyped __cpp__('hx::SetTopOfStack((int *)0, true)');
		}

		@:nullSafety(Off)
		return null;
	}

	@:noCompletion
	@:noDebug
	@:unreflective
	public static function videoUnlock(data:RawPointer<cpp.Void>, id:RawPointer<cpp.Void>, p_pixels:VoidStarConstStar):Void
	{
		final videoOutput:VideoOutput = untyped __cpp__('reinterpret_cast<VideoOutput_obj *>({0})', data);

		if (videoOutput != null)
		{
			untyped __cpp__('int stackBase');

			untyped __cpp__('hx::SetTopOfStack(&stackBase, true)');

			videoOutput.mutex.release();

			untyped __cpp__('hx::SetTopOfStack((int *)0, true)');
		}
	}

	@:noCompletion
	@:noDebug
	@:unreflective
	public static function videoDisplay(opaque:RawPointer<cpp.Void>, picture:RawPointer<cpp.Void>):Void
	{
		final videoOutput:VideoOutput = untyped __cpp__('reinterpret_cast<VideoOutput_obj *>({0})', opaque);

		if (videoOutput != null && videoOutput.onDisplay != null)
		{
			untyped __cpp__('int stackBase');

			untyped __cpp__('hx::SetTopOfStack(&stackBase, true)');

			videoOutput.mutex.acquire();

			videoOutput.onDisplay(videoOutput.pixels);

			videoOutput.mutex.release();

			untyped __cpp__('hx::SetTopOfStack((int *)0, true)');
		}
	}

	@:noCompletion
	@:noDebug
	@:nullSafety(Off)
	@:unreflective
	public static function videoFormatSetup(opaque:RawPointer<RawPointer<cpp.Void>>, chroma:CastCharStar, width:RawPointer<UInt32>, height:RawPointer<UInt32>,
			pitches:RawPointer<UInt32>, lines:RawPointer<UInt32>):UInt32
	{
		final videoOutput:VideoOutput = untyped __cpp__('reinterpret_cast<VideoOutput_obj *>(*{0})', opaque);

		if (videoOutput != null && videoOutput.onFormatSetup != null && videoOutput.chroma != null && videoOutput.bytesPerPixel > 0)
		{
			untyped __cpp__('int stackBase');

			untyped __cpp__('hx::SetTopOfStack(&stackBase, true)');

			#if HXCPP_GC_GENERATIONAL
			untyped __cpp__('HX_CTX = HX_CTX_GET');
			#end

			Stdlib.nativeMemcpy(untyped chroma, untyped cpp.CastCharStar.fromString(videoOutput.chroma), videoOutput.chroma.length);

			videoOutput.mutex.acquire();

			if ((videoOutput.outputWidth != null && videoOutput.outputWidth > 0)
				&& (videoOutput.outputHeight != null && videoOutput.outputHeight > 0))
			{
				width[0] = videoOutput.outputWidth;
				height[0] = videoOutput.outputHeight;
			}
			else
			{
				final originalWidth:UInt32 = width[0];
				final originalHeight:UInt32 = height[0];

				if (!calculateVideoSize(videoOutput.nativeMediaPlayer, width, height))
				{
					width[0] = originalWidth;
					height[0] = originalHeight;
				}
			}

			videoOutput.width = width[0];
			videoOutput.height = height[0];

			videoOutput.planeOffsets = [];
			videoOutput.planePitches = [];
			videoOutput.planeLines = [];

			final frameWidth:Int = width[0];
			final frameHeight:Int = height[0];

			if (isPlanar420(videoOutput.chroma))
			{
				final chromaWidth:Int = (frameWidth + 1) >> 1;
				final chromaHeight:Int = (frameHeight + 1) >> 1;

				videoOutput.planePitches.push(align(frameWidth * videoOutput.bytesPerPixel, PITCH_ALIGNMENT));
				videoOutput.planeLines.push(frameHeight);

				for (_ in 0...2)
				{
					videoOutput.planePitches.push(align(chromaWidth * videoOutput.bytesPerPixel, PITCH_ALIGNMENT));
					videoOutput.planeLines.push(chromaHeight);
				}
			}
			else
			{
				videoOutput.planePitches.push(frameWidth * videoOutput.bytesPerPixel);
				videoOutput.planeLines.push(frameHeight);
			}

			var frameSize:Int = 0;

			for (i in 0...videoOutput.planePitches.length)
			{
				pitches[i] = videoOutput.planePitches[i];
				lines[i] = videoOutput.planeLines[i];

				videoOutput.planeOffsets.push(frameSize);

				frameSize += videoOutput.planePitches[i] * videoOutput.planeLines[i];
			}

			if (videoOutput.pixels == null)
				videoOutput.pixels = new BytesData();

			NativeArray.setSize(videoOutput.pixels, frameSize);

			videoOutput.onFormatSetup(videoOutput.width, videoOutput.height);

			videoOutput.mutex.release();

			untyped __cpp__('hx::SetTopOfStack((int *)0, true)');

			return 1;
		}

		return 0;
	}

	/** Row alignment for planar output, so every plane can be uploaded without changing `GL_UNPACK_ALIGNMENT`. */
	@:noCompletion
	private static inline final PITCH_ALIGNMENT:Int = 32;

	@:noCompletion
	private static inline function align(value:Int, alignment:Int):Int
	{
		return (value + alignment - 1) & ~(alignment - 1);
	}

	/** Whether `chroma` is limited range, three plane (Y, U, V) 4:2:0 YUV. */
	@:noCompletion
	private static function isPlanar420(chroma:Null<String>):Bool
	{
		return chroma == "I420";
	}

	/**
	 * @see https://github.com/obsproject/obs-studio/blob/5d1f0efc43c64c25f5edd4101bc1f0013bcacb60/plugins/vlc-video/vlc-video-source.c#L385
	 */
	@:noCompletion
	@:noDebug
	@:unreflective
	public static function calculateVideoSize(mediaPlayer:RawPointer<LibVLC_Media_Player_T>, width:RawPointer<UInt32>, height:RawPointer<UInt32>):Bool
	{
		if (mediaPlayer != null)
		{
			final currentMediaItem:RawPointer<LibVLC_Media_T> = LibVLC.media_player_get_media(mediaPlayer);

			if (currentMediaItem != null)
			{
				final tracks:RawPointer<RawPointer<LibVLC_Media_Track_T>> = untyped NULL;

				final count:UInt32 = LibVLC.media_tracks_get(currentMediaItem, RawPointer.addressOf(tracks));

				for (i in 0...count)
				{
					final track:RawPointer<LibVLC_Media_Track_T> = tracks[i];

					if (track[0].i_type != LibVLC_Track_Video || LibVLC.video_get_track(mediaPlayer) != track[0].i_id)
						continue;

					var trackWidth:UInt32 = track[0].video[0].i_width;
					var trackHeight:UInt32 = track[0].video[0].i_height;

					if (trackWidth == 0 || trackHeight == 0)
						break;

					var trackSarNum:UInt32 = track[0].video[0].i_sar_num;
					var trackSarDen:UInt32 = track[0].video[0].i_sar_den;

					if (trackSarNum > 0 && trackSarDen > 0)
					{
						trackWidth = Math.floor(trackWidth / trackSarDen) * trackSarNum + Math.floor((trackWidth % trackSarDen) * trackSarNum / trackSarDen);
					}

					if (track[0].video[0].i_orientation == LibVLC_Video_Orient_Right_Bottom)
					{
						width[0] = trackHeight;
						height[0] = trackWidth;
					}
					else
					{
						width[0] = trackWidth;
						height[0] = trackHeight;
					}

					LibVLC.media_tracks_release(tracks, count);

					return true;
				}

				LibVLC.media_tracks_release(tracks, count);
			}
		}

		return false;
	}
}
