//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Sergey Lagutin"
#property link      "ic.icreator@gmail.com"
#property strict
//+--- constants ----------------------------------------------------+
#define DELAY 50
#define SYMBOL_LEN 50
//+--- enums --------------------------------------------------------+
enum TypeC
  {
   MASTER= 0,// Master
   SLAVE = 1 // Slave
  };
//+------------------------------------------------------------------+
enum Switch
  {
   OFF= 0,// Off
   ON = 1 // On
  };
//+------------------------------------------------------------------+
enum TypeL
  {
   FIXED=0,// Fixed
   DYNAMIC=1 // Dynamic (equity based)
  };
//+--- structures ---------------------------------------------------+
struct Params
  {
   int               account;
   char              symbol[SYMBOL_LEN];
   int               ticket;
   int               magic;
   int               type;
   double            volume;
   double            sl;
   double            tp;
   double            equity;
  };
//+--- inputs -------------------------------------------------------+
input TypeC CopierType=MASTER; // Copier
input TypeL LotType=DYNAMIC; // Volume
Switch Log=OFF;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Trade
  {
public:
   static bool open(Params &p)
     {
      string s=CharArrayToString(p.symbol);
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      double v=LotType==DYNAMIC
               ? normalizeLot(CharArrayToString(p.symbol),eq/p.equity*p.volume)
               : p.volume;
      double ask=SymbolInfoDouble(s,SYMBOL_ASK);
      double bid=SymbolInfoDouble(s,SYMBOL_BID);
      return OrderSend(s,
                       p.type,
                       v,
                       p.type%2==0 ? ask : bid,
                       0,
                       p.sl,
                       p.tp,
                       NULL,
                       p.magic);
     }

   static bool close(Params &p,double coeff=1)
     {
      string s=CharArrayToString(p.symbol);
      double ask = SymbolInfoDouble(s,SYMBOL_ASK);
      double bid = SymbolInfoDouble(s,SYMBOL_BID);
      int total=OrdersTotal();
      double lot;
      for(int i=total-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)
            && OrderMagicNumber()==p.magic)
           {
            lot=normalizeLot(s,OrderLots()*coeff);
            return OrderClose(OrderTicket(),lot,OrderType()%2==0?bid:ask,0);
           }
        }
      return false;
     }

   static bool modify(Params &p)
     {
      string s=CharArrayToString(p.symbol);
      double ask = SymbolInfoDouble(s,SYMBOL_ASK);
      double bid = SymbolInfoDouble(s,SYMBOL_BID);
      int total= OrdersTotal();
      for(int i=total-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS)
            && OrderMagicNumber()==p.magic)
           {
            return OrderModify(OrderTicket(),OrderOpenPrice(),p.sl,p.tp,0);
           }
        }
      return false;
     }

   static double normalizeLot(string symbol,double lot)
     {
      double lotMin = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double lotMax = SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      double lotStep= SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      double c=1.0/lotStep;
      double l=floor(lot*c)/c;
      if(l < lotMin) l = lotMin;
      if(l > lotMax) l = lotMax;
      return l;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class TradeCopier
  {
   Params            shared[];
   Params            saved[];
   Params            positions[];
   string            backupName;
   string            sharedName;
   int               account;

public:

   void create()
     {
      account=AccountNumber();
      backupName=IntegerToString(account);
      sharedName="shared";
      backup();
     }

   TradeCopier *opened()
     {
      double eq=AccountInfoDouble(ACCOUNT_EQUITY);
      int total=OrdersTotal(),sz=0;
      string c;
      ArrayFree(positions);

      for(int i=total-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS) && OrderType()<=1)
           {
            sz=ArrayResize(positions,sz+1);
            char sa[];
            StringToCharArray(OrderSymbol(),sa);
            ArrayCopy(positions[sz-1].symbol,sa);
            positions[sz-1].ticket=OrderTicket();
            c=OrderComment();
            positions[sz-1].magic=(int)StringToInteger(StringSubstr(c,StringFind(c,"#")+1));
            positions[sz-1].volume=OrderLots();
            positions[sz-1].sl=OrderStopLoss();
            positions[sz-1].tp=OrderTakeProfit();
            positions[sz-1].type=OrderType();
            positions[sz-1].equity=eq;
            positions[sz-1].account=this.account;
           }
        }
      return GetPointer(this);
     }

   TradeCopier *mergeAndTrade()
     {
      ArrayFree(saved);
      ArrayFree(shared);
      int sz=backup(saved);
      int szO=pull(shared);
      int ind;
      double coeff;

      // ни одной сделки еще не скопировано, копируем
      if(sz==0)
        {
         for(int i=0;i<szO;i++)
           {
            shared[i].magic=shared[i].ticket;
            Trade::open(shared[i]);
           }
         backup();
         return GetPointer(this);
        }

      // находим закрытые ордера на мастере
      for(int i=sz-1;i>=0;i--)
         if(exists(saved[i],shared)<0)
            Trade::close(saved[i]);

      // частичное закрытие, модификация и открытие новых ордеров
      for(int i=0;i<szO;i++)
        {
         if((ind=exists(shared[i],saved))!=-1)
           {
            shared[i].magic=saved[ind].magic;
            if((coeff=1-shared[i].volume/saved[ind].volume)>0.0)
               Trade::close(shared[i],coeff);
            if(shared[i].sl!=saved[ind].sl || shared[i].tp!=saved[ind].tp)
               Trade::modify(shared[i]);
           }
         else
           {
            shared[i].magic=shared[i].ticket;
            Trade::open(shared[i]);
           }
        }
      backup();
      return GetPointer(this);
     }

   int exists(Params &what,Params &where[])
     {
      int sz=ArraySize(where);
      for(int i=0;i<sz;i++)
         if(where[i].ticket==what.ticket
            || where[i].ticket==what.magic
            || where[i].magic==what.ticket
            || where[i].magic==what.magic)
            return i;
      return -1;
     }

   int pull(Params &a[])
     {
      read(sharedName,a);
      return ArraySize(a);
     }

   void share()
     {
      Params orders[],temp[];
      read(sharedName,orders);

      int szO=ArraySize(orders);
      int szP=ArraySize(positions);
      int szTemp=ArrayResize(temp,0,szO+szP);

      for(int i=0;i<szO;i++)
         if(orders[i].account!=this.account)
           {
            szTemp=ArrayResize(temp,szTemp+1);
            ArrayCopy(temp,orders,szTemp-1,i,1);
           }
      ArrayResize(temp,szTemp+szP);
      for(int i=szTemp;i<szTemp+szP;i++)
         ArrayCopy(temp,positions,i,i-szTemp,1);

      write(sharedName,temp);
     }

   void backup()
     {
      write(backupName,shared,true);
     }

   int backup(Params &a[])
     {
      read(backupName,a,true);
      return ArraySize(a);
     }

private:
   void write(string name,Params &a[],bool local=false)
     {
      int h;
      do
        {
         h=local ? FileOpen(name,FILE_WRITE|FILE_BIN) : FileOpen(name,FILE_WRITE|FILE_BIN|FILE_COMMON);
         if(GetLastError()!=0)
            Sleep(DELAY);
        }
      while(h==INVALID_HANDLE);
      FileWriteArray(h,a);
      FileClose(h);
     }

   void read(string name,Params &a[],bool local=false)
     {
      int h;
      do
        {
         h=local ? FileOpen(name,FILE_READ|FILE_BIN) : FileOpen(name,FILE_READ|FILE_BIN|FILE_COMMON);
         if(GetLastError()!=0)
            Sleep(DELAY);
        }
      while(h==INVALID_HANDLE);
      FileReadArray(h,a);
      FileClose(h);
     }
  };

TradeCopier copier;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   copier.create();

   EventSetMillisecondTimer(DELAY*10);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   int sz,i;
   string str="";
   Params a[];

   if(CopierType==SLAVE)
     {
      copier.mergeAndTrade();

      if(Log==ON)
        {
         sz=copier.backup(a);
         for(i=0;i<sz;i++)
            str+=StringFormat("[%i] ticket: %i, magic: %i, volume: %0.2f, sl: %0.5f, tp: %0.5f\n",
                              i,a[i].ticket,a[i].magic,a[i].volume,a[i].sl,a[i].tp);
         Comment(str);
        }
     }
   else if(CopierType==MASTER)
     {
      copier.opened().share();

      if(Log==ON)
        {
         sz=copier.pull(a);
         for(i=0;i<sz;i++)
            str+=StringFormat("[%i] ticket: %i, magic: %i, volume: %0.2f, sl: %0.5f, tp: %0.5f\n",
                              i,a[i].ticket,a[i].magic,a[i].volume,a[i].sl,a[i].tp);
         Comment(str);
        }
     }
  }
//+------------------------------------------------------------------+
