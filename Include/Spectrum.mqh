//+------------------------------------------------------------------+
//|                                                     Spectrum.mqh |
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
class CSpectrum
  {
private:
   uint              ci_HistoryBars;               //Bars for analysis
   string            cs_Symbol;                    //Symbol
   ENUM_TIMEFRAMES   ce_Timeframe;                 //Timeframe
   double            cda_AR[];                     //Autoregression coefficients
   double            cda_QuotesCenter[];           //Shift quotes mean to 0
   int               IP;                           //Number of autoregression coefficients
   double            cad_Spectr[];                 //array of spectr
      
   bool              Autoregression(void);
   bool              Spectrum(void);
   bool              LevinsonRecursion(const double &R[],double &A[],double &K[]);
   void              FHT(double &f[], ulong ldn);  // Fast Hartley Transform
  
public:
                     CSpectrum(uint bars=2880, string symbol=NULL, ENUM_TIMEFRAMES period=PERIOD_CURRENT);
                    ~CSpectrum();
   void              SetTimeframe(ENUM_TIMEFRAMES value)    {  ce_Timeframe=value;     }
   void              SetHistoryBars(uint value)             {  ci_HistoryBars=value;   }
   bool              GetPeriods(int &FAT, int &SAT);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSpectrum::CSpectrum(uint bars=2880, string symbol=NULL, ENUM_TIMEFRAMES period=PERIOD_CURRENT)
  {
   ci_HistoryBars =  bars;
   cs_Symbol      =  (symbol==NULL ? _Symbol : symbol);
   ce_Timeframe   =  period;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSpectrum::~CSpectrum()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSpectrum::Autoregression(void)
  {
   //--- check for insufficient data
   if(Bars(cs_Symbol,ce_Timeframe)<(int)ci_HistoryBars)
      return false;

//--- make all prices available
   double close[];
   int NumTS=CopyClose(cs_Symbol,ce_Timeframe,1,ci_HistoryBars,close);
   if(NumTS<=0)
      return false;
   double Mean=MathMean(close);
   if(ArraySize(cda_QuotesCenter)!=NumTS)
     {
      if(ArrayResize(cda_QuotesCenter,NumTS)<NumTS)
         return false;
     }
   for(int i=0;i<NumTS;i++)
      cda_QuotesCenter[i]=close[i]-Mean;                 // Centered time series
  
   int NLags=(int)MathRound(10*MathLog10(NumTS));
   if(NLags>NumTS/5)NLags=NumTS/5;
   if(NLags<3)NLags=3;                                   // Number of lags for ACF
   
   IP=NLags*5;
   if(IP>NumTS*0.7)
      IP=(int)MathRound(NumTS*0.7);                      // Autoregressive model order
  
   double cor[],tdat[];
   if(IP<=0 || ArrayResize(cor,IP)<IP || ArrayResize(cda_AR,IP)<IP || ArrayResize(tdat,IP)<IP)
      return false;
   double a=0;
   for(int i=0;i<NumTS;i++)
      a+=cda_QuotesCenter[i]*cda_QuotesCenter[i];    
   for(int i=1;i<=IP;i++)
     {  
      double c=0;
      for(int k=i;k<NumTS;k++)
      c+=cda_QuotesCenter[k]*cda_QuotesCenter[k-i];
      cor[i-1]=c/a;                                      // Autocorrelation
     } 
  
   if(!LevinsonRecursion(cor,cda_AR,tdat))               // Levinson-Durbin recursion
      return false;
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSpectrum::Spectrum(void)
  {
   if(!Autoregression())
      return false;

   int p=12;                                             // n = 2**p = 4096
   int n=(1<<p);                                         // Number of X-points
   if(n<=10)
      return false;

   int m=n<<1;
   double tdat[];
   ArrayResize(cad_Spectr,n);                            // AR Spectrum. Y-axis
   ArrayResize(tdat,m);
   ArrayInitialize(tdat,0);
   tdat[0]=1;
   for(int i=0;i<IP;i++)
      tdat[i+1]=-cda_AR[i];
   FHT(tdat,p+1);                                        // Fast Hartley transform (FHT)
   for(int k=1,i=m-1;k<i;++k,--i)
      tdat[k]=tdat[k]*tdat[k]+tdat[i]*tdat[i];
   tdat[0]=2*tdat[0]*tdat[0];
   ArrayCopy(cad_Spectr,tdat,0,0,n);
   double c=-DBL_MAX;
   for(int i=0;i<n;i++)
     {
      cad_Spectr[i]=1/cad_Spectr[i];
      if(c<cad_Spectr[i])
         c=cad_Spectr[i];                                // c = max(cad_Spectrum)
     } 
   for(int i=0;i<n;i++)                                  // logarithmic scale
     {
      double b=cad_Spectr[i]/c;                          // normalization
      if(b<1e-7)
         b=1e-7; 
      cad_Spectr[i]=NormalizeDouble(10*MathLog10(b),3);                     // dB
     }
   return true;
  }
//+-----------------------------------------------------------------------------------+
//| Radix-2 decimation in frequency (DIF) fast Hartley transform (FHT).               |
//| Length is N = 2 ** ldn                                                            |
//+-----------------------------------------------------------------------------------+
void CSpectrum::FHT(double &f[], ulong ldn)
  {
   const ulong n = ((ulong)1<<ldn);
   for (ulong ldm=ldn; ldm>=1; --ldm)
     {
      const ulong m = ((ulong)1<<ldm);
      const ulong mh = (m>>1);
      const ulong m4 = (mh>>1);
      const double phi0 = M_PI / (double)mh;
      for (ulong r=0; r<n; r+=m)
        {
         for (ulong j=0; j<mh; ++j)
           {
            uint t1 =(int)(r+j);
            uint t2 =(int)(t1+mh);
            double u = f[t1];
            double v = f[t2];
            f[t1] = u + v;
            f[t2] = u - v;
           }
         double ph = 0.0;
         for (ulong j=1; j<m4; ++j)
           {
            ulong k = mh-j;
            ph += phi0;
            double s=MathSin(ph);
            double c=MathCos(ph);
            uint t1 =(int)(r+mh+j);
            uint t2 =(int)(r+mh+k);
            double pj = f[t1];
            double pk = f[t2];
            f[t1] = pj * c + pk * s;
            f[t2] = pj * s - pk * c;
           }
        }
     }
   if(n>2)
     {
      uint r = 0;
      for (uint i=1; i<n; i++)
        {
         ulong k = n;
         do {k = k>>1; r = (int)(r^k);} while ((r & k)==0);
         if (r>i) {double tmp = f[i]; f[i] = f[r]; f[r] = tmp;}
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CSpectrum::GetPeriods(int &FAT,int &SAT)
  {
   if(!Spectrum())
      return false;
   FAT=SAT=0;
   int total=ArraySize(cad_Spectr)-1;
   for(int i=1;(i<total);i++)
     {
      int temp=2*(total+1)/i;
      if(cad_Spectr[i]==0 || temp>(int)ci_HistoryBars/4)
         continue;
      if((cad_Spectr[i]-cad_Spectr[i+1])>=0 && (cad_Spectr[i]-cad_Spectr[i-1])>0)
        {
         if(SAT==0)
            SAT=temp;
         else
           {
            if(cad_Spectr[i]<-40)
              {
               if(FAT==0)
                  FAT=temp;
               break;
              }
            if(temp>=20)
               FAT=temp;
           }
        }
     }
   if(SAT==0 || FAT==0)
      return false;
   return true;
  }
//+-----------------------------------------------------------------------------------+
//| Calculate the Levinson-Durbin recursion for the autocorrelation sequence R[]      |
//| and return the autoregression coefficients A[] and partial autocorrelation        |
//| coefficients K[]                                                                  |
//+-----------------------------------------------------------------------------------+
bool CSpectrum::LevinsonRecursion(const double &R[],double &A[],double &K[])
  {
   int p,i,m;
   double km,Em,Am1[],err;
   
   p=ArraySize(R);
   if(ArrayResize(Am1,p)<=0 || (ArraySize(A)<p && ArrayResize(A,p)<=0) || (ArraySize(K)<p && ArrayResize(K,p)<=0))
      return false;
   ArrayInitialize(Am1,0);
   ArrayInitialize(A,0);
   ArrayInitialize(K,0);
   km=0;
   Em=1;
   for(m=0;m<p;m++)
     {
      err=0;
      for(i=0;i<m;i++)
         err+=Am1[i]*R[m-i-1];
      km=(R[m]-err)/Em;
      K[m]=km; A[m]=km;
      for(i=0;i<m;i++)
         A[i]=(Am1[i]-km*Am1[m-i-1]);
      Em=(1-km*km)*Em;
      ArrayCopy(Am1,A);
     }
   return true;
  }
//+------------------------------------------------------------------+
