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
        return CopyRates(m_symbol, m_period, 1, m_size, m_rates) == m_size;
    }
    
    double Atr() {
        double range = 0.0;
        
        for(int i=0; i<m_size-1; ++i) {
            double high = High(i);
            double low  = Low(i);
            range += high - low;
        }
        
        range = range / (double)(m_size-1);
        
        double lastRange = High(m_size-1) - Low(m_size-1);
      
        double atr = (lastRange * 100.0 / range) / 100.0;
        
        return atr;
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
        int idx = m_size-1;
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

