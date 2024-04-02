//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#include <Generic/ArrayList.mqh>

class CStopWatch
{
    string _title;
    uint _ticksStart;
    uint _ticksEnd;

public:
    CStopWatch()
    : _title("")
    , _ticksStart(0)
    , _ticksEnd(0)
    { 
    }
    
    ~CStopWatch()
    {
    }

    void Start(string title) {
        _title = title;

        StringTrimLeft(_title);
        StringTrimRight(_title);
        if(StringLen(_title)<=0) {
            _title = "iAlgo";
        }

        _ticksStart = GetTickCount();
        _ticksEnd= 0;
    }
    
    void Stop(uint minticks=20) {
        if(_ticksStart ==0 || _ticksEnd != 0) return;
        
        _ticksEnd=GetTickCount();
        uint diff =  _ticksEnd-_ticksStart; 
        if(diff > minticks) {
            Print(_title, " : duration (ms) ", diff);
        }
    }
};


class CIniFile {

public:
    class CItem {
    public:
        static CItem* Create(string key, string value) {
            return new CItem(key, value);
        }

    private:
        string       _key;
        string       _value;

                     CItem(string key, string value)
            :        _key(key)
            ,        _value(value) {
        }

    public:
                    ~CItem() {
        }

        string       Key() const {
            return _key;
        }

        string       Value() const {
            return _value;
        }

    };


    class CSeg {
       
    public:
        static CSeg* Create(string name) {
            return new CSeg(name);
        }
        
    public:
        string _name;
        CItem* _items[];
        uint _itemCount;
        uint _arraySize;
        
        CSeg(string name)
            : _name(name)
            , _itemCount(0)
            , _arraySize(0)
        {
            ExpandArray();
        }
        
    public:
        ~CSeg() {
            
            for(uint i=0; i<_itemCount; ++i) {
                CItem* item = _items[i];
                delete item;
                _items[i] = NULL;
            }
            ArrayFree(_items);
            _itemCount=0;
            _arraySize=0;
        }

        void ExpandArray() {
            int count=100;
            ArrayResize(_items, _arraySize+count);
            _arraySize += count;
        }
        
        uint ItemCount() {
            return _itemCount;
        }
        
        string Name() {
            return _name;
        }

        bool Contains(string key) {
            const CItem *item = GetItem(key);
            return item != NULL;
        }

        const CItem* GetItem(string key) const {
            for(uint i=0; i<_itemCount; ++i ) {
                CItem* item = _items[i];
                if(StringCompare(item.Key(), key, false) == 0) {
                    return item;
                }
            }
            return NULL;
        }

        bool Get(const string key, double& value) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            value = StringToDouble(item.Value() );
            return true;
        }

        bool Get(const string key, double& values[]) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            string aStr[];
            int n = StringSplit(item.Value(), ';', aStr);
            ArrayResize(values, n);
            
            for(int i=0; i<n; ++i) {
                StringTrimLeft(aStr[i]);
                StringTrimRight(aStr[i]);

                values[i] = StringToDouble( aStr[i] );
            }

            return true;
        }

        bool Get(const string key, long& value) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            value = StringToInteger(item.Value() );
            return true;
        }

        bool         Get(const string key, long& values[]) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            string aStr[];
            int n = StringSplit(item.Value(), ';', aStr);
            ArrayResize(values, n);
            for(int i=0; i<n; ++i) {

                StringTrimLeft(aStr[i]);
                StringTrimRight(aStr[i]);

                int count = ArraySize(values);
                values[i] = StringToInteger( aStr[i] );
            }

            return true;
        }

        bool Get(const string key, string& value) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            value = item.Value();
            StringTrimLeft(value);
            StringTrimRight(value);

            return true;
        }

        bool Get(const string key, string& values[]) const {
            const CItem* item = GetItem(key);
            if(item == NULL)
                return false;

            string aStr[];
            int n = StringSplit(item.Value(), ';', aStr);
            ArrayResize(values, n);
            for(int i=0; i<n; ++i) {

                StringTrimLeft(aStr[i]);
                StringTrimRight(aStr[i]);

                values[i] = aStr[i];
            }

            return true;
        }



        void Add(const string key, const double value) {
            Add(key, DoubleToString(value));
        }

        void Add(const string key, const double& values[]) {
            int n = ArraySize(values);
            string val = "";
            for(int i=0; i<n; ++i) {
                if(i>0) {
                    val += ";";
                }
                val += DoubleToString(values[i]);
            }
            Add(key, val);
        }

        void Add(const string key, const long value) {
            Add(key, IntegerToString(value));
        }

        void Add(const string key, const long& values[]) {
            int n = ArraySize(values);
            string val = "";
            for(int i=0; i<n; ++i) {
                if(i>0) {
                    val += ";";
                }
                val += IntegerToString(values[i]);
            }
            Add(key, val);
        }

        void Add(const string key, const string& values[]) {
            int n = ArraySize(values);
            string val = "";
            for(int i=0; i<n; ++i) {
                if(i>0) {
                    val += ";";
                }

                string value = values[i];
                StringTrimLeft(value);
                StringTrimRight(value);

                val += value;
            }
            Add(key, val);
        }

        void Add(const string _key, const string _value) {
            string key = _key;
            string val = _value;

            StringTrimLeft(key);
            StringTrimRight(key);

            StringTrimLeft(val);
            StringTrimRight(val);

            CItem *item = CItem::Create(key, val);
            Add(item); 
        }

        void Add(CItem* item) {
            if(_itemCount==_arraySize-1) {
                ExpandArray();
            }
            _items[_itemCount]=item;
            _itemCount++;
        }

        string GetAsString(string key) {
            return "";
        }
        /*
        string ToString() {
            string str = "";
            
            if(_itemCount>0) {
                str += StringFormat("[%s]|", Name());

                for(uint i=0; i<_itemCount; ++i) {
                    str += StringFormat("%-6s = %s |", _items[i].Key(), _items[i].Value() );
                }
            }
            return str;
        }
        */
    };


public:

    CArrayList<CSeg*> _segments;

public:
    CIniFile() {
    }

    ~CIniFile() {
        int n = _segments.Count();
        for(int i=0; i<n; ++i) {
            CSeg* seg;
            if(_segments.TryGetValue(i, seg)) {
                delete seg;
            }
        }
        _segments.Clear();
    }

    void Add(const string segName, const string key, const double value) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, value);
        }
    }

    void Add(const string segName, const string key, const double& values[]) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, values);
        }
    }

    void Add(const string segName, const string key, const long value) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, value);
        }
    }

    void Add(const string segName, const string key, const long& values[]) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, values);
        }
    }

    void Add(const string segName, const string key, const string& values[]) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, values);
        }
    }

    void Add(const string segName, const string key, const string value) {
        CSeg* seg = GetOrCreate(segName);
        if(false == seg.Contains(key)) {
            seg.Add(key, value);
        }
    }

    CSeg* GetOrCreate(string segName) {
        CSeg *seg = GetSeg(segName);
        if(seg == NULL) {
            seg = CSeg::Create(segName);
            Add(seg);
        }
        return seg;
    }

    void Add(CSeg* seg) {
        _segments.Add(seg);
    }


    CSeg* GetSeg(string name) {
        int n = SegCount();
        for(int i=0; i<n; ++i) {
            CSeg* seg;
            if(_segments.TryGetValue(i, seg) ) {
                if( StringCompare(seg.Name(), name, false ) == 0 ) {
                    return seg;
                }
            }
        }
        return NULL;
    }


    int SegCount() {
        return _segments.Count();
    }

    void SaveToFile(string filename) {
        int filehandle=FileOpen( filename, FILE_WRITE|FILE_ANSI|FILE_TXT);
        if(filehandle!=INVALID_HANDLE) {
            CStopWatch sw;
            sw.Start("Ini FileWriteString()");

            int n = _segments.Count();
            for(int i=0; i<n; ++i) {
                CSeg* seg;
                if(_segments.TryGetValue(i, seg) )  {
                    uint iCount = seg.ItemCount();
                    for(uint j=0; j<iCount; ++j) {
                        
                        if(j==0) {
                            FileWriteString(filehandle, "["+ seg.Name() + "]\r\n");
                        }
                                        
                        // str += StringFormat("%-6s = %s |", _items[i].Key(), _items[i].Value() );

                        FileWriteString(filehandle, seg._items[j].Key() + "=" + seg._items[j].Value() +  "\r\n");
                    }
                }
            }
            
            // sw.Stop(0);

            sw.Start("Ini FileFlush()");
            FileFlush(filehandle);
            // sw.Stop(0);

            FileClose(filehandle);

        } else {
            int ErrNum=GetLastError();
            printf("Error opening file %s # %i",filename,ErrNum);
        }
    }

    void ReadFromFile(string filename) {

        string content = ReadAllFromFile(filename);

        string lines[];
        int k=StringSplit(content, '\n', lines);

        string segname = "";
        for(int i=0; i<k; ++i) {

            string line = lines[i];
            if(line.Length() == 0 )
                continue;


            if(line[0] == '[') {
                segname = StringSubstr(line, 1, line.Length()-2);
            } else {

                string key_val[];
                if(StringSplit(line, '=', key_val) == 2) {
                    Add(segname, key_val[0], key_val[1]);
                }
            }
        }
    }
private:
    string ReadAllFromFile(string filename) {
        string content = "";
        int file_handle=FileOpen( filename, FILE_READ|FILE_ANSI|FILE_TXT);
        if(file_handle!=INVALID_HANDLE) {
            int str_size=0;

            //--- lesen Sie die Dateidaten
            while(!FileIsEnding(file_handle)) {
                str_size=FileReadInteger(file_handle,INT_VALUE);
                //--- lesen Sie die Zeile
                content += FileReadString(file_handle,str_size);
                content += "\n";
            }

            FileClose(file_handle);

        } else {
            int ErrNum=GetLastError();
            printf("Error opening file %s # %i",filename,ErrNum);
        }
        return content;
    }

public:

};

//+------------------------------------------------------------------+
