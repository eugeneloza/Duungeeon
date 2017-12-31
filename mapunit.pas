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
  MapArea = (MapSizeX - 2) * (MapSizeY - 2);

const Inaccessible = -1;

type
  TLocation = (LGraveyard, LMausoleum, LForest, LCatacomb, LCheckers, LBlocky, LMaze, LTwisty, LDeepForest);

type
  TMapItem = integer;

type
  TMap = array [0..MapSizeX - 1, 0..MapSizeY - 1] of TMapItem;

type
  TLocationGenerator = class(TObject)
  strict private {map generation algorithms}

    procedure MakeRandomMap;
    procedure MakeBoxMap;
    procedure MakeDrunkenWalkerMap;
    procedure MakeRotorMap;
    procedure MakeCheckersMap;
    procedure MakeDenseCheckersMap;
    procedure MakeTwistyMap;
    procedure MakeBlockyMap;
    procedure MakePixelgrowMap;
    //procedure MakeSineMap;
  strict private {map generation tools}
    FloodMap: TMap;
    CurrentLocation: TLocation;
    Rnd: TCastleRandom;
    procedure ClearFloodFill;
    procedure ClearMap(const aValue: TMapItem);
    function SafeFloodMap(const ax, ay: integer): TMapItem;
    function isInaccessible(const ax, ay: integer): boolean;
    function isAccessible(const ax, ay: integer): boolean;
    function FloodFill: boolean;
    procedure OpenInaccessible;
    { so that there will be no wall completely blocked }
    procedure ProcessWallBlocks;
    { leave no walls with less than 2 nearby passable tiles }
    procedure ProcessWallDeadends;
    procedure FloodWallBlocks;
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


type
  TTileList = specialize TObjectList<TX3DRootNode>;

function TLocationGenerator.MakeRoot: TX3DRootNode;
var
  Wall, Pass, Border: TTileList;

  Translation: TTransformNode;
  Background: TBackgroundNode;
  ix, iy: integer;
begin
  Result := TX3DRootNode.Create;

  Wall := TTileList.Create(true);
  Pass := TTileList.Create(true);
  Border := TTileList.Create(true);

  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard01.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard02.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard03.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard04.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard05.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard06.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard07.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard08.x3d')));
  Wall.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard09.x3d')));
  Border.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard_border.x3d')));
  Pass.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard_pass01.x3d')));
  Pass.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard_pass02.x3d')));
  Pass.Add(LoadBlenderX3D(ApplicationData('tiles/graveyard/graveyard_pass03.x3d')));

  {build the scene}

  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do begin
      Translation := TTransformNode.Create;
      if (ix = 0) or (iy = 0) or (ix = MapSizeX - 1) or (iy = MapSizeY - 1) then
        Translation.AddContent(Border[Rnd.Random(Border.Count)])
      else
      if Map[ix, iy] = 0 then
        Translation.AddContent(Pass[Rnd.Random(Pass.Count)])
      else
        Translation.AddContent(Wall[Rnd.Random(Wall.Count)]);

      Translation.Translation := Vector3(ix * 2 * Scale, 0, iy * 2 * Scale);
      Translation.Rotation := Vector4(0, 1, 0, Pi / 2 * Rnd.Random(4));
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

  Wall.Free;
  Pass.Free;
  Border.Free;
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

procedure TLocationGenerator.ClearMap(const aValue: TMapItem);
var
  ix, iy: integer;
begin
  for ix := 0 to MapSizeX - 1 do
    for iy := 0 to MapSizeY - 1 do
      Map[ix, iy] := aValue;
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

procedure TLocationGenerator.FloodWallBlocks;
var
  ix, iy: integer;
  tmpMap: TMap;
begin
  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do begin
      tmpMap[ix, iy] := 0;
      if Map[ix, iy] = 1 then
      begin
        if (Map[ix - 1, iy] = 1) and (Map[ix + 1, iy] = 1) and
           (Map[ix, iy - 1] = 1) and (Map[ix, iy + 1] = 1) then
          tmpMap[ix, iy] := 1;
      end;
    end;

  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do if tmpMap[ix, iy] = 1 then
      Map[ix, iy] := 0;
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
      if (Rnd.Random < 0.4) then
        Map[ix, iy] := 0
      else
        Map[ix, iy] := 1;

  //make space for player start location
  Map[EntranceX, EntranceY] := 0;

  ProcessWallBlocks;
  ProcessWallDeadends;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeBoxMap;
const
  BlockChance = 0.5;
var
  ix, iy: integer;
  r, r2, rmax, BlockCount: integer;
begin
  ClearMap(0);
  MakeOuterWalls;

  if MapSizeX < MapSizey then
    rmax := MapSizeX div 4 - 1
  else
    rmax := MapSizeY div 4 - 1;

  //make boxes
  for r := 1 to rmax do begin
    r2 := r * 2;
    for ix := r2 to MapSizeX - 1 - r2 do begin
      Map[ix, r2] := 1;
      Map[ix, MapSizeY - 1 - r2] := 1;
    end;
    for iy := r2 to MapSizeY - 1 - r2 do begin
      Map[r2, iy] := 1;
      Map[MapSizeX - 1 - r2, iy] := 1;
    end;
  end;
  //block passages
  for r := 1 to rmax do begin
    r2 := r * 2;
    BlockCount := 0;
    for ix := r2+1 to MapSizeX - 2 - r2 do
      if Rnd.Random < BlockChance then begin
        if BlockCount = 0 then begin
          Map[ix, r2 - 1] := 1;
          BlockCount := 2;
        end
        else
          Dec(BlockCount);
      end;
    BlockCount := 0;
    for ix := r2+1 to MapSizeX - 2 - r2 do
      if Rnd.Random < BlockChance then begin
        if BlockCount = 0 then begin
          Map[ix, MapSizeY - r2] := 1;
          BlockCount := 2;
        end
        else
          Dec(BlockCount);
      end;
    BlockCount := 0;
    for iy := r2+1 to MapSizeY - 2 - r2 do
      if Rnd.Random < BlockChance then begin
        if BlockCount = 0 then begin
          Map[r2 - 1, iy] := 1;
          BlockCount := 2;
        end
        else
          Dec(BlockCount);
      end;
    BlockCount := 0;
    for iy := r2+1 to MapSizeY - 2 - r2 do
      if Rnd.Random < BlockChance then begin
        if BlockCount = 0 then begin
          Map[MapSizeX - r2, iy] := 1;
          BlockCount := 2;
        end
        else
          Dec(BlockCount);
      end;
  end;

  //make space for player start location
  Map[EntranceX, EntranceY] := 0;

  OpenInaccessible;
end;

procedure TLocationGenerator.MakeDrunkenWalkerMap;
var
  mx, my: integer;
  dx, dy: shortint;
  WallHardness: TMap;
  FreeSpace: integer;

  procedure ClearHardnessMap;
  var
    jx, jy: integer;
  begin
    for jx := 0 to MapSizeX - 1 do
      for jy := 0 to MapSizeY - 1 do
        WallHardness[jx, jy] := 1;
  end;
  function CanDig(const ax, ay: integer): boolean;
  begin
    if (ax = 1) or (ay = 1) or (ax = MapSizeX - 1) or (ay = MapSizeY - 1) then
      Result := false
    else
      if isPassable(ax,ay) then
        Result := true
      else
        Result := (Rnd.Random < 0.001) or (Rnd.Random < Sqr(1 / WallHardness[ax, ay]));
  end;
  procedure RandomDirection;
  begin
    if Rnd.RandomBoolean then
    begin
      dy := 0;
      if Rnd.RandomBoolean then
        dx := +1
      else
        dx := -1;
    end
    else
    begin
      dx := 0;
      if Rnd.RandomBoolean then
        dy := +1
      else
        dy := -1;
    end;
  end;
  procedure Dig(const ax, ay: integer);
  begin
    if (dx<>-1) and (not isPassable(ax - 1, ay)) then inc(WallHardness[ax - 1, ay]);
    if (dx<>+1) and (not isPassable(ax + 1, ay)) then inc(WallHardness[ax + 1, ay]);
    if (dy<>-1) and (not isPassable(ax, ay - 1)) then inc(WallHardness[ax, ay - 1]);
    if (dy<>+1) and (not isPassable(ax, ay + 1)) then inc(WallHardness[ax, ay + 1]);
    if not isPassable(ax, ay) then inc(FreeSpace);
    Map[ax, ay] := 0;
    mx := ax;
    my := ay;
  end;
begin
  ClearMap(1);
  ClearHardnessMap;
  FreeSpace := 0;
  mx := EntranceX;
  my := EntranceY;
  Dig(mx, my);
  repeat
    RandomDirection;
    if CanDig(mx + dx, my + dy) then Dig(mx + dx, my + dy);
    if Rnd.Random < 0.01 then begin
      mx := EntranceX;
      my := EntranceY;
    end;
  until FreeSpace > MapArea div 2;
  ProcessWallBlocks;
  //ProcessWallDeadends;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeRotorMap;
const
  RotorLength = 4;
var
  mx, my, ml: integer;
  dx, dy: shortint;
  FreeSpace: integer;
  procedure RandomDirection;
  begin
    if Rnd.RandomBoolean then
    begin
      dy := 0;
      if Rnd.RandomBoolean then
        dx := +1
      else
        dx := -1;
    end
    else
    begin
      dx := 0;
      if Rnd.RandomBoolean then
        dy := +1
      else
        dy := -1;
    end;
  end;
  function CanDig(const ax, ay: integer): boolean;
  begin
    if (ax = 1) or (ay = 1) or (ax = MapSizeX - 1) or (ay = MapSizeY - 1) then
      Result := false
    else
      Result := true
  end;
  procedure Dig(const ax, ay: integer);
  begin
    if not isPassable(ax, ay) then begin
      Map[ax, ay] := 0;
      inc(FreeSpace);
    end;
  end;
  function Rotor(doDig: boolean): boolean;
  var
    mx1, my1: integer;
    i: integer;
    cp, cw: integer;
  begin
    Result := true;
    cp := 0;
    cw := 0;
    mx1 := mx;
    my1 := my;
    for i := 1 to ml do
    begin
      if CanDig(mx1, my1) then
      begin
        if doDig then Dig(mx1, my1);

        if isPassable(mx1, my1) then inc(cp) else inc(cw);
        if isPassable(mx1+1, my1) then inc(cp) else inc(cw);
        if isPassable(mx1-1, my1) then inc(cp) else inc(cw);
        if isPassable(mx1, my1+1) then inc(cp) else inc(cw);
        if isPassable(mx1, my1-1) then inc(cp) else inc(cw);

        mx1 := mx1 + dx;
        my1 := my1 + dy;
      end
      else
        Result := false;
    end;
    //if too many passages around
    if 3 * cp > cw then Result := false;
  end;
begin
  ClearMap(1);
  FreeSpace := 0;
  Dig(EntranceX, EntranceY);
  repeat
    RandomDirection;
    mx := Rnd.Random(MapSizeX - 2) + 1;
    my := Rnd.Random(MapSizeY - 2) + 1;
    ml := Round(sqrt(Rnd.Random * 2) * RotorLength) + 1;
    if Rotor(false) then Rotor(true);
  until FreeSpace > MapArea div 2;
  FloodWallBlocks;
  //ProcessWallDeadends;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeCheckersMap;
var
  ix, iy: integer;
begin
  ClearMap(0);
  MakeOuterWalls;
  for ix := 0 to (MapSizeX) div 3 - 2 do
    for iy := 1 to MapSizeY - 2 do
      Map[3 + ix * 3, iy] := 1;
  for iy := 0 to (MapSizeY) div 3 - 2 do
    for ix := 1 to MapSizeX - 2 do
      Map[ix, 3 + iy * 3] := 1;
  Map[EntranceX, EntranceY] := 0;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeDenseCheckersMap;
var
  ix, iy: integer;
begin
  ClearMap(0);
  MakeOuterWalls;
  for ix := 0 to (MapSizeX) div 2 - 2 do
    for iy := 1 to MapSizeY - 2 do
      Map[3 + ix * 2, iy] := 1;
  for iy := 0 to (MapSizeY) div 2 - 2 do
    for ix := 1 to MapSizeX - 2 do
      Map[ix, 3 + iy * 2] := 1;
  Map[EntranceX, EntranceY] := 0;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeTwistyMap;
const
  OpenChance = 0.4;
var
  ix, iy: integer;
begin
  ClearMap(0);
  MakeOuterWalls;
  for ix := 0 to (MapSizeX) div 4 - 1 do
    for iy := 1 to MapSizeY - 2 do
      Map[4 + ix * 4, iy] := 1;
  for iy := 0 to (MapSizeY) div 4 - 1 do
    for ix := 1 to MapSizeX - 2 do
      Map[ix, 4 + iy * 4] := 1;

  //put columns
  for ix := 0 to (MapSizeX) div 4 - 1 do
    for iy := 0 to (MapSizeY) div 4 - 1 do
      Map[2 + ix * 4, 2 + iy * 4] := 1;

  //open passages
  for ix := 0 to (MapSizeX) div 4 - 1 do
    for iy := 0 to (MapSizeY) div 4 - 1 do begin
      if (Rnd.Random < OpenChance) and (4 + ix * 4 < MapSizeX - 3) then
        Map[4 + ix * 4, 2 + iy * 4] := 0;
      if (Rnd.Random < OpenChance) and (4 + iy * 4 < MapSizeY - 3) then
        Map[2 + ix * 4, 4 + iy * 4] := 0;
      if (Rnd.Random < OpenChance) and (ix > 0) then
        Map[ix * 4, 2 + iy * 4] := 0;
      if (Rnd.Random < OpenChance) and (iy > 0) then
        Map[2 + ix * 4, iy * 4] := 0;
    end;
  Map[EntranceX, EntranceY] := 0;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakeBlockyMap;
var
  mx, my: integer;
  ix, iy: integer;
  sx, sy: integer;
  flg: boolean;
  FreeSpace: integer;
  Count: integer;
begin
  ClearMap(1);
  MakeOuterWalls;
  Count := 0;
  FreeSpace := 0;
  repeat
    inc(Count);
    mx := Rnd.Random(MapSizeX - 2) + 1;
    my := Rnd.Random(MapSizeY - 2) + 1;
    sx := Round(sqr(Rnd.Random)*5) + 1;
    sy := Round(sqr(Rnd.Random)*5) + 1;
    flg := true;
    for ix := - 1 to sx + 1 do
      for iy :=  - 1 to sy + 1 do
        if ((ix <> -1) or (iy <> -1)) and
           ((ix <> sx + 1) or (iy <> -1)) and
           ((ix <> -1) or (iy <> sy + 1)) and
           ((ix <> sx + 1) or (iy <> sy + 1)) then
          if isPassable(mx + ix, my + iy) then begin
            flg := false;
            Break;
          end;
    if flg then
      for ix := mx to mx + sx do if ix < MapSizeX - 1 then
        for iy := my to my + sy do if iy < MapSizeY - 1 then
        begin
          inc(FreeSpace);
          Map[ix, iy] := 0;
        end;
  until (FreeSpace > MapArea div 2) or (Count > 10*Sqr(MapArea));
  Map[EntranceX, EntranceY] := 0;
  FloodWallBlocks;
  OpenInaccessible;
end;

procedure TLocationGenerator.MakePixelgrowMap;
var
  mx, my: integer;
  FreeSpace, Count: integer;
  c: integer;
begin
  ClearMap(1);
  FreeSpace := 0;
  Count := 0;
  repeat
    inc(Count);
    mx := Rnd.Random(MapSizeX - 2) + 1;
    my := Rnd.Random(MapSizeY - 2) + 1;
    if not isPassable(mx, my) then begin
      c := 0;
      if not isPassable(mx + 1, my) then
        inc(c);
      if not isPassable(mx - 1, my) then
        inc(c);
      if not isPassable(mx, my + 1) then
        inc(c);
      if not isPassable(mx, my - 1) then
        inc(c);
      if (c = 3) or ((c = 4) and ((Rnd.Random < 0.1)) or (FreeSpace < 5))  then
      begin
        Map[mx, my] := 0;
        inc(FreeSpace);
      end;
    end;
  until (FreeSpace > MapArea div 2) or (Count > 100*Sqr(MapArea));
  Map[EntranceX, EntranceY] := 0;
  //FloodWallBlocks;
  ProcessWallBlocks;
  //ProcessWallDeadends;
  OpenInaccessible;
end;

{//not working as expected
procedure TLocationGenerator.MakeSineMap;
const
  Harmoniques = 3;
var
  i: integer;
  ix, iy: integer;
  Amp, wx, wy, Phase: array[1..Harmoniques] of single;
  maxSine, minSine: single;
  s: single;
  function Sine(const ax, ay: integer): single;
  var j: integer;
  begin
    Result := 0;
    for j := 1 to Harmoniques do
      Result += Amp[j] * (Sin(wx[j] * ax + wy[j] * ay + Phase[j]));
    Result := (Result);
  end;
begin
  for i := 1 to Harmoniques do begin
    Amp[i] := 1 + Rnd.Random;
    wx[i] := ((1 + Rnd.Random) / 9);
    if Rnd.RandomBoolean then wx[i] := -wx[i];
    wy[i] := ((1 + Rnd.Random) / 9);
    if Rnd.RandomBoolean then wy[i] := -wy[i];
    Phase[i] := Rnd.Random * 2 * Pi;
  end;

  maxSine := -1000;
  minSine := 1000;
  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do begin
      s := Sine(ix, iy);
      if s > maxSine then
        maxSine := s;
      if s < minSine then
        minSine := s;
    end;

  for ix := 1 to MapSizeX - 2 do
    for iy := 1 to MapSizeY - 2 do
    begin
      s := (Sine(ix, iy) - minSine) / (maxSine - minSine);
      if ((s > 0.1) and (s < 0.2)) or ((s > 0.4) and (s < 0.5)) or
        ((s > 0.7) and (s < 0.8)) then
        Map[ix, iy] := 0
      else
        Map[ix, iy] := 1;
    end;

  MakeOuterWalls;
  Map[EntranceX, EntranceY] := 0;
  FloodWallBlocks;
  //ProcessWallDeadends;
  OpenInaccessible;
end;}


procedure TLocationGenerator.MakeMap(const aLocation: TLocation);
begin
  CurrentLocation := aLocation;

  {get accessible area}
  ClearFloodFill;

  {do the core map generation}
  case CurrentLocation of
    LGraveyard: MakeRandomMap;
    LMausoleum: MakeBoxMap;
    LForest: MakeDrunkenWalkerMap;
    LCatacomb: MakeRotorMap;
    LCheckers: MakeCheckersMap;
    LBlocky: MakeBlockyMap;
    LMaze: MakeDenseCheckersMap;
    LTwisty: MakeTwistyMap;
    //LCave: MakeSineMap;
    LDeepForest: MakePixelgrowMap;
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

