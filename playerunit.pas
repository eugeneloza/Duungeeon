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
  strict private
    procedure ResetDirection;
  public
    Current, Last, Next: TCoord;
    Camera: TWalkCamera;

    procedure Move(Fwd: shortint);
    procedure RotateClockwise;
    procedure RotateCounterclockwise;

    procedure Manage;

    constructor Create;
    destructor Destroy; override;
  end;

var
  Face: array [TDir] of TVector3;
  Player: TPlayer;


implementation

uses
  WindowUnit, WorldUnit;

procedure TPlayer.Manage;
begin
  ResetDirection;
  Camera.Position := Vector3(Current.X * 2 * Scale,
    Camera.PreferredHeight - 1 * ScaleY, Current.Y * 2 * Scale);
  Camera.Direction := Face[Current.Dir];
end;

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
  if Map[Last.X + dx, Last.Y + dy] = 0 then begin
    Next.X := Last.X + dx;
    Next.Y := Last.Y + dy;
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
end;

procedure TPlayer.RotateCounterclockwise;
begin
  case Last.Dir of
    East: Next.Dir := North;
    North: Next.Dir := West;
    West: Next.Dir := South;
    South: Next.Dir := East;
  end;
end;

procedure TPlayer.ResetDirection;
begin
  Last.Dir := Next.Dir;
  Last.X := Next.X;
  Last.Y := Next.Y;
  Current.Dir := Next.Dir;
  Current.X := Next.X;
  Current.Y := Next.Y;
end;

constructor TPlayer.Create;
begin
  //inherited <-------- nothing to inherit
  Next.Dir := South;
  Next.X := 30 div 2;
  Next.Y := 30 div 2;
  ResetDirection;

  Camera := TWalkCamera.Create(Window);
  Camera.PreferredHeight := 1 * ScaleY;
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

