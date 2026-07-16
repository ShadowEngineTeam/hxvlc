package hxcodec.openfl;

import hxvlc.openfl.Video as HxvlcVideo;

class Video extends HxvlcVideo
{
	private var _location:String = null;

	public var location(get, never):String;
	private function get_location():String
	{
		return _location;
	}

	public function new():Void
	{
		super();
	}

	override public function load(location:hxvlc.openfl.Location, ?options:Array<String>):Bool
	{
		if ((location is String))
			_location = cast(location, String);
		else
			_location = null;

		return super.load(location, options);
	}
}
