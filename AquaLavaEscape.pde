// ========== SISTEMA DE ESCENAS ==========
enum GameScene { 
  INICIO, JUEGO, TIENDA, SELECCION, PERSONAJE, NIVEL, 
  BOSS_WARNING, BOSS_CHASE, BOSS_SHOOTER, TRANSICION 
}
GameScene currentScene = GameScene.INICIO;

// ========== MENÚ: IMÁGENES Y CONFIGURACIÓN ==========
final String FONDO_FILE  = "fondo2.png";
final String PLAY_FILE   = "play.png";
final String STORE_FILE  = "store.png";

float PLAY_UX  = 0.50, PLAY_UY  = 0.60; 
float STORE_UX = 0.50, STORE_UY = 0.74;
float PLAY_SCALE_EXTRA  = 0.20;
float STORE_SCALE_EXTRA = 0.20;

PImage bg, btnPlayImg, btnStoreImg;

// ========== SISTEMA DE JUGADORES ==========
int terrainChosen = -1;
final int NUM_PLAYERS = 4;
PImage[] playerImg = new PImage[NUM_PLAYERS];
int currentPlayer = 0;

PImage bgPersonaje;
PImage baseImg;
boolean useAccessory = true;

// ========== CONTROL DE SELECCIÓN ==========
float selCX, selCY;
float btnPlaySelX, btnPlaySelY, btnPlaySelW = 240, btnPlaySelH = 64;
float leftX, leftY, rightX, rightY;
float arrowW = 56, arrowH = 72;
float toggleX, toggleY, toggleW = 28, toggleH = 28;

// ========== SISTEMA DE NIVELES ==========
int selectedLevel = -1;
final int LEVELS_PER_TERRAIN = 4;
boolean[] lavaUnlocked = new boolean[LEVELS_PER_TERRAIN];
boolean[] marUnlocked  = new boolean[LEVELS_PER_TERRAIN];

// ========== BOTONES DEL MENÚ ==========
class ImgButton {
  PImage img;
  float ux, uy;
  float w, h;
  float cx, cy;
  float extraScale;
  ImgButton(PImage img, float ux, float uy, float extraScale){
    this.img = img; this.ux = ux; this.uy = uy; this.extraScale = extraScale;
  }
  void layout(float offX, float offY, float drawW, float drawH, float scaleFit){
    cx = offX + ux * drawW;
    cy = offY + uy * drawH;
    if (img != null){
      w = img.width  * scaleFit * extraScale;
      h = img.height * scaleFit * extraScale;
    } else {
      w = 180 * scaleFit; h = 60 * scaleFit;
    }
  }
  boolean over(){ return mouseX > cx - w/2 && mouseX < cx + w/2 && mouseY > cy - h/2 && mouseY < cy + h/2; }
  void draw(){
    pushStyle();
    imageMode(CENTER);
    if (img != null){
      tint(255, over()? 235 : 255);
      image(img, cx, cy, w, h);
      noTint();
    } else {
      rectMode(CENTER); noStroke(); fill(240); rect(cx, cy, w, h, 12);
      fill(40); textAlign(CENTER,CENTER); text("BTN", cx, cy);
    }
    popStyle();
  }
}
ImgButton btnPlay, btnStore;

float drawW, drawH, offX, offY, scaleFit;

PImage bgSelect, imgLava, imgMar;
PImage bgStore;

// ========== SISTEMA DE GEMAS (TIENDA) ==========
int gems = 0;
PImage gemIcon;

PImage imgSombrero, imgSombrero2, imgSombrero3, imgNavidad, imgCorona, imgGorro;

class ShopItem {
  String name; int price; PImage img;
  float x, y, w, h;
  boolean owned = false;
  ShopItem(String n, int p, PImage im){ name=n; price=p; img=im; }
  boolean over(){ return mouseX > x && mouseX < x+w && mouseY > y && mouseY < y+h; }
}
ShopItem[] items;
int equippedIndex = -1;
String flashMsg = "";
int flashTimer = 0;
boolean storeInitialized = false;
void addGems(int n){ gems = max(0, gems + n); }

// ========== JUEGO: VARIABLES PRINCIPALES ==========
float offset = 0;
float speed = 8;
float trackWidth = 400;
ArrayList<PathObject> objects = new ArrayList<PathObject>();
Player player;

// ========== SISTEMA DE PUNTOS Y COLISIONES ==========
int score = 0;
int diamondsCollected = 0;
int diamondsForHealth = 0;
float collisionDistance = 35;

// ========== SISTEMA DE VIDAS ==========
int maxHealth = 100;
int absoluteMaxHealth = 200;
int currentHealth = 100;
boolean gameOver = false;

// ========== SISTEMA DE TIEMPO ==========
int gameTime = 30;
int startTime;
boolean gameRunning = true;
int timeLeft = 30;

// ========== SISTEMA DE SPRITES DEL JUEGO ==========
PImage[] droidSprites;
PImage[] kamchakSprites;
boolean spritesLoaded = false;
int totalDroidFrames = 5;
int totalKamchakFrames = 5;
PImage bgJuego, bgBoss;

// ========== SISTEMA DE SPRITES DE JUGADORES ==========
PImage[][] playerSprites = new PImage[NUM_PLAYERS][4];
boolean playerSpritesLoaded = false;

// ========== TRANSICIÓN ==========
boolean transitioning = false;
float fadeAlpha = 0;
boolean fadeOut = false;
boolean fadeIn = false;
float fadeSpeed = 4.0;
float playerForwardZ = 0;

// ========== BOSS FIGHT VARIABLES - CHASE MODE ==========
BossEnemy bossChase = null;
boolean bossChaseGameOver = false;
boolean bossChaseWon = false;
boolean hasShot = false;
int bossWarningStart = 0;
float bossCollisionDistance = 60;

// ========== BOSS FIGHT VARIABLES - SHOOTER MODE ==========
PImage cannon, cacodemon;
PVector cannonBase = new PVector(0, 120, 200);
float barrelLen = 180;
float barrelRadius = 22;
float yaw = 0;
float pitch = 0;
int lastTime = 0;
float deltaTime = 0;
Target target = null;
Projectile projectile = null;
float projectileSpeed = 15;
boolean bossShooterGameOver = false;
boolean bossShooterWon = false;
PVector camPos = new PVector();
float bossTrackOffset = 0;
float bossZPlane = -400;

// ========== VARIABLES FINALES ==========
int finalScore = 0;
int finalDiamonds = 0;

// ========== SETUP ==========
void settings(){ size(1920, 1080, P3D); }

void setup(){
  surface.setTitle("AquaLava Escape – Inicio");
  surface.setLocation(0, 0);
  textFont(createFont("Arial Bold", 20, true));
  
  bg         = safeLoad(FONDO_FILE);
  btnPlayImg = safeLoad(PLAY_FILE);
  btnStoreImg= safeLoad(STORE_FILE);
  btnPlay  = new ImgButton(btnPlayImg,  PLAY_UX,  PLAY_UY,  PLAY_SCALE_EXTRA);
  btnStore = new ImgButton(btnStoreImg, STORE_UX, STORE_UY, STORE_SCALE_EXTRA);
  computeBackgroundFit();
  bgSelect = safeLoad("fondo3.png");
  imgLava  = safeLoad("lava.png");
  imgMar   = safeLoad("mar.png");
  bgPersonaje = safeLoad("fondo4.png");
  baseImg = safeLoad("base.png");
  playerImg[0] = safeLoad("sprite1.png");
  playerImg[1] = safeLoad("sprite2.png");
  playerImg[2] = safeLoad("sprite3.png");
  playerImg[3] = safeLoad("sprite4.png");
  bgStore = safeLoad("fondo4.png");
  cacodemon = safeLoad("cacodemon.png");
  cannon = safeLoad("cannon_i.png");
  
  lavaUnlocked[0] = true;
  marUnlocked[0]  = true;
  
  initGame();
  lastTime = millis();
}

void initGame() {
  spritesLoaded = false;
  
  // Cargar sprites de enemigos
  droidSprites = new PImage[totalDroidFrames];
  boolean droidOk = true;
  for (int i = 0; i < totalDroidFrames; i++) {
    try {
      droidSprites[i] = loadImage("droid_" + i + ".png");
      if (droidSprites[i] == null) droidOk = false;
    } catch (Exception e) {
      droidOk = false;
    }
  }
  
  kamchakSprites = new PImage[totalKamchakFrames];
  boolean kamchakOk = true;
  for (int i = 0; i < totalKamchakFrames; i++) {
    try {
      kamchakSprites[i] = loadImage("kamchak_" + i + ".png");
      if (kamchakSprites[i] == null) kamchakOk = false;
    } catch (Exception e) {
      kamchakOk = false;
    }
  }
  
  if (droidOk && kamchakOk) {
    spritesLoaded = true;
    println("✓ SPRITES ENEMIGOS CARGADOS");
  } else {
    println("✗ USANDO FORMAS 3D PARA ENEMIGOS");
  }
  
  // Cargar sprites de jugadores
  playerSpritesLoaded = true;
  for (int p = 0; p < NUM_PLAYERS; p++) {
    for (int f = 0; f < 4; f++) {
      try {
        String filename = "personaje" + (p+1) + "_" + (f+1) + ".png";
        playerSprites[p][f] = loadImage(filename);
        if (playerSprites[p][f] == null) playerSpritesLoaded = false;
      } catch (Exception e) {
        playerSpritesLoaded = false;
      }
    }
  }
  
  if (playerSpritesLoaded) {
    println("✓ SPRITES DE JUGADORES CARGADOS");
  } else {
    println("✗ USANDO CUBO PARA JUGADOR");
  }
  
  player = new Player();
}

PImage safeLoad(String file){
  try { return loadImage(file); }
  catch(Exception e){ println("No se pudo cargar: " + file); return null; }
}

void computeBackgroundFit(){
  if (bg == null){
    drawW = width; drawH = height; offX = 0; offY = 0; scaleFit = 1;
    return;
  }
  float sx = (float)width  / bg.width;
  float sy = (float)height / bg.height;
  scaleFit = min(sx, sy);
  drawW = bg.width  * scaleFit;
  drawH = bg.height * scaleFit;
  offX = (width  - drawW) * 0.5;
  offY = (height - drawH) * 0.5;
}

void draw(){
  if      (currentScene == GameScene.INICIO)        drawInicio();
  else if (currentScene == GameScene.SELECCION)     drawSeleccion();
  else if (currentScene == GameScene.PERSONAJE)     drawPersonaje();
  else if (currentScene == GameScene.NIVEL)         drawSeleccionNivel();
  else if (currentScene == GameScene.JUEGO)         drawJuego();
  else if (currentScene == GameScene.BOSS_WARNING)  drawBossWarning();
  else if (currentScene == GameScene.BOSS_CHASE)    drawBossChase();
  else if (currentScene == GameScene.BOSS_SHOOTER)  drawBossShooter();
  else if (currentScene == GameScene.TRANSICION)    drawTransicion();
  else                                              drawTienda();
}

void drawInicio(){
  background(120, 170, 255);
  computeBackgroundFit();
  if (bg != null){
    imageMode(CORNER);
    image(bg, offX, offY, drawW, drawH);
  }
  btnPlay.layout(offX, offY, drawW, drawH, scaleFit);
  btnStore.layout(offX, offY, drawW, drawH, scaleFit);
  btnPlay.draw();
  btnStore.draw();
  fill(255); textAlign(CENTER); textSize(14);
  text("Enter/Espacio: Play   ·   S: Store   ·   Gemas totales: " + gems, width/2f, height - 24);
}

void drawSeleccion(){
  background(124,181,255);
  drawImageCover(bgSelect, 0, 0, width, height);
  drawBackButton();
  float cardW = min(width*0.32f, 520);
  float cardH = cardW * 0.62f;
  float leftX  = width*0.30f - cardW/2f;
  float rightX = width*0.69f - cardW/2f;
  float cardsY = height*0.52f - cardH/2f + 135;
  boolean lavaOver = mouseX > leftX && mouseX < leftX+cardW && mouseY > cardsY && mouseY < cardsY+cardH;
  boolean marOver  = mouseX > rightX && mouseX < rightX+cardW && mouseY > cardsY && mouseY < cardsY+cardH;
  drawSelectCard(leftX,  cardsY, cardW, cardH, imgLava, lavaOver);
  drawSelectCard(rightX, cardsY, cardW, cardH, imgMar,  marOver);
  if (lavaOver || marOver) cursor(HAND); else cursor(ARROW);
}

void drawSelectCard(float x, float y, float w, float h, PImage img, boolean hover){
  if (img != null){
    imageMode(CENTER);
    float ir = (float)img.width / img.height;
    float dw = w * 0.92f, dh = h * 0.92f;
    float cw = dh*ir, ch = dw/ir;
    if (ir > w/h) image(img, x + w/2f, y + h/2f, dw, ch);
    else         image(img, x + w/2f, y + h/2f, cw, dh);
  }
  if (hover){
    noFill();
    stroke(255, 220);
    strokeWeight(3);
    rect(x, y, w, h, 12);
  }
}

void drawPersonaje(){
  background(0);
  if (bgPersonaje != null) {
    drawImageCover(bgPersonaje, 0, 0, width, height);
  }
  drawBackButton();
  selCX = width*0.50f;
  selCY = height*0.56f;
  float pivotX = selCX;
  float pivotY = selCY + 74;
  float baseS = 0.30;
  imageMode(CENTER);
  if (baseImg != null){
    image(baseImg, pivotX, pivotY, baseImg.width*baseS, baseImg.height*baseS);
  }
  if (playerImg != null && playerImg[currentPlayer] != null){
    float maxW = width*0.15f;
    float playerYOffset = -110;
    float pw = playerImg[currentPlayer].width;
    float ph = playerImg[currentPlayer].height;
    float scaleP = min(maxW/pw, (maxW*1.2f)/ph);
    imageMode(CENTER);
    image(playerImg[currentPlayer], pivotX, pivotY + playerYOffset, pw*scaleP, ph*scaleP);
    if (useAccessory && equippedIndex >= 0 && items != null &&
        items[equippedIndex] != null && items[equippedIndex].img != null){
      PImage acc = items[equippedIndex].img;
      float accScale = 0.80;
      float offX = 0;
      float offY = -80;
      image(acc, pivotX + offX, pivotY + playerYOffset + offY,
            acc.width*accScale, acc.height*accScale);
    }
  }
  leftX  = selCX - 260; leftY  = selCY;
  rightX = selCX + 260; rightY = selCY;
  drawArrow(leftX, leftY, true);
  drawArrow(rightX, rightY, false);
  toggleX = width*0.5f - 160;
  toggleY = height - 170;
  drawAccessoryToggle();
  btnPlaySelW = 240; btnPlaySelH = 64;
  btnPlaySelX = width*0.5f - btnPlaySelW/2f;
  btnPlaySelY = height - 110;
  boolean over = (mouseX>btnPlaySelX && mouseX<btnPlaySelX+btnPlaySelW &&
                  mouseY>btnPlaySelY && mouseY<btnPlaySelY+btnPlaySelH);
  pushStyle();
  rectMode(CORNER);
  stroke(40); strokeWeight(4);
  fill(over? 230 : 245);
  rect(btnPlaySelX, btnPlaySelY, btnPlaySelW, btnPlaySelH, 12);
  fill(30); textAlign(CENTER, CENTER); textSize(22);
  text("Jugar", btnPlaySelX+btnPlaySelW/2, btnPlaySelY+btnPlaySelH/2);
  popStyle();
  fill(255); textAlign(CENTER, TOP); textSize(16);
  text("Flechas: cambiar jugador   ·   Click en el check: usar accesorio comprado", width/2f, 28);
}

void drawArrow(float cx, float cy, boolean left){
  boolean over = (mouseX>cx-arrowW/2 && mouseX<cx+arrowW/2 &&
                  mouseY>cy-arrowH/2 && mouseY<cy+arrowH/2);
  pushStyle();
  noStroke();
  fill(over? color(255,255,255,180) : color(255,255,255,120));
  rectMode(CENTER);
  rect(cx, cy, arrowW, arrowH, 10);
  fill(40);
  if (left){
    triangle(cx+10, cy-18, cx-12, cy, cx+10, cy+18);
  } else {
    triangle(cx-10, cy-18, cx+12, cy, cx-10, cy+18);
  }
  popStyle();
}

void drawAccessoryToggle(){
  boolean over = (mouseX>toggleX && mouseX<toggleX+toggleW &&
                  mouseY>toggleY && mouseY<toggleY+toggleH);
  pushStyle();
  rectMode(CORNER);
  stroke(40); strokeWeight(3);
  fill( useAccessory ? color(120, 255, 160) : color(240) );
  rect(toggleX, toggleY, toggleW, toggleH, 6);
  if (useAccessory){
    stroke(30); strokeWeight(4);
    line(toggleX+6, toggleY+14, toggleX+12, toggleY+22);
    line(toggleX+12, toggleY+22, toggleX+22, toggleY+8);
  }
  noStroke(); fill(255); textAlign(LEFT, CENTER); textSize(16);
  text("Usar accesorio equipado", toggleX + toggleW + 10, toggleY + toggleH/2);
  popStyle();
}

boolean isLevelUnlocked(int terrain, int levelIndex1Based){
  int idx = levelIndex1Based - 1;
  if (idx < 0 || idx >= LEVELS_PER_TERRAIN) return false;
  return (terrain == 0) ? lavaUnlocked[idx] : marUnlocked[idx];
}

void unlockNextLevel(int terrain, int completedLevel1Based){
  int nextIdx = completedLevel1Based;
  if (nextIdx >= 0 && nextIdx < LEVELS_PER_TERRAIN){
    if (terrain == 0) lavaUnlocked[nextIdx] = true;
    else              marUnlocked[nextIdx]  = true;
  }
}

void drawSeleccionNivel() {
  background(0);
  if (bgPersonaje != null) drawImageCover(bgPersonaje, 0, 0, width, height);
  drawBackButton();
  String terrenoTxt = (terrainChosen == 0) ? "LAVA" : "MAR";
  fill(255); textAlign(CENTER, TOP); textSize(28);
  text("SELECCIONA NIVEL – " + terrenoTxt, width/2f, 40);
  int cols = 2, rows = 2;
  float gridW = min(width*0.75f, 760);
  float gridH = min(height*0.55f, 420);
  float startX = width*0.5f - gridW/2f;
  float startY = height*0.52f - gridH/2f + 20;
  float pad = 28;
  float cellW = (gridW - pad*(cols-1)) / cols;
  float cellH = (gridH - pad*(rows-1)) / rows;
  int n = 1;
  for (int r=0; r<rows; r++){
    for (int c=0; c<cols; c++){
      float x = startX + c*(cellW + pad);
      float y = startY + r*(cellH + pad);
      boolean unlocked = isLevelUnlocked(terrainChosen, n);
      boolean over = mouseX > x && mouseX < x+cellW && mouseY > y && mouseY < y+cellH;
      pushStyle();
      rectMode(CORNER);
      if (unlocked){
        stroke(40); strokeWeight(over? 5 : 3);
        fill(over? 245 : 235, over? 245 : 235, over? 245 : 235, 230);
      } else {
        stroke(80); strokeWeight(3);
        fill(200, 200, 200, 150);
      }
      rect(x, y, cellW, cellH, 18);
      fill(unlocked ? 30 : 90);
      textAlign(CENTER, CENTER);
      textSize(36);
      text("Nivel " + n, x + cellW/2f, y + cellH/2f);
      if (!unlocked){
        fill(0,140); noStroke();
        rect(x, y, cellW, cellH, 18);
        fill(255); textSize(20);
        text("🔒", x + cellW/2f, y + cellH/2f - 30);
        textSize(14);
        text("Completa el anterior", x + cellW/2f, y + cellH/2f + 16);
      }
      popStyle();
      n++;
    }
  }
  fill(255); textAlign(CENTER); textSize(14);
  text("Solo puedes entrar a niveles desbloqueados", width/2f, height - 26);
}

void toast(String msg){ flashMsg = msg; flashTimer = 60; }

int indexOf(ShopItem it){
  for (int i=0;i<items.length;i++) if (items[i]==it) return i;
  return -1;
}

void initStoreOnce(){
  if (storeInitialized) return;
  storeInitialized = true;
  gemIcon      = safeLoad("gemas.png");
  imgSombrero  = safeLoad("sombrero.png");
  imgSombrero2 = safeLoad("sombrero2.png");
  imgSombrero3 = safeLoad("sombrero3.png");
  imgNavidad   = safeLoad("navidad.png");
  imgCorona    = safeLoad("corona.png");
  imgGorro     = safeLoad("gorro.png");
  items = new ShopItem[]{
    new ShopItem("Sombrero",   2500, imgSombrero),
    new ShopItem("Sombrero2",  3000, imgSombrero2),
    new ShopItem("Corona",     3500, imgCorona),
    new ShopItem("Navidad",    4000, imgNavidad),
    new ShopItem("Sombrero3",  4500, imgSombrero3),
    new ShopItem("Gorro",      5000, imgGorro)
  };
}

void drawTienda(){
  initStoreOnce();
  background(0);
  if (bgStore != null) {
    drawImageCover(bgStore, 0, 0, width, height);
  }
  drawBalanceCapsule();
  drawBackButton();
  int cols = 3, rows = 2;
  float padX = 140, padY = 80;
  float areaX = 120, areaY = 120;
  float areaW = width  - areaX*2;
  float areaH = height - areaY*2 - 80;
  float cellW = (areaW - padX*(cols-1)) / cols;
  float cellH = (areaH - padY*(rows-1)) / rows;
  float scaleImg = min(cellW, cellH) * 0.60;
  int idx = 0;
  for (int r=0; r<rows; r++){
    for (int c=0; c<cols; c++){
      ShopItem it = items[idx++];
      float cx = areaX + c*(cellW + padX) + cellW/2;
      float cy = areaY + r*(cellH + padY) + cellH/2;
      it.x = cx - cellW/2; it.y = cy - cellH/2; it.w = cellW; it.h = cellH;
      imageMode(CENTER);
      if (it.img != null){
        float iw = it.img.width, ih = it.img.height;
        float s = scaleImg / max(iw, ih);
        image(it.img, cx, cy-10, iw*s, ih*s);
      } else {
        noStroke(); fill(240); rectMode(CENTER);
        rect(cx, cy-10, scaleImg, scaleImg*0.75, 16);
        fill(60); textAlign(CENTER, CENTER); textSize(14); text(it.name, cx, cy-10);
      }
      drawPrice(cx - cellW*0.22, cy + cellH*0.20, it.price);
      if (it.owned || equippedIndex == indexOf(it)){
        noFill();
        stroke(equippedIndex == indexOf(it) ? color(16,185,129) : color(59,130,246));
        strokeWeight(4);
        rect(it.x+6, it.y+6, it.w-12, it.h-12, 18);
      }
    }
  }
  if (flashTimer > 0){
    flashTimer--;
    pushStyle();
    fill(0,160); noStroke(); rectMode(CENTER);
    rect(width/2, 96, 280, 48, 12);
    fill(255); textAlign(CENTER, CENTER); textSize(18);
    text(flashMsg, width/2, 96);
    popStyle();
  }
}

void drawBalanceCapsule(){
  String t = nf(gems, 1, 0);
  float wCaps = textWidth(t) + 90;
  float x = width - wCaps - 28;
  float y = 28;
  pushStyle();
  rectMode(CORNER);
  stroke(55, 65, 81); strokeWeight(3);
  fill(230, 230, 235);
  rect(x, y, wCaps, 44, 12);
  fill(40); textAlign(LEFT, CENTER); textSize(22);
  text(t, x+16, y+22);
  if (gemIcon!=null) image(gemIcon, x + wCaps - 35, y + 24, 68, 40);
  popStyle();
}

boolean overBack(){ return dist(mouseX, mouseY, 70, 70) <= 28; }
void drawBackButton(){
  pushStyle();
  noStroke(); fill(255,207,0); ellipse(70,70,56,56);
  fill(60);
  beginShape(); vertex(72,54); vertex(58,70); vertex(72,86);
  vertex(72,76); vertex(86,76); vertex(86,64); vertex(72,64); endShape(CLOSE);
  if (overBack()){ noFill(); stroke(0,120); strokeWeight(3); ellipse(70,70,58,58); }
  popStyle();
}

float PRICE_TEXT_SIZE = 26;
float GEM_GAP = 18;

void drawPrice(float x, float y, int price){
  pushStyle();
  String p = str(price);
  textAlign(LEFT, CENTER);
  fill(255); stroke(0, 180); strokeWeight(4);
  textSize(PRICE_TEXT_SIZE);
  text(p, x, y);
  if (gemIcon != null) {
    image(gemIcon, x + textWidth(p) + 20, y + 5, 64, 40);
  }
  popStyle();
}

void drawImageCover(PImage img, float x, float y, float w, float h){
  if (img==null) return;
  float ir = (float)img.width/img.height, br = w/h;
  float dw, dh;
  if (ir > br){ dh = h; dw = h*ir; } else { dw = w; dh = w/ir; }
  imageMode(CENTER); image(img, x+w/2, y+h/2, dw, dh);
}

// ========== INICIO DEL JUEGO ==========
void startGame() {
  if (terrainChosen == 0) {
    bgJuego = safeLoad("5.png");
    println("🔥 MODO LAVA");
  } else {
    bgJuego = safeLoad("8.png");
    println("🌊 MODO MAR");
  }
  
  if (bgJuego != null) bgJuego.resize(1920, 1061);
  bgBoss = bgJuego; // Usar mismo fondo para boss
  
  gameOver = false;
  gameRunning = true;
  currentHealth = maxHealth;
  score = 0;
  diamondsCollected = 0;
  diamondsForHealth = 0;
  offset = 0;
  speed = 8;
  startTime = millis();
  timeLeft = gameTime;
  
  objects.clear();
  for (int i = 0; i < 60; i++) {
    int randomLane = int(random(0, 3));
    float xPos = (randomLane == 0) ? -trackWidth/4 : (randomLane == 1) ? 0 : trackWidth/4;
    objects.add(new PathObject(xPos, -i * 130, int(random(0, 3))));
  }
  
  player.lane = 1;
  player.updateTargetX();
  player.x = player.targetX;
  
  println("=== JUEGO INICIADO ===");
}

// ========== JUEGO PRINCIPAL ==========
void drawJuego(){
  background(19, 175, 255);
  hint(DISABLE_DEPTH_TEST);
  camera();
  if (bgJuego != null) {
    drawImageCover(bgJuego, 0, 0, width, height);
  }
  hint(ENABLE_DEPTH_TEST);
  lights();
  
  camera(width/2, height/2 - 240, 380, 
       width/2, height/2 - 75, -300, 
       0, 1, 0);
  
  if (gameRunning && !gameOver) {
    int elapsedTime = (millis() - startTime) / 1000;
    timeLeft = gameTime - elapsedTime;
    
    if (timeLeft <= 0) {
      gameRunning = false;
      timeLeft = 0;
      endGameSession();
      startBossWarning();
      return;
    }
  }
  
  if (gameRunning && !gameOver) {
    offset += speed;
  }
  
  drawTrack();
  
  if (gameRunning && !gameOver) {
    updateObjects();
  } else {
    pushMatrix();
    translate(width/2, height/2, 0);
    for (int i = 0; i < objects.size(); i++) {
      objects.get(i).display();
    }
    popMatrix();
  }
  
  player.update();
  player.display();
  
  if (gameRunning && !gameOver) {
    checkCollisions();
  }
  
  camera();
  fill(255);
  textSize(20);
  text("Velocidad: " + nf(speed, 1, 1) + " | ↑/↓ velocidad | ←/→ o A/D mover", 10, 20);
  
  drawScoreHUD();
  drawHealthBar();
  drawTimeCounter();
  
  if (gameOver) {
    drawGameOver();
  }
}

void endGameSession() {
  finalScore = score;
  finalDiamonds = diamondsCollected;
  gems += diamondsCollected;
  println("💎 Diamantes guardados: " + diamondsCollected);
  println("💰 Total de gemas: " + gems);
}

// ========== ADVERTENCIA DE JEFE ==========
void startBossWarning() {
  println("⚠️ ¡ADVERTENCIA DE JEFE!");
  bossWarningStart = millis();
  currentScene = GameScene.BOSS_WARNING;
}

void drawBossWarning() {
  background(19, 175, 255);
  hint(DISABLE_DEPTH_TEST);
  camera();
  if (bgJuego != null) {
    drawImageCover(bgJuego, 0, 0, width, height);
  }
  hint(ENABLE_DEPTH_TEST);
  lights();
  
  camera(width/2, height/2 - 240, 380, 
       width/2, height/2 - 75, -300, 
       0, 1, 0);
  
  drawTrack();
  player.display();
  
  camera();
  
  int elapsed = (millis() - bossWarningStart) / 1000;
  int countdown = 3 - elapsed;
  
  if (countdown <= 0) {
    // Alternar entre los dos modos de boss
    if (selectedLevel % 2 == 0) {
      startBossChase();
    } else {
      startBossShooter();
    }
    return;
  }
  
  if (frameCount % 20 < 10) {
    fill(255, 0, 0, 200);
  } else {
    fill(255, 50, 50, 150);
  }
  noStroke();
  rect(0, 0, width, height);
  
  fill(255, 255, 0);
  textAlign(CENTER, CENTER);
  textSize(120);
  text("⚠️ ¡JEFE FINAL! ⚠️", width/2, height/2 - 100);
  
  fill(255);
  textSize(80);
  text(countdown, width/2, height/2 + 50);
  
  textSize(40);
  fill(255, 200, 0);
  if (selectedLevel % 2 == 0) {
    text("¡Prepárate para disparar!", width/2, height/2 + 150);
  } else {
    text("¡Apunta y dispara!", width/2, height/2 + 150);
  }
}

// ========== BOSS CHASE MODE ==========
void startBossChase() {
  println("🎯 ¡INICIANDO BOSS CHASE!");
  bossChaseGameOver = false;
  bossChaseWon = false;
  hasShot = false;
  bossChase = new BossEnemy();
  currentScene = GameScene.BOSS_CHASE;
}

void drawBossChase(){
  background(19, 175, 255);
  hint(DISABLE_DEPTH_TEST);
  camera();
  if (bgBoss != null) {
    drawImageCover(bgBoss, 0, 0, width, height);
  }
  hint(ENABLE_DEPTH_TEST);
  lights();
  
  camera(width/2, height/2 - 240, 380, 
       width/2, height/2 - 75, -300, 
       0, 1, 0);
  
  if (!bossChaseGameOver) {
    offset += speed * 0.5;
  }
  
  drawTrack();
  
  if (bossChase != null && !bossChase.hit) {
    bossChase.update();
    bossChase.display();
    
    float dx = bossChase.x - player.x;
    float dz = bossChase.z - player.z;
    float distance = sqrt(dx * dx + dz * dz);
    
    if (distance < bossCollisionDistance) {
      bossChaseGameOver = true;
      bossChaseWon = false;
      println("💀 ¡EL JEFE TE ALCANZÓ!");
    }
  }
  
  player.update();
  player.display();
  
  camera();
  
  drawBossChaseHUD();
  
  if (bossChaseGameOver) {
    drawBossChaseFinalScreen();
  }
}

void drawBossChaseHUD() {
  fill(0, 0, 0, 180);
  noStroke();
  rect(width - 310, 10, 300, 80, 10);
  
  fill(255, 220, 0);
  textSize(24);
  textAlign(RIGHT);
  
  if (!hasShot) {
    text("🎯 MUNICIÓN: 1", width - 20, 35);
  } else {
    text("🎯 MUNICIÓN: 0", width - 20, 35);
  }
  
  fill(255, 100, 100);
  textSize(18);
  text("¡DISPARA AL JEFE!", width - 20, 65);
  
  textAlign(LEFT);
  
  if (bossChase != null && !bossChase.hit) {
    fill(255, 0, 0, 150);
    textAlign(CENTER);
    textSize(28);
    text("⬇️ ¡DISPARA AQUÍ! ⬇️", width/2, 100);
  }
}

void drawBossChaseFinalScreen() {
  hint(DISABLE_DEPTH_TEST);
  
  fill(0, 0, 0, 220);
  noStroke();
  rect(0, 0, width, height);
  
  textAlign(CENTER, CENTER);
  
  if (bossChaseWon) {
    fill(40, 100, 40);
    stroke(0, 255, 0);
    strokeWeight(5);
    rectMode(CENTER);
    rect(width/2, height/2, 700, 500, 20);
    rectMode(CORNER);
    
    fill(0, 255, 0);
    textSize(90);
    text("¡VICTORIA!", width/2, height/2 - 150);
    
    stroke(0, 255, 0);
    strokeWeight(3);
    line(width/2 - 300, height/2 - 80, width/2 + 300, height/2 - 80);
  } else {
    fill(40, 20, 20);
    stroke(255, 50, 50);
    strokeWeight(5);
    rectMode(CENTER);
    rect(width/2, height/2, 700, 500, 20);
    rectMode(CORNER);
    
    fill(255, 50, 50);
    textSize(90);
    text("¡DERROTA!", width/2, height/2 - 150);
    
    stroke(255, 50, 50);
    strokeWeight(3);
    line(width/2 - 300, height/2 - 80, width/2 + 300, height/2 - 80);
  }
  
  fill(255, 220, 0);
  textSize(55);
  text("PUNTOS: " + finalScore, width/2, height/2 - 10);
  
  fill(0, 255, 150);
  textSize(45);
  text("💎 Diamantes: " + finalDiamonds, width/2, height/2 + 60);
  
  fill(100, 200, 255);
  textSize(35);
  text("💰 Gemas totales: " + gems, width/2, height/2 + 110);
  
  stroke(255, 255, 255, 100);
  strokeWeight(2);
  line(width/2 - 250, height/2 + 150, width/2 + 250, height/2 + 150);
  
  fill(255);
  textSize(30);
  if (bossChaseWon) {
    text("ESC: Menú   |   C: Completar nivel", width/2, height/2 + 190);
  } else {
    text("ESC: Menú   |   R: Reintentar", width/2, height/2 + 190);
  }
  
  textAlign(LEFT);
  hint(ENABLE_DEPTH_TEST);
}

void shootAtBossChase() {
  if (hasShot || bossChaseGameOver || bossChase == null) return;
  
  hasShot = true;
  println("💥 ¡DISPARO REALIZADO!");
  
  if (player.lane == bossChase.lane) {
    bossChase.hit = true;
    bossChaseGameOver = true;
    bossChaseWon = true;
    println("🎯 ¡IMPACTO! ¡JEFE DERROTADO!");
  } else {
    bossChaseGameOver = true;
    bossChaseWon = false;
    println("❌ ¡FALLASTE! El jefe estaba en otro carril");
  }
}

// ========== BOSS SHOOTER MODE ==========
void startBossShooter() {
  println("🎯 ¡INICIANDO BOSS SHOOTER!");
  bossShooterGameOver = false;
  bossShooterWon = false;
  hasShot = false;
  target = new Target();
  projectile = null;
  yaw = 0;
  pitch = 0;
  lastTime = millis();
  bossTrackOffset = 0;
  currentScene = GameScene.BOSS_SHOOTER;
}

void drawBossShooter(){
  int currentTime = millis();
  deltaTime = currentTime - lastTime;
  lastTime = currentTime;
  
  background(245);
  hint(DISABLE_DEPTH_TEST);
  camera();
  
  if (bgBoss != null) {
    drawImageCover(bgBoss, 0, 0, width, height);
  }
  
  hint(ENABLE_DEPTH_TEST);
  
  float boardWidth = 720;
  float boardHeight = 420;
  
  float targetX = map(mouseX, 0, width, -boardWidth/2, boardWidth/2);
  float targetY = map(mouseY, 0, height, -boardHeight/2, boardHeight/2);
  PVector aimPoint = new PVector(targetX, targetY, 0);
  
  PVector dir = PVector.sub(aimPoint, cannonBase);
  yaw   = atan2(dir.x, dir.z);
  pitch = -atan2(dir.y, sqrt(dir.x*dir.x + dir.z*dir.z));
  
  placeCameraBehindCannon(yaw, pitch);
  
  lights();
  
  drawBossTrack();
  
  if (!bossShooterGameOver) {
    drawCrosshair(aimPoint);
  }
  
  if (target != null && !target.hit) {
    target.update(deltaTime);
    target.draw();
  }
  
  if (projectile != null) {
    projectile.update();
    projectile.draw();
    
    if (projectile.isOffScreen()) {
      projectile = null;
      if (!bossShooterWon) {
        bossShooterGameOver = true;
        bossShooterWon = false;
      }
    }
  }
  
  if (projectile != null && target != null && !target.hit) {
    if (PVector.dist(projectile.pos, target.pos) < (target.radius + projectile.radius)) {
      target.hit = true;
      bossShooterGameOver = true;
      bossShooterWon = true;
    }
  }
  
  noLights();
  imageMode(CENTER);
  if (cannon != null) {
    image(cannon, 5, 220);
  }
  
  drawBossShooterHUD();
  
  if (bossShooterGameOver) {
    drawBossShooterFinalScreen();
  }
}

void drawBossShooterHUD() {
  camera();
  hint(DISABLE_DEPTH_TEST);
  
  fill(0, 0, 0, 180);
  noStroke();
  rect(width - 310, 10, 300, 80, 10);
  
  fill(255, 220, 0);
  textSize(24);
  textAlign(RIGHT);
  
  if (!hasShot) {
    text("🎯 MUNICIÓN: 1", width - 20, 35);
  } else {
    text("🎯 MUNICIÓN: 0", width - 20, 35);
  }
  
  fill(255, 100, 100);
  textSize(18);
  text("¡CLICK PARA DISPARAR!", width - 20, 65);
  
  textAlign(LEFT);
  hint(ENABLE_DEPTH_TEST);
}

void drawBossShooterFinalScreen() {
  hint(DISABLE_DEPTH_TEST);
  camera();
  
  fill(0, 0, 0, 220);
  noStroke();
  rect(0, 0, width, height);
  
  textAlign(CENTER, CENTER);
  
  if (bossShooterWon) {
    fill(40, 100, 40);
    stroke(0, 255, 0);
    strokeWeight(5);
    rectMode(CENTER);
    rect(width/2, height/2, 700, 500, 20);
    rectMode(CORNER);
    
    fill(0, 255, 0);
    textSize(90);
    text("¡VICTORIA!", width/2, height/2 - 150);
    
    stroke(0, 255, 0);
    strokeWeight(3);
    line(width/2 - 300, height/2 - 80, width/2 + 300, height/2 - 80);
  } else {
    fill(40, 20, 20);
    stroke(255, 50, 50);
    strokeWeight(5);
    rectMode(CENTER);
    rect(width/2, height/2, 700, 500, 20);
    rectMode(CORNER);
    
    fill(255, 50, 50);
    textSize(90);
    text("¡FALLASTE!", width/2, height/2 - 150);
    
    stroke(255, 50, 50);
    strokeWeight(3);
    line(width/2 - 300, height/2 - 80, width/2 + 300, height/2 - 80);
  }
  
  fill(255, 220, 0);
  textSize(55);
  text("PUNTOS: " + finalScore, width/2, height/2 - 10);
  
  fill(0, 255, 150);
  textSize(45);
  text("💎 Diamantes: " + finalDiamonds, width/2, height/2 + 60);
  
  fill(100, 200, 255);
  textSize(35);
  text("💰 Gemas totales: " + gems, width/2, height/2 + 110);
  
  stroke(255, 255, 255, 100);
  strokeWeight(2);
  line(width/2 - 250, height/2 + 150, width/2 + 250, height/2 + 150);
  
  fill(255);
  textSize(30);
  if (bossShooterWon) {
    text("ESC: Menú   |   C: Completar nivel", width/2, height/2 + 190);
  } else {
    text("ESC: Menú   |   R: Reintentar", width/2, height/2 + 190);
  }
  
  textAlign(LEFT);
  hint(ENABLE_DEPTH_TEST);
}

void placeCameraBehindCannon(float yaw, float pitch) {
  PVector forward = new PVector(
    0,
    -sin(pitch),
    cos(yaw) * cos(pitch)
  );
  forward.normalize();
  
  float camBack = 360;
  float camUp   = -200;
  
  PVector worldUp = new PVector(0, 1, 0);
  PVector right = forward.copy().cross(worldUp);
  if (right.mag() < 1e-4) {
    worldUp = new PVector(1, 0, 0);
    right = forward.copy().cross(worldUp);
  }
  right.normalize();
  PVector up = right.copy().cross(forward).normalize();
  
  camPos = PVector.sub(cannonBase, PVector.mult(forward, camBack));
  camPos.add(PVector.mult(up, camUp));
  
  PVector center = PVector.add(cannonBase, PVector.mult(forward, 200));
  
  camera(camPos.x, 15, 500,
    0, -1, 0,
    up.x, up.y, up.z);
}

void drawBossTrack() {
  bossTrackOffset += 6;
  
  pushMatrix();
  translate(width/2, height/2, 0);
  
  for (int z = -10; z < 210; z++) {
    float zPos = -z * 80 - (bossTrackOffset % 80);
    
    fill(55, 55, 60);
    noStroke();
    beginShape(QUAD);
    vertex(-trackWidth - 840, 0, zPos);
    vertex(-640, 0, zPos);
    vertex(-640, 0, zPos + 80);
    vertex(-trackWidth - 840, 0, zPos + 80);
    endShape();
  }
  
  fill(180, 40, 40);
  for (int z = -10; z < 210; z++) {
    float zPos = -z * 80 - (bossTrackOffset % 80);
    
    pushMatrix();
    translate(-trackWidth - 848, -3, zPos + 40);
    box(12, 6, 80);
    popMatrix();
    pushMatrix();
    translate(- 632, -3, zPos + 40);
    box(12, 6, 80);
    popMatrix();
  }
  
  stroke(255);
  strokeWeight(2);
  for (int z = -10; z < 2100; z++) {
    float zPos = -z * 80 - (bossTrackOffset % 80);
    line(-trackWidth + 15-840, -1, zPos, -trackWidth + 15-840, -1, zPos + 80);
    line(-655, -1, zPos, - 655, -1, zPos + 80);
  }
  
  popMatrix();
}

void drawCrosshair(PVector p) {
  pushMatrix();
  translate(p.x, p.y, p.z + 0.5);
  noFill();
  stroke(0, 180);
  strokeWeight(2);
  
  ellipseMode(CENTER);
  ellipse(0, 0, 30, 30);
  
  line(-15, 0, 0, -5, 0, 0);
  line(5, 0, 0, 15, 0, 0);
  line(0, -15, 0, 0, -5, 0);
  line(0, 5, 0, 0, 15, 0);
  
  fill(255, 0, 0, 200);
  noStroke();
  ellipse(0, 0, 3, 3);
  
  noStroke();
  popMatrix();
}

void drawBillboardImage(PImage img, PVector worldPos, float w, float h, float alpha) {
  pushMatrix();
  translate(worldPos.x, worldPos.y, worldPos.z);
  
  PVector toCam = PVector.sub(camPos, worldPos);
  float yawToCam   = atan2(toCam.x, toCam.z);
  float pitchToCam = atan2(-toCam.y, sqrt(toCam.x*toCam.x + toCam.z*toCam.z));
  rotateY(0);
  rotateX(0);
  
  imageMode(CENTER);
  tint(255, alpha);
  image(img, 0, 0, w, h);
  noTint();
  
  popMatrix();
}

void shootBossShooter() {
  if (hasShot || bossShooterGameOver) return;
  
  hasShot = true;
  
  PVector forward = new PVector(
    sin(yaw) * cos(pitch),
    -sin(pitch),
    cos(yaw) * cos(pitch)
  );
  forward.normalize();
  
  PVector barrelTip = PVector.add(cannonBase, PVector.mult(forward, barrelLen));
  
  projectile = new Projectile(barrelTip, forward);
}

// ========== TRANSICIÓN ==========
void drawTransicion() {
  background(19, 175, 255);
  
  hint(DISABLE_DEPTH_TEST);
  camera();
  if (bgJuego != null) {
    drawImageCover(bgJuego, 0, 0, width, height);
  }
  hint(ENABLE_DEPTH_TEST);
  
  lights();
  camera(width/2, height/2 - 240, 380, width/2, height/2 - 75, -300, 0, 1, 0);
  hint(DISABLE_DEPTH_TEST);
  
  playerForwardZ += 8;
  player.z = 50 + playerForwardZ;
  offset += speed;
  
  drawTrack();
  player.update();
  player.display();
  
  fill(0, fadeAlpha);
  noStroke();
  rectMode(CORNER);
  rect(0, 0, width, height);
  
  if (fadeOut) {
    fadeAlpha += fadeSpeed;
    if (fadeAlpha >= 255) {
      fadeAlpha = 255;
      fadeOut = false;
      fadeIn = true;
      startBossWarning();
      fadeAlpha = 255;
    }
  } else if (fadeIn) {
    fadeAlpha -= fadeSpeed;
    if (fadeAlpha <= 0) {
      fadeAlpha = 0;
      fadeIn = false;
      transitioning = false;
    }
  }
  hint(ENABLE_DEPTH_TEST);
}

// ========== ELEMENTOS DEL JUEGO ==========
void drawTrack() {
  pushMatrix();
  translate(width/2, height/2, 0);
  
  for (int z = -10; z < 210; z++) {
    float zPos = -z * 80 - (offset % 80);
    
    fill(55, 55, 60);
    noStroke();
    beginShape(QUAD);
    vertex(-trackWidth/2, 0, zPos);
    vertex(trackWidth/2, 0, zPos);
    vertex(trackWidth/2, 0, zPos + 80);
    vertex(-trackWidth/2, 0, zPos + 80);
    endShape();
  }
  
  fill(180, 40, 40);
  for (int z = -10; z < 210; z++) {
    float zPos = -z * 80 - (offset % 80);
    
    pushMatrix();
    translate(-trackWidth/2 - 8, -3, zPos + 40);
    box(12, 6, 80);
    popMatrix();
    
    pushMatrix();
    translate(trackWidth/2 + 8, -3, zPos + 40);
    box(12, 6, 80);
    popMatrix();
  }
  
  stroke(255);
  strokeWeight(2);
  for (int z = -10; z < 210; z++) {
    float zPos = -z * 80 - (offset % 80);
    line(-trackWidth/2 + 15, -1, zPos, -trackWidth/2 + 15, -1, zPos + 80);
    line(trackWidth/2 - 15, -1, zPos, trackWidth/2 - 15, -1, zPos + 80);
  }
  
  popMatrix();
}

void updateObjects() {
  pushMatrix();
  translate(width/2, height/2, 0);
  
  for (int i = objects.size() - 1; i >= 0; i--) {
    PathObject obj = objects.get(i);
    obj.update(speed);
    obj.display();
    
    if (obj.z > 400) {
      objects.remove(i);
      int randomLane = int(random(0, 3));
      float xPos = (randomLane == 0) ? -trackWidth/4 : (randomLane == 1) ? 0 : trackWidth/4;
      objects.add(new PathObject(xPos, -6000, int(random(0, 3))));
    }
  }
  
  popMatrix();
}

void checkCollisions() {
  for (int i = 0; i < objects.size(); i++) {
    PathObject obj = objects.get(i);
    
    if (!obj.alive) continue;
    
    float dx = obj.x - player.x;
    float dz = obj.z - player.z;
    float distance = sqrt(dx * dx + dz * dz);
    
    if (distance < collisionDistance) {
      if (obj.type == 0) {
        obj.alive = false;
        score += 1;
        diamondsCollected++;
        diamondsForHealth++;
        
        if (diamondsForHealth >= 10) {
          int healthBefore = currentHealth;
          currentHealth = min(currentHealth + 25, absoluteMaxHealth);
          diamondsForHealth = 0;
          println("✨ ¡VIDA REGENERADA! +" + (currentHealth - healthBefore) + " HP");
        }
      } else {
        obj.alive = false;
        currentHealth -= 25;
        
        if (currentHealth <= 0) {
          currentHealth = 0;
          gameOver = true;
          endGameSession();
          println("💀 GAME OVER");
        }
      }
    }
  }
}

void drawScoreHUD() {
  fill(0, 0, 0, 180);
  noStroke();
  rect(width - 310, 10, 300, 130, 10);
  
  fill(255, 220, 0);
  textSize(28);
  textAlign(RIGHT);
  text("PUNTOS: " + score, width - 20, 45);
  
  fill(0, 255, 150);
  textSize(20);
  text("💎 Diamantes: " + diamondsCollected, width - 20, 75);
  
  fill(255, 100, 255);
  textSize(18);
  text("❤️ Siguiente vida: " + diamondsForHealth + "/10", width - 20, 105);
  
  textAlign(LEFT);
}

void drawHealthBar() {
  float barWidth = 300;
  float barHeight = 30;
  float barX = 10;
  float barY = 50;
  
  fill(100, 0, 0);
  noStroke();
  rect(barX, barY, barWidth, barHeight, 5);
  
  float healthPercent = (float)currentHealth / absoluteMaxHealth;
  float currentBarWidth = barWidth * healthPercent;
  
  if (currentHealth > maxHealth) {
    fill(0, 255, 255);
    if (frameCount % 30 < 15) {
      fill(100, 255, 255);
    }
  } else if (healthPercent > 0.6) {
    fill(0, 255, 0);
  } else if (healthPercent > 0.3) {
    fill(255, 200, 0);
  } else {
    fill(255, 0, 0);
  }
  
  rect(barX, barY, currentBarWidth, barHeight, 5);
  
  if (currentHealth > maxHealth) {
    float normalHealthWidth = barWidth * (maxHealth / (float)absoluteMaxHealth);
    stroke(255, 255, 0);
    strokeWeight(2);
    line(barX + normalHealthWidth, barY, barX + normalHealthWidth, barY + barHeight);
  }
  
  noFill();
  stroke(255);
  strokeWeight(3);
  rect(barX, barY, barWidth, barHeight, 5);
  
  fill(255);
  textSize(20);
  textAlign(CENTER);
  text(currentHealth + " / " + absoluteMaxHealth, barX + barWidth/2, barY + 22);
  textAlign(LEFT);
  
  fill(255);
  textSize(16);
  String healthLabel = "VIDA";
  if (currentHealth > maxHealth) {
    healthLabel = "VIDA ★ EXTRA";
    fill(0, 255, 255);
  }
  text(healthLabel, barX, barY - 5);
}

void drawTimeCounter() {
  float barWidth = 200;
  float barHeight = 50;
  float barX = width/2 - barWidth/2;
  float barY = 10;
  
  fill(0, 0, 0, 180);
  noStroke();
  rect(barX, barY, barWidth, barHeight, 10);
  
  if (timeLeft > 20) {
    fill(0, 255, 0);
  } else if (timeLeft > 10) {
    fill(255, 200, 0);
  } else {
    fill(255, 0, 0);
    if (timeLeft <= 5 && frameCount % 20 < 10) {
      fill(255, 100, 100);
    }
  }
  
  textSize(32);
  textAlign(CENTER);
  text("⏱ " + timeLeft + "s", barX + barWidth/2, barY + 35);
  
  textAlign(LEFT);
}

void drawGameOver() {
  hint(DISABLE_DEPTH_TEST);
  
  fill(0, 0, 0, 220);
  noStroke();
  rect(0, 0, width, height);
  
  fill(40, 20, 20);
  stroke(255, 50, 50);
  strokeWeight(5);
  rectMode(CENTER);
  rect(width/2, height/2, 700, 500, 20);
  rectMode(CORNER);
  
  fill(255, 50, 50);
  textSize(90);
  textAlign(CENTER, CENTER);
  text("GAME OVER", width/2, height/2 - 150);
  
  stroke(255, 50, 50);
  strokeWeight(3);
  line(width/2 - 300, height/2 - 80, width/2 + 300, height/2 - 80);
  
  fill(255, 220, 0);
  textSize(55);
  text("PUNTOS: " + score, width/2, height/2 - 10);
  
  fill(0, 255, 150);
  textSize(45);
  text("💎 Diamantes: " + diamondsCollected, width/2, height/2 + 60);
  
  fill(100, 200, 255);
  textSize(35);
  text("💰 Gemas totales: " + gems, width/2, height/2 + 110);
  
  stroke(255, 255, 255, 100);
  strokeWeight(2);
  line(width/2 - 250, height/2 + 150, width/2 + 250, height/2 + 150);
  
  fill(255);
  textSize(30);
  text("ESC: Menú   |   R: Reintentar", width/2, height/2 + 190);
  
  textAlign(LEFT);
  hint(ENABLE_DEPTH_TEST);
}

void diamond(float size) {
  float s = 15;
  
  fill(0, 255, 150);
  beginShape(TRIANGLES);
  vertex(0, s, 0);
  vertex(-s, 0, s);
  vertex(s, 0, s);
  vertex(0, s, 0);
  vertex(s, 0, s);
  vertex(s, 0, -s);
  vertex(0, s, 0);
  vertex(s, 0, -s);
  vertex(-s, 0, -s);
  vertex(0, s, 0);
  vertex(-s, 0, -s);
  vertex(-s, 0, s);
  endShape();
  
  fill(0, 200, 120);
  beginShape(TRIANGLES);
  vertex(0, -s, 0);
  vertex(s, 0, s);
  vertex(-s, 0, s);
  vertex(0, -s, 0);
  vertex(s, 0, -s);
  vertex(s, 0, s);
  vertex(0, -s, 0);
  vertex(-s, 0, -s);
  vertex(s, 0, -s);
  vertex(0, -s, 0);
  vertex(-s, 0, s);
  vertex(-s, 0, -s);
  endShape();
}

// ========== CLASES ==========
class BossEnemy {
  float x, z;
  int lane;
  float targetX;
  float moveSpeed;
  boolean hit = false;
  float size = 80;
  int animFrame = 0;
  int frameCounter = 0;
  
  BossEnemy() {
    lane = int(random(0, 3));
    z = -3000;
    moveSpeed = 6;
    updateTargetX();
    x = targetX;
  }
  
  void updateTargetX() {
    if (lane == 0) {
      targetX = -trackWidth/4;
    } else if (lane == 1) {
      targetX = 0;
    } else {
      targetX = trackWidth/4;
    }
  }
  
  void changeLane() {
    lane = int(random(0, 3));
    updateTargetX();
  }
  
  void update() {
    if (hit) return;
    
    z += moveSpeed;
    x = lerp(x, targetX, 0.08);
    
    if (random(100) < 1.5) {
      changeLane();
    }
    
    frameCounter++;
    if (frameCounter >= 5) {
      frameCounter = 0;
      animFrame = (animFrame + 1) % 4;
    }
  }
  
  void display() {
    pushMatrix();
    translate(width/2, height/2, 0);
    translate(x, -60, z);
    
    noStroke();
    
    if (hit) {
      for (int i = 0; i < 10; i++) {
        pushMatrix();
        translate(random(-30, 30), random(-30, 30), random(-30, 30));
        fill(255, random(100, 255), 0, 200);
        sphere(random(5, 15));
        popMatrix();
      }
    } else {
      if (cacodemon != null && spritesLoaded) {
        hint(DISABLE_DEPTH_TEST);
        pushMatrix();
        rotateY(PI);
        beginShape(QUADS);
        textureMode(NORMAL);
        texture(cacodemon);
        float w = size * 2;
        float h = size * 2;
        vertex(-w/2, -h, 0, 0, 0);
        vertex(w/2, -h, 0, 1, 0);
        vertex(w/2, 0, 0, 1, 1);
        vertex(-w/2, 0, 0, 0, 1);
        endShape();
        popMatrix();
        hint(ENABLE_DEPTH_TEST);
      } else {
        rotateY(PI);
        fill(150, 20, 20);
        sphere(size/2);
        
        fill(255, 0, 0);
        pushMatrix();
        translate(-15, -10, size/2 - 5);
        sphere(8);
        popMatrix();
        
        pushMatrix();
        translate(15, -10, size/2 - 5);
        sphere(8);
        popMatrix();
        
        fill(100, 10, 10);
        pushMatrix();
        translate(-20, -40, 0);
        rotateZ(-0.3);
        box(8, 30, 8);
        popMatrix();
        
        pushMatrix();
        translate(20, -40, 0);
        rotateZ(0.3);
        box(8, 30, 8);
        popMatrix();
      }
      
      pushMatrix();
      translate(0, 62, 0);
      rotateX(PI/2);
      fill(0, 0, 0, 100);
      noStroke();
      ellipse(0, 0, size * 2, size);
      popMatrix();
    }
    
    popMatrix();
  }
}

class Target {
  PVector pos;
  float radius;
  color col;
  boolean hit = false;
  
  float speedX;
  float minX, maxX;
  float changeTimer = 0;
  float changeInterval = random(800, 1500);
  
  Target() {
    float boardHalfW = 360;
    float boardHalfH = 210;
    float margin = 60;
    
    float yCenter = 0;
    
    minX = -boardHalfW;
    maxX =  boardHalfW - margin;
    
    float startX = 0;
    
    pos = new PVector(startX, yCenter, -40);
    
    radius = 50;
    col = color(255, 50, 50);
    
    speedX = (random(0, 1) < 0.5 ? -1 : 1) * random(120, 200);
  }
  
  void update(float dtMillis) {
    if (hit) return;
    
    float dt = dtMillis / 1000.0;
    
    changeTimer += dtMillis;
    if (changeTimer > changeInterval) {
      speedX = (random(0, 1) < 0.5 ? -1 : 1) * random(120, 200);
      changeInterval = random(800, 1500);
      changeTimer = 0;
    }
    
    pos.x += speedX * dt;
    
    if (pos.x < minX) {
      pos.x = minX;
      speedX *= -1;
    } else if (pos.x > maxX) {
      pos.x = maxX;
      speedX *= -1;
    }
  }
  
  void draw() {
    float alpha = hit ? 200 : 255;
    
    float s = radius * 3.5;
    PVector p = new PVector(pos.x, pos.y, pos.z);
    
    if (cacodemon != null) {
      drawBillboardImage(cacodemon, p, s, s, alpha);
    }
  }
}

class Projectile {
  PVector pos;
  PVector vel;
  float radius = 5;
  
  Projectile(PVector start, PVector direction) {
    pos = start.copy();
    vel = direction.copy();
    vel.normalize();
    vel.mult(projectileSpeed);
  }
  
  void update() {
    pos.add(vel);
  }
  
  boolean isOffScreen() {
    return pos.z < -100 || abs(pos.x) > 500 || abs(pos.y) > 500;
  }
  
  void draw() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    fill(255, 200, 0);
    noStroke();
    sphere(radius);
    popMatrix();
  }
}

class PathObject {
  float x, z;
  int type;
  color objColor;
  float size;
  int animFrame = 0;
  int animSpeed = 5;
  int frameCounter = 0;
  boolean alive = true;
  
  PathObject(float x, float z, int type) {
    this.x = x;
    this.z = z;
    this.type = type;
    this.size = 40;
    
    if (this.type == 0) {
      objColor = color(0, 255, 150);
    } else if (this.type == 1) {
      objColor = color(100, 100, 200);
    } else {
      objColor = color(200, 50, 50);
    }
  }
  
  void update(float speed) {
    z += speed;
    
    frameCounter++;
    if (frameCounter >= animSpeed) {
      frameCounter = 0;
      animFrame = (animFrame + 1) % 4;
    }
  }
  
  void display() {
    if (!alive) return;
    
    pushMatrix();
    translate(x, -30, z);
    
    noStroke();
    
    if (spritesLoaded && type != 0) {
      hint(DISABLE_DEPTH_TEST);
      
      pushMatrix();
      rotateY(PI);
      
      beginShape(QUADS);
      textureMode(NORMAL);
      
      PImage currentSprite = null;
      if (type == 1 && droidSprites != null && droidSprites[0] != null) {
        currentSprite = droidSprites[animFrame % totalDroidFrames];
      } else if (type == 2 && kamchakSprites != null && kamchakSprites[0] != null) {
        currentSprite = kamchakSprites[animFrame % totalKamchakFrames];
      }
      
      if (currentSprite != null) {
        texture(currentSprite);
        float w = 60;
        float h = 60;
        vertex(-w/2, -h, 0, 0, 0);
        vertex(w/2, -h, 0, 1, 0);
        vertex(w/2, 0, 0, 1, 1);
        vertex(-w/2, 0, 0, 0, 1);
      }
      endShape();
      popMatrix();
      
      hint(ENABLE_DEPTH_TEST);
      
    } else {
      rotateY(PI);
      
      if (type == 0) {
        pushMatrix();
        rotateY(-PI);
        diamond(0);
        popMatrix();
      } else if (type == 1) {
        drawDroid();
      } else {
        drawKamchak();
      }
    }
    
    pushMatrix();
    translate(0, 32, 0);
    rotateX(PI/2);
    fill(0, 0, 0, 100);
    noStroke();
    ellipse(0, 0, size * 1.2, size * 0.6);
    popMatrix();
    
    popMatrix();
  }
  
  void drawDroid() {
    pushMatrix();
    
    fill(60, 70, 90);
    sphere(25);
    
    fill(80, 90, 120);
    pushMatrix();
    translate(-20, 0, 0);
    rotateZ(sin(frameCount * 0.1 + animFrame) * 0.3);
    box(8, 25, 8);
    popMatrix();
    
    pushMatrix();
    translate(20, 0, 0);
    rotateZ(-sin(frameCount * 0.1 + animFrame) * 0.3);
    box(8, 25, 8);
    popMatrix();
    
    fill(255, 100, 100);
    pushMatrix();
    translate(0, 0, 25);
    sphere(8);
    popMatrix();
    
    translate(0, sin(frameCount * 0.1 + animFrame) * 3, 0);
    
    popMatrix();
  }
  
  void drawKamchak() {
    pushMatrix();
    
    float walkCycle = sin(frameCount * 0.15 + animFrame) * 5;
    
    fill(80, 100, 70);
    pushMatrix();
    translate(0, -10 + abs(walkCycle) * 0.5, 0);
    box(35, 40, 30);
    popMatrix();
    
    fill(120, 80, 60);
    pushMatrix();
    translate(0, -35, 0);
    box(25, 20, 25);
    popMatrix();
    
    fill(60, 80, 50);
    
    pushMatrix();
    translate(-12, 10, 0);
    translate(0, walkCycle, 0);
    box(10, 20, 10);
    popMatrix();
    
    pushMatrix();
    translate(12, 10, 0);
    translate(0, -walkCycle, 0);
    box(10, 20, 10);
    popMatrix();
    
    fill(100, 60, 40);
    
    pushMatrix();
    translate(-20, -10, 5);
    rotateZ(sin(frameCount * 0.1) * 0.2);
    box(8, 15, 8);
    popMatrix();
    
    pushMatrix();
    translate(20, -10, 5);
    rotateZ(-sin(frameCount * 0.1) * 0.2);
    box(8, 15, 8);
    popMatrix();
    
    fill(255, 0, 0);
    pushMatrix();
    translate(-8, -30, 15);
    sphere(4);
    popMatrix();
    
    pushMatrix();
    translate(8, -30, 15);
    sphere(4);
    popMatrix();
    
    popMatrix();
  }
}

class Player {
  float x, z;
  int lane;
  float targetX;
  float moveSpeed;
  int animFrame = 0;
  int frameCounter = 0;
  int animSpeed = 8;
  
  Player() {
    lane = 1;
    z = 50;
    moveSpeed = 15;
    updateTargetX();
    x = targetX;
  }
  
  void updateTargetX() {
    if (lane == 0) {
      targetX = -trackWidth/4;
    } else if (lane == 1) {
      targetX = 0;
    } else {
      targetX = trackWidth/4;
    }
  }
  
  void moveLeft() {
    if (lane > 0) {
      lane--;
      updateTargetX();
    }
  }
  
  void moveRight() {
    if (lane < 2) {
      lane++;
      updateTargetX();
    }
  }
  
  void update() {
    x = lerp(x, targetX, 0.5);
    
    frameCounter++;
    if (frameCounter >= animSpeed) {
      frameCounter = 0;
      animFrame = (animFrame + 1) % 4;
    }
  }
  
  void display() {
    pushMatrix();
    translate(width/2, height/2, 0);
    translate(x, -20, z);
    
    noStroke();
    
    if (playerSpritesLoaded && playerSprites[currentPlayer][0] != null) {
      hint(DISABLE_DEPTH_TEST);
      
      pushMatrix();
      rotateY(PI);
      
      beginShape(QUADS);
      textureMode(NORMAL);
      
      PImage currentSprite = playerSprites[currentPlayer][animFrame];
      
      if (currentSprite != null) {
        texture(currentSprite);
        float w = 50;
        float h = 50;
        vertex(-w/2, -h, 0, 0, 0);
        vertex(w/2, -h, 0, 1, 0);
        vertex(w/2, 0, 0, 1, 1);
        vertex(-w/2, 0, 0, 0, 1);
      }
      endShape();
      popMatrix();
      
      hint(ENABLE_DEPTH_TEST);
    } else {
      fill(0, 255, 0);
      box(30, 30, 30);
    }
    
    pushMatrix();
    translate(0, 20, 0);
    rotateX(PI/2);
    fill(0, 0, 0, 80);
    noStroke();
    ellipse(0, 0, 35, 25);
    popMatrix();
    
    popMatrix();
  }
}

// ========== CONTROLES ==========
void mousePressed(){
  if (currentScene == GameScene.INICIO){
    if (btnPlay.over())  currentScene = GameScene.SELECCION;
    if (btnStore.over()) currentScene = GameScene.TIENDA;
  }
  else if (currentScene == GameScene.BOSS_SHOOTER) {
    shootBossShooter();
  }
  else if (currentScene == GameScene.SELECCION){
    if (overBack()){ currentScene = GameScene.INICIO; return; }
    float cardW = min(width*0.32f, 520);
    float cardH = cardW * 0.62f;
    float leftX  = width*0.30f - cardW/2f;
    float rightX = width*0.69f - cardW/2f;
    float cardsY = height*0.52f - cardH/2f + 135;
    if (mouseX > leftX && mouseX < leftX+cardW && mouseY > cardsY && mouseY < cardsY+cardH){
      terrainChosen = 0; currentScene = GameScene.PERSONAJE; return;
    } else if (mouseX > rightX && mouseX < rightX+cardW && mouseY > cardsY && mouseY < cardsY+cardH){
      terrainChosen = 1; currentScene = GameScene.PERSONAJE; return;
    }
  }
  else if (currentScene == GameScene.PERSONAJE){
    if (overBack()){ currentScene = GameScene.SELECCION; return; }
    if (mouseX > leftX - arrowW/2 && mouseX < leftX + arrowW/2 &&
        mouseY > leftY - arrowH/2 && mouseY < leftY + arrowH/2){
      currentPlayer = (currentPlayer - 1 + NUM_PLAYERS) % NUM_PLAYERS; return;
    }
    if (mouseX > rightX - arrowW/2 && mouseX < rightX + arrowW/2 &&
        mouseY > rightY - arrowH/2 && mouseY < rightY + arrowH/2){
      currentPlayer = (currentPlayer + 1) % NUM_PLAYERS; return;
    }
    if (mouseX > toggleX && mouseX < toggleX + toggleW &&
        mouseY > toggleY && mouseY < toggleY + toggleH){
      useAccessory = !useAccessory; return;
    }
    if (mouseX > btnPlaySelX && mouseX < btnPlaySelX + btnPlaySelW &&
        mouseY > btnPlaySelY && mouseY < btnPlaySelY + btnPlaySelH){
      selectedLevel = -1; currentScene = GameScene.NIVEL; return;
    }
  }
  else if (currentScene == GameScene.NIVEL){
    if (overBack()){ currentScene = GameScene.PERSONAJE; return; }
    int cols = 2, rows = 2;
    float gridW = min(width*0.75f, 760);
    float gridH = min(height*0.55f, 420);
    float startX = width*0.5f - gridW/2f;
    float startY = height*0.52f - gridH/2f + 20;
    float pad = 28;
    float cellW = (gridW - pad*(cols-1)) / cols;
    float cellH = (gridH - pad*(rows-1)) / rows;
    int n = 1;
    for (int r=0; r<rows; r++){
      for (int c=0; c<cols; c++){
        float x = startX + c*(cellW + pad);
        float y = startY + r*(cellH + pad);
        if (mouseX > x && mouseX < x+cellW && mouseY > y && mouseY < y+cellH){
          if (isLevelUnlocked(terrainChosen, n)){
            selectedLevel = n;
            startGame();
            currentScene = GameScene.JUEGO;
            return;
          }
        }
        n++;
      }
    }
  }
  else if (currentScene == GameScene.TIENDA){
    if (overBack()){ currentScene = GameScene.INICIO; return; }
    for (int i=0; i<items.length; i++){
      ShopItem it = items[i];
      if (it.over()){
        if (!it.owned){
          if (gems >= it.price){
            gems -= it.price; it.owned = true; equippedIndex = i; toast("Comprado: " + it.name);
          } else {
            toast("No alcanza");
          }
        } else {
          equippedIndex = i; toast("Equipado: " + it.name);
        }
      }
    }
  }
}

void keyPressed(){
  if (currentScene == GameScene.INICIO){
    if (key == ENTER || key == ' ') currentScene = GameScene.SELECCION;
    if (key == 's' || key == 'S')   currentScene = GameScene.TIENDA;
  }
  else if (currentScene == GameScene.SELECCION){
    if (key == ESC){ key = 0; currentScene = GameScene.INICIO; }
    if (key == '1'){ terrainChosen = 0; currentScene = GameScene.PERSONAJE; }
    if (key == '2'){ terrainChosen = 1; currentScene = GameScene.PERSONAJE; }
  }
  else if (currentScene == GameScene.PERSONAJE){
    if (key == ESC){ key = 0; currentScene = GameScene.SELECCION; }
    if (keyCode == LEFT)  currentPlayer = (currentPlayer - 1 + NUM_PLAYERS) % NUM_PLAYERS;
    if (keyCode == RIGHT) currentPlayer = (currentPlayer + 1) % NUM_PLAYERS;
    if (key == ENTER || key == ' ') { selectedLevel = -1; currentScene = GameScene.NIVEL; }
  }
  else if (currentScene == GameScene.NIVEL){
    if (key == ESC){ key = 0; currentScene = GameScene.PERSONAJE; }
  }
  else if (currentScene == GameScene.TIENDA){
    if (key == ESC){ key = 0; currentScene = GameScene.INICIO; }
    if (key == 'g' || key == 'G') addGems(1000);
  }
  else if (currentScene == GameScene.JUEGO){
    if (key == ESC){
      key = 0;
      currentScene = GameScene.INICIO;
      return;
    }
    
    if (key == 'r' || key == 'R') {
      startGame();
      return;
    }
    
    if (gameOver || !gameRunning) return;
    
    if (keyCode == UP) {
      speed = min(speed + 0.5, 20);
    } else if (keyCode == DOWN) {
      speed = max(speed - 0.5, 0.5);
    }
    
    if (keyCode == LEFT || key == 'a' || key == 'A') {
      player.moveLeft();
    } else if (keyCode == RIGHT || key == 'd' || key == 'D') {
      player.moveRight();
    }
  }
  else if (currentScene == GameScene.BOSS_CHASE){
    if (key == ESC){
      key = 0;
      currentScene = GameScene.INICIO;
      return;
    }
    
    if (key == 'r' || key == 'R' && !bossChaseWon) {
      startGame();
      return;
    }
    
    if ((key == ' ' || key == ENTER) && !bossChaseGameOver) {
      shootAtBossChase();
      return;
    }
    
    if (bossChaseGameOver && bossChaseWon && (key == 'c' || key == 'C')) {
      unlockNextLevel(terrainChosen, selectedLevel);
      toast("¡Nivel " + selectedLevel + " completado!");
      currentScene = GameScene.NIVEL;
      return;
    }
    
    if (!bossChaseGameOver) {
      if (keyCode == LEFT || key == 'a' || key == 'A') {
        player.moveLeft();
      } else if (keyCode == RIGHT || key == 'd' || key == 'D') {
        player.moveRight();
      }
    }
  }
  else if (currentScene == GameScene.BOSS_SHOOTER){
    if (key == ESC){
      key = 0;
      currentScene = GameScene.INICIO;
      return;
    }
    
    if (key == 'r' || key == 'R' && !bossShooterWon) {
      startGame();
      return;
    }
    
    if (bossShooterGameOver && bossShooterWon && (key == 'c' || key == 'C')) {
      unlockNextLevel(terrainChosen, selectedLevel);
      toast("¡Nivel " + selectedLevel + " completado!");
      currentScene = GameScene.NIVEL;
      return;
    }
  }
}
