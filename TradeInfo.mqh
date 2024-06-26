//+------------------------------------------------------------------+
//|                                                    TradeInfo.mqh |
//|                                       Copyright 2023, Udo Köller |
//|                                              http://www.lumtu.de |
//+------------------------------------------------------------------+


class CTradeInfo {
public:
    string _symbol;
    datetime _begin;
    datetime _end;
    double _open;
    double _close;
    double _tp;
    double _sl;
    MqlRates _ahtf[];
    MqlRates _aetf[];
    ENUM_TIMEFRAMES _inpHTF;
    ENUM_TIMEFRAMES _inpETF;
    
public:
    CTradeInfo(ENUM_TIMEFRAMES inpHTF, ENUM_TIMEFRAMES inpETF) {
        _symbol = _Symbol;
        _inpHTF = inpHTF;
        _inpETF = inpETF;
        
    } 
    
    
    void Begin(datetime val) { _begin=val; InitRates(); }
    void End(datetime val) { _end=val;}
    void Open(double val) {_open=val;}
    void TP(double val) {_tp=val;}
    void SL(double val) {_sl=val;}
    void Close() {
        double ask=0.0, bid=0.0;
        if(SymbolInfoDouble(_symbol,SYMBOL_ASK,ask) && SymbolInfoDouble(_symbol,SYMBOL_BID,bid)) {
            double tp_diff = MathAbs( _tp- (IsLong() ? bid : ask ));
            double sl_diff = MathAbs( _sl- (IsLong() ? ask : bid ));
            double be_diff = MathAbs( _open- (IsLong() ? bid : ask ));
            _close=_sl;
            if(tp_diff < sl_diff) {
                _close = _tp; 
            }
            if(be_diff<tp_diff && be_diff< sl_diff ){
                _close = _open; 
            }
        }
    }
    
    bool IsLong()const {return _tp>_sl;}
    

    void InitRates() {
        int barCount = GetBarCount(_inpHTF);
        CopyRates(_symbol, _inpHTF, _begin, barCount, _ahtf);
        
        barCount = GetBarCount(_inpETF);
        CopyRates(_symbol, _inpETF, _begin, barCount, _aetf);
    }
    
    int GetBarCount(ENUM_TIMEFRAMES timeFrame) {
    
        if(timeFrame >= PERIOD_H4) {
            return 20;
            
        } else if(timeFrame >= PERIOD_H1) {
            return 30;

        } else if(timeFrame >= PERIOD_M15) {
            return 40;
        }
    
        return 100;
    }
    
    void Save() {

        string res = "{"; 
        res += ToKey_StrVal("symbol", _symbol) +", ";  
        res += ToKey_NumVal("begin", (long )_begin) +", ";
        res += ToKey_NumVal("end",  (long)_end ) +", ";
        res += ToKey_NumVal("open", _open) +", ";
        res += ToKey_NumVal("close", _close) +", ";
        res += ToKey_NumVal("tp", _tp) +", ";
        res += ToKey_NumVal("sl", _sl) +", ";
        res += ToKey_MqlRate("htf", _ahtf) +", "; 
        res += ToKey_MqlRate("etf", _aetf);
        res += "}";   
       
        MqlDateTime dt;
        TimeToStruct(_begin, dt);
       
        string tpOrSl = GetResultKey();
       
        ResetLastError(); 
        string filename = StringFormat("Trade_%s %s %d-%02d-%02d %02d%02d%02d.json", 
            _symbol,
            tpOrSl,
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
    
    
    string GetResultKey() const {
    
        double diff_be = MathAbs(_close - _open);
    
        // is a loss
        double diff_tp = _close - _tp;
        double diff_sl = _sl - _close;
        if(IsLong()) {
            diff_tp = _tp - _close;
            diff_sl = _close - _sl;
        }
        
        if(diff_be < diff_tp && diff_be < diff_sl) {
            return "be";
        }
        
        return (diff_tp < diff_sl ) ? "tp" : "sl";
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
