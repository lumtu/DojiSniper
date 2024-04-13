#include <Arrays\ArrayObj.mqh>
#include "Neuron.mqh"

class CLayer: public CArrayObj
  {
private:
   uint              iOutputs;
public:
                     CLayer(const int outputs=0) { iOutputs=outputs; }
                    ~CLayer(void){};
   //---
   virtual bool      CreateElement(const uint index);
   virtual int       Type(void) const { return(0x7779); }
};
   
   

bool CLayer::CreateElement(const uint index)
  {
//---
   if(m_data_max<(int)index+1)
     {
      if(ArrayResize(m_data,index+10)<=0)
         return false;
      m_data_max=ArraySize(m_data)-1;
     }
//---
   CNeuron *neuron=new CNeuron(iOutputs,index);
   if(!CheckPointer(neuron)!=POINTER_INVALID)
   { return false; }
   
   neuron.setOutputVal((index%3)-1);  
//---
   m_data[index]=neuron;
   m_data_total=(int)MathMax(m_data_total,index);
//---
   return (true);
  }
  
  
  
class CArrayLayer  :    public CArrayObj
{
public:
    CArrayLayer(void){};
    ~CArrayLayer(void){};
    //---
    virtual bool      CreateElement(const uint neurons, const uint outputs);
    virtual int       Type(void) const { return(0x7780); }
};
   
   
   
bool CArrayLayer::CreateElement(const uint neurons, const uint outputs)
  {
   if(neurons<=0)
      return false;
//---
   if(m_data_max<=m_data_total)
     {
      if(ArrayResize(m_data,m_data_total+10)<=0)
         return false;
      m_data_max=ArraySize(m_data)-1;
     }
//---
   CLayer *layer=new CLayer(outputs);
   if(!CheckPointer(layer)!=POINTER_INVALID)
      return false;
      
   for(uint i=0; i<neurons; i++)
      if(!layer.CreateElement(i))
         return false;
         
//---
   m_data[m_data_total]=layer;
   m_data_total++;
//---
   return (true);
  }