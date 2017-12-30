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

{ main file }

program Duungeeon;

uses
  SysUtils, CastleWindow, CastleLog,
  CastleKeysMouse, WorldUnit, PlayerUnit, windowunit;

procedure doPress(Container: TUIContainer; const Event: TInputPressRelease);
  procedure Move(Fwd: shortint);
  var dx, dy: shortint;
  begin
    dx := 0;
    dy := 0;
    Case Player.Dir of
      South: dx := 1;
      North: dx := -1;
      West: dy := 1;
      East: dy := -1;
    end;
    dx := dx * Fwd;
    dy := dy * Fwd;
    if Map[Player.X + dx, Player.Y + dy] = 0 then begin
      Player.X += dx;
      Player.Y += dy;
      Player.Camera.Position := Player.Camera.Position + Fwd * Player.Camera.Direction * Scale * 2;
    end;
  end;
  procedure Rotate(CCW: boolean);
  begin
    if CCW then
    begin
      case Player.Dir of
        East: Player.Dir := North;
        North: Player.Dir := West;
        West: Player.Dir := South;
        South: Player.Dir := East;
      end;
    end
    else
    begin
      case Player.Dir of
        East: Player.Dir := South;
        North: Player.Dir := East;
        West: Player.Dir := North;
        South: Player.Dir := West;
      end;
    end;
    Player.Camera.Direction := Face[Player.Dir];
  end;
begin
  if Event.EventType = itKey then begin
    case Event.Key of
      k_W: Move(1);
      k_S: Move(-1);
      k_A: Rotate(true);
      k_D: Rotate(false);
    end;
  end;
end;

begin
  InitializeLog('0', nil, ltTime);
  Window := TCastleWindow.Create(Application);
  Window.DoubleBuffer := True;
  Window.OnPress := @doPress;
  Application.MainWindow := Window;
  PrepareScene;
  Window.OpenAndRun;
end.

