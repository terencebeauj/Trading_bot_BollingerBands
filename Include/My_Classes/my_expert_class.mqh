//+------------------------------------------------------------------+
//|                                              my_expert_class.mqh |
//|                                                 Terence Beaujour |
//|                                            beaujour.t@hotmail.fr |
//+------------------------------------------------------------------+
#property copyright "Terence Beaujour"
#property link      "beaujour.t@hotmail.fr"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MyExpert
  {
private:
   int               Magic_No;
   int               Chk_Margin;
   double            LOTS;
   double            TradePct;
   double            ADX_min;
   int               ADX_handle;
   int               MA_handle;
   double            plus_DI[];
   double            minus_DI[];
   double            MA_val[];
   double            ADX_val[];
   double            Closeprice;
   MqlTradeRequest   trequest;
   MqlTradeResult    tresult;
   string            symbol;
   ENUM_TIMEFRAMES   period;
   string            Errormsg;
   int               Errcode;

public:
   void              MyExpert();
   void              setSymbol(string symb) {symbol = symb;}
   void              setPeriod(ENUM_TIMEFRAMES per) {period=per;}
   void              setCloseprice(double prc) {Closeprice=prc;}
   void              setchkMAG(int mag) {Chk_Margin=mag;}
   void              setLOTS(double lot) {LOTS=lot;}
   void              setTRpct(double trpct) {TradePct=trpct/100;}
   void              setMagic(int magic) {Magic_No=magic;}
   void              setadxmin(double adx) {ADX_min=adx;}

   void              doInit(int adx_period,int ma_period) ;
   void              doUninit();
   bool              checkBuy();
   bool              checkSell();
   void              openBuy(ENUM_ORDER_TYPE otype,double askprice,double SL,double TP,int dev,string comment=NULL);
   void              openSell(ENUM_ORDER_TYPE otype,double bidprice,double SL,double TP,int dev,string comment=NULL);

protected:
   void              showError(string msg, int ercode);
   void              getBuffers();
   bool              MarginOK();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::MyExpert(void)
  {
   ZeroMemory(trequest);
   ZeroMemory(tresult);
   ZeroMemory(ADX_val);
   ZeroMemory(MA_val);
   ZeroMemory(plus_DI);
   ZeroMemory(minus_DI);
   Errcode=0;
   Errormsg="";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::showError(string msg,int ercode)
  {
   Alert(msg,"-error:","!!");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::getBuffers(void)
  {
   if(CopyBuffer(ADX_handle,0,0,3,ADX_val)<0 || CopyBuffer(ADX_handle,1,0,3,plus_DI)<0 || CopyBuffer(ADX_handle,2,0,3,minus_DI)<0 || CopyBuffer(MA_handle,0,0,3,MA_val)<0)
     {
      Errormsg="Error copying indicator Buffers";
      Errcode=GetLastError();
      showError(Errormsg,Errcode);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MyExpert::MarginOK(void)
  {
   double one_lot_price;
   double act_f_mag = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   double contract_size = SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE);
   string base_currency = SymbolInfoString(symbol,SYMBOL_CURRENCY_BASE);

   if(base_currency=="USD")
     {
      one_lot_price=contract_size/leverage;
     }
   else
     {
      double bprice = SymbolInfoDouble(symbol,SYMBOL_BID);
      one_lot_price=bprice*contract_size/leverage;
     }

   if(MathFloor(LOTS*one_lot_price)>MathFloor(act_f_mag*TradePct))
      return false;

   else
      return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::doInit(int adx_period,int ma_period)
  {
   ADX_handle=iADX(symbol,period,adx_period);
   MA_handle=iMA(symbol,period,ma_period,0,MODE_EMA,PRICE_CLOSE);

   if(ADX_handle<0 || MA_handle<0)
     {
      Errormsg="Error handle indic";
      Errcode=GetLastError();
      showError(Errormsg,Errcode);
     }

   ArraySetAsSeries(ADX_val,true);
   ArraySetAsSeries(MA_val,true);
   ArraySetAsSeries(plus_DI,true);
   ArraySetAsSeries(minus_DI,true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::doUninit(void)
  {
   IndicatorRelease(ADX_handle);
   IndicatorRelease(MA_handle);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MyExpert::checkBuy(void)
  {
   getBuffers();

   bool Buy_Condition_1 = (MA_val[0]>MA_val[1]) && (MA_val[1]>MA_val[2]);
   bool Buy_Condition_2 = Closeprice>MA_val[1];
   bool Buy_Condition_3 = ADX_val[0]>ADX_min;
   bool Buy_Condition_4 = plus_DI[0]>minus_DI[0];

   if(Buy_Condition_1&&Buy_Condition_2&&Buy_Condition_3&&Buy_Condition_4)
      return true;
   else
      return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MyExpert::checkSell(void)
  {
   getBuffers();

   bool Sell_Condition_1 = (MA_val[0]<MA_val[1]) && (MA_val[1]<MA_val[2]);
   bool Sell_Condition_2 = Closeprice<MA_val[1];
   bool Sell_Condition_3 = ADX_val[0]>ADX_min;
   bool Sell_Condition_4 = plus_DI[0]<minus_DI[0];

   if(Sell_Condition_1&&Sell_Condition_2&&Sell_Condition_3&&Sell_Condition_4)
      return true;
   else
      return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::openBuy(ENUM_ORDER_TYPE otype,double askprice,double SL,double TP,int dev,string comment=NULL)
  {
   if(Chk_Margin==1)
     {
      if(MarginOK()==false)
        {
         Errormsg="Don't have enough money to open this position!";
         Errcode=GetLastError();
         showError(Errormsg,Errcode);
        }
      else
        {
         trequest.action=TRADE_ACTION_DEAL;
         trequest.type=otype;
         trequest.volume=LOTS;
         trequest.price=askprice;
         trequest.sl=SL;
         trequest.tp=TP;
         trequest.deviation=dev;
         trequest.magic=Magic_No;
         trequest.symbol=symbol;
         trequest.type_filling=ORDER_FILLING_FOK;

         OrderSend(trequest,tresult);

         if(tresult.retcode==10009||tresult.retcode==10008)
            Alert("Buy completed. ",tresult.order," !!");
         else
           {
            Errormsg="Buy failed.";
            Errcode=GetLastError();
            showError(Errormsg,Errcode);
           }
        }
     }
   else
     {
      trequest.action=TRADE_ACTION_DEAL;
      trequest.type=otype;
      trequest.volume=LOTS;
      trequest.price=askprice;
      trequest.sl=SL;
      trequest.tp=TP;
      trequest.deviation=dev;
      trequest.magic=Magic_No;
      trequest.symbol=symbol;
      trequest.type_filling=ORDER_FILLING_FOK;

      OrderSend(trequest,tresult);

      if(tresult.retcode==10009||tresult.retcode==10008)
         Alert("Buy completed. ",tresult.order," !!");
      else
        {
         Errormsg="Buy failed.";
         Errcode=GetLastError();
         showError(Errormsg,Errcode);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MyExpert::openSell(ENUM_ORDER_TYPE otype,double bidprice,double SL,double TP,int dev,string comment=NULL)
  {
   if(Chk_Margin==1)
     {
      if(MarginOK()==false)
        {
         Errormsg="Don't have enough money to open this position!";
         Errcode=GetLastError();
         showError(Errormsg,Errcode);
        }
      else
        {
         trequest.action=TRADE_ACTION_DEAL;
         trequest.type=otype;
         trequest.volume=LOTS;
         trequest.price=bidprice;
         trequest.sl=SL;
         trequest.tp=TP;
         trequest.deviation=dev;
         trequest.magic=Magic_No;
         trequest.symbol=symbol;
         trequest.type_filling=ORDER_FILLING_FOK;

         OrderSend(trequest,tresult);

         if(tresult.retcode==10009||tresult.retcode==10008)
            Alert("Sell completed. ",tresult.order," !!");
         else
           {
            Errormsg="Sell failed.";
            Errcode=GetLastError();
            showError(Errormsg,Errcode);
           }
        }
     }
   else
     {
      trequest.action=TRADE_ACTION_DEAL;
      trequest.type=otype;
      trequest.volume=LOTS;
      trequest.price=bidprice;
      trequest.sl=SL;
      trequest.tp=TP;
      trequest.deviation=dev;
      trequest.magic=Magic_No;
      trequest.symbol=symbol;
      trequest.type_filling=ORDER_FILLING_FOK;

      OrderSend(trequest,tresult);

      if(tresult.retcode==10009||tresult.retcode==10008)
         Alert("Sell completed. ",tresult.order," !!");
      else
        {
         Errormsg="Sell failed.";
         Errcode=GetLastError();
         showError(Errormsg,Errcode);
        }
     }
  }
//+------------------------------------------------------------------+
