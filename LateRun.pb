Procedure.f IIf(Test.b, ValTrue.f, ValFalse.f);classic vb function, helps us to save some lines in if else endif fragments
  If Test
    ProcedureReturn ValTrue
  EndIf
  ProcedureReturn ValFalse
EndProcedure
Prototype UpdateSpriteProc(SpriteAddress.i, Elapsed.f);our prototype procedure that each sprite can call to update itself
Structure TSprite
  x.f
  y.f
  XVelocity.f
  YVelocity.f
  SpriteNum.i
  NumFrames.a
  CurrentFrame.a
  Width.u;the original width of the sprite, before zooming
  Height.u;the original height of the sprite, before zooming
  AnimationTimer.f
  IsVisible.b
  ZoomLevel.f;the actual width or height it must be multiplied by the zoomlevel value
  Update.UpdateSpriteProc;the address of the update procedure that will update sprites positions and velocities, also handles inputs
EndStructure
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, StartTimeInMs.f, SoundInitiated.b
Global NewList *SpriteDisplayList.TSprite(), NewList *SpriteUpdateList.TSprite(), Hero.TSprite;
Global IsHeroOnGround.b = #True, HeroGroundY.f
#Animation_FPS = 12
#Hero_Sprite = 1
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpriteNum.i, SpritePath.s, NumFrames.a, IsVisible.b, UpdateProc.UpdateSpriteProc, ZoomLevel.f = 1)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = SpriteNum : *Sprite\IsVisible = IsVisible : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\Update = UpdateProc : *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 1 / #Animation_FPS
  LoadSprite(*Sprite\SpriteNum, SpritePath)
  *Sprite\NumFrames = NumFrames
  *Sprite\Width = SpriteWidth(*Sprite\SpriteNum) / NumFrames
  *Sprite\Height = SpriteHeight(*Sprite\SpriteNum);we assume all sprite sheets are only one row
EndProcedure
Procedure UpdateHero(HeroSpriteAddress.i, Elapsed.f);we should upadate the Hero sprite state here
  *HeroSprite.TSprite = HeroSpriteAddress
  If KeyboardPushed(#PB_Key_Space)
    *HeroSprite\YVelocity = -500.0 : IsHeroOnGround = #False
  EndIf
  *HeroSprite\y + *HeroSprite\YVelocity * Elapsed
  If *HeroSprite\y > HeroGroundY
    *HeroSprite\y = HeroGroundY : IsHeroOnGround = #True
  EndIf
  If Not IsHeroOnGround
    *HeroSprite\YVelocity + 1000 * Elapsed
  EndIf
EndProcedure
Procedure UpdateSpriteList(List *SpriteList.TSprite(), Elapsed.f)
  ForEach *SpriteList()
    *SpriteList()\Update(*SpriteList(), Elapsed)
  Next
EndProcedure
Procedure DisplaySpriteList(List *SpriteList.TSprite(), Elapsed.f)
  ForEach *SpriteList()
    ClipSprite(*SpriteList()\SpriteNum, *SpriteList()\CurrentFrame * *SpriteList()\Width, 0, *SpriteList()\Width, *SpriteList()\Height);here we clip the current frame that we want to display
    ZoomSprite(*SpriteList()\SpriteNum, *SpriteList()\Width * *SpriteList()\ZoomLevel, *SpriteList()\Height * *SpriteList()\ZoomLevel);the zoom must be applied after the clipping(https://www.purebasic.fr/english/viewtopic.php?p=421807#p421807)
    If *SpriteList()\AnimationTimer <= 0.0;time to change frames and reset the animation timer
      *SpriteList()\CurrentFrame = IIf(Bool(*SpriteList()\CurrentFrame + 1 > *SpriteList()\NumFrames - 1), 0, *SpriteList()\CurrentFrame + 1)
      *SpriteList()\AnimationTimer = 1 / #Animation_FPS
    EndIf
    *SpriteList()\AnimationTimer - Elapsed;run the timer to get to the next frame
    DisplaySprite(*SpriteList()\SpriteNum, *SpriteList()\x, *SpriteList()\y)
  Next
EndProcedure
Procedure AddSpriteToList(*Sprite.TSprite, List *SpriteList.TSprite());general procedure to add TSprites to lists
  AddElement(*SpriteList()) : *SpriteList() = *Sprite
EndProcedure
Procedure StartGame();we start a new game here
  InitializeSprite(Hero, 0, 0, 0, 0, #Hero_Sprite, BasePath + "graphics" + #PS$ + "hero.png", 4, #True, @UpdateHero(), 4)
  Hero\x = Hero\Width * Hero\ZoomLevel : HeroGroundY = ScreenHeight() / 2 * 1.25 : Hero\y = HeroGroundY;starting position for the hero
  IsHeroOnGround = #True
  AddSpriteToList(@Hero, *SpriteDisplayList()) : AddSpriteToList(@Hero, *SpriteUpdateList());add to the SpriteDisplayList(to show it on the screen) and SpriteUpdateList (to update it)
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
      UpdateSpriteList(*SpriteUpdateList(), ElapsedTimneInS)
      DisplaySpriteList(*SpriteDisplayList(), ElapsedTimneInS)
    Until ExitGame
  EndIf
EndIf