//+------------------------------------------------------------------+
//|                                            RSI_Scalper_EA.mq4    |
//|                                          Copyright 2024, EK      |
//|                                          Efe Kumru               |
//+------------------------------------------------------------------+
#property copyright "Efe Kumru"
#property version   "1.00"
#property strict

// --- Inputs ---
input int      RSI_Period     = 7;           // RSI Period (shorter for scalping)
input int      RSI_OB         = 75;          // Overbought level
input int      RSI_OS         = 25;          // Oversold level
input int      BB_Period      = 14;          // Bollinger Period
input double   BB_Dev         = 2.0;         // Bollinger Deviation
input double   LotSize        = 0.02;        // Lot size
input int      TP_Points      = 30;          // Take profit (points)
input int      SL_Points      = 20;          // Stop loss (points)
input int      MaxSpread      = 20;          // Max spread allowed (points)
input int      StartHour      = 8;           // Trading start hour (server time)
input int      EndHour        = 20;          // Trading end hour
input int      MagicNumber    = 20243;

//+------------------------------------------------------------------+
int OnInit()
{
    Print("RSI Scalper initialized | RSI: ", RSI_Period, " BB: ", BB_Period);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
    // Time filter
    int hour = TimeHour(TimeCurrent());
    if(hour < StartHour || hour >= EndHour) return;
    
    // Spread filter
    double spread = (Ask - Bid) / Point;
    if(spread > MaxSpread) return;
    
    // Check if already in a trade
    if(HasOpenOrder()) return;
    
    // Indicators
    double rsi     = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 0);
    double prevRSI = iRSI(NULL, 0, RSI_Period, PRICE_CLOSE, 1);
    
    double bbUpper = iBands(NULL, 0, BB_Period, BB_Dev, 0, PRICE_CLOSE, MODE_UPPER, 0);
    double bbLower = iBands(NULL, 0, BB_Period, BB_Dev, 0, PRICE_CLOSE, MODE_LOWER, 0);
    double bbMid   = iBands(NULL, 0, BB_Period, BB_Dev, 0, PRICE_CLOSE, MODE_MAIN, 0);
    
    double point = MarketInfo(Symbol(), MODE_POINT);
    
    // Long: RSI crosses above oversold + price near lower BB
    if(rsi > RSI_OS && prevRSI <= RSI_OS && Bid <= bbLower + (bbMid - bbLower) * 0.3)
    {
        double sl = Ask - SL_Points * point;
        double tp = Ask + TP_Points * point;
        
        int ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3,
                               NormalizeDouble(sl, Digits),
                               NormalizeDouble(tp, Digits),
                               "RSI Scalp Long", MagicNumber, 0, clrGreen);
        
        if(ticket > 0)
            Print("Scalp LONG @ ", Ask, " RSI: ", NormalizeDouble(rsi, 1));
    }
    
    // Short: RSI crosses below overbought + price near upper BB
    if(rsi < RSI_OB && prevRSI >= RSI_OB && Ask >= bbUpper - (bbUpper - bbMid) * 0.3)
    {
        double sl = Bid + SL_Points * point;
        double tp = Bid - TP_Points * point;
        
        int ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3,
                               NormalizeDouble(sl, Digits),
                               NormalizeDouble(tp, Digits),
                               "RSI Scalp Short", MagicNumber, 0, clrRed);
        
        if(ticket > 0)
            Print("Scalp SHORT @ ", Bid, " RSI: ", NormalizeDouble(rsi, 1));
    }
}

//+------------------------------------------------------------------+
bool HasOpenOrder()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol())
                return true;
        }
    }
    return false;
}
//+------------------------------------------------------------------+
