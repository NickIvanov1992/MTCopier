//+------------------------------------------------------------------+
//|                                               MT5ExcelReader.mq5 |
//|                                  Copyright 2025, Николай Иванов. |
//|                                https://github.com/NickIvanov1992 |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#property icon "\\Files\\terminal.ico"
#property version "1.01"
#property copyright "Copyright 2025, Николай Иванов"
#property link "https://github.com/NickIvanov1992"
#property description "Работает совместно с EXCEL WRITER (mql4)"
#property description "Файлы расположены в общем каталоге терминалов"
#property description "CurrentOrders, HistoryOrders, MagicCollection"


   #include <Trade\PositionInfo.mqh>
   #include <Trade\Trade.mqh>
   #include <Trade\SymbolInfo.mqh>  
   #include <Trade\OrderInfo.mqh>
      
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
   
   MT4Order CurrentOrders[];   //Храним текущие открытые позиции мастер-терминала
   MT4Order HistoryOrders[];    //Храним историю открытых позиций мастер-терминала
   
   MT4Order MT5CurrentOrders[];  //Текущие открытые позиции клиент-терминала
   MT4Order MT5HistoryOrders[];  //Закрытые позиции (история) клиент-терминала
   
   datetime lastOrdersUpdate;
   datetime lastHistoryUpdate;
   
   CTrade myTrade;
   
   string obj_name = "mainLabel";
   string main_text = "mainText"; 
   string commentText = "commentText";
   string commentText2 = "commentText2";
   string commentText3 = "commentText3";
   string commentText4 = "commentText4";
  
   long current_chart_id = ChartID(); 
   
   
int OnInit()
  {
   UpdatePositions("CurrentOrders.csv",MT5CurrentOrders); //CurrentOrders
   UpdatePositions("HistoryOrders.csv",HistoryOrders);      //HistoryOrders
   UpdatePositions("CurrentOrders.csv",CurrentOrders);   //CurrentOrders
   
   if(ArraySize(MT5CurrentOrders) > 0)
      OpenOrders();
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
      ObjectDelete(ChartID(),obj_name);
      ObjectDelete(ChartID(),main_text);
      ObjectDelete(ChartID(),commentText);
      ObjectDelete(ChartID(),commentText2);
      ObjectDelete(ChartID(),commentText3);
      ObjectDelete(ChartID(),commentText4);   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {     
      if(CurrentPositionsIsChecked() == false)
         ModifyOpenPositions();
         
      ShowInformation();
  }
//+------------------------------------------------------------------+

   void UpdatePositions(string fileName, MT4Order & order[])
   {    
      int handle = FileOpen(fileName,FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON,"\n");
      string result[];
      
      if(handle != -1)
      {
         int size = 0;
         while(FileIsEnding(handle) == false)
         {
            StringSplit(FileReadString(handle),StringGetCharacter("\t",0),result);
            
            if(ArraySize(result) != 0 && result[0] != "Тикет")
            {
               ArrayResize(order,size+1);
               
               order[size].ticket = (int)result[0];
               order[size].op_price = NormalizeDouble((double)result[1],5);
               order[size].op_time = (datetime)result[2];
               order[size].symbol = result[3];
               order[size].type = (int)result[4];
               order[size].volume = NormalizeDouble((double)result[5],2);
               order[size].tp = NormalizeDouble((double)result[6],5);
               order[size].sl = NormalizeDouble((double)result[7],5);
               order[size].magic = (int)result[8];
                  
               size += 1;
            }
         }
         
         if(size == 0)
            ArrayFree(order);
         
         if(fileName == "CurrentOrders.csv")
            lastOrdersUpdate = (datetime)FileGetInteger(handle,FILE_MODIFY_DATE);
         else if(fileName == "HistoryOrders.csv")
            lastHistoryUpdate = (datetime)FileGetInteger(handle,FILE_MODIFY_DATE);
      }
      FileClose(handle);
   }
 //---------------------------------------------------------------------------
 
   bool CurrentPositionsIsChecked()
   {
      if((datetime)FileGetInteger("CurrentOrders.csv",FILE_MODIFY_DATE,true) != lastOrdersUpdate)
         return false;
      else
         return true;   
   }  
   
   bool HistoryIsChecked()
   {
      if((datetime)FileGetInteger("HistoryOrders.csv",FILE_MODIFY_DATE,true) != lastHistoryUpdate)
         return false;
      else
         return true;
   }
//-------------------------------------------------------------------------------------------

   void ModifyOpenPositions()
   {
        //сравним текущий файл MT5CurrentOrders с ранее записанным 
      int foundMagic = 0;   //найденный мэджик     
      UpdatePositions("CurrentOrders.csv",MT5CurrentOrders);
      
      int modifiedMagic = LotIsModify();       //проверка на модификацию объема(закрытие части позиции) 
      
      if(ArraySize(CurrentOrders) > ArraySize(MT5CurrentOrders)) // 1 условие:  (значит какой то ордер закрылся)
      {
         for(int i=0; i<ArraySize(CurrentOrders); i++)
         {
            if(ArraySearch(MT5CurrentOrders, CurrentOrders[i].magic) == false) //ищем закрытый ордер
               {
                  foundMagic = CurrentOrders[i].magic;                   //тот самый мэджик, который нужно закрыть 
                  CloseOrder(foundMagic);
               }
            
         }
      }

      else if(ArraySize(CurrentOrders) < ArraySize(MT5CurrentOrders)) //2 условие:  (значит какой то ордер открылся)
      {
         for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
         {
            if(ArraySearch(CurrentOrders,MT5CurrentOrders[i].magic) == false)   //ищем открытый ордер
              {
                  foundMagic = MT5CurrentOrders[i].magic;                         //тот самый мэджик , который нужно открыть
                  OpenOrder(foundMagic);
              }
         }
      }
      else if(ArraySize(CurrentOrders) == ArraySize(MT5CurrentOrders) && modifiedMagic == 0) //3 условие:   (значит произошла модификация какого то ордера)
      {
              foundMagic = ArraySearchModify(MT5CurrentOrders,CurrentOrders);
              ModifyOrder(foundMagic);
      }
      else if(ArraySize(CurrentOrders) == ArraySize(MT5CurrentOrders) && modifiedMagic > 0)  //4 условие:   (значит произошло закрытие части позиции)
      {
              ModifyLot(modifiedMagic);                
      }
   }
//-----------------------------------------------------------------------------------------------------------------------------------
   
   void CloseOrder(int magic)
   {  
      int ticket = FindTicket(CurrentOrders,magic);
      if(ticket != 0)
      {
         for(int i=0; i<PositionsTotal(); i++)
         {
            PositionSelectByTicket(PositionGetTicket(i));
            if(PositionGetInteger(POSITION_TICKET) == ticket)
              {
                  myTrade.PositionClose(ticket);
                  DeleteElement(ticket,CurrentOrders);
              }
         }
      }
      
   }
   
   void OpenOrder(int magic)
   {
      int ticket = FindTicket(MT5CurrentOrders,magic);
      if(ticket != 0)
      {
         for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
         {
            if(MT5CurrentOrders[i].magic == magic)
            {
               bool isOpen = false;
               
               while(isOpen == false)
               {
                  isOpen = myTrade.PositionOpen(MT5CurrentOrders[i].symbol,
                                    GetOrderType(magic,MT5CurrentOrders),
                                    MT5CurrentOrders[i].volume,
                                    GetOrderPrice(magic,MT5CurrentOrders),
                                    MT5CurrentOrders[i].sl,
                                    MT5CurrentOrders[i].tp,
                                    IntegerToString(MT5CurrentOrders[i].magic));
               }
               
                                    
               UpdatePositions("CurrentOrders.csv",CurrentOrders);
            }       
         }
         //обновить тикеты
         for(int i=0; i<PositionsTotal(); i++)
         {
         PositionSelectByTicket(PositionGetTicket(i));
         CurrentOrders[i].ticket = (int)PositionGetInteger(POSITION_TICKET);
         }        
      }   
   }
   
   void ModifyOrder(int magic)  //Проверить поиск по тикету среди открытых позиций
   {
      int ticket = FindTicket(CurrentOrders,magic);
      if(ticket != 0)
      {
         for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
         {
            if(MT5CurrentOrders[i].magic == magic)
               myTrade.PositionModify(ticket,
                                      MT5CurrentOrders[i].sl,
                                      MT5CurrentOrders[i].tp);
         }
         //присвоить актуальный тикет открытым позам
         for(int i=0; i<PositionsTotal(); i++)
         {           
            PositionSelectByTicket(PositionGetTicket(i));
            CurrentOrders[i].ticket = (int)PositionGetInteger(POSITION_TICKET);
            CurrentOrders[i].sl = (double)PositionGetDouble(POSITION_SL);
            CurrentOrders[i].tp = (double)PositionGetDouble(POSITION_TP);
         }
      }  
   }
   
   void ModifyLot(int magic)
   {
      int ticket = FindTicket(CurrentOrders,magic);
      double ClosedVolume = GetCloseVolume(magic,MT5CurrentOrders,CurrentOrders);     
      
      if(myTrade.PositionClosePartial(ticket,ClosedVolume,SetMagicComment(ticket)) == true)
      {    
         UpdatePositions("CurrentOrders.csv",CurrentOrders);    
         //присвоить актуальный тикет открытым позам
         for(int i=0; i<PositionsTotal(); i++)
         {
            PositionSelectByTicket(PositionGetTicket(i));
            CurrentOrders[i].ticket = (int)PositionGetInteger(POSITION_TICKET);
         }
      }        
   }
   
   void OpenOrders()
   {
      for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
      {
         bool isMatch = false;
         for(int j=0; j < PositionsTotal(); j++)
         {
            if(PositionSelect(CurrentOrders[j].symbol) == true)
            {
               if(PositionGetString(POSITION_COMMENT) == IntegerToString(CurrentOrders[i].magic))
               isMatch = true;
            }               
         }
         
         if(isMatch == false)
         {
            myTrade.PositionOpen(MT5CurrentOrders[i].symbol,
                                 GetOrderType(MT5CurrentOrders[i].magic,MT5CurrentOrders),
                                 MT5CurrentOrders[i].volume,
                                 GetOrderPrice(MT5CurrentOrders[i].magic,MT5CurrentOrders),
                                 MT5CurrentOrders[i].sl,
                                 MT5CurrentOrders[i].tp,
                                 IntegerToString(MT5CurrentOrders[i].magic));
                    
         }           
      }
      //присвоить актуальный тикет открытым позам
      for(int i=0; i<PositionsTotal(); i++)
      {
         PositionSelectByTicket(PositionGetTicket(i));
         CurrentOrders[i].ticket = (int)PositionGetInteger(POSITION_TICKET);
      }
   }
   
   void ShowInformation()
   {
      if(ObjectFind(current_chart_id,obj_name) < 0 || ObjectFind(current_chart_id,main_text) < 0 ||
         ObjectFind(current_chart_id,commentText) < 0 || ObjectFind(current_chart_id,commentText2) < 0 ||
         ObjectFind(current_chart_id,commentText3) < 0 || ObjectFind(current_chart_id,commentText4) < 0)
         {
            if(!ObjectCreate(current_chart_id,obj_name,OBJ_RECTANGLE_LABEL,0,0,0)) 
            { 
               Print("Ошибка создания объекта: code #",GetLastError()); 
            } 
      
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
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_YSIZE,100);       
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_BACK,false); 
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(current_chart_id,obj_name,OBJPROP_YDISTANCE,20);
      
      //Название программы
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_XDISTANCE,150); 
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_YDISTANCE,30); 
      ObjectSetString(current_chart_id,main_text,OBJPROP_FONT,"GOST type B");
      ObjectSetInteger(current_chart_id,main_text,OBJPROP_COLOR,clrBlack);
      ObjectSetString(current_chart_id,main_text,OBJPROP_TEXT,"EXCEL READER 1.01");
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
   }
//////------------------------------------------------------------------------------------------
//////------------------------------------------------------------------------------------------

   bool ArraySearch(MT4Order & array[], int value)
   {
      for(int i=0; i<ArraySize(array); i++)
      {
         if(array[i].magic == value)
            return true;
      }
      return false;
   }
  //---------------------------------------------------------------------- 
  
   int ArraySearchModify(MT4Order & array[], MT4Order & compareableArray[])
   {
      for (int i=0; i<ArraySize(compareableArray); i++)
      {
         if(array[i].tp != compareableArray[i].tp || array[i].sl != compareableArray[i].sl)
            return array[i].magic;                                                           //тот самый мэджик модифицированного ордера
      }
      return 0;
   }
   
   int FindTicket(MT4Order & arr[], int magic)
   {
      for(int i=0; i<ArraySize(arr); i++)
      {
         if(arr[i].magic == magic)
         {
            return arr[i].ticket;
         }
      }
      return 0;
   }
   const ENUM_ORDER_TYPE GetOrderType (int magic, MT4Order & array[]) 
   {
      for(int i=0; i<ArraySize(array); i++)
      {
         if(array[i].magic == magic)
         {
            if(array[i].type == 0)
               return ORDER_TYPE_BUY;
            else if(array[i].type == 1)
               return ORDER_TYPE_SELL;
            else if(array[i].type == 2)
               return ORDER_TYPE_BUY_LIMIT;
            else if(array[i].type == 3)
               return ORDER_TYPE_SELL_LIMIT;
            else if(array[i].type == 4)
               return ORDER_TYPE_BUY_STOP;
            else if(array[i].type == 5)
               return ORDER_TYPE_SELL_STOP;
         }
      }
      return ORDER_TYPE_SELL;
   }
   
   double GetOrderPrice(int magic, MT4Order & array[])
   {
      for(int i=0; i<ArraySize(array); i++)
      {
         if(array[i].magic == magic)
         {
            if(array[i].type == 0)
               return SYMBOL_ASK;
            else if(array[i].type == 1)
               return SYMBOL_BID;
            else if(array[i].type == 2 ||
                    array[i].type == 4 ||
                    array[i].type == 3 || 
                    array[i].type == 5)
                    return array[i].op_price;
         }
      }
      return 0;
   }
   
   void DeleteElement(int ticket, MT4Order & arr[])
   {
      for (int i=0; i<ArraySize(arr); i++)
      {
         if(arr[i].ticket == ticket)
            ArrayRemove(arr,i,1);
      } 
   }
   
   int LotIsModify()
   {
      for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
      {
         for(int j=0; j<ArraySize(CurrentOrders); j++)
         {
            if(CurrentOrders[j].op_time == MT5CurrentOrders[i].op_time &&
               CurrentOrders[j].volume != MT5CurrentOrders[i].volume)
               return CurrentOrders[j].magic;
         }
      }
      return 0;
   }
   
   double GetCloseVolume(int magic, MT4Order & MT4arr[], MT4Order & CurrentArr[])  //мэджик текущий будет отличаться от мэджика MT4'
   {
      int MT4magic;
      double CurrentVolume = 0;
      double MT4Volume = 0;
      double ClosedVolume;
      
      for(int i=0; i<ArraySize(MT4arr); i++)
      {
         for(int j=0; j<ArraySize(CurrentArr); j++)
         {
            if(CurrentArr[j].op_time == MT4arr[i].op_time &&
               CurrentArr[j].op_price == MT4arr[i].op_price &&
               CurrentArr[j].magic == magic)
               {
                  MT4magic = MT4arr[i].magic;
                  MT4Volume = MT4arr[i].volume;
                  CurrentVolume = CurrentArr[j].volume;
               }                 
         }
      }
      
      ClosedVolume = CurrentVolume - MT4Volume;       //узнаем , какую часть объема необходимо закрыть
      return ClosedVolume;
   }
   
   
   int SetMagicComment(int ticket)
   {
      for(int i=0; i<ArraySize(MT5CurrentOrders); i++)
      {
         for(int j=0; j<ArraySize(CurrentOrders); j++)
         {
            if(CurrentOrders[j].ticket == ticket &&
               CurrentOrders[j].op_time == MT5CurrentOrders[i].op_time)
               return MT5CurrentOrders[i].magic;
         }
      }
      return 0;
   }