package hxvlc.util.macros;

import haxe.io.Path;
import sys.io.File;
import sys.FileSystem;
import sys.io.Process;
#if macro
import haxe.macro.Context;
#end

using StringTools;

class LibraryMacro
{
	#if macro
	public static function copyLibraries()
	{
		#if !display
		#if windows
        if (!Context.getDefines().exists("HXVLC_EXPORT_DIR"))
            Context.error("Couldn't find a value for `HXVLC_EXPORT_DIR` haxe define. Please set it to your export directory.", Context.currentPos());

        final exportDirectory:String = Context.getDefines().get("HXVLC_EXPORT_DIR") + "/windows/bin";
        final arch:String = #if (HXCPP_M64 && !HXCPP_ARM64) "64" #elseif (HXCPP_ARM64 && !HXCPP_M64) "Arm64" #else "" #end;
        final projectDir:String = getProjectDirectory();
        final libvlcPath:String = Path.join([projectDir, "project/vlc/lib/Windows" + arch, "libvlc.dll"]);
        final libvlccorePath:String = Path.join([projectDir, "project/vlc/lib/Windows" + arch, "libvlccore.dll"]);
        final pluginsPath:String = Path.join([projectDir, "project/vlc/plugins/Windows" + arch]);
        final exportPluginsDir:String = Path.join([exportDirectory, "plugins"]);

        if (!FileSystem.exists(exportPluginsDir))
            FileSystem.createDirectory(exportPluginsDir);

        if (!FileSystem.exists(Path.join([exportDirectory, "libvlc.dll"])))
            File.copy(libvlcPath, Path.join([exportDirectory, "libvlc.dll"]));

        if (!FileSystem.exists(Path.join([exportDirectory, "libvlccore.dll"])))
            File.copy(libvlccorePath, Path.join([exportDirectory, "libvlccore.dll"]));

        copyRecursive(pluginsPath, exportPluginsDir);
		#end
		#end
	}
	#end

	private static function getProjectDirectory():String
	{
		final proc:Process = new Process("haxelib libpath hxvlc");
		return proc.stdout.readAll().toString().trim().split("\n")[0];
	}

	private static function copyRecursive(src:String, dest:String):Void
	{
		var normalizedSrc = Path.normalize(src);
		var normalizedDest = Path.normalize(dest);

		if (FileSystem.isDirectory(normalizedSrc))
		{
			if (!FileSystem.exists(normalizedDest))
				FileSystem.createDirectory(normalizedDest);

			for (file in FileSystem.readDirectory(normalizedSrc))
			{
				var srcPath = Path.join([normalizedSrc, file]);
				var destPath = Path.join([normalizedDest, file]);
				copyRecursive(srcPath, destPath);
			}
		}
		else
		{
			var parent = Path.directory(normalizedDest);
			if (!FileSystem.exists(parent))
				FileSystem.createDirectory(parent);

			try
			{
				File.copy(normalizedSrc, normalizedDest);
			}
			catch(e:Dynamic) {}
		}
	}
}