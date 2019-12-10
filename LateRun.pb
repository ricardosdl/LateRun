Procedure.f IIf(Test.b, ValTrue.f, ValFalse.f);classic vb function, helps us to save some lines in if else endif fragments
  If Test : ProcedureReturn ValTrue : EndIf : ProcedureReturn ValFalse
EndProcedure
Structure TRect
  x.f : y.f : w.f : h.f
EndStructure
Prototype UpdateSpriteProc(SpriteAddress.i, Elapsed.f);our prototype procedure that each sprite can call to update itself
EnumerationBinary SpriteTypes : #Hero : #Obstacle : #Ground : #Cloud : EndEnumeration;we use to indentigy different type of sprites
Enumeration Sounds : #Jump : #Collision : #Score : EndEnumeration
Structure TSprite
  x.f : y.f;position
  XVelocity.f : YVelocity.f;velociy in each axis
  SpriteNum.i : SpriteType.a;spritenum is the id returned by loadsprite and spritetype is one of the enumerations above
  NumFrames.a : CurrentFrame.a
  Width.u : Height.u;the original width and height of the sprite, before zooming
  AnimationTimer.f : IsAnimated.a
  IsAlive.b;if a sprite is not alive it will be removed
  DrawOrder.u;the sprites with lower draw order must be drawn first
  ZoomLevel.f;the actual width or height it must be multiplied by the zoomlevel value
  Update.UpdateSpriteProc;the address of the update procedure that will update sprites positions and velocities, also handles inputs
  CollisionRect.TRect : SpriteNumNight.i;the collision rect we use for the player and the sprite that is shown when it's night
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
Global BaseVelocity.f, ObstaclesVelocity.f, CloudTimer.f, MaxCloudTimer.f
Global Dim SkyColors.i(4) : SkyColors(0) = RGB($81, $b1, $d9) : SkyColors(1) = RGB($ff, $99, $33) : SkyColors(2) = RGB($ff, $66, $33)
SkyColors(3) = RGB($69, $69, $69) : SkyColors(4) = RGB(0, 0, 0)
Global SkyColor.i, SkyTimer.f, SkyColorIndex.i = 0, SkyTransition.a = #False, SkyTransitionTimer.f, SkyColorIndexDirection.b
Global Score.f, RoundedScore.i, HighestScore.i = 0, ScoreModuloDivisor.l, DrawCollisionBoxes.a = #False, PausedGame.a = #False
#Max_Score_Flash_Timer = 1.5 : #Max_Score_Sub_Flash_Timer = 0.075 : #Max_Score_Velocity = 1500
#Animation_FPS = 12 : #Bitmap_Font_Sprite = 0 : #Obstacle_Gap_Time_Multiplier = 0.8 : #Cloud_Vel_Multiplier = 0.25
Global Hero_Sprite_Path.s = BasePath + "graphics" + #PS$ + "hero.png", Hero_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "hero-greyed.png"
Global Dog_Sprite_Path.s = BasePath + "graphics" + #PS$ + "dog-48x27-transparent.png", Dog_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "dog-48x27-transparent-greyed.png";Represented by D below;Represented by D below
Global BusinessMan_Sprite_Path.s = BasePath + "graphics" + #PS$ + "businessman-24x48.png", BusinessMan_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "businessman-24x48-greyed.png";R below;R below
Global Fence_Sprite_Path.s = BasePath + "graphics" + #PS$ + "fence-16x24.png", Fence_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "fence-16x24-greyed.png";F below;F below
Global Bird_Sprite_Path.s = BasePath + "graphics" + #PS$ + "bird-32x32.png", Bird_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "bird-32x32-greyed.png"  ;B below
Global Ground_Sprite_Path.s = BasePath + "graphics" + #PS$ + "ground-672x160.png", Ground_Sprite_Path_Night.s = BasePath + "graphics" + #PS$ + "ground-672x160-greyed.png"
Global Clouds_Sprite_Path.s = BasePath + "graphics" + #PS$ + "clouds-120x40.png"
Global ObstaclesPatterns.s = "D;DD;R;RR;RRR;RRF;F;FF;FFF;FFR;FR;RFF;RF;FRF";each letter represents an obstacle, two letters together means the obstacles are side by side
Global ScoreFlashTimer.f, ScoreSubFlashTimer.f, ShowScore.a
Procedure SetCollisionRect(*Sprite.TSprite, Offset.a = 8)
  *Sprite\CollisionRect\w = (*Sprite\Width * *Sprite\ZoomLevel) - Offset : *Sprite\CollisionRect\h = (*Sprite\Height * *Sprite\ZoomLevel) - Offset
  *Sprite\CollisionRect\x = (*Sprite\x + (*Sprite\Width * *Sprite\ZoomLevel) / 2) - *Sprite\CollisionRect\w / 2
  *Sprite\CollisionRect\y = (*Sprite\y + (*Sprite\Height * *Sprite\ZoomLevel) / 2) - *Sprite\CollisionRect\h / 2
EndProcedure
Procedure PlaySoundEffect(Sound.a)
  If SoundInitiated; And Not SoundMuted
    PlaySound(Sound)
  EndIf
EndProcedure
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpritePath.s, SpriteType.a, NumFrames.a, IsAnimated.a, IsAlive.b, UpdateProc.UpdateSpriteProc, SpriteNumNight.i, ZoomLevel.f = 1, DrawOrder.u = 0)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = LoadSprite(#PB_Any, SpritePath) : *Sprite\SpriteType = SpriteType : *Sprite\IsAlive = IsAlive : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\Update = UpdateProc : *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 1 / #Animation_FPS : *Sprite\DrawOrder = DrawOrder
  *Sprite\NumFrames = NumFrames : *Sprite\IsAnimated = IsAnimated : *Sprite\Width = SpriteWidth(*Sprite\SpriteNum) / NumFrames
  *Sprite\Height = SpriteHeight(*Sprite\SpriteNum);we assume all sprite sheets are only one row
  *Sprite\SpriteNumNight = SpriteNumNight : SetCollisionRect(*Sprite)
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
    PlaySoundEffect(#Jump)
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
  SetCollisionRect(*HeroSprite);update the collision rectangle based on the new player hero position
  ForEach SpriteList()
    If SpriteList()\SpriteType & #Obstacle;we only check collisions with obstacles
      If (Not IsGameOver) And (Not IsInvincibleMode) And AABBCollision(@*HeroSprite\CollisionRect, @SpriteList()\CollisionRect)
        IsGameOver = Bool(Not IsInvincibleMode) : PlaySoundEffect(#Collision)
        HighestScore = IIf(Bool(RoundedScore > HighestScore), RoundedScore, HighestScore)
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
  *Ground2\x + (-ObstaclesVelocity * BaseVelocity) * Elapsed;bump both gorunds to the left and then adjust their position accordingly
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
    If SpriteList()\Update = #Null : Continue : EndIf;if there is no update procedure we go to the next
    *CurrentSprite.TSprite = @SpriteList();save the current sprite being updated
    ResetList(SpriteList());reset the list so that the update functions can loop the spritelist from the beginning
    *CurrentSprite\Update(*CurrentSprite, Elapsed);call the update function on the current sprite
    ChangeCurrentElement(SpriteList(), *CurrentSprite);reset the current sprite so that we can go on to the next one
  Next
EndProcedure
Procedure DisplaySpriteList(List SpriteList.TSprite(), Elapsed.f)
  SortStructuredList(SpriteList(), #PB_Sort_Ascending, OffsetOf(TSprite\DrawOrder), TypeOf(TSprite\DrawOrder))
  ForEach SpriteList() : IsNight.a = Bool(SkyColorIndex = 4);if it is night we draw the spritenumnight instead
    SpriteToDisplay.i = IIf(Bool(Not IsNight Or SpriteList()\SpriteNumNight = -1), SpriteList()\SpriteNum, SpriteList()\SpriteNumNight)
    ClipSprite(SpriteToDisplay, SpriteList()\CurrentFrame * SpriteList()\Width, 0, SpriteList()\Width, SpriteList()\Height);here we clip the current frame that we want to display
    ZoomSprite(SpriteToDisplay, SpriteList()\Width * SpriteList()\ZoomLevel, SpriteList()\Height * SpriteList()\ZoomLevel) ;the zoom must be applied after the clipping(https://www.purebasic.fr/english/viewtopic.php?p=421807#p421807)
    If SpriteList()\IsAnimated
      If SpriteList()\AnimationTimer <= 0.0;time to change frames and reset the animation timer
        SpriteList()\CurrentFrame = IIf(Bool(SpriteList()\CurrentFrame + 1 > SpriteList()\NumFrames - 1), 0, SpriteList()\CurrentFrame + 1)
        SpriteList()\AnimationTimer = 1 / #Animation_FPS
      EndIf
      SpriteList()\AnimationTimer - Elapsed;run the timer to get to the next frame
    EndIf
    DisplayTransparentSprite(SpriteToDisplay, SpriteList()\x, SpriteList()\y)
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
      FreeSprite(SpriteList()\SpriteNum) : If SpriteList()\SpriteNumNight <> -1 : FreeSprite(SpriteList()\SpriteNumNight) : EndIf
      DeleteElement(SpriteList())
    EndIf
  Next
EndProcedure
Procedure LoadGroundSprites(List SpriteList.TSprite())
  AddElement(SpriteList())
  GroundNight.i = LoadSprite(#PB_Any, Ground_Sprite_Path_Night)
  InitializeSprite(@SpriteList(), 0, 0, 0, 0, Ground_Sprite_Path, #Ground, 1, #False, #True, @UpdateGround(), GroundNight, 1, 1)
  SpriteList()\x = ScreenWidth() / 2 - (SpriteList()\Width * SpriteList()\ZoomLevel / 2)
  SpriteList()\y = HeroBottom : *Ground1 = @SpriteList()
  AddElement(SpriteList())
  GroundNight = LoadSprite(#PB_Any, Ground_Sprite_Path_Night)
  InitializeSprite(@SpriteList(), 0, 0, 0, 0, Ground_Sprite_Path, #Ground, 1, #False, #True, @UpdateGround(), GroundNight, 1, 1)
  SpriteList()\x = *Ground1\x + (*Ground1\Width * *Ground1\ZoomLevel)
  SpriteList()\y = HeroBottom : *Ground2 = @SpriteList()
EndProcedure
Procedure AddRandomClouds(NumCloudsToAdd.a, AddOnScreen.a)
  For i.a = 1 To NumCloudsToAdd
    AddElement(SpriteList())
    CloudX.f = IIf(Bool(AddOnScreen), Random(ScreenWidth(), 0), Random(2 * ScreenWidth(), ScreenWidth()))
    InitializeSprite(@SpriteList(), CloudX, Random(HeroBottom, 0), #Cloud_Vel_Multiplier * -ObstaclesVelocity * BaseVelocity, 0, Clouds_Sprite_Path, #Cloud, 3, #False, #True, @UpdateObstacle(), -1, 3, 0)
    SpriteList()\CurrentFrame = Random(2, 0)
  Next
EndProcedure
Procedure StartGame();we start a new game here
  ForEach SpriteList() : SpriteList()\IsAlive = #False :Next;mark all sprites as not alive, so we can remove them
  RemoveSpritesFromList(SpriteList())
  AddElement(SpriteList()) : *Hero = @SpriteList()
  HeroNight.i = LoadSprite(#PB_Any, Hero_Sprite_Path_Night)
  InitializeSprite(*Hero, 0, 0, 0, 0, Hero_Sprite_Path, #Hero, 4, #True, #True, @UpdateHero(), HeroNight, 4, 2)
  *Hero\x = *Hero\Width * *Hero\ZoomLevel : HeroGroundY = ScreenHeight() / 2 * 1.25 : *Hero\y = HeroGroundY;starting position for the hero
  HeroDistanceFromScreenEdge = ScreenWidth() - (*Hero\CollisionRect\x + *Hero\CollisionRect\w) : HeroBottom = HeroGroundY + (*Hero\Height * *Hero\ZoomLevel)
  IsHeroOnGround = #True : HeroJumpTimer = 0.0 : IsHeroJumping = #False : IsGameOver = #False : IsInvincibleMode = #False
  BaseVelocity = 1.0 : ObstaclesVelocity = 250.0
  SkyColorIndex = 0 : SkyColor = SkyColors(SkyColorIndex) : SkyTimer = 0.0 : SkyTransition = #False : SkyTransitionTimer = 0.0 : SkyColorIndexDirection = 1
  Score = 0.0 : RoundedScore = 0 : ScoreModuloDivisor = 100 : LoadSprite(#Bitmap_Font_Sprite, BasePath + "graphics" + #PS$ + "font.png")
  LoadGroundSprites(SpriteList()) : AddRandomClouds(Random(5, 3), #True) : CloudTimer = 0.0 : MaxCloudTimer = ScreenWidth() / (#Cloud_Vel_Multiplier * ObstaclesVelocity * BaseVelocity)
  ScoreFlashTimer = 0.0 : ScoreSubFlashTimer = 0.0 : ShowScore.a = #True
EndProcedure
Procedure AddRandomObstaclePattern()
  MaxScoreVelocityMultiplier.f = IIf(Bool(RoundedScore < #Max_Score_Velocity), #Obstacle_Gap_Time_Multiplier, #Obstacle_Gap_Time_Multiplier * 0.9)
  MaxObstacleGapMultiplier.f = 1.0
  If RoundedScore < #Max_Score_Velocity
    MaxObstacleGapMultiplier + Random(100) / 100.0;MaxObstacleGapMultiplier ranges from 1.0 to 2.0
  ElseIf RoundedScore < (2 * #Max_Score_Velocity)
    MaxObstacleGapMultiplier + Random(50) / 100.0;MaxObstacleGapMultiplier ranges from 1.0 to 1.5
  EndIf
  BaseObstaclesVelocity.f = ObstaclesVelocity * BaseVelocity * MaxScoreVelocityMultiplier
  GapBetweenObstacleWaves.f = Random(BaseObstaclesVelocity * MaxObstacleGapMultiplier, BaseObstaclesVelocity)
  NumWaves.a = Random(6, 2)
  ;Debug "ObstaclesVelocity * BaseVelocity:" + StrF(ObstaclesVelocity * BaseVelocity)
  For i.a = 1 To NumWaves
    QtdPatterns.a = CountString(ObstaclesPatterns, ";") + 1
    Pattern.s = StringField(ObstaclesPatterns, Random(QtdPatterns, 1), ";") : XOffSet.f = IIf(Bool(MaxScoreVelocityMultiplier * ObstaclesVelocity * BaseVelocity < HeroDistanceFromScreenEdge - 16), HeroDistanceFromScreenEdge - 16, MaxScoreVelocityMultiplier * ObstaclesVelocity * BaseVelocity)
    ShouldAddBird = Bool((Score >= 600) And (i = NumWaves) And (Random(100, 1) / 100.0 < 0.4));only adds birds at the last wave
    If ShouldAddBird : Pattern = Pattern + "B" : EndIf
    For j.a = 1  To Len(Pattern)
      Obstacle.a = Asc(Mid(Pattern, j, 1)) : AddElement(SpriteList())
      Select Obstacle
        Case 'D'
          DogNight.i = LoadSprite(#PB_Any, Dog_Sprite_Path_Night)
          InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Dog_Sprite_Path, #Obstacle, 3, #True, #True, @UpdateObstacle(), DogNight, 1, 3)
        Case 'R'
          BusinessManNight.i = LoadSprite(#PB_Any, BusinessMan_Sprite_Path_Night)
          InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, BusinessMan_Sprite_Path, #Obstacle, 1, #True, #True, @UpdateObstacle(), BusinessManNight, 1, 3)
        Case 'F'
          FenceNight.i = LoadSprite(#PB_Any, Fence_Sprite_Path_Night)
          InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Fence_Sprite_Path, #Obstacle, 1, #True, #True, @UpdateObstacle(), FenceNight, 1, 3)
        Case 'B'
          BirdNight.i = LoadSprite(#PB_Any, Bird_Sprite_Path_Night) : BirdVelocityMultiplier.f = IIf(Bool(RoundedScore < #Max_Score_Velocity), 0.9, Random(100, 90) / 100.0)
          InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity * BirdVelocityMultiplier, 0, Bird_Sprite_Path, #Obstacle, 5, #True, #True, @UpdateObstacle(), BirdNight, 1, 3)
      EndSelect
      IIndex = i + IIf(Bool(Obstacle = 'B'), 1, 0);hack to make the bird start a "new" wave after the before last obstacle
      SpriteList()\x = XOffSet + (IIndex - 1) * GapBetweenObstacleWaves : XOffSet + (SpriteList()\Width * SpriteList()\ZoomLevel)
      If Obstacle <> 'B';its not a bird, should be added at the hero level at the ground
        SpriteList()\y = HeroBottom - (SpriteList()\Height * SpriteList()\ZoomLevel)
      Else;adding a bird
        SpriteList()\y = IIf(Bool(Random(100, 1) / 100.0 < 0.5), HeroBottom - (SpriteList()\Height * SpriteList()\ZoomLevel), HeroBottom - 5 - (*Hero\Height * *Hero\ZoomLevel) - (SpriteList()\Height * SpriteList()\ZoomLevel))
      EndIf
    Next
  Next
EndProcedure
Procedure.u CountSprites(SpriteType.a)
  Qtd.u = 0
  ForEach SpriteList()
    If SpriteList()\SpriteType & SpriteType : Qtd + 1 : EndIf
  Next
  ProcedureReturn Qtd
EndProcedure
Procedure UpdateGameLogic(Elapsed.f)
  Score + Elapsed * 10 : RoundedScore = Int(Round(Score, #PB_Round_Nearest))
  If CountSprites(#Obstacle) = 0
    AddRandomObstaclePattern()
  EndIf
  If RoundedScore <> 0 And RoundedScore % ScoreModuloDivisor = 0
    BaseVelocity = IIf(Bool(RoundedScore <= #Max_Score_Velocity), BaseVelocity * 1.1, BaseVelocity);after #Max_Score_Velocity points we don't increase the base velocity anymore
    ScoreModuloDivisor + 100 : PlaySoundEffect(#Score) : ScoreFlashTimer = #Max_Score_Flash_Timer
  EndIf
  CloudTimer + Elapsed
  If CloudTimer >= MaxCloudTimer
    CloudTimer = 0.0 : AddRandomClouds(Random(8, 4), #False) : MaxCloudTimer = ScreenWidth() / (#Cloud_Vel_Multiplier * ObstaclesVelocity * BaseVelocity)
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
Procedure DrawHUD(Elapsed.f)
  If ScoreFlashTimer > 0
    ScoreFlashTimer - Elapsed
    ScoreSubFlashTimer + Elapsed
    If ScoreSubFlashTimer >= #Max_Score_Sub_Flash_Timer
      ScoreSubFlashTimer = 0.0 : ShowScore = Bool(Not ShowScore)
    EndIf
  Else
    ShowScore = #True : ScoreFlashTimer = 0.0
  EndIf
  If ShowScore : DrawBitmapText(ScreenWidth() / 2, 10, Str(Round(Score, #PB_Round_Nearest))) : EndIf
  If IsInvincibleMode : DrawBitmapText(5, ScreenHeight() - 30, "Invincible mode", 8, 12) : EndIf
  If PausedGame : DrawBitmapText(ScreenWidth() / 2 - 96 / 2, ScreenHeight() / 2 - 24 / 2, "PAUSED") : EndIf
  DrawBitmapText(0 + 15, 10, "Highest:" + Str(HighestScore))
  If IsGameOver
    DrawBitmapText(ScreenWidth() / 2 - (Len("Game Over") * 16 / 2), ScreenHeight() / 2 - 30, "Game Over")
    DrawBitmapText(ScreenWidth() / 2 - (Len("(Enter To restart)") * 16 / 2), ScreenHeight() / 2, "(Enter To restart)")
  EndIf
EndProcedure
Procedure UpdateInput()
  If KeyboardReleased(#PB_Key_Return) And IsGameOver
    StartGame();when is game over the player can hit enter to restart the game
  EndIf
  IsInvincibleMode = Bool(KeyboardReleased(#PB_Key_I) XOr IsInvincibleMode);if we press I the collision of obstacles is not game ove anymore
  DrawCollisionBoxes = Bool(KeyboardReleased(#PB_Key_C) XOr DrawCollisionBoxes);press C to show/hide the collision boxes
  PausedGame = Bool((KeyboardReleased(#PB_Key_P) XOr PausedGame) And (Not IsGameOver))
  If KeyboardReleased(#PB_Key_N);debug only, press N to advance the score and the obstacles' velocity
    NextScore.f = Round(Score / 100, #PB_Round_Up) * 100 : Score = NextScore
  EndIf
EndProcedure
Procedure ShowSky(Elapsed.f)
  SkyColor = SkyColors(SkyColorIndex) : ClearScreen(SkyColor) : SkyTimer + Elapsed
  If SkyTimer >= 40;each 40 seconds we transition to day or night and back
    SkyTransition = #True : SkyTransitionTimer = 0.0 : SkyTimer = 0
  EndIf
  If SkyTransition;here we perform the sky transition changing the skycolorindex to display different colors
    SkyTransitionTimer + Elapsed
    If SkyTransitionTimer > 10 /  ArraySize(SkyColors());10 seconds divided by the number of sky color transitions
      SkyColorIndex = SkyColorIndex + SkyColorIndexDirection : SkyTransitionTimer = 0.0
      SkyTransition = IIf(Bool(SkyColorIndex = 0 Or SkyColorIndex = 4), #False, #True);stops the transition when we reach the day or night sky index
      If Not SkyTransition : SkyColorIndexDirection * -1 : EndIf;change the direction, from day to night or from night to day
    EndIf
  EndIf
EndProcedure
Procedure LoadSounds()
  If SoundInitiated
    LoadSound(#Jump, BasePath + "sounds" + #PS$ + "jump.wav")
    LoadSound(#Collision, BasePath + "sounds" + #PS$ + "collision.wav")
    LoadSound(#Score, BasePath + "sounds" + #PS$ + "score.wav")
;     If LoadSound(#Ball_Touch, BasePath + "ball_touch.wav")
;       PlaySoundEffect(#Ball_Touch);on windows the first call to playsound is taking over a second to complete, so we call it here to get over it
;     EndIf
  EndIf
EndProcedure
If InitSprite() = 0 Or InitKeyboard() = 0
  MessageRequester("Error", "Sprite system or keyboard system can't be initialized", 0)
  End
EndIf
UsePNGImageDecoder() : SoundInitiated = InitSound()
If OpenWindow(0, 0, 0, 640, 480, "Late Run", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, 640, 480, 0, 0, 0)
    LoadSounds() : StartGame()
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
      FlipBuffers() : ShowSky(ElapsedTimneInS)
      ExamineKeyboard() : UpdateInput()
      ElapsedTimneInS = (ElapsedMilliseconds() - StartTimeInMs) / 1000.0
      ElapsedTimneInS = IIf(Bool(ElapsedTimneInS >= 0.05), 0.05, ElapsedTimneInS)
      ElapsedTimneInS = IIf(IsGameOver, 0.0, ElapsedTimneInS) : ElapsedTimneInS = IIf(PausedGame, 0.0, ElapsedTimneInS)
      UpdateGameLogic(ElapsedTimneInS) : UpdateSpriteList(SpriteList(), ElapsedTimneInS) : DisplaySpriteList(SpriteList(), ElapsedTimneInS)
      DrawHUD(ElapsedTimneInS) : RemoveSpritesFromList(SpriteList())
    Until ExitGame
  EndIf
EndIf