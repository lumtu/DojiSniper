//=====================================================================
// Expert DojiSniper
//=====================================================================
#property copyright  "lumtu"
#property link       "develop@lumtu.de"
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
//---------------------------------------------------------------------
// External parameters:
//---------------------------------------------------------------------

// input group "Global";
input ENUM_TIMEFRAMES InpHTF = PERIOD_H4; // Higher timeframe
input ENUM_TIMEFRAMES InpEntryTF = PERIOD_H4; // Entry timeframe
input int InpWinRat = 2;    // winrate R/R
input double InpDojiBody = 0.15; // Doji-Body in Percent 0.01 to 1 (0.15 default);
input double InpEntryAtr = 1.2;

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

CArrayDouble g_targets;

bool m_useMoneyInsteadOfPercentage = UseMoneyInsteadOfPercentage;
bool m_useEquityInsteadOfBalance = UseEquityInsteadOfBalance; // Eigenkapital statt Balance
double m_fixedBalance = FixedBalance;            // If greater than 0, position size calculator will use it instead of actual account balance.
double m_moneyRisk = MoneyRisk;               // Risk tolerance in base currency
double m_risk = TotalRiskInPercent;                    // Risk tolerance in percentage points
int m_lotFactor = LotFactor;


CSymbolInfo m_symbol;
CAccountInfo m_account;
CPositionInfo m_position; // trade position object
CTrade m_trade;

int m_margin_mode=0;
void SetMarginMode(void) { m_margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE); }
bool IsHedging(void) { return(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING); }


//---------------------------------------------------------------------
// Initialization event handler:
//---------------------------------------------------------------------
int OnInit()
{
   SetMarginMode();
   
    ResetLastError();

    m_trade.SetExpertMagicNumber(Expert_MagicNumber);
    m_symbol.Name(_Symbol);
    
    return(0);
}
//---------------------------------------------------------------------
// Deinitialization event handler:
//---------------------------------------------------------------------
void OnDeinit(const int _reason)
{
// Delete indicator handle:
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
    }

   bool canOpen = true; //!SelectPosition(_Symbol);
    
// Check if there is the BUY signal:
    if(canOpen && CheckBuySignal(current_signal,prev_signal)==1) {
        double price = m_symbol.Ask();
        double lots = TradeSizeOptimized(price-g_stopLost);
        m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,lots,SymbolInfoDouble(Symbol(),SYMBOL_ASK), g_stopLost, g_takeProfit, "DojiSniper" );
        
        SaveChart(ORDER_TYPE_BUY);
    }

// Check if there is the SELL signal:
    if(canOpen && CheckSellSignal(current_signal,prev_signal)==1) {
        double price = m_symbol.Bid();
        double lots = TradeSizeOptimized(g_stopLost-price);
        m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,lots,SymbolInfoDouble(Symbol(),SYMBOL_BID), g_stopLost, g_takeProfit, "DojiSniper");
        
        SaveChart(ORDER_TYPE_SELL);
    }

// Save current signal:
    prev_signal=current_signal;
}

void SaveChart(ENUM_ORDER_TYPE order_type ) {

    string tf = EnumToString((ENUM_TIMEFRAMES)_Period);
    string ot = EnumToString((ENUM_TIMEFRAMES)order_type);
    string filename = StringFormat("DojiSniper_%s_%s_%s.PNG", _Symbol, tf, ot );
    
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
            return(1);
        }
        
    }

    if(_signal==-1 || _signal==0) {
        // If there is the SELL position already opened, then return:
        if(position_type==(long)POSITION_TYPE_SELL) {
            return(1);
        }
    }

// Close position:
    // CTrade   trade;
    // trade.PositionClose(Symbol());

    return(0);
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
#define LEN 2
//---------------------------------------------------------------------
int GetSignal()
{
    if(!CheckNewBar())
        return 0;
    
    MqlRates htf_bars[], etf_bars[];

    ResetLastError();
    
    if(  CopyRates(_Symbol, InpHTF    , 1,1, htf_bars) !=1
      || CopyRates(_Symbol, InpEntryTF, 1,1, etf_bars) !=1
      ) {
        Print("CopyRates copy error, Code = ",GetLastError());
        return(0);
    }

    int trend = 0;
    if(false == IsDoji(htf_bars[0])) {
        return trend; // kein doji
    }
   
    double atr = 1.5;
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
    
    double ticksize = (spread * 2.0) * (trend>0 ? 1.0 : -1.0) ;
    
    if(trend>0) {
        g_stopLost   = etf_bars[0].low - ticksize;
        g_takeProfit = ask+ ((ask -g_stopLost) *InpWinRat);
        
    } else if(trend<0) {
        g_stopLost   = etf_bars[0].high + ticksize;
        g_takeProfit = bid+ ((g_stopLost -bid) *InpWinRat);
    }
            
    g_stopLost   = m_symbol.NormalizePrice(g_stopLost);
    g_takeProfit = m_symbol.NormalizePrice(g_takeProfit);
    
    if( MathAbs(g_stopLost - ask ) > MathAbs( g_takeProfit-ask) ) {
        trend = 0;
    }
    
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
int CheckNewBar()
{
    MqlRates      current_rates[1];

    ResetLastError();
    if(CopyRates(Symbol(),Period(),0,1,current_rates)!=1) {
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
