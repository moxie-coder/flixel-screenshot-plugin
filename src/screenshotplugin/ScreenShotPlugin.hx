package screenshotplugin;

import openfl.utils.ByteArray;
import openfl.display.Sprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import flixel.input.keyboard.FlxKey;
import flixel.input.FlxInput.FlxInputState;

using StringTools;

// @:sound("embed/screenshot.wav") @:allow(ScreenShotPlugin) class ScreenshotSound extends openfl.media.Sound {}

class ScreenShotPlugin extends flixel.FlxBasic {
    private static var initialized:Bool = false;
    private var container:Sprite;
    private var flashSprite:Sprite;
    private var flashBitmap:Bitmap;
    private var screenshotSprite:Sprite;
    private var shotDisplayBitmap:Bitmap;
    private var outlineBitmap:Bitmap;
    private var lastWidth:Float = FlxG.width;
    private var lastHeight:Float = FlxG.height;
    public static var enabled:Bool = true;
    public static var screenshotKey:FlxKey = FlxKey.F2;
    public static var saveFormat(default, set):FileFormatOption = PNG;
    public static var screenshotPath:String = "screenshots";
    public static var flashColor(default, set):Int = 0xFFFFFFFF;
    public static function set_flashColor(v:Int):Int {
        if (flashBitmap != null)
            flashBitmap.bitmapData = new BitmapData(lastWidth, lastHeight, true, v);
        return flashColor = v;
    }
    public static function set_saveFormat(v:FileFormatOption) {
        if (v != JPEG && v != PNG) {
            throw new haxe.Exception("Unsupported value for saveFormat: " + v);
            return saveFormat = PNG;
        }
        return saveFormat = v;
    }
    override public function new(flashColor:Int = 0xFFFFFFFF):Void {
        super();
        if (initialized) {
            FlxG.plugins.remove(this);
            destroy();
            return;
        }
        initialized = true;
        this.flashColor = flashColor;
        container = new Sprite();
        FlxG.stage.addChild(container);
        flashSprite = new Sprite();
        flashSprite.alpha = 0;
        flashBitmap = new Bitmap(new BitmapData(FlxG.width, FlxG.height, true, this.flashColor));
        flashSprite.addChild(flashBitmap);
        screenshotSprite = new Sprite();
        screenshotSprite.alpha = 0;
        container.addChild(screenshotSprite);
        outlineBitmap = new Bitmap(new BitmapData(Std.int(FlxG.width / 5) + 10, Std.int(FlxG.height / 5) + 10, true, 0xffffffff));
        outlineBitmap.x = 5;
        outlineBitmap.y = 5;
        screenshotSprite.addChild(outlineBitmap);
        shotDisplayBitmap = new Bitmap();
        shotDisplayBitmap.scaleX /= 5;
        shotDisplayBitmap.scaleY /= 5;
        screenshotSprite.addChild(shotDisplayBitmap);
        container.addChild(flashSprite);
        @:privateAccess openfl.Lib.application.window.onResize.add((w, h) -> {
            flashBitmap.bitmapData = new BitmapData(w, h, true, this.flashColor);
            outlineBitmap.bitmapData = new BitmapData(Std.int(w / 5) + 10, Std.int(h / 5) + 10, true, 0xffffffff);
            lastWidth = w;
            lastHeight = h;
        });
    }
    
    override public function update(elapsed:Float):Void {
        if (FlxG.keys.checkStatus(screenshotKey ?? FlxKey.F2, JUST_PRESSED) && enabled) {
            screenshot();
        }
    }

    private function screenshot():Void {
        FlxTween.cancelTweensOf(flashSprite);
        FlxTween.cancelTweensOf(screenshotSprite);
        flashSprite.alpha = 0;
        screenshotSprite.alpha = 0;
        var shot:Bitmap = new Bitmap(new BitmapData(Math.floor(FlxG.stage.stageWidth), Math.floor(FlxG.stage.stageHeight), true, 0));
        shot.bitmapData.draw(FlxG.stage, new Matrix(1, 0, 0, 1, -0, -0));
        var png:ByteArray = shot.bitmapData.encode(shot.bitmapData.rect, (saveFormat == PNG ? new openfl.display.PNGEncoderOptions() : new openfl.display.JPEGEncoderOptions()));
        png.position = 0;
        var path = "screenshots/Screenshot " + Date.now().toString().split(":").join("-") + saveFormat;
        if (!sys.FileSystem.exists("./${screenshotPath}/"))
            sys.FileSystem.createDirectory("./${screenshotPath}/");
        sys.io.File.saveBytes(path, png);
        flashSprite.alpha = 1;
        FlxTween.tween(flashSprite, {alpha: 0}, 0.25);
        shotDisplayBitmap.bitmapData = shot.bitmapData;
        shotDisplayBitmap.x = outlineBitmap.x + 5;
        shotDisplayBitmap.y = outlineBitmap.y + 5;
        screenshotSprite.alpha = 1;
        FlxTween.tween(screenshotSprite, {alpha: 0}, 0.5, {startDelay: .5});
    }
}

enum abstract FileFormatOption(String) {
    var JPEG = ".jpg";
    var PNG = ".png";
}
