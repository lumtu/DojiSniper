
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
const double percentChange(double startPoint, double currentPoint) {
    double sp =  MathAbs(startPoint);
    if(sp > 0.0) {

        double x = ((currentPoint)-startPoint) / (startPoint) * 100.00;
        if (x == 0.0) {
            return 0.000000001;
        } else {
            return x;
        }
    }
    return 0.0001;
}

double ToPrice(const double percent, const double price) {
        return price+(price*(percent/100.0));
}




class CActiveInfo {
    long _index;
    double _price;
    
public:
    CActiveInfo()
    : _index(-1)
    , _price(0.0) {
    }
    
    ~CActiveInfo() {
    }
    
    CActiveInfo* operator = (const CActiveInfo& obj) {
        
        _index = obj._index;
        _price = obj._price;
        
        return &this;
    }
    
    long Index() const {
        return _index;
    }
    
    double Price() const {
        return _price;
    }
    
    bool IsActive() const {
        return (_index >0 && _price > 0.0 );
    }
    
    void Activate(long index, double price) {
        _index = index;
        _price = price;
    }
    
    void Stop() {
        _index = -1;
        _price = 0.0;
    }
};

enum PatternState {
    Unset =0,
    Pending = 1,
    Improve = 2,
    Finished = 3
};

static ulong sg_PatternID=0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CPattern {
    ulong _id;
public:
    double _PriceAvg[];
    double _rsi[];

    double _longTP;
    double _longSL;
    double _shortTP;
    double _shortSL;
    long _longInTP;
    long _longInSL;
    long _shortInTP;
    long _shortInSL;

    long _matchCount;
    long _successCount;
    PatternState _state;
    
    CActiveInfo _activInfo;
public:
   CPattern()
        : _id(sg_PatternID++)
        , _matchCount(1)
        , _successCount(1)
    , _longTP(0)
    , _longSL(0)
    , _shortTP(0)
    , _shortSL(0)
    , _longInTP(0)
    , _longInSL(0)
    , _shortInTP(0)
    , _shortInSL(0)
    , _state(PatternState::Unset)
    { }

    ulong ID() const { return _id; }

    bool IsUnset(CActiveInfo& activeInfo) {
        activeInfo = _activInfo;
        return _state == PatternState::Unset;
    }

    bool IsPending(CActiveInfo& activeInfo) {
        activeInfo = _activInfo;
        return IsPending();
    }

    bool IsPending() {
        return _state == PatternState::Pending;
    }

    bool IsImproving() {
        return _state == PatternState::Improve;
    }


    bool IsFinished() {
        return _state == PatternState::Finished;
    }
    
    void SetState(PatternState state) {
        _state = state;
    }

    bool IsNotActive() const {
        return !IsActive();
    }
    
    bool IsActive() const {
        return _activInfo.IsActive();
    }
    
    bool IsActive(CActiveInfo& activeInfo)  {
        activeInfo = _activInfo;
        return _activInfo.IsActive();
    }
    
    void Activate(int index, double price) {
        _activInfo.Activate(index, price);
    }

    bool IsLong()const {
        long longHit = _longInTP - _longInSL;
        long shortHit = _shortInTP - _shortInSL;
        if( _longInTP > _longInSL
         && longHit > shortHit ) {
            return true;
        }
        return false;
    }

    bool IsShort() const {
        long longHit = _longInTP - _longInSL;
        long shortHit = _shortInTP - _shortInSL;
        if( _shortInTP > _shortInSL 
         && shortHit > longHit) {
            return true;
        }
        return false;
    }
    
    double LongTP() const { return _longTP; }
    double ShortTP() const { return _shortTP; }
    
    double LongSL() const { return _longSL; }
    double ShortSL() const { return _shortSL; }
    
    double TP() {
        if(IsLong()) {
            if(_longTP == 0.0) {
                return _shortTP * -1.0;
            }
            return _longTP;
            
        } else {
            if(_shortTP == 0.0) {
                return _longTP * -1.0;
            }
            return _shortTP;
        }
        // return IsLong() ? _longTP : _shortTP;
    }

    double SL() {
        if( IsLong() ) {
            if(_longSL == 0.0 ) {
                return _shortSL * -1.0;
            }
            return _longSL;
            
        } else {
            if(_shortSL == 0.0) {
                return _longSL * -1.0;
            }
            return _shortSL;
        }
        // return IsLong() ? _longSL : _shortSL;
    }

    double TP(const double price)const {
        double tp = IsLong() ? _longTP : _shortTP;
        return price+(price*(tp/100.0));
    }
    
    double SL(const double price)const {
        double sl = IsLong() ? _longSL : _shortSL;
        return price+(price*(sl/100.0));
    }
    
    void HitTP(bool wasLong) {
        _activInfo.Stop();
        if(wasLong) {
            _longInTP++;
        } else {
            _shortInTP++;
        }
    }
    
    void HitSL(bool wasLong) {
        _activInfo.Stop();
        if(wasLong) {
            _longInSL++;
        } else {
            _shortInSL++;
        }
    }
    
   
    void Increment() {
        _matchCount++;
    }

    double SuccessRate() const {
        if(IsLong()) {
            return (_longInTP+1.0) / (_longInSL+1.0) * 100.0;
        }
        
        return (_shortInTP+1.0) / (_shortInSL+1.0) * 100.0;
        // return (_successCount+1.0) / (_matchCount+1.0) * 100.0;
    }

    void Success(bool hitTP, bool wasLong) {
        _successCount += (hitTP ? 1:-1);
        if(hitTP) {
            HitTP(wasLong);
        } else {
            HitSL(wasLong);
        }
    }

    long SuccessCount() {
        return _successCount;
    }
    
    long MatchCount() const{return _matchCount;}
    
    long HitCount() const {
        return LongHitCount() + ShortHitCount();
    }
    
    long LongHitCount() const {
        return _longInTP + _longInSL;
    }

    long ShortHitCount() const {
        return _shortInSL + _shortInTP;
    }
    
    void Add(double percentPrice) {
        int n = ArraySize(_PriceAvg);
        ArrayResize(_PriceAvg, n+1);
        _PriceAvg[n] = percentPrice;
    }

    void AddRSI(double percentRsi) {
        int n = ArraySize(_rsi);
        ArrayResize(_rsi, n+1);
        _rsi[n] = percentRsi;
    }

    int Count()const {
        return ArraySize(_PriceAvg);
    }

    double operator[](int idx) const {
        int n = ArraySize(_PriceAvg);
        if(idx>=0 && idx<n) {
            return _PriceAvg[idx];
        }

        return 0.0;
    }

    void SetOutcome(double tp, double sl, bool isLong) {
        _state = PatternState::Pending;
        if(isLong) {
            _longSL = sl;
            _longTP = tp;
        } else {
            _shortSL = sl;
            _shortTP = tp;
        }
    }

    bool Match(const CPattern& pattern2Check, double& matchRate)const {
        return Match(pattern2Check, matchRate, false);
    }
    
    bool Match(const CPattern& pattern2Check, double& matchRate, bool checkDirection)const {
        long thisCount = Count();
        long checkCount = Count();
        if(thisCount != checkCount) {
            return false;
        }
        
        if(checkDirection) {
            if(IsLong() != pattern2Check.IsLong()) {
                return false;
            }
        }
        
        double sim=0.0;
        for(int idx=0; idx<thisCount; ++idx) {
            // sim += 100.00 - MathAbs( percentChange( ToPrice( _PriceAvg[idx], 100.0), ToPrice(pattern2Check._PriceAvg[idx], 100.0) ));
            sim += 100.00 - MathAbs( percentChange( _PriceAvg[idx], pattern2Check._PriceAvg[idx] ));
        }

        double howSim = sim / thisCount;    
        bool isMatching = howSim > matchRate;

        // RSI check        
        bool isRsiMatch = true;
        int rsiCount=ArraySize(_rsi);
        int check_rsi_count = ArraySize(pattern2Check._rsi);
        if(rsiCount>0 ) {
            isRsiMatch = false;
            if(rsiCount == check_rsi_count) {
                double sim_rsi = 0.0;
                for(int r=0; r<rsiCount; ++r ) {
                    sim_rsi += 100.00 - MathAbs(percentChange( _rsi[r], pattern2Check._rsi[r] ) );
                }
                isRsiMatch = sim_rsi / rsiCount;
            } else {
                Print("The rsi count is different");
            }
        }
        
        if(isMatching && isRsiMatch) {
            matchRate = howSim;
        }
        
        return isMatching;
    }
    
    bool Merge(const CPattern& pattern2Check) {
        long thisCount = Count();
        long checkCount = Count();
        if(thisCount != checkCount) {
            return false;
        }

        for(int idx=0; idx<thisCount; ++idx) {
            _PriceAvg[idx] = ((_PriceAvg[idx] + pattern2Check[idx]) / 2.0);
        }
        
        if(IsLong()) {
            _longTP = (_longTP + pattern2Check._longTP) / 2.0;
            _longSL = (_longSL + pattern2Check._longSL) / 2.0;
        } else {
            _shortTP = (_shortTP + pattern2Check._shortTP) / 2.0;
            _shortSL = (_shortSL + pattern2Check._shortSL) / 2.0;
        }
        
        return true;
    }
    
    string ToString() 
    {
        string result = StringFormat("%d; %d; %d; %f; %f", 
            (int)IsLong(), _matchCount, _successCount, TP(), SL()) ;
        
        int n = ArraySize(_PriceAvg);
        result += StringFormat(";%d", n);
        
        for(int i=0; i<n; ++i) {
            result += StringFormat(";%f", _PriceAvg[i]);
        }
        
        return result;
    }
};






void RunPatternTest() {


    CPattern p;
    CPattern p2;
    
    double start = 100.00;

    double prices[20] ;

    for(int i=0; i<20; ++i) {
        prices[i] = MathRandDbl(50.00, 150.0);
        
        p.Add( percentChange(100.0, prices[i]) );
        p2.Add( percentChange(100.0, (prices[i] * 0.65 ) ) );
    }

    double matchRate = 70.0;
    bool isaMatch = p.Match(p2, matchRate);
    
    PrintFormat("MatchRateTest [%d] : %f", (int)isaMatch , matchRate);

}

double MathRandDbl(const double min, const double max)
{
   double f   = (MathRand() / 32768.0);
   return min + (int)(f * (max - min));
}
