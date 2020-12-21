//+------------------------------------------------------------------+
//|                                          Ichimoku_Class_Test.mqh |
//|                                                 Terence Beaujour |
//|                                            beaujour.t@hotmail.fr |
//+------------------------------------------------------------------+
#property copyright "Terence Beaujour"
#property link      "beaujour.t@hotmail.fr"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIchimoku
  {
protected:
   double               ichimoku_hand;
   double               tenkan_buff[],kijun_buff[],ssa_buff[],ssb_buff[],chikou_buff[];
   bool                 buyflag;
   bool                 sellflag;
   MqlRates             candle[];
   MqlRates             candle_timeframesup[];

public:
   void                 CIchimoku();
   void                 setSsa(int start=0, int count=10);
   void                 setSsb(int start=0, int count=10);
   void                 setKijun(int start=0, int count=10);
   void                 setTenkan(int start=0, int count=10);
   void                 setChikou(int start=0, int count=10);
   void                 setCandle(int start=0, int count=10);
   void                 setCandleTimeframeSup(int start=0, int count=10);
   void                 setIchimokuParams(int start=0, int count=10);
   ENUM_INIT_RETCODE    init(ENUM_TIMEFRAMES period=0,int tenkan=9, int kijun=26,int ssb=52);
   void                 cleanBuffer();
   bool                 check_buyflag();
   bool                 check_sellflag();
   bool                 check_buyflag_02();
   bool                 check_sellflag_02();
   bool                 check_buyflag_timeframesup();
   bool                 check_sellflag_timeframesup();
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::CIchimoku(void)
  {
   ZeroMemory(ichimoku_hand);
   ZeroMemory(ssa_buff);
   ZeroMemory(ssb_buff);
   ZeroMemory(kijun_buff);
   ZeroMemory(tenkan_buff);
   ZeroMemory(chikou_buff);
   ZeroMemory(buyflag);
   ZeroMemory(sellflag);
   ZeroMemory(candle);
   ZeroMemory(candle_timeframesup);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_INIT_RETCODE CIchimoku::init(ENUM_TIMEFRAMES period=0,int tenkan=9,int kijun=26,int ssb=52)
  {
   ichimoku_hand=iIchimoku(Symbol(),period,tenkan,kijun,ssb);

   if(ichimoku_hand==INVALID_HANDLE)
      return INIT_FAILED;

   ArraySetAsSeries(ssa_buff,true);
   ArraySetAsSeries(ssb_buff,true);
   ArraySetAsSeries(kijun_buff,true);
   ArraySetAsSeries(tenkan_buff,true);
   ArraySetAsSeries(chikou_buff,true);
   ArraySetAsSeries(candle,true);
   ArraySetAsSeries(candle_timeframesup,true);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setSsa(int start=0, int count=10)
  {
   if(!(CopyBuffer(ichimoku_hand,2,start,count,ssa_buff)>0))
     {
      Print("Error in setting ssa : " + (string)GetLastError());
      ResetLastError();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setSsb(int start=0, int count=10)
  {
   if(!(CopyBuffer(ichimoku_hand,3,start,count,ssb_buff)>0))
     {
      Print("Error in setting ssb : " + (string)GetLastError());
      ResetLastError();
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setKijun(int start=0, int count=10)
  {
   if(CopyBuffer(ichimoku_hand,1,start,count,ssa_buff)<=0)
     {
      Print("Error in setting kijun : " + (string)GetLastError());
      ResetLastError();
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setTenkan(int start=0, int count=10)
  {
   if(CopyBuffer(ichimoku_hand,0,start,count,tenkan_buff)<=0)
     {
      Print("Error in setting tenkan : " + (string)GetLastError());
      ResetLastError();
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setChikou(int start=0, int count=10)
  {
   if(!(CopyBuffer(ichimoku_hand,4,start,count,chikou_buff)>0))
     {
      Print("Error in setting chikou : "+(string)GetLastError());
      ResetLastError();
     }

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setIchimokuParams(int start=0,int count=10)
  {
   setTenkan(start,count);
   setKijun(start,count);
   setSsa(start,count);
   setSsb(start,count);
   setChikou(start,count);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::setCandle(int start=0,int count=10)
  {
   if(CopyRates(Symbol(),PERIOD_CURRENT,start,count,candle)<=0)
     {
      Print("Error in setting chikou : "+ (string)GetLastError());
      ResetLastError();
     }
  }

void  CIchimoku::setCandleTimeframeSup(int start=0,int count=10)
{
   if(CopyRates(Symbol(),PERIOD_D1,start,count,candle_timeframesup)<=0)
     {
      Print("Error in setting chikou : "+ (string)GetLastError());
      ResetLastError();
     }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::check_buyflag(void)
  {
   buyflag=(((candle[2].open>=ssb_buff[2]) && (candle[2].open<ssa_buff[2])) && (candle[2].close>ssa_buff[2]) && (candle[1].open>=ssa_buff[1]) && (candle[1].close>candle[1].open)) || (((candle[2].open>=ssa_buff[2]) && (candle[2].open<ssb_buff[2])) && (candle[2].close>ssb_buff[2]) && (candle[1].open>=ssb_buff[1]) && (candle[1].close>candle[1].open));
   if(buyflag)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::check_sellflag(void)
  {
   sellflag=(((candle[2].open<=ssb_buff[2]) && (candle[2].open>ssa_buff[2])) && (candle[2].close<ssa_buff[2]) && (candle[1].open<=ssa_buff[1]) && (candle[1].close<candle[1].open)) || (((candle[2].open<=ssa_buff[2]) && (candle[2].open>ssb_buff[2])) && (candle[2].close<ssb_buff[2]) && (candle[1].open<=ssb_buff[1]) && (candle[1].close<candle[1].open));
   if(sellflag)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::check_buyflag_02(void)
  {
   buyflag = (candle[1].close>candle[1].open && candle[1].close>ssa_buff[1] && candle[1].close>ssb_buff[1]) && (candle[1].open<ssa_buff[1] && candle[1].open<ssb_buff[1]);
   if(buyflag)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::check_sellflag_02(void)
  {
   sellflag = (candle[1].close<candle[1].open && candle[1].close<ssa_buff[1] && candle[1].close<ssb_buff[1]) && (candle[1].open>ssa_buff[1] && candle[1].open>ssb_buff[1]);
   if(sellflag)
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CIchimoku::cleanBuffer(void)
  {
   ZeroMemory(ssa_buff);
   ZeroMemory(ssb_buff);
   ZeroMemory(kijun_buff);
   ZeroMemory(tenkan_buff);
   ZeroMemory(chikou_buff);
   ZeroMemory(candle);
   ZeroMemory(candle_timeframesup);
  }
//+------------------------------------------------------------------+
bool CIchimoku::check_buyflag_timeframesup(void)
  {
   if(candle_timeframesup[1].close>candle_timeframesup[1].open && candle_timeframesup[1].open>ssa_buff[1] && candle_timeframesup[1].open>ssb_buff[1])
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIchimoku::check_sellflag_timeframesup(void)
  {
   if(candle_timeframesup[1].close<candle_timeframesup[1].open && candle_timeframesup[1].open<ssa_buff[1] && candle_timeframesup[1].open<ssb_buff[1])
      return true;
   return false;
  }
//+------------------------------------------------------------------+
