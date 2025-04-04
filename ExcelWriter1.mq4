//+------------------------------------------------------------------+
//|                                                 ExcelWriter1.mq4 |
//|                                      Copyright 2024, Nick Ivanov |
//|                                https://github.com/NickIvanov1992 |
//+------------------------------------------------------------------+
#property icon "\\Files\\terminal.ico"
#property copyright "Copyright 2024, Nick Ivanov"
#property link      "https://github.com/NickIvanov1992"
#property version   "1.01"

#property description "Работает совместно с EXCEL READER (mql5)"
#property description "Файлы расположены в общем каталоге терминалов"
#property description "CurrentOrders, HistoryOrders, MagicCollection"

#property strict

//--------------------------------------------------------------------
   struct MT4Order
   {
      int ticket;       //Номер тикета
      double op_price; //Цена открытия
      datetime op_time;//время открытия ордера
      string symbol;   //Символ
      int type;        //Тип ордера
      double tp;       //takeProfit
      double sl;       // stoploss
      double volume;   // объем
      int magic;       //Уникальный номер ордера
   };
   
   MT4Order CurrentOrders[];   //Храним текущие открытые позиции
   MT4Order HistoryOrders[];    //Храним историю открытых позиций
   
   int totalOpenOrders = OrdersTotal();
   int totalHistoryOrders = OrdersHistoryTotal();
   
   string obj_name = "mainLabel";
   string main_text = "mainText"; 
   string commentText = "commentText";
   string commentText2 = "commentText2";
   string commentText3 = "commentText3";
   string commentText4 = "commentText4";
  
   long current_chart_id = ChartID(); 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      InitialPositions();
      InitialHistory();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      ObjectDelete(main_text);
      ObjectDelete(commentText);
      ObjectDelete(commentText2);
      ObjectDelete(commentText3);
      ObjectDelete(commentText4); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
      if(PositionsIsModify() == true)
         InitialPositions();

      if(HistoryIsModify() == true)
         InitialHistory();

      ShowInformation();
  }
//+------------------------------------------------------------------+
   void InitialPositions()
   {
         if(totalOpenOrders == 0)
            ArrayFree(CurrentOrders);
            
         for(int i=0; i < totalOpenOrders; i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true)
            {
               ArrayResize(CurrentOrders,i+1);
               CurrentOrders[i].ticket = OrderTicket();
               CurrentOrders[i].op_price = OrderOpenPrice();
               CurrentOrders[i].op_time = OrderOpenTime();
               CurrentOrders[i].symbol = OrderSymbol();
               CurrentOrders[i].type = OrderType();
               CurrentOrders[i].volume = OrderLots();
               CurrentOrders[i].tp = OrderTakeProfit();
               CurrentOrders[i].sl = NormalizeDouble(OrderStopLoss(),5);
               CurrentOrders[i].magic = GetMagicNumber(OrderTicket());
            }          
         }
            RewriteFile("CurrentOrders.csv",CurrentOrders);
   }
   
   void InitialHistory()
   {
      for(int i=0; i < totalHistoryOrders; i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) == true)
            {
               ArrayResize(HistoryOrders,i+1);
               HistoryOrders[i].ticket = OrderTicket();
               HistoryOrders[i].op_price = OrderOpenPrice();
               HistoryOrders[i].op_time = OrderOpenTime();
               HistoryOrders[i].symbol = OrderSymbol();
               HistoryOrders[i].type = OrderType();
               HistoryOrders[i].volume = OrderLots();
               HistoryOrders[i].tp = OrderTakeProfit();
               HistoryOrders[i].sl = OrderStopLoss();
               HistoryOrders[i].magic = GetMagicNumber(OrderTicket());    //возможна генерация одинакового числа!
            }           
         }
         if(ArraySize(HistoryOrders) != 0)
            RewriteFile("HistoryOrders.csv",HistoryOrders);
   }
   
   void RewriteFile(string fileName,MT4Order & collection[])
   {
        int handle = FileOpen(fileName,FILE_WRITE|FILE_CSV|FILE_COMMON,"\t");  //FILE_COMMON
        
        FileWrite(handle,"Тикет", "Цена открытия","Время открытия","Символ","Тип","Объем","Тейк-Профит","Стоп-Лосс","Мэджик");
        
        for (int i = 0; i < ArraySize(collection); i++)
        {
            FileWrite(handle,collection[i].ticket,
                             collection[i].op_price,
                             collection[i].op_time,
                             collection[i].symbol,
                             collection[i].type,
                             collection[i].volume,
                             collection[i].tp,
                             collection[i].sl,
                             collection[i].magic);                            
        }
        FileClose(handle);
   }  
   //+====================================================================
   //Показать комментарии:
   void ShowInformation()
   {
      //рисуем Лейбл
      if(ObjectFind(obj_name) < 0 || ObjectFind(main_text) < 0 ||
         ObjectFind(commentText) < 0 || ObjectFind(commentText2) < 0 ||
         ObjectFind(commentText3) < 0 || ObjectFind(commentText4) < 0)
      {
         if(!ObjectCreate(current_chart_id,obj_name,OBJ_RECTANGLE_LABEL,0,0,0)) 
            Print("Ошибка создания объекта: code #",GetLastError());     
         ObjectCreate(current_chart_id,main_text,OBJ_LABEL,0,0,0);
         ObjectCreate(current_chart_id,commentText,OBJ_LABEL,0,0,0);
         ObjectCreate(current_chart_id,commentText2,OBJ_LABEL,0,0,0);
         ObjectCreate(current_chart_id,commentText3,OBJ_LABEL,0,0,0);
         ObjectCreate(current_chart_id,commentText4,OBJ_LABEL,0,0,0);
      }
      
      
      //--- устанавливаем цвет и положение  
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_BGCOLOR,clrWhite); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_COLOR,clrCoral); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_WIDTH,2); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_XDISTANCE,0); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_YDISTANCE,0);
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_XSIZE,300); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_YSIZE,150);       
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_BACK,False); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_YDISTANCE,15);
      
      //Название программы
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_XDISTANCE,150); 
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_YDISTANCE,30); 
      ObjectSetString(current_chart_id,main_text,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_COLOR,clrBlack);
      ObjectSetString(current_chart_id,main_text,OBJPROP_TEXT,"EXCEL WRITER 1.01");
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_ANCHOR,ANCHOR_CENTER);
           
      //"Открытых ордеров в книге:"
      ObjectSetInteger(current_chart_id,commentText,OBJPROP_XDISTANCE,20);
      ObjectSetInteger(current_chart_id,commentText,OBJPROP_YDISTANCE,50);
      ObjectSetInteger(current_chart_id,commentText,OBJPROP_FONTSIZE,10);
      ObjectSetString(current_chart_id,commentText,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,commentText,OBJPROP_COLOR,clrBlack);
      ObjectSetString(current_chart_id,commentText,OBJPROP_TEXT,"Открытых ордеров в книге:  " + IntegerToString(ArraySize(CurrentOrders)));
      
      //"Обновлено:"
      ObjectSetInteger(current_chart_id,commentText2,OBJPROP_XDISTANCE,20);
      ObjectSetInteger(current_chart_id,commentText2,OBJPROP_YDISTANCE,65);
      ObjectSetInteger(current_chart_id,commentText2,OBJPROP_FONTSIZE,10);
      ObjectSetString(current_chart_id,commentText2,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,commentText2,OBJPROP_COLOR,clrBlack);
      datetime dat1 = (datetime)FileGetInteger("CurrentOrders.csv",FILE_MODIFY_DATE,true);
      ObjectSetString(current_chart_id,commentText2,OBJPROP_TEXT,"Обновлено:" + TimeToString(dat1,TIME_DATE|TIME_MINUTES|TIME_SECONDS));
      
      //"Закрытых ордеров в книге:"
      ObjectSetInteger(current_chart_id,commentText3,OBJPROP_XDISTANCE,20);
      ObjectSetInteger(current_chart_id,commentText3,OBJPROP_YDISTANCE,90);
      ObjectSetInteger(current_chart_id,commentText3,OBJPROP_FONTSIZE,10);
      ObjectSetString(current_chart_id,commentText3,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,commentText3,OBJPROP_COLOR,clrBlack);
      ObjectSetString(current_chart_id,commentText3,OBJPROP_TEXT,"Закрытых ордеров в книге:   " + IntegerToString(ArraySize(HistoryOrders)));
      
      //"Обновлено:"
      ObjectSetInteger(current_chart_id,commentText4,OBJPROP_XDISTANCE,20);
      ObjectSetInteger(current_chart_id,commentText4,OBJPROP_YDISTANCE,105);
      ObjectSetInteger(current_chart_id,commentText4,OBJPROP_FONTSIZE,10);
      ObjectSetString(current_chart_id,commentText4,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,commentText4,OBJPROP_COLOR,clrBlack);
      datetime dat2 = (datetime)FileGetInteger("HistoryOrders.csv",FILE_MODIFY_DATE,true);
      ObjectSetString(current_chart_id,commentText4,OBJPROP_TEXT,"Обновлено:" + TimeToString(dat2,TIME_DATE|TIME_MINUTES|TIME_SECONDS));
   }
   //+====================================================================
   //---------------------------------------------------------------------
   
   bool PositionsIsModify()      
   {
      bool isModify = false;
      if(totalOpenOrders != OrdersTotal())
      {
         totalOpenOrders = OrdersTotal();
         isModify = true;
         return isModify;
      }
      for(int i=0; i<OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
         {
            bool checkIn = false;
            for(int j=0; j<ArraySize(CurrentOrders); j++)
            { 
               if(CurrentOrders[j].ticket == OrderTicket())
               {
                  checkIn = true;
                  if(CurrentOrders[j].sl != OrderStopLoss() ||
                     CurrentOrders[j].tp != OrderTakeProfit())
                     {
                          isModify = true;
                          return isModify;
                     }
               }
            }
            if(checkIn == false)
               isModify = true;
         }
      }
      return isModify;
   }
   
   int GetMagicNumber(int ticket)
   {
      int value;
      string result[];
      int numbers[];
      int handle = FileOpen("MagicCollection.csv",FILE_READ|FILE_CSV|FILE_COMMON,"\t");    //FILE_COMMON
      if(handle != -1)
      {   
          int size = 0;
          while(FileIsEnding(handle)==false)
         {
              size += 1;
              StringSplit(FileReadString(handle),StringGetCharacter(" ",0),result);
              ArrayResize(numbers,size);
              numbers[size-1] = result[1];
              
              if(result[0] == IntegerToString(ticket))
              {
                  FileClose(handle);
                  return StringToInteger(result[1]);
              }                
         }
      }
      FileClose(handle);
      
      int writeHandle = FileOpen("MagicCollection.csv",FILE_READ|FILE_WRITE|FILE_CSV|FILE_COMMON," ");   //FILE_COMMON
      FileSeek(writeHandle,0,SEEK_END);
      
      // первый номер в истории
      value = 12345;
      
      for(int i=0; i<ArraySize(numbers); i++)
      {
         if(numbers[i] == value)
         {
            value = MathRand();
            i = 0;
         }
      }
      
      FileWrite(writeHandle,ticket,value);
      FileClose(writeHandle);
      
      return value;
   }

   bool HistoryIsModify()
   {
      bool isModify = false;
      if(totalHistoryOrders != OrdersHistoryTotal())
      {
         totalHistoryOrders = OrdersHistoryTotal();
         isModify = true;
      }
      return isModify;
   }