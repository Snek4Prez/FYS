//Code credit Winand Metz

//Alles game gerelateerd
class Game {
  Timer timer;
  ObjectHandler objectHandler;
  MapHandler mapHandler;
  TextureAssets textureLoader;
  Highscore highscore;
  GraphicsEngine graphicsEngine;
  UserInterface userInterface;
  Background background;
  SoundAssets soundLoader;

  final int width, height;

  //Inladen van alle assets voor de game en level creation dmv inladen van een png map, op basis van pixels plaatsing van objecten
  //TileSize is grote van de blokken in het plaatsingsgrid (tegelgrote)
  Game(int tileSize, int width, int height, TextureAssets textureAssets, SoundAssets soundAssets) {
    this.width = width;
    this.height = height;
    textureLoader = textureAssets;
    soundLoader = soundAssets;
    highscore = new Highscore(serverHandler);
    objectHandler = new ObjectHandler(this.textureLoader, this.soundLoader);
    objectHandler.addPlayer(this.highscore);
    objectHandler.addFix();
    background = new Background(textureLoader);
    mapHandler = new MapHandler(tileSize);
    graphicsEngine = new GraphicsEngine();
    userInterface = new UserInterface(this.textureLoader, this.highscore, this.objectHandler);
    timer = new Timer();
    isPlaying = true;
  }

  //Oproepen van objecten in de game zodat ze worden getekend
  void update() {
    mapHandler.update();
    background.update();
    objectHandler.update();
    highscore.update();
    graphicsEngine.update();
    userInterface.update();

    //stuurt je naar het main menu als je op escape drukt
    if (input.escapeDown() && timer.startTimer(200)) {
      isPlaying = false;
      inMainMenu = false;
    }
  }

  void draw() {
    background(41, 29, 43);

    if (!isPlaying) {
      graphicsEngine.update();
    }

    background.draw();
    graphicsEngine.drawFloorLighting();
    objectHandler.draw();
    graphicsEngine.draw();
    userInterface.draw();
  }

  //-----------------------------Graphics engine---------------------------------

  class GraphicsEngine {

    Emitter emitterPlayer;

    PGraphics floorLightMap;
    PGraphics floorTorchLight;
    PGraphics floorShadowMask;
    PGraphics floorInvShadowMask;
    PGraphics floorInvShadowMap;
    PGraphics floorShadowMap;

    PGraphics wallLightMask;
    PGraphics wallLightMap;

    PImage torchLight;
    PImage invTorchLight;

    PVector playerPos;

    GraphicsEngine() {
      emitterPlayer = new Emitter(objectHandler);
      playerPos = new PVector();
      torchLight = loadImage("data/lightmaps/torch.png");
      invTorchLight = loadImage("data/lightmaps/inv_torch.png");
      floorInvShadowMap = createGraphics(1920, 1080, P2D);
      floorShadowMap = createGraphics(1920, 1080, P2D);
      floorLightMap = createGraphics(1920, 1080, P2D);
      floorTorchLight = createGraphics(1920, 1080, P2D);
      floorShadowMask = createGraphics(1920, 1080, P2D);
      floorInvShadowMask = createGraphics(1920, 1080, P2D);
      wallLightMask = createGraphics(1920, 1080, P2D);
      wallLightMap = createGraphics(1920, 1080, P2D);
    }

    void update() {
      ArrayList<Object> entityObjects = objectHandler.entities;
      Object playerEntity = entityObjects.get(0);
      playerPos.set(playerEntity.x, playerEntity.y);
      emitterPlayer.update(playerPos.x, playerPos.y);
      emitterPlayer.cast(objectHandler.walls);
    }

    //Tekent de bewegende shaduwen op de vloer
    void drawFloorLighting() {
      //Bepaald hoe het licht op de vloer valt op basis van een variant van path tracing
      floorLightMap.beginDraw();
      floorLightMap.clear();
      floorLightMap.background(0);
      floorLightMap.shape(emitterPlayer.getShape(255));
      floorLightMap.endDraw();

      //Bepaald de grote van het fakkel licht van de player dmv een png
      floorTorchLight.beginDraw();
      floorTorchLight.clear();
      floorTorchLight.background(0);
      floorTorchLight.imageMode(CENTER);
      floorTorchLight.image(torchLight, playerPos.x, playerPos.y);
      floorTorchLight.endDraw();

      //Zorgt ervoor dat path tracing alleen voordoet binnen het fakkel licht
      floorLightMap.mask(floorTorchLight);

      //Maakt een mask van de floorLightMap die inverted is, oftwel de inverted shadow mask
      floorInvShadowMask.beginDraw();
      floorInvShadowMask.clear();
      floorInvShadowMask.background(0);
      floorInvShadowMask.image(floorLightMap, 0, 0);
      floorInvShadowMask.endDraw();

      //Basis layer voor de inverted shadow map
      floorInvShadowMap.beginDraw();
      floorInvShadowMap.clear();
      floorInvShadowMap.background(0);
      floorInvShadowMap.endDraw();

      //Zet de inverted shadow mask om in de inverted shadow map
      floorInvShadowMap.mask(floorInvShadowMask);

      //Tekend de shadow mask, dit bepaald waar de schaduwen komen en hoe sterk ze zijn
      floorShadowMask.beginDraw();
      floorShadowMask.clear();
      floorShadowMask.background(FLOOR_SHADOW_STRENGTH);
      floorShadowMask.image(floorInvShadowMap, 0, 0);
      floorShadowMask.endDraw();

      //Tekend de shadow map, dit is wat uiteindelijk te zien is op het scherm
      floorShadowMap.beginDraw();
      floorShadowMap.clear();
      floorShadowMap.background(0);
      floorShadowMap.endDraw();

      //Zet de shadow mask om in de shadow map die geprojecteerd wordt
      floorShadowMap.mask(floorShadowMask);

      //Aantal check functies
      //image(lightMap, 0, 0);
      //image(lightMapOutput, 0, 0);
      //image(shadowMask, 0, 0);
      //image(shadowMap, 0, 0);
      //image(lightMask, 0, 0);
      image(floorShadowMap, 0, 0);
    }

    void draw() {
      //Dit is de light mask voor de muren en entities, laad de grote van het fakkel licht en de sterkte van de schaduwen in en zet dit om in een mask
      wallLightMask.beginDraw();
      wallLightMask.clear();
      wallLightMask.background(ENVIROMENT_SHADOW_STRENGHT);
      wallLightMask.imageMode(CENTER);
      wallLightMask.image(invTorchLight, playerPos.x, playerPos.y);
      wallLightMask.endDraw();

      //De uiteindelijke light map die te zien is op het scherm
      wallLightMap.beginDraw();
      wallLightMap.clear();
      wallLightMap.background(0);
      wallLightMap.endDraw();

      //Zet de mask om in een light map
      wallLightMap.mask(wallLightMask);

      //Check functie
      //image(wallLightMap, 0, 0);
      image(wallLightMap, 0, 0);
    }
  }

  class Background {
    //Path path;

    Object[] backgrounds = new Object[170];

    float x, y;
    int cols = 17;
    int rows = 10;
    int amount = 170;

    Background(TextureAssets sprites) {
      int k = 0;
      for (int i = 0; i < cols; i++) {
        for (int j = 0; j < rows; j++) {
          backgrounds[k] = new Path(i * 128, j * 128 - OBJECT_Y_OFFSET, 128, 128, objectHandler, sprites, soundAssets);

          k++;
        }
      }
    }

    void update() {
      for (int i = 0; i < backgrounds.length; i++) {
        backgrounds[i].moveMap();
        backgrounds[i].update();
      }
    }

    void draw() {
      for (int i = 0; i < backgrounds.length; i++) {
        backgrounds[i].draw();
      }
    }
  }
}

//-----------------------------Highscore---------------------------------

//code credit Jordy
class Highscore {
  int score, timeScore, timer;
  Timer scoreTimer;
  boolean scoreAdded;
  ServerHandler serverHandler;

  Highscore(ServerHandler serverHandler) {
    this.serverHandler = serverHandler;
    score = 0; 
    timeScore = TIME_SCORE;
    timer = FRAMERATE * TIME_SCORE_TIMER;
    scoreTimer = new Timer();
    scoreAdded = false;
  }

  //iedere sec komt er score bij
  void update() {
    switch(gameState) {
    case 1:
      if (scoreTimer.startTimer(timer)) {
        score += timeScore;
      }
      break;
    case 2:
      //als gameState gameover is en de highscores nog niet geupdate zijn worden de scores geupdate
      if (scoreAdded == false) {
        updateHighscores();
      }
      break;
    }
  }

  //update de highscorelist
  void updateHighscores() {
    //zet de highscore in de tabel
    serverHandler.updateHighscores(score);
    scoreAdded = true;
  }

  //als je buiten deze class score wilt toevoegen
  void addScore(int amount) {
    score += amount;
  }
}
