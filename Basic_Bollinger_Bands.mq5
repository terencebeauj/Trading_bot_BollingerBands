//+------------------------------------------------------------------+
//|                                        Basic_Bollinger_Bands.mq5 |
//|                                                 Terence Beaujour |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+


// This is a basic example of how one can uses the MQL5 language to develop robust algorithm
// Add the parabolic Sar indicator for those who want to use it as a regular or trailing indicator
// Each position has a TP and SL and if the conditions are met, a trailing stop loss too
// Look at the Buyflag and sellflag variables to understand under wich conditions we want to open a position.

#property copyright "Terence Beaujour"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Includes all libraries
#include <Trade/trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trail.mqh>
#include <NewC.mqh>

// Instanciation of objects
CTrade my_trade;
CPositionInfo my_position;

// Inputs parameters (you can optimize them with the Genetic Algorithm of the MT5 platform)
input long my_magic_number;
input int my_slippage;
input double my_volume;
input unsigned int my_sl_buy;
input unsigned int my_tp_buy;
input unsigned int my_sl_sell;
input unsigned int my_tp_sell;
input double TrailStop = 100;
input double TrailStep = 50;

// Global variables
double bb_high_buffer[];
double bb_low_buffer[];
double bb_middle_buffer[];
double sar_buffer[];
double bb_handle,tick_point,my_bid,my_ask;
int sar_handle;
int tradenow=0,my_total;
int buyflag,sellflag;
bool sl_buy_flag,tp_buy_flag,sl_sell_flag,tp_sell_flag;
string my_symbol;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   my_symbol=Symbol();

   bb_handle=iBands(my_symbol,0,20,0,2.0,PRICE_CLOSE);
   sar_handle=iSAR(my_symbol,PERIOD_CURRENT,0.02,0.2);

   if(bb_handle==INVALID_HANDLE||sar_handle==INVALID_HANDLE)
      return INIT_FAILED;

   my_trade.SetDeviationInPoints(my_slippage);
   my_trade.SetExpertMagicNumber(my_magic_number);
   my_trade.SetAsyncMode(false);

   tick_point=Point();

   ArraySetAsSeries(sar_buffer,true);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   MqlRates my_candle[];
   double bb_low_1_ago=0,bb_low_2_ago=0,bb_high_1_ago=0,bb_high_2_ago=0,bb_middle_1_ago=0,bb_middle_2_ago=0;
   double close_1_ago,close_2_ago,open_1_ago,open_2_ago;
   double buy_sl,buy_tp,sell_sl,sell_tp;
   MqlTick my_tick;

   sl_buy_flag = my_sl_buy!=0;
   sl_sell_flag = my_sl_sell!=0;
   tp_buy_flag = my_tp_buy!=0;
   tp_sell_flag = my_tp_sell!=0;

   if(SymbolInfoTick(Symbol(), my_tick))
     {
      my_ask = SymbolInfoDouble(my_symbol,SYMBOL_ASK);
      my_bid = SymbolInfoDouble(my_symbol,SYMBOL_BID);
      my_total = PositionsTotal();

      ArraySetAsSeries(bb_high_buffer,true);
      ArraySetAsSeries(bb_low_buffer,true);
      ArraySetAsSeries(bb_middle_buffer,true);
      ArraySetAsSeries(my_candle,true);

      if(!CopyBuffer(bb_handle,0,0,9,bb_middle_buffer)<=0)
        {
         bb_middle_1_ago = bb_middle_buffer[1];
         bb_middle_2_ago = bb_middle_buffer[2];
        }

      if(!CopyBuffer(bb_handle,1,0,9,bb_high_buffer)<=0)
        {
         bb_high_1_ago = bb_high_buffer[1];
         bb_high_2_ago = bb_high_buffer[2];
        }

      if(!CopyBuffer(bb_handle,2,0,9,bb_low_buffer)<=0)
        {
         bb_low_1_ago = bb_low_buffer[1];
         bb_low_2_ago = bb_low_buffer[2];
        }

      if(CopyRates(my_symbol,0,0,9,my_candle)>0)
        {
         close_1_ago=my_candle[1].close;
         close_2_ago=my_candle[2].close;
         open_1_ago=my_candle[1].open;
         open_2_ago=my_candle[2].open;
        }



      if(IsNewCandle())
        {
         tradenow=1;
        }

      buyflag = (open_2_ago>bb_low_2_ago&&close_2_ago<=bb_low_2_ago) && (open_1_ago<=bb_low_1_ago&&close_1_ago>bb_low_1_ago);
      sellflag = (close_2_ago>bb_high_2_ago&&open_2_ago<=bb_high_2_ago) && (open_1_ago>=bb_high_1_ago&&close_1_ago<bb_high_1_ago);

      if(buyflag && tradenow)
        {
         for(int i=my_total-1; i>=0; i--)
           {
            ulong ticket = PositionGetTicket(i);

            if(ticket>0)
              {
               if(my_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  my_trade.PositionClose(ticket,my_slippage);
                 }
              }
           }
         buy_sl = NormalizeDouble(my_bid-tick_point*my_sl_buy,Digits());
         buy_tp = NormalizeDouble(my_bid+tick_point*my_tp_buy,Digits());

         if(tp_buy_flag || sl_buy_flag)
           {
            if(tp_buy_flag && !sl_buy_flag)
              {
               my_trade.Buy(my_volume,Symbol(),my_ask,0,buy_tp);
              }
            else
               if(!tp_buy_flag && sl_buy_flag)
                 {
                  my_trade.Buy(my_volume,Symbol(),my_ask,buy_sl,0);
                 }
               else
                 {
                  my_trade.Buy(my_volume,Symbol(),my_ask,buy_sl,buy_tp);
                 }

           }
         else
           {
            my_trade.Buy(my_volume,Symbol(),my_ask,0,0);
           }
         tradenow=0;
        }


      if(sellflag && tradenow)
        {
         for(int i=my_total-1; i>=0; i--)
           {
            ulong ticket = PositionGetTicket(i);

            if(ticket>0)
              {
               if(my_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  my_trade.PositionClose(ticket,my_slippage);
                 }
              }

           }
         sell_sl = NormalizeDouble(my_ask+tick_point*my_sl_sell,Digits());
         sell_tp = NormalizeDouble(my_ask-tick_point*my_tp_sell,Digits());

         if(tp_sell_flag || sl_sell_flag)
           {
            if(tp_sell_flag && !sl_sell_flag)
              {
               my_trade.Sell(my_volume,Symbol(),my_bid,0,sell_tp);
              }
            else
               if(!tp_sell_flag && sl_sell_flag)
                 {
                  my_trade.Sell(my_volume,Symbol(),my_bid,sell_sl,0);
                 }
               else
                 {
                  my_trade.Sell(my_volume,Symbol(),my_bid,sell_sl,sell_tp);
                 }

           }
         else
           {
            my_trade.Sell(my_volume,Symbol(),my_bid,0,0);
           }
         tradenow=0;
        }
      Trail();
     }
  }
//+------------------------------------------------------------------+
