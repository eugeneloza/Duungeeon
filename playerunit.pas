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
  TPlayer = class(TObject)
  public
    Dir: TDir;
    x, y: integer;
    Camera: TWalkCamera;

    constructor Create;
    destructor Destroy; override;
  end;

var
  Face: array [TDir] of TVector3;
  Player: TPlayer;


implementation

uses
  WindowUnit;


constructor TPlayer.Create;
begin
  //inherited <-------- nothing to inherit
  Dir := South;
  X := 30 div 2;
  Y := 30 div 2;

  Camera := TWalkCamera.Create(Window);
  Camera.PreferredHeight := 1 * ScaleY;
  Camera.Position := Vector3(X * 2 * Scale,
    Camera.PreferredHeight - 1 * ScaleY, Y * 2 * Scale);
  Camera.Direction := Face[Dir];
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

