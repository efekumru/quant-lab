//+------------------------------------------------------------------+
//|                                          TrendFollowerEA.mq4     |
//|                                          Copyright 2024, EK      |
//|                                          Efe Kumru               |
//+------------------------------------------------------------------+
#property copyright "Efe Kumru"
#property version   "1.20"
#property strict

// --- Input Parameters ---
input int      FastMA_Period    = 20;        // Fast MA Period
input int      SlowMA_Period    = 50;        // Slow MA Period
input int      ADX_Period       = 14;        // ADX Period
input double   ADX_Threshold    = 25.0;      // Min ADX for trend
input double   RiskPercent      = 1.0;       // Risk per trade (%)
input double   ATR_StopMult     = 2.0;       // ATR multiplier for SL
input int      ATR_Period       = 14;        // ATR Period
input int      MagicNumber      = 20241;     // Magic Number

// --- Global Variables ---
double fastMA, slowMA, adxValue, atrValue;
int ticket = -1;

//+------------------------------------------------------------------+
int OnInit()
{
    Print("TrendFollower EA initialized | Fast:", FastMA_Period, " Slow:", SlowMA_Period);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
    // Calculate indicators
    fastMA   = iMA(NULL, 0, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
    slowMA   = iMA(NULL, 0, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE, 0);
    adxValue = iADX(NULL, 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
    atrValue = iATR(NULL, 0, ATR_Period, 0);
    
    double prevFastMA = iMA(NULL, 0, FastMA_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    double prevSlowMA = iMA(NULL, 0, SlowMA_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
    
    // Check for open positions
    bool hasPosition = false;
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
            {
                hasPosition = true;
                ManagePosition();
                break;
            }
        }
    }
    
    if(hasPosition) return;
    
    // Entry logic: MA crossover + ADX filter
    bool bullishCross = fastMA > slowMA && prevFastMA <= prevSlowMA;
    bool bearishCross = fastMA < slowMA && prevFastMA >= prevSlowMA;
    bool strongTrend  = adxValue > ADX_Threshold;
    
    if(bullishCross && strongTrend)
    {
        double sl = Ask - atrValue * ATR_StopMult;
        double tp = Ask + atrValue * ATR_StopMult * 2.0; // 2:1 RR
        double lots = CalculateLotSize(Ask - sl);
        
        ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, sl, tp, 
                          "TrendFollower Long", MagicNumber, 0, clrGreen);
        
        if(ticket > 0)
            Print("LONG entry @ ", Ask, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
        else
            Print("Order error: ", GetLastError());
    }
    
    if(bearishCross && strongTrend)
    {
        double sl = Bid + atrValue * ATR_StopMult;
        double tp = Bid - atrValue * ATR_StopMult * 2.0;
        double lots = CalculateLotSize(sl - Bid);
        
        ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, sl, tp,
                          "TrendFollower Short", MagicNumber, 0, clrRed);
        
        if(ticket > 0)
            Print("SHORT entry @ ", Bid, " SL: ", sl, " TP: ", tp, " Lots: ", lots);
        else
            Print("Order error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
void ManagePosition()
{
    // Trailing stop: move SL to breakeven + 1 ATR after 1.5 ATR profit
    if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
    
    double entryPrice = OrderOpenPrice();
    double currentSL  = OrderStopLoss();
    
    if(OrderType() == OP_BUY)
    {
        double profit = Bid - entryPrice;
        if(profit > atrValue * 1.5)
        {
            double newSL = entryPrice + atrValue;
            if(newSL > currentSL)
            {
                OrderModify(ticket, entryPrice, newSL, OrderTakeProfit(), 0, clrGreen);
            }
        }
    }
    else if(OrderType() == OP_SELL)
    {
        double profit = entryPrice - Ask;
        if(profit > atrValue * 1.5)
        {
            double newSL = entryPrice - atrValue;
            if(newSL < currentSL || currentSL == 0)
            {
                OrderModify(ticket, entryPrice, newSL, OrderTakeProfit(), 0, clrRed);
            }
        }
    }
}

//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
    if(slDistance <= 0) return 0.01;
    
    double riskAmount = AccountBalance() * RiskPercent / 100.0;
    double tickValue  = MarketInfo(Symbol(), MODE_TICKVALUE);
    double tickSize   = MarketInfo(Symbol(), MODE_TICKSIZE);
    
    if(tickValue == 0 || tickSize == 0) return 0.01;
    
    double lots = riskAmount / (slDistance / tickSize * tickValue);
    lots = MathMax(lots, MarketInfo(Symbol(), MODE_MINLOT));
    lots = MathMin(lots, MarketInfo(Symbol(), MODE_MAXLOT));
    lots = NormalizeDouble(lots, 2);
    
    return lots;
}
//+------------------------------------------------------------------+
