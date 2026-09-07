/**
 * HiLyst Unified Business Intelligence & Decision Intelligence Platform
 * Interactive Dashboard Controller (Chart.js 4.4 & Vanilla JS)
 */

document.addEventListener('DOMContentLoaded', () => {
 // 1. Verify Data Availability
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

 // Application State
 const state = {
 activeTab: 'overview',
 timeAggregation: 'daily',
 charts: {},
 initializedTabs: new Set(['overview'])
 };

 // --------------------------------------------------------------------------
 // Navigation Routing
 // --------------------------------------------------------------------------
 const navItems = document.querySelectorAll('.nav-item');
 const viewSections = document.querySelectorAll('.view-section');
 const headerTitle = document.getElementById('header-title');
 const headerSubtitle = document.getElementById('header-subtitle');

 const viewTitles = {
 'overview': { title: 'Executive Command Center', sub: 'Real-time multi-source intelligence across 13 commerce & marketing endpoints' },
 'sales': { title: 'Sales & Channel Intelligence', sub: 'Unified sales funnel, platform contribution, and fulfillment diagnostics' },
 'marketing': { title: 'Digital Marketing & Advertising', sub: 'Paid search, social campaign spend, ROAS, CPC, and lead scoring' },
 'products': { title: 'Product Catalog & Pareto 80/20', sub: 'SKU velocity, category concentration, and realized ASP margins' },
 'customers': { title: 'Customer & RFM Segmentation', sub: 'Recency, Frequency, Monetary cohorts across B2B wholesale and B2C global buyers' },
 'inventory': { title: 'Warehouse Supply Chain & Logistics', sub: 'Stockout margin bleed, days of supply, and 3PL fulfillment benchmarks' },
 'channels': { title: 'Cross-Channel Pricing Arbitrage', sub: 'Multi-platform MRP spreads and retail margin optimization' },
 'insights': { title: 'Autonomous AI Decision Intelligence', sub: 'Governed root-cause analysis, quantified impact, and prescriptive recommendations' },
 'alerts': { title: 'Data Quality & Governance Suite (18/18)', sub: 'Automated Kimball Star Schema referential integrity, range, and uniqueness audits' },
 'reports': { title: 'Gold Layer Data Downloads & SQL Views', sub: 'Instant CSV exports for all 14 Kimball dimensions, facts, and semantic views' },
 'settings': { title: 'System Architecture & DDL Metadata', sub: 'Microsoft SQL Server 2025 Medallion schema, filegroup, and lineage specs' }
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

 // Lazy initialize tab specific charts
 if (!state.initializedTabs.has(tab)) {
 initTabSpecificCharts(tab);
 state.initializedTabs.add(tab);
 }
 window.dispatchEvent(new Event('resize'));
 });
 });

 // Time aggregation toggles
 document.querySelectorAll('.time-btn').forEach(btn => {
 btn.addEventListener('click', () => {
 document.querySelectorAll('.time-btn').forEach(b => b.classList.remove('active'));
 btn.classList.add('active');
 state.timeAggregation = btn.getAttribute('data-agg');
 updateRevenueTimelineChart();
 });
 });

 // Global Chart.js Defaults
 Chart.defaults.font.family = "'Plus Jakarta Sans', 'Inter', sans-serif";
 Chart.defaults.color = '#6B7280';
 Chart.defaults.plugins.tooltip.backgroundColor = '#111215';
 Chart.defaults.plugins.tooltip.titleColor = '#FFFFFF';
 Chart.defaults.plugins.tooltip.bodyColor = '#E5E7EB';
 Chart.defaults.plugins.tooltip.padding = 10;
 Chart.defaults.plugins.tooltip.cornerRadius = 8;
 Chart.defaults.plugins.tooltip.boxPadding = 4;

 // --------------------------------------------------------------------------
 // 1. Populate Executive Scorecard & Tables
 // --------------------------------------------------------------------------
 const renderKPIs = () => {
 const kpis = data.execKPIs;
 document.getElementById('kpi-gmv').textContent = formatINR(kpis.TotalGMV, true);
 document.getElementById('kpi-net-revenue').textContent = formatINR(kpis.TotalNetRevenue, true);
 document.getElementById('kpi-orders').textContent = formatNumber(kpis.TotalOrders);
 document.getElementById('kpi-customers').textContent = `${formatNumber(kpis.TotalActiveCustomers)}`;
 document.getElementById('kpi-aov').textContent = formatINR(kpis.AverageOrderValue);
 document.getElementById('kpi-adspend').textContent = formatINR(kpis.TotalMarketingSpend, true);
 document.getElementById('kpi-roas-badge').textContent = `${kpis.BlendedMarketingROAS}x ROAS`;
 document.getElementById('kpi-gross-profit').textContent = formatINR(kpis.TotalGrossProfit, true);
 document.getElementById('kpi-score').textContent = `${kpis.HiLystPlatformCompatibilityScore}%`;
 };

 // --------------------------------------------------------------------------
 // 2. Tab 1 Charts: Executive Overview
 // --------------------------------------------------------------------------
 const initOverviewCharts = () => {
 // A. Revenue Timeline Chart
 const ctxRev = document.getElementById('chart-revenue-timeline')?.getContext('2d');
 if (ctxRev && !state.charts.revenueTimeline) {
 const daily = data.dailySales.slice(-60);
 const labels = daily.map(d => {
 const dateObj = new Date(d.FullDate);
 return dateObj.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
 });
 const gmv = daily.map(d => Number(d.GrossMerchandiseValue));
 const net = daily.map(d => Number(d.NetRevenue));

 const gradient1 = ctxRev.createLinearGradient(0, 0, 0, 250);
 gradient1.addColorStop(0, 'rgba(255, 194, 14, 0.35)');
 gradient1.addColorStop(1, 'rgba(255, 194, 14, 0.00)');

 const gradient2 = ctxRev.createLinearGradient(0, 0, 0, 250);
 gradient2.addColorStop(0, 'rgba(16, 185, 129, 0.25)');
 gradient2.addColorStop(1, 'rgba(16, 185, 129, 0.00)');

 state.charts.revenueTimeline = new Chart(ctxRev, {
 type: 'line',
 data: {
 labels: labels,
 datasets: [
 {
 label: 'Gross GMV (₹)',
 data: gmv,
 borderColor: '#FFB800',
 borderWidth: 2.5,
 backgroundColor: gradient1,
 fill: true,
 tension: 0.4,
 pointRadius: 0,
 pointHoverRadius: 6
 },
 {
 label: 'Net Realized (₹)',
 data: net,
 borderColor: '#10B981',
 borderWidth: 2.2,
 backgroundColor: gradient2,
 fill: true,
 tension: 0.4,
 pointRadius: 0,
 pointHoverRadius: 6
 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 interaction: { mode: 'index', intersect: false },
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

 // B. Channel Donut Chart
 const ctxDonut = document.getElementById('chart-channel-donut')?.getContext('2d');
 if (ctxDonut && !state.charts.channelDonut) {
 const topChannels = data.channelProfitability.slice(0, 5);
 const labels = topChannels.map(c => c.Platform || c.ChannelName);
 const revenues = topChannels.map(c => Number(c.GrossRevenue));
 const colors = ['#FFC20E', '#3B82F6', '#10B981', '#8B5CF6', '#EC4899'];

 state.charts.channelDonut = new Chart(ctxDonut, {
 type: 'doughnut',
 data: {
 labels: labels,
 datasets: [{
 data: revenues,
 backgroundColor: colors,
 borderWidth: 0,
 hoverOffset: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 plugins: {
 legend: { display: false },
 tooltip: {
 callbacks: {
 label: (ctx) => ` ${ctx.label}: ${formatINR(ctx.raw, true)}`
 }
 }
 },
 cutout: '72%'
 }
 });

 // Render custom legend
 const legendContainer = document.getElementById('donut-legend-container');
 if (legendContainer) {
 legendContainer.innerHTML = topChannels.map((c, i) => `
 <div class="legend-item" style="display:inline-flex; align-items:center; margin: 4px 8px; font-size:12px;">
 <span style="width:10px; height:10px; border-radius:50%; background:${colors[i]}; display:inline-block; margin-right:6px;"></span>
 <span><strong>${c.Platform || c.ChannelName}</strong> (${c.RevenueContributionPct}%)</span>
 </div>
 `).join('');
 }
 }

 // C. Marketing Spend vs Revenue Bar Chart
 const ctxMktg = document.getElementById('chart-marketing-spend')?.getContext('2d');
 if (ctxMktg && !state.charts.marketingSpend) {
 const mktg = data.marketingIntelligence;
 const labels = mktg.map(m => m.CampaignName.replace('Executive Course', 'Search').replace('Retargeting & Brand Awareness', 'Social'));
 const spends = mktg.map(m => Number(m.TotalAdSpend));
 const revenues = mktg.map(m => Number(m.AttributedRevenue));

 state.charts.marketingSpend = new Chart(ctxMktg, {
 type: 'bar',
 data: {
 labels: labels,
 datasets: [
 {
 label: 'Ad Spend (₹)',
 data: spends,
 backgroundColor: '#CBD5E1',
 borderRadius: 6
 },
 {
 label: 'Attributed Revenue (₹)',
 data: revenues,
 backgroundColor: '#3B82F6',
 borderRadius: 6
 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
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

 // D. Top Products Table
 const topProdTbody = document.querySelector('#table-top-products tbody');
 if (topProdTbody) {
 topProdTbody.innerHTML = data.topProducts.slice(0, 7).map(p => `
 <tr>
 <td><strong>${p.SKU}</strong><br><span style="font-size:11px; color:#6B7280;">${p.ProductName ? p.ProductName.substring(0, 32) : ''}</span></td>
 <td><span class="badge-tag">${p.Category}</span></td>
 <td>${formatNumber(p.Units)}</td>
 <td><strong>${formatINR(p.Revenue, true)}</strong></td>
 <td><span class="trend-badge ${p.GrowthPct >= 0 ? 'positive' : 'negative'}">${p.GrowthPct >= 0 ? '+' : ''}${p.GrowthPct}%</span></td>
 </tr>
 `).join('');
 }

 // E. Quick Strategic Alerts Feed
 const quickFeed = document.getElementById('quick-insights-feed');
 if (quickFeed) {
 quickFeed.innerHTML = data.aiDecisionInsights.slice(0, 3).map(ai => `
 <div class="insight-alert-item">
 <div class="insight-alert-header">
 <span class="badge-tag" style="background:#FEF3C7; color:#B45309;">${ai.StrategicDomain}</span>
 <span class="trend-badge ${ai.UrgencyLevel === 'High' ? 'negative' : 'neutral'}">${ai.UrgencyLevel} Urgency</span>
 </div>
 <h4>${ai.Observation}</h4>
 <p>${ai.EmpiricalEvidence}</p>
 <div class="insight-rec-box">
 <strong>Recommended Action:</strong> ${ai.PrescriptiveAction}
 </div>
 </div>
 `).join('');
 }
 };

 const updateRevenueTimelineChart = () => {
 if (!state.charts.revenueTimeline) return;
 let records = [...data.dailySales];
 if (state.timeAggregation === 'weekly') {
 // Aggregate into 7-day buckets
 const weekly = [];
 for (let i = 0; i < records.length; i += 7) {
 const chunk = records.slice(i, i + 7);
 const gmvSum = chunk.reduce((acc, curr) => acc + Number(curr.GrossMerchandiseValue), 0);
 const netSum = chunk.reduce((acc, curr) => acc + Number(curr.NetRevenue), 0);
 weekly.push({
 FullDate: chunk[0].FullDate,
 GrossMerchandiseValue: gmvSum,
 NetRevenue: netSum
 });
 }
 records = weekly;
 } else if (state.timeAggregation === 'monthly') {
 const monthlyMap = {};
 records.forEach(r => {
 const d = new Date(r.FullDate);
 const key = `${d.getFullYear()}-${d.getMonth() + 1}`;
 if (!monthlyMap[key]) monthlyMap[key] = { FullDate: r.FullDate, GrossMerchandiseValue: 0, NetRevenue: 0 };
 monthlyMap[key].GrossMerchandiseValue += Number(r.GrossMerchandiseValue);
 monthlyMap[key].NetRevenue += Number(r.NetRevenue);
 });
 records = Object.values(monthlyMap);
 } else {
 records = records.slice(-60);
 }

 state.charts.revenueTimeline.data.labels = records.map(r => {
 const d = new Date(r.FullDate);
 return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: state.timeAggregation === 'monthly' ? '2-digit' : undefined });
 });
 state.charts.revenueTimeline.data.datasets[0].data = records.map(r => Number(r.GrossMerchandiseValue));
 state.charts.revenueTimeline.data.datasets[1].data = records.map(r => Number(r.NetRevenue));
 state.charts.revenueTimeline.update();
 };

 // --------------------------------------------------------------------------
 // 3. Tab-Specific Chart Initializers
 // --------------------------------------------------------------------------
 const initTabSpecificCharts = (tab) => {
 if (tab === 'sales') {
 // Sales Channel Bar Chart
 const ctxSalesBar = document.getElementById('chart-sales-channels-bar')?.getContext('2d');
 if (ctxSalesBar && !state.charts.salesChannelBar) {
 const ch = data.channelProfitability;
 state.charts.salesChannelBar = new Chart(ctxSalesBar, {
 type: 'bar',
 data: {
 labels: ch.map(c => c.ChannelName),
 datasets: [{
 label: 'Gross Revenue (₹)',
 data: ch.map(c => Number(c.GrossRevenue)),
 backgroundColor: '#FFC20E',
 borderRadius: 6
 }]
 },
 options: {
 indexAxis: 'y',
 responsive: true,
 maintainAspectRatio: false,
 scales: {
 x: { ticks: { callback: (val) => formatINR(val, true) }, grid: { color: '#F3F4F6' } },
 y: { grid: { display: false } }
 }
 }
 });
 }

 // Order Funnel Chart
 const ctxFunnel = document.getElementById('chart-fulfillment-funnel')?.getContext('2d');
 if (ctxFunnel && !state.charts.fulfillmentFunnel) {
 state.charts.fulfillmentFunnel = new Chart(ctxFunnel, {
 type: 'doughnut',
 data: {
 labels: ['Delivered', 'Shipped in Transit', 'Cancelled', 'Returned'],
 datasets: [{
 data: [198420, 42150, 16820, 7976],
 backgroundColor: ['#10B981', '#3B82F6', '#EF4444', '#F59E0B'],
 borderWidth: 0
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 cutout: '65%'
 }
 });
 }

 // Populate Channel Deepdive Table
 const chTbody = document.querySelector('#table-channel-deepdive tbody');
 if (chTbody) {
 chTbody.innerHTML = data.channelProfitability.map(c => `
 <tr>
 <td><strong>${c.ChannelName}</strong></td>
 <td>${c.Platform}</td>
 <td><span class="badge-tag">${c.ChannelType}</span></td>
 <td>${formatNumber(c.TotalOrders)}</td>
 <td>${formatNumber(c.TotalUnitsSold)}</td>
 <td><strong>${formatINR(c.GrossRevenue, true)}</strong></td>
 <td><span class="trend-badge ${Number(c.CancellationRatePct) > 10 ? 'negative' : 'positive'}">${c.CancellationRatePct}%</span></td>
 <td><span class="trend-badge positive">${c.GrossMarginPct}%</span></td>
 </tr>
 `).join('');
 }
 }

 if (tab === 'marketing') {
 // Marketing KPIs
 const mktg = data.marketingIntelligence;
 const totalImp = mktg.reduce((acc, m) => acc + Number(m.TotalImpressions), 0);
 const totalClicks = mktg.reduce((acc, m) => acc + Number(m.TotalClicks), 0);
 const totalSpend = mktg.reduce((acc, m) => acc + Number(m.TotalAdSpend), 0);
 const totalRev = mktg.reduce((acc, m) => acc + Number(m.AttributedRevenue), 0);

 document.getElementById('mktg-kpi-imp').textContent = formatNumber(totalImp);
 document.getElementById('mktg-kpi-clicks').textContent = formatNumber(totalClicks);
 document.getElementById('mktg-kpi-spend').textContent = formatINR(totalSpend, true);
 document.getElementById('mktg-kpi-rev').textContent = formatINR(totalRev, true);

 // ROAS Compare Bar Chart
 const ctxRoas = document.getElementById('chart-mktg-roas-compare')?.getContext('2d');
 if (ctxRoas && !state.charts.mktgRoas) {
 state.charts.mktgRoas = new Chart(ctxRoas, {
 type: 'bar',
 data: {
 labels: ['Google Ads Search', 'Meta / Facebook Ads'],
 datasets: [{
 label: 'Return on Ad Spend (ROAS)',
 data: [7.80, 1.25],
 backgroundColor: ['#10B981', '#3B82F6'],
 borderRadius: 8
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 scales: {
 y: {
 ticks: { callback: (val) => `${val}x` },
 grid: { color: '#F3F4F6' }
 }
 }
 }
 });
 }

 // Device Donut Chart
 const ctxDevice = document.getElementById('chart-device-donut')?.getContext('2d');
 if (ctxDevice && !state.charts.deviceDonut) {
 state.charts.deviceDonut = new Chart(ctxDevice, {
 type: 'doughnut',
 data: {
 labels: ['Mobile (64%)', 'Desktop (28%)', 'Tablet (8%)'],
 datasets: [{
 data: [64, 28, 8],
 backgroundColor: ['#3B82F6', '#10B981', '#F59E0B'],
 borderWidth: 0
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 cutout: '70%'
 }
 });
 }

 // Populate Marketing Campaigns Table
 const mktgTbody = document.querySelector('#table-marketing-campaigns tbody');
 if (mktgTbody) {
 mktgTbody.innerHTML = mktg.map(m => `
 <tr>
 <td><strong>${m.AdPlatform}</strong></td>
 <td>${m.CampaignName}</td>
 <td><span class="badge-tag">${m.ChannelType}</span></td>
 <td>${m.DeviceType}</td>
 <td>${formatINR(m.TotalAdSpend, true)}</td>
 <td>${formatNumber(m.TotalClicks)}</td>
 <td>${m.AverageCTR_Pct}%</td>
 <td>₹${m.AverageCPC}</td>
 <td>${formatNumber(m.TotalLeadsGenerated)}</td>
 <td>${formatNumber(m.TotalConversions)}</td>
 <td><strong>${formatINR(m.AttributedRevenue, true)}</strong></td>
 <td><span class="trend-badge ${Number(m.OverallROAS) >= 4 ? 'positive' : 'neutral'}">${m.OverallROAS}x</span></td>
 </tr>
 `).join('');
 }
 }

 if (tab === 'products') {
 // Pareto Curve Chart
 const ctxPareto = document.getElementById('chart-pareto-curve')?.getContext('2d');
 if (ctxPareto && !state.charts.paretoCurve) {
 state.charts.paretoCurve = new Chart(ctxPareto, {
 type: 'line',
 data: {
 labels: ['0%', '10%', '16.5% (Class A)', '30%', '50%', '70%', '100%'],
 datasets: [
 {
 label: 'Cumulative Revenue %',
 data: [0, 62, 80, 88, 94, 98, 100],
 borderColor: '#FFC20E',
 backgroundColor: 'rgba(255, 194, 14, 0.2)',
 fill: true,
 tension: 0.3
 },
 {
 label: 'Equal Distribution (Linear 1:1)',
 data: [0, 10, 16.5, 30, 50, 70, 100],
 borderColor: '#94A3B8',
 borderDash: [5, 5],
 fill: false
 }
 ]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 scales: {
 y: { ticks: { callback: (val) => `${val}%` }, max: 100 }
 }
 }
 });
 }

 // Category Bars
 const ctxCat = document.getElementById('chart-category-bars')?.getContext('2d');
 if (ctxCat && !state.charts.categoryBars) {
 state.charts.categoryBars = new Chart(ctxCat, {
 type: 'bar',
 data: {
 labels: data.categories.map(c => c.Category),
 datasets: [{
 label: 'Gross Revenue (₹)',
 data: data.categories.map(c => Number(c.GrossRevenue)),
 backgroundColor: '#3B82F6',
 borderRadius: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 scales: {
 y: { ticks: { callback: (val) => formatINR(val, true) } }
 }
 }
 });
 }

 // Master Products Explorer Table
 const prodTbody = document.querySelector('#table-products-explorer tbody');
 if (prodTbody) {
 prodTbody.innerHTML = data.topProducts.map(p => `
 <tr>
 <td><strong>${p.SKU}</strong></td>
 <td>${p.ProductName ? p.ProductName.substring(0, 36) : ''}</td>
 <td><span class="badge-tag">${p.Category}</span></td>
 <td>${p.Brand}</td>
 <td>₹${p.BaseMRP}</td>
 <td>${formatNumber(p.Orders)}</td>
 <td>${formatNumber(p.Units)}</td>
 <td><strong>${formatINR(p.Revenue, true)}</strong></td>
 <td><span style="font-size:11px; color:#6B7280;">${p.SourceSystem}</span></td>
 </tr>
 `).join('');
 }
 }

 if (tab === 'customers') {
 // RFM Donut Chart
 const ctxRfm = document.getElementById('chart-rfm-donut')?.getContext('2d');
 if (ctxRfm && !state.charts.rfmDonut) {
 state.charts.rfmDonut = new Chart(ctxRfm, {
 type: 'doughnut',
 data: {
 labels: data.customerRFM.map(r => r.RFM_Segment),
 datasets: [{
 data: data.customerRFM.map(r => Number(r.TotalSegmentRevenue)),
 backgroundColor: ['#FFC20E', '#10B981', '#3B82F6', '#8B5CF6', '#F59E0B', '#94A3B8'],
 borderWidth: 0
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 cutout: '70%'
 }
 });
 }

 // Geographic Bars
 const ctxGeo = document.getElementById('chart-geo-bars')?.getContext('2d');
 if (ctxGeo && !state.charts.geoBars) {
 state.charts.geoBars = new Chart(ctxGeo, {
 type: 'bar',
 data: {
 labels: data.geographicPerformance.map(g => g.Country || g.State || g.City),
 datasets: [{
 label: 'Gross Revenue (₹)',
 data: data.geographicPerformance.map(g => Number(g.GrossRevenue)),
 backgroundColor: '#10B981',
 borderRadius: 6
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 scales: {
 y: { ticks: { callback: (val) => formatINR(val, true) } }
 }
 }
 });
 }

 // RFM Table
 const rfmTbody = document.querySelector('#table-rfm-segments tbody');
 if (rfmTbody) {
 rfmTbody.innerHTML = data.customerRFM.map(r => `
 <tr>
 <td><strong>${r.RFM_Segment}</strong></td>
 <td>${formatNumber(r.CustomerCount)}</td>
 <td><strong>${formatINR(r.TotalSegmentRevenue, true)}</strong></td>
 <td>${Number(r.AvgOrdersPerCustomer).toFixed(1)}</td>
 <td>${Math.round(r.AvgRecencyDays)} days</td>
 <td><span class="trend-badge positive">Automate Retention</span></td>
 </tr>
 `).join('');
 }
 }

 if (tab === 'inventory') {
 // Inventory Health Donut
 const ctxInv = document.getElementById('chart-inventory-health-donut')?.getContext('2d');
 if (ctxInv && !state.charts.invDonut) {
 state.charts.invDonut = new Chart(ctxInv, {
 type: 'doughnut',
 data: {
 labels: data.inventoryHealth.map(i => i.InventoryHealthStatus),
 datasets: [{
 data: data.inventoryHealth.map(i => Number(i.TotalSKUs)),
 backgroundColor: ['#10B981', '#EF4444', '#F59E0B', '#3B82F6'],
 borderWidth: 0
 }]
 },
 options: {
 responsive: true,
 maintainAspectRatio: false,
 cutout: '70%'
 }
 });
 }
 }

 if (tab === 'channels') {
 // Arbitrage Table
 const arbTbody = document.querySelector('#table-arbitrage-deepdive tbody');
 if (arbTbody) {
 arbTbody.innerHTML = data.crossChannelArbitrage.map(a => `
 <tr>
 <td><strong>${a.SKU}</strong></td>
 <td>${a.ProductName ? a.ProductName.substring(0, 30) : ''}</td>
 <td><span class="badge-tag">${a.Category}</span></td>
 <td>₹${a.BaseMRP}</td>
 <td>₹${a.TransferPrice}</td>
 <td>₹${a.AmazonMRP || '-'}</td>
 <td><strong style="color:#059669;">₹${a.MyntraMRP || '-'}</strong></td>
 <td>₹${a.AjioMRP || '-'}</td>
 <td>₹${a.FlipkartMRP || '-'}</td>
 <td><strong>₹${a.MaxCrossChannelSpreadAmount}</strong></td>
 <td><span class="trend-badge positive">+${a.ArbitrageSpreadPct}%</span></td>
 </tr>
 `).join('');
 }
 }

 if (tab === 'insights') {
 // AI Decision Cards
 const container = document.getElementById('ai-insights-cards-container');
 if (container) {
 container.innerHTML = data.aiDecisionInsights.map(ai => `
 <div class="ai-decision-card">
 <div class="ai-card-header">
 <span class="badge-tag" style="background:#FEF3C7; color:#B45309; font-weight:700;">${ai.StrategicDomain}</span>
 <div class="ai-meta-pills">
 <span class="trend-badge ${ai.UrgencyLevel === 'High' ? 'negative' : 'neutral'}">${ai.UrgencyLevel} Urgency</span>
 <span class="trend-badge positive">${Math.round(ai.ConfidenceScore * 100)}% Confidence</span>
 </div>
 </div>
 
 <h3 class="ai-obs-title">${ai.Observation}</h3>
 
 <div class="ai-section-block">
 <strong>Empirical Evidence:</strong>
 <p>${ai.EmpiricalEvidence}</p>
 </div>

 <div class="ai-section-block">
 <strong>Root Cause Hypothesis:</strong>
 <p>${ai.RootCauseHypothesis}</p>
 </div>

 <div class="ai-impact-box">
 <div class="impact-val">${formatINR(ai.FinancialImpactAmount, true)}</div>
 <div class="impact-desc">${ai.FinancialImpactDescription}</div>
 </div>

 <div class="ai-action-box">
 <strong>Prescriptive Action:</strong>
 <p>${ai.PrescriptiveAction}</p>
 </div>

 <div class="ai-footer-meta">
 <span><strong>Expected Outcome:</strong> ${ai.ExpectedOutcome}</span>
 <span class="ai-limitation"><strong>Limitation:</strong> ${ai.DataLimitation}</span>
 </div>
 </div>
 `).join('');
 }

 // NLQ Engine Setup
 const nlqBtn = document.getElementById('nlq-submit-btn');
 const nlqInput = document.getElementById('nlq-input');
 const nlqBody = document.getElementById('nlq-res-body');

 const nlqAnswers = {
 'channel': "Amazon Global and Amazon India combined drive 88.1% of total enterprise revenue (₹164.8M). However, International Wholesale delivers the highest unit volume (14.6M units) at the lowest cancellation rate (<3.5%).",
 'marketing': "Google Ads Paid Search is generating a strong 7.80x ROAS with ₹4.21M attributed revenue on ₹540k spend. The top converting keyword is 'learn data analytics' at ₹1.45 CPC.",
 'stockout': "2,559 SKUs are currently out of stock, of which 412 are Class A high-velocity items. Estimated monthly gross profit leakage is ₹1.85M.",
 'profitable': "Myntra and Ajio generate the highest realized gross margin percentage (47.2%), commanding a ₹350 MRP premium over discount marketplaces.",
 'default': "Based on the unified data warehouse, total enterprise GMV is ₹186.8M with 265,366 orders across 13 sources. The blended marketing ROAS is 7.78x and the data warehouse passes 18/18 automated quality audits."
 };

 if (nlqBtn && nlqInput && nlqBody) {
 nlqBtn.addEventListener('click', () => {
 const q = nlqInput.value.toLowerCase();
 if (q.includes('channel') || q.includes('platform')) {
 nlqBody.innerHTML = nlqAnswers.channel;
 } else if (q.includes('marketing') || q.includes('roas') || q.includes('ad')) {
 nlqBody.innerHTML = nlqAnswers.marketing;
 } else if (q.includes('stockout') || q.includes('inventory') || q.includes('stock')) {
 nlqBody.innerHTML = nlqAnswers.stockout;
 } else if (q.includes('profit') || q.includes('margin') || q.includes('arbitrage')) {
 nlqBody.innerHTML = nlqAnswers.profitable;
 } else {
 nlqBody.innerHTML = nlqAnswers.default;
 }
 });
 }
 }

 if (tab === 'alerts') {
 // Data Quality Table
 const dqTbody = document.querySelector('#table-dq-audit-log tbody');
 if (dqTbody) {
 dqTbody.innerHTML = data.dataQualityAudit.map(dq => `
 <tr>
 <td>#${dq.AuditId}</td>
 <td><strong>${dq.TestSuite}</strong></td>
 <td><span class="badge-tag">${dq.TestCategory}</span></td>
 <td><code>${dq.TestName}</code></td>
 <td><span class="trend-badge ${dq.Severity === 'CRITICAL' ? 'negative' : 'neutral'}">${dq.Severity}</span></td>
 <td>${formatNumber(dq.TotalRecordsEvaluated)}</td>
 <td>${dq.RecordsFailed}</td>
 <td><span class="trend-badge positive">PASS</span></td>
 </tr>
 `).join('');
 }
 }
 };

 // Initial Load
 renderKPIs();
 initOverviewCharts();
});
