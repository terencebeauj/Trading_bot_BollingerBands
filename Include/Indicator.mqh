//+------------------------------------------------------------------+
//|                                                    Indicator.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/ru/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, DNG®"
#property link      "http://www.mql5.com/ru/users/dng"
#property version   "1.00"
#include <Arrays\ArrayDouble.mqh>
#include <ErrorDescription.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CArrayBuffer   :  public CArrayDouble
  {
public:
                     CArrayBuffer(void);
                    ~CArrayBuffer(void);
//---
   int               CopyBuffer(const int start, const int count, double &double_array[]);
   int               Initilize(void);
   virtual bool      Shift(const int shift);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CArrayBuffer::CArrayBuffer(void)
  {}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CArrayBuffer::~CArrayBuffer(void)
  {}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CArrayBuffer::CopyBuffer(const int start,const int count,double &double_array[])
  {
   if(start<0 || start>=m_data_total)
     {
      ArrayFree(double_array);
      Print("_42 Indicator.mqh CArrayBuffer::CopyBuffer. Error="+(string)_LastError+" "+ErrorDescription(_LastError));
      return -1;
     }
//---
   //ArraySetAsSeries(m_data,true);
   int bars=fmin(m_data_total-start,count);
   return ArrayCopy(double_array,m_data,0,m_data_total-start-bars,bars);
   //return ArrayCopy(double_array,m_data,0,0,bars);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CArrayBuffer::Initilize(void)
  {
   return ArrayInitialize(m_data,EMPTY_VALUE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CArrayBuffer::Shift(const int shift)
  {
   if(shift<=0)
      {
         Print("_65 Indicator.mqh CIndicator::Shift. Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;
      }
   if(shift>=m_data_total)
      return (Initilize()>0);
//---
   return CArrayDouble::MemMove(0,shift,m_data_total-shift);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CIndicator
  {
private:
//---
   datetime             m_last_load;
public:
                        CIndicator(void);
                       ~CIndicator(void);
   virtual bool         Create(const string symbol=NULL, const ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT, const ENUM_APPLIED_PRICE price=PRICE_CLOSE);
//--- Set indicator's main settings
   virtual bool         SetBufferSize(const int bars);
//--- Get indicator's data
   virtual int          CopyBuffer(const uint buffer_num,const uint start, const uint count, double &double_array[]);
   virtual double       GetData(const uint buffer_num,const uint shift);

protected:
//--- массивы таймсерии
   double               m_source_data[];
   datetime             m_time[];
   double               m_high[];
   double               m_low[];
   double               m_open[];
   double               m_close[];
   
   CArrayBuffer         ar_IndBuffers[];
   int                  m_buffers;
   int                  m_history_len;
   int                  m_data_len;
//---
   string               m_Symbol;
   ENUM_TIMEFRAMES      m_Timeframe;
   ENUM_APPLIED_PRICE   m_Price;      
//--- Set indicator's main settings
   virtual bool         SetHistoryLen(const int bars=-1);
//---
   virtual bool         LoadHistory(void);
   virtual bool         Calculate()                         {  return true;   }

  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CIndicator::CIndicator()   :  m_buffers(0),
                              m_Symbol(_Symbol),
                              m_Timeframe(PERIOD_CURRENT),
                              m_Price(PRICE_CLOSE),
                              m_last_load(0)
  {
   m_data_len=m_history_len  =  Bars(m_Symbol,m_Timeframe)-1;
   ArrayFree(ar_IndBuffers);
   ArraySetAsSeries(ar_IndBuffers,true);
   
   ArrayFree(m_source_data);
   ArrayFree(m_time);
   ArrayFree(m_high);
   ArrayFree(m_low);
   ArrayFree(m_open);
   ArrayFree(m_close);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CIndicator::~CIndicator()
  {
   ArrayFree(ar_IndBuffers);
   ArraySetAsSeries(ar_IndBuffers,true);
   
   ArrayFree(m_source_data);
   ArrayFree(m_time);
   ArrayFree(m_high);
   ArrayFree(m_low);
   ArrayFree(m_open);
   ArrayFree(m_close);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIndicator::SetBufferSize(const int bars)
  {
   ArrayResize(ar_IndBuffers,m_buffers,m_buffers);
   
   if(bars>0)
      m_data_len  =  bars;
   else
      m_data_len  =  Bars(m_Symbol,m_Timeframe);
//---
   if(m_data_len<=0)
     {
      for(int i=0;i<m_buffers;i++)
         ar_IndBuffers[i].Shutdown();
      Print("_166 Indicator.mqh CIndicator::SetBufferSize. Error="+(string)_LastError+" "+ErrorDescription(_LastError));
      return false;
     }
//---
   if(m_history_len<m_data_len)
      if(!SetHistoryLen(m_data_len))
         {
            Print("_173 Indicator.mqh CIndicator::SetBufferSize. Error="+(string)_LastError+" "+ErrorDescription(_LastError));
            return false;
         }
//---
   for(int i=0;i<m_buffers;i++)
     {
      ar_IndBuffers[i].Shutdown();
      if(!ar_IndBuffers[i].Resize(m_data_len))
         {
            Print("_182 Indicator.mqh CIndicator::SetBufferSize. Error="+(string)_LastError+" "+ErrorDescription(_LastError));
            return false;
         }
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CIndicator::CopyBuffer(const uint buffer_num,const uint start,const uint count,double &double_array[])
  {
   if(!Calculate())
      {
         Print("_196 Indicator.mqh CIndicator::CopyBuffer. Calculate() Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return -1;
      }
//---
   if((int)buffer_num>=m_buffers)
     {
      ArrayFree(double_array);
      Print("_203 Indicator.mqh CIndicator::CopyBuffer. buffer_num>=m_buffers Error="+(string)_LastError+" "+ErrorDescription(_LastError));
      return -1;
     }
//---
   return ar_IndBuffers[buffer_num].CopyBuffer(start,count,double_array);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CIndicator::GetData(const uint buffer_num,const uint shift)
  {
   if(!Calculate())
      {
         Print("_216 Indicator.mqh CIndicator::GetData. Calculate() Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return EMPTY_VALUE;
      }
//---
   if((int)buffer_num>=m_buffers)
      {
         Print("_222 Indicator.mqh CIndicator::GetData. buffer_num>=m_buffers Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return EMPTY_VALUE;
      }
//---
   return ar_IndBuffers[buffer_num].At(m_data_len-shift);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIndicator::SetHistoryLen(const int bars)
  {
   if(bars>0)
      m_history_len  =  bars;
   else
      m_history_len  =  Bars(m_Symbol,m_Timeframe)-1;
//---
   if(m_history_len<0)
     {
      SetBufferSize(m_history_len);
      ArrayFree(m_source_data);
      ArrayFree(m_time);
      ArrayFree(m_high);
      ArrayFree(m_low);
      ArrayFree(m_open);
      ArrayFree(m_close);
      m_last_load=0;
      Print("_248 Indicator.mqh CIndicator::SetHistoryLen. m_history_len<0 Error="+(string)_LastError+" "+ErrorDescription(_LastError));
      return false;
     }
//---
   if(m_history_len<m_data_len)
      if(!SetBufferSize(m_history_len))
        {
         m_last_load=0;
         Print("_256 Indicator.mqh CIndicator::SetHistoryLen. m_history_len<m_data_len Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;
        }
//---
   if(ArrayResize(m_source_data,m_history_len)<0)
      {
         Print("_262 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_source_data) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }    
   if(ArrayResize(m_time,m_history_len)<0)
      {
         Print("_267 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_time) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }   
   if(ArrayResize(m_high,m_history_len)<0)
      {
         Print("_272 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_high) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }   
   if(ArrayResize(m_low,m_history_len)<0)
      {
         Print("_277 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_low) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }   
   if(ArrayResize(m_open,m_history_len)<0)
      {
         Print("_282 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_open) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }   
   if(ArrayResize(m_close,m_history_len)<0)
      {
         Print("_287 Indicator.mqh CIndicator::SetHistoryLen. ArrayResize(m_close) Error="+(string)_LastError+" "+ErrorDescription(_LastError));
         return false;  
      }   
   m_history_len=ArraySize(m_source_data);
   m_last_load=0;
   ArrayInitialize(m_source_data,EMPTY_VALUE);
   ArrayInitialize(m_time,0);
   ArrayInitialize(m_high,EMPTY_VALUE);
   ArrayInitialize(m_low,EMPTY_VALUE);
   ArrayInitialize(m_open,EMPTY_VALUE);
   ArrayInitialize(m_close,EMPTY_VALUE);
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIndicator::LoadHistory(void)
  {
   //datetime cur_date=(datetime)SeriesInfoInteger(m_Symbol,m_Timeframe,SERIES_LASTBAR_DATE);
   //if(m_last_load>=cur_date && ArraySize(m_source_data)>=m_history_len)
   //   return true;
//---
   MqlRates rates[];
   int total=0,i;
   
   total=CopyRates(m_Symbol,m_Timeframe,1,m_history_len,rates);
   if(total<=0) {Print("_314 Indicator.mqh CIndicator::LoadHistory Ошибка CopyRates (total="+IntegerToString(total)+"). Не смогли получить историю. Error=" +(string)_LastError+" "+ErrorDescription(_LastError)); return false;}
   if(total<m_history_len) 
      {
         Print("_317 Indicator.mqh CIndicator::LoadHistory Недостаточно истории. Есть "+IntegerToString(total)+" надо "+IntegerToString(m_history_len));
         return false;
      }
   else Print("_320 Indicator.mqh CIndicator::LoadHistory Загружено "+ IntegerToString(total) + " баров истории, надо было "+IntegerToString(m_history_len)+" баров");
   
   if(!ArraySetAsSeries(rates,true))         Print("_322 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_source_data,true)) Print("_323 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_time,true))        Print("_324 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_high,true))        Print("_325 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_low,true))         Print("_326 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_open,true))        Print("_327 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   if(!ArraySetAsSeries(m_close,true))       Print("_328 Indicator.mqh CIndicator::LoadHistory Ошибка ArraySetAsSeries массива time. Error=" +(string)_LastError+" "+ErrorDescription(_LastError));
   for(i=1;i<total;i++)
      {
         m_source_data[i]=rates[i].close;
         m_time[i]=rates[i].time;
         m_high[i]=rates[i].high;
         m_low[i]=rates[i].low;
         m_open[i]=rates[i].open;
         m_close[i]=rates[i].close;
      }
     
//---
   //m_last_load=cur_date;
   return (total>0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CIndicator::Create(const string symbol=NULL,const ENUM_TIMEFRAMES timeframe=0,const ENUM_APPLIED_PRICE price=1)
  {
   m_Symbol=(symbol==NULL ? _Symbol : symbol);
   if(!SymbolInfoInteger(m_Symbol,SYMBOL_SELECT))
      if(!SymbolSelect(m_Symbol,true))
         {
            Print("_352 Indicator.mqh CIndicator::Create. total<=0 Error="+(string)_LastError+" "+ErrorDescription(_LastError));
            return false;
         }
//---
   m_Timeframe=timeframe;
   m_Price=price;
//---
   return true;
  }
//+------------------------------------------------------------------+
