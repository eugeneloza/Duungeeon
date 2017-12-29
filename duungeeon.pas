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
      dSouth: dx := 1;
      dNorth: dx := -1;
      dWest: dy := 1;
      dEast: dy := -1;
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
        dEast: Player.Dir := dNorth;
        dNorth: Player.Dir := dWest;
        dWest: Player.Dir := dSouth;
        dSouth: Player.Dir := dEast;
      end;
    end
    else
    begin
      case Player.Dir of
        dEast: Player.Dir := dSouth;
        dNorth: Player.Dir := dEast;
        dWest: Player.Dir := dNorth;
        dSouth: Player.Dir := dWest;
      end;
    end;
    Player.Camera.Direction := Player.GetDirection(Player.Dir);
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

