// This function activates the trailing stop loss for both long and short positions.

void Trail()
  {
   int pt = PositionsTotal();

   for(int i=pt; i>=0; i--)
     {
      ulong tick = PositionGetTicket(i);

      if(PositionSelectByTicket(tick))
        {
         if(PositionGetInteger(POSITION_TYPE)==0 && my_bid-PositionGetDouble(POSITION_PRICE_OPEN)>TrailStop*Point() && my_bid-(TrailStep*Point())>PositionGetDouble(POSITION_SL))
           {
            double btp = PositionGetDouble(POSITION_TP);
            double bsl = NormalizeDouble(my_bid-(TrailStep*Point()),Digits());
            my_trade.PositionModify(tick,bsl,btp);
           }

         if(PositionGetInteger(POSITION_TYPE)==1 && PositionGetDouble(POSITION_PRICE_OPEN)-my_ask>TrailStop*Point() && my_ask+(TrailStep*Point())<PositionGetDouble(POSITION_SL))
           {
            double stp = PositionGetDouble(POSITION_TP);
            double ssl = NormalizeDouble(my_ask+(TrailStep*Point()),Digits());
            my_trade.PositionModify(tick,ssl,stp);
           }
        }
     }
  }
