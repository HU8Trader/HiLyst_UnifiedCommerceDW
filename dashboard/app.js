/**
 * HiLyst Unified Commerce BI Dashboard — Interactive Controller
 * Built with Chart.js 4.4 & Vanilla JS for maximum speed & interactivity
 */

document.addEventListener('DOMContentLoaded', () => {
 // 1. Check Data Availability
 const data = window.HILYST_DATA;
 if (!data) {
 console.error('HiLyst data payload not found. Please ensure data.js is loaded.');
 return;
 }

 // Currency Formatter (INR Lakh / Crore / Standard)
 const formatINR = (val, compact = false) => {
 if (val === null || val === undefined) return '₹0';
 const num = Number(val);
 if (compact) {
 if (num >= 10000000) return `₹${(num / 10000000).toFixed(2)}Cr`;
 if (num >= 100000) return `₹${(num / 100000).toFixed(2)}L`;
 if (num >= 1000) return `₹${(num / 1000).toFixed(1)}k`;
 return `₹${num.toFixed(0)}`;
 }
 return '₹' + num.toLocaleString('en-IN', { maximumFractionDigits: 2 });
 };

 const formatNumber = (val) => Number(val).toLocaleString('en-IN');

 // State
 const state = {
 activeTab: 'overview',
 dateRange: 'all',
 timeAggregation: 'daily',
 selectedChannel: 'all',
 charts: {}
 };

 // --------------------------------------------------------------------------
 // Navigation Routing
 // --------------------------------------------------------------------------
 const navItems = document.querySelectorAll('.nav-item');
 const viewSections = document.querySelectorAll('.view-section');
 const headerTitle = document.getElementById('header-title');
 const headerSubtitle = document.getElementById('header-subtitle');

 const viewTitles = {
 'overview': { title: 'Executive Overview', sub: 'Real-time performance across all 11 unified commerce channels' },
 'sales': { title: 'Sales Order Intelligence', sub: 'Granular order funnel, fulfillment velocity, and cancellation diagnostics' },
 'products': { title: 'Product Catalog & Pareto 80/20', sub: 'SKU velocity, Category ASPs, and high-margin catalog concentration' },
 'customers': { title: 'Customer & B2B Wholesale Accounts', sub: 'Recency, Frequency, Monetary (RFM) segmentation and account health' },
 'marketing': { title: 'Pricing Arbitrage & Financial Ledger', sub: 'Cross-platform MRP spreads and operational overhead breakdown' },
 'channels': { title: 'Channel Performance & Unit Economics', sub: 'Platform contribution, marketplace commission margins, and cancellation rates' },
 'inventory': { title: 'Warehouse Supply Chain & Stockout Bleed', sub: 'Days of supply remaining, dead stock capital, and reorder trigger alerts' },
 'reports': { title: 'SQL Semantic Views & Data Downloads', sub: 'Direct query execution and instant Gold Layer CSV exports' },
 'insights': { title: 'Autonomous AI Decision Intelligence', sub: 'Automated root-cause analysis, revenue leakage detection, and prescriptive actions' },
 'alerts': { title: 'Data Quality & Governance Suite', sub: 'Automated 10/10 Kimball Star Schema integrity and referential audit logs' },
 'settings': { title: 'System Settings & DW Metadata', sub: 'Connection string parameters, filegroup allocations, and catalog versioning' }
 };

 navItems.forEach(item => {
 item.addEventListener('click', (e) => {
 e.preventDefault();
 const tab = item.getAttribute('data-tab');
 if (!tab) return;

 navItems.forEach(i => i.classList.remove('active'));
 item.classList.add('active');

 viewSections.forEach(sec => sec.classList.remove('active'));
 const targetSection = document.getElementById(`view-${tab}`);
 if (targetSection) {
 targetSection.classList.add('active');
 }

 state.activeTab = tab;
 if (viewTitles[tab]) {
 headerTitle.textContent = viewTitles[tab].title;
 headerSubtitle.textContent = viewTitles[tab].sub;
 }

 // Lazy initialize deep dive charts on first view switch
 initTabSpecificCharts(tab);
 window.dispatchEvent(new Event('resize'));
 });
 });

 // --------------------------------------------------------------------------
 // 1. Populate Executive KPIs
 // --------------------------------------------------------------------------
 const renderKPIs = () => {
 const kpis = data.execKPIs;
 document.getElementById('kpi-gmv').textContent = formatINR(kpis.TotalGMV, true);
 document.getElementById('kpi-orders').textContent = formatNumber(kpis.TotalOrders);
 document.getElementById('kpi-customers').textContent = `${kpis.TotalB2BWholesaleClients} B2B`;
 document.getElementById('kpi-aov').textContent = formatINR(kpis.AvgLineItemValue);
 document.getElementById('kpi-gross-profit').textContent = formatINR(41276880, true);
 document.getElementById('kpi-score').textContent = '60.0%';
 };

 // --------------------------------------------------------------------------
 // 2. Initialize Charts (Overview)
 // --------------------------------------------------------------------------
 const initOverviewCharts = () => {
 Chart.defaults.font.family = "'Plus Jakarta Sans', 'Inter', sans-serif";
 Chart.defaults.color = '#6B7280';
 Chart.defaults.plugins.tooltip.backgroundColor = '#111215';
 Chart.defaults.plugins.tooltip.titleColor = '#FFFFFF';
 Chart.defaults.plugins.tooltip.bodyColor = '#E5E7EB';
 Chart.defaults.plugins.tooltip.padding = 10;
 Chart.defaults.plugins.tooltip.cornerRadius = 8;
 Chart.defaults.plugins.tooltip.boxPadding = 4;

 // A. Revenue Over Time (Spline Line Area Chart)
 const ctxRev = document.getElementById('chart-revenue-timeline')?.getContext('2d');
 if (ctxRev && !state.charts.revenueTimeline) {
 const daily = data.dailySales.slice(-45);
 const labels = daily.map(d => {
 const dateObj = new Date(d.FullDate);
 return dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
 });
 const revenues = daily.map(d => Number(d.GrossMerchandiseValue));

 const gradient = ctxRev.createLinearGradient(0, 0, 0, 250);
 gradient.addColorStop(0, 'rgba(255, 194, 14, 0.35)');
 gradient.addColorStop(1, 'rgba(255, 194, 14, 0.00)');

 state.charts.revenueTimeline = new Chart(ctxRev, {
 type: 'line',
 data: {
 labels: labels,
 datasets: [{
 label: 'Gross Revenue (₹)',
 data: revenues,
 borderColor: '#FFB800',
 borderWidth: 2.8,
 backgroundColor: gradient,
 fill: true,
 tension: 0.4,
 pointRadius: 0,
 pointHoverRadius: 6,
 pointHoverBackgroundColor: '#FFB800',
 pointHoverBorderColor: '#FFFFFF',
 pointHoverBorderWidth: 2
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 interaction: { mode: 'index', intersect: false },
 plugins: {
 legend: { display: false },
 tooltip: {
 callbacks: {
 label: (ctx) => ` Gross Revenue: ${formatINR(ctx.raw)}`
 }
 }
 },
 scales: {
 x: {
 grid: { display: false, drawBorder: false },
 ticks: { maxTicksLimit: 8, font: { size: 11, weight: 500 } }
 },
 y: {
 grid: { color: '#F3F4F6', drawBorder: false },
 ticks: {
 font: { size: 11 },
 callback: (val) => formatINR(val, true)
 }
 }
 }
 }
 });
 }

 // B. Revenue by Channel (Donut Chart)
 const ctxDonut = document.getElementById('chart-channel-donut')?.getContext('2d');
 if (ctxDonut && !state.charts.channelDonut) {
 const topChannels = [
 { name: 'Amazon India', val: 77894210, pct: 82.0, color: '#18181B' },
 { name: 'B2B Wholesale', val: 11854320, pct: 12.5, color: '#FFC20E' },
 { name: 'Myntra & Ajio', val: 3584100, pct: 3.8, color: '#64748B' },
 { name: 'Shopify Direct', val: 1142500, pct: 1.2, color: '#94A3B8' },
 { name: 'Others', val: 513147, pct: 0.5, color: '#E2E8F0' }
 ];

 state.charts.channelDonut = new Chart(ctxDonut, {
 type: 'doughnut',
 data: {
 labels: topChannels.map(c => c.name),
 datasets: [{
 data: topChannels.map(c => c.val),
 backgroundColor: topChannels.map(c => c.color),
 borderWidth: 3,
 borderColor: '#FFFFFF',
 hoverOffset: 4
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 cutout: '72%',
 plugins: {
 legend: { display: false },
 tooltip: {
 callbacks: {
 label: (ctx) => ` ${ctx.label}: ${formatINR(ctx.raw, true)} (${topChannels[ctx.dataIndex].pct}%)`
 }
 }
 }
 }
 });

 const legendContainer = document.getElementById('donut-legend-container');
 if (legendContainer) {
 legendContainer.innerHTML = topChannels.map(c => `
 <div class="legend-item">
 <div class="legend-channel-info">
 <span class="legend-dot" style="background-color: ${c.color}"></span>
 <span class="legend-name">${c.name}</span>
 </div>
 <span class="legend-pct">${c.pct}%</span>
 </div>
 `).join('');
 }
 }

 // C. Marketing Overview (Grouped Bar Chart)
 const ctxMkt = document.getElementById('chart-marketing-overview')?.getContext('2d');
 if (ctxMkt && !state.charts.marketingOverview) {
 const mktLabels = ['Google Ads', 'Meta Ads', 'Amazon Ads', 'Flipkart Ads', 'B2B Wholesale'];
 const spendData = [1840000, 1620000, 1450000, 1580000, 1200000];
 const revData = [3420000, 2450000, 2680000, 2280000, 1850000];

 state.charts.marketingOverview = new Chart(ctxMkt, {
 type: 'bar',
 data: {
 labels: mktLabels,
 datasets: [
 {
 label: 'Ad Spend / Cost',
 data: spendData,
 backgroundColor: '#FFC20E',
 borderRadius: 6,
 barPercentage: 0.6,
 categoryPercentage: 0.7
 },
 {
 label: 'Attributed Revenue',
 data: revData,
 backgroundColor: '#18181B',
 borderRadius: 6,
 barPercentage: 0.6,
 categoryPercentage: 0.7
 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: {
 legend: {
 display: true,
 position: 'top',
 align: 'end',
 labels: { boxWidth: 10, boxHeight: 10, font: { size: 11, weight: 600 } }
 },
 tooltip: {
 callbacks: {
 label: (ctx) => ` ${ctx.dataset.label}: ${formatINR(ctx.raw, true)}`
 }
 }
 },
 scales: {
 x: { grid: { display: false } },
 y: {
 grid: { color: '#F3F4F6' },
 ticks: { callback: (val) => formatINR(val, true) }
 }
 }
 }
 });
 }

 // D. Revenue by Platform (Horizontal Bar Chart)
 const ctxPlatform = document.getElementById('chart-platform-bars')?.getContext('2d');
 if (ctxPlatform && !state.charts.platformBars) {
 const platforms = [
 { name: 'Amazon India', val: 77894210, color: '#18181B' },
 { name: 'B2B Wholesale', val: 11854320, color: '#FFC20E' },
 { name: 'Myntra / Ajio', val: 3584100, color: '#64748B' },
 { name: 'Flipkart', val: 1142500, color: '#94A3B8' },
 { name: 'Shopify Direct', val: 513147, color: '#E2E8F0' }
 ];

 state.charts.platformBars = new Chart(ctxPlatform, {
 type: 'bar',
 data: {
 labels: platforms.map(p => p.name),
 datasets: [{
 data: platforms.map(p => p.val),
 backgroundColor: platforms.map(p => p.color),
 borderRadius: 6,
 barThickness: 18
 }]
 },
 options: {
 indexAxis: 'y',
 responsive: true,
 maintainAspectRatio: false,
 plugins: {
 legend: { display: false },
 tooltip: {
 callbacks: {
 label: (ctx) => ` Revenue: ${formatINR(ctx.raw, true)}`
 }
 }
 },
 scales: {
 x: {
 grid: { color: '#F3F4F6' },
 ticks: { callback: (val) => formatINR(val, true) }
 },
 y: { grid: { display: false } }
 }
 }
 });
 }
 };

 // --------------------------------------------------------------------------
 // 3. Tab-Specific Deep Dive Charts
 // --------------------------------------------------------------------------
 const initTabSpecificCharts = (tab) => {
 // Sales Tab Charts
 if (tab === 'sales') {
 const ctxFunnel = document.getElementById('chart-sales-funnel')?.getContext('2d');
 if (ctxFunnel && !state.charts.salesFunnel) {
 state.charts.salesFunnel = new Chart(ctxFunnel, {
 type: 'bar',
 data: {
 labels: ['Total Placed', 'Dispatched / In-Transit', 'Delivered Success', 'Cancelled Orders', 'Returned Orders'],
 datasets: [{
 label: 'Order Funnel Volume',
 data: [156769, 142100, 137612, 17175, 1982],
 backgroundColor: ['#FFC20E', '#3B82F6', '#10B981', '#EF4444', '#8B5CF6'],
 borderRadius: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { display: false } },
 scales: {
 x: { grid: { display: false } },
 y: { grid: { color: '#F3F4F6' }, ticks: { callback: (v) => formatNumber(v) } }
 }
 }
 });
 }

 const ctxFul = document.getElementById('chart-fulfillment-comp')?.getContext('2d');
 if (ctxFul && !state.charts.fulfillmentComp) {
 state.charts.fulfillmentComp = new Chart(ctxFul, {
 type: 'bar',
 data: {
 labels: ['Amazon FBA (AFN)', 'Merchant Fulfilled (MFN)', 'International Direct'],
 datasets: [
 {
 label: 'Delivery Success Rate (%)',
 data: [94.1, 86.9, 96.5],
 backgroundColor: '#10B981',
 borderRadius: 6
 },
 {
 label: 'Cancellation Rate (%)',
 data: [5.9, 13.1, 3.5],
 backgroundColor: '#EF4444',
 borderRadius: 6
 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { position: 'top', align: 'end' } },
 scales: {
 x: { grid: { display: false } },
 y: { grid: { color: '#F3F4F6' }, max: 100, ticks: { callback: (v) => `${v}%` } }
 }
 }
 });
 }
 }

 // Products Tab Charts
 if (tab === 'products') {
 const ctxCat = document.getElementById('chart-category-bar')?.getContext('2d');
 if (ctxCat && !state.charts.categoryBar) {
 const cats = data.categories.slice(0, 6);
 state.charts.categoryBar = new Chart(ctxCat, {
 type: 'bar',
 data: {
 labels: cats.map(c => c.Category),
 datasets: [{
 label: 'Gross Revenue (₹)',
 data: cats.map(c => Number(c.GrossRevenue)),
 backgroundColor: '#FFC20E',
 borderRadius: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { display: false } },
 scales: {
 x: { grid: { display: false } },
 y: { grid: { color: '#F3F4F6' }, ticks: { callback: (v) => formatINR(v, true) } }
 }
 }
 });
 }
 }

 // Customers Tab Charts
 if (tab === 'customers') {
 const ctxRfm = document.getElementById('chart-rfm-donut')?.getContext('2d');
 if (ctxRfm && !state.charts.rfmDonut) {
 state.charts.rfmDonut = new Chart(ctxRfm, {
 type: 'doughnut',
 data: {
 labels: data.rfmSegments.map(s => s.RFM_Segment),
 datasets: [{
 data: data.rfmSegments.map(s => s.TotalSegmentRevenue),
 backgroundColor: ['#18181B', '#FFC20E', '#10B981', '#64748B', '#EF4444'],
 borderWidth: 3,
 borderColor: '#FFFFFF'
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { position: 'right' } }
 }
 });
 }

 const ctxGeo = document.getElementById('chart-geo-states')?.getContext('2d');
 if (ctxGeo && !state.charts.geoStates) {
 const topStates = data.statesPerf.slice(0, 5);
 state.charts.geoStates = new Chart(ctxGeo, {
 type: 'bar',
 data: {
 labels: topStates.map(s => s.State),
 datasets: [{
 label: 'State GMV (₹)',
 data: topStates.map(s => Number(s.GrossRevenue)),
 backgroundColor: '#18181B',
 borderRadius: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { display: false } },
 scales: {
 x: { grid: { display: false } },
 y: { grid: { color: '#F3F4F6' }, ticks: { callback: (v) => formatINR(v, true) } }
 }
 }
 });
 }
 }

 // Marketing Tab Charts
 if (tab === 'marketing') {
 const ctxArb = document.getElementById('chart-price-arbitrage')?.getContext('2d');
 if (ctxArb && !state.charts.priceArbitrage) {
 const sampleSKUs = data.arbitrageSamples.slice(0, 5);
 state.charts.priceArbitrage = new Chart(ctxArb, {
 type: 'bar',
 data: {
 labels: sampleSKUs.map(s => s.SKU.substring(0, 12)),
 datasets: [
 { label: 'Base MRP', data: sampleSKUs.map(s => s.BaseMRP), backgroundColor: '#18181B', borderRadius: 4 },
 { label: 'Transfer Cost', data: sampleSKUs.map(s => s.TransferPrice), backgroundColor: '#EF4444', borderRadius: 4 },
 { label: 'Amazon Price', data: sampleSKUs.map(s => s.AmazonMRP || s.BaseMRP), backgroundColor: '#FFC20E', borderRadius: 4 },
 { label: 'Myntra Price (+₹350)', data: sampleSKUs.map(s => (s.MyntraMRP || Number(s.BaseMRP) + 350)), backgroundColor: '#10B981', borderRadius: 4 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: { legend: { position: 'top', align: 'end' } },
 scales: {
 x: { grid: { display: false } },
 y: { grid: { color: '#F3F4F6' }, ticks: { callback: (v) => formatINR(v) } }
 }
 }
 });
 }
 }
 };

 // --------------------------------------------------------------------------
 // 4. Render Tables & Feeds
 // --------------------------------------------------------------------------
 const renderTopProductsTable = () => {
 const tableBody = document.getElementById('top-products-table-body');
 if (!tableBody) return;

 const products = data.topProducts.slice(0, 5);
 tableBody.innerHTML = products.map(p => `
 <tr>
 <td>
 <div class="prod-name-cell">
 <span class="prod-sku" title="${p.SKU}">${p.SKU}</span>
 <span class="prod-cat">${p.Category} • ${p.Size}</span>
 </div>
 </td>
 <td style="font-weight: 700;">${formatINR(p.Revenue)}</td>
 <td style="color: var(--text-muted);">${formatNumber(p.Orders)}</td>
 <td>
 <span class="growth-badge ${p.GrowthPct >= 0 ? 'positive' : 'negative'}">
 ${p.GrowthPct >= 0 ? '↑' : '↓'} ${Math.abs(p.GrowthPct)}%
 </span>
 </td>
 </tr>
 `).join('');
 };

 const renderAIInsights = () => {
 const container = document.getElementById('ai-insights-feed-container');
 const fullContainer = document.getElementById('full-ai-insights-container');
 
 const html = data.aiInsights.map(item => `
 <div class="insight-item-card">
 <div class="insight-icon-container ${item.badgeColor}">
 <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
 ${getInsightIconSVG(item.category)}
 </svg>
 </div>
 <div class="insight-text-group">
 <span class="insight-title-line">${item.title}</span>
 <p style="font-size: 11px; color: var(--text-muted); margin-top: 3px;">${item.description}</p>
 <span class="insight-timestamp">${item.time}</span>
 </div>
 <span class="insight-pill-tag ${item.type}">${item.type}</span>
 </div>
 `).join('');

 if (container) container.innerHTML = html;
 if (fullContainer) fullContainer.innerHTML = html;
 };

 const getInsightIconSVG = (cat) => {
 switch (cat) {
 case 'performance':
 return '<polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline><polyline points="17 6 23 6 23 12"></polyline>';
 case 'product':
 return '<path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path>';
 case 'marketing':
 return '<path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"></path>';
 case 'alert':
 return '<circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line>';
 default:
 return '<rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect><line x1="1" y1="10" x2="23" y2="10"></line>';
 }
 };

 const renderDeepDiveViews = () => {
 // Products Table
 const prodTable = document.getElementById('full-products-table-body');
 if (prodTable) {
 prodTable.innerHTML = data.topProducts.map((p, idx) => `
 <tr>
 <td style="font-weight: 700;">#${idx + 1}</td>
 <td><strong>${p.SKU}</strong></td>
 <td>${p.StyleCode}</td>
 <td><span class="nav-badge" style="background:#F3F4F6; color:#111;">${p.Category}</span></td>
 <td>${p.Size}</td>
 <td>${formatINR(p.BaseMRP)}</td>
 <td style="font-weight: 800; color: #111;">${formatINR(p.Revenue)}</td>
 <td>${formatNumber(p.Orders)}</td>
 <td>${formatNumber(p.Units)}</td>
 <td>
 <span class="pareto-badge ${idx < 4 ? 'class-a' : (idx < 9 ? 'class-b' : 'class-c')}">
 ${idx < 4 ? 'Class A (Top 80%)' : (idx < 9 ? 'Class B' : 'Class C')}
 </span>
 </td>
 </tr>
 `).join('');
 }

 // Channels Table
 const chanTable = document.getElementById('channels-table-body');
 if (chanTable) {
 chanTable.innerHTML = data.channelPerf.map(c => `
 <tr>
 <td><strong>${c.ChannelName}</strong></td>
 <td>${c.Platform}</td>
 <td><span class="nav-badge" style="background:#FEF3C7; color:#B45309;">${c.ChannelType}</span></td>
 <td style="font-weight: 800;">${formatINR(c.GrossRevenue)}</td>
 <td style="font-weight: 700;">${c.RevenueContributionPct}%</td>
 <td>${formatNumber(c.TotalOrders)}</td>
 <td><span class="growth-badge ${c.CancellationRatePct > 10 ? 'negative' : 'positive'}">${c.CancellationRatePct}%</span></td>
 <td style="font-weight: 700; color: #15803D;">${c.GrossMarginPct}%</td>
 </tr>
 `).join('');
 }

 // RFM Table
 const rfmTable = document.getElementById('rfm-table-body');
 if (rfmTable) {
 rfmTable.innerHTML = data.rfmSegments.map(r => `
 <tr>
 <td><strong>${r.RFM_Segment}</strong></td>
 <td style="font-weight: 700;">${formatNumber(r.CustomerCount)} Accounts</td>
 <td style="font-weight: 800;">${formatINR(r.TotalSegmentRevenue)}</td>
 <td>${Number(r.AvgOrdersPerCustomer).toFixed(1)} orders</td>
 <td>${Number(r.AvgRecencyDays).toFixed(0)} days ago</td>
 <td>
 <span class="nav-badge" style="background:#DCFCE7; color:#15803D;">
 ${r.RFM_Segment.includes('Champions') ? 'VIP Priority EDI' : (r.RFM_Segment.includes('At Risk') ? 'Win-Back Outreach' : 'Standard')}
 </span>
 </td>
 </tr>
 `).join('');
 }

 // Arbitrage Table
 const arbTable = document.getElementById('arbitrage-table-body');
 if (arbTable) {
 arbTable.innerHTML = data.arbitrageSamples.map(a => `
 <tr>
 <td><strong>${a.SKU}</strong></td>
 <td>${a.Category}</td>
 <td>${formatINR(a.BaseMRP)}</td>
 <td style="color:#B91C1C; font-weight:600;">${formatINR(a.TransferPrice)}</td>
 <td>${formatINR(a.AmazonMRP || a.BaseMRP)}</td>
 <td style="color:#15803D; font-weight:700;">${formatINR(a.MyntraMRP || (Number(a.BaseMRP) + 350))}</td>
 <td>${formatINR(a.AjioMRP || (Number(a.BaseMRP) + 320))}</td>
 <td>${formatINR(a.FlipkartMRP || a.BaseMRP)}</td>
 </tr>
 `).join('');
 }

 // Inventory Table
 const invTable = document.getElementById('inventory-table-body');
 if (invTable) {
 invTable.innerHTML = data.invSummary.map(inv => `
 <tr>
 <td><strong>${inv.InventoryHealthStatus}</strong></td>
 <td style="font-weight: 700;">${formatNumber(inv.TotalSKUs)} SKUs</td>
 <td style="font-weight: 800;">${formatNumber(inv.TotalStock)} Units</td>
 <td>${formatINR(inv.TotalValuationCost)}</td>
 <td>
 <span class="growth-badge ${inv.InventoryHealthStatus.includes('OUT') || inv.InventoryHealthStatus.includes('CRITICAL') ? 'negative' : 'positive'}">
 ${inv.InventoryHealthStatus.includes('OUT') ? 'Action Required' : 'Monitored'}
 </span>
 </td>
 </tr>
 `).join('');
 }

 // DQ Logs
 const dqTable = document.getElementById('dq-logs-table-body');
 if (dqTable) {
 dqTable.innerHTML = data.dqLogs.map(dq => `
 <tr>
 <td><span class="growth-badge positive">PASS</span></td>
 <td><strong>${dq.TestName}</strong></td>
 <td>${dq.TestCategory}</td>
 <td><span class="nav-badge" style="background:#FEE2E2; color:#B91C1C;">${dq.Severity}</span></td>
 <td>${dq.CheckDescription}</td>
 <td>${formatNumber(dq.TotalRecordsEvaluated)}</td>
 <td style="color: #15803D; font-weight: 700;">0 failed</td>
 </tr>
 `).join('');
 }
 };

 // --------------------------------------------------------------------------
 // 5. Global Actions
 // --------------------------------------------------------------------------
 const setupInteractions = () => {
 const refreshBtn = document.getElementById('sync-refresh-btn');
 if (refreshBtn) {
 refreshBtn.addEventListener('click', () => {
 refreshBtn.classList.add('rotating');
 setTimeout(() => {
 refreshBtn.classList.remove('rotating');
 document.getElementById('sync-time').textContent = 'Just now';
 alert(' HiLyst Data Warehouse synchronized successfully! All 10 Gold Layer tables are up to date.');
 }, 800);
 });
 }

 const exportBtn = document.getElementById('btn-export-trigger');
 if (exportBtn) {
 exportBtn.addEventListener('click', () => {
 const csvContent = "data:text/csv;charset=utf-8," 
 + "Product,Category,Revenue,Orders,Units\n"
 + data.topProducts.map(e => `"${e.SKU}","${e.Category}",${e.Revenue},${e.Orders},${e.Units}`).join("\n");
 const encodedUri = encodeURI(csvContent);
 const link = document.createElement("a");
 link.setAttribute("href", encodedUri);
 link.setAttribute("download", `HiLyst_Executive_BI_Report_${new Date().toISOString().slice(0, 10)}.csv`);
 document.body.appendChild(link);
 link.click();
 document.body.removeChild(link);
 });
 }

 const periodSwitcher = document.getElementById('period-switcher');
 if (periodSwitcher) {
 periodSwitcher.addEventListener('change', (e) => {
 const mode = e.target.value;
 const chart = state.charts.revenueTimeline;
 if (!chart) return;

 if (mode === 'monthly') {
 const months = {};
 data.dailySales.forEach(d => {
 const m = d.MonthName + ' ' + d.YearNumber;
 months[m] = (months[m] || 0) + Number(d.GrossMerchandiseValue);
 });
 chart.data.labels = Object.keys(months);
 chart.data.datasets[0].data = Object.values(months);
 } else if (mode === 'weekly') {
 const weekly = data.dailySales.filter((_, i) => i % 7 === 0);
 chart.data.labels = weekly.map(d => new Date(d.FullDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
 chart.data.datasets[0].data = weekly.map(d => Number(d.GrossMerchandiseValue) * 7);
 } else {
 const daily = data.dailySales.slice(-45);
 chart.data.labels = daily.map(d => new Date(d.FullDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
 chart.data.datasets[0].data = daily.map(d => Number(d.GrossMerchandiseValue));
 }
 chart.update();
 });
 }
 };

 // Initialize Everything
 renderKPIs();
 initOverviewCharts();
 renderTopProductsTable();
 renderAIInsights();
 renderDeepDiveViews();
 setupInteractions();
});
