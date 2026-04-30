# 🏭 Manufacturing Operations Analytics

> An end-to-end data analysis project identifying root causes of production defects, rising supplier costs, and inventory holding inefficiencies in a manufacturing company.

---

## 🧩 Business Problem

A manufacturing company was facing three compounding operational challenges that were eroding profitability and customer satisfaction:

- **Rising production defect rates** — quality control failures across product lines
- **Increasing supplier costs** — uneven vendor performance with poor-quality, high-cost suppliers
- **Inventory holding issues** — stockout risks and inefficient reorder management

**Goals:**
- Identify which products and suppliers have the highest defect rates
- Find the most and least profitable products and suppliers
- Analyse monthly production trends and day-over-day output variation
- Assess inventory health and flag critical stockout risks
- Recommend data-driven actions to improve operational efficiency

---

## 📊 Key Metrics (Dashboard)

| Metric | Value |
|---|---|
| Total Products | 500 |
| Total Production | $52.42M |
| Total Profit | $55.42bn |
| Total Suppliers | 200 |
| Avg Defect Rate | 1.91% |
| Date Range | Feb 2024 – Feb 2026 |

---

## 🗂️ Dataset Structure

Five CSV files were used, forming a relational schema:

```
products.csv     → Product catalog, category, standard_cost, selling_price
suppliers.csv    → Supplier master, country, rating
inventory.csv    → Stock levels, reorder thresholds, last_updated timestamps
production.csv   → Daily production runs, quantity_produced, production_cost, shift
defects.csv      → Inspection records, defect_type, defect_quantity per production run
```

### Entity Relationships
```
products  ──< production >── suppliers
production ──< defects
products  ──< inventory
```

---

## 🐍 Python Analysis (Pandas)

**File:** `Manufacturing_project.ipynb`

### Steps Performed

**1. Data Loading**
```python
import pandas as pd
products   = pd.read_csv('products.csv')
suppliers  = pd.read_csv('suppliers.csv')
inventory  = pd.read_csv('inventory.csv')
production = pd.read_csv('production.csv')
defects    = pd.read_csv('defects.csv')
```

**2. Data Cleaning per Table**

| Table | Cleaning Applied |
|---|---|
| Products | No nulls — derived features added |
| Suppliers | `country` nulls → `'Unknown'`; `rating` nulls → `0` |
| Inventory | `stock_quantity` nulls → `0`; `last_updated` parsed to datetime |
| Production | `production_cost` nulls → median; `production_date` parsed to datetime |
| Defects | `defect_quantity` nulls → group median by `defect_type`; `inspection_date` parsed |

**3. Feature Engineering**

| Feature | Table | Logic |
|---|---|---|
| `margin` | Products | `selling_price − standard_cost` |
| `margin_status` | Products | `'Profit'` if margin > 0 else `'Loss'` |
| `rating_category` | Suppliers | High (4–5) / Medium (3–4) / Low (1–3) / No Rating (0) |
| `warehouse_condition` | Inventory | Healthy / Reorder Now / Stockout Risk |
| `defect_rate` | Analysis DF | `defect_quantity / quantity_produced` |
| `cost_per_unit` | Analysis DF | `production_cost / quantity_produced` |
| `total_profit` | Analysis DF | `margin_per_unit × quantity_produced` |

**Inventory Condition Logic:**
```python
def get_condition(row):
    if row['stock_quantity'] > row['reorder_level']:
        return 'Healthy'
    elif row['stock_quantity'] == row['reorder_level']:
        return 'Reorder Now'
    else:
        return 'Stockout Risk'

inventory['warehouse_condition'] = inventory.apply(get_condition, axis=1)
```

**Supplier Rating Logic:**
```python
def get_rating(x):
    if   x >= 4: return "High"
    elif x >= 3: return "Medium"
    elif x >= 1: return "Low"
    else:        return "No Rating"

suppliers['rating_category'] = suppliers['rating'].apply(get_rating)
```

**4. Table Merging**
```python
analysis_df = production.merge(products,  on='product_id',  how='left')
analysis_df = analysis_df.merge(suppliers, on='supplier_id', how='left')

defects_agg   = defects.groupby('production_id')['defect_quantity'].sum().reset_index()
inventory_agg = inventory.groupby('product_id')['stock_quantity'].sum().reset_index()

analysis_df = analysis_df.merge(defects_agg,   on='production_id', how='left')
analysis_df = analysis_df.merge(inventory_agg, on='product_id',    how='left')
```

**5. Pivot Table Analysis**
- Top 10 & Bottom 10 suppliers by total profit
- Top 10 suppliers by average defect rate
- Top 10 & Bottom 10 products by total profit
- Top 10 products by average defect rate
- Production volume by shift
- Average production cost by shift
- Total defect quantities by defect type

**6. Visualisations**
- Bar chart: Top 10 Suppliers by Defect Rate
- Bar chart: Top 10 Products by Defect Rate

**7. Export to MySQL**
```python
from sqlalchemy import create_engine
engine = create_engine("mysql+pymysql://root:password@localhost:3306/manufacturing_project")
products.to_sql('products',   engine, if_exists='replace', index=False)
suppliers.to_sql('suppliers', engine, if_exists='replace', index=False)
inventory.to_sql('inventory', engine, if_exists='replace', index=False)
production.to_sql('production', engine, if_exists='replace', index=False)
defects.to_sql('defects',     engine, if_exists='replace', index=False)
```

---

## 🗄️ SQL Analysis (MySQL)

**File:** `manufacturing_project.sql`

### Queries Overview

| # | Query | Technique |
|---|---|---|
| 1 | Top 10 products by total profit | `GROUP BY`, multi-table `JOIN`, `ORDER BY` |
| 2 | Suppliers with profit above $30M | `HAVING` on aggregated profit |
| 3 | Products above overall avg defect rate | Correlated subquery |
| 4 | Rank products by total profit (Top 5) | CTE + `DENSE_RANK()` |
| 5 | Worst 5 suppliers by defect rate | CTE + `ROW_NUMBER()` |
| 6 | Monthly total quantity produced | `DATE_FORMAT`, `GROUP BY`, `ORDER BY` |
| 7 | Supplier profit vs. overall average | CTE + scalar subquery + `CASE WHEN` |
| 8 | Running total of quantity produced | `SUM() OVER (ORDER BY production_date)` |
| 9 | Day-over-day production difference | `LAG()` window function |
| 10 | Classify products by profit tier | CTE + `CASE WHEN` classification |

### Product Profit Classification
```sql
CASE
  WHEN total_profit > 50000000            THEN 'High Profit'
  WHEN total_profit BETWEEN 20000000
                        AND 50000000      THEN 'Medium Profit'
  ELSE                                        'Low Profit'
END
```

### Supplier Benchmarking (Q7)
```sql
CASE
  WHEN total_profit > (SELECT AVG(total_profit) FROM supplier_profit)
  THEN 'Above Average'
  ELSE 'Below Average'
END
```

---

## 📈 Power BI Dashboard

**File:** Dashboard screenshot included in project report.

### Components
- **KPI Cards** — Total Products, Total Production, Total Profit, Total Suppliers, Avg Defect Rate
- **Total Production by Category** — Horizontal bar chart (Packaging 18.6bn → Automotive 10.2bn)
- **Monthly Production Trend** — Line chart with data labels (Jan–Dec)
- **Product Detail Table** — Defect Rate, Total Profit, Category per product (sortable)
- **Supplier Rank Table** — Suppliers ranked by defect rate and total profit
- **Date Range Slicer** — Feb 2024 to Feb 2026 (adjustable)
- **Country Filter** — China / Unknown / Germany / USA / India
- **Products & Suppliers Slicers** — Dynamic category and vendor-level filtering

---

## 💡 Key Findings

- **Packaging** is the highest-volume production category (18.6bn units), but volume ≠ profitability
- **1.91% average defect rate** equals millions of defective units annually at scale
- The **top 5 worst suppliers by defect rate** are identifiable and directly actionable
- A subset of products have **negative margins** (standard_cost > selling_price) — operating at a loss
- **Night shifts** produce higher cost-per-unit, indicating overtime premiums or lower productivity
- **February** is the lowest-output month; **July–August** peaks at ~4.53M units/month
- Some inventory records are in **Stockout Risk** status — a direct production continuity threat

---

## ✅ Recommendations

| Area | Action |
|---|---|
| Defect Reduction | Audit worst 5 suppliers; implement incoming material inspection |
| Quality Control | Deploy SPC monitoring on above-average defect-rate product lines |
| Supplier Strategy | Consolidate with high-profit, low-defect suppliers; phase out underperformers |
| Supplier Scorecard | Quarterly review combining defect rate, profit, delivery, and rating |
| Inventory | Automate reorder triggers for all Stockout Risk products |
| Safety Stock | Build buffers for high-profit products against supplier delays |
| Production | Investigate low-output months; review night shift economics |
| Portfolio | Discontinue or reprice all products with negative margins |

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| Python 3 (Pandas) | Data loading, cleaning, feature engineering, EDA, pivot analysis |
| Matplotlib | Defect rate bar chart visualisations |
| MySQL | 10 structured queries across profit, defect, trend, and classification |
| SQLAlchemy | DataFrame-to-MySQL export via `create_engine` |
| Power BI | Interactive manufacturing operations dashboard |

---

## 📁 Project Structure

```
Manufacturing_Project/
│
├── Manufacturing_project.ipynb       # Python EDA notebook
├── manufacturing_project.sql         # MySQL queries
├── products.csv                      # Product catalog
├── suppliers.csv                     # Supplier master data
├── inventory.csv                     # Warehouse stock levels
├── production.csv                    # Daily production records
├── defects.csv                       # Inspection & defect records
└── Manufacturing_Project_Report.docx # Full project report
```

---

## 🚀 How to Run

**Python Notebook**
```bash
pip install pandas matplotlib sqlalchemy pymysql cryptography
jupyter notebook Manufacturing_project.ipynb
```

**MySQL**
```sql
CREATE DATABASE manufacturing_project;
USE manufacturing_project;
-- Run manufacturing_project.sql
```

---
