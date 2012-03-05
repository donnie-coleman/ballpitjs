(function(){
var c =	document.getElementById('c');
var fps = 1000 / 30,
	width = parseInt(c.style.width),
	height = parseInt(c.style.height),
	minLiveRadius = 20,
	maxLiveRadius = 10,
	splitRadius = 60,
	initLiveSpeedX = 7,
	initLiveSpeedY = 7,
	backgroundColor = '#ff0000',
	selectedColor = '#00ff00',
	unselectedColor = '#ffcc00',
	taintedColor = '#00ff00',
	obstacleColor = '#000000',
	hitColor = '#ffffff',
	newColor = '#ff0000',
	powerColor = '#0000ff',	
	unselectedTextColor = '#000000',
	paper = Raphael(c,width,height),
	dragok = false,
	currentBall = null,
	x = 0,
	y = 0;
	
var initLiveBalls = 4;
var liveBalls = initLiveBalls;
var initEnemyBalls = 2;
var enemyBalls = initEnemyBalls;
var newBalls = 0;

var totalBalls = function(){ return initLiveBalls + initEnemyBalls + newBalls };
var ballset = paper.set();
var balls = [];

var myMove = function(dx, dy){
	if(!this.deflating && this.dragging){
	 this.attr({cx: this.ox + dx, cy: this.oy + dy});
	 var radius = this.attr("r"); 
	 radius *= 1.005;
	 this.attr({r: radius});
	 if(radius >= splitRadius){
		splitBall(this);
	 }
	}
};

var myDown = function(){
	if(this.draggable && !this.deflating){
		this.ox = this.attr("cx");
	    this.oy = this.attr("cy");
	    this.dragging = true;
		this.attr({fill: "r(0.65, 0.35)#fff-"+selectedColor});
		currentBall = this;
	}
};

var myUp = function(){
	if(!this.deflating && this.dragging){
		this.attr({fill: "r(0.65, 0.35)#fff-"+selectedColor});
		this.deflating = true;	
		this.released = true;
		this.dragging = false;
		currentBall = null;
	}
};

var makeBall = function(quantity, config){
	for (var i = 0; i < quantity; i++){
	  var r = (Math.random()*config.radiusMax)+config.radiusMin;
	  var cx = config.isCoordsRandom?Math.random()*width:config.initX;
	  var cy = config.isCoordsRandom?Math.random()*height:config.initY;
	  var vx = config.isSpeedRandom?(Math.random() * config.speedX - (config.speedX/2)):config.speedX;
	  var vy = config.isSpeedRandom?(Math.random() * config.speedY - (config.speedY/2)):config.speedY;

	  var c = paper.circle(cx, cy, r).attr({fill: "r(0.65, 0.35)#fff-"+config.color});
	 
	  c.draggable = config.isDraggable?true:false;
	  if(c.draggable){
		c.released = false;
		c.dragging = false;
		c.drag(myMove, myDown, myUp);
	  }
	  
	  balls.push({color:config.color,
				 radius:r,
				 oradius:r,
				 vx:vx,
				 vy:vy,
				 x:cx, 
				 y:cy, 
				 text:i,
				 textColor:config.textColor,
				 ball: c});
	
	  ballset.push(c);
	}
};

var makeGoodBall = function(quantity){
	makeBall(quantity,
			{color:unselectedColor,
			 isDraggable:true,
			 radiusMin:minLiveRadius,
			 radiusMax:maxLiveRadius,
			 isSpeedRandom:true,
			 speedX:initLiveSpeedX,
			 speedY:initLiveSpeedY,
			 isCoordsRandom:true,
			 text:'x',
			 textColor:unselectedTextColor
			});
}

var makeBadBall = function(quantity){
	makeBall(quantity,
			{color:obstacleColor,
			 isDraggable:false,
			 radiusMin:minLiveRadius,
			 radiusMax:maxLiveRadius,
			 isSpeedRandom:true,
			 speedX:initLiveSpeedX,
			 speedY:initLiveSpeedY,
			 isCoordsRandom:true,
			 text:'x',
			 textColor:unselectedTextColor
			});
}

var makeKillerBall = function(quantity,x,y){
	makeBall(quantity,
			{color:newColor,
			 isDraggable:false,
			 radiusMin:minLiveRadius,
			 radiusMax:maxLiveRadius,
			 isSpeedRandom:true,
			 speedX:initLiveSpeedX,
			 speedY:initLiveSpeedY,
			 isCoordsRandom:false,
			 initX:x,
			 initY:y,
			 text:'x',
			 textColor:unselectedTextColor
			});
}
//init
//var background = paper.rect(x,y,width,height).attr({fill: backgroundColor});
makeGoodBall(initLiveBalls);
makeBadBall(initEnemyBalls);

var test = 0;
var MoveBalls = function(){
  detectCollisions(); //detect collisions first to make changes to x and y that will translate to cx and cy
  for (var i = 0; i < totalBalls(); i++) {
	var tmpBall = balls[i];
	if(tmpBall.ball.released){
		tmpBall.vx = Math.random()*initLiveSpeedX;
		tmpBall.vy = Math.random()*initLiveSpeedY;	
		tmpBall.x = tmpBall.ball.attr("cx"); 
		tmpBall.y = tmpBall.ball.attr("cy");
		tmpBall.ball.released = false;
		tmpBall.ball.deflating = true;
		test = 0;
		
		log("RELEASED", tmpBall.ball);
	 }	  
	  
	 //tmpBall.vx = tmpBall.ball.vx;
	 //tmpBall.vy = tmpBall.ball.vy;	 
	 if(!tmpBall.ball.dragging){
		if(tmpBall.radius > tmpBall.oradius){
			var radius = tmpBall.ball.attr("r"); 
	 		radius *= .95;
			tmpBall.ball.attr({r: radius});
		}
		else if(tmpBall.ball.deflating){
			tmpBall.ball.deflating = false;
			tmpBall.ball.deflated = true;
		}
		else if(tmpBall.ball.deflated){
			tmpBall.ball.attr({fill: "r(0.65, 0.35)#fff-"+unselectedColor});
		}

		checkWalls(tmpBall);

		tmpBall.x += tmpBall.vx;
		tmpBall.y += tmpBall.vy;

		tmpBall.ball.attr({cx:tmpBall.x, cy:tmpBall.y});
	 }
	 else{
		 tmpBall.x = tmpBall.ball.attr("cx");
		 tmpBall.y = tmpBall.ball.attr("cy");
		
		if(!test){
			test = 1;
			log("GRABBED",tmpBall.ball);
		}
	 }

	tmpBall.radius = tmpBall.ball.attr("r");	 
  }
};

var checkWalls = function(ball){
	if(ball.isDead) return;
	
	//console.log("ball.x="+ball.x+" ball.radius="+ball.radius+" width="+width);
	//console.log("ball.y="+ball.y+" ball.radius="+ball.radius+" height="+height);
	if (ball.x + ball.radius >= width) {
		ball.x = width - ball.radius;
		ball.vx *= -1
	} 
	else if (ball.x - ball.radius <= 0) {
		ball.x = ball.radius;
		ball.vx *= -1;
	} 
	
	if (ball.y + ball.radius >= height) {
		ball.y = height - ball.radius;
		ball.vy *= -1;
	} 
	else if (ball.y - ball.radius <= 0) {
		ball.y = ball.radius;
		ball.vy *= -1;
	}
};

var detectCollisions = function (){
	for(var i = 0; i < totalBalls() - 1; i++){
		var ballA = balls[i];
		if(ballA.isDead) continue; //if the ball doesn't have a mass, it's dead
		for(var j = i + 1; j < totalBalls(); j++){
			var ballB = balls[j];
			if(ballB.isDead) continue; //if the ball doesn't have a mass, it's dead
			if(!checkCollision(ballA, ballB))
				return;
		}
	}	
}

var checkCollision = function (ball0, ball1){
	//if(!(ball0.mass && ball1.mass)) return true; //@TODO: if either of the balls we're checking doesn't have mass, it doesn't exist. NEXT but really, only real balls should get this far
								  
	var dx = ball1.x - ball0.x;
	var dy = ball1.y - ball0.y;
	var dist = Math.sqrt(dx*dx + dy*dy);
	if(dist < ball0.radius + ball1.radius)	{	
		
					
		// calculate angle, sine and cosine
		var angle = Math.atan2(dy, dx);
		var sin = Math.sin(angle);
		var cos = Math.cos(angle);
		
		// rotate ball0's position
		var pos0  = [0, 0];
		
		// rotate ball1's position
		var pos1 = rotate(dx, dy, sin, cos, true);

		// rotate ball0's velocity
		var vel0 = rotate(ball0.vx,
								ball0.vy,
								sin,
								cos,
								true);
		
		// rotate ball1's velocity
		var vel1 = rotate(ball1.vx,
								ball1.vy,
								sin,
								cos,
								true);
								


		
		// collision reaction
		var vxTotal = vel0[0] - vel1[0];
		vel0[0] = vel1[0]; //((ball0.mass - ball1.mass) * vel0.x +2 * ball1.mass * vel1.x) /	(ball0.mass + ball1.mass);
		vel1[0] = vxTotal + vel0[0];
		/*
		if(ball0.ball.dragging){
			console.log("1: "+ball0.vx)
			console.log(vel0)
			console.log(vel1)
		}
		if(ball1.ball.dragging){
			console.log("2: "+ball1.vx)
			console.log(vel1)
			console.log(vel0)
		}*/
		// update position
		var absV = Math.abs(vel0[0]) + Math.abs(vel1[0]);
		var overlap = (ball0.radius + ball1.radius) 
						  - Math.abs(pos0[0] - pos1[0]);
		pos0[0] += vel0[0] / absV * overlap;
		pos1[0] += vel1[0] / absV * overlap;
		
		// rotate positions back
		var pos0F = rotate(pos0[0],
								  pos0[1],
								  sin,
								  cos,
								  false);
								  
		var pos1F = rotate(pos1[0],
								  pos1[1],
								  sin,
								  cos,
								  false);

		// adjust positions to actual screen positions
		ball1.x = ball0.x + pos1F[0];
		ball1.y = ball0.y + pos1F[1];
		ball0.x = ball0.x + pos0F[0];
		ball0.y = ball0.y + pos0F[1];
		
		// rotate velocities back
		var vel0F = rotate(vel0[0],
							  vel0[1],
							  sin,
							  cos,
							  false);
		var vel1F = rotate(vel1[0],
								  vel1[1],
								  sin,
								  cos,
								  false);
		ball0.vx = vel0F[0];
		ball0.vy = vel0F[1];
		ball1.vx = vel1F[0];
		ball1.vy = vel1F[1];

		if(currentBall){	
			if(ball1.ball.id == currentBall.id){
				log("My Current Ball Touched Something!",currentBall);
				
				if(ball0.color == unselectedColor)
					absorbBall(ball0);
				//else if(ball0.color == powerColor)
				//	absorbPowerball(ball0);
				else
					killBall(ball1);					
			}
			else if(ball0.ball.id == currentBall.id){
				log("Something Touched my Current Ball!",currentBall)

				if(ball1.color == unselectedColor)
					absorbBall(ball1);
				//else if(ball1.color == powerColor)
				//	absorbPowerball(ball1);
				else
					killBall(ball0);					
			}						
		}
		
		if(ball0.color == newColor && ball1.color == obstacleColor){
			if(!removeObstacleBall(ball0,ball1))
				return false; //this is to stop processing in onEnterFrame if this round is over
		}
		else if (ball1.color == newColor && ball0.color == obstacleColor){
			if(!removeObstacleBall(ball1,ball0))
				return false; //this is to stop processing in onEnterFrame if this round is over
		}
	}

	return true;
};

var rotate = function (x, y,	sin,	cos,	reverse){
	var result = [0,0];
	if(reverse){
		result[0] = x * cos + y * sin;
		result[1] = y * cos - x * sin;
	}
	else{
		result[0] = x * cos - y * sin;
		result[1] = y * cos + x * sin;
	}
	return result;
};	

var absorbBall = function(ball){
	log("ABSORB",ball);
	removeBall(ball);
	if(--liveBalls <= 0){
		showRestartButton();
	}
	else{
		log(liveBalls+" live balls...");
	}
}

var absorbPowerBall = function(ball){
	removeBall(ball);
	//add time to the clock
}

var killBall = function(ball){
	log("KILL",ball);
	//TODO: do not transfer momentum to the killer ball
	removeBall(ball);
	//if no more live balls, end the game
	if(--liveBalls <= 0){		
		showRestartButton();
	}
	else{
		log(liveBalls+" live balls ");
	}
}

var removeObstacleBall = function(nBall,oBall){
	removeBall(oBall);
	//if no more bad balls, end the game
	if(--enemyBalls <= 0){
		showNextLevelButton();
	}
	else{
		log(enemyBalls+" enemy balls");
	}
	//change nBall into a pBall
	nBall.ball.attr({fill:"r(0.65, 0.35)#fff-"+unselectedColor});
	nBall.color = unselectedColor;
	nBall.ball.draggable = true;
	nBall.ball.drag(myMove, myDown, myUp);
	liveBalls++;
}

var removeBall = function(ball){
	ball.ball.hide(); //because ball.ball.undrag(); and ball.ball.remove(); doesn't work
	ball.isDead = true;
	ball.vx = 0;
	ball.vy = 0;
}

var splitBall = function(rBall){
	rBall.released  = true;
	rBall.dragging = false;
	makeKillerBall(1,rBall.attr("cx")+rBall.attr("r"),rBall.attr("cy"));
	currentBall = null;
	newBalls++;
}

var log = function(message,ball){
	if(window.console && console.log){
		console.log("*********"+message);
		if(ball){		
			console.log(ball);
		}
	}	
}

var showRestartButton = function(){
	clearTimeout(gLoop);
	ballset.hide();
	showMessage("You Lost!");
	showButton("Restart", gameRestart);
}

var gameRestart = function(){
	location.reload();
}

var showNextLevelButton = function(){
	clearTimeout(gLoop);
	ballset.hide();
	showMessage("You Won!");
	showButton("Restart",nextLevel);
}

var nextLevel = function(){
	location.reload();
}

var showMessage = function(msg){
	paper.text(width/2,30,msg).attr({"font-size":"30px","color":"black"});
}

var showButton = function(title,func){
	var button = paper.set();
	button.push(paper.rect(width/2-50, height/4, 100, 50, 10).attr({"stroke": "#000", "stroke-width": "2", "fill": "#fff"}));
	button.push(paper.text(width/2,height/4+25,title).attr({"font-size":"20px"}));
	button.attr({cursor:"pointer"});
	button.click(func);
}

var gLoop = null;
var GameLoop = function(){
	gLoop = setTimeout(GameLoop, fps);
	MoveBalls();
};

GameLoop();
})();

//TODO: make button plugin that can has text