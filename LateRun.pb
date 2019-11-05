Procedure.f IIf(Test.b, ValTrue.f, ValFalse.f);classic vb function, helps us to save some lines in if else endif fragments
  If Test : ProcedureReturn ValTrue : EndIf
  ProcedureReturn ValFalse
EndProcedure
Prototype UpdateSpriteProc(SpriteAddress.i, Elapsed.f);our prototype procedure that each sprite can call to update itself
Structure TSprite
  x.f : y.f;position
  XVelocity.f : YVelocity.f;velociy in each axis
  SpriteNum.i
  NumFrames.a : CurrentFrame.a
  Width.u;the original width of the sprite, before zooming
  Height.u;the original height of the sprite, before zooming
  AnimationTimer.f
  IsAlive.b
  DrawOrder.u;the sprites with lower draw order must be drawn first
  ZoomLevel.f;the actual width or height it must be multiplied by the zoomlevel value
  Update.UpdateSpriteProc;the address of the update procedure that will update sprites positions and velocities, also handles inputs
EndStructure
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, StartTimeInMs.q, SoundInitiated.b
Global NewList SpriteList.TSprite(), *Hero.TSprite;
Global IsHeroOnGround.b = #True, HeroGroundY.f, HeroJumpTimer.f, IsHeroJumping.b = #False
Global BaseVelocity.f, ObstaclesVelocity.f, ObstaclesTimer.f, CurrentObstaclesTimer.f, ObstaclesChance.f
Global Score.f
#Animation_FPS = 12 : #Bitmap_Font_Sprite = 0
Global Hero_Sprite_Path.s = BasePath + "graphics" + #PS$ + "hero.png"
Global Dog_Sprite_Path.s = BasePath + "graphics" + #PS$ + "dog-48x27-transparent.png"
Global Boulder_Sprite_Path.s = BasePath + "graphics" + #PS$ + "boulder-48x48.png"
Global Fence_Sprite_Path.s = BasePath + "graphics" + #PS$ + "fence-16x24.png"
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpritePath.s, NumFrames.a, IsAlive.b, UpdateProc.UpdateSpriteProc, ZoomLevel.f = 1)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = LoadSprite(#PB_Any, SpritePath) : *Sprite\IsAlive = IsAlive : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\Update = UpdateProc : *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 1 / #Animation_FPS
  *Sprite\NumFrames = NumFrames : *Sprite\Width = SpriteWidth(*Sprite\SpriteNum) / NumFrames
  *Sprite\Height = SpriteHeight(*Sprite\SpriteNum);we assume all sprite sheets are only one row
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
    Debug "Jump time:" + Str(ElapsedMilliseconds() - StartJump) : StartJump = 0
    Debug "Lowest Y:" + StrF(LowestHeroY) : LowestHeroY = 1000
  EndIf
  If Not IsHeroOnGround;kind like gravity here
    *HeroSprite\YVelocity + 2200 * Elapsed
  EndIf
EndProcedure
Procedure UpdateObstacle(ObstacleAddress.i, Elapsed.f);obstacles only goes to the left at the given velocity
  *Obstacle.TSprite = ObstacleAddress : *Obstacle\x + *Obstacle\XVelocity * Elapsed
  *Obstacle\IsAlive = IIf(Bool(*Obstacle\x < -(*Obstacle\Width * *Obstacle\ZoomLevel)), #False, #True)
EndProcedure
Procedure UpdateSpriteList(List SpriteList.TSprite(), Elapsed.f)
  ForEach SpriteList() : SpriteList()\Update(@SpriteList(), Elapsed) : Next
EndProcedure
Procedure DisplaySpriteList(List SpriteList.TSprite(), Elapsed.f)
  ForEach SpriteList()
    ClipSprite(SpriteList()\SpriteNum, SpriteList()\CurrentFrame * SpriteList()\Width, 0, SpriteList()\Width, SpriteList()\Height);here we clip the current frame that we want to display
    ZoomSprite(SpriteList()\SpriteNum, SpriteList()\Width * SpriteList()\ZoomLevel, SpriteList()\Height * SpriteList()\ZoomLevel);the zoom must be applied after the clipping(https://www.purebasic.fr/english/viewtopic.php?p=421807#p421807)
    If SpriteList()\AnimationTimer <= 0.0;time to change frames and reset the animation timer
      SpriteList()\CurrentFrame = IIf(Bool(SpriteList()\CurrentFrame + 1 > SpriteList()\NumFrames - 1), 0, SpriteList()\CurrentFrame + 1)
      SpriteList()\AnimationTimer = 1 / #Animation_FPS
    EndIf
    SpriteList()\AnimationTimer - Elapsed;run the timer to get to the next frame
    DisplayTransparentSprite(SpriteList()\SpriteNum, SpriteList()\x, SpriteList()\y)
  Next
EndProcedure
Procedure RemoveSpritesFromList(List SpriteList.TSprite())
  ForEach SpriteList()
    If Not SpriteList()\IsAlive
      FreeSprite(SpriteList()\SpriteNum)
      DeleteElement(SpriteList(), #True)
    EndIf
  Next
EndProcedure
Procedure StartGame();we start a new game here
  AddElement(SpriteList()) : *Hero = @SpriteList()
  InitializeSprite(*Hero, 0, 0, 0, 0, Hero_Sprite_Path, 4, #True, @UpdateHero(), 4)
  *Hero\x = *Hero\Width * *Hero\ZoomLevel : HeroGroundY = ScreenHeight() / 2 * 1.25 : *Hero\y = HeroGroundY;starting position for the hero
  IsHeroOnGround = #True : HeroJumpTimer = 0.0 : IsHeroJumping = #False
  BaseVelocity = 1.0 : ObstaclesVelocity = 250.0 : ObstaclesTimer = 0.0 : CurrentObstaclesTimer = 1.5 : ObstaclesChance.f = 0.5
  Score = 0.0 : LoadSprite(#Bitmap_Font_Sprite, BasePath + "graphics" + #PS$ + "font.png")
EndProcedure
Procedure UpdateGameLogic(Elapsed.f)
  Score + Elapsed : ObstaclesTimer + Elapsed
  If ObstaclesTimer >= CurrentObstaclesTimer : ObstaclesTimer = 0.0
    If Random(100, 0) / 100.0 < ObstaclesChance
      AddElement(SpriteList()) : RandomValue.f = Random(100, 0) / 100.0
      If RandomValue < 0.33
        InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Boulder_Sprite_Path, 1, #True, @UpdateObstacle(), 1)
        SpriteList()\x = ScreenWidth() - (SpriteList()\Width * SpriteList()\ZoomLevel) : SpriteList()\y = HeroGroundY
      ElseIf RandomValue < 0.66
        InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Dog_Sprite_Path, 3, #True, @UpdateObstacle(), 1)
        SpriteList()\x = ScreenWidth() - (SpriteList()\Width * SpriteList()\ZoomLevel) : SpriteList()\y = HeroGroundY + (*Hero\Height * *Hero\ZoomLevel) - (SpriteList()\Height * SpriteList()\ZoomLevel)
      Else
        InitializeSprite(@SpriteList(), 0, 0, -ObstaclesVelocity * BaseVelocity, 0, Fence_Sprite_Path, 1, #True, @UpdateObstacle(), 1)
        SpriteList()\x = ScreenWidth() - (SpriteList()\Width * SpriteList()\ZoomLevel) : SpriteList()\y = HeroGroundY + (*Hero\Height * *Hero\ZoomLevel) - (SpriteList()\Height * SpriteList()\ZoomLevel)
      EndIf
    EndIf
  EndIf
EndProcedure
Procedure DrawBitmapText(x.f, y.f, Text.s);draw text is too slow on linux, let's try to use bitmap fonts
  For i.i = 1 To Len(Text);loop the string Text char by char
    AsciiValue.a = Asc(Mid(Text, i, 1))
    ClipSprite(#Bitmap_Font_Sprite, (AsciiValue - 32) % 16 * 8, (AsciiValue - 32) / 16 * 12, 8, 12)
    ZoomSprite(#Bitmap_Font_Sprite, 16, 24)
    DisplayTransparentSprite(#Bitmap_Font_Sprite, x + (i - 1) * 16, y)
  Next i
EndProcedure
Procedure DrawHUD()
  DrawBitmapText(ScreenWidth() / 2, 10, Str(Round(Score * 10, #PB_Round_Nearest)));score
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
      ClearScreen(RGB(0,0,0))
      ExamineKeyboard()
      ElapsedTimneInS = (ElapsedMilliseconds() - StartTimeInMs) / 1000.0
      ElapsedTimneInS = IIf(Bool(ElapsedTimneInS >= 0.05), 0.05, ElapsedTimneInS)
      UpdateGameLogic(ElapsedTimneInS) : UpdateSpriteList(SpriteList(), ElapsedTimneInS) : DisplaySpriteList(SpriteList(), ElapsedTimneInS)
      DrawHUD()
      RemoveSpritesFromList(SpriteList())
    Until ExitGame
  EndIf
EndIf