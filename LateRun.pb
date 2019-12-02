Procedure.f IIf(Test.b, ValTrue.f, ValFalse.f);classic vb function, helps us to save some lines in if else endif fragments
  If Test : ProcedureReturn ValTrue : EndIf : ProcedureReturn ValFalse
EndProcedure
Structure TRect
  x.f : y.f : w.f : h.f
EndStructure
Prototype UpdateSpriteProc(SpriteAddress.i, Elapsed.f);our prototype procedure that each sprite can call to update itself
EnumerationBinary SpriteTypes : #Hero : #Obstacle : #Ground : #Cloud : EndEnumeration
Structure TSprite
  x.f : y.f;position
  XVelocity.f : YVelocity.f;velociy in each axis
  SpriteNum.i : SpriteType.a
  NumFrames.a : CurrentFrame.a
  Width.u : Height.u;the original width and height of the sprite, before zooming
  AnimationTimer.f : IsAnimated.a
  IsAlive.b
  DrawOrder.u;the sprites with lower draw order must be drawn first
  ZoomLevel.f;the actual width or height it must be multiplied by the zoomlevel value
  Update.UpdateSpriteProc;the address of the update procedure that will update sprites positions and velocities, also handles inputs
  CollisionRect.TRect
EndStructure
Procedure.a AABBCollision(*Rect1.TRect, *Rect2.TRect)
  ProcedureReturn Bool(*Rect1\x < *Rect2\x + *Rect2\w And 
                       *Rect1\x + *Rect1\w > *Rect2\x And
                       *Rect1\y < *Rect2\y + *Rect2\h And
                       *Rect1\y + *Rect1\h > *Rect2\y)
EndProcedure
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, StartTimeInMs.q, SoundInitiated.b, IsGameOver.a, IsInvincibleMode.a
Global NewList SpriteList.TSprite(), *Hero.TSprite, *Ground1.TSprite, *Ground2.TSprite
Global HeroDistanceFromScreenEdge.f, IsHeroOnGround.b = #True, HeroGroundY.f, HeroBottom.f, HeroJumpTimer.f, IsHeroJumping.b = #False
Global BaseVelocity.f, ObstaclesVelocity.f
Global Score.f, ScoreModuloDivisor.l, DrawCollisionBoxes.a = #False, PausedGame.a = #False
#Animation_FPS = 12 : #Bitmap_Font_Sprite = 0 : #Obstacle_Gap_Time_Multiplier = 0.8
Global Hero_Sprite_Path.s = BasePath + "graphics" + #PS$ + "hero.png"
Global Dog_Sprite_Path.s = BasePath + "graphics" + #PS$ + "dog-48x27-transparent.png";Represented by D below
Global BusinessMan_Sprite_Path.s = BasePath + "graphics" + #PS$ + "businessman-24x48.png";R below
Global Fence_Sprite_Path.s = BasePath + "graphics" + #PS$ + "fence-16x24.png";F below
Global Bird_Sprite_Path.s = BasePath + "graphics" + #PS$ + "bird-32x32.png"  ;B below
Global Ground_Sprite_Path.s = BasePath + "graphics" + #PS$ + "ground-672x160.png"
Global Clouds_Sprite_Path.s = BasePath + "graphics" + #PS$ + "clouds-120x40.png"
Global ObstaclesPatterns.s = "D;DD;R;RR;RRR;RRF;F;FF;FFF;FFR;FR;RFF;RF;FRF";each letter represents an obstacle, two letters together means the obstacles are side by side
Procedure SetCollisionRect(*Sprite.TSprite, Offset.a = 8)
  *Sprite\CollisionRect\w = (*Sprite\Width * *Sprite\ZoomLevel) - Offset : *Sprite\CollisionRect\h = (*Sprite\Height * *Sprite\ZoomLevel) - Offset
  *Sprite\CollisionRect\x = (*Sprite\x + (*Sprite\Width * *Sprite\ZoomLevel) / 2) - *Sprite\CollisionRect\w / 2
  *Sprite\CollisionRect\y = (*Sprite\y + (*Sprite\Height * *Sprite\ZoomLevel) / 2) - *Sprite\CollisionRect\h / 2
EndProcedure
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpritePath.s, SpriteType.a, NumFrames.a, IsAnimated.a, IsAlive.b, UpdateProc.UpdateSpriteProc, ZoomLevel.f = 1)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = LoadSprite(#PB_Any, SpritePath) : *Sprite\SpriteType = SpriteType : *Sprite\IsAlive = IsAlive : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\Update = UpdateProc : *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 1 / #Animation_FPS
  *Sprite\NumFrames = NumFrames : *Sprite\IsAnimated = IsAnimated : *Sprite\Width = SpriteWidth(*Sprite\SpriteNum) / NumFrames
  *Sprite\Height = SpriteHeight(*Sprite\SpriteNum);we assume all sprite sheets are only one row
  SetCollisionRect(*Sprite)
EndProcedure
Global StartJump.q = 0, LowestHeroY.f = 1000
Procedure UpdateHero(HeroSpriteAddress.i, Elapsed.f);we should upadate the Hero sprite state here
  *HeroSprite.TSprite = HeroSpriteAddress : SpacePushed.b = KeyboardPushed(#PB_Key_Space) : SpaceReleased.b = KeyboardReleased(#PB_Key_Space)
  If (Not IsHeroJumping) And SpacePushed And IsHeroOnGround
    IsHeroJumping = #True
  EndIf
  HeroJumpTimer + IIf(IsHeroJumping, Elapsed, 0.0)
  If (IsHeroJumping And (HeroJumpTimer >= 0.15)) Or (IsHeroJumping And SpaceReleased)
    EndHeroJump = #True
  EndIf
  If EndHeroJump;the hero jumped!
    StartJump = ElapsedMilliseconds()
    *HeroSprite\YVelocity = IIf(Bool(HeroJumpTimer >= 0.15), -750.0, -650.0)
    IsHeroJumping = #False : HeroJumpTimer = 0.0 : EndHeroJump = #False : IsHeroOnGround = #False
  EndIf
  *HeroSprite\y + *HeroSprite\YVelocity * Elapsed
  LowestHeroY = IIf(Bool(*HeroSprite\y < LowestHeroY), *HeroSprite\y, LowestHeroY)
  If *HeroSprite\y > HeroGroundY
    *HeroSprite\y = HeroGroundY : IsHeroOnGround = #True : *HeroSprite\YVelocity = 0.0
    ;Debug "Jump time:" + Str(ElapsedMilliseconds() - StartJump) : StartJump = 0
    ;Debug "Lowest Y:" + StrF(LowestHeroY) : LowestHeroY = 1000
  EndIf
  If Not IsHeroOnGround;kind like gravity here
    *HeroSprite\YVelocity + 2200 * Elapsed
  EndIf
  SetCollisionRect(*HeroSprite)
  ForEach SpriteList()
    If SpriteList()\SpriteType & #Obstacle
      If AABBCollision(@*HeroSprite\CollisionRect, @SpriteList()\CollisionRect)
        IsGameOver = Bool(Not IsInvincibleMode)
      EndIf
    EndIf
  Next
EndProcedure
Procedure UpdateObstacle(ObstacleAddress.i, Elapsed.f);obstacles only goes to the left at the given velocity
  *Obstacle.TSprite = ObstacleAddress : *Obstacle\x + *Obstacle\XVelocity * Elapsed
  *Obstacle\IsAlive = IIf(Bool(*Obstacle\x < -(*Obstacle\Width * *Obstacle\ZoomLevel)), #False, #True)
  SetCollisionRect(*Obstacle)
EndProcedure
Procedure UpdateGround(GroundTileAdrress.i, Elapsed.f)
  If GroundTileAdrress <> *Ground1 : ProcedureReturn : EndIf;we only process ground1, ground2 position is relative to ground1
  *Ground1\x + (-ObstaclesVelocity * BaseVelocity) * Elapsed
  If *Ground1\x <= -(*Ground1\Width * *Ground1\ZoomLevel)
    *Ground1\x = *Ground2\x + (*Ground2\Width * *Ground2\ZoomLevel) - 1
  ElseIf *Ground2\x <= -(*Ground2\Width * *Ground2\ZoomLevel)
    *Ground2\x = *Ground1\x + (*Ground1\Width * *Ground1\ZoomLevel) - 1
  EndIf
  If *Ground1\x <= *Ground2\x
    *Ground2\x = *Ground1\x + (*Ground1\Width * *Ground1\ZoomLevel) - 1
  Else
    *Ground2\x = *Ground1\x - (*Ground2\Width * *Ground2\ZoomLevel) + 1
  EndIf
EndProcedure
Procedure UpdateSpriteList(List SpriteList.TSprite(), Elapsed.f)
  ForEach SpriteList()
    If SpriteList()\Update = #Null : Continue : EndIf
    *CurrentSprite.TSprite = @SpriteList();save the current sprite being updated
    ResetList(SpriteList());reset the list so that the update functions can loop the spritelist from the beginning
    *CurrentSprite\Update(*CurrentSprite, Elapsed);call the update function on the current sprite
    ChangeCurrentElement(SpriteList(), *CurrentSprite);reset the current sprite so that we can go on to the next one
  Next
EndProcedure
Procedure DisplaySpriteList(List SpriteList.TSprite(), Elapsed.f)
  ForEach SpriteList()
    ClipSprite(SpriteList()\SpriteNum, SpriteList()\CurrentFrame * SpriteList()\Width, 0, SpriteList()\Width, SpriteList()\Height);here we clip the current frame that we want to display
    ZoomSprite(SpriteList()\SpriteNum, SpriteList()\Width * SpriteList()\ZoomLevel, SpriteList()\Height * SpriteList()\ZoomLevel) ;the zoom must be applied after the clipping(https://www.purebasic.fr/english/viewtopic.php?p=421807#p421807)
    If SpriteList()\IsAnimated
      If SpriteList()\AnimationTimer <= 0.0;time to change frames and reset the animation timer
        SpriteList()\CurrentFrame = IIf(Bool(SpriteList()\CurrentFrame + 1 > SpriteList()\NumFrames - 1), 0, SpriteList()\CurrentFrame + 1)
        SpriteList()\AnimationTimer = 1 / #Animation_FPS
      EndIf
      SpriteList()\AnimationTimer - Elapsed;run the timer to get to the next frame
    EndIf
    DisplayTransparentSprite(SpriteList()\SpriteNum, SpriteList()\x, SpriteList()\y)
  Next
  If DrawCollisionBoxes
    StartDrawing(ScreenOutput()) : DrawingMode(#PB_2DDrawing_Outlined)
    ForEach SpriteList()
      Box(SpriteList()\CollisionRect\x, SpriteList()\CollisionRect\y, SpriteList()\CollisionRect\w, SpriteList()\CollisionRect\h)
    Next
    StopDrawing()
  EndIf
EndProcedure
Procedure RemoveSpritesFromList(List SpriteList.TSprite())
  ForEach SpriteList()
    If Not SpriteList()\IsAlive
      FreeSprite(SpriteList()\SpriteNum)
      DeleteElement(SpriteList())
    EndIf
  Next
EndProcedure
Procedure LoadGroundSprites(List SpriteList.TSprite())
  AddElement(SpriteList())
  InitializeSprite(@SpriteList(), 0, 0, 0, 0, Ground_Sprite_Path, #Ground, 1, #False, #True, @UpdateGround(), 1)
  SpriteList()\x = ScreenWidth() / 2 - (SpriteList()\Width * SpriteList()\ZoomLevel / 2)
  SpriteList()\y = HeroBottom : *Ground1 = @SpriteList()
  AddElement(SpriteList())
  InitializeSprite(@SpriteList(), 0, 0, 0, 0, Ground_Sprite_Path, #Ground, 1, #False, #True, @UpdateGround(), 1)
  SpriteList()\x = *Ground1\x + (*Ground1\Width * *Ground1\ZoomLevel)
  SpriteList()\y = HeroBottom : *Ground2 = @SpriteList()
EndProcedure
Procedure StartGame();we start a new game here
  ForEach SpriteList() : SpriteList()\IsAlive = #False :Next;mark all sprites as not alive, so we can remove them
  RemoveSpritesFromList(SpriteList())
  AddElement(SpriteList()) : *Hero = @SpriteList()
  InitializeSprite(*Hero, 0, 0, 0, 0, Hero_Sprite_Path, #Hero, 4, #True, #True, @UpdateHero(), 4)
  *Hero\x = *Hero\Width * *Hero\ZoomLevel : HeroGroundY = ScreenHeight() / 2 * 1.25 : *Hero\y = HeroGroundY;starting position for the hero
  HeroDistanceFromScreenEdge = ScreenWidth() - (*Hero\CollisionRect\x + *Hero\CollisionRect\w) : HeroBottom = HeroGroundY + (*Hero\Height * *Hero\ZoomLevel)
  IsHeroOnGround = #True : HeroJumpTimer = 0.0 : IsHeroJumping = #False : IsGameOver = #False : IsInvincibleMode = #False
  BaseVelocity = 1.0 : ObstaclesVelocity = 250.0
  Score = 0.0 : ScoreModuloDivisor = 100 : LoadSprite(#Bitmap_Font_Sprite, BasePath + "graphics" + #PS$ + "font.png")
  LoadGroundSprites(SpriteList())
EndProcedure
Procedure AddRandomObstaclePattern()
  NumWaves.a = Random(6, 2) : MaxObstacleGapMultiplier.f = 1.0 + (Random(100) / 100.0) : GapBetweenObstacleWaves.f = Random(ObstaclesVelocity * BaseVelocity * #Obstacle_Gap_Time_Multiplier * MaxObstacleGapMultiplier, (ObstaclesVelocity * BaseVelocity * #Obstacle_Gap_Time_Multiplier))
  Debug "ObstaclesVelocity * BaseVelocity:" + StrF(ObstaclesVelocity * BaseVelocity)
  For i.a = 1 To NumWaves
    QtdPatterns.a = CountString(ObstaclesPatterns, ";") + 1
    Pattern.s = StringField(ObstaclesPatterns, Random(QtdPatterns, 1), ";") : XOffSet.f = ScreenWidth()
    ShouldAddBird = Bool((Score >= 600) And (i = NumWaves) And (Random(100, 1) / 100.0 < 0.5));only adds birds at the last wave
    If ShouldAddBird : Pattern = Pattern + "B" : EndIf
    For j.a = 1  To Len(Pattern)
      Obstacle.a = Asc(Mid(Pattern, j, 1)) : AddElement(SpriteList())
      Select Obstacle
        Case 'D' : InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Dog_Sprite_Path, #Obstacle, 3, #True, #True, @UpdateObstacle(), 1)
        Case 'R' : InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, BusinessMan_Sprite_Path, #Obstacle, 1, #True, #True, @UpdateObstacle(), 1)
        Case 'F' : InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Fence_Sprite_Path, #Obstacle, 1, #True, #True, @UpdateObstacle(), 1)
        Case 'B' : InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity * 0.7, 0, Bird_Sprite_Path, #Obstacle, 5, #True, #True, @UpdateObstacle(), 1)
      EndSelect
      SpriteList()\x = XOffSet + i * GapBetweenObstacleWaves : XOffSet + (SpriteList()\Width * SpriteList()\ZoomLevel)
      If Obstacle <> 'B';its not a bird, should be added at the hero level at the ground
        SpriteList()\y = HeroBottom - (SpriteList()\Height * SpriteList()\ZoomLevel)
      Else;adding a bird
        SpriteList()\y = IIf(Bool(Random(100, 1) / 100.0 < 0.5), HeroBottom - (SpriteList()\Height * SpriteList()\ZoomLevel), HeroBottom - 5 - (*Hero\Height * *Hero\ZoomLevel) - (SpriteList()\Height * SpriteList()\ZoomLevel))
      EndIf
    Next
  Next
EndProcedure
Procedure.u CountObstacles()
  QtdObstacles.u = 0
  ForEach SpriteList()
    If SpriteList()\SpriteType & #Obstacle : QtdObstacles + 1 : EndIf
  Next
  ProcedureReturn QtdObstacles
EndProcedure
Procedure AddRandomClouds()
  
EndProcedure
Procedure UpdateGameLogic(Elapsed.f)
  Score + Elapsed * 10 : RoundedScore.i = Int(Round(Score, #PB_Round_Nearest))
  If CountObstacles() = 0
    AddRandomObstaclePattern()
  EndIf
  If RoundedScore <> 0 And RoundedScore % ScoreModuloDivisor = 0
    BaseVelocity * 1.1 : ScoreModuloDivisor + 100
  EndIf
EndProcedure
Procedure DrawBitmapText(x.f, y.f, Text.s, CharWidthPx.a = 16, CharHeightPx.a = 24);draw text is too slow on linux, let's try to use bitmap fonts
  ClipSprite(#Bitmap_Font_Sprite, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
  ZoomSprite(#Bitmap_Font_Sprite, #PB_Default, #PB_Default)
  For i.i = 1 To Len(Text);loop the string Text char by char
    AsciiValue.a = Asc(Mid(Text, i, 1))
    ClipSprite(#Bitmap_Font_Sprite, (AsciiValue - 32) % 16 * 8, (AsciiValue - 32) / 16 * 12, 8, 12)
    ZoomSprite(#Bitmap_Font_Sprite, CharWidthPx, CharHeightPx)
    DisplayTransparentSprite(#Bitmap_Font_Sprite, x + (i - 1) * CharWidthPx, y)
  Next
EndProcedure
Procedure DrawHUD()
  DrawBitmapText(ScreenWidth() / 2, 10, Str(Round(Score, #PB_Round_Nearest)));score
  If IsInvincibleMode : DrawBitmapText(5, ScreenHeight() - 30, "Invincible mode", 8, 12) : EndIf
  If PausedGame : DrawBitmapText(ScreenWidth() / 2 - 96 / 2, ScreenHeight() / 2 - 24 / 2, "PAUSED") : EndIf
EndProcedure
Procedure UpdateInput()
  If KeyboardReleased(#PB_Key_Return) And IsGameOver
    StartGame();when is game over the player can hit enter to restart the game
  EndIf
  IsInvincibleMode = Bool(KeyboardReleased(#PB_Key_I) XOr IsInvincibleMode);if we press I the collision of obstacles is not game ove anymore
  DrawCollisionBoxes = Bool(KeyboardReleased(#PB_Key_C) XOr DrawCollisionBoxes);press C to show/hide the collision boxes
  PausedGame = Bool(KeyboardReleased(#PB_Key_P) XOr PausedGame)
  If KeyboardReleased(#PB_Key_N);debug only, press N to advance the score and the obstacles' velocity
    NextScore.f = Round(Score / 100, #PB_Round_Up) * 100 : Score = NextScore
  EndIf
EndProcedure
If InitSprite() = 0 Or InitKeyboard() = 0
  MessageRequester("Error", "Sprite system or keyboard system can't be initialized", 0)
  End
EndIf
UsePNGImageDecoder() : SoundInitiated = InitSound()
If OpenWindow(0, 0, 0, 640, 480, "Late Run", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, 640, 480, 0, 0, 0)
    StartGame()
    Repeat
      StartTimeInMs = ElapsedMilliseconds()
      Repeat
        ; Always process all the events to flush the queue at every frame
        Event = WindowEvent()
        Select Event
          Case #PB_Event_CloseWindow
            ExitGame = #True
        EndSelect
      Until Event = 0 ; Quit the event loop only when no more events are available
      FlipBuffers()
      ClearScreen(RGB($81, $b1, $d9));#81b1d9
      ExamineKeyboard() : UpdateInput()
      ElapsedTimneInS = (ElapsedMilliseconds() - StartTimeInMs) / 1000.0
      ElapsedTimneInS = IIf(Bool(ElapsedTimneInS >= 0.05), 0.05, ElapsedTimneInS)
      ElapsedTimneInS = IIf(IsGameOver, 0.0, ElapsedTimneInS) : ElapsedTimneInS = IIf(PausedGame, 0.0, ElapsedTimneInS)
      UpdateGameLogic(ElapsedTimneInS) : UpdateSpriteList(SpriteList(), ElapsedTimneInS) : DisplaySpriteList(SpriteList(), ElapsedTimneInS)
      DrawHUD() : RemoveSpritesFromList(SpriteList())
    Until ExitGame
  EndIf
EndIf