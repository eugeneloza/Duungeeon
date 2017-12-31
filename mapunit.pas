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
  Generics.Collections, CastleRandom, X3DNodes, CastleVectors, CastleImages;

const
  MapSizeX = 30;
  MapSizeY = 30;

const Inaccessible = -1;

type
  TLocation = (LGraveyard);

type
  TMapItem = integer;

type
  TMap = array [0..MapSizeX - 1, 0..MapSizeY - 1] of TMapItem;

type
  TLocationGenerator = class(TObject)
  strict private {map generation algorithms}

    procedure MakeRandomMap;
  strict private {map generation tools}
    FloodMap: TMap;
    CurrentLocation: TLocation;
    Rnd: TCastleRandom;
    procedure ClearFloodFill;
    function SafeFloodMap(const ax, ay: integer): TMapItem;
    function isInaccessible(const ax, ay: integer): boolean;
    function isAccessible(const ax, ay: integer): boolean;
    function FloodFill: boolean;
    procedure OpenInaccessible;
    { so that there will be no wall completely blocked }
    procedure ProcessWallBlocks;
    { leave no walls with less than 2 nearby passable tiles }
    procedure ProcessWallDeadends;
    procedure MakeOuterWalls;
  public
    EntranceX, EntranceY: integer;

    procedure MakeMap(const aLocation: TLocation);
    function MakeRoot: TX3DRootNode;
    function MakeMinimap: TRGBAlphaImage;

    constructor Create;
    destructor Destroy; override;
  end;


var
  Map: TMap;
  Minimap: TRGBAlphaImage;
  Location: TLocationGenerator;


function isPassable(ax, ay: integer): boolean;
//function SafeMap(ax, ay: integer): TMapItem;
implementation

uses
  SysUtils,
  MyLoad3D, CastleFilesUtils, CastleLog,
  CastleColors, //temp
  WindowUnit;

function isPassable(ax, ay: integer): boolean;
begin
  if (ax >= 0) and (ay >= 0) and (ax < MapSizeX) and (ay < MapSizeY) then
  begin
    if Map[ax, ay] = 0 then
      Result := true
    else
      Result := false;
  end
  else
    Result := false;
end;

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
      Translation.Translation := Vector3(ix * 2 * Scale, 0, iy * 2 * Scale);
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

function TLocationGenerator.MakeMinimap: TRGBAlphaImage;
var
  ix, iy: integer;
begin
  Result := TRGBAlphaImage.Create;
  Result.SetSize(MapSizeX*8, MapSizeY*8);
  Result.Clear(Vector4Byte(0, 0, 0, 0));
  for ix := 0 to MapSizeX - 1 do
    for iy := 0 to MapSizeY - 1 do begin
      if Map[ix, iy] = 1 then Result.FillEllipse(ix * 8 + 4, iy * 8 + 4, 6, 6, White);
    end;
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

procedure TLocationGenerator.ClearFloodFill;
var
  ix, iy: integer;
begin
  for ix := 0 to MapSizeX - 1 do
    for iy := 0 to MapSizeY - 1 do
      FloodMap[ix, iy] := 0;
  FloodMap[EntranceX, EntranceY] := 1;
end;

function TLocationGenerator.SafeFloodMap(const ax, ay: integer): TMapItem;
begin
  if (ax >= 0) and (ay >= 0) and (ax < MapSizeX) and (ay < MapSizeY) then
    Result := FloodMap[ax, ay]
  else
    Result := 0;
end;

function TLocationGenerator.isInaccessible(const ax, ay: integer): boolean;
begin
  if SafeFloodMap(ax, ay) = Inaccessible then
    Result := true
  else
    Result := false;
end;

function TLocationGenerator.isAccessible(const ax, ay: integer): boolean;
begin
  if SafeFloodMap(ax, ay) > 0 then
    Result := true
  else
    Result := false;
end;

function TLocationGenerator.FloodFill: boolean;
var
  ix, iy: integer;
  Count: integer;
  Pass: integer;
begin
  Pass := 1; {in case we've just cleared FloodMap it'll build a good distance map}
  repeat
    inc(Pass);
    Count := 0;
    for ix := 0 to MapSizeX - 1 do
      for iy := 0 to MapSizeY - 1 do
        if (isPassable(ix, iy)) and (FloodMap[ix, iy] <= 0) then begin
          if (SafeFloodMap(ix - 1, iy) > 0) or (SafeFloodMap(ix + 1, iy) > 0) or
            (SafeFloodMap(ix, iy - 1) > 0) or (SafeFloodMap(ix, iy + 1) > 0) then
          begin
            FloodMap[ix, iy] := Pass;
            inc(Count);
          end;
        end;
  until Count = 0;

  Result := true;
  for ix := 0 to MapSizeX - 1 do
    for iy := 0 to MapSizeY - 1 do
      if (isPassable(ix, iy)) and (FloodMap[ix, iy] <= 0) then begin
        FloodMap[ix, iy] := Inaccessible;
        Result := false;
      end;
end;

type
  Txy = record
    x, y: integer;
  end;
type TMapList = specialize TList<Txy>;

procedure TLocationGenerator.OpenInaccessible;
var
  ix, iy: integer;
  Join, LoopJoin: TMapList;
  tmp: Txy;
  ci, cw, ca: integer;
  indx: integer;
begin
  if not FloodFill then begin
    Join := TMapList.Create;
    LoopJoin := TMapList.Create;
    repeat
      Join.Clear;
      LoopJoin.Clear;
      for ix := 1 to MapSizeX - 2 do
        for iy := 1 to MapSizeY - 2 do if not isPassable(ix,iy) then begin
          ci := 0;
          if isInaccessible(ix + 1, iy) then inc(ci);
          if isInaccessible(ix - 1, iy) then inc(ci);
          if isInaccessible(ix, iy + 1) then inc(ci);
          if isInaccessible(ix, iy - 1) then inc(ci);
          ca := 0;
          if isAccessible(ix + 1, iy) then inc(ca);
          if isAccessible(ix - 1, iy) then inc(ca);
          if isAccessible(ix, iy + 1) then inc(ca);
          if isAccessible(ix, iy - 1) then inc(ca);
          cw := 0;
          if not isPassable(ix + 1, iy) then inc(cw);
          if not isPassable(ix - 1, iy) then inc(cw);
          if not isPassable(ix, iy + 1) then inc(cw);
          if not isPassable(ix, iy - 1) then inc(cw);

          if (ci > 0) then begin
            if (ca = 1) then begin
              tmp.x := ix;
              tmp.y := iy;
              Join.Add(tmp);
            end;
            if (ca > 1) then begin
              tmp.x := ix;
              tmp.y := iy;
              LoopJoin.Add(tmp);
            end;
          end;
        end;
      if Join.Count > 0 then begin
        indx := Rnd.Random(Join.Count);
        Map[Join[indx].x, Join[indx].y] := 0;
      end
      else
      if LoopJoin.Count > 0 then begin
        indx := Rnd.Random(LoopJoin.Count);
        Map[LoopJoin[indx].x, LoopJoin[indx].y] := 0;
      end
      else
        raise Exception.Create('Unable to join inaccessible area!');

    until (FloodFill);
    LoopJoin.Free;
    Join.Free;
  end;
end;

procedure TLocationGenerator.ProcessWallBlocks;
var
  ix, iy: integer;
begin
  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do
      if Map[ix, iy] = 1 then
      begin
        if (Map[ix - 1, iy] = 1) and (Map[ix + 1, iy] = 1) and
           (Map[ix, iy - 1] = 1) and (Map[ix, iy + 1] = 1) then
          Map[ix, iy] := 0;
      end;
end;

procedure TLocationGenerator.ProcessWallDeadends;
var
  ix, iy: integer;
  c: integer;
begin
  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do
      if Map[ix, iy] = 1 then
      begin
        c := 0;
        if isPassable(ix - 1, iy) then inc(c);
        if isPassable(ix + 1, iy) then inc(c);
        if isPassable(ix, iy - 1) then inc(c);
        if isPassable(ix, iy + 1) then inc(c);
        if c <= 1 then
          Map[ix, iy] := 0;
      end;
end;

procedure TLocationGenerator.MakeRandomMap;
var
  ix, iy: integer;
begin
  MakeOuterWalls;

  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do
      if (Rnd.Random < 0.3) then
        Map[ix, iy] := 0
      else
        Map[ix, iy] := 1;

  //make space for player start location
  Map[EntranceX, EntranceY] := 0;

  ProcessWallBlocks;
  ProcessWallDeadends;

  OpenInaccessible;
end;

procedure TLocationGenerator.MakeMap(const aLocation: TLocation);
begin
  CurrentLocation := aLocation;

  {get accessible area}
  ClearFloodFill;
  //FloodFill;

  {do the core map generation}
  case CurrentLocation of
    LGraveyard: MakeRandomMap;
  end;

  {build distance map}
  ClearFloodFill;
  FloodFill;

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

