//+------------------------------------------------------------------+
//|                                        @itochan_otochan_σの歪.mq4 |
//|                       Copyright 2021, @itochan_otochan(Twitter). |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, @itochan_otochan(Twitter)."
#property version   "1.00"
#property strict

input int Slippage = 3;
input double Lots = 0.2;  
input int Expiration  = 4;
input int MAGIC = 234234234;
input int time = 20;
input int TP_point = 190;
input int SL_spec = 50;
input int SL_point = 20;
input int MaxSpread = 2;
input int sigma_time = 2;
input int waitflag=false;
input int TrailingStop  =10;

int sample = 1000 - time;
double sigma_2 = 0;

int b_ticket = 0;
int s_ticket = 0;
input int wt = 0;
int waittime = wt * 60;
datetime b_time = 0;
datetime s_time = 0;
double b_trail = 0;
double s_trail = 0;

int Test_SummerTimeGMTOffset = 3;
int Test_WinterTimeGMTOffset = 2;

datetime tokyotime =0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   sigma_2 = calcSigma(sigma_time);
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
   int b_o = 0, s_o = 0;
   int OpenSignal=0,CloseSignal=0;
   
   tokyotime = TimeGMT()+Hour2Sec(9)-Hour2Sec(GetGMTOffset());
   
   
   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(OrderSelect(i, SELECT_BY_POS)==true)
      {  
         if( OrderSymbol() == _Symbol && OrderMagicNumber() == MAGIC ){
            if( OrderType() == OP_BUY ){
               b_o++;
            }
            if( OrderType() == OP_SELL ){
               s_o++;
            }        
         }
      }   
   }
   if(Weekend(tokyotime)){
      if(b_o>0) goCloseOrder(1);
      if(s_o>0) goCloseOrder(-1);
   }else{
   
      if(Volume[0]==1){
         OpenSignal = checkOpenSignal();
         if(OpenSignal)goOpenOrder(OpenSignal);
      }
         CloseSignal = checkCloseSignal();      
         if(CloseSignal)goCloseOrder(CloseSignal);
      }
  
  }
//+------------------------------------------------------------------+

int checkOpenSignal(){
   
   int ret = 0;
   sigma_2 = calcSigma(sigma_time);
   
   if(Close[0]-Close[time]>=(sigma_2)){
      ret = -1;
   }
   if(Close[0]-Close[time]<=(-1*sigma_2)){
      ret = 1;   
   }
   
   return ret;
}

void goOpenOrder(int OpenSignal){

   int b_o = 0, s_o = 0;
   datetime expiration = TimeCurrent()+3600*Expiration; 
   double spread = NormalizeDouble(Ask -Bid,Digits);
   
   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(OrderSelect(i, SELECT_BY_POS)==true)
      {  
         if( OrderSymbol() == _Symbol && OrderMagicNumber() == MAGIC ){
            if( OrderType() == OP_BUY ) b_o++;
            if( OrderType() == OP_SELL ) s_o++;        
         }
      }   
   }
   
   if(b_o == 0  && OpenSignal == 1 && checkWait(b_time) && (spread <= NormalizeDouble(MaxSpread * Point,Digits))){
         b_ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,NormalizeDouble(Bid-SL_spec*Point-(MaxSpread * Point),Digits),NormalizeDouble(Ask+TP_point*Point,Digits),"",MAGIC,expiration,clrRed);
//         b_ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,NormalizeDouble(Ask+TP_point*Point,Digits),"",MAGIC,expiration,clrRed);
         b_time = TimeCurrent();
   }
   
   if(s_o == 0 && OpenSignal == -1 && checkWait(s_time) && (spread <= NormalizeDouble(MaxSpread * Point,Digits))){
         s_ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,NormalizeDouble(Bid+SL_spec*Point+(MaxSpread * Point),Digits),NormalizeDouble(Bid-TP_point*Point,Digits),"",MAGIC,expiration,clrBlue);
//         s_ticket = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,NormalizeDouble(Bid-TP_point*Point,Digits),"",MAGIC,expiration,clrBlue);
         s_time = TimeCurrent();
   }
}

int checkCloseSignal(){

   int b_o = 0, s_o = 0,ret=0;
   int res_select=0;
   double b_OpenPrice=0,s_OpenPrice=0;
   double oos =0;

   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==true)
      {  
         if( OrderSymbol() == _Symbol && OrderMagicNumber() == MAGIC ){
            if( OrderType() == OP_BUY ){
             b_o++;
             oos = OrderOpenPrice();
             b_OpenPrice=NormalizeDouble(oos-SL_point*Point,Digits);
             if(TrailingStop>0){
                  if(NormalizeDouble(Bid-oos,Digits)>Point*TrailingStop){
                     if((b_trail<(Bid-Point*TrailingStop)) || (b_trail ==0)){
                        b_trail = Bid-NormalizeDouble(Point*TrailingStop,Digits);
                    }
                 }
              }
            }
            if( OrderType() == OP_SELL ){
             s_o++;
             oos = OrderOpenPrice();
             s_OpenPrice=NormalizeDouble(oos+SL_point*Point,Digits);
              if(TrailingStop>0){
               if(NormalizeDouble(oos-Ask,Digits)>(Point*TrailingStop)){
                  if((s_trail>(Ask+Point*TrailingStop)) || (s_trail==0)){
                     s_trail = Ask+NormalizeDouble(Point()*TrailingStop,Digits);
                    }
                 }
              }
            }        
         }
      }   
   }
   
   if(b_o >0){
      if(Ask <= b_OpenPrice)ret = 1;
   }
   if(s_o >0){
      if(Bid >= s_OpenPrice)ret = -1;
   }
   if(b_o >0){
      if(Bid <= b_trail && b_trail > 0){
      ret = 1;
      b_trail =0;
      }
   }
   if(s_o >0){
      if(Ask >= s_trail && s_trail >0 ){
      ret = -1;
      Print("trail(s) done:",s_trail);
      s_trail=0;
      }  
   }

   return ret;
}



void goCloseOrder(int CloseSignal){

   int ret = 0;
   int b_o = 0, s_o = 0;
   
   for(int i=0; i<OrdersTotal(); i++)
   {  
      if(OrderSelect(i, SELECT_BY_POS)==true)
      {  
         if( OrderSymbol() == _Symbol && OrderMagicNumber() == MAGIC ){
            if( OrderType() == OP_BUY ) b_o++;
            if( OrderType() == OP_SELL ) s_o++;        
         }
      }   
   }
   
   if(b_o > 0 && CloseSignal == 1){
      ret = OrderClose(b_ticket, OrderLots(), Bid,0);
   }
   
   if(s_o > 0 && CloseSignal == -1){
      ret = OrderClose(s_ticket, OrderLots(), Ask,0);
   }

}

double checkAve(){
   
   double tmp_ave=0;
   
   for(int i=1;i<=sample;i++){
      tmp_ave += (Close[i+time] - Close[i]);
   }
   
   return (tmp_ave/sample);   
}

double checkStdexp(double ave){
   
   double tmp1=0,tmp2=0;
   
   for(int i=1;i<sample;i++){
      tmp1 = (Close[i+time] - Close[i])-ave;
      tmp2 = tmp2 + tmp1*tmp1;
   }
   
   return MathSqrt(tmp2/sample);      

}

bool checkWait(datetime o_time){
   if(waitflag){
      if((o_time + waittime) < TimeCurrent()){
         return true;
      }else{
         return false;
      }
   }else{
      return true;
   }
}

double calcSigma(int sigma){
   double ave=0,stdexp=0,ret=0;
   ave = checkAve();
   stdexp = checkStdexp(ave);
   ret = sigma*stdexp + ave;
   
   Comment("AVE:",NormalizeDouble(ave,Digits)," STDEXP:",NormalizeDouble(stdexp,Digits)," SIGMA:",NormalizeDouble(ret,Digits),
   " Def_Close:",NormalizeDouble((Close[time] - Close[0]),Digits), "\n Weekend:",Weekend(tokyotime) );
   
   return ret;
}

bool Weekend(datetime tm){
   bool ret = false;
   int Yobi = TimeDayOfWeek(tm);
   int Ji = TimeHour(tm);
   if((Yobi == SATURDAY && Ji >= 5)||Yobi==SUNDAY || (Yobi ==MONDAY && Ji <7))ret=true;
   else ret=false;
   return(ret);
}


int GetGMTOffset()
  {
   // バックテストの場合はパラメーター指定の固定値を返却
   if ( IsTesting() )
     {
      if(IsSummerTime()){
         return( Test_SummerTimeGMTOffset );
      }else{
         return( Test_WinterTimeGMTOffset );
      }
     }
     
 
   // 日付処理で使用
   MqlDateTime current;
   MqlDateTime gmt;
 
   // 補正処理で使用
   int offset = 0;
    
   // MT4時刻を取得する
   TimeCurrent( current );
 
   // GMT時刻を取得する
   TimeGMT( gmt );
 
   // 日付が異なる場合の補正処理
   if( ( current.day - gmt.day ) > 0 )
     {
      offset =  24;
     }
   if( ( current.day - gmt.day ) < 0 )
     {
      offset = -24;
     }
 
   // GMTOffset値を返却
   return ( current.hour - gmt.hour + offset );
  }
  
bool IsSummerTime(){
   //3月第2日曜日午前2時〜11月第1日曜日午前2時
   switch(Year()){
      case 2005: if(StringToTime("2005.3.13")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2005.11.6"))return true; break;
      case 2006: if(StringToTime("2006.3.12")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2006.11.5"))return true; break;
      case 2007: if(StringToTime("2007.3.11")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2007.11.4"))return true; break;
      case 2008: if(StringToTime("2008.3.9") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2008.11.2"))return true; break;
      case 2009: if(StringToTime("2009.3.8") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2009.11.1"))return true; break;
      case 2010: if(StringToTime("2010.3.14")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2010.11.7"))return true; break;
      case 2011: if(StringToTime("2011.3.13")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2011.11.6"))return true; break;
      case 2012: if(StringToTime("2012.3.11")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2012.11.4"))return true; break;
      case 2013: if(StringToTime("2013.3.10")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2013.11.3"))return true; break;
      case 2014: if(StringToTime("2014.3.9") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2014.11.2"))return true; break;
      case 2015: if(StringToTime("2015.3.8") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2015.11.1"))return true; break;
      case 2016: if(StringToTime("2016.3.13")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2016.11.6"))return true; break;
      case 2017: if(StringToTime("2017.3.12")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2017.11.5"))return true; break;
      case 2018: if(StringToTime("2018.3.11")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2018.11.4"))return true; break;
      case 2019: if(StringToTime("2019.3.10")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2019.11.3"))return true; break;
      case 2020: if(StringToTime("2020.3.8") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2020.11.1"))return true; break;
      case 2021: if(StringToTime("2021.3.14")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2021.11.7"))return true; break;
      case 2022: if(StringToTime("2022.3.13")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2022.11.6"))return true; break;
      case 2023: if(StringToTime("2023.3.12")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2023.11.5"))return true; break;
      case 2024: if(StringToTime("2024.3.10")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2024.11.3"))return true; break;
      case 2025: if(StringToTime("2025.3.9") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2025.11.2"))return true; break;
      case 2026: if(StringToTime("2026.3.8") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2026.11.1"))return true; break;
      case 2027: if(StringToTime("2027.3.14")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2027.11.7"))return true; break;
      case 2028: if(StringToTime("2028.3.12")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2028.11.5"))return true; break;
      case 2029: if(StringToTime("2029.3.11")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2029.11.4"))return true; break;
      case 2030: if(StringToTime("2030.3.10")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2030.11.3"))return true; break;
      case 2031: if(StringToTime("2031.3.9") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2031.11.2"))return true; break;
      case 2032: if(StringToTime("2032.3.14")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2032.11.7"))return true; break;
      case 2033: if(StringToTime("2033.3.13")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2033.11.6"))return true; break;
      case 2034: if(StringToTime("2034.3.12")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2034.11.5"))return true; break;
      case 2035: if(StringToTime("2035.3.11")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2035.11.4"))return true; break;
      case 2036: if(StringToTime("2036.3.9") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2036.11.2"))return true; break;
      case 2037: if(StringToTime("2037.3.8") <=TimeCurrent()&&TimeCurrent()<=StringToTime("2037.11.1"))return true; break;
      case 2038: if(StringToTime("2038.3.14")<=TimeCurrent()&&TimeCurrent()<=StringToTime("2038.11.7"))return true; break;
   }
   return false;
}

int Hour2Sec(int hour){
   return (hour * 60 * 60 );
}
