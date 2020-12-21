//+------------------------------------------------------------------+
//|                                                  NerveMatrix.mq5 |
//|                                                254loop@gmail.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include <Math\Stat\Math.mqh>

//+------------------------------------------------------------------+
//|              store possible activation functions                 |
//+------------------------------------------------------------------+
enum Activations {
    Tanh,
    Relu,
    Sigmoid
};
//+------------------------------------------------------------------+
//|   Main _nerve_ object. Derived from CObject                        |
//+------------------------------------------------------------------+
class CNerveMatrix : public CObject {
private:
    //--- activation functions
    double           tanH(const double x) const;
    double           reLu(const double x) const;
    double           sigmoid(const double x) const;
    //--- activation derivatives
    double           tanhDerivative(const double x) const;
    double           reLuDerivative(const double x) const;
    double           sigmoidDerivative(const double x) const;
    //---
private:
    double           m_error;
    bool             m_activated;
    double           m_recent_average_error;
    //--- data arrays
    double           m_errors[];
    double           m_gradients[];
    double           m_node_vals[];
    double           m_delta_weights[];
    double           m_weights[];
    double           m_eta, m_alpha;
    Activations      m_activation[2];
    int              m_configuration[];
    double           m_smoothing_factor;
//---
private:
    //--- private methods
    double           activate(const int layer, const double x);
    double           derive(const int layer, const double x);

public:
    //--- constructor and destructor
    CNerveMatrix(void);
    ~CNerveMatrix(void);
    //--- initializing the network
    bool             initialize(const int &configuration[], const Activations &function_layout[]);
    void             setParameters(double eta = 0.15, double alpha = 0.5, double smoothing_factor = 100.0);
    //--- class methods
    void             feedForward(const double &inputVals[]);
    void             backPropagate(const double &targetVals[]);
    virtual void     getResults(double &resultVals[], bool probabilities = false) const;
    virtual void     getErrorBuffer(double &ave_err[]) const;
    //--- working with sessions
    virtual string   Save(void)const;
    virtual bool     Load(const string &to_parse);
};

//+------------------------------------------------------------------+
//|           Network constructor                                    |
//+------------------------------------------------------------------+
CNerveMatrix::CNerveMatrix(void) {
//--- allocate memory for hist. storage
    ArrayResize(m_errors, 0, 10000);
//--- initialize class variables
    m_recent_average_error = 0.0;
    m_activated = false;
//--- set initial network parameters
    setParameters();
}

//+------------------------------------------------------------------+
//|           Network destructor                                     |
//+------------------------------------------------------------------+
CNerveMatrix::~CNerveMatrix(void) {
//--- free
    ArrayFree(m_errors);
    ArrayFree(m_weights);
    ArrayFree(m_gradients);
    ArrayFree(m_node_vals);
    ArrayFree(m_configuration);
    ArrayFree(m_delta_weights);
}
//+------------------------------------------------------------------+
//|  Init the network creating neurons and weights                   |
//+------------------------------------------------------------------+
bool CNerveMatrix::initialize(const int &configuration[], const Activations &function_layout[]) {
//--- check params
    int conf = ArraySize(configuration);
    int activations = ArraySize(function_layout);
//--- set activation functions
    if (activations != 2) {
        m_activation[0] = Tanh;
        m_activation[1] = Tanh;
    } else {
        m_activation[0] = function_layout[0];
        m_activation[1] = function_layout[1];
    }
//---
    if (conf <= 0)
        return false;
//--- copy configuration to internal container
    if (ArrayCopy(m_configuration, configuration) <= 0)
        return false;
//--- counter variables
    int neurons = 0;
    int weights = 0;
//--- count network elements
    for (int i = 0; i < conf; i++) {
        neurons += (i + 1 < conf) ? configuration[i] + 1 : configuration[i];
        weights += (i + 1 < conf) ? (configuration[i] * configuration[i + 1]) + configuration[i + 1] : 0;
    }
//--- resize data arrays
    ArrayResize(m_node_vals, neurons);
    ArrayResize(m_weights, weights);
//---
    ArrayResize(m_delta_weights, weights);
    ArrayResize(m_gradients, neurons);
//--- set initialize arrays
    ArrayInitialize(m_node_vals, 1.0);
    ArrayInitialize(m_gradients, 0.0);
//--- set randomn weights
    for (int i = 0; i < weights; i++) {
        m_weights[i] = MathRandomNonZero();
        m_delta_weights[i] = 0.0;
    }
//--- return result of operation
    m_activated = true;
    return m_activated;
}

//+------------------------------------------------------------------+
//|  Set learning parameters                                         |
//+------------------------------------------------------------------+
void CNerveMatrix::setParameters(double eta, double alpha, double smoothing_factor) {
    m_eta = eta;                           // learning rate
    m_alpha = alpha;                       // learning momentum
    m_smoothing_factor = smoothing_factor; // averaging period
}

//+------------------------------------------------------------------+
//|  Propagate forward                                               |
//+------------------------------------------------------------------+
void CNerveMatrix::feedForward(const double &inputVals[]) {
//---
    if (!m_activated)
        return;
//--- check parameters
    if (ArraySize(inputVals) != m_configuration[0])
        return;
//--- set input nodes
    for (int i = 0; i < m_configuration[0]; i++)
        m_node_vals[i] = inputVals[i];
//--- element sums
    int neurons = ArraySize(m_node_vals);
    int layers = ArraySize(m_configuration);
    int weights = ArraySize(m_delta_weights);
//--- propagate
    int start_index = 0;
    int weight_index = 0;
    for (int i = 1; i < layers && !IsStopped(); i++) {
        //--- loop layer nodes
        int layer_nodes = (i + 1 < layers) ? m_configuration[i] + 1 : m_configuration[i];
        int last_layer_nodes = m_configuration[i - 1] + 1;
        //--- mark layer start_point
        start_index += last_layer_nodes;
        //---
        int nodes_to_account = (i + 1 < layers) ? (start_index + layer_nodes) - 1 : (start_index + layer_nodes);
        for (int j = start_index; j < nodes_to_account && !IsStopped(); j++) {
            m_node_vals[j] = 0.0;
            double weighted_sum = 0.0;
            //--- loop last layer collecting weighted sums
            for (int k = start_index - last_layer_nodes; k < start_index && !IsStopped(); k++) {
                //--- process weight adjustments
                m_delta_weights[weight_index] = m_eta * m_node_vals[k] * m_gradients[j] +
                                                m_alpha * m_delta_weights[weight_index];
                m_weights[weight_index] += m_delta_weights[weight_index];
                //--- sum weighted vals
                weighted_sum += m_node_vals[k] * m_weights[weight_index];
                ++weight_index;
            }
            //--- activate value after loop
            m_node_vals[j] = activate(i, weighted_sum);
        }
    }
//--- end
    return;
}

//+------------------------------------------------------------------+
//|  Propagate backwards                                             |
//+------------------------------------------------------------------+
void CNerveMatrix::backPropagate(const double &targetVals[]) {
    if (!m_activated)
        return;
//--- check parameters
    if (ArraySize(targetVals) != m_configuration[ArraySize(m_configuration) - 1])
        return;
//--- element sums
    int neurons = ArraySize(m_node_vals);
    int layers = ArraySize(m_configuration);
    int weights = ArraySize(m_weights);
//--- compute last layer errors
    for (int i = layers - 1; i > layers - 2 && !IsStopped(); --i) {
        m_error = 0.0;
        int idx = ArraySize(targetVals) - 1;
        //--- compute errors
        for (int n = neurons - 1; n >= neurons - m_configuration[layers - 1]; n--) {
            double delta = targetVals[idx] - m_node_vals[n];
            m_gradients[n] = delta * derive(i, m_node_vals[n]);
            m_error += delta * delta;
            --idx;
        }
        //--- calculate RMS
        m_error /= m_configuration[layers - 1];
        m_error = sqrt(m_error);
        m_recent_average_error = (m_recent_average_error * m_smoothing_factor + m_error) / (m_smoothing_factor + 1.0);
        //--- store in error buffer
        int size = ArraySize(m_errors);
        ArrayResize(m_errors, size + 1);
        m_errors[size] = m_recent_average_error;
    }
//--- positional efficiency
    int start_index, weight_index;
    start_index = neurons - 1;
    weight_index = weights - 1;
//--- loop 2nd last to 2nd layer
    for (int i = layers - 2; i > 0; i--) {
        //--- loop layer nodes
        int layer_nodes = m_configuration[i] + 1;
        int next_layer_nodes = (i + 1 == layers - 1) ? m_configuration[i + 1] : m_configuration[i + 1] + 1;
        //--- backwards start_point
        start_index -= next_layer_nodes;
        //--- loop layer elements
        int nodes_to_account = (start_index - layer_nodes) + 1;
        //--- sum contributions to next layer errors
        double sum[];
        ArrayResize(sum, layer_nodes);
        ArrayInitialize(sum, 0.0);
        //--- loop next layer and sum values in array
        for (int k = start_index + next_layer_nodes; k >= start_index + 1 && !IsStopped(); --k)
            for (int l = 0; l < ArraySize(sum) && !IsStopped() && weight_index >= 0; ++l) {
                sum[l] += m_weights[weight_index] * m_gradients[k];
                --weight_index;
            }
        //--- loop this layer setting gradients
        int data = 0;
        for (int j = start_index; j >= nodes_to_account; --j) {
            m_gradients[j] = sum[data] * derive(i, m_node_vals[j]);
            //---
            ++data;
        }
    }
//---
    return;
}

//+------------------------------------------------------------------+
//|        Select appropriate activation function                    |
//+------------------------------------------------------------------+
double CNerveMatrix::activate(const int layer, const double x) {
    Activations act = (layer < ArraySize(m_configuration) - 1) ? m_activation[0] : m_activation[1];
    switch (act) {
    case Tanh:
        return tanH(x);
    case Relu:
        return sigmoid(x);
    default:
        return sigmoid(x);
    }
}

//+------------------------------------------------------------------+
//|                 Select appropriate derivative                    |
//+------------------------------------------------------------------+
double CNerveMatrix::derive(const int layer, const double x) {
    Activations act = (layer < ArraySize(m_configuration) - 1) ? m_activation[0] : m_activation[1];
    switch (act) {
    case Tanh:
        return tanhDerivative(x);
    case Relu:
        return sigmoid(x);
    default:
        return sigmoidDerivative(x);
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//|                                                                  |
//|                   Activation functions                           |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|            tahn activation function                              |
//+------------------------------------------------------------------+
double CNerveMatrix::tanH(const double x) const {
//--- range(-1.0,1.0)
    return tanh(x);
}

//+------------------------------------------------------------------+
//|             derivative of tanH activation function               |
//+------------------------------------------------------------------+
double CNerveMatrix::tanhDerivative(const double x) const {
    return 1.0 / MathPow(cosh(x), 2);
}

//+------------------------------------------------------------------+
//|           sigmoid activation                                     |
//+------------------------------------------------------------------+
double CNerveMatrix::sigmoid(const double x) const {
    return 1.0 / (1 + exp(-x));
}

//+------------------------------------------------------------------+
//|             sigmoid derivative                                   |
//+------------------------------------------------------------------+
double CNerveMatrix::sigmoidDerivative(const double x) const {
    return x * (1.0 - x);
}

//+------------------------------------------------------------------+
//|             RectiLinear activation                               |
//+------------------------------------------------------------------+
double CNerveMatrix::reLu(const double x) const {
    return fmax(0.0, x);
}

//+------------------------------------------------------------------+
//|             RectiLinear derivative                               |
//+------------------------------------------------------------------+
double CNerveMatrix::reLuDerivative(const double x) const {
    if (x < 0.0)
        return 0.0;
//---
    return 1.0;
}

//+------------------------------------------------------------------+
//|   fetch prediction results from last layer nodes                 |
//+------------------------------------------------------------------+
void CNerveMatrix::getResults(double &resultVals[], bool probabilities) const {
    if (!m_activated)
        return;
//--- clear array
    ArrayFree(resultVals);
//--- process results
    int res_total = m_configuration[ArraySize(m_configuration) - 1];
    ArrayResize(resultVals, res_total);
//--- loop and copy
    int idx = ArraySize(m_node_vals) - 1;
    for (int i = res_total - 1; i >= 0; --i) {
        resultVals[i] = m_node_vals[idx];
        --idx;
    }
//---
    if (!probabilities)
        return;
//
    double sum = 0.0;
    for (int i = 0; i < ArraySize(resultVals) && !IsStopped(); ++i)
        sum += resultVals[i];
//--- compute probs
    for (int i = 0; i < ArraySize(resultVals) && !IsStopped(); ++i)
        resultVals[i] /= sum;
//---
    return;
}

//+------------------------------------------------------------------+
//|     get error information over the training sample               |
//+------------------------------------------------------------------+
void CNerveMatrix::getErrorBuffer(double &ave_err[]) const {
    ArrayFree(ave_err);
    ArrayCopy(ave_err, m_errors);
//---
    return;
}

//+------------------------------------------------------------------+
//|    Prepare a string-encoded framework of _nerve_                   |
//+------------------------------------------------------------------+
string CNerveMatrix::Save(void)const {
    if(!m_activated)
        return NULL;
//---
    string _nerve_ = "";
    const string del = "|";
    const string nan = "nan";
//--- parse layers
    _nerve_ += IntegerToString(ArraySize(m_configuration)) + del + nan + del;
//--- configuration
    for(int i = 0; i < ArraySize(m_configuration) && !IsStopped(); ++i)
        _nerve_ += IntegerToString(m_configuration[i]) + del;
    _nerve_ += nan + del;
//--- activation
    for(int i = 0; i < ArraySize(m_activation) && !IsStopped(); ++i)
        _nerve_ += IntegerToString(m_activation[i]) + del;
    _nerve_ += nan + del;
//--- eta,alpha & smoothing factor
    _nerve_ += DoubleToString(m_eta, 4) + del;
    _nerve_ += DoubleToString(m_alpha, 4) + del;
    _nerve_ += DoubleToString(m_smoothing_factor, 4) + del;
    _nerve_ += nan + del;
//--- count weights
    int weights = ArraySize(m_weights);
    _nerve_ += IntegerToString(weights) + del + nan + del;
//--- weights
    for(int i = 0; i < ArraySize(m_weights) && !IsStopped(); ++i)
        _nerve_ += DoubleToString(m_weights[i], 16) + del;
    _nerve_ += nan;
//---
    return _nerve_;
}

//+------------------------------------------------------------------+
//|  Load a string-encoded framework of the network                  |
//+------------------------------------------------------------------+
bool CNerveMatrix::Load(const string &to_parse) {
    if(StringLen(to_parse) <= 0)
        return false;
//---
    ArrayFree(m_weights);
    ArrayFree(m_configuration);
    ArrayFree(m_delta_weights);
    ArrayFree(m_errors);
    ArrayFree(m_node_vals);
//---
    string parse[];
    StringSplit(to_parse, '|', parse);
//--- check validity
    if(parse[1] != "nan")
        return false;
//--- parse and load the network
    int layers = (int)parse[0];
    if(layers == 0)
        return false;
//--- remove layer delimiters
    ArrayRemove(parse, 0, 2);
//--- extract layer node count
    ArrayResize(m_configuration, layers);
    for(int i = 0; i < ArraySize(m_configuration) && !IsStopped(); ++i)
        m_configuration[i] = (int)parse[i];
//--- remove node delimiters
    ArrayRemove(parse, 0, layers + 1);
//--- read activations
    for(int i = 0; i < 2 && !IsStopped(); ++i)
        m_activation[i] = (Activations)parse[i];
//--- remove activation delimiters
    ArrayRemove(parse, 0, 3);
//--- read settings
    m_eta = (double)parse[0];
    m_alpha = (double)parse[1];
    m_smoothing_factor = (double)parse[2];
//--- remove settings delimiters
    ArrayRemove(parse, 0, 4);
//--- load connections count
    int connections = (int)parse[0];
    ArrayResize(m_weights, connections);
//--- remove connection delimiters
    ArrayRemove(parse, 0, 2);
//--- load weights
    for(int i = 0; i < connections && !IsStopped(); ++i)
        m_weights[i] = (double)parse[i];
//--- initialize the network
//--- counter variables
    int neurons = 0;
//--- count network elements
    for (int i = 0; i < layers; i++)
        neurons += (i + 1 < layers ) ? m_configuration[i] + 1 : m_configuration[i];
//--- resize data arrays
    ArrayResize(m_node_vals, neurons);
//---
    ArrayResize(m_delta_weights, connections);
    ArrayResize(m_gradients, neurons);
//--- set initialize arrays
    ArrayInitialize(m_node_vals, 1.0);
    ArrayInitialize(m_gradients, 0.0);
    ArrayInitialize(m_delta_weights, 0.0);
//--- return result of operation
    m_activated = true;
    return true;
}
//+------------------------------------------------------------------+
