unit Cex.io.utils;

interface

uses SysUtils,DBXJSON,  Windows, Messages, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

Type

//TCurrency =  (crUSD,crEUR,crGBP,crRUB);
//TCryptoCurrency =  (ccBTC,ccETH,ccBCH,ccDASH,ccZEC,ccGHS);

//status – "d" — done (fully executed), "c" — canceled (not executed), "cd" — cancel-done (partially executed)
//TOrderStatus   = (osDONE,osCANCELLED,osCANCELDONE);
//TOrderType   = (otBUY,otSELL);

TCurrency = Class
const
  USD = 'USD';
  EUR = 'EUR';
  GBP = 'GBP';
  RUB = 'RUB';
end;

TCryptoCurrency = Class
const
  BTC  = 'BTC';
  ETH  = 'ETH';
  BCH  = 'BCH';
  DASH = 'DASH';
  ZEC  = 'ZEC';
  GHS  = 'GHS';
end;

//status – "d" — done (fully executed), "c" — canceled (not executed), "cd" — cancel-done (partially executed)
TOrderStatus = Class
const
  DONE            = 'd';
  CANCELLED       = 'c';
  CANCELDONE      = 'cd';
end;

TOrderType   = Class
const
  BUY  = 'buy';
  SELL = 'sell';
end;


TOrderDetails = Record
_id:String;
_type:String;
_status:String;
_price:String;
end;


TCexUtils = Class
 class var Currency:TCurrency;
 class var CryptoCurrency:TCryptoCurrency;
 class var OrderStatus:TOrderStatus;
 class var OrderType:TOrderType;
end;



function DateTimeToUNIXTimeFAST(DelphiTime : TDateTime): LongWord;
function getValueFromJSonName(aJSONValue:TJSONValue;aName:String):String;
procedure logYaz(aMemo:TMemo;aLog:String);
//function CryptoCurrencyToString(aCryptoCurrency:TCryptoCurrency):String;
//function StringToCryptoCurrency(aString:String):TCryptoCurrency;
//function CurrencyToString(aCurrency:TCurrency):String;
//function StringToCurrency(aString:String):TCurrency;
//function OrderStatusToString(aOrderStatus:TOrderStatus):String;
//function StringToOrderStatus(aString:String):TOrderStatus;
//function OrderTypeToString(aOrderType:TOrderType):String;
//function StringToOrderType(aString:String):TOrderType;


implementation

// 10x faster than dateutils version
function DateTimeToUNIXTimeFAST(DelphiTime : TDateTime): LongWord;
begin
Result := Round((DelphiTime - 25569) * 86400);
end;

//function CryptoCurrencyToString(aCryptoCurrency:TCryptoCurrency):String;
//begin
//  result :='';
//  case aCryptoCurrency of
//  ccBTC  : CryptoCurrencyToString :='BTC';
//  ccETH  : CryptoCurrencyToString :='ETH';
//  ccBCH  : CryptoCurrencyToString :='BCH';
//  ccDASH : CryptoCurrencyToString :='DASH';
//  ccZEC  : CryptoCurrencyToString :='ZEC';
//  ccGHS  : CryptoCurrencyToString :='GHS';
//  end;
//end;
//
//function StringToCryptoCurrency(aString:String):TCryptoCurrency;
//begin
//
//  if aString = 'BTC'  then StringToCryptoCurrency :=ccBTC  else
//  if aString = 'ETH'  then StringToCryptoCurrency :=ccETH  else
//  if aString = 'BCH'  then StringToCryptoCurrency :=ccBCH  else
//  if aString = 'DASH' then StringToCryptoCurrency :=ccDASH else
//  if aString = 'ZEC'  then StringToCryptoCurrency :=ccZEC  else
//  if aString = 'GHS'  then StringToCryptoCurrency :=ccGHS;
//end;
//
//function CurrencyToString(aCurrency:TCurrency):String;
//begin
//  result :='';
//  case aCurrency of
//  crUSD  : CurrencyToString :='USD';
//  crEUR  : CurrencyToString :='EUR';
//  crGBP  : CurrencyToString :='GBP';
//  crRUB  : CurrencyToString :='RUB';
//  end;
//end;
//
//function StringToCurrency(aString:String):TCurrency;
//begin
//
//  if aString = 'USD'  then StringToCurrency :=crUSD  else
//  if aString = 'EUR'  then StringToCurrency :=crEUR  else
//  if aString = 'GBP'  then StringToCurrency :=crGBP  else
//  if aString = 'DASH' then StringToCurrency :=crRUB;
//end;
//
//function OrderStatusToString(aOrderStatus:TOrderStatus):String;
//begin
//  result :='';
//  case aOrderStatus of
//  osDONE        : OrderStatusToString :='d';
//  osCANCELLED   : OrderStatusToString :='c';
//  osCANCELDONE  : OrderStatusToString :='cd';
//  end;
//end;
//
//function StringToOrderStatus(aString:String):TOrderStatus;
//begin
//  if aString = 'd'  then StringToOrderStatus  :=osDONE       else
//  if aString = 'c'  then StringToOrderStatus  :=osCANCELLED  else
//  if aString = 'cd'  then StringToOrderStatus :=osCANCELDONE
//end;
//
//function OrderTypeToString(aOrderType:TOrderType):String;
//begin
//  result :='';
//  case aOrderType of
//  otBUY        : OrderTypeToString :='buy';
//  otSELL       : OrderTypeToString :='sell';
//  end;
//end;
//
//function StringToOrderType(aString:String):TOrderType;
//begin
//  if aString = 'buy'   then StringToOrderType  :=otBUY       else
//  if aString = 'cell'  then StringToOrderType  :=otSELL;
//end;

function getValueFromJSonName(aJSONValue:TJSONValue;aName:String):String;
var
vJSONPair:TJSONPair;
JSONObject:TJSONObject;
strTemp:String;
i:integer;
encoder:TEncoding;
begin
  result :='';
  JSONObject := nil;
  encoder :=TEncoding.Create;
  try
    JSONObject     := TJSONObject.ParseJSONValue(encoder.ASCII.GetBytes(aJSONValue.ToString), 0) as TJSONObject;
    for I := 0 to JSONObject.Size - 1 do
    begin
       vJSONPair := JSONObject.Get(i);
       strTemp := trim(vJSONPair.JsonString.ToString);
       strTemp := StringReplace(strTemp,'"','',[rfReplaceAll]);
       if strTemp = aName then
       begin
         strTemp := trim(vJSONPair.JsonValue.ToString);
         strTemp := StringReplace(strTemp,'"','',[rfReplaceAll]);
         Result :=strTemp;
         Break;
       end;
    end;
  except on E: Exception do
  end;
  FreeAndNil(encoder);
  FreeAndNil(JSONObject);
end;

procedure logYaz(aMemo:TMemo;aLog:String);
begin
 aMemo.Lines.Add(DateTimeToStr(now) + '-->'+ aLog);
 aMemo.Lines.SaveToFile('cex.log');
end;

end.
