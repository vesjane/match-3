package  {
	
	import flash.display.MovieClip;
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.Timer;
	import com.FlippingBook.Page.IPage;
	import com.FlippingBook.Page.PageProxy;
	import flash.filters.GlowFilter;
	
	public class MatchTree extends MovieClip implements IPage {
		
		
		static const numPieces:uint = 7;
		static const spacing:Number = 48;
		static const offsetX:Number = 90;
		static const offsetY:Number = 170;
		static const deltaSpacing:Number = 8;
		
		private var grid:Array;
		private var gameSprite:Sprite;
		private var firstPiece:Piece;
		private var isDropping,isSwapping:Boolean;
		private var gameScore:int;		
		
		public var gameTime:int;
		public var levelDuration:int = 20;
		private var gameTimer:Timer;
		private var isFirstClick:Boolean;
		private var isPause:Boolean = false;
		
		private var bookProxy:PageProxy;		
		
		public function setBookPage(bookPage:*):void
		{
			bookProxy =  new PageProxy(bookPage);
			bookProxy.addEventListener(PageProxy.PAGE_CLOSE_EVENT,onPageClose);
		}
		
		private function onPageClose(e:Event):void
		{			
			
			
		}
		
		
		public function startMatchThree() {					
			init();
			isFirstClick = false;
			gameScore = 0;
			gameTime = levelDuration;
			gameTimer = new Timer(1000,levelDuration);
			gameTimer.addEventListener(TimerEvent.TIMER, updateTime);
			gameTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeExpired);
			MovieClip(root).timerText.text = String(gameTime);
			
		}
		
		private function updateGemeTimer(newValue:Number)
		{
			gameTimer.removeEventListener(TimerEvent.TIMER, updateTime);
			gameTimer.removeEventListener(TimerEvent.TIMER, timeExpired);
			gameTimer.stop();
			gameTimer = new Timer(1000,newValue);
			gameTimer.addEventListener(TimerEvent.TIMER, updateTime);
			gameTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeExpired);
			gameTimer.start();
		}
		private function init():void
		{
			grid = new Array();
			for(var gridrows:int=0;gridrows<8;gridrows++) {
				grid.push(new Array());
			}
			setUpGrid();
			isDropping = false;
			isSwapping = false;
			addEventListener(Event.ENTER_FRAME,movePieces);
		}
		
		function updateTime(e:TimerEvent):void
		{			
			gameTime--;
			MovieClip(root).timerText.text = String(gameTime);
		
		}
		
		function timeExpired(e:TimerEvent):void
		{
			var gameTimer:Timer = e.target as Timer;
			gameTimer.removeEventListener(TimerEvent.TIMER, updateTime);
			gameTimer.removeEventListener(TimerEvent.TIMER, timeExpired);
			endGame();			
		}
		
		public function initNewPieces() {
			for(var i:int=0;i<8;i++) {
					for(var j:int=0;j<8;j++) {
						grid[i][j] = null;
					}
			}
			for(var col:int=0;col<8;col++) {
				var missingPieces:int = 0;
				for(var row:int=7;row>=0;row--) {
					if (grid[col][row] == null) {
						var newPiece:Piece = addPiece(col,row);
						newPiece.visible = false;
						newPiece.y = offsetY-spacing-spacing*missingPieces++;						
						isDropping = true;
					}
				}
			}
		}
		
	public function setUpGrid() {			
			while (true) {				
				gameSprite = new Sprite();				
				initNewPieces();
				isPause = false;				
				
				if (lookForMatches().length != 0) continue;					
				if (lookForPossibles() == false) continue;				
				break;
			} 			
			
			addChild(gameSprite);
		}		
		
		public function addPiece(col,row:int):Piece {
			var newPiece:Piece = new Piece();
			newPiece.x = col*spacing+offsetX;
			newPiece.y = row*spacing+offsetY;			
			newPiece.col = col;
			newPiece.row = row;
			newPiece.type = Math.ceil(Math.random()*7);
			newPiece.gotoAndStop(newPiece.type);
			newPiece.select.visible = false;
			gameSprite.addChild(newPiece);
			grid[col][row] = newPiece;
			newPiece.addEventListener(MouseEvent.CLICK,clickPiece);
			return newPiece;
		}
		
		
		public function clickPiece(event:MouseEvent) {
			var piece:Piece = Piece(event.currentTarget);
			
			
			if (firstPiece == null) {
				piece.select.visible = true;
				firstPiece = piece;			
			
			} else if (firstPiece == piece) {
				piece.select.visible = false;
				firstPiece = null;				
			
			
			} else {
				firstPiece.select.visible = false;				
				
				if ((firstPiece.row == piece.row) && (Math.abs(firstPiece.col-piece.col) == 1)) {
					makeSwap(firstPiece,piece);
					firstPiece = null;					
				
				} else if ((firstPiece.col == piece.col) && (Math.abs(firstPiece.row-piece.row) == 1)) {
					makeSwap(firstPiece,piece);
					firstPiece = null;					
				
				} else {
					firstPiece = piece;
					firstPiece.select.visible = true;		
					
				}
			}
			if(!isFirstClick)
			{
				isFirstClick = true;
				gameTimer.start();
				MovieClip(root).stopBtn.visible = true;
				MovieClip(root).playBtn.visible = false;
				isPause = false;
			}
		}

		public function setGamePause():void
		{
			gameTimer.stop();
			isPause = true;
		}
		
		public function gamePauseReset():void
		{
			gameTimer.start();
			isPause = false;
		}
		
		public function makeSwap(piece1,piece2:Piece) {
			swapPieces(piece1,piece2);			
			if (lookForMatches().length == 0) {				
				swapPieces(piece1,piece2);				
			} else {
				isSwapping = true;
			}
		}		
		
		public function swapPieces(piece1,piece2:Piece) {			
			var tempCol:uint = piece1.col;
			var tempRow:uint = piece1.row;
			piece1.col = piece2.col;
			piece1.row = piece2.row;
			piece2.col = tempCol;
			piece2.row = tempRow;			
			
			grid[piece1.col][piece1.row] = piece1;
			grid[piece2.col][piece2.row] = piece2;
			
		}		
		
		public function moveAnimation():Boolean
		{
			var madeMove:Boolean = false;
			for(var row:int=0;row<8;row++) {
				for(var col:int=0;col<8;col++) {
					if (grid[col][row] != null) {		
					grid[col][row].visible = false;
						// needs to move down
						if (grid[col][row].y < grid[col][row].row*spacing+offsetY) {
							grid[col][row].y += deltaSpacing;
							madeMove = true;
							
						// needs to move up
						} else if (grid[col][row].y > grid[col][row].row*spacing+offsetY) {
							grid[col][row].y -= deltaSpacing;
							madeMove = true;
							
						// needs to move right
						} else if (grid[col][row].x < grid[col][row].col*spacing+offsetX) {
							grid[col][row].x += deltaSpacing;
							madeMove = true;
							
						// needs to move left
						} else if (grid[col][row].x > grid[col][row].col*spacing+offsetX) {
							grid[col][row].x -= deltaSpacing;
							madeMove = true;
						}
						if (grid[col][row].y >= offsetY-spacing/2)
							{
								grid[col][row].visible = true;
							}
					}
				}
			}
			
			return madeMove;
			
		}
		public function movePieces(event:Event) {
			if(!isPause)
			{
				var madeMove:Boolean = moveAnimation();			
				// if all dropping is done
				if (isDropping && !madeMove) {
					isDropping = false;
					findAndRemoveMatches();
					
				// if all swapping is done
				} else if (isSwapping && !madeMove) {
					isSwapping = false;
					findAndRemoveMatches();
				}
			}
			
		}
				
		function removePieceAnimation():void
		{
			
		}
		
		// gets matches and removes them, applies points
		public function findAndRemoveMatches() {
			// get list of matches
			var matches:Array = lookForMatches();
			for(var i:int=0;i<matches.length;i++) {
				var numPoints:Number = (matches[i].length-1)*50;
				for(var j:int=0;j<matches[i].length;j++) {
					if (gameSprite.contains(matches[i][j])) {
						var pb = new PointBurst(this,numPoints,matches[i][j].x,matches[i][j].y);						
						addScore(numPoints);
						gameSprite.removeChild(matches[i][j]);
						grid[matches[i][j].col][matches[i][j].row] = null;
						affectAbove(matches[i][j]);
						
					}
				}
				if(matches[i].length >3)
						{
							gameTime+=15;		
							updateGemeTimer(gameTime);		
							var timeAdd = new PointBurst(this,"+15",MovieClip(root).timerText.x-15,MovieClip(root).timerText.y);
							MovieClip(root).timerText.text = String(gameTime);
						}
			}
			
			addNewPieces();			
			
			if (matches.length == 0) {
				if (!lookForPossibles()) {					
					cleanUp();
					init();
				}
			}
		}
		
		
		public function lookForMatches():Array {
			var matchList:Array = new Array();
			
			// search for horizontal matches
			for (var row:int=0;row<8;row++) {
				for(var col:int=0;col<6;col++) {
					var match:Array = getMatchHoriz(col,row);
					if (match.length > 2) {
						matchList.push(match);
						col += match.length-1;
					}
				}
			}
			
			// search for vertical matches
			for(col=0;col<8;col++) {
				for (row=0;row<6;row++) {
					match = getMatchVert(col,row);
					if (match.length > 2) {
						matchList.push(match);
						row += match.length-1;
					}
						
				}
			}
			return matchList;
		}		
		
		public function getMatchHoriz(col,row):Array {
			var match:Array = new Array(grid[col][row]);
			for(var i:int=1;col+i<8;i++) {
				if (grid[col][row].type == grid[col+i][row].type) {
					match.push(grid[col+i][row]);
				} else {
					return match;
				}
			}
			return match;
		}
		
		public function getMatchVert(col,row):Array {
			var match:Array = new Array(grid[col][row]);
			for(var i:int=1;row+i<8;i++) {
				if (grid[col][row].type == grid[col][row+i].type) {
					match.push(grid[col][row+i]);
				} else {
					return match;
				}
			}
			return match;
		}		
		
		public function affectAbove(piece:Piece) {
			for(var row:int=piece.row-1;row>=0;row--) {
				if (grid[piece.col][row] != null) {
					grid[piece.col][row].row++;
					grid[piece.col][row+1] = grid[piece.col][row];
					grid[piece.col][row] = null;
				}
			}
		}		
		
		public function addNewPieces() {
			for(var col:int=0;col<8;col++) {
				var missingPieces:int = 0;
				for(var row:int=7;row>=0;row--) {
					if (grid[col][row] == null) {
						var newPiece:Piece = addPiece(col,row);
						newPiece.visible = false;
						newPiece.y = offsetY-spacing-spacing*missingPieces++;						
						isDropping = true;
					}
				}
			}
		}
		
		
		public function lookForPossibles() {
			for(var col:int=0;col<8;col++) {
				for(var  row:int=0;row<8;row++) {
					
					// horizontal possible, two plus one
					if (matchPattern(col, row, [[1,0]], [[-2,0],[-1,-1],[-1,1],[2,-1],[2,1],[3,0]])) {
						return true;
					}
					
					// horizontal possible, middle
					if (matchPattern(col, row, [[2,0]], [[1,-1],[1,1]])) {
						return true;
					}
					
					// vertical possible, two plus one
					if (matchPattern(col, row, [[0,1]], [[0,-2],[-1,-1],[1,-1],[-1,2],[1,2],[0,3]])) {
						return true;
					}
					
					// vertical possible, middle
					if (matchPattern(col, row, [[0,2]], [[-1,1],[1,1]])) {
						return true;
					}
				}
			}			
			
			return false;
		}
		
		public function matchPattern(col,row:uint, mustHave, needOne:Array) {
			var thisType:int = grid[col][row].type;			
			
			for(var i:int=0;i<mustHave.length;i++) {
				if (!matchType(col+mustHave[i][0], row+mustHave[i][1], thisType)) {
					return false;
				}
			}			
			
			for(i=0;i<needOne.length;i++) {
				if (matchType(col+needOne[i][0], row+needOne[i][1], thisType)) {
					return true;
				}
			}
			return false;
		}
		
		public function matchType(col,row,type:int) {			
			if ((col < 0) || (col > 7) || (row < 0) || (row > 7)) return false;
			return (grid[col][row].type == type);
		}
		
		public function addScore(numPoints:int) {
			gameScore += numPoints;
			MovieClip(root).scoreText.text = String(gameScore);
		}
		
		public function endGame() {					
			
			setChildIndex(gameSprite,0);			
			gotoAndStop("gameover");
		}
		public function showResults()
		{
			MovieClip(root).endGameWindow.snowBall.scoreText.text = String(gameScore);
		}
		
		public function cleanUp() {
			grid = null;
			removeChild(gameSprite);
			gameSprite = null;
			removeEventListener(Event.ENTER_FRAME,movePieces);
		}

	}
	

}
