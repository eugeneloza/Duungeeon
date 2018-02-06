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

(* Entities *)

unit EntityUnit;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TStatEnum = (stHP, stMP);

type
  TStateEnum = (stAlive, stDead);

  { TStat }

type
  TStat = class(TObject)
  strict private
    FCur: Integer;
    FMax: Integer;
    FPrm: Integer;
    FTmp: Integer;
    procedure SetCur(Value: Integer);
    function GetCur: Integer;
    procedure SetMax(Value: Integer = 0);
    function GetMax: Integer;
    procedure SetPrm(Value: Integer);
    function GetPrm: Integer;
    procedure SetTmp(Value: Integer);
    function GetTmp: Integer;
  public
    constructor Create;
    function IsMin: Boolean;
    function IsMax: Boolean;
    function IsTmp: Boolean;
    procedure Dec(const Value: Integer = 1);
    procedure Inc(const Value: Integer = 1);
    property Cur: Integer read GetCur write SetCur;
    property Max: Integer read GetMax write SetMax;
    property Prm: Integer read GetPrm write SetPrm;
    property Tmp: Integer read GetTmp write SetTmp;
    function ToString: string;
    procedure ToMin;
    procedure ToMax;
  end;

  { TEntity }

type
  TEntity = class(TObject)
  strict private
    FLevel: Integer;
    FStat: array [TStatEnum] of TStat;
    function GetStat(const AStat: TStatEnum): TStat;
    procedure SetStat(const AStat: TStatEnum; const Value: TStat);
  public
    constructor Create;
    destructor Destroy; override;
    property Stat[const AStat: TStatEnum]: TStat read GetStat write SetStat;
    property Level: Integer read FLevel write FLevel;
  end;

  { THero }

type
  THero = class(TEntity)
  strict private
    FID: Integer;
    FExp: Integer;
    FState: TStateEnum;
    FName: string;
  public
    constructor Create;
    destructor Destroy; override;
    function AddExp(const AExp: Integer): Boolean;
    function GetNextLevelExp: Integer;
    function ExpToString: string;
    property ID: Integer read FID write FID;
    property Exp: Integer read FExp;
    property State: TStateEnum read FState write FState;
    property Name: string read FName write FName;
  end;

  { TParty }

type
  TParty = class(TObject)
  strict private
    FActive: Integer;
    FHero: array [0 .. 3] of THero;
    function GetHero(N: Integer): THero;
    procedure SetHero(N: Integer; Value: THero);
  public
    constructor Create;
    destructor Destroy; override;
    property Active: Integer read FActive write FActive;
    property Hero[N: Integer]: THero read GetHero write SetHero;
    procedure AddHero(N: Integer; const HeroID: Integer);
    function Damage(N: Integer; const Value: Integer): Boolean;
    procedure Cure(N: Integer; const Value: Integer);
  end;

implementation

{ TStat }

constructor TStat.Create;
begin
  FCur := 1;
  FMax := 1;
  FPrm := 0;
  FTmp := 0;
end;

procedure TStat.Dec(const Value: Integer);
begin
  if ((FCur > 0) and (Value > 0)) then
    SetCur(GetCur - Value);
  if (FCur < 0) then
    FCur := 0;
end;

function TStat.GetPrm: Integer;
begin
  Result := FPrm;
end;

procedure TStat.SetTmp(Value: Integer);
begin
  FTmp := Value;
  SetMax;
end;

function TStat.GetTmp: Integer;
begin
  Result := FTmp;
end;

function TStat.GetCur: Integer;
begin
  Result := FCur;
end;

function TStat.GetMax: Integer;
begin
  Result := FMax;
end;

procedure TStat.Inc(const Value: Integer);
begin
  if ((FCur < FMax) and (Value > 0)) then
    SetCur(GetCur + Value);
  if (FCur > FMax) then
    FCur := FMax;
end;

function TStat.IsMax: Boolean;
begin
  Result := FCur >= FMax
end;

function TStat.IsTmp: Boolean;
begin
  Result := FTmp > 0
end;

function TStat.IsMin: Boolean;
begin
  Result := FCur <= 0
end;

procedure TStat.SetPrm(Value: Integer);
begin
  FPrm := Value;
  SetMax;
end;

procedure TStat.SetCur(Value: Integer);
begin
  if (Value < 0) then
    Value := 0;
  if (Value > FMax) then
    Value := FMax;
  FCur := Value;
end;

procedure TStat.SetMax(Value: Integer);
begin
  if (Value < 0) then
    Value := 0;
  FMax := Value + FPrm + FTmp;
  if (FCur >= FMax) then
    ToMax;
end;

procedure TStat.ToMax;
begin
  FCur := FMax;
end;

procedure TStat.ToMin;
begin
  FCur := 0;
end;

function TStat.ToString: string;
begin
  Result := IntToStr(FCur) + '/' + IntToStr(FMax);
end;

{ TEntity }

function TEntity.GetStat(const AStat: TStatEnum): TStat;
begin
  Result := FStat[AStat];
end;

procedure TEntity.SetStat(const AStat: TStatEnum; const Value: TStat);
begin
  FStat[AStat] := Value
end;

constructor TEntity.Create;
var
  I: TStatEnum;
begin
  FLevel := 1;
  for I := Low(TStatEnum) to High(TStatEnum) do
    FStat[I] := TStat.Create;
end;

destructor TEntity.Destroy;
var
  I: TStatEnum;
begin
  for I := Low(TStatEnum) to High(TStatEnum) do
    FreeAndNil(FStat[I]);
  inherited Destroy;
end;

{ THero }

constructor THero.Create;
begin
  inherited Create;
  FID := 0;
  FExp := 0;
  FName := '';
  State := stAlive;
end;

destructor THero.Destroy;
begin
  inherited Destroy;
end;

function THero.AddExp(const AExp: Integer): Boolean;
begin
  Result := False;
  if (AExp <= 0) then
    Exit;
  Inc(FExp, AExp);
  if (FExp > GetNextLevelExp) then
  begin
    Level := Level + 1;
    Result := True;
  end;
end;

function THero.GetNextLevelExp: Integer;
begin
  Result := (Level * 35) + ((Level - 1) * 15);
end;

function THero.ExpToString: string;
begin
  Result := IntToStr(FExp) + '/' + IntToStr(GetNextLevelExp);
end;

{ TParty }

function TParty.GetHero(N: Integer): THero;
begin
  Result := FHero[N];
end;

procedure TParty.SetHero(N: Integer; Value: THero);
begin
  FHero[N] := Value;
end;

constructor TParty.Create;
var
  N: Integer;
begin
  for N := 0 to 3 do
    FHero[N] := THero.Create;
  FActive := 0;
end;

destructor TParty.Destroy;
var
  N: Integer;
begin
  for N := 0 to 3 do
    FreeAndNil(FHero[N]);
  inherited Destroy;
end;

function TParty.Damage(N: Integer; const Value: Integer): Boolean;
begin
  Result := False;
  with FHero[N] do
  begin
    Stat[stHP].Dec(Value);
    if Stat[stHP].IsMin then
    begin
      State := stDead;
      Result := True;
    end;
  end;
end;

procedure TParty.Cure(N: Integer; const Value: Integer);
begin
  FHero[N].Stat[stHP].Inc(Value);
end;

procedure TParty.AddHero(N: Integer; const HeroID: Integer);
begin
  FHero[N].ID := HeroID;
  FHero[N].Stat[stHP].Max := 100;
  FHero[N].Stat[stHP].ToMax;
  FHero[N].Stat[stMP].Max := 50;
  FHero[N].Stat[stMP].ToMax;
end;

end.
