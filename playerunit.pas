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

(* operates the player *)

unit PlayerUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleVectors, CastleCameras;

type TDir = (South, West, North, East);

type
  TCoord = record
    Dir: TDir;
    x, y: integer;
  end;

type
  TPlayer = class(TObject)
  public
    Last, Next: TCoord;
    Camera: TWalkCamera;

    procedure Move(Fwd: shortint);
    procedure RotateClockwise;
    procedure RotateCounterclockwise;

    constructor Create;
    destructor Destroy; override;
  end;

var
  Face: array [TDir] of TVector3;
  Player: TPlayer;


implementation

uses
  WindowUnit, WorldUnit;


procedure TPlayer.Move(Fwd: shortint);
var dx, dy: shortint;
begin
  dx := 0;
  dy := 0;
  case Player.Last.Dir of
    South: dx := 1;
    North: dx := -1;
    West: dy := 1;
    East: dy := -1;
  end;
  dx := dx * Fwd;
  dy := dy * Fwd;
  if Map[Player.Last.X + dx, Player.Last.Y + dy] = 0 then begin
    Player.Next.X := Player.Last.X + dx;
    Player.Next.Y := Player.Last.Y + dy;
    Player.Camera.Position := Player.Camera.Position + Fwd * Player.Camera.Direction * Scale * 2;
    Player.Last.X := Player.Next.X;
    Player.Last.Y := Player.Next.Y;
  end;
end;


procedure TPlayer.RotateClockwise;
begin
  case Last.Dir of
    East: Next.Dir := South;
    North: Next.Dir := East;
    West: Next.Dir := North;
    South: Next.Dir := West;
  end;
  Last.Dir := Next.Dir;
  Player.Camera.Direction := Face[Player.Last.Dir];
end;

procedure TPlayer.RotateCounterclockwise;
begin
  case Last.Dir of
    East: Next.Dir := North;
    North: Next.Dir := West;
    West: Next.Dir := South;
    South: Next.Dir := East;
  end;
  Last.Dir := Next.Dir;
  Player.Camera.Direction := Face[Player.Last.Dir];
end;

constructor TPlayer.Create;
begin
  //inherited <-------- nothing to inherit
  Last.Dir := South;
  Last.X := 30 div 2;
  Last.Y := 30 div 2;

  Camera := TWalkCamera.Create(Window);
  Camera.PreferredHeight := 1 * ScaleY;
  Camera.Position := Vector3(Last.X * 2 * Scale,
    Camera.PreferredHeight - 1 * ScaleY, Last.Y * 2 * Scale);
  Camera.Direction := Face[Last.Dir];
  Camera.FallingEffect := false;
  Camera.Input := [];
end;

destructor TPlayer.Destroy;
begin
  inherited Destroy;
end;

initialization
  Face[South] := Vector3(1,0,0);
  Face[North] := Vector3(-1,0,0);
  Face[East] := Vector3(0,0,-1);
  Face[West] := Vector3(0,0,1);


finalization
  Player.Free;

end.

