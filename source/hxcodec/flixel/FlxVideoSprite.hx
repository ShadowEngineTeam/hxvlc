package hxcodec.flixel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import hxcodec.openfl.Video;
import sys.FileSystem;

class FlxVideoSprite extends FlxSprite
{
	public var bitmap(default, null):Video;
	private var _shouldLoop:Bool = false;

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);

		makeGraphic(1, 1, FlxColor.TRANSPARENT);

		bitmap = new Video();
		bitmap.alpha = 0;
		bitmap.onOpening.add(function()
		{
			#if FLX_SOUND_SYSTEM
			bitmap.volume = (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume;
			#end
		});
		bitmap.onFormatSetup.add(() -> {
			if (bitmap.bitmapData != null)
				loadGraphic(bitmap.bitmapData);
		});
		FlxG.game.addChild(bitmap);
	}

	public function play(location:String, shouldLoop:Bool = false):Bool
	{
		_shouldLoop = shouldLoop;

		if (FlxG.autoPause)
		{
			if (!FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.add(resume);

			if (!FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.add(pause);
		}

		if (bitmap != null)
		{
			if (_shouldLoop)
			{
				bitmap.onEndReached.add(function()
				{
					bitmap.stop();
					haxe.Timer.delay(function()
					{
						if (bitmap != null)
						{
							var path = bitmap.location;
							if (path != null && bitmap.load(path))
								bitmap.resume();
						}
					}, 50);
				});
			}

			var videoPath = location;
			if (FileSystem.exists(Sys.getCwd() + location))
				videoPath = Sys.getCwd() + location;

			var success = bitmap.load(videoPath);
			if (success)
			{
				bitmap.resume();
				return true;
			}
			return false;
		}
		else
			return false;
	}

	public function stop():Void
	{
		if (bitmap != null)
			bitmap.stop();
	}

	public function pause():Void
	{
		if (bitmap != null)
			bitmap.pause();
	}

	public function resume():Void
	{
		if (bitmap != null)
			bitmap.resume();
	}

	public function togglePaused():Void
	{
		if (bitmap != null)
		{
			if (bitmap.isPlaying)
				bitmap.pause();
			else
				bitmap.resume();
		}
	}

	override public function update(elapsed:Float):Void
	{
		#if FLX_SOUND_SYSTEM
		if (bitmap != null)
			bitmap.volume = (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume;
		#end

		super.update(elapsed);
	}

	override public function destroy():Void
	{
		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(resume))
				FlxG.signals.focusGained.remove(resume);

			if (FlxG.signals.focusLost.has(pause))
				FlxG.signals.focusLost.remove(pause);
		}

		if (bitmap != null)
		{
			bitmap.dispose();

			if (FlxG.game.contains(bitmap))
				FlxG.game.removeChild(bitmap);
		}

		super.destroy();
	}
}