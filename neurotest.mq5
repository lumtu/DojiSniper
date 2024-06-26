#property copyright "Copyright 2024, Udo Köller"
#property link      "https://www.luntu.de"

#include "neuronetz.mqh"



class ScriptExecutor
{
    Network* _network;
public:
    ScriptExecutor()
    : _network(NULL)
    { }
    
    bool Init()
    {
        
        int data[][2];
        ArrayResize(data, 4);
        int idx = 0;
        // ArrayResize(data[idx], 2);
        data[idx][0] = 200;
        data[idx][1] = 80;

        ++idx;
        // ArrayResize(data[idx], 2);
        data[idx][0] = 100;
        data[idx][1] = 40;

        ++idx;
        // ArrayResize(data[idx], 2);
        data[idx][0] = 110;
        data[idx][1] = 45;

        ++idx;
        // ArrayResize(data[idx], 2);
        data[idx][0] = 190;
        data[idx][1] = 75;


        double answers[4];
        answers[0] = 1.0;
        answers[1] = 0.0;
        answers[2] = 0.0;
        answers[3] = 1.0;


        int size = ArraySize(data);
        Print("-- ArraySize(data) : " + IntegerToString(size));
        _network = new Network(3,2,1);
        _network.train(data, answers);
        
        return true;
    }
    
    void Processing()
    {
        double h = Util::fRand(30, 300);
        double w = Util::fRand(30, 100);
        
        Print("call compute (", h, ", ", w, ")");
        
        double prediction[5];
        prediction[0]= _network.predict(200, 80);
        prediction[1]= _network.predict(100, 40);
        prediction[2]= _network.predict(110, 45);
        prediction[3]= _network.predict(190, 75);
        prediction[4]= _network.predict(105, 42);
        
        for(int i=0; i<5; ++i) {
            Print("prediction: ", i, " : ", prediction[i]);
        }
            
        Sleep(5000);
    }
    
    void Deinit()
    {
        delete _network;
        _network = NULL;
    }
};


ScriptExecutor ExtScript;

void OnStart(void)
{
    Print("Start Network");
    
    Network* network = new Network(3,2,1);
    double prediction = network.predict(115, 66);
    
    Print("prediction: "+ DoubleToString(prediction));
    
//--- call init function
   if(ExtScript.Init())
     {
      //--- cycle until the script is not halted
      while(!IsStopped())
         ExtScript.Processing();
     }
//--- call deinit function
   ExtScript.Deinit();
    
}


/*
void OnInit()
{
}

void OnTick()
{
}
*/
