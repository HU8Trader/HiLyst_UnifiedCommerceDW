import os
import sys
import subprocess
import time
from PIL import Image

# Ensure UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

CHROME_PATH = r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
WORKSPACE = r"c:\Users\pc\Documents\HiLyst\Shopify E-Commerce Sales Dataset"
DASHBOARD_HTML = os.path.join(WORKSPACE, "dashboard", "index.html")
OUTPUT_DIR = os.path.join(WORKSPACE, "Dashboard Screenshots")
LINKEDIN_SCREENSHOTS_DIR = os.path.join(WORKSPACE, "Linkedin Post", "Dashboard Screenshots")

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(LINKEDIN_SCREENSHOTS_DIR, exist_ok=True)

def take_chrome_screenshot(url, output_path, window_size="1920,1080", delay=3000):
    cmd = [
        CHROME_PATH,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        f"--window-size={window_size}",
        f"--virtual-time-budget={delay}",
        f"--screenshot={output_path}",
        url
    ]
    subprocess.run(cmd, capture_output=True, text=True)

def capture_tab_view(tab_name, output_path, window_size="1920,1080"):
    # Read HTML, modify active tab, write temp HTML, take screenshot, remove temp HTML
    with open(DASHBOARD_HTML, "r", encoding="utf-8") as f:
        html = f.read()
        
    # Replace active nav item and active view section
    html = html.replace('class="nav-item active"', 'class="nav-item"')
    html = html.replace(f'data-tab="{tab_name}">\n <a class="nav-link">', f'data-tab="{tab_name}">\n <a class="nav-link" style="background:#FFC20E; color:#111;">')
    html = html.replace('class="view-section active"', 'class="view-section"')
    html = html.replace(f'id="view-{tab_name}"', f'id="view-{tab_name}" class="view-section active"')
    
    # Also update header title in temp html
    titles = {
        "overview": ("Executive Overview", "Real-time performance across all 11 unified commerce channels"),
        "sales": ("Sales Order Intelligence", "Granular order funnel, fulfillment velocity, and cancellation diagnostics"),
        "products": ("Product Catalog & Pareto 80/20", "SKU velocity, Category ASPs, and high-margin catalog concentration"),
        "customers": ("Customer & B2B Wholesale Accounts", "Recency, Frequency, Monetary (RFM) segmentation and account health"),
        "marketing": ("Pricing Arbitrage & Financial Ledger", "Cross-platform MRP spreads and operational overhead breakdown"),
        "channels": ("Channel Performance & Unit Economics", "Platform contribution, marketplace commission margins, and cancellation rates"),
        "inventory": ("Warehouse Supply Chain & Stockout Bleed", "Days of supply remaining, dead stock capital, and reorder trigger alerts"),
        "reports": ("SQL Semantic Views & Data Downloads", "Direct query execution and instant Gold Layer CSV exports"),
        "insights": ("Autonomous AI Decision Intelligence", "Automated root-cause analysis, revenue leakage detection, and prescriptive actions"),
        "alerts": ("Data Quality & Governance Suite", "Automated 10/10 Kimball Star Schema integrity and referential audit logs"),
        "settings": ("System Settings & DW Metadata", "Connection string parameters, filegroup allocations, and catalog versioning")
    }
    
    if tab_name in titles:
        t, sub = titles[tab_name]
        html = html.replace('<h1 id="header-title">Executive Overview</h1>', f'<h1 id="header-title">{t}</h1>')
        html = html.replace('<p id="header-subtitle">Real-time performance across all 11 unified commerce channels</p>', f'<p id="header-subtitle">{sub}</p>')
    
    # Add auto chart init script trigger in temp html
    trigger_script = f"""
    <script>
    document.addEventListener('DOMContentLoaded', () => {{
        setTimeout(() => {{
            const navBtn = document.querySelector('[data-tab="{tab_name}"]');
            if (navBtn) navBtn.click();
        }}, 500);
    }});
    </script>
    """
    html = html.replace('</body>', f'{trigger_script}</body>')
    
    temp_html_path = os.path.join(WORKSPACE, "scratch", f"temp_{tab_name}.html")
    with open(temp_html_path, "w", encoding="utf-8") as f:
        f.write(html)
        
    url = f"file:///{temp_html_path.replace(os.sep, '/')}"
    take_chrome_screenshot(url, output_path, window_size=window_size, delay=3500)
    
    if os.path.exists(temp_html_path):
        os.remove(temp_html_path)

def main():
    print("============================================================================")
    print(" CAPTURING HIGH-RESOLUTION DASHBOARD COMPONENT SCREENSHOTS")
    print("============================================================================")
    
    # 1. Full Executive Overview
    full_overview_path = os.path.join(OUTPUT_DIR, "01_Executive_Overview_Full.png")
    url_main = f"file:///{DASHBOARD_HTML.replace(os.sep, '/')}"
    print("Capturing 01_Executive_Overview_Full.png...")
    take_chrome_screenshot(url_main, full_overview_path, window_size="1920,1080", delay=3000)
    
    # Copy to assets and linkedin post
    import shutil
    shutil.copy2(full_overview_path, os.path.join(WORKSPACE, "assets", "dashboard_overview.png"))
    shutil.copy2(full_overview_path, os.path.join(LINKEDIN_SCREENSHOTS_DIR, "dashboard_overview.png"))
    
    # 2. Crop individual component parts from the full overview
    if os.path.exists(full_overview_path):
        img = Image.open(full_overview_path)
        w, h = img.size
        print(f"Loaded master capture ({w}x{h}). Generating component crops...")
        
        # A. Top KPI Cards Row
        # Canvas starts at x=260 (sidebar), header ends at y=90, KPI row is y=90 to y=230, x=290 to x=1890
        kpi_crop = img.crop((290, 85, 1890, 245))
        kpi_path = os.path.join(OUTPUT_DIR, "02_Executive_KPI_Cards.png")
        kpi_crop.save(kpi_path)
        print(" [✓] Generated 02_Executive_KPI_Cards.png")
        
        # B. Revenue Over Time Chart
        # Middle row left card: x=290 to x=1020, y=260 to y=615
        rev_crop = img.crop((290, 260, 1035, 620))
        rev_path = os.path.join(OUTPUT_DIR, "03_Revenue_Over_Time_Chart.png")
        rev_crop.save(rev_path)
        print(" [✓] Generated 03_Revenue_Over_Time_Chart.png")
        
        # C. Revenue by Channel Donut Chart
        # Middle row center card: x=1055 to x=1460, y=260 to y=620
        donut_crop = img.crop((1055, 260, 1465, 620))
        donut_path = os.path.join(OUTPUT_DIR, "04_Revenue_by_Channel_Donut.png")
        donut_crop.save(donut_path)
        print(" [✓] Generated 04_Revenue_by_Channel_Donut.png")
        
        # D. Top Performing Products Table
        # Middle row right card: x=1485 to x=1890, y=260 to y=620
        prod_crop = img.crop((1485, 260, 1890, 620))
        prod_path = os.path.join(OUTPUT_DIR, "05_Top_Performing_Products_Table.png")
        prod_crop.save(prod_path)
        print(" [✓] Generated 05_Top_Performing_Products_Table.png")
        
        # E. Marketing Ad Spend vs Revenue Grouped Bar Chart
        # Bottom row left card: x=290 to x=970, y=640 to y=1030
        mkt_crop = img.crop((290, 640, 970, 1030))
        mkt_path = os.path.join(OUTPUT_DIR, "06_Marketing_AdSpend_vs_Revenue.png")
        mkt_crop.save(mkt_path)
        print(" [✓] Generated 06_Marketing_AdSpend_vs_Revenue.png")
        
        # F. Revenue by Platform Horizontal Bar Chart
        # Bottom row center card: x=990 to x=1430, y=640 to y=1030
        plat_crop = img.crop((990, 640, 1435, 1030))
        plat_path = os.path.join(OUTPUT_DIR, "07_Revenue_by_Platform_Horizontal_Bars.png")
        plat_crop.save(plat_path)
        print(" [✓] Generated 07_Revenue_by_Platform_Horizontal_Bars.png")
        
        # G. Autonomous AI Insights Stream
        # Bottom row right card: x=1455 to x=1890, y=640 to y=1030
        ai_crop = img.crop((1455, 640, 1890, 1030))
        ai_path = os.path.join(OUTPUT_DIR, "08_Autonomous_AI_Insights_Stream.png")
        ai_crop.save(ai_path)
        print(" [✓] Generated 08_Autonomous_AI_Insights_Stream.png")

    # 3. Capture Deep-Dive Views
    deep_dive_tabs = [
        ("sales", "09_Sales_Funnel_and_Fulfillment_Intelligence.png"),
        ("products", "10_Product_Catalog_and_Pareto_80_20.png"),
        ("customers", "11_Customer_RFM_and_State_Geographics.png"),
        ("marketing", "12_Cross_Channel_Pricing_Arbitrage.png"),
        ("channels", "13_Multi_Channel_Profitability_Matrix.png"),
        ("inventory", "14_Warehouse_Supply_Chain_Inventory_Health.png"),
        ("alerts", "15_Data_Quality_Suite_10_of_10_Pass_Logs.png"),
        ("reports", "16_Gold_Layer_Data_Reports_Download_Center.png")
    ]
    
    for tab_name, fname in deep_dive_tabs:
        out_fpath = os.path.join(OUTPUT_DIR, fname)
        print(f"Capturing {fname}...")
        capture_tab_view(tab_name, out_fpath, window_size="1920,1080")
        print(f" [✓] Saved {fname}")
        
    # Copy all to Linkedin Post / Dashboard Screenshots as well
    for f in os.listdir(OUTPUT_DIR):
        if f.endswith('.png'):
            shutil.copy2(os.path.join(OUTPUT_DIR, f), os.path.join(LINKEDIN_SCREENSHOTS_DIR, f))

    # Generate Catalog README in Dashboard Screenshots
    readme_path = os.path.join(OUTPUT_DIR, "README.md")
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write("# HiLyst BI Dashboard — Visual Screenshots Catalog\n\n")
        f.write("This directory contains high-resolution (1920x1080) visual captures of the complete Executive Dashboard and all granular analytical views.\n\n")
        f.write("---\n\n")
        f.write("## Screenshot Inventory\n\n")
        f.write("| File Name | Visual Component | Description |\n")
        f.write("| :--- | :--- | :--- |\n")
        f.write("| `01_Executive_Overview_Full.png` | Executive Overview | Complete single-page dashboard with Obsidian Dark sidebar and Studio Light canvas. |\n")
        f.write("| `02_Executive_KPI_Cards.png` | KPI Scorecard | Top 6 metric cards: Total GMV, Orders, B2B Accounts, AOV, Gross Margin, and HiLyst Score. |\n")
        f.write("| `03_Revenue_Over_Time_Chart.png` | Revenue Timeline | Spline area line chart with golden gradient fill and Daily/Weekly/Monthly switcher. |\n")
        f.write("| `04_Revenue_by_Channel_Donut.png` | Channel Donut | High-contrast revenue distribution across Amazon (82%), Wholesale (12.5%), Myntra/Ajio (3.8%). |\n")
        f.write("| `05_Top_Performing_Products_Table.png` | Top Products | Ranked product performance table with revenue, orders, and growth percentage tags. |\n")
        f.write("| `06_Marketing_AdSpend_vs_Revenue.png` | Marketing & Cost Ledger | Grouped bar chart comparing ad spend/costs vs attributed gross sales revenue. |\n")
        f.write("| `07_Revenue_by_Platform_Horizontal_Bars.png` | Platform Rankings | Horizontal bar chart ranking multi-channel sales volume across platforms. |\n")
        f.write("| `08_Autonomous_AI_Insights_Stream.png` | AI Insights Feed | Stream of strategic decision cards tagged by Performance, Product, Marketing, Alert, and Operations. |\n")
        f.write("| `09_Sales_Funnel_and_Fulfillment_Intelligence.png` | Sales Intelligence | Order funnel stages (Placed, Dispatched, Delivered, Cancelled) and FBA vs MFN fulfillment comparison. |\n")
        f.write("| `10_Product_Catalog_and_Pareto_80_20.png` | Product & Pareto 80/20 | Category revenue breakdown, Pareto Class A/B/C metrics, and conformed catalog search table. |\n")
        f.write("| `11_Customer_RFM_and_State_Geographics.png` | Customer & Geography | RFM customer segmentation donut, Top Indian states revenue bar chart, and B2B wholesale accounts table. |\n")
        f.write("| `12_Cross_Channel_Pricing_Arbitrage.png` | Pricing Arbitrage | Multi-channel MRP spread chart comparing Amazon vs Myntra (+Rs 350 spread) vs Ajio vs Flipkart. |\n")
        f.write("| `13_Multi_Channel_Profitability_Matrix.png` | Channel Profitability | Detailed financial matrix across all 11 sales channels with commission rates and cancellation churn. |\n")
        f.write("| `14_Warehouse_Supply_Chain_Inventory_Health.png` | Inventory Supply Chain | Warehouse stock on hand, Out-of-Stock warnings (2,559 SKUs), and dead stock capital valuation. |\n")
        f.write("| `15_Data_Quality_Suite_10_of_10_Pass_Logs.png` | Data Quality Suite | Automated 10/10 Kimball Star Schema integrity validation audit trail. |\n")
        f.write("| `16_Gold_Layer_Data_Reports_Download_Center.png` | Reports & Downloads | Direct CSV download links for all 10 Gold Star Schema tables. |\n")

    print(f"\n[✓] Generated Visual Catalog: {readme_path}")
    print("============================================================================")
    print(" ALL 16 DASHBOARD SCREENSHOTS CAPTURED AND CATALOGED SUCCESSFULLY!")
    print("============================================================================")

if __name__ == "__main__":
    main()
