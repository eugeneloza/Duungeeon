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

(* operates the player *)

unit PlayerUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleVectors, CastleCameras, CastleTimeUtils;

type
  TDir = (drSouth, drWest, drNorth, drEast);

const
  MoveSpeed = 0.2; { seconds }

type
  TCoord = record
    Dir: TDir;
    X, Y: Integer;
  end;

  TMove = (mvWalkForward, mvBackPedal, mvStepLeft, mvStepRight, mvRotateClockwise, mvRotateCounterclockwise);

type

  { TPlayer }

  TPlayer = class(TObject)
  strict private
    MoveStart: TTimerResult;
    IsMoving: Boolean;
    procedure ResetDirection;
    procedure ResetCamera;
  public
    Last, Next: TCoord;
    Camera: TWalkCamera;
    procedure ForceEndTurn;
    procedure Teleport(const TX, TY: Integer; const TD: TDir);
    procedure SetCameraTo(const CX, CY: Single; const D: TVector3);
    procedure Move(AMove: TMove);
    procedure Manage;
    constructor Create;
    destructor Destroy; override;
  end;

var
  Face: array [TDir] of TVector3;
  Player: TPlayer;

implementation

uses
  SysUtils, WindowUnit, MapUnit;

procedure TPlayer.ForceEndTurn;
begin
  // enemy actions should be here
  ResetDirection;
end;

procedure TPlayer.Teleport(const TX, TY: Integer; const TD: TDir);
begin
  Next.X := TX;
  Next.Y := TY;
  Next.Dir := TD;
  ResetDirection;
  ResetCamera;
end;

procedure TPlayer.ResetCamera;
begin
  SetCameraTo(Next.X, Next.Y, Face[Next.Dir]);
end;

procedure TPlayer.Manage;
var
  Phase: Single;
  CX, CY: Single;
  CFace: TVector3;
begin
  if (not IsMoving) then
    if (Next.X <> Last.X) or (Next.Y <> Last.Y) or (Next.Dir <> Last.Dir) then
    begin
      IsMoving := true;
      MoveStart := Timer;
    end;
  if IsMoving then
  begin
    Phase := TimerSeconds(Timer, MoveStart) / MoveSpeed;
    if Phase < 1 then
    begin
      CX := Next.X * Phase + Last.X * (1 - Phase);
      CY := Next.Y * Phase + Last.Y * (1 - Phase);
      CFace := Face[Next.Dir] * Phase + Face[Last.Dir] * (1 - Phase);
      SetCameraTo(CX, CY, CFace);
    end
    else
    begin
      ResetDirection;
      ResetCamera;
      IsMoving := false;
    end;
  end;
end;

procedure TPlayer.SetCameraTo(const CX, CY: Single; const D: TVector3);
begin
  Camera.Position := Vector3(CX * 2 * Scale - D[0], Camera.PreferredHeight, CY * 2 * Scale - D[2]);
  Camera.Direction := D;
end;

procedure TPlayer.Move(AMove: TMove);
var
  DX, DY, FW: ShortInt;
begin
  if IsMoving then
    ForceEndTurn;

  FW := 0;
  DX := 0;
  DY := 0;

  case AMove of
    mvWalkForward:
      FW := 1;
    mvBackPedal:
      FW := -1;
    mvStepLeft:
      FW := -1;
    mvStepRight:
      FW := 1;
    mvRotateClockwise:
      begin
        case Last.Dir of
          drEast:
            Next.Dir := drSouth;
          drNorth:
            Next.Dir := drEast;
          drWest:
            Next.Dir := drNorth;
          drSouth:
            Next.Dir := drWest;
        end;
        Exit;
      end;
    mvRotateCounterclockwise:
      begin
        case Last.Dir of
          drEast:
            Next.Dir := drNorth;
          drNorth:
            Next.Dir := drWest;
          drWest:
            Next.Dir := drSouth;
          drSouth:
            Next.Dir := drEast;
        end;
        Exit;
      end;
  end;

  case AMove of
    mvWalkForward, mvBackPedal:
      case Player.Last.Dir of
        drSouth:
          DX := 1;
        drNorth:
          DX := -1;
        drWest:
          DY := 1;
        drEast:
          DY := -1;
      end;
    mvStepLeft, mvStepRight:
      case Player.Last.Dir of
        drSouth:
          DY := 1;
        drNorth:
          DY := -1;
        drWest:
          DX := -1;
        drEast:
          DX := 1;
      end;
  end;

  DX := DX * FW;
  DY := DY * FW;

  if isPassable(Last.X + DX, Last.Y + DY) then
  begin
    Next.X := Last.X + DX;
    Next.Y := Last.Y + DY;
  end;
end;

procedure TPlayer.ResetDirection;
begin
  Last.Dir := Next.Dir;
  Last.X := Next.X;
  Last.Y := Next.Y;
  IsMoving := false;
end;

constructor TPlayer.Create;
begin
  // inherited <-------- nothing to inherit
  Next.Dir := drSouth;
  Next.X := 30 div 2;
  Next.Y := 30 div 2;
  ResetDirection;

  Camera := TWalkCamera.Create(Window);
  Camera.PreferredHeight := 1 * ScaleY;
  Camera.FallingEffect := false;
  Camera.Input := [];
  Camera.Gravity := false;
end;

destructor TPlayer.Destroy;
begin
  inherited Destroy;
end;

initialization

Face[drSouth] := Vector3(1, 0, 0);
Face[drNorth] := Vector3(-1, 0, 0);
Face[drEast] := Vector3(0, 0, -1);
Face[drWest] := Vector3(0, 0, 1);

finalization

FreeAndNil(Player);

end.
