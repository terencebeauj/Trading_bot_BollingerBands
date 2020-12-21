//+------------------------------------------------------------------+
//|                                          ChartObjectsFigures.mqh |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
//| Все фигуры.                                                      |
//+------------------------------------------------------------------+
#include "ChartObject.mqh"
//+------------------------------------------------------------------+
//| Класс CChartObjectRectangle.                                     |
//| Назначение: Класс графического объекта "Прямоугольник".          |
//+------------------------------------------------------------------+
class CChartObjectRectangle : public CChartObject
  {
public:
   //--- метод создания объекта
   bool              Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2);
   //--- метод идентификации объекта
   virtual int       Type() { return(OBJ_RECTANGLE); };
  };
//+------------------------------------------------------------------+
//| Создание объекта "Прямоугольник".                                |
//| INPUT:  chart_id-идентификатор графика,                          |
//|         name    -имя объекта,                                    |
//|         window  -номер подокна графика,                          |
//|         time1   -первая координата времени,                      |
//|         price1  -первая координата цены,                         |
//|         time2   -вторая координата времени,                      |
//|         price2  -вторая координата цены.                         |
//| OUTPUT: true при удачном создании, иначе - false.                |
//| REMARK: нет.                                                     |
//+------------------------------------------------------------------+
bool CChartObjectRectangle::Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2)
  {
   bool result=ObjectCreate(chart_id,name,OBJ_RECTANGLE,window,time1,price1,time2,price2);
//---
   if(result) result&=Attach(chart_id,name,window,2);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Класс CChartObjectTriangle.                                      |
//| Назначение: Класс графического объекта "Треугольник".            |
//+------------------------------------------------------------------+
class CChartObjectTriangle : public CChartObject
  {
public:
   //--- метод создания объекта
   bool              Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3);
   //--- метод идентификации объекта
   virtual int       Type() { return(OBJ_TRIANGLE); };
  };
//+------------------------------------------------------------------+
//| Создание объекта "Треугольник".                                  |
//| INPUT:  chart_id-идентификатор графика,                          |
//|         name    -имя объекта,                                    |
//|         window  -номер подокна графика,                          |
//|         time1   -первая координата времени,                      |
//|         price1  -первая координата цены,                         |
//|         time2   -вторая координата времени,                      |
//|         price2  -вторая координата цены,                         |
//|         time3   -третья координата времени,                      |
//|         price3  -третья координата цены.                         |
//| OUTPUT: true при удачном создании, иначе - false.                |
//| REMARK: нет.                                                     |
//+------------------------------------------------------------------+
bool CChartObjectTriangle::Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3)
  {
   bool result=ObjectCreate(chart_id,name,OBJ_TRIANGLE,window,time1,price1,time2,price2,time3,price3);
//---
   if(result) result&=Attach(chart_id,name,window,3);
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Класс CChartObjectEllipse.                                       |
//| Назначение: Класс графического объекта "Эллипс".                 |
//+------------------------------------------------------------------+
class CChartObjectEllipse : public CChartObject
  {
public:
   //--- метод создания объекта
   bool              Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3);
   //--- метод идентификации объекта
   virtual int       Type() { return(OBJ_ELLIPSE); };
  };
//+------------------------------------------------------------------+
//| Создание объекта "Эллипс".                                       |
//| INPUT:  chart_id-идентификатор графика,                          |
//|         name    -имя объекта,                                    |
//|         window  -номер подокна графика,                          |
//|         time1   -первая координата времени,                      |
//|         price1  -первая координата цены,                         |
//|         time2   -вторая координата времени,                      |
//|         price2  -вторая координата цены,                         |
//|         time3   -третья координата времени,                      |
//|         price3  -третья координата цены.                         |
//| OUTPUT: true при удачном создании, иначе - false.                |
//| REMARK: нет.                                                     |
//+------------------------------------------------------------------+
bool CChartObjectEllipse::Create(long chart_id,string name,int window,datetime time1,double price1,datetime time2,double price2,datetime time3,double price3)
  {
   bool result=ObjectCreate(chart_id,name,OBJ_ELLIPSE,window,time1,price1,time2,price2,time3,price3);
//---
   if(result) result&=Attach(chart_id,name,window,3);
//---
   return(result);
  }
//+------------------------------------------------------------------+
