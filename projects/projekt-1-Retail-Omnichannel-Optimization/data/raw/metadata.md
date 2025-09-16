# Online Retail II Dataset Metadata

## Source Information
- **Dataset:** Online Retail II
- **Source:** UCI Machine Learning Repository
- **License:** CC BY 4.0
- **URL:** https://archive.ics.uci.edu/ml/datasets/Online+Retail+II
- **Download Date:** 2025-08-12

## Dataset Description
- **Records:** ~540,000 transactions
- **Time Period:** 2009-2011 (2 years)
- **Business Type:** UK-based online retail
- **Geography:** Primarily UK, some international

## Schema Overview
| Column | Type | Description | Business Rules |
|--------|------|-------------|----------------|
| Invoice | String | Transaction ID | 6-digit, starts with C for cancellations |
| StockCode | String | Product code | 5-6 characters, unique per product |
| Description | String | Product name | Free text, may contain variations |
| Quantity | Integer | Units sold | Negative for returns/cancellations |
| InvoiceDate | DateTime | Transaction timestamp | DD/MM/YYYY HH:MM format |
| Price | Decimal | Unit price | GBP, positive values |
| Customer ID | Integer | Customer identifier | May be null for guest purchases |
| Country | String | Customer country | UK majority, 37 countries total |

## Data Quality Notes
- Guest purchases (no Customer ID): ~25% of records
- Returns/cancellations: ~8% of transactions
- Missing descriptions: <1% of records
- International sales: ~15% of total value

## Business Context
- B2C online retailer specializing in unique gifts
- Peak seasons: November-December (Christmas)
- Product categories: Home decor, gifts, seasonal items
- Customer segments: UK domestic + international exports
