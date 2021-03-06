// import sound library
import ddf.minim.*;
Minim minim;
AudioPlayer yoshiNoise;
AudioPlayer dyingNoise;
AudioPlayer flyingNoise;
AudioPlayer shortHopNoise;
AudioPlayer maxPowerNoise;

//enable print messages
boolean DEBUG = false;

// key flags
boolean keyA = false;
boolean keyS = false;
boolean keyD = false;
boolean keyW = false;

int CELL_SIZE = 25;
int PLAYER_SIZE = 50;
// an Array to hold all of our tiles
PImage[] tiles = new PImage[3];

StageGenerator sg;
int[][] level;

float offset; //camera offset.

int highScore;
Player squid; // in our version it's a yoshi, though

boolean deathScreen; //death screen toggle
Lava lava;

Enemy booA;

PImage gameOverScreen;
PImage loadScreen;
void setup() {
  size(500, 500);
  loadTiles();
  squid = new Player(0, 300);
  sg = new StageGenerator(40);
  level = sg.generate();
  resetCameraAngle();
  highScore = 0;
  deathScreen = false;
//<<<<<<< HEAD  
  booA = new Enemy();

  minim = new Minim(this);
  yoshiNoise = minim.loadFile("sounds/Yoshi.mp3");
  dyingNoise = minim.loadFile("sounds/Dying.mp3");
  flyingNoise = minim.loadFile("sounds/Flying.mp3");
  shortHopNoise = minim.loadFile("sounds/Short Hop.mp3");
  maxPowerNoise = minim.loadFile("sounds/Max Power.mp3");
  
  gameOverScreen = loadImage("data/gameover.png");
//=======
  lava = new Lava();
//>>>>>>> 3de2a6a98446439d20f001cd9353f8cedd3d2b36
}

void draw() {
  if (deathScreen) {
    deathScreen();
  } else {
    gamePlaying();
  }
}

//interactions during game play
void gamePlaying() {
  drawLevel();
  adjustCameraView();
  booA.display();
  lava.move();
  lava.display();
  squid.move();
  squid.display();
  sg.curtainRaise();

  //if boo touches the lava, boo respawns somewhere else
  if(booA.isTouchingLava(lava)){
    booA.respawn();
  }
  
  if (squid.isBelowMap() || squid.isTouchingLava(lava) || squid.isTouchingBoo(booA)) {
    goToDeathScreen();
    dyingNoise.pause();
    dyingNoise.rewind();
    dyingNoise.play();
    squid.die();
    booA.respawn();
    resetStage();
  }
  
  
  if (squid.isTouchingCoin()) {
    flyingNoise.pause();
    yoshiNoise.pause();
    yoshiNoise.rewind();
    yoshiNoise.play();
    toNextStage();
  }
  squid.updateScore();
  setHighScore();
  displayScore();
}

//intereactions with death screen
void deathScreen() {
  background(0);
  if (squid.livesRemaining > 0) { //there are still lives
    text("You are dead!", 20, 20);
    text("Lives remaining: " + squid.livesRemaining, 20, 40);
    text("Press space to continue.", 20, 60);
    if (keyPressed && key==' ') {
      exitDeathScreen();
    }
  } else { //no more lives.
    background(gameOverScreen);
    //text("Game Over!", 20, 20);
    text("Press space to start a new game.", 20, 20);
    if (keyPressed && key==' ') {
      exitDeathScreen();
      newGame();
    }
  }  
}

void screenIn(PImage p) {
  image(p, 0, 0);
  
}

//death screen toggles
void goToDeathScreen() {deathScreen = true;}
void exitDeathScreen() {deathScreen = false;}

//resets camera angle and then produces new stage.
void resetStage() {
  level = sg.generate();
  lava.reset();
  resetCameraAngle();
}

//text representation of score
void displayScore() {
  fill(255);
  text("High Score: " + highScore, 20, 30);
  text("Score: " + squid.totalScore, 20, 50);
  text("Lives Remaining: " + squid.livesRemaining, 20, 70);
  text("Level: " + squid.currLevel, 20, 90);
}

//create a brand new game. used for after game over.
void newGame() {
  resetStage();
  squid = new Player(0, 300);
  booA = new Enemy();
  resetCameraAngle();
  displayScore();
}


//resets the camera to the bottom of the level
void resetCameraAngle() {
  offset = (-CELL_SIZE*level.length) + width; 
}


//Goes to the next level for the player by creating a new stage and incrementing level.
void toNextStage() {
  resetStage();
  squid.respawn();
  squid.currLevel++;
  booA.respawn();
}


//Sets high score if current player's score is better than high score.
void setHighScore() {
  highScore = max(highScore, squid.totalScore);
}

// Updates the camera view of the game depending on Yoshi's location.
void adjustCameraView() {
//  System.out.println("offset: " + offset);
  if (offset < 0 && squid.y <= width/3) { //move camera up if yoshi is in the top 1/3 of screen.
    offset+=2;
    squid.y+=2; //move our character up too, since the world is technically "shifting".
    booA.y+=2;
  }
  if (offset >= 0) offset = 0;
}

// load our tiles into memory
void loadTiles() {
  for (int i = 0; i < tiles.length; i++) {
    tiles[i] = loadImage(i + ".png");
  }
}

// iterate over the level array and draw the correct tile to the screen
void drawLevel() {
  for (int row = 0; row < level.length; row++) {
    for (int col = 0; col < level[row].length; col++) {
      int tileID = level[row][col];
      image(tiles[tileID], col*CELL_SIZE, offset+row*CELL_SIZE, CELL_SIZE, CELL_SIZE);
    }
  }
}

// gets the current tile under the x, y, and current camera offset.
int getTileCode(float x, float y, float offset) {
  // convert x & y coordinate to an array coordinate
  int col = int(x)/CELL_SIZE;
  int row = int(y + abs(offset))/CELL_SIZE;
  if (x >= width || x <= 0 || y >= height || y <= 0){
    return 1; // off the board - return air tile
  }
  // otherwise return the tile value
  return level[row][col];
}

// isSolid - returns true if the tile in question is solid, false if not.
boolean isSolid(int tileCode) {
  return tileCode == 0;
}

boolean isCoin(int tileCode) {
  return tileCode == 2;
}

// handle multiple key presses
void keyPressed() {
  if (key == 'a') { keyA = true; }  
  if (key == 's') { keyS = true; }  
  if (key == 'd') { keyD = true; }  
  if (key == 'w') { keyW = true; }    
}

void keyReleased() {
  if (key == 'a') { keyA = false; }  
  if (key == 's') { keyS = false; }  
  if (key == 'd') { keyD = false; }  
  if (key == 'w') { keyW = false; }    
}
