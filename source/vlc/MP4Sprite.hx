package vlc;

import flixel.FlxSprite;
import vlc.MP4Handler;

class MP4Sprite extends FlxSprite
{
	public var readyCallback:Void->Void;
	public var finishCallback:Void->Void;

	private var video:MP4Handler;

	public function new(x:Float = 0, y:Float = 0, width:Float = 320, height:Float = 240, autoScale:Bool = true)
	{
		super(x, y);

		video = new MP4Handler(width, height, autoScale);
		video.alpha = 0;

		video.readyCallback = function()
		{
			if (video.bitmapData != null)
				loadGraphic(video.bitmapData);

			if (readyCallback != null)
				readyCallback();
		}

		video.finishCallback = function()
		{
			if (finishCallback != null)
				finishCallback();

			kill();
		};
	}

	public function playVideo(path:String, ?repeat:Bool = false, ?pauseMusic:Bool = false):Void
	{
		video.playVideo(path, repeat, pauseMusic);
	}

	public function pause():Void
	{
		video.pause();
	}

	public function resume():Void
	{
		video.resume();
	}

	override public function destroy():Void
	{
		if (video != null)
		{
			video.dispose();
			video = null;
		}

		super.destroy();
	}
}
