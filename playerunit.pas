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

{ operates the player }

unit PlayerUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleVectors, CastleCameras;

type TDir = (dSouth, dWest, dNorth, dEast);

type TPlayer = record
  Dir: TDir;
  x, y: integer;
end;

var
  South, West, North, East: TVector3;
  Camera: TWalkCamera;
  Player: TPlayer;


function GetDirection(a: TDir): TVector3;
implementation

function GetDirection(a: TDir): TVector3;
begin
  case a of
    dSouth: Result := South;
    dEast: Result := East;
    dWest: Result := West;
    dNorth: Result := North;
  end;
end;

end.

