//+------------------------------------------------------------------+
//|                                                    HPFFilter.mqh |
//|                                  Copyright 2020,Terence Beaujour |
//|                                          beaujour.t@hotmail.fr   |
//+------------------------------------------------------------------+

#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- Header guard
#ifndef HPFFILTER_MQH
#define HPFFILTER_MQH

#include <My_Classes/Harmonics_Patterns/HPFMatcher.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
interface CHPFFilter
  {
   bool IsValidUndershot(int patternIndex,PATTERN_MATCH &match);
   bool IsValidMatched(int patternIndex,PATTERN_MATCH &match);
   bool IsValidOvershot(int patternIndex,PATTERN_MATCH &match);
  };
//--- Header guard end
#endif
//+------------------------------------------------------------------+
