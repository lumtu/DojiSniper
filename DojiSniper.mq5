//+------------------------------------------------------------------+
//|                                                  CandleRange.mqh |
//|                                        Copyright 2023, U. Köller |
//|                              https://github.com/lumtu/DojiSniper |
//+------------------------------------------------------------------+
//=====================================================================
// Expert DojiSniper
//=====================================================================
#property copyright  "lumtu"
#property link       "https://github.com/lumtu/DojiSniper"
#property version    "1.00"
#property description "Expert DojiSniper"

//---------------------------------------------------------------------
// Included libraries:
//---------------------------------------------------------------------
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Arrays\ArrayDouble.mqh>

#include "CandleRange.mqh"


enum ENUM_HOURS
  {
   hour_00  =0,   // 00
   hour_01  =1,   // 01
   hour_02  =2,   // 02
   hour_03  =3,   // 03
   hour_04  =4,   // 04
   hour_05  =5,   // 05
   hour_06  =6,   // 06
   hour_07  =7,   // 07
   hour_08  =8,   // 08
   hour_09  =9,   // 09
   hour_10  =10,  // 10
   hour_11  =11,  // 11
   hour_12  =12,  // 12
   hour_13  =13,  // 13
   hour_14  =14,  // 14
   hour_15  =15,  // 15
   hour_16  =16,  // 16
   hour_17  =17,  // 17
   hour_18  =18,  // 18
   hour_19  =19,  // 19
   hour_20  =20,  // 20
   hour_21  =21,  // 21
   hour_22  =22,  // 22
   hour_23  =23,  // 23
  };

enum ENUM_MINUTES
  {
   min_00  =0,   // 00
   min_05  =5,   // 05
   min_10  =10,  // 10
   min_15  =15,  // 15
   min_20  =20,  // 20
   min_25  =25,  // 25
   min_30  =30,  // 30
   min_35  =35,  // 35
   min_40  =40,  // 40
   min_45  =45,  // 45
   min_50  =50,  // 50
   min_55  =55   // 55
  };


//---------------------------------------------------------------------
// External parameters:
//---------------------------------------------------------------------

enum ENUM_PARTIAL {
    None,  // None
    HalfR, // Half R
    _1R,   // 1R
    _2R,   // 2R
};



// input group "Global";
input ENUM_TIMEFRAMES InpHTF = PERIOD_H4;  // Higher timeframe
input ENUM_TIMEFRAMES InpETF = PERIOD_M15; // Sniper timeframe
input double InpWinRat   = 2;    // Winrate 
input double InpDojiBody = 0.15; // Doji-Body in Percent 0.01 to 1 (0.15 default);
input double InpEntryAtr = 1.2;  // ATR 1<=>100%  der letzten Glättung
input int    InpAtrPeriod = 15;  // Glättungsperiode 
input bool   Inp1RBE = true;   // Auf BE wenn 1R erreicht
input ENUM_PARTIAL InpPartial = _1R; // Teilgewinn

input group "Trading-Time"
input ENUM_HOURS   InpBeginH = hour_07;
input ENUM_MINUTES InpBeginM = min_05;
input ENUM_HOURS   InpEndH   = hour_15;
input ENUM_MINUTES InpEndM   = min_45;

input group "Money management"
input bool   UseMoneyInsteadOfPercentage = false;
input bool   UseEquityInsteadOfBalance   = true; // Eigenkapital statt Balance
input double FixedBalance       = 0.0;      // FixedBalance If greater than 0, position size calculator will use it instead of actual account balance.
input double MoneyRisk          = 0.0;      // MoneyRisk Risk tolerance in base currency
input double TotalRiskInPercent = 1.0;      // Risk tolerance in percentage points
input int    LotFactor          = 1;

input ulong Expert_MagicNumber = 253672;  // MagicNumber

//---------------------------------------------------------------------
int    current_signal=0;
int    prev_signal=0;
bool   is_first_signal=true;
double g_stopLost = 0.0;
double g_takeProfit = 0.0;

bool   g_take_partials=false;
bool   g_close_at_open=false;

CArrayDouble g_targets;

bool m_useMoneyInsteadOfPercentage = UseMoneyInsteadOfPercentage;
bool m_useEquityInsteadOfBalance = UseEquityInsteadOfBalance; // Eigenkapital statt Balance
double m_fixedBalance = FixedBalance;            // If greater than 0, position size calculator will use it instead of actual account balance.
double m_moneyRisk = MoneyRisk;               // Risk tolerance in base currency
double m_risk = TotalRiskInPercent;                    // Risk tolerance in percentage points
int m_lotFactor = LotFactor;


bool barIsBured=true;

CSymbolInfo m_symbol;
CAccountInfo m_account;
CPositionInfo m_position; // trade position object
CTrade m_trade;

int m_margin_mode=0;
void SetMarginMode(void) { m_margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE); }
bool IsHedging(void) { return(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING); }


int g_start_hour = InpBeginH;
int g_end_hour   = InpEndH;
int g_start_min  = InpBeginM;
int g_end_min    = InpEndM;


class CTradeInfo {
    string _symbol;
    datetime _begin;
    datetime _end;
    double _open;
    double _close;
    double _tp;
    double _sl;
        
public:
    CTradeInfo() {
        _symbol = _Symbol;
    } 
    
    void Begin(datetime val) { _begin=val;}
    void End(datetime val) { _end=val;}
    void Open(double val) {_open=val;}
    void TP(double val) {_tp=val;}
    void SL(double val) {_sl=val;}
    void Close() {
        double ask=0.0, bid=0.0;
        if(SymbolInfoDouble(_symbol,SYMBOL_ASK,ask) && SymbolInfoDouble(_symbol,SYMBOL_BID,bid)) {
            double tp_diff = MathAbs( _tp- (IsLong() ? bid : ask ));
            double sl_diff = MathAbs( _sl- (IsLong() ? ask : bid ));
            _close=_sl;
            if(tp_diff < sl_diff) {
                _close = _tp; 
            }
        }
    }
    
    bool IsLong()const {return _tp>_sl;}
    
    void Save() {
        
        MqlRates ahtf[];
        CopyRates(_symbol, InpHTF, 0, 100, ahtf);
    
        MqlRates aetf[];
        CopyRates(_symbol, InpETF, 0, 300, aetf);

        string res = "{"; 
        res += ToKey_StrVal("symbol", _symbol) +", ";  
        res += ToKey_NumVal("begin", (long )_begin) +", ";
        res += ToKey_NumVal("end",  (long)_end ) +", ";
        res += ToKey_NumVal("open", _open) +", ";
        res += ToKey_NumVal("close", _close) +", ";
        res += ToKey_NumVal("tp", _tp) +", ";
        res += ToKey_NumVal("sl", _sl) +", ";
        res += ToKey_MqlRate("htf", ahtf) +", "; 
        res += ToKey_MqlRate("etf", aetf);
        res += "}";   
       
        MqlDateTime dt;
        TimeToStruct(_begin, dt);
       
        ResetLastError(); 
        string filename = StringFormat("%d/%d/Trade_%s %d-%02d-%02d %02d%02d%02d.json", 
            dt.year,
            dt.mon,
            _symbol,
            dt.year,
            dt.mon,
            dt.day,
            dt.hour,
            dt.min,
            dt.sec
            );

        int filehandle=FileOpen( filename, FILE_WRITE|FILE_ANSI|FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            FileWriteString(filehandle, res);
            FileFlush(filehandle);
            FileClose(filehandle);
        } else {
            int errcode = GetLastError();
            Print("Fehler in WebRequest. Fehlercode  =",errcode); 
        }
    }
    
    string ToKey_StrVal(string key, string val) {
        return "\""+key+"\":\""+val+"\"";
    }
    string ToKey_NumVal(string key, long val) {
        return "\""+key+"\": "+IntegerToString(val)+"";
    }
    string ToKey_NumVal(string key, double val) {
        return "\""+key+"\": "+DoubleToString(val)+"";
    }
    string ToKey_MqlRate(string key, MqlRates& rates[]) {
        string data="";
        int size = ArraySize(rates);
        for(int i=0; i<size; ++i) {
            if(i>0) data += ",";
            data += "{";
            data += "\"open\":" + DoubleToString(rates[i].open);
            data += ",\"close\":" + DoubleToString(rates[i].close);
            data += ",\"high\":" + DoubleToString(rates[i].high);
            data += ",\"low\":" + DoubleToString(rates[i].low);
            data += ",\"time\":" + IntegerToString( (long )(rates[i].time) );
            data += "}";
        }
        return "\""+key+"\": ["+data +"]";
    }
  
};

CTradeInfo* g_trade=NULL;


bool g_test_mode=true;

//---------------------------------------------------------------------
// Initialization event handler:
//---------------------------------------------------------------------
int OnInit()
{
    SetMarginMode();
   
    ResetLastError();

    m_trade.SetExpertMagicNumber(Expert_MagicNumber);
    m_symbol.Name(_Symbol);
    
   if(g_end_hour < g_start_hour) {
      g_start_hour += 24;
   }
    
   return(0);
}
//---------------------------------------------------------------------
// Deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit(const int _reason)
{
// Delete indicator handle:
}


void OnTesterInit(void) {
    g_test_mode = true;
    // return 0;
}

void OnTesterDeinit() {
}

//---------------------------------------------------------------------
void OnTick()
{
        
// Wait for beginning of a new bar:
    // if(CheckNewBar()!=1) { return;  }
    m_symbol.Refresh();
    m_symbol.RefreshRates();
    

// Get signal to open/close position:
    current_signal=GetSignal();
    if(is_first_signal==true) {
        prev_signal=current_signal;
        is_first_signal=false;
    }

// Select position by current symbol:
    if(PositionSelect(Symbol())==true) {
        // Check if we need to close a reverse position:
        if(CheckPositionClose(current_signal)==1) {
            return;
        }
 
    } else if(g_trade != NULL) {
        ENUM_ORDER_TYPE order_type = g_trade.IsLong() ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        SaveChart(order_type);

        g_trade.End(TimeLocal());
        g_trade.Close();
        g_trade.Save();
        delete g_trade;
        g_trade = NULL;
    }

    if(false == IsInTime())
        return;

    bool canOpen = !barIsBured; //!SelectPosition(_Symbol);
    
// Check if there is the BUY signal:
    if(canOpen && CheckBuySignal(current_signal,prev_signal)==1) {
        double price = m_symbol.Ask();
        double lots = TradeSizeOptimized(price-g_stopLost);
        if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,lots, price, g_stopLost, g_takeProfit, "DojiSniper" ))
        {
            g_trade = new CTradeInfo();
            g_trade.Begin(TimeLocal());
            g_trade.Open(price);
            g_trade.SL(g_stopLost);
            g_trade.TP(g_takeProfit);
            
            printf("Position by %s to be opened",Symbol());
            g_take_partials = false;
            g_close_at_open=false;
            // SaveChart(ORDER_TYPE_BUY);
            barIsBured = true;

        } else {
            printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f,TP=%f", price, g_stopLost, g_takeProfit);
        }
        
    }

// Check if there is the SELL signal:
    if(canOpen && CheckSellSignal(current_signal,prev_signal)==1) {
        double price = m_symbol.Bid();
        double lots = TradeSizeOptimized(g_stopLost-price);
        if(m_trade.PositionOpen(Symbol(), ORDER_TYPE_SELL, lots, price, g_stopLost, g_takeProfit, "DojiSniper"))
        {
            g_trade = new CTradeInfo();
            g_trade.Begin(TimeLocal());
            g_trade.Open(price);
            g_trade.SL(g_stopLost);
            g_trade.TP(g_takeProfit);
    
            printf("Position by %s to be opened", Symbol());
            g_take_partials = false;
            g_close_at_open=false;
            // SaveChart(ORDER_TYPE_BUY);
            barIsBured = true;

        } else {
            printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
            printf("Open parameters : price=%f,SL=%f,TP=%f", price, g_stopLost, g_takeProfit);
        }
        
    }

// Save current signal:
    prev_signal=current_signal;
}

void SaveChart(ENUM_ORDER_TYPE order_type ) {

    MqlDateTime dt;
    TimeCurrent(dt);

    string filename = StringFormat("%d/%d/Trade_%s %d-%02d-%02d %02d%02d%02d.png", 
        dt.year,
        dt.mon,
        _Symbol,
        dt.year,
        dt.mon,
        dt.day,
        dt.hour,
        dt.min,
        dt.sec
        );

  
    ChartScreenShot( ChartID(), filename, 1024, 768,  ALIGN_RIGHT );        
}

bool SelectPosition(const string symbol)
  {
   bool res=false;
//---
   if(IsHedging())
     {
      uint total=PositionsTotal();
      for(uint i=0; i<total; i++)
        {
         string position_symbol=PositionGetSymbol(i);
         if(position_symbol==symbol &&   Expert_MagicNumber==PositionGetInteger(POSITION_MAGIC))
           {
            res=true;
            break;
           }
        }
     }
   else
      res=PositionSelect(symbol);
//---
   return(res);
  }


//---------------------------------------------------------------------
// Check if we need to close position:
//---------------------------------------------------------------------
// returns:
//  0 - no open position
//  1 - position already opened in signal's direction
//---------------------------------------------------------------------
int CheckPositionClose(int _signal)
{
    long position_type=PositionGetInteger(POSITION_TYPE);
    
    m_position.Select(Symbol());

    if(_signal==1 || _signal==0) {
    
        // If there is the BUY position already opened, then return:
        if(position_type==(long)POSITION_TYPE_BUY) {
            CheckTrailingStop();
            ChechPartials();
            
            if(!g_close_at_open)
                return(1);
        }
        
    }

    if(_signal==-1 || _signal==0) {
        // If there is the SELL position already opened, then return:
        if(position_type==(long)POSITION_TYPE_SELL) {
            CheckTrailingStop();
            ChechPartials();
            if(!g_close_at_open)
                return(1);
        }
    }

// Close position:
    if(g_close_at_open ) {
        double ask = m_symbol.Ask();
        double bid = m_symbol.Bid();
        double open = m_position.PriceOpen();
        
        bool close = false;
        if(g_stopLost<g_takeProfit && ask < open) 
            close = true;
        else if(g_stopLost>g_takeProfit && bid > open) 
            close = true;
            
        if(close) {
            m_trade.PositionClose(Symbol());
        }
    }

    return(0);
}

double Round(double price)
{
    double tick_size = m_symbol.TickSize();

   return NormalizeDouble( round( price / tick_size ) * tick_size, m_symbol.Digits() );    
   
}

void CheckTrailingStop() {
    
    // nicht auf BE 
    if(false == Inp1RBE)
        return;
    
    double ask = m_symbol.Ask();
    double bid = m_symbol.Bid();
    double spread = ask-bid;
    long position_type=PositionGetInteger(POSITION_TYPE);
    if(position_type==(long)POSITION_TYPE_BUY) {
        double open = m_position.PriceOpen();
        double sl = m_position.StopLoss();
        double tp = m_position.TakeProfit();
        
        if(sl ==0 ){
            sl = open;
        } else {
            if(sl >= (open-spread) )
                return;
        }
    
        double r1 = MathAbs(open - sl);
        if(ask > (open + r1)) {
            g_close_at_open = false;
            if(!m_trade.PositionModify(m_position.Ticket(), Round(sl), g_takeProfit))
            {
                g_close_at_open = true;
                Print("Error setting SL");
            }
        }
    
    
    } else if(position_type==(long)POSITION_TYPE_SELL) {
        double open = m_position.PriceOpen();
        double sl = m_position.StopLoss();
        double tp = m_position.TakeProfit();
    
        if(sl ==0 ){
            sl = open;
            
        } else {
            if(sl <= (open+spread) )
                return;
        }

        double r1 = MathAbs(sl - open);
        if(bid < (open - r1)) {
            g_close_at_open = false;
            if(!m_trade.PositionModify(m_position.Ticket(), Round(sl), g_takeProfit))
            {
                g_close_at_open = true;
                Print("Error setting SL");
            }
        }
    }
}

void ChechPartials()
{
    // nicht auf BE 
    if(InpPartial == None)
        return;
    
    if(g_take_partials)
        return;
    
    double ask = m_symbol.Ask();
    double bid = m_symbol.Bid();
    double spread = ask-bid;
    long position_type=PositionGetInteger(POSITION_TYPE);
    if(position_type==(long)POSITION_TYPE_BUY) {
        double open = m_position.PriceOpen();
        double tp = m_position.TakeProfit();
        double wr_steps = MathAbs((tp - open) / InpWinRat);
    
        // Teil-Ziel noch nicht erreicht
        if(bid < (open + wr_steps) )
            return;
    
        double minLotes = m_symbol.LotsMin();
        double partialSize = (m_position.Volume() / 2.0);
        
        // Position to small
        if(partialSize < minLotes) {
            // Position to small
            g_take_partials = true;
            return;
        }
        
        double LotStep = m_symbol.LotsStep();
        partialSize = partialSize - MathMod(partialSize, LotStep);
        printf("Partial size: %.3f", partialSize);
    
        if(IsHedging()) {
            g_take_partials = m_trade.PositionClosePartial(m_position.Ticket(), partialSize);
            
        } else {
            g_take_partials = m_trade.Sell(partialSize, _Symbol, 0.0, 0.0, 0.0, "Take partials");
        }
    
    
    } else if(position_type==(long)POSITION_TYPE_SELL) {
        double open = m_position.PriceOpen();
        double tp = m_position.TakeProfit();
        double wr_steps = MathAbs((open-tp) / InpWinRat);
    
        // Teil-Ziel noch nicht erreicht
        if(ask > (open - wr_steps) )
            return; 
    
        double minLotes = m_symbol.LotsMin();
        double partialSize = (m_position.Volume() / 2.0);
        
        // Position to small
        if(partialSize < minLotes) {
            g_take_partials = true;
            return;
        }
        
        double LotStep = m_symbol.LotsStep();
        partialSize = partialSize - MathMod(partialSize, LotStep);
        printf("Partial size: %.3f", partialSize);
    
        if(IsHedging()) {
            g_take_partials = m_trade.PositionClosePartial(m_position.Ticket(), partialSize);
            
        } else {
            g_take_partials = m_trade.Sell(partialSize, _Symbol, 0.0, 0.0, 0.0, "Take partials");
        }
    }
}


//---------------------------------------------------------------------
// Check if there is the BUY signal:
//---------------------------------------------------------------------
// returns:
//  0 - no signal
//  1 - there is the BUY signal
//---------------------------------------------------------------------
int CheckBuySignal(int _curr_signal,int _prev_signal)
{
// Check if signal has changed to BUY:
    if((_curr_signal==1 && _prev_signal==0) || (_curr_signal==1 && _prev_signal==-1)) {
        return(1);
    }

    return(0);
}
//---------------------------------------------------------------------
// Check if there is the SELL signal:
//---------------------------------------------------------------------
// returns:
//  0 - no signal
//  1 - there is the SELL signal
//---------------------------------------------------------------------
int CheckSellSignal(int _curr_signal,int _prev_signal)
{
// Check if signal has changed to SELL:
    if((_curr_signal==-1 && _prev_signal==0) || (_curr_signal==-1 && _prev_signal==1)) {
        return(1);
    }

    return(0);
}

//---------------------------------------------------------------------
// Get signal to open/close position:
//---------------------------------------------------------------------
int GetSignal()
{
    if(!CheckNewBar(Period()))
        return 0;
    
    
    if(CheckNewBar(InpHTF)){
        barIsBured = false;
    }
    
    MqlRates htf_bars[], etf_bars[];

    ResetLastError();
    
    if(  CopyRates(_Symbol, InpHTF, 1,1, htf_bars) !=1
      || CopyRates(_Symbol, InpETF, 1,1, etf_bars) !=1
      ) {
        Print("CopyRates copy error, Code = ",GetLastError());
        return(0);
    }

    int trend = 0;
    if(false == IsDoji(htf_bars[0])) {
        return trend; // kein doji
    }
   
    CandleRange cr(_Symbol, InpETF, InpAtrPeriod);
    double atr = cr.Atr();
    
    // Hier nocht die atr ermitteln
    if(atr < InpEntryAtr) {
        return trend; // atr zu klein
    }

    if( etf_bars[0].close >  htf_bars[0].high &&
        etf_bars[0].open <  htf_bars[0].high) {
        trend = 1;
        
    } else if( etf_bars[0].close <  htf_bars[0].low &&
        etf_bars[0].open >  htf_bars[0].low) {
        trend = -1;
    }
   

    double ask = m_symbol.Ask();
    double bid = m_symbol.Bid();
    double spread = ask - bid;
    
    double ticksize = (spread * 2.0);
    
    if(trend>0) {
        g_stopLost   = etf_bars[0].low - ticksize;
        g_takeProfit = ask+ ((ask -g_stopLost) *InpWinRat);
        
    } else if(trend<0) {
        g_stopLost   = etf_bars[0].high + ticksize;
        g_takeProfit = bid - ((g_stopLost -bid) *InpWinRat);
    } else {
        return trend;
    }

    g_stopLost   = m_symbol.NormalizePrice(g_stopLost);
    g_takeProfit = m_symbol.NormalizePrice(g_takeProfit);
    
    
    if( trend >0 && g_stopLost>=ask) trend = 0;
    if( trend <0 && g_stopLost<=bid) trend = 0;
   
    return trend;
}

bool IsDoji(MqlRates &rate) {
    
    double high = rate.high;
    double low = rate.low;
    double open = rate.open;
    double close = rate.close;
    const double DOJI_PCT = InpDojiBody; // 0.15

    const double sizeBody = MathAbs(open - close);
    const double sizeBar = (high - low);
    return (sizeBody <= DOJI_PCT * sizeBar);
}

bool IsInTime()
{
   if(g_start_hour == 0 && g_start_min == 0
     && g_end_hour == 0 && g_end_min == 0)
     {
      return true;
     }

   MqlDateTime timeLocal;
   TimeCurrent(timeLocal);
   

   int curr = (timeLocal.hour * 1000) + (timeLocal.min);
   int start = (g_start_hour * 1000) + (g_start_min);
   int end = (g_end_hour * 1000) + (g_end_min);
   
   if( curr > start && curr < end)
   {
      return true;
   }

   return false;
}



void TryAddTarget(int dir, double price)
{
   if(price<=0.0 || dir == 0)
      return;

   price = m_symbol.NormalizePrice(price);
   
   double ask = m_symbol.Ask();
   double bid = m_symbol.Bid();
   double spread = ask - bid;

   double currPrice = dir>0 ? ask : bid;
   currPrice += spread * dir;
   
   if(  (dir > 0 && price < currPrice) 
     || (dir < 0 && price > currPrice)  ) {
      return;
   }

   g_targets.Add(price);   
   
   g_targets.Sort(1);
   
}


//---------------------------------------------------------------------
// Returns flag of a new bar:
//---------------------------------------------------------------------
// - if it returns 1, there is a new bar
//---------------------------------------------------------------------
int CheckNewBar(ENUM_TIMEFRAMES tf)
{
    MqlRates      current_rates[1];

    ResetLastError();
    if(CopyRates(Symbol(), tf,0,1,current_rates)!=1) {
        Print("CopyRates copy error, Code = ",GetLastError());
        return(0);
    }

    if(current_rates[0].tick_volume>1) {
        return(0);
    }

    return(1);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(double stopLoss)
{

    double Size, RiskMoney, PositionSize = 0;

    if(m_symbol.CurrencyBase() == "")
        return (0);

    if(m_fixedBalance > 0) {
        Size = m_fixedBalance;
    } else if(m_useEquityInsteadOfBalance) {
        Size = m_account.Equity();
    } else {
        Size = m_account.Balance();
    }

    if(!m_useMoneyInsteadOfPercentage) {
        RiskMoney = Size * m_risk / 100;
    } else {
        RiskMoney = m_moneyRisk;
    }

    double UnitCost = m_symbol.TickValue();
    double TickSize = m_symbol.TickSize();

    if((stopLoss != 0) && (UnitCost != 0) && (TickSize != 0)) {
        PositionSize = NormalizeDouble(RiskMoney / (stopLoss * UnitCost / TickSize), m_symbol.Digits());
    }

    PositionSize = MathMax(PositionSize, m_symbol.LotsMin());
    PositionSize = MathMin(PositionSize, m_symbol.LotsMax());

    PositionSize = m_lotFactor * PositionSize;
    double LotStep = m_symbol.LotsStep();
    PositionSize = PositionSize - MathMod(PositionSize, LotStep);

    printf("Position Size: %.3f", PositionSize);

    return (PositionSize);
}

//+------------------------------------------------------------------+



