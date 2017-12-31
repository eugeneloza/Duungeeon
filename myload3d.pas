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

{ x3d file loading and basic processing routines.
  The unit name is not good, should change it to something more informative}
unit MyLoad3D;

interface

uses X3DNodes, BlenderCleaner;

function LoadBlenderX3D(const URL: string): TX3DRootNode;
{++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
implementation

uses SysUtils, {StrUtils,} CastleVectors, X3DLoad;

var
  TextureProperties: TTexturePropertiesNode;

procedure MakeDefaultTextureProperties;
begin
  begin
    TextureProperties := TTexturePropertiesNode.Create;
    TextureProperties.AnisotropicDegree := 8;
    TextureProperties.FdMagnificationFilter.Value := 'DEFAULT';
    TextureProperties.FdMinificationFilter.Value := 'DEFAULT';
  end
end;

{-----------------------------------------------------------------------------}

{maybe, a better name would be nice.
 attaches texture properties (anisotropic smoothing) to the texture of the object.
 TODO: Normal map still doesn't work. I should fix it one day...}
procedure AddMaterial(const Root: TX3DRootNode);

  procedure ScanNodesRecoursive(const Source: TAbstractX3DGroupingNode);
  var
    i: integer;
    Material: TMaterialNode;
  begin
    for i := 0 to Source.FdChildren.Count - 1 do
      if Source.FdChildren[i] is TAbstractX3DGroupingNode then
        ScanNodesRecoursive(TAbstractX3DGroupingNode(Source.FdChildren[i]))
      else
      {NOT FOUND exception is a normal error here, it's processed internally,
       set it to "always ignore this type of exceptions"}
      if (Source.FdChildren[i] is TShapeNode) then
        try
          (TShapeNode(Source.FdChildren[i]).fdAppearance.Value.FindNode(
            TImageTextureNode, False) as TImageTextureNode).
          TextureProperties :=
            TextureProperties;
          {create a link to each and every material loaded}
          Material := (TShapeNode(Source.FdChildren[i]).FdAppearance.Value.FindNode(
            TMaterialNode, False) as TMaterialNode);
          Material.AmbientIntensity := 2;
        except
        end;
  end;

begin
  ScanNodesRecoursive(Root);
end;

{---------------------------------------------------------------------------}

function LoadBlenderX3D(const URL: string): TX3DRootNode;
begin
  if TextureProperties = nil then
    MakeDefaultTextureProperties;
  Result := CleanUp(Load3D(URL),true,true);
  AddMaterial(Result);
end;


end.
