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

(* Draws GUI *)

unit GUIUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleGLImages, CastleImages,
  Classes, SysUtils, CastleWindow, CastleScene, CastleControls, CastleLog,
  CastleFilesUtils, CastleKeysMouse;

type
  TMapImage = class(TObject)
  strict private
    GLMapImage: TGLImage;
  public
    procedure Update;
    procedure Draw;
    destructor Destroy; override;
  end;

type

  { TGUI }

  TGUI = class (TComponent)
  public
    MapImage: TMapImage;
    procedure Draw;
    procedure Resize;
    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  GUI: TGUI;

implementation

uses
  WindowUnit, MapUnit;

var
  ImageWithBorders: array [0..3] of TGLImage;
  Left: Integer;

procedure TMapImage.Draw;
begin
  if GlMapImage <> nil then
    GlMapImage.Draw(0,0)
  else
    Update;
end;

procedure TMapImage.Update;
var
  tmpImage: TRGBAlphaImage;
begin
  if Minimap <> nil then
  begin
    tmpImage := Minimap.MakeCopy as TRGBAlphaImage;
    GLMapImage := TGLImage.Create(tmpImage, true, true);
  end;
end;

destructor TMapImage.Destroy;
begin
  FreeAndNil(GLMapImage);
  FreeAndNil(Minimap); //temp
  inherited Destroy;
end;

procedure TGUI.Draw;
var
  N: Integer;
begin
  //MapImage.Draw;
  for N := 0 to 3 do
    ImageWithBorders[N].Draw(Left + (N * (128 + 8)), 8);
end;

procedure TGUI.Resize;
begin
  Left := (Window.Width div 2) - ((128 * 2) + 8 + (8 div 2));
end;

constructor TGUI.Create(aOwner: TComponent);
var
  N: Integer;
begin
  inherited Create(aOwner);
  MapImage := TMapImage.Create;
  for N := 0 to 3 do
    ImageWithBorders[N] := TGLImage.Create(ApplicationData('gui\box_with_borders.png'));
end;

destructor TGUI.Destroy;
begin
  MapImage.Free;
  inherited Destroy;
end;

end.

