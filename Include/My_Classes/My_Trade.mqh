//+------------------------------------------------------------------+
//|                                                     My_Trade.mqh |
//|                                                 Terence Beaujour |
//|                                            beaujour.t@hotmail.fr |
//+------------------------------------------------------------------+
#property copyright "Terence Beaujour"
#property link      "beaujour.t@hotmail.fr"

#include  <Trade/Trade.mqh>
#include  <Trade/PositionInfo.mqh>

CTrade            trade;
CPositionInfo     position;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class My_Trade
  {
protected:
   MqlTick           tick;
   double            bid,ask;
   double            points;
   int               total;
   uint              TrailStop;
   uint              TrailingStep;
   bool              sl_buyflag,tp_buyflag,sl_sellflag,tp_sellflag;
   bool              newcandle;

public:
   void              setTotal() {total=PositionsTotal();}
   void              setPoints() {points=Point();}
   void              setAll();
   void              setSlbuyflag(unsigned int sl);
   void              setTpbuyflag(unsigned int tp);
   void              setSlsellflag(unsigned int sl);
   void              setTpsellflag(unsigned int tp);
   void              setTrailStop(unsigned int trlstop);
   void              setTrailingStep(unsigned int trlingstep);
   int               getTotal() {return total;}
   unsigned int      getTrailStop() {return TrailStop;}
   unsigned int      getTrailingStep() {return TrailingStep;}
   double            getPoints() {return points;}
   bool              getSlbuyflag() {return sl_buyflag;}
   bool              getTpbuyflag() {return tp_buyflag;}
   bool              getSlsellflag() {return sl_sellflag;}
   bool              getTpsellflag() {return tp_sellflag;}
   bool              CatchLastTick();
   bool              CheckNewCandle();
   void              CloseAllSellPositions(int deviation=5);
   void              CloseAllLongPositions(int deviation=5);
   void              Buy(double volume, uint my_sl, uint my_tp);
   void              Sell(double volume, uint my_sl, uint my_tp);
   void              TrailingLongPositions();
   void              TrailingShortPositions();
  };




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setAll(void)
  {
   setPoints();
   setTotal();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool My_Trade::CatchLastTick(void)
  {
   if(SymbolInfoTick(Symbol(),tick))
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool My_Trade::CheckNewCandle(void)
  {
   static int BarsOnChart=0;
   if(Bars(Symbol(),PERIOD_CURRENT) == BarsOnChart)
      return (false);
   BarsOnChart = Bars(Symbol(),PERIOD_CURRENT);
   return(true);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::CloseAllSellPositions(int deviation=5)
  {
   setTotal();
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         if(position.PositionType()==POSITION_TYPE_SELL)
           {
            trade.PositionClose(ticket,deviation);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::CloseAllLongPositions(int deviation=5)
  {
   setTotal();
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         if(position.PositionType()==POSITION_TYPE_BUY)
           {
            trade.PositionClose(ticket,deviation);
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setSlbuyflag(uint sl)
  {
   if(sl!=0)
      sl_buyflag=true;
   else
      sl_buyflag=false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setTpbuyflag(uint tp)
  {
   if(tp!=0)
      tp_buyflag=true;
   else
      tp_buyflag=false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setSlsellflag(uint sl)
  {
   if(sl!=0)
      sl_sellflag=true;
   else
      sl_sellflag=false;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setTpsellflag(uint tp)
  {
   if(tp!=0)
      tp_sellflag=true;
   else
      tp_sellflag=false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setTrailStop(uint trlstop)
  {
   TrailStop=trlstop;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::setTrailingStep(uint trlingstep)
  {
   TrailingStep=trlingstep;
  }

//+------------------------------------------------------------------+
void  My_Trade::Buy(double volume, uint my_sl, uint my_tp)
  {
   double buy_sl = NormalizeDouble(tick.bid-getPoints()*my_sl,Digits());
   double buy_tp = NormalizeDouble(tick.bid+getPoints()*my_tp,Digits());

   if(getTpbuyflag() || getSlbuyflag())
     {
      if(getTpbuyflag() && !getSlbuyflag())
        {
         trade.Buy(volume,Symbol(),tick.ask,0,buy_tp);
        }
      else
         if(!getTpbuyflag() && getSlbuyflag())
           {
            trade.Buy(volume,Symbol(),tick.ask,buy_sl,0);
           }
         else
           {
            trade.Buy(volume,Symbol(),tick.ask,buy_sl,buy_tp);
           }
     }
   else
     {
      trade.Buy(volume,Symbol(),tick.ask,0,0);
     }
  }

//+------------------------------------------------------------------+
void My_Trade::Sell(double volume,uint my_sl,uint my_tp)
  {
   double sell_sl = NormalizeDouble(tick.ask+getPoints()*my_sl,Digits());
   double sell_tp = NormalizeDouble(tick.ask-getPoints()*my_tp,Digits());

   if(getTpsellflag() || getSlsellflag())
     {
      if(getTpsellflag() && !getSlsellflag())
        {
         trade.Sell(volume,Symbol(),tick.bid,0,sell_tp);
        }
      else
         if(!getTpsellflag() && getSlsellflag())
           {
            trade.Sell(volume,Symbol(),tick.bid,sell_sl,0);
           }
         else
           {
            trade.Sell(volume,Symbol(),tick.bid,sell_sl,sell_tp);
           }
     }
   else
     {
      trade.Sell(volume,Symbol(),tick.bid,0,0);
     }
  }


//+------------------------------------------------------------------+
void My_Trade::TrailingLongPositions()
  {
   setTotal();
   double trsl = NormalizeDouble(tick.bid-(getPoints()*getTrailingStep()),Digits());
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         if((position.PositionType()==POSITION_TYPE_BUY) && (tick.bid-position.PriceOpen()>=getTrailStop()*getPoints()) && (tick.bid-(getTrailingStep()*getPoints())>=position.StopLoss()))
           {
            trade.PositionModify(ticket,getTrailingStep(),position.TakeProfit());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void My_Trade::TrailingShortPositions()
  {
   setTotal();
   double trsl = NormalizeDouble(tick.ask+(getPoints()*getTrailingStep()),Digits());
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         if((position.PositionType()==POSITION_TYPE_SELL) && (position.PriceOpen()-tick.ask>=getTrailStop()*getPoints()) && (tick.ask+(getTrailingStep()*getPoints())<=position.StopLoss()))
           {
            trade.PositionModify(ticket,getTrailingStep(),position.TakeProfit());
           }
        }
     }
  }
//+------------------------------------------------------------------+
