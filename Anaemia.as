package
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.system.System;
	
	public class Anaemia extends Sprite
	{
			
		private var _level:uint = 1;
		private var balls:Array;
		private const totalBallsInit:uint = 7;
		private var totalBalls:uint = totalBallsInit;
		private const liveBallsInit:uint = totalBallsInit - 1;
		private var liveBalls:uint = liveBallsInit;
		private var obstacleBalls:uint = totalBalls - liveBalls;
		private var newBalls:uint = 0;
		private var deadBalls:uint = 0;
		private var deadObstacles:uint = 0;
		private var powerBalls:uint = 0;
		
		private var initLiveSpeed:uint = 10;
		private var initObstacleSpeed:uint = 20;
		
		private var maxLiveRadius:Number = 10;
		private var maxObstacleRadius:Number = maxLiveRadius;
		private var minLiveRadius:Number = 20;
		private var minObstacleRadius:Number = minLiveRadius;
		private const splitRadius:Number = minLiveRadius*3;
		
		private var currentBall:Ball = null;
		
		private const bounce:Number = -1.0;
		
		private const selectedColor:uint = 0x00ff00;
		private const unselectedColor:uint = 0xffcc00;
		private const taintedColor:uint = 0x00ff00;
		private const obstacleColor:uint = 0x000000;		
		private const hitColor:uint = 0xffffff;
		private const newColor:uint = 0xff0000;
		private const powerColor:uint = 0x0000ff;
		
		private var _score:Number = 0;
		private var _highscore:Number = 0;
		private const pointFactor:Number = .05;
		private var explosionPenalty:Number = 0;//liveBalls*pointFactor*1428;
		private var _extraLevels:uint = 0;
		private var absorptionMultiplier:Number = .3;
		
		private const growthFactor:Number = 1.005;
		private const shrinkFactor:Number = .97;
		
		private var stopGame:Boolean = false;
		private var mouseLeft:Boolean = false;
		
		private var _gameoverbtn:MovieClip = null;		
		private var _nextlevelbtn:MovieClip = null;		
		private const TIMELIMIT:uint = 30;
		private var _time:uint = 0;
		private var _myTimer:Timer = null;
		
		private const POWERUPINCREMENT:uint = 1000;
		private var _nextpowerup:uint = POWERUPINCREMENT;
		private const POWERUPBONUS:uint = 4; //seconds
	
		public function Anaemia(){
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			mc_Background.width = stage.stageWidth;
			mc_Background.height = stage.stageHeight - mc_footer.height; //footer height
			
			mc_timer = mc_timer;
			
			mc_scoreboard.setBoard(_score,"SCORE:",Scoreboard.RIGHT);
			mc_levelboard.setBoard(_level,"LEVEL:",Scoreboard.LEFT);
			
			init();			
		}
		
		private function onNextLevelRestart(event:Event):void{
			if(_nextlevelbtn){
				_nextlevelbtn.mc_next.removeEventListener(MouseEvent.CLICK, onNextLevelRestart);
				removeChild(_nextlevelbtn);
				_nextlevelbtn=null;
			}			
			//trace("extra levels = "+_extraLevels);
			//trace("total Balls init = "+totalBallsInit);
			//trace("level = "+_level);					
					
			restart(_extraLevels + totalBallsInit-_level, _extraLevels + totalBallsInit);
		}
		
		private function onGameOverRestart(event:Event):void{
			if(_gameoverbtn){
				_gameoverbtn.again.removeEventListener(MouseEvent.CLICK, onGameOverRestart);
				_gameoverbtn.startover.removeEventListener(MouseEvent.CLICK, onGameRestart);
				removeChild(_gameoverbtn);
				_gameoverbtn=null;
			}
			_score = 0;
			_nextpowerup = POWERUPINCREMENT;
			
			restart(_extraLevels + totalBallsInit-_level, _extraLevels + totalBallsInit);
		}
		
		private function onGameRestart(event:Event):void{
			if(_gameoverbtn){
				_gameoverbtn.again.removeEventListener(MouseEvent.CLICK, onGameOverRestart);
				_gameoverbtn.startover.removeEventListener(MouseEvent.CLICK, onGameRestart);
				removeChild(_gameoverbtn);
				_gameoverbtn=null;
			}
			_score = 0;
			_level = 1;
			_extraLevels = 0;
			_nextpowerup = POWERUPINCREMENT;
			
			restart();
		}
		
		private function restart(newLiveBalls:uint = liveBallsInit, newTotalBalls:uint=totalBallsInit):void{
			for(var i:uint = 0; i < getTotalBalls(); i++){
				removeChild(balls[i]);
				balls[i] = null;
			}
			liveBalls = newLiveBalls;
			obstacleBalls = newTotalBalls - newLiveBalls;
			stopGame = false;
			deadBalls = 0;
			deadObstacles = 0;
			newBalls = 0;
			currentBall = null;

			init();
		}	
		
		private function setTimer(seconds:uint):void{
			_time = seconds;
			_myTimer = new Timer(1000, _time);
			_myTimer.addEventListener(TimerEvent.TIMER,onTimerEvent);
			_myTimer.start();
		}
		
		private function resetTimer(seconds:uint):void{
			_time += seconds;
			_myTimer.repeatCount = _time;
		}
		
		private function onTimerEvent(event:TimerEvent) {
			mc_timer.time.text = String(_time-_myTimer.currentCount);
			if (_time-_myTimer.currentCount == 0) {
				endGame();
			}
		}

		private function init():void{
			mc_levelboard.setBoard(_level); 
			mc_timer.time.text = String(TIMELIMIT);
			
			powerBalls = 0;
			balls = new Array();
			var ball:Ball = null;
			for(var i:int = 0; i < liveBalls; i++){
				ball = addBall(unselectedColor, minLiveRadius, maxLiveRadius, initLiveSpeed, initLiveSpeed, true, mc_Background.width, mc_Background.height, true, ":-)", 0x000000);
				ball.addEventListener(MouseEvent.MOUSE_DOWN, onBallSelect,false,0,true);
				ball.addEventListener(MouseEvent.MOUSE_UP, onBallUnSelect,false,0,true);
			}
			for(i = 0; i < obstacleBalls; i++){
				ball = addBall(obstacleColor, minObstacleRadius, maxObstacleRadius, initObstacleSpeed, initObstacleSpeed, true, 0, mc_Background.height, true, "X", 0xff0000);
				ball.mass = 50;
			}
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMovement);
			
			setTimer(TIMELIMIT);
		}
		
		private function isMouseLeft():Boolean{
			if(mouseX > mc_Background.width || mouseX < 0 || mouseY > mc_Background.height || mouseY < 0){
				//trace("mouse has left");
				return true;
			}
			return false;
		}
		
		private function onMouseMovement(event:Event):void{
			//are we holding  ball?
			if(currentBall){
				//if cursor is outside the stage, let _gameoverbtn of the ball
				if(isMouseLeft()){
					onBallUnSelect(event);
					return;
				}
				if(currentBall.radius >= splitRadius){
					splitBall(event);
					return;
				}
				//as the mouse moves, grow the ball
				currentBall.radius = currentBall.radius*growthFactor;
				var ratio:Number = ((currentBall.radius-currentBall.mass)/(splitRadius-currentBall.mass));
				//change color slightly  selectedColor -> taintedColor::currentBall.mass->minLiveRadius*2
				currentBall.fadeHex(unselectedColor, taintedColor, ratio);
				currentBall.innerBall(0,0,ratio);
				//trace("radius = "+ratio);
				//trace("radius = "+currentBall.radius);
				//trace("mass ="+currentBall.mass);
				//trace("color = "+currentBall.color.toString(16));
				currentBall.x = mouseX;
				currentBall.y = mouseY;			
				currentBall.redraw();
				_score += currentBall.radius * (liveBalls - deadBalls) * pointFactor;
				//trace("liveBalls = "+liveBalls);
				//trace("deadBalls = "+deadBalls);
			}
		}
		
		private function splitBall(event:Event):void{
			var oldball:Ball = event.currentTarget as Ball;
			if(!oldball){ //would happen if a ball ran into currentBall and pushed currentBall over the threshold
				oldball = currentBall;			
			}
			onBallUnSelect(event); //sets currentBall = null, which is why we do it before we use oldball
			addExplosion(oldball.x+oldball.radius, oldball.y);
			var ball:Ball = addBall(newColor, minLiveRadius, maxLiveRadius, -oldball.vx, -oldball.vy, false, oldball.x+oldball.radius, oldball.y, false, "X", 0x000000);
			newBalls++;
		}
		
		private function onBallUnSelect(event:Event):void{
			if(stopGame || !currentBall) return;
			currentBall.color = taintedColor;			
			currentBall.tainted = (currentBall.radius / (currentBall.radius + currentBall.mass )) * 100;
			currentBall.vx = Math.random() * initLiveSpeed;
			currentBall.vy = Math.random() * minLiveRadius - minLiveRadius/2;
			currentBall.setText("X",0x000000);
			currentBall.removeInnerBall();
			currentBall.redraw();	
			currentBall = null;
		}
		
		private function onBallSelect(event:Event):void{
			//cannot select tainted balls
			//use currentTarget so that event returns the parent, to whom the event listener was explicitly added (not the children)
			if(stopGame || (event.currentTarget as Ball).color == taintedColor || (event.currentTarget as Ball).color == newColor) return;
			currentBall = event.currentTarget as Ball;
			currentBall.vx = 0;
			currentBall.vy = 0;
			currentBall.x = mouseX;
			currentBall.y = mouseY;							
			currentBall.setText(":-O",0x000000);			
			currentBall.redraw();
			currentBall.innerBall(25, 0xff0000, 0);			
		}
		
		private function getTotalBalls():uint{
			return liveBalls + obstacleBalls + newBalls + powerBalls;
			
		}
		
		private function onEnterFrame(event:Event):void{
//var mem:String = Number( System.totalMemory / 1024 / 1024 ).toFixed( 2 ) + 'Mb';
//trace( mem ); // eg traces “24.94Mb”
			var score:Number = Math.round(_score);
			mc_scoreboard.setBoard(score);
			if(score >= _nextpowerup){
				var powerball:Ball = addBall(powerColor, minLiveRadius, maxLiveRadius, initLiveSpeed, initLiveSpeed, true, mc_Background.width, mc_Background.height, true,"+"+_level);
				_nextpowerup += POWERUPINCREMENT;
				powerball.mass = 1000;
				powerBalls++;
			}
			
			for(var i:int = 0; i < getTotalBalls(); i++){
				var ball:Ball = balls[i];
				//trace("ball_1[i]="+i);
				if(!ball.mass) continue; //if the ball doesn't have a mass, it's dead
				//tainted means that the ball is red, bigger than normal and unselectable
				
				if(ball.tainted > 0){
					ball.color = taintedColor;
					ball.radius = ball.radius * shrinkFactor;
					if(ball.radius <= ball.mass){
						ball.color = unselectedColor;
						ball.tainted = 0;
						ball.radius = ball.mass;
						ball.setText(":-)",0x000000);
					}
					else { 						
						ball.tainted *= shrinkFactor;						
					}
					ball.redraw();	
				}
				
				//set the position of the ball according to its current speed
				ball.x += ball.vx;
				ball.y += ball.vy;
				
				checkWalls(ball);
			}
			
			for(i = 0; i < getTotalBalls() - 1; i++){
				var ballA:Ball = balls[i];
				if(!ballA.mass) continue; //if the ball doesn't have a mass, it's dead
				for(var j:int = i + 1; j < getTotalBalls(); j++){
					var ballB:Ball = balls[j];
					if(!ballB.mass) continue; //if the ball doesn't have a mass, it's dead
					if(!checkCollision(ballA, ballB))
						return;
				}
			}			
		}
		
		private function checkWalls(ball:Ball):void{
			//check speed of ball to determine which direction it's moving in
			
			if(ball.x - ball.radius > mc_Background.width){
				ball.x = ball.radius;
			}
			else if(ball.x + ball.radius < 0){	
				ball.x = mc_Background.width - ball.radius;
			}
			
			if(ball.y + ball.radius > mc_Background.height){
				ball.y = mc_Background.height - ball.radius;
				ball.vy *= bounce;
			}
			else if(ball.y - ball.radius < 0){
				ball.y = ball.radius;
				ball.vy *= bounce;
			}
		}

		private function checkCollision(ball0:Ball, ball1:Ball):Boolean{
			var dx:Number = ball1.x - ball0.x;
			var dy:Number = ball1.y - ball0.y;
			var dist:Number = Math.sqrt(dx*dx + dy*dy);
			if(dist < ball0.radius + ball1.radius)	{				
				// calculate angle, sine and cosine
				var angle:Number = Math.atan2(dy, dx);
				var sin:Number = Math.sin(angle);
				var cos:Number = Math.cos(angle);
				
				// rotate ball0's position
				var pos0:Point = new Point(0, 0);
				
				// rotate ball1's position
				var pos1:Point = rotate(dx, dy, sin, cos, true);
				
				// rotate ball0's velocity
				var vel0:Point = rotate(ball0.vx,
										ball0.vy,
										sin,
										cos,
										true);
				
				// rotate ball1's velocity
				var vel1:Point = rotate(ball1.vx,
										ball1.vy,
										sin,
										cos,
										true);
				
				// collision reaction
				var vxTotal:Number = vel0.x - vel1.x;
				vel0.x = ((ball0.mass - ball1.mass) * vel0.x + 
				          2 * ball1.mass * vel1.x) / 
				          (ball0.mass + ball1.mass);
				vel1.x = vxTotal + vel0.x;

				// update position
				var absV:Number = Math.abs(vel0.x) + Math.abs(vel1.x);
				var overlap:Number = (ball0.radius + ball1.radius) 
				                      - Math.abs(pos0.x - pos1.x);
				pos0.x += vel0.x / absV * overlap;
				pos1.x += vel1.x / absV * overlap;
				
				// rotate positions back
				var pos0F:Object = rotate(pos0.x,
										  pos0.y,
										  sin,
										  cos,
										  false);
										  
				var pos1F:Object = rotate(pos1.x,
										  pos1.y,
										  sin,
										  cos,
										  false);

				// adjust positions to actual screen positions
				ball1.x = ball0.x + pos1F.x;
				ball1.y = ball0.y + pos1F.y;
				ball0.x = ball0.x + pos0F.x;
				ball0.y = ball0.y + pos0F.y;
				
				// rotate velocities back
				var vel0F:Object = rotate(vel0.x,
										  vel0.y,
										  sin,
										  cos,
										  false);
				var vel1F:Object = rotate(vel1.x,
										  vel1.y,
										  sin,
										  cos,
										  false);
				ball0.vx = vel0F.x;
				ball0.vy = vel0F.y;
				ball1.vx = vel1F.x;
				ball1.vy = vel1F.y;
				if(currentBall){					
					if(ball1.id == currentBall.id){
						if(ball0.color == unselectedColor)
							absorbBall(ball0);
						else if(ball0.color == powerColor)
							absorbPowerball(ball0);
						else
							killBall(ball0);					
					}
					else if(ball0.id == currentBall.id){
						if(ball1.color == unselectedColor)
							absorbBall(ball1);
						else if(ball1.color == powerColor)
							absorbPowerball(ball1);
						else
							killBall(ball1);					
					}						
				}
				if(ball0.color == newColor && ball1.color == obstacleColor){
					if(!removeObstacleBall(ball0,ball1))
						return false; //this is to stop processing in onEnterFrame
				}
				else if (ball1.color == newColor && ball0.color == obstacleColor){
					if(!removeObstacleBall(ball1,ball0))
						return false; //this is to stop processing in onEnterFrame
				}
			}
			return true;
		}
		
		private function rotate(x:Number, y:Number,	sin:Number,	cos:Number,	reverse:Boolean):Point{
			var result:Point = new Point();
			if(reverse){
				result.x = x * cos + y * sin;
				result.y = y * cos - x * sin;
			}
			else{
				result.x = x * cos - y * sin;
				result.y = y * cos + x * sin;
			}
			return result;
		}		
			
		private function removeObstacleBall(newBall:Ball, obstacleBall:Ball):Boolean{
			obstacleBall.remove();
			newBall.color = unselectedColor;
			newBall.setText(":-)",0x000000);
			newBall.redraw();
			newBall.addEventListener(MouseEvent.MOUSE_DOWN, onBallSelect,false,0,true);
			newBall.addEventListener(MouseEvent.MOUSE_UP, onBallUnSelect,false,0,true);
			newBalls--;
			liveBalls++;
			if(++deadObstacles >= obstacleBalls){
				nextLevel(); //win game!
				return false;
			}			
			return true;
		}
		
		private function absorbPowerball(otherBall:Ball):void{
			otherBall.remove();
			currentBall.x = mouseX;
			currentBall.y = mouseY;
			currentBall.vx = 0; //because we determine if we collide AFTER we do the energy xfer calculations, we have to set these to 0
			currentBall.vy = 0;
			
			resetTimer(_level);
			onTimerEvent(new TimerEvent("dummy"));
		}
				
		private function absorbBall(otherBall:Ball):void{
			_score += explosionPenalty;
			
			otherBall.disappear();
			if(currentBall.radius + otherBall.radius * absorptionMultiplier < splitRadius) {
				currentBall.radius += otherBall.radius * absorptionMultiplier;
			}
			else {
				currentBall.radius = splitRadius;
			}
			var ratio:Number = ((currentBall.radius-currentBall.mass)/(splitRadius-currentBall.mass));
			currentBall.fadeHex(unselectedColor, taintedColor, ratio);
			currentBall.x = mouseX;
			currentBall.y = mouseY;
			currentBall.vx = 0; //because we determine if we collide AFTER we do the energy xfer calculations, we have to set these to 0
			currentBall.vy = 0;
			currentBall.redraw();
			if(currentBall.radius >= splitRadius){
				splitBall(new Event("dummy"));				
			}
			
			//if you absorb too many balls, game over, man. game over
			if(++deadBalls >= liveBalls){
				endGame();
			}
		}
		
		private function killBall(otherBall:Ball):void{
			if(otherBall.color == newColor){
				otherBall.remove();
				otherBall = null;
			}
			currentBall.remove();
			currentBall.removeEventListener(MouseEvent.MOUSE_DOWN, onBallSelect);
			currentBall.removeEventListener(MouseEvent.MOUSE_UP, onBallUnSelect);
			currentBall = null;
			_score -= Math.round(explosionPenalty);
			if(_score < 0) _score = 0;
			if(++deadBalls >= liveBalls){				
				endGame();
			} else {
			}
		}
		
		private function nextLevel(){
			_myTimer.removeEventListener(TimerEvent.TIMER,onTimerEvent);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovement);

			stopGame = true;

			if(++_level >= totalBallsInit){
				_extraLevels++
			}
			
			_nextlevelbtn = new NextLevel();
			_nextlevelbtn.x = (mc_Background.width) / 2;
			_nextlevelbtn.y = (mc_Background.height) / 2;
			_nextlevelbtn.mc_next.buttonMode = true;
			_nextlevelbtn.mc_next.addEventListener(MouseEvent.CLICK, onNextLevelRestart);
			addChild(_nextlevelbtn);
		}
		
		private function endGame(){
			_myTimer.removeEventListener(TimerEvent.TIMER,onTimerEvent);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMovement);
				
			stopGame = true;
			
			if(_score > _highscore) 
				_highscore = _score;
			_gameoverbtn = new GameOver();
			_gameoverbtn.x = (mc_Background.width-_gameoverbtn.width) / 2;
			_gameoverbtn.y = 0;
			_gameoverbtn.score.text = Math.round(_score);
			_gameoverbtn.highscore.text = Math.round(_highscore);
			
			_gameoverbtn.again.buttonMode = true;
			_gameoverbtn.again.addEventListener(MouseEvent.CLICK, onGameOverRestart);
			
			_gameoverbtn.startover.buttonMode = true;
			_gameoverbtn.startover.mouseChildren = false;
			_gameoverbtn.startover.addEventListener(MouseEvent.CLICK, onGameRestart);
			addChild(_gameoverbtn);
		}
		
		private function addBall(color:uint, 
								  radiusMin:Number, radiusMax:Number, 
								  speedX:Number, 
								  speedY:Number,
								  randomSpeed:Boolean,
								  initX:Number, initY:Number, 
								  randomCoords:Boolean,
								  text:String=null,
								  textColor:uint = 0xffffff):Ball{
			var radius:Number = Math.random() * radiusMax + radiusMin;
			var ball:Ball = new Ball(radius,color,text,textColor);
			ball.mass = radius;
			ball.x = initX * (randomCoords?Math.random():1);
			ball.y = initY * (randomCoords?Math.random():1);
			ball.vx = speedX * (randomSpeed?Math.random():1);
			ball.vy = randomSpeed?(Math.random() * speedY - (speedY/2)):speedY;
			addChild(ball);
			balls.push(ball);
				
			return ball;
		}
		
		function addExplosion(_targetX:Number, _targetY:Number, _explosionParticleAmount:Number = 15, _distance:Number = 30, _explosionSize:Number = 1, _explosionAlpha:Number = 75):void{
			//run a for loop based on the amount of explosion particles
			for(var i = 0; i < _explosionParticleAmount; i++)
			{
				//create particle
				var _tempClip2:MovieClip = new explosion2(); 
				var _tempClip:MovieClip = new explosion();
		
				//set particle position
				_tempClip.x = _targetX+Math.random()*_distance-(_distance/2);
				_tempClip.y = _targetY+Math.random()*_distance-(_distance/2);		
				_tempClip2.x = _targetX+Math.random()*_distance-(_distance/2);
				_tempClip2.y = _targetY+Math.random()*_distance-(_distance/2);
									
				//get random particle scale
				var tempRandomSize:Number = Math.random()*_explosionSize+_explosionSize/2;
				//set particle scale
				_tempClip.scaleX = tempRandomSize;
				_tempClip.scaleY = tempRandomSize;
				//get random particle scale
				tempRandomSize = Math.random()*_explosionSize+_explosionSize/2;
				//set particle scale
				_tempClip2.scaleX = tempRandomSize;
				_tempClip2.scaleY = tempRandomSize;
									
				//set particle alpha
				_tempClip.alpha = Math.random()*_explosionAlpha+_explosionAlpha/4;
				_tempClip2.alpha = Math.random()*_explosionAlpha+_explosionAlpha/4;
				this.addChild(_tempClip2);
				this.addChild(_tempClip);
			}
		}
	}
}