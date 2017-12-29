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
  X3DLoad, X3DNodes, CastleRandom, CastleVectors,

  PlayerUnit;

const
  MapSizeX = 30;
  MapSizeY = 30;
  Scale = 10;
  ScaleY = 5;

var
  Window: TCastleWindow;
  Scene: TCastleScene;
  Map: array [0..MapSizeX-1, 0..MapSizeY-1] of byte;

procedure PrepareScene;
implementation

procedure GenerateMaze(var Root: TX3DRootNode);
var
  Box: TX3DRootNode;
  Pass: TX3DRootNode;
  Translation: TTransformNode;
  Rnd: TCastleRandom;

  ix, iy: integer;
begin
  Box := LoadBlenderX3D(ApplicationData('Box.x3d'));
  Pass := LoadBlenderX3D(ApplicationData('Pass.x3d'));
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
  Player.X := MapSizeX div 2;
  Player.Y := MapSizeY div 2;
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
begin
  South := Vector3(1,0,0);
  North := Vector3(-1,0,0);
  East := Vector3(0,0,-1);
  West := Vector3(0,0,1);

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

  Scene.Load(GenerationNode, true);

  Camera := TWalkCamera.Create(Window);
  Camera.PreferredHeight := 1 * ScaleY;
  Camera.Position := Vector3(Player.X*2*Scale,
    Camera.PreferredHeight-1*ScaleY, Player.Y*2*Scale);
  Player.Dir := dSouth;
  Camera.Direction := GetDirection(Player.Dir);
  Camera.FallingEffect := false;
  Camera.Input := [];
{  Camera.MoveSpeed := 10;
  Camera.MouseLookHorizontalSensitivity := 1;
  Camera.MouseLook := true;}

  Window.SceneManager.Items.Add(Scene);
  Window.SceneManager.MainScene := Scene;
  Window.SceneManager.Camera := Camera;
end;

end.

