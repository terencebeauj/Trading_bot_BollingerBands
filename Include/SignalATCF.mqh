//+------------------------------------------------------------------+
//|                                                   SignalATCF.mqh |
//|                                              Copyright 2017, DNG |
//|                                      https://forex-start.ucoz.ua |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, DNG"
#property link      "https://forex-start.ucoz.ua"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>
#include <ATCF_Gizlyk\\Spectrum.mqh>
#include <ATCF_Gizlyk\\FLF.mqh>
// wizard description start
//+---------------------------------------------------------------------------+
//| Description of the class                                                  |
//| Title=Signals degign by DNG for Adaptive Trend & Cycles Following Method  |
//| Type=SignalAdvanced                                                       |
//| Name=Signals Adaptive Trend & Cycles Following Method                     |
//| ShortName=ATCF                                                            |
//| Class=CSignalATCF                                                         |
//| Page=http://www.mql5.com/ru/articles/3456                                 |
//| Parameter=TimeFrame,ENUM_TIMEFRAMES,PERIOD_H4,Timeframe                   |
//| Parameter=HistoryBars,uint,1560,Bars in history to analysis               |
//| Parameter=AveragePeriod,uint,500,Period for RBCI and PCCI                 |
//| Parameter=Pattern1,bool,true,Use pattern 1                                |
//| Parameter=Pattern2,bool,true,Use pattern 2                                |
//| Parameter=Pattern3,bool,true,Use pattern 3                                |
//| Parameter=Pattern4,bool,true,Use pattern 4                                |
//| Parameter=Pattern5,bool,true,Use pattern 5                                |
//| Parameter=Pattern6,bool,true,Use pattern 6                                |
//| Parameter=Pattern7,bool,true,Use pattern 7                                |
//| Parameter=Pattern8,bool,true,Use pattern 8                                |
//+---------------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CSignalATCF : public CExpertSignal
  {
private:
   ENUM_TIMEFRAMES   ce_Timeframe;  //Timframe
   uint              ci_HistoryBars;//Bars in history to analysis
   uint              ci_AveragePeriod;//Period for RBCI and PCCI
   CSpectrum         *Spectrum;     //Class for spectr calculation
   CFLF              *FFLF;         //Class of fast low frequency filter
   CFLF              *SFLF;         //Class of slow low frequency filter
   //--- Indicators data
   double             FATL, FATL1, FATL2;
   double             SATL, SATL1;
   double             RFTL, RFTL1, RFTL2;
   double             RSTL, RSTL1;
   double             FTLM, FTLM1, FTLM2;
   double             STLM, STLM1;
   double             RBCI, RBCI1, RBCI2;
   double             PCCI, PCCI1, PCCI2;
   //---
   bool               cb_UsePattern1;
   bool               cb_UsePattern2;
   bool               cb_UsePattern3;
   bool               cb_UsePattern4;
   bool               cb_UsePattern5;
   bool               cb_UsePattern6;
   bool               cb_UsePattern7;
   bool               cb_UsePattern8;
   //---
   datetime           cdt_LastSpectrCalc;
   datetime           cdt_LastCalcIndicators;
   bool               cb_fast_calced;
   bool               cb_slow_calced;
   
   bool              CalculateIndicators(void);
       
public:
                     CSignalATCF();
                    ~CSignalATCF();
   //---
   void              TimeFrame(ENUM_TIMEFRAMES value);
   void              HistoryBars(uint value);
   void              AveragePeriod(uint value);
   void              Pattern1(bool value)                {  cb_UsePattern1=value;   }
   void              Pattern2(bool value)                {  cb_UsePattern2=value;   }
   void              Pattern3(bool value)                {  cb_UsePattern3=value;   }
   void              Pattern4(bool value)                {  cb_UsePattern4=value;   }
   void              Pattern5(bool value)                {  cb_UsePattern5=value;   }
   void              Pattern6(bool value)                {  cb_UsePattern6=value;   }
   void              Pattern7(bool value)                {  cb_UsePattern7=value;   }
   void              Pattern8(bool value)                {  cb_UsePattern8=value;   }
   //--- method of verification of settings
   virtual bool      ValidationSettings(void);
   //--- method of creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);
   //--- methods of checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalATCF::CSignalATCF():   cdt_LastSpectrCalc(0),
                              ci_HistoryBars(2880),
                              cb_fast_calced(false),
                              cb_slow_calced(false)
  {
   ce_Timeframe=m_period;
   
   if(CheckPointer(m_symbol)!=POINTER_INVALID)
      Spectrum=new CSpectrum(ci_HistoryBars,m_symbol.Name(),ce_Timeframe);
   FFLF=new CFLF();
   SFLF=new CFLF();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalATCF::~CSignalATCF()
  {
   if(CheckPointer(m_close)!=POINTER_INVALID)
      delete m_close;
   if(CheckPointer(m_open)!=POINTER_INVALID)
      delete m_open;
   if(CheckPointer(m_high)!=POINTER_INVALID)
      delete m_high;
   if(CheckPointer(m_low)!=POINTER_INVALID)
      delete m_low;
   if(CheckPointer(FFLF)!=POINTER_INVALID)
      delete FFLF;
   if(CheckPointer(SFLF)!=POINTER_INVALID)
      delete SFLF;
   if(CheckPointer(Spectrum)!=POINTER_INVALID)
      delete Spectrum;
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CSignalATCF::ValidationSettings(void)
  {
//--- validation settings of additional filters
   if(!CExpertSignal::ValidationSettings())
      return(false);
//--- initial data checks
   if(ci_HistoryBars<200)
     {
      PrintFormat("Too short historical period. Minimal historical period is 200 bars. HistoryBars=%d", ci_HistoryBars);
      return(false);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Create indicators.                                               |
//+------------------------------------------------------------------+
bool CSignalATCF::InitIndicators(CIndicators *indicators)
  {
//--- check of pointer is performed in the method of the parent class
//---
//--- initialization of indicators and timeseries of additional filters
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
//--- initialize close serias
   if(CheckPointer(m_close)==POINTER_INVALID)
     {
      if(!InitClose(indicators))
         return false;
     }
//--- initialize open serias
   if(CheckPointer(m_open)==POINTER_INVALID)
     {
      if(!InitOpen(indicators))
         return false;
     }
//--- initialize high serias
   if(CheckPointer(m_high)==POINTER_INVALID)
     {
      if(!InitHigh(indicators))
         return false;
     }
//--- initialize low serias
   if(CheckPointer(m_low)==POINTER_INVALID)
     {
      if(!InitLow(indicators))
         return false;
     }
//--- create and initialize Spectrum and Filters
   if(CheckPointer(Spectrum)==POINTER_INVALID)
     {
      Spectrum=new CSpectrum(ci_HistoryBars,m_symbol.Name(),ce_Timeframe);
      if(CheckPointer(Spectrum)==POINTER_INVALID)
        {
         cb_fast_calced=false;
         cb_slow_calced=false;
         return false;
        }
     }
   else
     {
      Spectrum.SetHistoryBars(ci_HistoryBars);
      Spectrum.SetTimeframe(ce_Timeframe);
     }
   
   int fast,slow;
   if(Spectrum.GetPeriods(fast,slow))
     {
      cdt_LastSpectrCalc=(datetime)SeriesInfoInteger(m_symbol.Name(),ce_Timeframe,SERIES_LASTBAR_DATE);
      if(CheckPointer(FFLF)==POINTER_INVALID)
        {
         FFLF=new CFLF();
         if(CheckPointer(FFLF)==POINTER_INVALID)
            return false;
        }
      cb_fast_calced=FFLF.CalcImpulses(fast);
      if(CheckPointer(SFLF)==POINTER_INVALID)
        {
         SFLF=new CFLF();
         if(CheckPointer(SFLF)==POINTER_INVALID)
            return false;
        }
      cb_slow_calced=SFLF.CalcImpulses(slow);
     }
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalATCF::TimeFrame(ENUM_TIMEFRAMES value)
  {
   ce_Timeframe=value;
   if(CheckPointer(m_close)!=POINTER_INVALID)
      m_close.Create(m_symbol.Name(),ce_Timeframe);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalATCF::HistoryBars(uint value)
  {
   ci_HistoryBars=value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSignalATCF::AveragePeriod(uint value)
  {
   ci_AveragePeriod=value;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSignalATCF::CalculateIndicators(void)
  {
   //--- Check time of last calculation
   datetime current=(datetime)SeriesInfoInteger(m_symbol.Name(),ce_Timeframe,SERIES_LASTBAR_DATE);
   if(current==cdt_LastCalcIndicators)
      return true;                  // Exit if data alredy calculated on this bar
   //--- Check fo recalc spectrum
   MqlDateTime Current;
   TimeToStruct(current,Current);
   Current.hour=0;
   Current.min=0;
   Current.sec=0;
   datetime start_day=StructToTime(Current);
   
   if(!cb_fast_calced || !cb_slow_calced || (!PositionSelect(m_symbol.Name()) && start_day>cdt_LastSpectrCalc))
     {
      if(CheckPointer(Spectrum)==POINTER_INVALID)
        {
         Spectrum=new CSpectrum(ci_HistoryBars,m_symbol.Name(),ce_Timeframe);
         if(CheckPointer(Spectrum)==POINTER_INVALID)
           {
            cb_fast_calced=false;
            cb_slow_calced=false;
            return false;
           }
        }
      
      int fast,slow;
      if(Spectrum.GetPeriods(fast,slow))
        {
         cdt_LastSpectrCalc=(datetime)SeriesInfoInteger(m_symbol.Name(),ce_Timeframe,SERIES_LASTBAR_DATE);
         if(CheckPointer(FFLF)==POINTER_INVALID)
           {
            FFLF=new CFLF();
            if(CheckPointer(FFLF)==POINTER_INVALID)
               return false;
           }
         cb_fast_calced=FFLF.CalcImpulses(fast);
         if(CheckPointer(SFLF)==POINTER_INVALID)
           {
            SFLF=new CFLF();
            if(CheckPointer(SFLF)==POINTER_INVALID)
               return false;
           }
         cb_slow_calced=SFLF.CalcImpulses(slow);
        }
     }
   if(!cb_fast_calced || !cb_slow_calced)
      return false;                       // Exit on some error
   
   //--- Calculate indicators data
   int shift=StartIndex();
   double rbci[],pcci[],close[];
   if(ArrayResize(rbci,ci_AveragePeriod)<(int)ci_AveragePeriod || ArrayResize(pcci,ci_AveragePeriod)<(int)ci_AveragePeriod ||
      m_close.GetData(shift,ci_AveragePeriod,close)<(int)ci_AveragePeriod)
     {
      return false;
     }
   for(uint i=0;i<ci_AveragePeriod;i++)
     {
      double fatl=FFLF.AdaptiveTrendLine(m_symbol.Name(),ce_Timeframe,shift+i);
      double satl=SFLF.AdaptiveTrendLine(m_symbol.Name(),ce_Timeframe,shift+i);
      switch(i)
        {
         case 0:
            FATL=fatl;
            SATL=satl;
            break;
         case 1:
            FATL1=fatl;
            SATL1=satl;
            break;
         case 2:
            FATL2=fatl;
            break;
        }
      rbci[i]=fatl-satl;
      pcci[i]=close[i]-fatl;
     }
   RFTL=FFLF.ReferenceTrendLine(m_symbol.Name(),ce_Timeframe,shift);
   RSTL=SFLF.ReferenceTrendLine(m_symbol.Name(),ce_Timeframe,shift);
   RFTL1=FFLF.ReferenceTrendLine(m_symbol.Name(),ce_Timeframe,shift+1);
   RSTL1=SFLF.ReferenceTrendLine(m_symbol.Name(),ce_Timeframe,shift+1);
   RFTL2=FFLF.ReferenceTrendLine(m_symbol.Name(),ce_Timeframe,shift+2);
   FTLM=FATL-RFTL;
   STLM=SATL-RSTL;
   FTLM1=FATL1-RFTL1;
   STLM1=SATL1-RSTL1;
   FTLM2=FATL2-RFTL2;
   double dev=MathStandardDeviation(rbci);
   if(dev==0 || dev==QNaN)
      return false;
   RBCI=rbci[0]/dev;
   RBCI1=rbci[1]/dev;
   RBCI2=rbci[2]/dev;
   dev=MathAverageDeviation(pcci);
   if(dev==0 || dev==QNaN)
      return false;
   PCCI=pcci[0]/(dev*0.015);
   PCCI1=pcci[1]/(dev*0.015);
   PCCI2=pcci[2]/(dev*0.015);
   cdt_LastCalcIndicators=current;
  //---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalATCF::LongCondition(void)
  {
   if(!CalculateIndicators() || m_open.GetData(1)>m_close.GetData(1))
      return 0;
   int result=0;
   //--- Close
   if(m_high.GetData(2)<m_close.GetData(1) || (STLM1<=0 && STLM>0)/* || (FTLM1<=0 && FTLM>0)*/ || (PCCI1<PCCI && PCCI1<=PCCI2) || (RBCI>RBCI1 && RBCI1>=RBCI2 && RBCI1<-1) || (RBCI1<=0 && RBCI>0))
      result=40;
   //--- Pattern 1
   if(cb_UsePattern1 && FTLM>0 && STLM>STLM1 && PCCI<100)
      result=80;
   else
   //--- Pattern 2
   if(cb_UsePattern2 && STLM>0 && FATL>FATL1 && FTLM>FTLM1 && RBCI>RBCI1 && (STLM>=STLM1 || (STLM<STLM1 && RBCI<1)))
      result=80;
   else
   //--- Pattern 3
   if(cb_UsePattern3 && STLM>0 && FATL>FATL1 && RBCI>RBCI1 && RBCI1<-1 && RBCI1<=RBCI2 && FTLM>FTLM1)
      result=80;
   else
   //--- Pattern 4
   if(cb_UsePattern4 && SATL>SATL1 && FATL>FATL1 && RBCI>RBCI1 && FTLM<FTLM1 && FTLM2<=FTLM1)
      result=80;
   else
   //--- Pattern 5
   if(cb_UsePattern5 && SATL>SATL1 && STLM>=0 && PCCI1<=-100 && PCCI1<PCCI && PCCI>-100 && RBCI>RBCI1 && RBCI1<=RBCI2 && RBCI1<-1)
      result=80;
   else
   //--- Pattern 6
   if(cb_UsePattern6 && SATL>SATL1 && STLM<0 && PCCI1<=-100 && PCCI>-100)
      result=80;
   else
   //--- Pattern 7
   if(cb_UsePattern7 && FATL>FATL1 && FATL1<=SATL1 && FATL>SATL && FATL1<=FATL2)
      result=80;
   //--- Pattern 8
   if(cb_UsePattern8 && FATL>FATL1 && FATL1<=SATL1 && FATL>SATL && FATL1<=RFTL1 && FATL>RFTL)
      result=80;
   
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CSignalATCF::ShortCondition(void)
  {
   if(!CalculateIndicators() || m_open.GetData(1)<m_close.GetData(1))
      return 0;
   int result=0;
   //--- Close
   if(m_low.GetData(2)>m_close.GetData(1) || (STLM1>=0 && STLM<0) || (FTLM1>=0 && FTLM<0) || (PCCI1>PCCI && PCCI1>=PCCI2) || (RBCI<RBCI1 && RBCI1<=RBCI2 && RBCI1>1) || (RBCI1>=0 && RBCI<0))
      result=40;
   //--- Pattern 1
   if(cb_UsePattern1 && FTLM<0 && STLM<STLM1 && PCCI>-100)
      result=80;
   else
   //--- Pattern 2
   if(cb_UsePattern2 && STLM<0 && FATL<FATL1 && FTLM<FTLM1 && RBCI<RBCI1 && (STLM<=STLM1 || (STLM>STLM1 && RBCI>-1)))
      result=80;
   else
   //--- Pattern 3
   if(cb_UsePattern3 && STLM<0 && FATL<FATL1 && RBCI<RBCI1 && RBCI1>1 && RBCI1>=RBCI2 && FTLM<FTLM1)
      result=80;
   else
   //--- Pattern 4
   if(cb_UsePattern4 && SATL<SATL1 && FATL<FATL1 && RBCI<RBCI1 && FTLM>FTLM1 && FTLM2>=FTLM1)
      result=80;
   else
   //--- Pattern 5
   if(cb_UsePattern5 && SATL<SATL1 && STLM<=0 && PCCI1>=100 && PCCI1>PCCI && PCCI<100 && RBCI<RBCI1 && RBCI1>=RBCI2 && RBCI1>1)
      result=80;
   else
   //--- Pattern 6
   if(cb_UsePattern6 && SATL<SATL1 && STLM>0 && PCCI1>=100 && PCCI<100)
      result=80;
   else
   //--- Pattern 7
   if(cb_UsePattern7 && FATL<FATL1 && FATL1>=SATL1 && FATL<SATL && FATL1>=FATL2)
      result=80;
   //--- Pattern 8
   if(cb_UsePattern8 && FATL<FATL1 && FATL1>=SATL1 && FATL<SATL && FATL1>=RFTL1 && FATL<RFTL)
      result=80;
   
   return result;
  }
//+------------------------------------------------------------------+
