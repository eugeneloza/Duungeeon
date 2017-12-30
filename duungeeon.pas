{Copyright (C) 2012-2017 Yevhen Loza

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.}

{---------------------------------------------------------------------------}

(* main file *)

program Duungeeon;

uses
  SysUtils, CastleWindow, CastleLog,
  CastleKeysMouse, WorldUnit, PlayerUnit, WindowUnit, GuiUnit;

procedure doManage(Container: TUIContainer);
begin
  Player.Manage;
end;

procedure doRender(Container: TUIContainer);
begin
  GUI.Draw;
end;

procedure doPress(Container: TUIContainer; const Event: TInputPressRelease);
begin
  if Event.EventType = itKey then begin
    case Event.Key of
      k_W: Player.Move(1);
      k_S: Player.Move(-1);
      k_A: Player.RotateCounterclockwise;
      k_D: Player.RotateClockwise;
    end;
  end;
end;

begin
  InitializeLog('0', nil, ltTime);
  Window := TCastleWindow.Create(Application);
  Window.DoubleBuffer := True;
  Window.OnPress := @doPress;
  Window.OnBeforeRender := @doManage;
  Window.OnRender := @doRender;
  Application.MainWindow := Window;
  GUI := TGui.Create(Window);
  PrepareScene;
  Window.OpenAndRun;
end.

