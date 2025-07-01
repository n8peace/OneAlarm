# Stock Symbols Reference

## 📈 OneAlarm Stock Market Coverage

This document provides a comprehensive reference for all stock symbols tracked by the OneAlarm system.

## 🎯 Overview

- **Total Symbols**: 25
- **Market Sectors**: 6
- **API Source**: Yahoo Finance via RapidAPI
- **Update Frequency**: Every hour with daily content generation
- **Optimization**: Single API call for all symbols (25x efficiency improvement)

## 📊 Symbol Breakdown by Sector

### **Technology Sector (10 symbols)**
| Symbol | Company Name | Description |
|--------|--------------|-------------|
| AAPL | Apple Inc. | Consumer electronics and software |
| GOOGL | Alphabet Inc. | Internet services and technology |
| TSLA | Tesla, Inc. | Electric vehicles and clean energy |
| MSFT | Microsoft Corporation | Software and cloud services |
| NVDA | NVIDIA Corporation | Graphics processing and AI |
| META | Meta Platforms, Inc. | Social media and technology |
| AMZN | Amazon.com, Inc. | E-commerce and cloud computing |
| NFLX | Netflix, Inc. | Streaming entertainment |
| ADBE | Adobe Inc. | Creative software and digital media |
| CRM | Salesforce, Inc. | Customer relationship management |

### **Finance Sector (4 symbols)**
| Symbol | Company Name | Description |
|--------|--------------|-------------|
| JPM | JPMorgan Chase & Co. | Banking and financial services |
| BAC | Bank of America Corporation | Banking and financial services |
| WFC | Wells Fargo & Company | Banking and financial services |
| GS | The Goldman Sachs Group, Inc. | Investment banking and securities |

### **Healthcare Sector (4 symbols)**
| Symbol | Company Name | Description |
|--------|--------------|-------------|
| JNJ | Johnson & Johnson | Pharmaceuticals and medical devices |
| PFE | Pfizer Inc. | Pharmaceutical research and development |
| UNH | UnitedHealth Group Incorporated | Health insurance and healthcare services |
| ABBV | AbbVie Inc. | Biopharmaceutical research |

### **Consumer Sector (4 symbols)**
| Symbol | Company Name | Description |
|--------|--------------|-------------|
| KO | The Coca-Cola Company | Beverages and consumer goods |
| PG | The Procter & Gamble Company | Consumer goods and personal care |
| WMT | Walmart Inc. | Retail and e-commerce |
| DIS | The Walt Disney Company | Entertainment and media |

### **Market Index (1 symbol)**
| Symbol | Index Name | Description |
|--------|------------|-------------|
| ^GSPC | S&P 500 Index | Major US stock market index |

### **Cryptocurrency (2 symbols)**
| Symbol | Cryptocurrency | Description |
|--------|----------------|-------------|
| BTC-USD | Bitcoin | Leading cryptocurrency |
| ETH-USD | Ethereum | Smart contract platform |

## 🔧 Technical Implementation

### **API Configuration**
```typescript
// Location: supabase/functions/daily-content/config.ts
stocks: {
  symbols: [
    // Technology (10 symbols)
    'AAPL', 'GOOGL', 'TSLA', 'MSFT', 'NVDA', 'META', 'AMZN', 'NFLX', 'ADBE', 'CRM',
    // Finance (4 symbols)
    'JPM', 'BAC', 'WFC', 'GS',
    // Healthcare (4 symbols)
    'JNJ', 'PFE', 'UNH', 'ABBV',
    // Consumer (4 symbols)
    'KO', 'PG', 'WMT', 'DIS',
    // Market Index (1 symbol)
    '^GSPC',
    // Crypto (2 symbols)
    'BTC-USD', 'ETH-USD'
  ],
  timeout: 10000,
  retries: 2
}
```

### **Data Format**
Stock data is delivered in the following format:
```
AAPL: $201.56 (0.63%)
GOOGL: $170.68 (2.34%)
TSLA: $327.55 (-3.79%)
MSFT: $492.27 (0.44%)
NVDA: $154.31 (4.33%)
...
```

### **Database Storage**
- **Table**: `daily_content`
- **Field**: `stocks_summary`
- **Format**: Multi-line string with symbol, price, and percentage change
- **Update Frequency**: Every hour at minute 3

## 📈 Performance Metrics

### **API Efficiency**
- **Before Optimization**: 25 separate API calls
- **After Optimization**: 1 API call for all symbols
- **Improvement**: 25x reduction in API calls
- **Monthly Usage**: ~720 requests (7.2% of 10,000 limit)

### **Coverage Benefits**
- **Market Diversity**: 6 different sectors represented
- **Market Cap Coverage**: Includes major large-cap companies
- **Geographic Focus**: Primarily US markets with global crypto
- **Sector Balance**: Technology-heavy with financial, healthcare, and consumer exposure

## 🚀 Adding New Symbols

### **Process**
1. Add symbol to `config.ts` symbols array
2. Deploy the function: `supabase functions deploy daily-content`
3. Test with: `./scripts/test-daily-content-flow.sh`
4. Verify data appears in database

### **Considerations**
- **API Limits**: Current usage at 7.2% of monthly limit
- **Response Size**: More symbols = larger response payload
- **Processing Time**: Minimal impact with current optimization
- **Error Handling**: Individual symbol failures don't affect others

## 📱 SwiftUI Integration

### **Displaying Stock Data**
```swift
struct StockDataView: View {
    let stocksSummary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Market Update")
                .font(.headline)
            
            Text(stocksSummary)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### **Parsing Stock Data**
```swift
func parseStockData(_ summary: String) -> [StockQuote] {
    let lines = summary.components(separatedBy: .newlines)
    return lines.compactMap { line in
        // Parse format: "AAPL: $201.56 (0.63%)"
        // Implementation details...
    }
}
```

## 📊 Monitoring and Alerts

### **Key Metrics to Monitor**
- API response times
- Symbol data availability
- Error rates per symbol
- Monthly API usage vs limits

### **Alert Thresholds**
- API usage > 80% of monthly limit
- Error rate > 5% for any symbol
- Response time > 5 seconds
- Missing data for > 3 symbols

---

**Last Updated**: June 2025  
**Total Symbols**: 25  
**Sectors**: 6  
**API Efficiency**: 25x improvement  
**Status**: ✅ Production Deployed 