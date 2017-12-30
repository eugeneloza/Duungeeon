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
  CastleRandom, X3DNodes, CastleVectors;

const
  MapSizeX = 30;
  MapSizeY = 30;

type
  TLocation = (LGraveyard);

type
  TMap = array [0..MapSizeX - 1, 0..MapSizeY - 1] of byte;

type
  TLocationGenerator = class(TObject)
  strict private
    procedure MakeGraveyardLocation;
  strict private
    GM: TMap;
    CurrentLocation: TLocation;
    Rnd: TCastleRandom;
    procedure MakeOuterWalls;
  public
    EntranceX, EntranceY: integer;

    procedure MakeMap(const aLocation: TLocation);
    function MakeRoot: TX3DRootNode;

    constructor Create;
    destructor Destroy; override;
  end;


var
  Map: TMap;
  Location: TLocationGenerator;


implementation

uses
  SysUtils,
  MyLoad3D, CastleFilesUtils, CastleLog,
  WindowUnit;

type
  TTransformNodeHelper = class helper for TTransformNode
  public
    procedure AddContent(aContent: TX3DRootNode);
  end;

procedure TTransformNodeHelper.AddContent(aContent: TX3DRootNode);
var
  i: integer;
begin
  for i := 0 to aContent.FdChildren.Count-1 do
    FdChildren.Add(aContent.FdChildren[i]);
end;

function TLocationGenerator.MakeRoot: TX3DRootNode;
var
  Tiles: array of TX3DRootNode;

  Translation: TTransformNode;
  Background: TBackgroundNode;
  ix, iy: integer;
begin
  Result := TX3DRootNode.Create;

  SetLength(Tiles, 2);
  Tiles[0] := LoadBlenderX3D(ApplicationData('tiles/Pass.x3d'));
  Tiles[1] := LoadBlenderX3D(ApplicationData('tiles/Box.x3d'));

  {build the scene}

  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do begin
      Translation := TTransformNode.Create;
      Translation.AddContent(Tiles[Map[ix, iy]]);
      Translation.Translation := Vector3(ix*2*Scale, 0, iy*2*Scale);
      Translation.Scale := Vector3(Scale, ScaleY, Scale);
      Result.FdChildren.Add(Translation);
    end;

  //may be moved to constructor, as there is only one background?
  Background := TBackgroundNode.Create;
  Background.FdBackUrl.Items.Add(ApplicationData('skybox/bkg2_back6_CC0_by_StumpyStrust.tga'));
  Background.FdBottomUrl.Items.Add(ApplicationData('skybox/bkg2_bottom4_CC0_by_StumpyStrust.tga'));
  Background.FdFrontUrl.Items.Add(ApplicationData('skybox/bkg2_front5_CC0_by_StumpyStrust.tga'));
  Background.FdLeftUrl.Items.Add(ApplicationData('skybox/bkg2_left2_CC0_by_StumpyStrust.tga'));
  Background.FdRightUrl.Items.Add(ApplicationData('skybox/bkg2_right1_CC0_by_StumpyStrust.tga'));
  Background.FdTopUrl.Items.Add(ApplicationData('skybox/bkg2_top3_CC0_by_StumpyStrust.tga'));
  Result.FdChildren.Add(Background);

  Tiles[0].Free;
  Tiles[1].Free;
end;

procedure TLocationGenerator.MakeOuterWalls;
var
  ix, iy: integer;
begin
  //make map borders
  for ix := 0 to MapSizeX - 1 do begin
    Map[ix, 0] := 1;
    Map[ix, MapSizeY - 1] := 1;
  end;
  for iy := 0 to MapSizeY - 1 do begin
    Map[0, iy] := 1;
    Map[MapSizeX - 1, iy] := 1;
  end;

end;

procedure TLocationGenerator.MakeGraveyardLocation;
var
  ix, iy: integer;
begin
  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do
      Map[ix, iy] := Rnd.Random(2);
end;

procedure TLocationGenerator.MakeMap(const aLocation: TLocation);
begin
  CurrentLocation := aLocation;

  case CurrentLocation of
    LGraveyard: MakeGraveyardLocation;
  end;

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

