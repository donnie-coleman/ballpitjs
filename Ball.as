package {
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.AntiAliasType;
	import flash.display.Graphics;
	import flash.display.GradientType;
	import flash.geom.Matrix;

	public class Ball extends Sprite {
		public static var staticId:Number = 0;

		private var _radius:Number;
		private var _color:uint;
		private var _mass:Number = 1;
		public var vx:Number = 0;
		public var vy:Number = 0;
		public var id:Number = 0;
		public var tainted:Number = 0;
		private var _shape:Shape = null;
		private var _countDown:Number = 48;
		private var _explosionTextField:TextField = null;
		private var _textField:TextField = null;
		private var _text:String = null;
		private const fontSize:Number = 20;
		private var _innerBall:Ball = null;
		
		public function set radius(radius:Number):void{			
			_radius = radius;
		}
		
		public function get radius():Number{
			return _radius;
		}
		
		public function set mass(mass:Number):void{
			_mass = mass;
		}
		
		public function get mass():Number{
			return _mass;			
		}
		
		public function set color(color:uint):void{
			_color = color;
		}		
									
		public function get color():uint{
			return _color;
		}
		
		public function Ball(radius:Number=40, color:uint=0xff0000, text:String = null, textColor:uint = 0xffffff) {
			_radius = radius;
			_color = color;
			init();
			id = staticId++;
			setText(text,textColor);			
		}
		
		public function setText(text:String,textColor:uint):void{
			if(text){
				if(_textField != null){ //if we already have a text field
					removeChild(_textField);
				}
				_text = text;
				_textField = new TextField();
				var textFormat:TextFormat = new TextFormat();
				var font = new ComicSans();
				textFormat.font = font.fontName;
				textFormat.size = fontSize;
				
				_textField.border = false;
				_textField.selectable = false;
				_textField.autoSize = TextFieldAutoSize.CENTER;
				_textField.defaultTextFormat = textFormat;
				_textField.embedFonts = true;
				_textField.antiAliasType = AntiAliasType.ADVANCED;
				
				_textField.text = _text;								
				_textField.textColor = textColor;				
				
				//_textField.width = _radius;
				//_textField.height = _radius;
				_textField.x = -_textField.width/2;
				_textField.y = -_textField.height/2;
				addChild(_textField);
			}
		}
		
		public function init():void {
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(1.5*_radius, 1.5*_radius, 0, -_radius+(_radius*.5), -_radius-(_radius*.5));
			var colors:Array = [0xffffff, _color];
			var alphas:Array = [1.0, 1.0];
			var ratios:Array = [0, 255];
			
			if(_shape){
				removeChild(_shape);
			}
			_shape = new Shape();
			_shape.graphics.beginGradientFill(GradientType.RADIAL, colors, alphas, ratios, matrix);
			//_shape.graphics.beginFill(_color);
			_shape.graphics.drawCircle(0, 0, _radius);
			_shape.graphics.endFill();
			addChild(_shape);
			if(_textField){
				swapChildren(_shape, _textField);
			}
			if(_innerBall){
				swapChildren(_shape, _innerBall);
			}
		}
		
		public function redraw():void{
			init();
		}
		
		public function remove(color:uint = 0xffffff, text:String = null, textColor:uint = 0xff0000):void{
			_mass = 0;
			_color = color;
			init();
			if(text){
				_explosionTextField = new TextField();
				_explosionTextField.text = text;
				_explosionTextField.textColor = textColor;
				addChild(_explosionTextField);
			}
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function disappear():void{
			_mass = 0;
			if(_shape){
				removeChild(_shape);
				_shape = null;
			}
			if(_textField){
				removeChild(_textField);
				_textField = null;
			}
			if(_explosionTextField){
				removeChild(_explosionTextField);
				_explosionTextField = null;					
			}
			if(_innerBall){
				removeChild(_innerBall);
				_innerBall = null;
			}
		}
		
		private function onEnterFrame(event:Event):void{						
			this.scaleX *= (_countDown / 48);
			this.scaleY *= (_countDown / 48);
			if(!--_countDown){
				disappear();
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		public function fadeHex (hex, hex2, ratio){
			var r = hex >> 16;
			var g = hex >> 8 & 0xFF;
			var b = hex & 0xFF;
			r += ((hex2 >> 16)-r)*ratio;
			g += ((hex2 >> 8 & 0xFF)-g)*ratio;
			b += ((hex2 & 0xFF)-b)*ratio;
			_color = (r<<16 | g<<8 | b);
		}
		
		public function innerBall (radius:Number=20, color:uint=0xff0000, alpha:Number = 1){
			if(radius){
				this.removeInnerBall();
				_innerBall = new Ball(radius, color);
				_innerBall.alpha = alpha;
				addChild(_innerBall);
				if(_textField){
					swapChildren(_innerBall, _textField);
				}
			}
			if(alpha && _innerBall){ 
				_innerBall.alpha = alpha;
			}
		}
		
		public function removeInnerBall(){
			if(_innerBall){
				removeChild(_innerBall);
				_innerBall = null;
			}
		}
	}
}