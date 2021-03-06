//+------------------------------------------------------------------+
//|                                              LimitTakeProfit.mqh |
//|                                             Copyright 2018, DNG® |
//|                                 http://www.mql5.com/ru/users/dng |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, DNG®"
#property link      "http://www.mql5.com/ru/users/dng"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\SymbolInfo.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayLong.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CLimitTakeProfit : public CObject
  {
private:
   static CSymbolInfo       c_Symbol;
   static CArrayLong        i_TakeProfit; //fixed take profit
   static CArrayDouble      d_TakeProfit; //percent to close at take profit

public:
                     CLimitTakeProfit();
                    ~CLimitTakeProfit();
   //---
   static void       Magic(int value)  {  i_Magic=value; }
   static int        Magic(void)       {  return i_Magic;}
   //---
   static void       OnlyOneSymbol(bool value)  {  b_OnlyOneSymbol=value;  }
   static bool       OnlyOneSymbol(void)        {  return b_OnlyOneSymbol; }
   //---
   static bool       OrderSend(const MqlTradeRequest &request, MqlTradeResult &result);
   static bool       OnTrade(void);
   static bool       AddTakeProfit(uint point, double percent);
   static bool       DeleteTakeProfit(uint point);

protected:
   static int        i_Magic;          //Magic number to control
   static bool       b_OnlyOneSymbol;  //Only position of one symbol under control
   //---
   static bool       SetTakeProfits(ulong position_ticket, double new_tp=0);
   static bool       SetTakeProfits(string symbol, double new_tp=0);
   static bool       CheckLimitOrder(MqlTradeRequest &request);
   static void       CheckLimitOrder(void);
   static bool       CheckOrderInHistory(ulong position_id, string comment, ENUM_ORDER_TYPE type, double &volume, ulong call_position=0);
   static double     GetLimitOrderPriceByComment(string comment);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSymbolInfo    CLimitTakeProfit::c_Symbol       =  new CSymbolInfo;
CArrayLong     CLimitTakeProfit::i_TakeProfit   =  new CArrayLong;
CArrayDouble   CLimitTakeProfit::d_TakeProfit   =  new CArrayDouble;
int            CLimitTakeProfit::i_Magic        =  -1;
bool           CLimitTakeProfit::b_OnlyOneSymbol=  false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CLimitTakeProfit::CLimitTakeProfit()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CLimitTakeProfit::~CLimitTakeProfit()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::OrderSend(const MqlTradeRequest &request,MqlTradeResult &result)
  {
   if((b_OnlyOneSymbol && request.symbol!=_Symbol) ||
      (i_Magic>=0 && request.magic!=i_Magic) || !(request.action==TRADE_ACTION_SLTP && request.tp>0))
      return(::OrderSend(request,result));
//---
   MqlTradeRequest new_request=request;
   if(((new_request.position>0 && SetTakeProfits(new_request.position,new_request.tp)) ||
       (new_request.position<=0 && SetTakeProfits(new_request.symbol,new_request.tp))) && new_request.tp>0)
      new_request.tp=0;
   if((new_request.position>0 && PositionSelectByTicket(new_request.position)) ||
      (new_request.position<=0 && PositionSelect(new_request.symbol)))
     {
      if(PositionGetDouble(POSITION_SL)!=new_request.sl || PositionGetDouble(POSITION_TP)!=new_request.tp)
         return(::OrderSend(new_request,result));
     }
//---
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::OnTrade(void)
  {
   int total=PositionsTotal();
   bool result=true;
   bool hedging=(AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   for(int i=0; i<total; i++)
     {
      ulong ticket=PositionGetTicket((uint)i);
      if(ticket<=0 || (b_OnlyOneSymbol && PositionGetString(POSITION_SYMBOL)!=_Symbol))
         continue;
      //---
      if(i_Magic>0)
        {
         if(hedging && PositionGetInteger(POSITION_MAGIC)!=i_Magic)
            continue;
        }
      //---
      if(hedging)
        {
         string comment=PositionGetString(POSITION_COMMENT);
         if(StringFind(comment,"TP")==0)
           {
            int start=StringFind(comment,"_");
            if(start>0)
              {
               long ticket_by=StringToInteger(StringSubstr(comment,start+1));
               long type=PositionGetInteger(POSITION_TYPE);
               if(ticket_by>0 && PositionSelectByTicket(ticket_by) && type!=PositionGetInteger(POSITION_TYPE))
                 {
                  MqlTradeRequest   request  = {0};
                  MqlTradeResult    trade_result   = {0};
                  request.action=TRADE_ACTION_CLOSE_BY;
                  request.position=ticket;
                  request.position_by=ticket_by;
                  if(::OrderSend(request,trade_result))
                     continue;
                 }
              }
           }
        }
      //---
      result=(SetTakeProfits(PositionGetInteger(POSITION_TICKET)) && result);
     }
//---
   CheckLimitOrder();
//---
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::SetTakeProfits(string symbol, double new_tp=0)
  {
   if(!PositionSelect(symbol))
      return false;
   return SetTakeProfits(PositionGetInteger(POSITION_TICKET),new_tp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::SetTakeProfits(ulong position_ticket, double new_tp=0)
  {
   if(!PositionSelectByTicket(position_ticket) || (b_OnlyOneSymbol && PositionGetString(POSITION_SYMBOL)!=_Symbol))
      return false;
   if(!(c_Symbol.Name()==PositionGetString(POSITION_SYMBOL) || c_Symbol.Name(PositionGetString(POSITION_SYMBOL))) || !c_Symbol.RefreshRates())
      return false;
//---
   double min_sell_limit=c_Symbol.NormalizePrice(c_Symbol.Ask()+c_Symbol.StopsLevel()*c_Symbol.Point());
   double max_buy_limit=c_Symbol.NormalizePrice(c_Symbol.Bid()-c_Symbol.StopsLevel()*c_Symbol.Point());
//---
   MqlTradeRequest tp_request= {0};
   MqlTradeResult tp_result= {0};
   tp_request.action =  TRADE_ACTION_PENDING;
   tp_request.magic  =  PositionGetInteger(POSITION_MAGIC);
   tp_request.type_filling =  ORDER_FILLING_RETURN;
   tp_request.position=position_ticket;
   tp_request.symbol=c_Symbol.Name();
   int total=i_TakeProfit.Total();
   double tp_price=(new_tp>0 ? new_tp : PositionGetDouble(POSITION_TP));
   if(tp_price<=0)
      tp_price=GetLimitOrderPriceByComment("TPP_"+IntegerToString(position_ticket));
   double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   int tp_int=(tp_price>0 ? (int)NormalizeDouble(MathAbs(open_price-tp_price)/c_Symbol.Point(),0) : INT_MAX);
   double position_volume=PositionGetDouble(POSITION_VOLUME);
   double closed=0;
   double closed_perc=0;
   double fix_closed_per=0;
//---
   for(int i=0; i<total; i++)
     {
      tp_request.comment="TP"+IntegerToString(i)+"_"+IntegerToString(position_ticket);
      if(i_TakeProfit.At(i)<tp_int && d_TakeProfit.At(i)>0)
        {
         if(closed>=100 || fix_closed_per>=100)
            break;
         //---
         double lot=position_volume*MathMin(d_TakeProfit.At(i),100-closed_perc)/(100-fix_closed_per);
         lot=MathMin(position_volume-closed,lot);
         lot=c_Symbol.LotsMin()+MathMax(0,NormalizeDouble((lot-c_Symbol.LotsMin())/c_Symbol.LotsStep(),0)*c_Symbol.LotsStep());
         lot=NormalizeDouble(lot,2);
         tp_request.volume=lot;
         switch((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
           {
            case POSITION_TYPE_BUY:
               tp_request.type=ORDER_TYPE_SELL_LIMIT;
               tp_request.price=c_Symbol.NormalizePrice(open_price+i_TakeProfit.At(i)*c_Symbol.Point());
               break;
            case POSITION_TYPE_SELL:
               tp_request.type=ORDER_TYPE_BUY_LIMIT;
               tp_request.price=c_Symbol.NormalizePrice(open_price-i_TakeProfit.At(i)*c_Symbol.Point());
               break;
           }
         if(CheckLimitOrder(tp_request))
           {
            if(tp_request.volume>=0)
              {
               closed+=tp_request.volume;
               closed_perc=closed/position_volume*100;
              }
            else
              {
               fix_closed_per-=tp_request.volume/(position_volume-tp_request.volume)*100;
              }
            continue;
           }
         switch(tp_request.type)
           {
            case ORDER_TYPE_BUY_LIMIT:
               tp_request.price=MathMin(tp_request.price,max_buy_limit);
               break;
            case  ORDER_TYPE_SELL_LIMIT:
               tp_request.price=MathMax(tp_request.price,min_sell_limit);
               break;
           }
         if(::OrderSend(tp_request,tp_result))
           {
            closed+=tp_result.volume;
            closed_perc=closed/position_volume*100;
            ZeroMemory(tp_result);
           }
        }
     }
//---
   if(tp_price>0 && position_volume>closed && PositionSelectByTicket(position_ticket))
     {
      tp_request.price=tp_price;
      tp_request.comment="TPP_"+IntegerToString(position_ticket);
      tp_request.volume=position_volume-closed;
      if(tp_request.volume<c_Symbol.LotsMin())
         return false;
      tp_request.volume=c_Symbol.LotsMin()+MathMax(0,NormalizeDouble((tp_request.volume-c_Symbol.LotsMin())/c_Symbol.LotsStep(),0)*c_Symbol.LotsStep());
      tp_request.volume=NormalizeDouble(tp_request.volume,2);
      //---
      switch((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
        {
         case POSITION_TYPE_BUY:
            tp_request.type=ORDER_TYPE_SELL_LIMIT;
            break;
         case POSITION_TYPE_SELL:
            tp_request.type=ORDER_TYPE_BUY_LIMIT;
            break;
        }
      if(CheckLimitOrder(tp_request) && tp_request.volume>=0)
        {
         closed+=tp_request.volume;
         closed_perc=closed/position_volume*100;
        }
      else
        {
         switch(tp_request.type)
           {
            case ORDER_TYPE_BUY_LIMIT:
               tp_request.price=MathMin(tp_request.price,max_buy_limit);
               break;
            case  ORDER_TYPE_SELL_LIMIT:
               tp_request.price=MathMax(tp_request.price,min_sell_limit);
               break;
           }
         if(tp_request.volume<=0)
           {
            tp_request.volume=position_volume-closed;
            tp_request.volume=c_Symbol.LotsMin()+MathMax(0,NormalizeDouble((tp_request.volume-c_Symbol.LotsMin())/c_Symbol.LotsStep(),0)*c_Symbol.LotsStep());
            tp_request.volume=NormalizeDouble(tp_request.volume,2);
           }
         if(::OrderSend(tp_request,tp_result))
           {
            closed+=tp_result.volume;
            closed_perc=closed/position_volume*100;
            ZeroMemory(tp_result);
           }
        }
     }
//---
   if(closed>=position_volume && PositionGetDouble(POSITION_TP)>0)
     {
      ZeroMemory(tp_request);
      ZeroMemory(tp_result);
      tp_request.action=TRADE_ACTION_SLTP;
      tp_request.position=position_ticket;
      tp_request.symbol=c_Symbol.Name();
      tp_request.sl=PositionGetDouble(POSITION_SL);
      tp_request.tp=0;
      tp_request.magic=PositionGetInteger(POSITION_MAGIC);
      if(!OrderSend(tp_request,tp_result))
         return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CLimitTakeProfit::GetLimitOrderPriceByComment(string comment)
  {
   int total=OrdersTotal();
   for(int i=0; i<total; i++)
     {
      ulong ticket=OrderGetTicket((uint)i);
      if(ticket<=0)
         continue;
      switch((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE))
        {
         case ORDER_TYPE_BUY_LIMIT:
         case ORDER_TYPE_SELL_LIMIT:
            break;
         default:
            continue;
            break;
        }
      if(OrderGetString(ORDER_COMMENT)!=comment)
         continue;
      return OrderGetDouble(ORDER_PRICE_OPEN);
     }
//---
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::CheckLimitOrder(MqlTradeRequest &request)
  {
   double min_sell_limit=c_Symbol.NormalizePrice(c_Symbol.Ask()+c_Symbol.StopsLevel()*c_Symbol.Point());
   double max_buy_limit=c_Symbol.NormalizePrice(c_Symbol.Bid()-c_Symbol.StopsLevel()*c_Symbol.Point());
//---
   int total=OrdersTotal();
   for(int i=0; i<total; i++)
     {
      ulong ticket=OrderGetTicket((uint)i);
      if(ticket<=0)
         continue;
      if(OrderGetString(ORDER_COMMENT)!=request.comment)
         continue;
      //---
      if(MathAbs(OrderGetDouble(ORDER_VOLUME_INITIAL) - request.volume)>=c_Symbol.LotsStep() || OrderGetInteger(ORDER_TYPE)!=request.type)
        {
         MqlTradeRequest del_request= {0};
         MqlTradeResult del_result= {0};
         del_request.action=TRADE_ACTION_REMOVE;
         del_request.order=ticket;
         if(::OrderSend(del_request,del_result))
            return false;
         request.volume=OrderGetDouble(ORDER_VOLUME_INITIAL);
        }
      //---
      if(MathAbs(OrderGetDouble(ORDER_PRICE_OPEN)-request.price)>=c_Symbol.Point())
        {
         MqlTradeRequest mod_request= {0};
         MqlTradeResult mod_result= {0};
         mod_request.action=TRADE_ACTION_MODIFY;
         mod_request.price=request.price;
         mod_request.magic=request.magic;
         mod_request.symbol=request.symbol;
         switch(request.type)
           {
            case ORDER_TYPE_BUY_LIMIT:
               if(mod_request.price>max_buy_limit)
                  return true;
               break;
            case ORDER_TYPE_SELL_LIMIT:
               if(mod_request.price<min_sell_limit)
                  return true;
               break;
           }
         bool mod=::OrderSend(mod_request,mod_result);
        }
      return true;
     }
//---
   if(!PositionSelectByTicket(request.position))
      return true;
//---
   return CheckOrderInHistory(PositionGetInteger(POSITION_IDENTIFIER),request.comment, request.type, request.volume);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::CheckOrderInHistory(ulong position_id, string comment, ENUM_ORDER_TYPE type, double &volume, ulong call_position=0)
  {
//---
   bool hedging=(AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   if(hedging && PositionSelectByTicket(position_id))
     {
      string symbol=PositionGetString(POSITION_SYMBOL);
      int total=PositionsTotal();
      for(int i=0; i<total; i++)
        {
         if(PositionGetSymbol(i)!=symbol || PositionGetInteger(POSITION_IDENTIFIER)==position_id)
            continue;
         if(PositionGetString(POSITION_COMMENT)==comment)
           {
            volume=PositionGetDouble(POSITION_VOLUME);
            return true;
           }
        }
     }
//---
   if(!HistorySelectByPosition(position_id))
      return true;
   int total=HistoryDealsTotal();
//---
   for(int i=0; i<total; i++)
     {
      ulong ticket=HistoryDealGetTicket((uint)i);
      ticket=HistoryDealGetInteger(ticket,DEAL_ORDER);
      if(!HistoryOrderSelect(ticket))
         continue;
      if(ticket<=0)
         continue;
      if(hedging && HistoryOrderGetInteger(ticket,ORDER_POSITION_ID)!=position_id && HistoryOrderGetInteger(ticket,ORDER_POSITION_ID)!=call_position)
        {
         if(CheckOrderInHistory(HistoryOrderGetInteger(ticket,ORDER_POSITION_ID),comment,type,volume))
            return true;
         if(!HistorySelectByPosition(position_id))
            continue;
        }
      if(HistoryOrderGetString(ticket,ORDER_COMMENT)!=comment)
         continue;
      if(HistoryOrderGetInteger(ticket,ORDER_TYPE)!=type)
         continue;
      //---
      volume=-OrderGetDouble(ORDER_VOLUME_INITIAL);
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CLimitTakeProfit::CheckLimitOrder(void)
  {
   int total=OrdersTotal();
   bool res=false;
//---
   for(int i=0; (i<total && !res); i++)
     {
      ulong ticket=OrderGetTicket((uint)i);
      if(ticket<=0)
         continue;
      string comment=OrderGetString(ORDER_COMMENT);
      if(StringFind(comment,"TP")!=0)
         continue;
      int pos=StringFind(comment,"_",0);
      if(pos<0)
         continue;
      //---
      long pos_ticker=StringToInteger(StringSubstr(comment,pos+1));
      if(!PositionSelectByTicket(pos_ticker))
        {
         MqlTradeRequest del_request= {0};
         MqlTradeResult del_result= {0};
         del_request.action=TRADE_ACTION_REMOVE;
         del_request.order=ticket;
         if(::OrderSend(del_request,del_result))
           {
            i--;
            total--;
           }
         continue;
        }
      //---
      switch((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE))
        {
         case POSITION_TYPE_BUY:
            if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT)
               continue;
            break;
         case POSITION_TYPE_SELL:
            if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT)
               continue;
            break;
        }
      MqlTradeRequest del_request= {0};
      MqlTradeResult del_result= {0};
      del_request.action=TRADE_ACTION_REMOVE;
      del_request.order=ticket;
      if(::OrderSend(del_request,del_result))
        {
         i--;
         total--;
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::AddTakeProfit(uint point,double percent)
  {
   if(percent<=0)
      return false;
//---
   int total=i_TakeProfit.Total();
   for(int i=0; i<total; i++)
     {
      if(i_TakeProfit.At(i)==point)
        {
         return d_TakeProfit.Update(i,percent);
        }
     }
//---
   if(i_TakeProfit.Add(point))
     {
      if(d_TakeProfit.Add(percent))
         return true;
      i_TakeProfit.Delete(i_TakeProfit.Total()-1);
     }
//---
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CLimitTakeProfit::DeleteTakeProfit(uint point)
  {
   int total=i_TakeProfit.Total();
   for(int i=0; i<total; i++)
     {
      if(i_TakeProfit.At(i)!=point)
         continue;
      if(i_TakeProfit.Delete(i) && (i>=d_TakeProfit.Total() || d_TakeProfit.Delete(i)))
         return true;
      break;
     }
//---
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LimitOrderSend(const MqlTradeRequest &request, MqlTradeResult &result)
  { return CLimitTakeProfit::OrderSend(request,result); }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OrderSend(request,result)      LimitOrderSend(request,result)
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade()
  {
   CLimitTakeProfit::OnTrade();
  }
//+------------------------------------------------------------------+
