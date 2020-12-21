// This function check whether or not there is a new candle

bool IsNewCandle()
  {
   static int BarsOnChart=0;
   if(Bars(Symbol(),PERIOD_CURRENT) == BarsOnChart)
      return (false);
   BarsOnChart = Bars(Symbol(),PERIOD_CURRENT);
   return(true);
  }
