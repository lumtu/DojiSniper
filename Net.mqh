#include <Arrays\ArrayInt.mqh>
#include <Arrays\ArrayDouble.mqh>


#include "Neuron.mqh"
#include "Layer.mqh"


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNet
  {
public:
                     CNet(const CArrayInt *topology);
                    ~CNet(){};
   void              feedForward(const CArrayDouble *inputVals);
   void              backProp(const CArrayDouble *targetVals);
   void              getResults(CArrayDouble *&resultVals) const;
   double            getRecentAverageError() const { return recentAverageError; }
   bool              Save(const string file_name, double error, double undefine, double forecast, datetime time, bool common=true);
   bool              Load(const string file_name, double &error, double &undefine, double &forecast, datetime &time, bool common=true);
//---
   static double     recentAverageSmoothingFactor;
private:
   CArrayLayer       layers;
   double            recentAverageError;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNet::recentAverageSmoothingFactor=100.0; // Number of training samples to average over
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CNet::CNet(const CArrayInt *topology)
  {
   if(CheckPointer(topology)==POINTER_INVALID)
      return;
//---
   int numLayers=topology.Total();
   for(int layerNum=0; layerNum<numLayers; layerNum++) 
     {
      uint numOutputs=(layerNum==numLayers-1 ? 0 : topology.At(layerNum+1));
      if(!layers.CreateElement(topology.At(layerNum), numOutputs))
         return;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNet::getResults(CArrayDouble *&resultVals) const
  {
   if(CheckPointer(resultVals)==POINTER_INVALID)
      resultVals=new CArrayDouble();
//---
   resultVals.Clear();
   CArrayObj *Layer=layers.At(layers.Total()-1);
   if(CheckPointer(Layer)==POINTER_INVALID)
     {
      return;
     }
   int total=Layer.Total()-1;
   for(int n=0; n<total; n++)
     {
      CNeuron *neuron=Layer.At(n);
      resultVals.Add(neuron.getOutputVal());
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNet::backProp(const CArrayDouble *targetVals)
  {
   if(CheckPointer(targetVals)==POINTER_INVALID)
      return;
      
   CArrayObj *outputLayer=layers.At(layers.Total()-1);
   if(CheckPointer(outputLayer)==POINTER_INVALID)
      return;
//---
   double error=0.0;
   int total=outputLayer.Total()-1;
   for(int n=0; n<total && !IsStopped(); n++)
     {
      CNeuron *neuron=outputLayer.At(n);
      double delta=targetVals[n]-neuron.getOutputVal();
      error+=delta*delta;
     }
   error/= total;
   error = sqrt(error);

   recentAverageError+=(error-recentAverageError)/recentAverageSmoothingFactor;
//---
   for(int n=0; n<total && !IsStopped(); n++)
     {
      CNeuron *neuron=outputLayer.At(n);
      neuron.calcOutputGradients(targetVals.At(n));
     }
//---
   for(int layerNum=layers.Total()-2; layerNum>0; layerNum--)
     {
      const CArrayObj *hiddenLayer=layers.At(layerNum);
      const CArrayObj *nextLayer=layers.At(layerNum+1);
      total=hiddenLayer.Total();
      for(int n=0; n<total && !IsStopped();++n)
        {
         CNeuron *neuron=hiddenLayer.At(n);
         neuron.calcHiddenGradients(nextLayer);
        }
     }
//---
   for(int layerNum=layers.Total()-1; layerNum>0; layerNum--)
     {
      CArrayObj *layer=layers.At(layerNum);
      CArrayObj *prevLayer=layers.At(layerNum-1);
      total=layer.Total()-1;
      for(int n=0; n<total && !IsStopped(); n++)
        {
         CNeuron *neuron=layer.At(n);
         neuron.updateInputWeights(prevLayer);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNet::feedForward(const CArrayDouble *inputVals)
  {
   if(CheckPointer(inputVals)==POINTER_INVALID)
      return;
//---
 CLayer *Layer=layers.At(0);
   if(CheckPointer(Layer)==POINTER_INVALID)
     {
      return;
     }
   int total=inputVals.Total();
   if(total!=Layer.Total()-1)
      return;
//---
   for(int i=0; i<total && !IsStopped(); i++) 
     {
      CNeuron *neuron=Layer.At(i);
      neuron.setOutputVal(inputVals.At(i));
     }
//---
   total=layers.Total();
   for(int layerNum=1; layerNum<total && !IsStopped(); layerNum++) 
     {
      const CArrayObj *prevLayer = layers.At(layerNum - 1);
      const CArrayObj *currLayer = layers.At(layerNum);
      int t=currLayer.Total()-1;
      for(int n=0; n<t && !IsStopped(); n++) 
        {
         CNeuron *neuron=currLayer.At(n);
         neuron.feedForward(prevLayer);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNet::Save(const string file_name, double loop_err, double undefine_p, double forecast_er,datetime time, bool common=true)
  {
   if(MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_FORWARD) || MQLInfoInteger(MQL_OPTIMIZATION))
      return true;
   if(file_name==NULL)
      return false;
//---
   int handle=FileOpen(file_name,(common ? FILE_COMMON : 0)|FILE_BIN|FILE_WRITE);
   if(handle==INVALID_HANDLE)
      return false;
//---
   if(FileWriteDouble(handle,loop_err)<=0 || FileWriteDouble(handle,undefine_p)<=0 || FileWriteDouble(handle,forecast_er)<=0 || FileWriteLong(handle,(long)time)<=0)
     {
      FileClose(handle);
      return false;
     }
   bool result=layers.Save(handle);
   FileFlush(handle);
   FileClose(handle);
//---
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CNet::Load(const string file_name, double &loop_err, double &undefine_p, double &forecast_er, datetime &time, bool common=true)
  {
   if(MQLInfoInteger(MQL_OPTIMIZATION) || MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_FORWARD) || MQLInfoInteger(MQL_OPTIMIZATION))
      return false;
//---
   if(file_name==NULL)
      return false;
//---
   int handle=FileOpen(file_name,(common ? FILE_COMMON : 0)|FILE_BIN|FILE_READ);
   if(handle==INVALID_HANDLE)
      return false;
//---
   loop_err=FileReadDouble(handle);
   undefine_p=FileReadDouble(handle);
   forecast_er=FileReadDouble(handle);
   time=(datetime)FileReadLong(handle);
//---
   layers.Clear();
   int i=0,num;
//--- check
//--- read and check start marker - 0xFFFFFFFFFFFFFFFF
   if(FileReadLong(handle)==-1)
     {
      //--- read and check array type
      if(FileReadInteger(handle,INT_VALUE)!=layers.Type())
         return(false);
     }
//--- read array length
   num=FileReadInteger(handle,INT_VALUE);
//--- read array
   if(num!=0)
     {
      for(i=0;i<num;i++)
        {
         //--- create new element
         CLayer *Layer=new CLayer();
         if(!Layer.Load(handle))
            break;
         if(!layers.Add(Layer))
            break;
        }
     }
   FileClose(handle);
//--- result
   return(layers.Total()==num);
  }
//+------------------------------------------------------------------+    