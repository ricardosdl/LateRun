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
  IsAnimated.b
  CurrentFrame.a
  AnimationTimer.f
  IsVisible.b
  ZoomLevel.f
EndStructure

Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, StartTimeInMs.f, SoundInitiated.b
Global NewList SpriteDisplayList.TSprite(), NewList SpriteUpdateList.TSprite(), Hero.TSprite
#Hero_Sprite = 1
Procedure LoadSprites()
  Loaded.i = LoadSprite(#Hero_Sprite, BasePath + "graphics" + #PS$ + "hero.png")
  If Not Loaded
    Debug "not loaded"
  EndIf
  ZoomSprite(#Hero_Sprite, SpriteWidth(#Hero_Sprite) * 4, SpriteHeight(#Hero_Sprite) * 4)
  Debug SpriteWidth(#Hero_Sprite)
  Debug SpriteHeight(#Hero_Sprite)
EndProcedure
Procedure InitializeSprite(*Sprite.TSprite, x.f, y.f, XVel.f, YVel.f, SpriteNum.i, IsAnimated.b, IsVisible.b, ZoomLevel.f)
  *Sprite\x = x : *Sprite\y = y : *Sprite\XVelocity = XVel : *Sprite\YVelocity = YVel
  *Sprite\SpriteNum = SpriteNum : *Sprite\IsAnimated = IsAnimated : *Sprite\IsVisible = IsVisible : *Sprite\ZoomLevel = ZoomLevel
  *Sprite\CurrentFrame = 0 : *Sprite\AnimationTimer = 0.0
EndProcedure


If InitSprite() = 0 Or InitKeyboard() = 0
  MessageRequester("Error", "Sprite system or keyboard system can't be initialized", 0)
  End
EndIf
UsePNGImageDecoder()
SoundInitiated = InitSound()
If OpenWindow(0, 0, 0, 640, 480, "Late Run", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, 640, 480, 0, 0, 0)
    LoadSprites()
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
      DisplaySprite(#Hero_Sprite, ScreenWidth() / 2, ScreenHeight() / 2)
      ElapsedTimneInS = (ElapsedMilliseconds() - StartTimeInMs) / 1000.0
      If ElapsedTimneInS >= 0.05;never let the elapsed time be higher than 20 fps
        ElapsedTimneInS = 0.05
      EndIf
    Until ExitGame
  EndIf
EndIf