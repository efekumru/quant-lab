"""
Shared utility functions for quant research notebooks.
"""

import numpy as np
import pandas as pd


def sharpe(returns: pd.Series, rf: float = 0.0) -> float:
    excess = returns - rf / 252
    return float((excess.mean() / excess.std()) * np.sqrt(252)) if excess.std() > 0 else 0.0


def max_drawdown(returns: pd.Series) -> float:
    cum = (1 + returns).cumprod()
    return float(((cum - cum.cummax()) / cum.cummax()).min())


def cagr(returns: pd.Series) -> float:
    total = (1 + returns).prod()
    n_years = len(returns) / 252
    return float(total ** (1 / max(n_years, 0.01)) - 1)


def quick_stats(returns: pd.Series, name: str = "") -> dict:
    """One-liner performance summary."""
    return {
        "name": name,
        "cagr": f"{cagr(returns):.1%}",
        "sharpe": f"{sharpe(returns):.2f}",
        "max_dd": f"{max_drawdown(returns):.1%}",
        "vol": f"{returns.std() * np.sqrt(252):.1%}",
        "skew": f"{returns.skew():.2f}",
    }


def compute_rsi(prices: pd.Series, period: int = 14) -> pd.Series:
    delta = prices.diff()
    gain = delta.where(delta > 0, 0).rolling(period).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(period).mean()
    rs = gain / loss.replace(0, np.nan)
    return 100 - (100 / (1 + rs))


def compute_macd(prices: pd.Series, fast=12, slow=26, signal=9):
    ema_f = prices.ewm(span=fast).mean()
    ema_s = prices.ewm(span=slow).mean()
    macd = ema_f - ema_s
    sig = macd.ewm(span=signal).mean()
    return macd, sig, macd - sig


def compute_bbands(prices: pd.Series, period=20, num_std=2.0):
    sma = prices.rolling(period).mean()
    std = prices.rolling(period).std()
    return sma + num_std * std, sma, sma - num_std * std
