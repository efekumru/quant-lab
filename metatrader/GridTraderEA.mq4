//+------------------------------------------------------------------+
//|                                              GridTraderEA.mq4    |
//|                                          Copyright 2024, EK      |
//|                                          Efe Kumru               |
//+------------------------------------------------------------------+
#property copyright "Efe Kumru"
#property version   "1.10"
#property strict

// --- Input Parameters ---
input double   GridSpacing      = 50;        // Grid spacing (points)
input int      GridLevels       = 5;         // Number of grid levels each side
input double   BaseLotSize      = 0.01;      // Base lot size
input double   LotMultiplier    = 1.0;       // Lot multiplier per level (1.0 = fixed)
input double   TakeProfit       = 50;        // TP per order (points)
input double   MaxDrawdownPct   = 10.0;      // Max DD before closing all (%)
input int      MagicNumber      = 20242;     // Magic Number

// --- Global Variables ---
double gridCenter;
bool   gridInitialized = false;

//+------------------------------------------------------------------+
int OnInit()
{
    gridCenter = NormalizeDouble((Ask + Bid) / 2, Digits);
    Print("Grid EA initialized | Center: ", gridCenter, " Spacing: ", GridSpacing, " pts");
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnTick()
{
    // Check max drawdown
    if(CheckDrawdown()) return;
    
    // Place grid orders if not yet done
    if(!gridInitialized)
    {
        PlaceGrid();
        gridInitialized = true;
    }
    
    // Replace filled orders
    ManageGrid();
}

//+------------------------------------------------------------------+
void PlaceGrid()
{
    double point = MarketInfo(Symbol(), MODE_POINT);
    
    for(int i = 1; i <= GridLevels; i++)
    {
        double lots = BaseLotSize * MathPow(LotMultiplier, i - 1);
        lots = NormalizeDouble(lots, 2);
        
        // Buy limit below current price
        double buyPrice = gridCenter - i * GridSpacing * point;
        double buySL = 0;
        double buyTP = buyPrice + TakeProfit * point;
        
        int buyTicket = OrderSend(Symbol(), OP_BUYLIMIT, lots, 
                                   NormalizeDouble(buyPrice, Digits),
                                   3, buySL, NormalizeDouble(buyTP, Digits),
                                   "Grid Buy L" + IntegerToString(i),
                                   MagicNumber, 0, clrGreen);
        
        if(buyTicket < 0)
            Print("Grid buy error level ", i, ": ", GetLastError());
        
        // Sell limit above current price
        double sellPrice = gridCenter + i * GridSpacing * point;
        double sellSL = 0;
        double sellTP = sellPrice - TakeProfit * point;
        
        int sellTicket = OrderSend(Symbol(), OP_SELLLIMIT, lots,
                                    NormalizeDouble(sellPrice, Digits),
                                    3, sellSL, NormalizeDouble(sellTP, Digits),
                                    "Grid Sell L" + IntegerToString(i),
                                    MagicNumber, 0, clrRed);
        
        if(sellTicket < 0)
            Print("Grid sell error level ", i, ": ", GetLastError());
    }
    
    Print("Grid placed: ", GridLevels, " levels each side");
}

//+------------------------------------------------------------------+
void ManageGrid()
{
    // Count active pending and market orders
    int pendingCount = 0;
    int marketCount = 0;
    
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;
        
        if(OrderType() <= OP_SELL)
            marketCount++;
        else
            pendingCount++;
    }
    
    // Reset grid if too few pending orders remain
    if(pendingCount < GridLevels && marketCount == 0)
    {
        CloseAllOrders();
        gridCenter = NormalizeDouble((Ask + Bid) / 2, Digits);
        gridInitialized = false;
        Print("Grid reset at new center: ", gridCenter);
    }
}

//+------------------------------------------------------------------+
bool CheckDrawdown()
{
    double balance = AccountBalance();
    double equity  = AccountEquity();
    
    if(balance == 0) return false;
    
    double ddPct = (balance - equity) / balance * 100;
    
    if(ddPct > MaxDrawdownPct)
    {
        Print("Max drawdown reached (", NormalizeDouble(ddPct, 1), "%). Closing all.");
        CloseAllOrders();
        gridInitialized = false;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
void CloseAllOrders()
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        if(OrderMagicNumber() != MagicNumber || OrderSymbol() != Symbol()) continue;
        
        if(OrderType() == OP_BUY)
            OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrGray);
        else if(OrderType() == OP_SELL)
            OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrGray);
        else
            OrderDelete(OrderTicket());
    }
}
//+------------------------------------------------------------------+
