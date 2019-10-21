Procedure.f IIf(Test.b, ValTrue.f, ValFalse.f)
  If Test
    ProcedureReturn ValTrue
  EndIf
  ProcedureReturn ValFalse
EndProcedure

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
  ZoomLevel.f
EndStructure

Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, StartTimeInMs.f, SoundInitiated.b
Global NewList *SpriteDisplayList.TSprite(), NewList *SpriteUpdateList.TSprite(), Hero.TSprite
#Animation_FPS = 12
#Hero_Sprite = 1
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpriteNum.i, SpritePath.s, NumFrames.a, IsVisible.b, ZoomLevel.f = 1)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = SpriteNum : *Sprite\IsVisible = IsVisible : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 1 / #Animation_FPS
  LoadSprite(*Sprite\SpriteNum, SpritePath)
  *Sprite\NumFrames = NumFrames
  *Sprite\Width = SpriteWidth(*Sprite\SpriteNum) / NumFrames
  *Sprite\Height = SpriteHeight(*Sprite\SpriteNum);we assume all sprite sheets are only one row
EndProcedure
Procedure UpdateSpriteList(List *SpriteList.TSprite(), Elapsed.f)
  ForEach *SpriteList()
;     If SpriteList()\IsAnimated
;     Else
;       ;DisplaySprite(SpriteList()\SpriteNum, SpriteList()\x, SpriteList()\y, )
;     EndIf
    
  Next
  
EndProcedure
Procedure DisplaySpriteList(List *SpriteList.TSprite(), Elapsed.f)
  ForEach *SpriteList()
    ClipSprite(*SpriteList()\SpriteNum, *SpriteList()\CurrentFrame * *SpriteList()\Width, 0, *SpriteList()\Width, *SpriteList()\Height)
    ZoomSprite(*SpriteList()\SpriteNum, *SpriteList()\Width * *SpriteList()\ZoomLevel, *SpriteList()\Height * *SpriteList()\ZoomLevel)
    If *SpriteList()\AnimationTimer <= 0
      *SpriteList()\CurrentFrame = IIf(Bool(*SpriteList()\CurrentFrame + 1 > *SpriteList()\NumFrames - 1), 0, *SpriteList()\CurrentFrame + 1)
      *SpriteList()\AnimationTimer = 1 / #Animation_FPS
    EndIf
    *SpriteList()\AnimationTimer - Elapsed
    DisplaySprite(*SpriteList()\SpriteNum, *SpriteList()\x, *SpriteList()\y)
  Next
EndProcedure
Procedure AddSpriteToList(*Sprite.TSprite, List *SpriteList.TSprite())
  AddElement(*SpriteList()) : *SpriteList() = *Sprite
EndProcedure


If InitSprite() = 0 Or InitKeyboard() = 0
  MessageRequester("Error", "Sprite system or keyboard system can't be initialized", 0)
  End
EndIf
UsePNGImageDecoder() : SoundInitiated = InitSound()
If OpenWindow(0, 0, 0, 640, 480, "Late Run", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, 640, 480, 0, 0, 0)
    InitializeSprite(Hero, ScreenWidth() / 2, ScreenHeight() / 2, 0, 0, #Hero_Sprite, BasePath + "graphics" + #PS$ + "hero.png", 4, #True, 4)
    AddSpriteToList(@Hero, *SpriteDisplayList()) : AddSpriteToList(@Hero, *SpriteUpdateList())
    
    ;LoadSounds()
    ;StartGame(#False)
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
      ;update here and then display
      DisplaySpriteList(*SpriteDisplayList(), ElapsedTimneInS)
    Until ExitGame
  EndIf
EndIf