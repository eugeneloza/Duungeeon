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

unit GuiUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleGlImages, CastleImages,
  Classes, SysUtils;

type
  TMapImage = class(TObject)
  strict private
    GLMapImage: TGlImage;
  public

    procedure Update;
    procedure Draw;
    destructor Destroy; override;
  end;

type
  TGui = class (TComponent)
  public
    MapImage: TMapImage;

    procedure Draw;

    constructor Create(aOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  GUI: TGui;

implementation

uses
  MapUnit;

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
  FreeAndNil(GlMapImage);
  FreeAndNil(Minimap); //temp
  inherited Destroy;
end;

procedure TGui.Draw;
begin
  MapImage.Draw;
end;

constructor TGui.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  MapImage := TMapImage.Create;
end;

destructor TGui.Destroy;
begin
  MapImage.Free;
  inherited Destroy;
end;

end.

