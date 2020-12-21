//+------------------------------------------------------------------+
//|                                       MoneyFixedRisk.mqh |
//|                                                   Enrico Lambino |
//|                             https://www.mql5.com/en/users/iceron |
//+------------------------------------------------------------------+
#property copyright "Enrico Lambino"
#property link      "https://www.mql5.com/en/users/iceron"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CMoneyFixedRisk : public CMoneyFixedRiskBase
  {
public:
                     CMoneyFixedRisk(double);
                    ~CMoneyFixedRisk(void);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CMoneyFixedRisk::CMoneyFixedRisk(double risk) : CMoneyFixedRiskBase(risk)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CMoneyFixedRisk::~CMoneyFixedRisk(void)
  {
  }
//+------------------------------------------------------------------+
