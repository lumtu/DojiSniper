#include <Object.mqh>
#include "Connection.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CNeuron  :  public CObject
  {
public:
                     CNeuron(uint numOutputs,uint myIndex);
                    ~CNeuron() {};
   void              setOutputVal(double val) { outputVal=val; }
   double            getOutputVal() const { return outputVal; }
   void              feedForward(const CArrayObj *&prevLayer);
   void              calcOutputGradients(double targetVals);
   void              calcHiddenGradients(const CArrayObj *&nextLayer);
   void              updateInputWeights(CArrayObj *&prevLayer);
   //--- methods for working with files
   virtual bool      Save(const int file_handle)                         { return(outputWeights.Save(file_handle));   }
   virtual bool      Load(const int file_handle)                         { return(outputWeights.Load(file_handle));   }

private:
   double            eta;
   double            alpha;
   static double     randomWeight() { return(double)MathRand()/32767.0; }
   static double     activationFunction(double x);
   static double     activationFunctionDerivative(double x);
   double            sumDOW(const CArrayObj *&nextLayer) const;
   double            outputVal;
   CArrayCon         outputWeights;
   uint              m_myIndex;
   double            gradient;
  };
  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CNeuron::CNeuron(uint numOutputs, uint myIndex)  :  eta(0.15), // net learning rate
                                                    alpha(0.5) // momentum  
  {
   for(uint c=0; c<numOutputs; c++)
     {
      outputWeights.CreateElement(c);
     }

   m_myIndex=myIndex;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNeuron::updateInputWeights(CArrayObj *&prevLayer)
  {
   int total=prevLayer.Total();
   for(int n=0; n<total && !IsStopped(); n++)
     {
      CNeuron *neuron= prevLayer.At(n);
      CConnection *con=neuron.outputWeights.At(m_myIndex);
      
      con.weight+=con.deltaWeight=(gradient!=0 ? eta*neuron.getOutputVal()*gradient : 0)+(con.deltaWeight!=0 ? alpha*con.deltaWeight : 0);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNeuron::sumDOW(const CArrayObj *&nextLayer) const
  {
   double sum=0.0;
   int total=nextLayer.Total()-1;
   for(int n=0; n<total; n++)
     {
      CConnection *con=outputWeights.At(n);
      double weight=con.weight;
      if(weight!=0)
        {
         CNeuron *neuron=nextLayer.At(n);
         sum+=weight*neuron.gradient;
        }
     }

   return sum;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNeuron::calcHiddenGradients(const CArrayObj *&nextLayer)
  {
   double dow=NormalizeDouble(sumDOW(nextLayer),5);
   gradient=(dow!=0 ? dow*CNeuron::activationFunctionDerivative(outputVal) : 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNeuron::calcOutputGradients(double targetVals)
  {
   double delta=NormalizeDouble(targetVals-outputVal,5);
   gradient=(delta!=0 ? delta*CNeuron::activationFunctionDerivative(outputVal) : 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNeuron::activationFunction(double x)
  {
//output range [-1.0..1.0]
   return tanh(x);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CNeuron::activationFunctionDerivative(double x)
  {
   return 1/MathPow(cosh(x),2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CNeuron::feedForward(const CArrayObj *&prevLayer)
  {
   double sum=0.0;
   int total=prevLayer.Total();
   for(int n=0; n<total && !IsStopped(); n++)
     {
      CNeuron *temp=prevLayer.At(n);
      double val=temp.getOutputVal();
      if(val!=0)
        {
         CConnection *con=temp.outputWeights.At(m_myIndex);
         sum+=val * con.weight;
        }
     }

   outputVal=activationFunction(sum);
  }