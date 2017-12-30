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

(* Generates the map *)

unit MapUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleRandom;

const
  MapSizeX = 30;
  MapSizeY = 30;

type
  TLocation = (LGraveyard);

type
  TLocationGenerator = class(TObject)
  strict private
    Rnd: TCastleRandom;
    procedure MakeOuterWalls;
  public
    EntranceX, EntranceY: integer;

    procedure MakeMap(const aLocation: TLocation);

    constructor Create;
    destructor Destroy; override;
  end;


var
  Map: array [0..MapSizeX - 1, 0..MapSizeY - 1] of byte;
  Location: TLocationGenerator;


implementation

procedure TLocationGenerator.MakeOuterWalls;
var
  ix, iy: integer;
begin
  //make map borders
  for ix := 0 to MapSizeX-1 do begin
    Map[ix, 0] := 1;
    Map[ix, MapSizeY-1] := 1;
  end;
  for iy := 0 to MapSizeY-1 do begin
    Map[0, iy] := 1;
    Map[MapSizeX-1, iy] := 1;
  end;

end;

procedure TLocationGenerator.MakeMap(const aLocation: TLocation);
var
  ix, iy: integer;
begin
  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do
      Map[ix, iy] := Rnd.Random(2);

  MakeOuterWalls;

  //make space for player start location
  Map[EntranceX, EntranceY] := 0;
end;

constructor TLocationGenerator.Create;
begin
  //inherited <------ nothing to inherit
  Rnd := TCastleRandom.Create;
end;

destructor TLocationGenerator.Destroy;
begin
  Rnd.Free;
  inherited Destroy;
end;


end.

