//+------------------------------------------------------------------+
//|                                                  CandleRange.mqh |
//|                                       Copyright 2023, Udo Köller |
//|                                              http://www.lumtu.de |
//+------------------------------------------------------------------+


class CandleRange {

private:
    string m_symbol;
    ENUM_TIMEFRAMES m_period;
    int m_size;
    MqlRates m_rates[];
    bool m_userBody;
    double m_dojiBody;
public:
    CandleRange(string symbol, ENUM_TIMEFRAMES period, int size)
     : m_symbol(symbol)
     , m_period(period)
     , m_size(size)
     , m_userBody(true)
     , m_dojiBody(0.15)
    {
        RefreshRates();
    }

    void DojiBody(double val) { m_dojiBody = val; }
    double DojiBody() const { return m_dojiBody; }

    bool RefreshRates(){
        return CopyRates(m_symbol, m_period, 0, m_size, m_rates) == m_size;
    }
    
    double Atr() {
        double range = 0.0;
        
        int idx = 0;
        for(idx=0; idx<m_size-1; ++idx) {
            if(false == IsValidBar(idx+1)) 
                break;
            
            double high = High(idx);
            double low  = Low(idx);
            range += high - low;
        }
        
        if(range == 0.0 || idx ==0)
            return 0.0;
        
        range = range / (double)(idx);
        
        double lastRange = High(idx) - Low(idx);
      
        double atr = (lastRange * 100.0 / range) / 100.0;
        
        return atr;
    }
    
    bool IsValidBar(int idx) {
        if(idx<0 || idx>=m_size )
            return false;
        
        if( m_rates[idx].tick_volume <=1)     {
            return false;
        }
        
        if( m_rates[idx].high == m_rates[idx].low)     {
            return false;
        }
        
        return true;
    }
    
    bool IsDoji() const {
        int idx = m_size-1;
        double open = m_rates[idx].open;
        double close = m_rates[idx].close;
        double high = m_rates[idx].high;
        double low = m_rates[idx].low;
        double sizeBody = MathAbs(open - close);
        double sizeBar = (high - low);
        return (sizeBody <= m_dojiBody * sizeBar);
    }
    
    bool IsGreen() {
        return IsGreen(0);
    }
    
    bool IsGreen(int idx) {
        idx = m_size - (idx+1);
        double open = m_rates[idx].open;
        double close = m_rates[idx].close;
        return open < close;
    }
    
    int BodyInPerc() {
        int idx = m_size-1;
        double open = m_rates[idx].open;
        double close = m_rates[idx].close;
        double high = m_rates[idx].high;
        double low = m_rates[idx].low;
        double sizeBody = MathAbs(open - close);
        double sizeBar = (high - low);

        return (int)MathFloor(sizeBody * 100.0 / sizeBar);
    }
    
    double GetHigh(int idx) {
        idx = m_size - (idx+1);
        return m_rates[idx].high;
    }

    double GetLow(int idx) {
        idx = m_size - (idx+1);
        return m_rates[idx].low;
    }
    
    double GetClose(int idx) {
        idx = m_size - (idx+1);
        return m_rates[idx].close;
    }

    double GetOpen(int idx) {
        idx = m_size - (idx+1);
        return m_rates[idx].open;
    }
    
    
private:
    double High(int idx) {
        double high = m_rates[idx].high;
        if(m_userBody) {
            high = MathMax(m_rates[idx].open, m_rates[idx].close);
        }
        return high;
    }
    double Low(int idx) {
        double low  = m_rates[idx].low;
        if(m_userBody) {
            low  = MathMin(m_rates[idx].open, m_rates[idx].close);
        }
        return low;
    }
};

