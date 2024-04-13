//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


class InputNeuron {

public:
    InputNeuron()
        : _input(0)
    {  }

    ~InputNeuron()
    {}

    InputNeuron(InputNeuron& cpy) 
    {
        this=cpy;
    }

    InputNeuron*     operator = (InputNeuron& cpy) 
    {
        if(&this == &cpy)
            return &this;

        _input = cpy._input;
        return &this;
    }

    // Auto-Impl Properties for trivial get and set
    double           Input() 
    {
        return _input;
    }
    
    void             Input(double val) 
    {
        _input = val;
    }

private:
    double           _input;
};


class Synapse {
public:
    Synapse(InputNeuron& from)
        : _weight(0.0)
        , _from(&from)
    {  }

    ~Synapse()
    {}


    InputNeuron*     From() {
        return &_from;
    }

    double           Weight() {
        return _weight;
    }
    void             Weight(double val) {
        _weight = val;
    }

private:
    InputNeuron      _from;
    double           _weight;
};



class OutputNeuron {
public:
    OutputNeuron()
        : _threshold(0.5)
    {  }

    ~OutputNeuron()
    { }

public:
    bool GetOutput() 
    {
        double net = 0.0;
        int count = ArraySize(_synapses);
        for (int i = 0; i < count; i++) {
            net = net + _synapses[i].Weight() * _synapses[i].From().Input();
        }

        // Fire, if we got over the threshold
        return (net > _threshold);
    }

    void AddSynapse(Synapse* s) 
    {
        int count = ArraySize(_synapses);
        ArrayResize(_synapses, count+1);
        _synapses[count] = s;
    }

    Synapse* GetSynapse(int i) 
    {
        return _synapses[i];
    }

    int GetSynapseSize() 
    {
        return ArraySize(_synapses);
    }

private:
    Synapse* _synapses[];

    double _threshold;
};








//---------------------------

class Util {

public:
    static double    sigmoid(double in) {
        return 1 / (1 + MathExp(-in));
    }

    static double meanSquareLoss(double& correctAnswers[], double& predictedAnswers[])
    {
        int size = ArraySize(correctAnswers);
        double sumSquare = 0;
        for (int i = 0; i < size; i++) {
            double error = correctAnswers[i] - predictedAnswers[i];
            sumSquare += (error * error);
        }
        return sumSquare / size;
    }

    static double fRand(double fMin, double fMax) {
        MathSrand(GetTickCount());

        int n = nRand((int)fMin, (int)fMax);

        int RAND_MAX= 2147483647;
        double f = (double)rand() / RAND_MAX;
        return n + f * (fMax - fMin);
    }

    static int       nRand(int min, int max) {
        return min + (int)MathMod(rand(), (max+1 - min));
    }
};


class Neuron {
public:
    Neuron () {
        Init();
    }

public:
    double compute(double input1, double input2) {
        // Print("compute (", input1, ", ", input2, ")");
        // Print("weight1 (", _weight1, "), weight2 (", _weight2, "), _bias (", _bias, ")" );
        double preActivation = (this._weight1 * input1) + (this._weight2 * input2) + this._bias;

        // Print("preActivation (", preActivation, ")");
        double output = Util::sigmoid(preActivation);
        return output;
    }


    void mutate() {

        int propertyToChange = Util::nRand(0, 3);
        double changeFactor = Util::fRand(-1, 1);

        if (propertyToChange == 0) {
            this._bias += changeFactor;

        } else if (propertyToChange == 1) {
            this._weight1 += changeFactor;

        } else {
            this._weight2 += changeFactor;
        }
    }

    void             forget() {
        _bias = _oldBias;
        _weight1 = _oldWeight1;
        _weight2 = _oldWeight2;
    }

    void             remember() {
        _oldBias = _bias;
        _oldWeight1 = _weight1;
        _oldWeight2 = _weight2;
    }

    void             Weight1(double val) {
        _weight1 = val;
    }
    double           Weight1() {
        return _weight1;
    }

private:
    void             Init() {
        _bias = Util::fRand(-1, 1);
        _weight1 = Util::fRand(-1, 1);
        _weight2 = Util::fRand(-1, 1);

        _oldBias = Util::fRand(-1, 1);
        _oldWeight1 = Util::fRand(-1, 1);
        _oldWeight2 = Util::fRand(-1, 1);
    }

private:
    double           _bias;
    double           _weight2;
    double           _weight1;

    double           _oldBias;
    double           _oldWeight1;
    double           _oldWeight2;

};


class Network {

public:
    Network(int sizeLayer1, int sizeLayer2, int sizeLayer3) 
    {
        Print("ctor Network");
        init(sizeLayer1, sizeLayer2, sizeLayer3);
    }

    ~Network() 
    {
        int count = ArraySize(_neurons);
        for(int i=0; i<count; ++i)
            delete _neurons[i];
    }

    void train(int& data[][], double& answers[]) 
    {

        Print("train Network");

        int size = ArraySize(data) / 2;
        Print("ArraySize(data) : " + IntegerToString(size));

        double bestEpochLoss = NULL;

        for (int epoch = 0; epoch < 10000; epoch++) {
            
            // adapt neuron
            
            for(int j=0; j<6; ++j)
            {
                Neuron* epochNeuron = _neurons[ j ];
                epochNeuron.mutate();
    
                double predictions[];
                ArrayResize(predictions, size);
    
                for (int i = 0; i < size; i++) {
                    predictions[i] = this.predict(data[i][0], data[i][1]);
                }
    
                double thisEpochLoss = Util::meanSquareLoss(answers, predictions);
    
                Print("train (thisEpochLoss) : ", thisEpochLoss, " : predictions:", bestEpochLoss);
                if (bestEpochLoss == NULL) {
    
                    bestEpochLoss = thisEpochLoss;
                    epochNeuron.remember();
                    Print("remember (thisEpochLoss) : ", thisEpochLoss);
    
                } else {
    
                    if (thisEpochLoss < bestEpochLoss) {
                        bestEpochLoss = thisEpochLoss;
                        epochNeuron.remember();
                        Print("remember (thisEpochLoss) : ", thisEpochLoss);
    
                    } else {
                        epochNeuron.forget();
                        // Print("forget (thisEpochLoss) : ", thisEpochLoss);
                    }
                }
            }
        }
    }

private:
    void init(int sizeLayer1, int sizeLayer2, int sizeLayer3) 
    {
        ArrayResize(_neurons, 6);

        /* input nodes */
        _neurons[0] = new Neuron();
        _neurons[1] = new Neuron();
        _neurons[2] = new Neuron();

        /* hidden nodes */
        _neurons[3] = new Neuron();
        _neurons[4] = new Neuron();

        /* output node */
        _neurons[5] = new Neuron();
    }

public:
    double predict(double input1, double input2) 
    {
        return _neurons[5].compute(
                   _neurons[4].compute(
                       _neurons[2].compute(input1, input2),
                       _neurons[1].compute(input1, input2)

                   ), _neurons[3].compute(
                       _neurons[1].compute(input1, input2),
                       _neurons[0].compute(input1, input2)
                   )
               );
    }

private:
    Neuron* _neurons[];
};
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
   static double     activationFunction(double x);
   static double     activationFunctionDerivative(double x);
   double            sumDOW(const CArrayObj *&nextLayer) const;
   double            outputVal;
   CArrayCon         outputWeights;
   uint              m_myIndex;
   double            gradient;
 };
  
  