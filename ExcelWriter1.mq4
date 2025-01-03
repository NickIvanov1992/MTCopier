//+------------------------------------------------------------------+
//|                                                 ExcelWriter1.mq4 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int OrderCollection[][5];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
   if (fileIsModify() == true)
      FileWriter();
  }
  
  

//+------------------------------------------------------------------+

void FileWriter()
{
      int ticket;
      string symbol;
      double volume;
      double TP;
      double SL;
      
      int handle = FileOpen("OrdersReports.csv",FILE_WRITE|FILE_CSV,"\t");
      
      FileWrite(handle,"#","Цена открытия","Время открытия","Символ","Объем","Тейк-Профит","Стоп-Лосс");
      int total = OrdersTotal();
      
      for(int pos=0;pos<total;pos++)
      {
          if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES)==false) continue;
          
          ticket = OrderTicket();
          symbol = OrderSymbol();
          volume = OrderLots();
          TP = OrderTakeProfit();
          SL = OrderStopLoss();
          
          FileWrite(handle,ticket,OrderOpenPrice(),OrderOpenTime(),symbol,volume,TP,SL);
          AddOrderToCollection(ticket,symbol,volume,TP,SL);
      }
       FileClose(handle);
}

void AddOrderToCollection(int ticket, string symbol, double volume, double TP, double SL)
{
   if(ArraySize(OrderCollection) == 0)
   {
      ArrayResize(OrderCollection,1);
      OrderCollection[0][0] = ticket;
      OrderCollection[0][1] = symbol;
      OrderCollection[0][2] = volume;
      OrderCollection[0][3] = TP;
      OrderCollection[0][4] = SL;
   }
   else
   {
      int temp = ArrayRange(OrderCollection,0);
      ArrayResize(OrderCollection,temp + 1);
      OrderCollection[temp-1][0] = ticket;
      OrderCollection[temp-1][1] = symbol;
      OrderCollection[temp-1][2] = volume;
      OrderCollection[temp-1][3] = TP;
      OrderCollection[temp-1][4] = SL;
   }
}

bool fileIsModify()
{
   if(OrdersTotal()==0)
   {
      //OrderCollection = 0;
      ArrayFree(OrderCollection);
      return false;
   }
   else if(OrdersTotal() > 0 && ArraySize(OrderCollection) == 0)
      return true;
   
   else if(OrdersTotal() > 0 && ArraySize(OrderCollection) > 0)
   {
      bool variable;
      variable = false;
      
      for (int pos = 0; pos < OrdersTotal() - 1; pos++)
      {
         if(OrderSelect(pos,SELECT_BY_POS,MODE_TRADES) == true)
         {
            if(searchIsMatch(OrderTicket(),OrderSymbol(),OrderLots(),OrderTakeProfit(),OrderStopLoss()) == false)
            variable = true;
         }
      }
      return variable;
   }
   else
      return false;
}

bool searchIsMatch(int ticket, string symbol, double volume, double TP, double SL)
{
   bool isMatch = false;
   
   //размер массива OrderCollection
   int temp = ArrayRange(OrderCollection,0);
   
      for(int i = 0; i < temp; i++)
      {
         if(OrderCollection[i][0] == ticket && OrderCollection[i][1] == symbol &&
            OrderCollection[i][2] == volume && OrderCollection[i][3] == TP &&
            OrderCollection[i][4] == SL)
            isMatch = true;
      }
    return isMatch;
}
//bool CheckOrders()
//{   
//   bool value = false;
//   if(OrdersTotal() == 0)
//   return true;
//   else
//   {
//      for (int pos = OrdersTotal()-1; pos >= 0; pos--)
//      {
//         if (OrderSelect(pos,SELECT_BY_POS,MODE_TRADES) == true)
//         {
//          if(getSearch(OrderTicket()) == true)
//             value = true;
//         }
//      }
//   }
//    return value;  
//}
//
//void AddTicketCollection(int number)
//{
//   if(ArraySize(TicketCollection) > 0)
//   {
//      bool isMatch = false;
//      for (int i = 0; i < ArraySize(TicketCollection); i++)
//      {
//          if(TicketCollection[i] == number)
//          isMatch = true;
//      }
//      if(isMatch == false)
//      {
//         ArrayResize(TicketCollection,ArraySize(TicketCollection) +1,0);
//         TicketCollection[ArraySize(TicketCollection) - 1] = OrderTicket();
//      }
//   }
//   else
//   {
//      ArrayResize(TicketCollection,1,0);
//      TicketCollection[0] = OrderTicket();
//   }
//}
//
//bool getSearch(int num)
//{
//   Print (num);
//
//
//
//   if(ArraySize(TicketCollection)==0)
//   return false;
//   else
//   {
//      for (int i = 0; i <= ArraySize(TicketCollection)-1; i++)
//      {
//      if(TicketCollection[i] == num)
//      return true;
//      }
//   }
//   
//   return false;
//}