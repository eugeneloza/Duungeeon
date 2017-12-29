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

{ main file }

program Duungeeon;

uses
  SysUtils,
  CastleWindow, CastleSceneCore, CastleScene, CastleLog, CastleFilesUtils,
  X3DLoad, X3DNodes, CastleRandom, CastleVectors, CastleCameras,
  CastleKeysMouse, MyLoad3D, worldunit;

const
  MapSizeX = 30;
  MapSizeY = 30;
  Scale = 10;
  ScaleY = 5;

type TDir = (dSouth, dWest, dNorth, dEast);

type TPlayer = record
  Dir: TDir;
  x, y: integer;
end;

var
  Window: TCastleWindow;
  Scene: TCastleScene;
  Map: array [0..MapSizeX-1, 0..MapSizeY-1] of byte;
  Camera: TWalkCamera;
  Player: TPlayer;
  South, West, North, East: TVector3;


function GetDirection(a: TDir): TVector3;
begin
  case a of
    dSouth: Result := South;
    dEast: Result := East;
    dWest: Result := West;
    dNorth: Result := North;
  end;
end;

procedure doPress(Container: TUIContainer; const Event: TInputPressRelease);
  procedure Move(Fwd: shortint);
  var dx, dy: shortint;
  begin
    dx := 0;
    dy := 0;
    Case Player.Dir of
      dSouth: dx := 1;
      dNorth: dx := -1;
      dWest: dy := 1;
      dEast: dy := -1;
    end;
    dx := dx * Fwd;
    dy := dy * Fwd;
    if Map[Player.X + dx, Player.Y + dy] = 0 then begin
      Player.X += dx;
      Player.Y += dy;
      Camera.Position := Camera.Position + Fwd * Camera.Direction * Scale * 2;
    end;
  end;
  procedure Rotate(CCW: boolean);
  begin
    if CCW then
    begin
      case Player.Dir of
        dEast: Player.Dir := dNorth;
        dNorth: Player.Dir := dWest;
        dWest: Player.Dir := dSouth;
        dSouth: Player.Dir := dEast;
      end;
    end
    else
    begin
      case Player.Dir of
        dEast: Player.Dir := dSouth;
        dNorth: Player.Dir := dEast;
        dWest: Player.Dir := dNorth;
        dSouth: Player.Dir := dWest;
      end;
    end;
    Camera.Direction := GetDirection(Player.Dir);
  end;
begin
  if Event.EventType = itKey then begin
    case Event.Key of
      k_W: Move(1);
      k_S: Move(-1);
      k_A: Rotate(true);
      k_D: Rotate(false);
    end;
  end;
end;

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

begin
  InitializeLog('0', nil, ltTime);
  Window := TCastleWindow.Create(Application);
  Window.DoubleBuffer := True;
  Window.OnPress := @doPress;
  Application.MainWindow := Window;
  PrepareScene;
  Window.OpenAndRun;
end.

