package {
	import flash.text.TextFieldAutoSize;	
	import flash.display.Sprite;
	
	public class Scoreboard extends Sprite {
		static const RIGHT:String = TextFieldAutoSize.RIGHT;
		static const LEFT:String = TextFieldAutoSize.LEFT;
		static const CENTER:String = TextFieldAutoSize.CENTER;
		static const NONE:String = TextFieldAutoSize.NONE;
		
		public function setBoard(score:Number, label:String = null, orientation:String = Scoreboard.RIGHT):void{
			this.score.text = String(score);
			this.label.x = this.score.x - this.label.width;
			if(label)
				this.label.text = label;
			if(orientation)
				this.score.autoSize = orientation;
		}
	}
}
	