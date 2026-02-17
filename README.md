# 🔬 Quant Lab

Research notebooks, strategy backtests, and MetaTrader expert advisors. This is my working lab for prototyping and testing quantitative trading ideas.

## Structure

```
quant-lab/
├── notebooks/          # Jupyter/Colab backtests & research
├── metatrader/         # Expert Advisors (.mq4)
├── strategies/
│   └── pine_scripts/   # TradingView Pine Script strategies
└── utils.py            # Shared helper functions
```

## Notebooks

| Notebook | Description |
|----------|-------------|
| [momentum_backtest_spy](notebooks/momentum_backtest_spy.ipynb) | 20-day momentum strategy on SPY (2019-2024) |
| [pairs_trading_research](notebooks/pairs_trading_research.ipynb) | Cointegration-based pairs trading on tech stocks |
| [rsi_mean_reversion](notebooks/rsi_mean_reversion.ipynb) | RSI oversold bounce strategy across 8 tickers |
| [bollinger_bands_comparison](notebooks/bollinger_bands_comparison.ipynb) | Mean reversion vs breakout using Bollinger Bands |
| [vol_targeting](notebooks/vol_targeting.ipynb) | Volatility-targeted position sizing |
| [macd_signal_analysis](notebooks/macd_signal_analysis.ipynb) | MACD signal accuracy across different assets |

## MetaTrader EAs

| EA | Strategy |
|----|----------|
| [TrendFollowerEA](metatrader/TrendFollowerEA.mq4) | EMA crossover + ADX filter + ATR trailing stops |
| [GridTraderEA](metatrader/GridTraderEA.mq4) | Grid trading with max drawdown protection |
| [RSI_Scalper_EA](metatrader/RSI_Scalper_EA.mq4) | RSI + Bollinger Bands scalping (M5/M15) |

## Pine Scripts

| Script | Description |
|--------|-------------|
| [momentum_rsi_filter](strategies/pine_scripts/momentum_rsi_filter.pine) | Momentum + RSI confirmation with ATR stops |
| [bb_mean_reversion](strategies/pine_scripts/bb_mean_reversion.pine) | Bollinger Band lower touch mean reversion |

## Disclaimer

Some strategies are kept in a private repo. What's here is for research and educational purposes.

## Tech Stack

Python · Pandas · NumPy · Matplotlib · MetaTrader 4 · Pine Script · Google Colab
