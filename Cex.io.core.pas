unit Cex.io.core;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,DBXJSON,

  //ICS OverByte
  OverbyteIcsWSocket, OverbyteIcsWndControl, OverbyteIcsHttpProt,

  // hashLibForPascal
  HlpHashFactory, HlpIHash,  HlpIHashInfo,   HlpConverters,

  //indy
  IdGlobal,IdURI,

  //Cex.io
  Cex.io.utils;

Type
  TCexIO = class(TObject)
  private
  fBaseURL:String;
    FProxyPort: Integer;
    FProxyPassword: String;
    FCexIOApiKey: String;
    FProxyUsername: String;
    FProxyServer: String;
    FCexIOUserID: String;
    FCexIOSecretKey: String;
    FSslHttpCli: TSslHttpCli;
    FSslContext: TSslContext;
    FLastNonce:longword;
    procedure SetCexIOApiKey(const Value: String);
    procedure SetCexIOSecretKey(const Value: String);
    procedure SetCexIOUserID(const Value: String);
    procedure SetProxyPassword(const Value: String);
    procedure SetProxyPort(const Value: Integer);
    procedure SetProxyServer(const Value: String);
    procedure SetProxyUsername(const Value: String);
    procedure setSSLComponentSettings();
    procedure initSSLComponents();
    procedure setProxy();
    function  sendRequest(aURL:AnsiString;aParams:AnsiString=''):TJSONValue;
    function getAuthenticationParams():AnsiString;
  protected

  public
    constructor Create;
    destructor Destroy; override;
    //public apis
    function getCexIOCurrencyLimits():TJSONValue;
    function getCexIOTicker(aCryptoCurrency:String;aCurrency:String):TJSONValue;
    function getCexIOLastPrice(aCryptoCurrency:String;aCurrency:String):TJSONValue;
    function getCexIOCovert(aCryptoCurrency:String;aCurrency:String;aAmount:Real):TJSONValue;
    function getCexIOChart(aCryptoCurrency:String;aCurrency:String;aLastHourst:Integer;aMaxRespArrSize:Integer):TJSONValue;
    function getCexIOHCistorical1mOHLCVChart(aCryptoCurrency:String;aCurrency:String;aDate:TDate):TJSONValue;
    function getCexIOOrderBook(aCryptoCurrency:String;aCurrency:String;aDepth:Integer=0):TJSONValue;
    function getCexIOTradeHistory(aCryptoCurrency:String;aCurrency:String;aSince:Integer=0):TJSONValue;

    //private apis
    function getCexIOAccountBalance():TJSONValue;
    function getCexIOOpenOrdersAll():TJSONValue;
    function getCexIOOpenOrders(aCryptoCurrency:String;aCurrency:String):TJSONValue;
    function getCexIOActiveOrderStatus(orders_list:array of String):TJSONValue;
    function getCexIOArchivedOrders(aCryptoCurrency:String;aCurrency:String;aLimit:integer;aDateTo,aDateFrom,aLastTxDateTo,aLastTxDateFrom:TDatetime;aStatus:String):TJSONValue;
    function CexIOCancelOrder(aID:String):TJSONValue;
    function CexIOCancelAllOrdersForGivenPair(aCryptoCurrency:String;aCurrency:String):TJSONValue;
    function CexIOPlaceOrder(aCryptoCurrency:String;aCurrency:String;aType:String;aAmount,aPrice:Real):TJSONValue;
    function CexIOPlaceInstantOrder(aCryptoCurrency:String;aCurrency:String;aType:String;aAmount:Real):TJSONValue;
    function getCexIOOrderDetails(aID:String):TJSONValue;
    function getCexIOOrderTransactions(aID:String):TJSONValue;
    function getCexIOCryptoAddress(aCryptoCurrency:String):TJSONValue;

    property CexIOUserID:String read FCexIOUserID write SetCexIOUserID;
    property CexIOApiKey:String read FCexIOApiKey write SetCexIOApiKey;
    property CexIOSecretKey:String read FCexIOSecretKey write SetCexIOSecretKey;
    property ProxyServer:String read FProxyServer write SetProxyServer;
    property ProxyPort:Integer read FProxyPort write SetProxyPort;
    property ProxyUsername:String read FProxyUsername write SetProxyUsername;
    property ProxyPassword:String read FProxyPassword write SetProxyPassword;
    
  end;


implementation


{ TCexIO }

function TCexIO.CexIOCancelAllOrdersForGivenPair(
  aCryptoCurrency: String; aCurrency: String): TJSONValue;
begin
  result :=nil;

  try
    result :=sendRequest('cancel_orders/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',getAuthenticationParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;

end;

function TCexIO.CexIOCancelOrder(aID: String): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;

  extParams := '&' + 'id=' + (aID);

  try
    result :=sendRequest('cancel_order/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;

end;

function TCexIO.CexIOPlaceInstantOrder(aCryptoCurrency: String;
  aCurrency: String; aType: String; aAmount:Real): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;
  DecimalSeparator :='.';
  extParams := '&'        + 'type='   + (aType)  + '&';
  extParams := extParams  + 'amount=' + FloatToStr(aAmount)       + '&';
  extParams := extParams  + 'order_type=market';

  try
    result :=sendRequest('place_order/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.CexIOPlaceOrder(aCryptoCurrency: String;
  aCurrency: String; aType: String; aAmount, aPrice: Real): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;
  DecimalSeparator :='.';
  extParams := '&'        + 'type='   + (aType)  + '&';
  extParams := extParams  + 'amount=' + FloatToStr(aAmount)       + '&';
  extParams := extParams  + 'price='  + FloatToStr(aPrice);

  try
    result :=sendRequest('place_order/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;

end;

constructor TCexIO.Create;
begin
  inherited;
  fBaseURL :='https://cex.io/api/';
  FSslHttpCli:= TSslHttpCli.Create(nil);
  FSslContext:= TSslContext.Create(nil);
  FLastNonce :=0;
  setSSLComponentSettings;
  initSSLComponents;
end;

destructor TCexIO.Destroy;
begin
  FreeAndNil(FSslHttpCli);
  FreeAndNil(FSslContext);
  inherited;
end;

function TCexIO.getCexIOAccountBalance: TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('balance/',getAuthenticationParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOActiveOrderStatus(
  orders_list: array of String): TJSONValue;
  var
  extParams:AnsiString;
  i:integer;
begin
  result :=nil;
  extParams :='&orders_list[]=';
  for i := Low(orders_list) to High(orders_list) do
      extParams := extParams + orders_list[i]+',';
  delete(extParams,length(extParams),1);

  try
    result :=sendRequest('active_orders_status/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOArchivedOrders(aCryptoCurrency: String;
  aCurrency: String; aLimit: integer; aDateTo, aDateFrom, aLastTxDateTo,
  aLastTxDateFrom: TDatetime; aStatus: String): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;

  extParams := '&'       + 'limit='          + IntToStr(aLimit) + '&';
  extParams := extParams + 'dateTo='         + IntToStr(DateTimeToUNIXTimeFAST(aDateTo))         + '&';
  extParams := extParams + 'dateFrom='       + IntToStr(DateTimeToUNIXTimeFAST(aDateFrom))       + '&';
  extParams := extParams + 'lastTxDateTo='   + IntToStr(DateTimeToUNIXTimeFAST(aLastTxDateTo))   + '&';
  extParams := extParams + 'lastTxDateFrom=' + IntToStr(DateTimeToUNIXTimeFAST(aLastTxDateFrom)) + '&';
  extParams := extParams + 'status='        + (aStatus);

  try
    result :=sendRequest('archived_orders/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;

end;

function TCexIO.getAuthenticationParams: AnsiString;
var
 _nonce : LongWord;
 _message:String;
 _Hash: IHash;
 _hmac: IHMAC;
 _signature:String;
begin

if (CexIOUserID = '') or (CexIOApiKey ='') or (CexIOSecretKey = '') then
   raise Exception.Create('Authentication Bilgileri Eksik');

//  message = nonce + userID + api_key
//  signature = hmac.new(API_SECRET, msg=message, digestmod=hashlib.sha256).hexdigest().upper()

  _nonce   := DateTimeToUNIXTimeFAST(Now);

  if _nonce <= FLastNonce then
     _nonce := FLastNonce + 1;

  FLastNonce := _nonce;

  _message := IntToStr(_nonce) + CexIOUserID + CexIOApiKey;

  _hmac := THashFactory.THMAC.CreateHMAC(THashFactory.TCrypto.CreateSHA2_256);
  _hmac.Initialize;
  _hmac.Key := TEncoding.ASCII.GetBytes(CexIOSecretKey);
  _hmac.Initialize;
  _signature := UpperCase(ToHex(_hmac.ComputeBytes(TEncoding.UTF8.GetBytes(_message)).GetBytes));

  result   :='key='       +  CexIOApiKey                + '&' +
             'nonce='     +  IntToStr(_nonce)           + '&' +
             'signature=' +  _signature;
end;

function TCexIO.getCexIOChart(aCryptoCurrency: String;
  aCurrency: String; aLastHourst, aMaxRespArrSize: Integer): TJSONValue;
var
params:AnsiString;
begin
  result :=nil;
  params := 'lastHours=' + inttostr(aLastHourst) + '&' + 'maxRespArrSize=' + inttostr(aMaxRespArrSize);
  try
    result :=sendRequest('price_stats/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',params);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOCovert(aCryptoCurrency: String;
  aCurrency: String;aAmount:Real): TJSONValue;
begin
  result :=nil;
  DecimalSeparator :='.';
  try
    result :=sendRequest('convert/'+(aCryptoCurrency)+'/'+(aCurrency)+'/','amnt='+FloatToStr(aAmount));
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOCryptoAddress(
  aCryptoCurrency: String): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;

  extParams := '&' + 'currency=' + (aCryptoCurrency);

  try
    result :=sendRequest('get_address/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOCurrencyLimits: TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('currency_limits/');
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOHCistorical1mOHLCVChart(
  aCryptoCurrency: String; aCurrency: String;
  aDate: TDate): TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('ohlcv/hd/'+FormatDateTime('YYYYMMDD',aDate)+'/'+(aCryptoCurrency)+'/'+(aCurrency)+'/');
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;

{
  "complete": false,
  "id": "5011340264",
  "time": 1510576560908,
  "pending": "1.00000000",
  "amount": "1.00000000",
  "type": "buy",
  "price": "270"
}

end;

function TCexIO.getCexIOLastPrice(aCryptoCurrency: String;
  aCurrency: String): TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('last_price/'+(aCryptoCurrency)+'/'+(aCurrency)+'/');
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOOpenOrders(aCryptoCurrency: String;
  aCurrency: String): TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('open_orders/'+(aCryptoCurrency)+'/'+(aCurrency)+'/',getAuthenticationParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOOpenOrdersAll: TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('open_orders/',getAuthenticationParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOOrderBook(aCryptoCurrency: String;
  aCurrency: String; aDepth: Integer): TJSONValue;
begin
  result :=nil;
  try
    if aDepth = 0 then
      result :=sendRequest('order_book/'+(aCryptoCurrency)+'/'+(aCurrency)+'/')
    else
      result :=sendRequest('order_book/'+(aCryptoCurrency)+'/'+(aCurrency)+'/?depth='+IntToStr(aDepth));
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOOrderDetails(aID: String): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;

  extParams := '&' + 'id=' + (aID);

  try
    result :=sendRequest('get_order/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOOrderTransactions(aID: String): TJSONValue;
  var
  extParams:AnsiString;
begin
  result :=nil;

  extParams := '&' + 'id=' + (aID);

  try
    result :=sendRequest('get_order_tx/',getAuthenticationParams+extParams);
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOTicker(aCryptoCurrency: String;
  aCurrency: String): TJSONValue;
begin
  result :=nil;
  try
    result :=sendRequest('ticker/'+aCryptoCurrency+'/'+aCurrency+'/');
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

function TCexIO.getCexIOTradeHistory(aCryptoCurrency: String;
  aCurrency: String; aSince: Integer): TJSONValue;
begin
  result :=nil;
  try
    if aSince = 0 then
      result :=sendRequest('trade_history/'+(aCryptoCurrency)+'/'+(aCurrency)+'/')
    else
      result :=sendRequest('trade_history/'+(aCryptoCurrency)+'/'+(aCurrency)+'/?since='+IntToStr(aSince));
  except on E: Exception do
     raise Exception.Create(E.Message);
  end;
end;

procedure TCexIO.initSSLComponents;
begin
  try
    FSslContext.InitContext;
  except
    on E: Exception do
    begin
      raise Exception.Create(E.Message);
    end;
  end;
end;

function TCexIO.sendRequest(aURL, aParams: AnsiString): TJSONValue;
var
response:TStringStream;
request:TMemoryStream;
begin
  result   := nil;
  request  := nil;
  response := nil;

  if NOT FSslContext.IsCtxInitialized then  Exit;

  FSslHttpCli.URL := fBaseURL + aURL;
  response := TStringStream.Create('', TEncoding.UTF8);
  FSslHttpCli.RcvdStream := response;
  aParams :=TIdURI.ParamsEncode(Trim(aParams));
  try
    if (aParams = '') then
    begin
       FSslHttpCli.Get;
    end
    else
    begin
      request := TMemoryStream.Create;
      try
        request.Write(aParams[1], Length(aParams));
        request.Seek(0, soFromBeginning);
        FSslHttpCli.SendStream := request;
        FSslHttpCli.SendStream.Position :=0;
        try
          FSslHttpCli.Post;
        except on E: Exception do
            raise Exception.Create(e.Message);
        end;
      finally
        freeandNil(request);
      end;
    end;

  except on E: Exception do
  begin
       freeandNil(response);
       raise Exception.Create(e.Message);
  end;
  end;
  response.Position := 0;

  try
    result:= TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(response.DataString),0) as TJSONValue;
  except on E: Exception do
  end;
  freeandNil(response);
end;

procedure TCexIO.SetCexIOApiKey(const Value: String);
begin
  FCexIOApiKey := Value;
end;

procedure TCexIO.SetCexIOSecretKey(const Value: String);
begin
  FCexIOSecretKey := Value;
end;

procedure TCexIO.SetCexIOUserID(const Value: String);
begin
  FCexIOUserID := Value;
end;

procedure TCexIO.setProxy;
begin
  if FProxyServer <> '' then 
  begin
    with FSslHttpCli do
    begin
      ProxyConnection := 'Kep-Alive';
      Proxy           := FProxyServer;
      ProxyPort       := inttostr(FProxyPort);
      ProxyUsername   := FProxyUsername;
      ProxyPassword   := FProxyPassword;
      ProxyAuth       := httpAuthBasic;
    end;
  end;
end;

procedure TCexIO.SetProxyPassword(const Value: String);
begin
  FProxyPassword := Value;
  setProxy;
end;

procedure TCexIO.SetProxyPort(const Value: Integer);
begin
  FProxyPort := Value;
  setProxy;
end;

procedure TCexIO.SetProxyServer(const Value: String);
begin
  FProxyServer := Value;
  setProxy;
end;

procedure TCexIO.SetProxyUsername(const Value: String);
begin
  FProxyUsername := Value;
  setProxy;
end;

procedure TCexIO.setSSLComponentSettings;
begin

  with FSslHttpCli do
  begin
    Accept :='text/json, image/gif, image/x-xbitmap, image/jpeg, image/jpg, */*';
    Agent := 'Mozilla/4.0 (compatible; ICS; MSIE 4.0)';
    BandwidthLimit := 10000;
    BandwidthSampling := 1000;
     ContentTypePost := 'application/x-www-form-urlencoded';
    FollowRelocation := True;
    ServerAuth := httpAuthBasic;
    ProxyAuth := httpAuthBasic;
    MultiThreaded := False;
    LocalAddr := '0.0.0.0';
    LocalAddr6 := '::';
    NoCache := False;
    RequestVer := '1.0';
    LocationChangeMaxCount := 5;
    BandwidthLimit := 10000;
    BandwidthSampling := 1000;
    Options := [];
    Timeout := 30;
    SocksAuthentication := SocksAuthentication;
    SocketFamily := sfIPv4;
//    ProxyConnection := 'Kep-Alive';
//    Proxy := FProxyServer;
//    ProxyPort := inttostr(FProxyPort);
//    ProxyUsername := FProxyUsername;
//    ProxyPassword := FProxyPassword;
//    ProxyAuth := httpAuthBasic;
  end;


  with FSslContext do
  begin
    SslVerifyPeer := False;
    SslVerifyDepth := 9;
    SslVerifyFlags := [];
    SslOptions := [];
    SslVerifyPeerModes := [SslVerifyMode_PEER];
    SslSessionCacheModes := [];
    SslCipherList := 'ALL:!ADH:RC4+RSA:+SSLv2:@STRENGTH';
    SslVersionMethod := sslTLS_V1_2_CLIENT;
    SslECDHMethod := sslECDHNone;
    SslSessionTimeout := 0;
    SslSessionCacheSize := 20480;
    SslOptions := [sslOpt_NO_SSLv2, sslOpt_NO_SSLv3, sslOpt_NO_TLSv1,sslOpt_NO_TLSv1_1];
  end;

  FSslHttpCli.SslContext := FSslContext;

end;

end.
