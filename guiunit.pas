{ Copyright (C) 2012-2017 Yevhen Loza

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <http://www.gnu.org/licenses/>. }

{ --------------------------------------------------------------------------- }

(* Draws GUI *)

unit GUIUnit;

{$mode objfpc}{$H+}

interface

uses
  CastleGLImages, CastleImages, Classes, SysUtils, CastleWindow, CastleScene, CastleControls, CastleLog,
  CastleFilesUtils, CastleKeysMouse;

type

  { TMapImage }

  TMapImage = class(TObject)
  strict private
    GLMapImage: TGLImage;
  public
    procedure Update;
    procedure Draw;
    destructor Destroy; override;
  end;

  { TFrame }

  TFrame = class(TObject)
  strict private
    FLeft: Integer;
    FTop: Integer;
    FImage: TGLImage;
    FActImage: TGLImage;
    FHeroImage: TGLImage;
    FLifeBarImage: TGLImage;
    FManaBarImage: TGLImage;
  public
    constructor Create(ALeft, ATop: Integer);
    procedure Draw(const N: Integer; const IsDrawActiveFrame: Boolean);
    destructor Destroy; override;
  end;

  { TGUI }

  TGUI = class(TComponent)
  strict private
    Frame: array [0 .. 3] of TFrame;
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
  WindowUnit, MapUnit, PlayerUnit, EntityUnit;

var
  SLeft, SWidth: Integer;

  { TFrame }

constructor TFrame.Create(ALeft, ATop: Integer);
begin
  FLeft := ALeft;
  FTop := ATop;
  FImage := TGLImage.Create(ApplicationData('gui\Frame.png'));
  FActImage := TGLImage.Create(ApplicationData('gui\ActFrame.png'));
  FHeroImage := TGLImage.Create(ApplicationData('heroes\1.png'));
  FLifeBarImage := TGLImage.Create(ApplicationData('gui\LifeBar.png'));
  FManaBarImage := TGLImage.Create(ApplicationData('gui\ManaBar.png'));
  SWidth := FImage.Width;
end;

procedure TFrame.Draw(const N: Integer; const IsDrawActiveFrame: Boolean);
begin
  if IsDrawActiveFrame then
    FActImage.Draw(SLeft + FLeft, FTop)
  else
    FImage.Draw(SLeft + FLeft, FTop);
  FHeroImage.Draw(SLeft + FLeft + 14, FTop + 14);
  FLifeBarImage.Draw3x3(SLeft + FLeft + 14, FTop + 114 + 5,
    Round(Player.Hero[N].Stat[stHP].Cur / Player.Hero[N].Stat[stHP].Max * 100), 5, 0, 0, 0, 0);
  FManaBarImage.Draw3x3(SLeft + FLeft + 14, FTop + 114,
    Round(Player.Hero[N].Stat[stMP].Cur / Player.Hero[N].Stat[stMP].Max * 100), 5, 0, 0, 0, 0);
end;

destructor TFrame.Destroy;
begin
  FreeAndNil(FManaBarImage);
  FreeAndNil(FLifeBarImage);
  FreeAndNil(FHeroImage);
  FreeAndNil(FActImage);
  FreeAndNil(FImage);
  inherited Destroy;
end;

{ TMapImage }

procedure TMapImage.Draw;
begin
  if GLMapImage <> nil then
    GLMapImage.Draw(0, 0)
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
  FreeAndNil(Minimap); // temp
  inherited Destroy;
end;

{ TGUI }

procedure TGUI.Draw;
var
  N: Integer;
begin
  // MapImage.Draw;
  for N := 0 to 3 do
    Frame[N].Draw(N, Player.Active = N);
end;

procedure TGUI.Resize;
begin
  SLeft := (Window.Width div 2) - (SWidth * 2);
end;

constructor TGUI.Create(aOwner: TComponent);
var
  N: Integer;
begin
  inherited Create(aOwner);
  MapImage := TMapImage.Create;
  for N := 0 to 3 do
    Frame[N] := TFrame.Create(N * SWidth, 0);
end;

destructor TGUI.Destroy;
var
  N: Integer;
begin
  for N := 0 to 3 do
    FreeAndNil(Frame[N]);
  FreeAndNil(MapImage);
  inherited Destroy;
end;

end.
