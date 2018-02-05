{ Copyright (C) 2012-2017 Yevhen Loza

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>. }

{ --------------------------------------------------------------------------- }

(* main file *)

program Duungeeon;

uses
  SysUtils, CastleWindow, CastleLog,
  CastleKeysMouse, WorldUnit, PlayerUnit, WindowUnit, GuiUnit;

{$PUSH}{$WARN 5024 off : Parameter "$1" not used}

procedure DoManage(Container: TUIContainer);
begin
  Player.Manage;
end;

procedure DoResize(Container: TUIContainer);
begin
  GUI.Resize;
end;

procedure DoRender(Container: TUIContainer);
begin
  GUI.Draw;
end;

procedure DoPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.EventType = itKey then
  begin
    case Event.Key of
      k_W:
        Player.Move(mvWalkForward);
      k_S:
        Player.Move(mvBackPedal);
      k_Q:
        Player.Move(mvStepLeft);
      k_E:
        Player.Move(mvStepRight);
      k_A:
        Player.Move(mvRotateCounterClockwise);
      k_D:
        Player.Move(mvRotateClockwise);
      k_P:
        Window.SaveScreen('duungeeon.png');
    end;
  end;
end;
{$POP}

begin
  InitializeLog('0', nil, ltTime);
  Window := TCastleWindow.Create(Application);
  Window.DoubleBuffer := True;
  Window.OnPress := @DoPress;
  Window.OnBeforeRender := @DoManage;
  Window.OnRender := @DoRender;
  Window.OnResize := @DoResize;
  Application.MainWindow := Window;
  GUI := TGui.Create(Window);
  PrepareScene;
  Window.OpenAndRun;

end.
