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

{ Generates the world }

unit WorldUnit;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, MyLoad3D, CastleWindow, CastleSceneCore, CastleScene,
  CastleLog, CastleFilesUtils, CastleCameras,
  X3DLoad, X3DNodes, CastleRandom, CastleVectors;

const
  MapSizeX = 30;
  MapSizeY = 30;

var
  Scene: TCastleScene;
  Map: array [0..MapSizeX-1, 0..MapSizeY-1] of byte;

procedure PrepareScene;
implementation

uses
  WindowUnit, PlayerUnit;

procedure GenerateMaze(var Root: TX3DRootNode);
var
  Box: TX3DRootNode;
  Pass: TX3DRootNode;
  Translation: TTransformNode;
  Rnd: TCastleRandom;

  ix, iy: integer;
begin
  Box := LoadBlenderX3D(ApplicationData('tiles/Box.x3d'));
  Pass := LoadBlenderX3D(ApplicationData('tiles/Pass.x3d'));
  Rnd := TCastleRandom.Create;

  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do
      Map[ix, iy] := Rnd.Random(2);

  //make map borders
  for ix := 0 to MapSizeX-1 do begin
    Map[ix, 0] := 1;
    Map[ix, MapSizeY-1] := 1;
  end;
  for iy := 0 to MapSizeY-1 do begin
    Map[0, iy] := 1;
    Map[MapSizeX-1, iy] := 1;
  end;

  //make space for player start location
  Map[Player.X, Player.Y] := 0;

  {build the scene}

  for ix := 0 to MapSizeX-1 do
    for iy := 0 to MapSizeY-1 do begin
      Translation := TTransformNode.Create;
      case Map[ix, iy] of
        0: Translation.FdChildren.Add(Pass);
        1: Translation.FdChildren.Add(Box);
        else WriteLnLog('Error: unexpected biome in map generation '+ IntToStr(Map[ix, iy]));
      end;
      Translation.Translation := Vector3(ix*2*Scale, 0, iy*2*Scale);
      Translation.Scale := Vector3(Scale, ScaleY, Scale);
      Root.FdChildren.Add(Translation);
    end;

  FreeAndNil(Rnd);
end;

procedure PrepareScene;
var
  GenerationNode: TX3DRootNode;
  Nav: TNavigationInfoNode;
  Viewport: TViewpointNode;
  Background: TBackgroundNode;
begin
  Player := TPlayer.Create;

  Scene := TCastleScene.Create(Application);
  Scene.Spatial := [ssRendering, ssDynamicCollisions];
  Scene.ProcessEvents := true;

  GenerationNode := TX3DRootNode.Create;

  GenerateMaze(GenerationNode);

  Nav := TNavigationInfoNode.Create;
  Nav.FdHeadlight.Value := false;
  GenerationNode.FdChildren.Add(Nav);

  Viewport := TViewpointNode.Create;
  Viewport.FieldOfView := 1.1;
  GenerationNode.FdChildren.Add(Viewport);

  Background := TBackgroundNode.Create;
  Background.FdBackUrl.Items.Add(ApplicationData('skybox/bkg2_back6_CC0_by_StumpyStrust.tga'));
  Background.FdBottomUrl.Items.Add(ApplicationData('skybox/bkg2_bottom4_CC0_by_StumpyStrust.tga'));
  Background.FdFrontUrl.Items.Add(ApplicationData('skybox/bkg2_front5_CC0_by_StumpyStrust.tga'));
  Background.FdLeftUrl.Items.Add(ApplicationData('skybox/bkg2_left2_CC0_by_StumpyStrust.tga'));
  Background.FdRightUrl.Items.Add(ApplicationData('skybox/bkg2_right1_CC0_by_StumpyStrust.tga'));
  Background.FdTopUrl.Items.Add(ApplicationData('skybox/bkg2_top3_CC0_by_StumpyStrust.tga'));

  GenerationNode.FdChildren.Add(Background);

  Scene.Load(GenerationNode, true);

  Window.SceneManager.Items.Add(Scene);
  Window.SceneManager.MainScene := Scene;
  Window.SceneManager.Camera := Player.Camera;
end;

end.

