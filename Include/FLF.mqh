//+------------------------------------------------------------------+
//|                                                          FLF.mqh |
//|                                              Copyright 2017, DNG |
//|                                      https://forex-start.ucoz.ua |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, DNG"
#property link      "https://forex-start.ucoz.ua"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Math\\Stat\\Math.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CFLF
  {
private:
   int         ci_N;                      //Lenght of filter
   double      cd_Fs;                     //Frequency
   double      cda_H[];                   //Filter Impulses

public:
                     CFLF();
                    ~CFLF();
   bool              CalcImpulses(int period);     //Calculate filter impulses
   double            AdaptiveTrendLine(string symbol=NULL, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT, int shift=1);
   double            ReferenceTrendLine(string symbol=NULL, ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT, int shift=1);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CFLF::CFLF()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CFLF::~CFLF()
  {
   ZeroMemory(cda_H);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CFLF::CalcImpulses(int period)
  {
   if(period<20)
      return false;
   int N=(int)(period/2);
   if(ArraySize(cda_H)!=N)
      if(ArrayResize(cda_H,N)<N)
         return false;
   double H_id[],W[];
   if(ArrayResize(H_id,N)<N || ArrayResize(W,N)<N)
      return false;
  
   cd_Fs=1/(double)period;
   for (int i=0;i<N;i++)
     {
      if (i==0)
         H_id[i] = 2*M_PI*cd_Fs;
      else
         H_id[i] = MathSin(2*M_PI*cd_Fs*i )/(M_PI*i);
      
      W[i] = 0.42 - 0.5 * MathCos((2*M_PI*i) /( N-1)) + 0.08 * MathCos((4*M_PI*i) /( N-1));
      cda_H[i] = H_id[i] * W[i];
     }
      
   //Normalization
   double SUM=MathSum(cda_H);
   if(SUM==QNaN || SUM==0)
      return false;
   for (int i=0; i<N; i++)
      cda_H[i]/=SUM; //summ of coefficients equal 1 
   //---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFLF::AdaptiveTrendLine(string symbol=NULL,ENUM_TIMEFRAMES timeframe=0,int shift=1)
  {
   string symb=(symbol==NULL ? _Symbol : symbol);
   int bars=ArraySize(cda_H);
   double values[];
   if(CopyClose(symb,timeframe,shift,bars,values)<=0)
      return QNaN;
   double mean=MathMean(values);
   double result=0;
   for(int i=0;i<bars;i++)
      result+=cda_H[i]*(values[bars-i-1]-mean);
   result+=mean;
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CFLF::ReferenceTrendLine(string symbol=NULL,ENUM_TIMEFRAMES timeframe=0,int shift=1)
  {
   shift+=(int)(1/(2*cd_Fs));
   return AdaptiveTrendLine(symbol,timeframe,shift);
  }
//+------------------------------------------------------------------+
