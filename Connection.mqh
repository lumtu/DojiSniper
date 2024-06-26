#include <Arrays\ArrayObj.mqh>

class CConnection : public CObject
  {
public:
   double            weight;
   double            deltaWeight;
                     CConnection(double w) { weight=w; deltaWeight=0; }
                    ~CConnection(){};
   //--- methods for working with files
   virtual bool      Save(const int file_handle);
   virtual bool      Load(const int file_handle);
  };
  
  
  
 bool CConnection::Save(const int file_handle)
  {
   if(file_handle==INVALID_HANDLE)
      return false;
//---
   if(FileWriteDouble(file_handle,weight)<=0)
      return false;
   if(FileWriteDouble(file_handle,deltaWeight)<=0)
      return false;
//---
   return true;
  }
  
  
  
class CArrayCon  :    public CArrayObj
  {
public:
                     CArrayCon(void){};
                    ~CArrayCon(void){};
   //---
   virtual bool      CreateElement(const int index);
   virtual int       Type(void) const { return(0x7781); }
   };
   
   
bool CArrayCon::CreateElement(const int index)
  {
   if(index<0)
      return false;
//---
   if(m_data_max<index+1)
     {
      if(ArrayResize(m_data,index+10)<=0)
         return false;
      m_data_max=ArraySize(m_data)-1;
     }
//---
   m_data[index]=new CConnection(MathRand()/32767.0);
   if(!CheckPointer(m_data[index])!=POINTER_INVALID)
      return false;
      
   m_data_total=MathMax(m_data_total,index);
//---
   return (true);
  }     