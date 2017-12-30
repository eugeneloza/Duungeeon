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

(* Constructs and manages the world *)

unit WorldUnit;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, CastleWindow, CastleSceneCore, CastleScene,
  CastleLog, X3DNodes, CastleVectors;

var
  Scene: TCastleScene;

procedure PrepareScene;
implementation

uses
  WindowUnit, PlayerUnit, MapUnit;

procedure PrepareScene;
var
  GenerationNode: TX3DRootNode;
  Nav: TNavigationInfoNode;
  Viewport: TViewpointNode;
begin
  Player := TPlayer.Create;

  Scene := TCastleScene.Create(Application);
  Scene.Spatial := [ssRendering, ssDynamicCollisions];
  Scene.ProcessEvents := true;

  Location := TLocationGenerator.Create;
  Location.EntranceX := MapSizeX div 2;
  Location.EntranceY := MapSizeY div 2;
  Location.MakeMap(LGraveyard);
  GenerationNode := Location.MakeRoot;
  Minimap := Location.MakeMinimap;
  Player.Teleport(Location.EntranceX, Location.EntranceY, South);
  Location.Free;

  Nav := TNavigationInfoNode.Create;
  Nav.FdHeadlight.Value := false;
  GenerationNode.FdChildren.Add(Nav);

  Viewport := TViewpointNode.Create;
  Viewport.FieldOfView := 0.8;
  GenerationNode.FdChildren.Add(Viewport);

  Scene.Load(GenerationNode, true);

  Window.SceneManager.Items.Add(Scene);
  Window.SceneManager.MainScene := Scene;
  Window.SceneManager.Camera := Player.Camera;
end;

end.

