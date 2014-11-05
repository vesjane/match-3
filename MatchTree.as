﻿package  {
	
	import flash.display.MovieClip;
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.utils.Timer;
	
	public class MatchTree extends MovieClip {
		
		// constants
		static const numPieces:uint = 7;
		static const spacing:Number = 48;
		static const offsetX:Number = 120;
		static const offsetY:Number = 30;
		static const deltaSpacing:Number = 8;
		
		// game grid and mode
		private var grid:Array;
		private var gameSprite:Sprite;
		private var firstPiece:Piece;
		private var isDropping,isSwapping:Boolean;
		private var gameScore:int;
		
		// set up grid and start game
		public function startMatchThree() {
			// create grid array
			grid = new Array();
			for(var gridrows:int=0;gridrows<8;gridrows++) {
				grid.push(new Array());
			}
			setUpGrid();
			isDropping = false;
			isSwapping = false;
			gameScore = 0;
			addEventListener(Event.ENTER_FRAME,movePieces);
		}
	public function setUpGrid() {
			// loop until valid starting grid
			while (true) {
				// create sprite
				gameSprite = new Sprite();
				
				// add 64 random pieces
				for(var col:int=0;col<8;col++) {
					for(var row:int=0;row<8;row++) {
						addPiece(col,row);
					}
				}
				
				// try again if matches are present
				if (lookForMatches().length != 0) continue;
				
				// try again if no possible moves
				if (lookForPossibles() == false) continue;
				
				// no matches, but possibles exist: good board found
				break;
			} 
			
			// add sprite
			addChild(gameSprite);
		}
		
		// create a random piece, add to sprite and grid
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
		
		// player clicks on a piece
		public function clickPiece(event:MouseEvent) {
			var piece:Piece = Piece(event.currentTarget);
			
			// first one selected
			if (firstPiece == null) {
				piece.select.visible = true;
				firstPiece = piece;
				
			// clicked on first piece again
			} else if (firstPiece == piece) {
				piece.select.visible = false;
				firstPiece = null;
			
			// clicked on second piece
			} else {
				firstPiece.select.visible = false;
				
				// same row, one column over
				if ((firstPiece.row == piece.row) && (Math.abs(firstPiece.col-piece.col) == 1)) {
					makeSwap(firstPiece,piece);
					firstPiece = null;
					
				// same column, one row over
				} else if ((firstPiece.col == piece.col) && (Math.abs(firstPiece.row-piece.row) == 1)) {
					makeSwap(firstPiece,piece);
					firstPiece = null;
					
				// bad move, reassign first piece
				} else {
					firstPiece = piece;
					firstPiece.select.visible = true;
				}
			}
		}

		// start animated swap of two pieces
		public function makeSwap(piece1,piece2:Piece) {
			swapPieces(piece1,piece2);
			
			// check to see if move was fruitful
			if (lookForMatches().length == 0) {
				swapPieces(piece1,piece2);
			} else {
				isSwapping = true;
			}
		}
		
		// swap two pieces
		public function swapPieces(piece1,piece2:Piece) {
			// swap row and col values
			var tempCol:uint = piece1.col;
			var tempRow:uint = piece1.row;
			piece1.col = piece2.col;
			piece1.row = piece2.row;
			piece2.col = tempCol;
			piece2.row = tempRow;
			
			// swap grid positions
			grid[piece1.col][piece1.row] = piece1;
			grid[piece2.col][piece2.row] = piece2;
			
		}

		// if any pieces are out of place, move them a step closer to being in place
		// happens when pieces are swapped, or they are dropping
		public function movePieces(event:Event) {
			var madeMove:Boolean = false;
			for(var row:int=0;row<8;row++) {
				for(var col:int=0;col<8;col++) {
					if (grid[col][row] != null) {
						
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
					}
				}
			}
			
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
			}
			
			// add any new piece to top of board
			addNewPieces();
			
			// no matches found, maybe the game is over?
			if (matches.length == 0) {
				if (!lookForPossibles()) {
					endGame();
				}
			}
		}
		
		//return an array of all matches found
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
		
		// look for horizontal matches starting at this point
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

		// look for vertical matches starting at this point
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
		
		// tell all pieces above this one to move down
		public function affectAbove(piece:Piece) {
			for(var row:int=piece.row-1;row>=0;row--) {
				if (grid[piece.col][row] != null) {
					grid[piece.col][row].row++;
					grid[piece.col][row+1] = grid[piece.col][row];
					grid[piece.col][row] = null;
				}
			}
		}
		
		// if there are missing pieces in a column, add one to drop
		public function addNewPieces() {
			for(var col:int=0;col<8;col++) {
				var missingPieces:int = 0;
				for(var row:int=7;row>=0;row--) {
					if (grid[col][row] == null) {
						var newPiece:Piece = addPiece(col,row);
						newPiece.y = offsetY-spacing-spacing*missingPieces++;
						isDropping = true;
					}
				}
			}
		}
		
		// look to see if a possible move is on the board
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
			
			// no possible moves found
			return false;
		}
		
		public function matchPattern(col,row:uint, mustHave, needOne:Array) {
			var thisType:int = grid[col][row].type;
			
			// make sure this has all must-haves
			for(var i:int=0;i<mustHave.length;i++) {
				if (!matchType(col+mustHave[i][0], row+mustHave[i][1], thisType)) {
					return false;
				}
			}
			
			// make sure it has at least one need-ones
			for(i=0;i<needOne.length;i++) {
				if (matchType(col+needOne[i][0], row+needOne[i][1], thisType)) {
					return true;
				}
			}
			return false;
		}
		
		public function matchType(col,row,type:int) {
			// make sure col and row aren't beyond the limit
			if ((col < 0) || (col > 7) || (row < 0) || (row > 7)) return false;
			return (grid[col][row].type == type);
		}
		
		public function addScore(numPoints:int) {
			gameScore += numPoints;
			//MovieClip(root).scoreDisplay.text = String(gameScore);
		}
		
		public function endGame() {
			// move to back
			setChildIndex(gameSprite,0);
			// go to end game
			gotoAndStop("gameover");
		}
		
		public function cleanUp() {
			grid = null;
			removeChild(gameSprite);
			gameSprite = null;
			removeEventListener(Event.ENTER_FRAME,movePieces);
		}
	}
}
