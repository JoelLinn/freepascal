{
   This file is part of the Free Pascal FCL library.
   BSD parts (c) 2011 Vlado Boza

   See the file COPYING.FPC, included in this distribution,
   for details about the copyright.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY;without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

**********************************************************************}
{$mode objfpc}

unit gdeque;

interface

type
  generic TDeque<T>=class
  private
  type
    PT=^T;
    TArr=array of T;
  var
    FData:TArr;
    FDataSize:SizeUInt;
    FCapacity:SizeUInt;
    FStart:SizeUInt;
    procedure SetValue(position:SizeUInt; value:T);inline;
    function GetValue(position:SizeUInt):T;inline;
    function GetMutable(position:SizeUInt):PT;inline;
    procedure IncreaseCapacity();
  public
    function Size():SizeUInt;inline;
    constructor Create();
    Procedure  Clear;
    procedure PushBack(value:T);inline;
    procedure PushFront(value:T);inline;
    procedure PopBack();inline;
    procedure PopFront();inline;
    function Front():T;inline;
    function Back():T;inline;
    function IsEmpty():boolean;inline;
    procedure Reserve(cap:SizeUInt);inline;
    procedure Resize(cap:SizeUInt);inline;
    procedure Insert(Position:SizeUInt; Value:T);inline;
    procedure Erase(Position:SIzeUInt);inline;
    property Items[i : SizeUInt]: T read GetValue write SetValue; default;
    property Mutable[i : SizeUInt]:PT read GetMutable;
end;

implementation

constructor TDeque.Create();
begin
  FDataSize:=0;
  FCapacity:=0;
  FStart:=0;
end;

procedure TDeque.Clear;
begin
 FDataSize:=0;
 FStart:=0;
end;

function TDeque.Size():SizeUInt;inline;
begin
  Size:=FDataSize;
end;

function TDeque.IsEmpty():boolean;inline;
begin
  IsEmpty:=Size()=0;
end;

procedure TDeque.PushBack(value:T);inline;
begin
  if(FDataSize=FCapacity) then
    IncreaseCapacity;
  FData[(FStart+FDataSize)mod FCapacity]:=value;
  inc(FDataSize);
end;

procedure TDeque.PopFront();inline;
begin
  if(FDataSize>0) then
  begin
    inc(FStart);
    dec(FDataSize);
    if(FStart=FCapacity) then
      FStart:=0;
  end;
end;

procedure TDeque.PopBack();inline;
begin
  if(FDataSize>0) then
    dec(FDataSize);
end;

procedure TDeque.PushFront(value:T);inline;
begin
  if(FDataSize=FCapacity) then
    IncreaseCapacity;
  if(FStart=0) then
    FStart:=FCapacity-1
  else
    dec(FStart);
  FData[FStart]:=value;
  inc(FDataSize);
end;

function TDeque.Front():T;inline;
begin
  Assert(size > 0, 'Accessing empty deque');
  Front:=FData[FStart];
end;

function TDeque.Back():T;inline;
begin
  Assert(size > 0, 'Accessing empty deque');
  Back:=FData[(FStart+FDataSize-1)mod FCapacity];
end;

procedure TDeque.SetValue(position:SizeUInt; value:T);inline;
begin
  Assert(position < size, 'Deque access out of range');
  FData[(FStart+position)mod FCapacity]:=value;
end;

function TDeque.GetValue(position:SizeUInt):T;inline;
begin
  Assert(position < size, 'Deque access out of range');
  GetValue:=FData[(FStart+position) mod FCapacity];
end;

function TDeque.GetMutable(position:SizeUInt):PT;inline;
begin
  Assert(position < size, 'Deque access out of range');
  GetMutable:=@FData[(FStart+position) mod FCapacity];
end;

procedure TDeque.IncreaseCapacity;
  function Min(const A,B: SizeUInt): SizeUInt; inline; //no need to drag in the entire Math unit ;-)
  begin
    if (A<B) then
      Result:=A
    else
      Result:=B;
  end;
const
  // if size is small, multiply by 2;
  // if size bigger but <256M, inc by 1/8*size;
  // otherwise inc by 1/16*size
  cSizeSmall = 1*1024*1024;
  cSizeBig = 256*1024*1024;
var
  i,OldEnd,
  DataSize,CurLast,EmptyElems,Elems:SizeUInt;
begin
  OldEnd:=FCapacity;
  DataSize:=FCapacity*SizeOf(T);
  if FCapacity=0 then
    FCapacity:=4
  else
  if DataSize<cSizeSmall then
    FCapacity:=FCapacity*2
  else
  if DataSize<cSizeBig then
    FCapacity:=FCapacity+FCapacity div 8
  else
    FCapacity:=FCapacity+FCapacity div 16;
  SetLength(FData, FCapacity);
  if (FStart>0) then
  begin
    if (FCapacity-OldEnd>=FStart) then //we have room to move all items in one go
    begin
      if IsManagedType(T) then
        for i:=0 to FStart-1 do
          FData[OldEnd+i]:=FData[i]
      else
        Move(FData[0], FData[OldEnd], FStart*SizeOf(T));
    end
    else
    begin  //we have to move things around in chunks: we have more data in front of FStart than we have newly created unused elements
      CurLast := OldEnd-1;
      EmptyElems:=FCapacity-1-CurLast;
      while (FStart>0) do
      begin
        Elems:=Min(EmptyElems, FStart);
        for i:=0 to Elems-1 do
          FData[CurLast+1+i]:=FData[i];
        for i := 0 to FCapacity-Elems-1 do
          FData[i]:=FData[Elems+i];
        Dec(FStart, Elems);
      end;
    end;
  end;
end;

procedure TDeque.Reserve(cap:SizeUInt);inline;
var i,OldEnd:SizeUInt;
begin
  if(cap<FCapacity) then
    exit
  else if(cap<=2*FCapacity) then
    IncreaseCapacity
  else
  begin
    OldEnd:=FCapacity;
    FCapacity:=cap;
    SetLength(FData, FCapacity);
    if FStart > 0 then
      for i:=0 to FStart-1 do
        FData[OldEnd+i]:=FData[i];
  end;
end;

procedure TDeque.Resize(cap:SizeUInt);inline;
begin
  Reserve(cap);
  FDataSize:=cap;
end;

procedure TDeque.Insert(Position:SizeUInt; Value: T);inline;
var i:SizeUInt;
begin
  pushBack(Value);
  for i:=Size-1 downto Position+1 do
  begin
    Items[i]:=Items[i-1];
  end;
  Items[Position]:=Value;
end;

procedure TDeque.Erase(Position:SizeUInt);inline;
var i:SizeUInt;
begin
  if Position <= Size then
  begin
    if Size > 1 then
      for i:=Position to Size-2 do
      begin
        Items[i]:=Items[i+1];
      end;
    popBack();
  end;
end;


end.
