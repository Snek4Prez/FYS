//Voor main menu etc
Game game;
InputHandler input;

final int KEY_LIMIT = 1024;
boolean[] keysPressed = new boolean[KEY_LIMIT];

void setup() {
  fullScreen(P2D);
  frameRate(60);
  game = new Game(128, width, height);
  input = new InputHandler();
  
}

//-----------------------------Draw & Key functies---------------------------------

void draw() {
  game.update();
  game.draw();
}

void keyPressed() {  
  if (keyCode >= KEY_LIMIT) return;
  keysPressed[keyCode] = true;
}

void keyReleased() {
  if (keyCode >= KEY_LIMIT) return;
  keysPressed[keyCode] = false;
}
