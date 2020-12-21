//-----------------------------------------------------------------------------------
//                                                                     TSAnalysis.mqh
//                                                                      2012, victorg
//                                                                http://www.mql5.com
//-----------------------------------------------------------------------------------
#property copyright "2012, victorg"
#property link      "http://www.mql5.com"
#property version   "2.00"

#include <Object.mqh>

#import "shell32.dll"
int ShellExecuteW(int hwnd,string lpOperation,string lpFile,string lpParameters,
                  string lpDirectory,int nShowCmd);
#import
#import "kernel32.dll"
int DeleteFileW(string lpFileName);
int MoveFileW(string lpExistingFileName,string lpNewFileName);
#import
//-----------------------------------------------------------------------------------
class TSAnalysis:public CObject
  {
protected:
  double    TS[];                    // Time series
  double    TSort[];                 // Sorted time series
  double    TSCenter[];              // Centered time series ( TS[] - mean )
  int       NumTS;                   // Number of time series data points
  double    MinTS;                   // Minimum time series value
  double    MaxTS;                   // Maximum time series value
  double    Median;                  // Median
  double    Mean;                    // Mean (average)
  double    Var;                     // Variance
  double    uVar;                    // Unbiased variance
  double    StDev;                   // Standard deviation
  double    uStDev;                  // Unbiaced standard deviation
  double    Skew;                    // Skewness
  double    Kurt;                    // Kurtosis
  double    ExKurt;                  // Excess Kurtosis
  double    JBTest;                  // Jarque-Bera test
  double    JBpVal;                  // JB test p-value
  double    AJBTest;                 // Adjusted Jarque-Bera test
  double    AJBpVal;                 // AJB test p-values
  double    maxOut;                  // Sequence Plot. Border of outliers
  double    minOut;                  // Sequence Plot. Border of outliers
  double    XHist[];                 // Histogram. X-axis
  double    YHist[];                 // Histogram. Y-axis
  double    Xnpp[];                  // Normal Probability Plot. X-axis
  int       NLags;                   // Number of lags for ACF and PACF Plot
  double    ACF[];                   // Autocorrelation function (correlogram)
  double    UPLim;                   // ACF. Upper limit (5% significance level)
  double    LOLim;                   // ACF. Lower limit (5% significance level)
  double    CBup[];                  // ACF. Upper limit (confidence bands)
  double    CBlo[];                  // ACF. Lower limit (confidence bands)
  double    Spect[];                 // ACF Spectrum. Y-axis
  double    PACF[];                  // Partial autocorrelation function
  int       IP;                      // Autoregressive model order
  double    ARSp[];                  // AR Spectrum. Y-axis
  
public:
            TSAnalysis();
  void      Calc(double &ts[]);      // Calculation

protected:
  double    ndtri(double y);         // Inverse of Normal distribution function
  void      LevinsonRecursion(const double &R[],double &A[],double &K[]);
  void      fht(double &f[], ulong ldn); // Fast Hartley Transform
  virtual void show();               // Show result
  };
//-----------------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------------
void TSAnalysis::TSAnalysis()
  {

  }
//-----------------------------------------------------------------------------------
// Calculate and draw
//-----------------------------------------------------------------------------------
void TSAnalysis::Calc(double &ts[])
  {
  int i,k,m,n,p;
  double sum2,sum3,sum4,a,b,c,v,delta;
  double cor[],ar[],tdat[];
  
  NumTS=ArraySize(ts);                          // Number of time series data points
  if(NumTS<8)                                   // Number of data points is too small
    {
    Print("TSAnalysis: Error. Number of TS data points is too small!");
    return;
    }
  ArrayResize(TS,NumTS);
  ArrayCopy(TS,ts);                                  // Time series
  ArrayResize(TSort,NumTS);
  ArrayCopy(TSort,ts);
  ArraySort(TSort);                                  // Sorted time series
  MinTS=TSort[0];                                    // Minimum time series value
  MaxTS=TSort[NumTS-1];                              // Maximum time series value
  
  i=(NumTS-1)/2;
  Median=TSort[i];                                   // Median
  if((NumTS&0x01)==0)Median=(Median+TSort[i+1])/2.0; // Median
  
  Mean=0; sum2=0; sum3=0; sum4=0;
  for(i=0;i<NumTS;i++)
    {
    n=i+1; delta=TS[i]-Mean;
    a=delta/n; Mean+=a;                              // Mean (average)
    sum4+=a*(a*a*delta*i*(n*(n-3.0)+3.0)+6.0*a*sum2-4.0*sum3); // sum of fourth degree
    b=TS[i]-Mean;
    sum3+=a*(b*delta*(n-2.0)-3.0*sum2);                  // sum of third degree
    sum2+=delta*b;                                   // sum of second degree
    }
  if(sum2<1.e-250)                                   // variance is too small
    {
    Print("TSAnalysis: Error. The variance is too small or zero!");
    return;
    }
  ArrayResize(TSCenter,NumTS);
  for(i=0;i<NumTS;i++)TSCenter[i]=TS[i]-Mean;        // Centered time series
  Var=sum2/NumTS;                                    // Variance
  uVar=sum2/(NumTS-1);                               // Unbiased variance
  StDev=MathSqrt(Var);                               // Standard deviation
  uStDev=MathSqrt(uVar);                             // Unbiased standard deviation
  Skew=MathSqrt(NumTS)*sum3/sum2/MathSqrt(sum2);     // Skewness
  Kurt=NumTS*sum4/sum2/sum2;                         // Kurtosis
  ExKurt=Kurt-3;                                     // Excess kurtosis
  JBTest=(NumTS/6.0)*(Skew*Skew+ExKurt*ExKurt/4);    // Jarque-Bera test
  JBpVal=MathExp(-JBTest/2.0);                       // JB test p-value
  a=6*(NumTS-2.0)/(NumTS+1.0)/(NumTS+3.0);
  b=3*(NumTS-1.0)/(NumTS+1.0);
  AJBTest=Skew*Skew/a+(Kurt-b)*(Kurt-b)/             // Adjusted Jarque-Bera test
          (24.0*NumTS*(NumTS-2.0)*(NumTS-3.0)/(NumTS+1.0)/
          (NumTS+1.0)/(NumTS+3.0)/(NumTS+5.0));
  AJBpVal=MathExp(-AJBTest/2.0);                     // AJB test p-value
  
  // Time Series Plot. Y=TS[],line1=maxOut,line2=Mean,line3=minOut
  delta=(1.55+0.8*MathLog10(NumTS/10.0)*MathSqrt(Kurt-1))*StDev;
  maxOut=Mean+delta;                          // Time Series Plot. Border of outliers
  minOut=Mean-delta;                          // Time Series Plot. Border of outliers
  
  // Histogram. X=XHist[],Y=YHist[]
  n=(int)MathRound((Kurt+1.5)*MathPow(NumTS,0.4)/6.0);
  if((n&0x01)==0)n--; if(n<5)n=5;                    // Number of bins
  ArrayResize(XHist,n);
  ArrayResize(YHist,n);
  ArrayInitialize(YHist,0.0);
  a=MathAbs(TSort[0]-Mean); b=MathAbs(TSort[NumTS-1]-Mean);
  if(a<b)a=b; v=Mean-a;
  delta=2.0*a/n;
  for(i=0;i<n;i++)XHist[i]=(v+(i+0.5)*delta-Mean)/StDev; // Histogram. X-axis
  for(i=0;i<NumTS;i++)
    {
    k=(int)((TS[i]-v)/delta);
    if(k>(n-1))k=n-1;
    YHist[k]++;
    }
  for(i=0;i<n;i++)YHist[i]=YHist[i]/NumTS/delta*StDev;   // Histogram. Y-axis
  
  // Normal Probability Plot. X=Xnpp[],Y=TSort[]
  ArrayResize(Xnpp,NumTS);
  Xnpp[NumTS-1]=MathPow(0.5,1.0/NumTS);
  Xnpp[0]=1-Xnpp[NumTS-1];
  a=NumTS+0.365;
  for(i=1;i<(NumTS-1);i++)Xnpp[i]=(i+0.6825)/a;
  for(i=0;i<NumTS;i++)Xnpp[i]=ndtri(Xnpp[i]);      // Normal Probability Plot. X-axis

  // Autocorrelation function (correlogram)
  NLags=(int)MathRound(10*MathLog10(NumTS));
  if(NLags>NumTS/5)NLags=NumTS/5;
  if(NLags<3)NLags=3;                         // Number of lags for ACF and PACF Plot

  IP=NLags*5;
  if(IP>NumTS*0.7)IP=(int)MathRound(NumTS*0.7);        // Autoregressive model order
  
  ArrayResize(cor,IP);
  ArrayResize(ar,IP);
  ArrayResize(tdat,IP);
  a=0;
  for(i=0;i<NumTS;i++)a+=TSCenter[i]*TSCenter[i];    
  for(i=1;i<=IP;i++)
    {  
    c=0;
    for(k=i;k<NumTS;k++)c+=TSCenter[k]*TSCenter[k-i];
    cor[i-1]=c/a;                                      // Autocorrelation
    } 
  
  LevinsonRecursion(cor,ar,tdat);                      // Levinson-Durbin recursion
  
  ArrayResize(ACF,NLags);
  ArrayCopy(ACF,cor,0,0,NLags);                        // ACF
  ArrayResize(PACF,NLags);
  ArrayCopy(PACF,tdat,0,0,NLags);                      // PACF
  
  UPLim=1.96/MathSqrt(NumTS);                  // Upper limit (5% significance level)
  LOLim=-UPLim;                                // Lower limit (5% significance level)
  ArrayResize(CBup,NLags);
  ArrayResize(CBlo,NLags);
  a=0;
  for(i=0;i<NLags;i++)
    {
    a+=ACF[i]*ACF[i];  
    CBup[i]=1.96*MathSqrt((1+2*a)/NumTS);           // Upper limit (confidence bands)
    CBlo[i]=-CBup[i];                               // Lower limit (confidence bands)
    }
  
  // Spectrum Plot
  n=320;                                              // Number of X-points
  ArrayResize(Spect,n);
  v=M_PI/n;
  for(i=0;i<n;i++)
    {
    a=i*v; b=0;
    for(k=0;k<NLags;k++)b+=((double)NLags-k)/(NLags+1.0)*ACF[k]*MathCos(a*(k+1));
    Spect[i]=2.0*(1+2*b);                             // Spectrum Y-axis
    }

  // AR Spectral Estimates Plot (maximum entropy method)
  p=12;                                               // n = 2**p = 4096
  n=((ulong)1<<p);                                    // Number of X-points
  m=n<<1;
  ArrayResize(ARSp,n);                                // AR Spectrum. Y-axis
  ArrayResize(tdat,m);
  ArrayInitialize(tdat,0);
  tdat[0]=1;
  for(i=0;i<IP;i++)tdat[i+1]=-ar[i];
  fht(tdat,p+1);                                      // Fast Hartley transform (FHT)
  for(k=1,i=m-1;k<i;++k,--i) tdat[k]=tdat[k]*tdat[k]+tdat[i]*tdat[i];
  tdat[0]=2*tdat[0]*tdat[0];
  ArrayCopy(ARSp,tdat,0,0,n);
  c=-DBL_MAX;
  for(i=0;i<n;i++)
    {
    ARSp[i]=1/ARSp[i];
    if(c<ARSp[i])c=ARSp[i];                           // c = max(ARSp)
    } 
  for(i=0;i<n;i++)                                    // logarithmic scale
    {
    b=ARSp[i]/c;                                      // normalization
    if(b<1e-7)b=1e-7; 
    ARSp[i]=10*MathLog10(b);                          // dB
    }

  // Vizualization
  show();
  
  return;
  }
//-----------------------------------------------------------------------------------
// virtual. Show result
//-----------------------------------------------------------------------------------
void TSAnalysis::show()
  {
  int i,k,n,fhandle;
  double a,x;
  string str="",path,datafile;
  
  str=StringFormat("var NumTS=%.12g;\n",NumTS);
  str+=StringFormat("var MinTS=%.12g;\n",MinTS);
  str+=StringFormat("var MaxTS=%.12g;\n",MaxTS);
  str+=StringFormat("var Mean=%.12g;\n",Mean);
  str+=StringFormat("var maxOut=%.12g;\n",maxOut);
  str+=StringFormat("var minOut=%.12g;\n",minOut);
  
  // Text
  str+="var s=[";
  str+=StringFormat("'Mean','=% g',",Mean);
  str+=StringFormat("'Var','=% g',",Var);
  str+=StringFormat("'StDev','=% g',",StDev);
  str+=StringFormat("'uVar','=% g',",uVar);
  str+=StringFormat("'uStDev','=% g',",uStDev);
  str+=StringFormat("'Skew','=% g',",Skew);
  str+=StringFormat("'ExKurt','=% g',",ExKurt);
  str+="'','','Jarque-Bera test:','',";
  str+=StringFormat("'JB','=% g',",JBTest);
  str+=StringFormat("'p-val','=% f',",JBpVal);
  str+="'','','Adjusted J-B test:','',";
  str+=StringFormat("'AJB','=% g',",AJBTest);
  str+=StringFormat("'p-val','=% f'",AJBpVal);
  str+="];\n";
  
  // Time Series Plot
  k=0;
  str+="var TS=[";
  for(i=0;i<NumTS-1;i++)
    {
    str+=StringFormat("%.12g,",TS[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("%.12g];\n",TS[NumTS-1]);
  
  // Lag Plot
  k=0;
  str+="var LagP=[";
  for(i=0;i<NumTS-2;i++)
    {
    str+=StringFormat("[%.12g,%.12g],",TS[i],TS[i+1]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%.12g,%.12g]];\n",TS[NumTS-2],TS[NumTS-1]);
  
  // Histogram
  n=ArraySize(XHist);
  str+="var HistP=[";
  k=0;
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("[%.4f,%.4f],",XHist[i],YHist[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%.4f,%.4f]];\n",XHist[n-1],YHist[n-1]);
  a=XHist[1]-XHist[0];
  str+="var Nd=[";                                   //Normal distribution line
  n=n+4;
  k=0;
  for(i=0;i<n-1;i++)
    {
    x=a*(i-n/2);
    str+=StringFormat("[%.4f,%.4f],",x,MathExp(-x*x/2)/MathSqrt(2*M_PI));
    if(10<k++){k=0; str+="\n";}
    }
  x=a*(n-1-n/2);
  str+=StringFormat("[%.4f,%.4f]];\n",x,MathExp(-x*x/2)/MathSqrt(2*M_PI));
  
  // Normal Probability Plot
  k=0;
  str+="var Xnpp=[";
  for(i=0;i<NumTS-1;i++)
    {
    str+=StringFormat("[%.12g,%.12g],",Xnpp[i],TSort[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%.12g,%.12g]];\n",Xnpp[NumTS-1],TSort[NumTS-1]);
  str+=StringFormat("var Ndl=[[%.12g,%.12g],[%.12g,%.12g]];\n",           // Line
                Xnpp[0],Xnpp[0]*StDev+Mean,Xnpp[NumTS-1],Xnpp[NumTS-1]*StDev+Mean);
  
  // Autocorrelation function (correlogram)
  str+=StringFormat("var NLags=%i;\n",NLags);        // ACF. Number of lags
  k=0;
  str+="var ACF=[";
  for(i=0;i<NLags-1;i++)
    {
    str+=StringFormat("[%i,%.4f],",i+1,ACF[i]);     // ACF
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%i,%.4f]];\n",NLags,ACF[NLags-1]);
  str+=StringFormat("var UPLim=%.4f;\n",UPLim);
  str+=StringFormat("var CBup=[[0,%.4f],",UPLim);
  k=0;
  for(i=0;i<NLags;i++)
    {
    str+=StringFormat("[%i,%.4f],",i+1,CBup[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%i,%.4f]];\n",NLags+1,CBup[NLags-1]);
  str+=StringFormat("var CBlo=[[0,%.4f],",LOLim);
  k=0;
  for(i=0;i<NLags;i++)
    {
    str+=StringFormat("[%i,%.4f],",i+1,CBlo[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%i,%.4f]];\n",NLags+1,CBlo[NLags-1]);
  
  // Spectrum
  k=0;
  n=ArraySize(Spect);
  str+="var Spec=[";
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("%.4f,",Spect[i]);
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("%.4f];\n",Spect[n-1]);
  
  // Partial autocorrelation function
  k=0;
  str+="var PACF=[";
  for(i=0;i<NLags-1;i++)
    {
    str+=StringFormat("[%i,%.4f],",i+1,PACF[i]);    // PACF
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%i,%.4f]];\n",NLags,PACF[NLags-1]);
  
  // Autoregressive Spectral Estimates
  str+=StringFormat("var IP=%i;\n",IP);              // AR model order
  k=0;
  n=ArraySize(ARSp);
  str+="var ARSp=[";
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("%.3f,",ARSp[i]);             // AR Spectrum. Y-axis
    if(10<k++){k=0; str+="\n";}
    }
  str+=StringFormat("%.3f];\n",ARSp[n-1]);          // AR Spectrum. Y-axis
  
  // Save
  fhandle=FileOpen("TSDat.txt",FILE_WRITE|FILE_TXT|FILE_ANSI);
  if(fhandle==INVALID_HANDLE)return;
  FileWriteString(fhandle,str);
  FileClose(fhandle);
  
  //Move data file and Execute
  datafile=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\TSDat.txt";
  path=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Scripts\\TSAnalysis\\";
  DeleteFileW(path+"TSDat.txt");
  MoveFileW(datafile,path+"TSDat.txt");
  ShellExecuteW(NULL,"open",path+"TSA.htm",NULL,NULL,1);

  return;
  }
//-----------------------------------------------------------------------------------
// Inverse of Normal distribution function
// Prototype:
// Cephes Math Library Release 2.8: June, 2000
// Copyright 1984, 1987, 1989, 2000 by Stephen L. Moshier
//-----------------------------------------------------------------------------------
double TSAnalysis::ndtri(double y0)
  {
  static double s2pi =2.50662827463100050242E0; // sqrt(2pi)
  static double P0[5]={-5.99633501014107895267E1,  9.80010754185999661536E1,
                       -5.66762857469070293439E1,  1.39312609387279679503E1,
                       -1.23916583867381258016E0};
  static double Q0[8]={ 1.95448858338141759834E0,  4.67627912898881538453E0,
                        8.63602421390890590575E1, -2.25462687854119370527E2,
                        2.00260212380060660359E2, -8.20372256168333339912E1,
                        1.59056225126211695515E1, -1.18331621121330003142E0};
  static double P1[9]={ 4.05544892305962419923E0,  3.15251094599893866154E1,
                        5.71628192246421288162E1,  4.40805073893200834700E1,
                        1.46849561928858024014E1,  2.18663306850790267539E0,
                       -1.40256079171354495875E-1,-3.50424626827848203418E-2,
                       -8.57456785154685413611E-4};
  static double Q1[8]={ 1.57799883256466749731E1,  4.53907635128879210584E1,
                        4.13172038254672030440E1,  1.50425385692907503408E1,
                        2.50464946208309415979E0, -1.42182922854787788574E-1,
                       -3.80806407691578277194E-2,-9.33259480895457427372E-4};
  static double P2[9]={ 3.23774891776946035970E0,  6.91522889068984211695E0,
                        3.93881025292474443415E0,  1.33303460815807542389E0,
                        2.01485389549179081538E-1, 1.23716634817820021358E-2,
                        3.01581553508235416007E-4, 2.65806974686737550832E-6,
                        6.23974539184983293730E-9};
  static double Q2[8]={ 6.02427039364742014255E0,  3.67983563856160859403E0,
                        1.37702099489081330271E0,  2.16236993594496635890E-1,
                        1.34204006088543189037E-2, 3.28014464682127739104E-4,
                        2.89247864745380683936E-6, 6.79019408009981274425E-9};
  double x,y,z,y2,x0,x1,a,b;
  int i,code;

  if(y0<=0.0){Print("Function ndtri() error!"); return(-DBL_MAX);}
  if(y0>=1.0){Print("Function ndtri() error!"); return(DBL_MAX);}

  code=1; y=y0;
  if(y>(1.0-0.13533528323661269189)){y=1.0-y; code=0;}  // 0.135... = exp(-2)
  if(y>0.13533528323661269189)                          // 0.135... = exp(-2)
    {
    y=y-0.5; y2=y*y;
    a=P0[0]; for(i=1;i<5;i++)a=a*y2+P0[i];
    b=y2+Q0[0]; for(i=1;i<8;i++)b=b*y2+Q0[i];
    x=y+y*(y2*a/b);
    x=x*s2pi; 
    return(x);
    }
  x=MathSqrt(-2.0*MathLog(y));
  x0=x-MathLog(x)/x;
  z=1.0/x;
  if(x<8.0)                               // y > exp(-32) = 1.2664165549e-14
    {
    a=P1[0]; for(i=1;i<9;i++)a=a*z+P1[i];
    b=z+Q1[0]; for(i=1;i<8;i++)b=b*z+Q1[i];
    x1=z*a/b;
    }
  else
    {
    a=P2[0]; for(i=1;i<9;i++)a=a*z+P2[i];
    b=z+Q2[0]; for(i=1;i<8;i++)b=b*z+Q2[i];
    x1=z*a/b;
    }
  x=x0-x1;
  if(code!=0)x=-x;

  return(x);
  }
//-----------------------------------------------------------------------------------
// Calculate the Levinson-Durbin recursion for the autocorrelation sequence R[]
// and return the autoregression coefficients A[] and partial autocorrelation
// coefficients K[]
//-----------------------------------------------------------------------------------
void TSAnalysis::LevinsonRecursion(const double &R[],double &A[],double &K[])
  {
  int p,i,m;
  double km,Em,Am1[],err;

  p=ArraySize(R);
  ArrayResize(Am1,p);
  ArrayInitialize(Am1,0);
  ArrayInitialize(A,0);
  ArrayInitialize(K,0);
  km=0;
  Em=1;
  for(m=0;m<p;m++)
    {
    err=0;
    for(i=0;i<m;i++)err+=Am1[i]*R[m-i-1];
    km=(R[m]-err)/Em;
    K[m]=km; A[m]=km;
    for(i=0;i<m;i++)A[i]=(Am1[i]-km*Am1[m-i-1]);
    Em=(1-km*km)*Em;
    ArrayCopy(Am1,A);
    }
  return;
  }
//-----------------------------------------------------------------------------------
// Radix-2 decimation in frequency (DIF) fast Hartley transform (FHT).
// Length is N = 2 ** ldn
//-----------------------------------------------------------------------------------
void TSAnalysis::fht(double &f[], ulong ldn)
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
        ulong t1 = r+j;
        ulong t2 = t1+mh;
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
        ulong t1 = r+mh+j;
        ulong t2 = r+mh+k;
        double pj = f[t1];
        double pk = f[t2];
        f[t1] = pj * c + pk * s;
        f[t2] = pj * s - pk * c;
        }
      }
    }
  if(n>2)
    {
    ulong r = 0;
    for (ulong i=1; i<n; i++)
      {
      ulong k = n;
      do {k = k>>1; r = r^k;} while ((r & k)==0);
      if (r>i) {double tmp = f[i]; f[i] = f[r]; f[r] = tmp;}
      }
    }
  }
//-----------------------------------------------------------------------------------

