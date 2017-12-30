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
  CastleVectors, CastleCameras, CastleTimeUtils;

type TDir = (South, West, North, East);

const
  MoveSpeed = 0.2; {seconds}

type
  TCoord = record
    Dir: TDir;
    x, y: integer;
  end;

type
  TPlayer = class(TObject)
  strict private
    MoveStart: TTimerResult;
    isMoving: boolean;
    procedure ResetDirection;
    procedure ResetCamera;
  public
    Last, Next: TCoord;
    Camera: TWalkCamera;

    procedure ForceEndTurn;

    procedure Teleport(const tx, ty: integer; const td: TDir);

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
  WindowUnit, MapUnit;

procedure TPlayer.ForceEndTurn;
begin
  //enemy actions should be here
  ResetDirection;
end;

procedure TPlayer.Teleport(const tx, ty: integer; const td: TDir);
begin
  Next.X := tx;
  Next.Y := ty;
  Next.Dir := td;
  ResetDirection;
  ResetCamera;
end;

procedure TPlayer.ResetCamera;
begin
  Camera.Position := Vector3(Next.X * 2 * Scale,
    Camera.PreferredHeight - 1 * ScaleY, Next.Y * 2 * Scale);
  Camera.Direction := Face[Next.Dir];
end;

procedure TPlayer.Manage;
var
  Phase: single;

  cx, cy: single;
  cface: TVector3;
begin
  if (not isMoving) then
    if (Next.X <> Last.X) or (Next.Y <> Last.Y) or (Next.Dir <> Last.Dir) then
    begin
      isMoving := true;
      MoveStart := Timer;
    end;
  if isMoving then begin
    Phase := TimerSeconds(Timer, MoveStart) / MoveSpeed;
    if Phase < 1 then begin
      cx := Next.X * Phase + Last.X * (1 - Phase);
      cy := Next.Y * Phase + Last.Y * (1 - Phase);
      cface := Face[Next.Dir] * Phase + Face[Last.Dir] * (1 - Phase);
      Camera.Position := Vector3(cx * 2 * Scale,
        Camera.PreferredHeight - 1 * ScaleY, cy * 2 * Scale);
      Camera.Direction := cface;
    end
    else begin
      ResetDirection;
      ResetCamera;
      isMoving := false;
    end;
  end;
end;

procedure TPlayer.Move(Fwd: shortint);
var dx, dy: shortint;
begin
  if isMoving then ForceEndTurn;

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
  if isPassable(Last.X + dx, Last.Y + dy) then begin
    Next.X := Last.X + dx;
    Next.Y := Last.Y + dy;
  end;
end;


procedure TPlayer.RotateClockwise;
begin
  if isMoving then ForceEndTurn;

  case Last.Dir of
    East: Next.Dir := South;
    North: Next.Dir := East;
    West: Next.Dir := North;
    South: Next.Dir := West;
  end;
end;

procedure TPlayer.RotateCounterclockwise;
begin
  if isMoving then ForceEndTurn;

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
  isMoving := false;
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

