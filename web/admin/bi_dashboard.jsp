<%-- web/admin/bi_dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.SaleDAO, mpeoa.dao.ExpenseDAO, mpeoa.dao.ProductDAO, java.util.*, java.text.*, java.math.BigDecimal, java.sql.*" %>
<%
    // Access control
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    // Initialize DAOs
    SaleDAO saleDAO = new SaleDAO();
    ExpenseDAO expenseDAO = new ExpenseDAO();
    ProductDAO productDAO = new ProductDAO();

    // --- Date Range Logic ---
    String period = request.getParameter("period");
    if (period == null) period = "month";
    
    java.sql.Date startDate = null;
    java.sql.Date endDate = new java.sql.Date(System.currentTimeMillis());
    Calendar cal = Calendar.getInstance();
    String periodLabel = "";
    
    switch (period) {
        case "week":
            cal.add(Calendar.DAY_OF_MONTH, -7);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 7 Days";
            break;
        case "month":
            cal.add(Calendar.MONTH, -1);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 30 Days";
            break;
        case "quarter":
            cal.add(Calendar.MONTH, -3);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 3 Months";
            break;
        case "year":
            cal.add(Calendar.YEAR, -1);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last Year";
            break;
        default:
            cal.add(Calendar.MONTH, -1);
            startDate = new java.sql.Date(cal.getTimeInMillis());
            periodLabel = "Last 30 Days";
    }

    // --- Fetch Real Data ---
    // Financials
    BigDecimal totalRevenue = saleDAO.getTotalSalesByDateRange(startDate, endDate);
    BigDecimal totalExpenses = expenseDAO.getTotalExpensesByDateRange(startDate, endDate);
    BigDecimal netProfit = totalRevenue.subtract(totalExpenses);
    BigDecimal profitMargin = totalRevenue.compareTo(BigDecimal.ZERO) > 0 
        ? netProfit.divide(totalRevenue, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100)) 
        : BigDecimal.ZERO;
        
    // Sales Trend
    List<Object[]> salesTrend = saleDAO.getDailySalesForPeriod(startDate, endDate);
    
    // Top Products
    List<mpeoa.models.Product> topProducts = productDAO.getTopSellingProducts(5);
    
    // Expenses by Category
    List<Object[]> expensesByCategory = expenseDAO.getExpensesByCategoryForPeriod(startDate, endDate);
    
    // Transaction Count
    int transactionCount = saleDAO.getSaleCount();

    // Formatting
    DecimalFormat df = new DecimalFormat("#,##0.00");
    DecimalFormat pf = new DecimalFormat("#,##0.0");
    
    // Chart Data Preparation
    StringBuilder chartLabels = new StringBuilder();
    StringBuilder chartRevenue = new StringBuilder();
    for (Object[] row : salesTrend) {
        chartLabels.append("'").append(row[0].toString()).append("',");
        chartRevenue.append(row[1].toString()).append(",");
    }
    
    StringBuilder expenseLabels = new StringBuilder();
    StringBuilder expenseValues = new StringBuilder();
    for (Object[] row : expensesByCategory) {
        expenseLabels.append("'").append(row[0].toString()).append("',");
        expenseValues.append(row[1].toString()).append(",");
    }

    // Build initials
    String initials = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BI & Financial Dashboard — Mpeoa Supermarket ERP</title>
    
    <!-- Bootstrap 5, Icons, Fonts -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <style>
        :root {
            --cream: #F5F0E6;
            --cream-dark: #EDE6D4;
            --cream-border: #DDD8CE;
            --gold: #C8923A;
            --gold-light: #DBA85A;
            --gold-pale: rgba(200,146,58,0.10);
            --navy: #12223A;
            --navy-mid: #1A3050;
            --white: #FFFFFF;
            --text-muted: #6B6670;
            --success: #2E7D52;
            --danger: #C0392B;
            --warning: #D4A42B;
            --info: #17A2B8;
            --sidebar-w: 260px;
            --topbar-h: 64px;
            --radius: 12px;
            --shadow: 0 2px 16px rgba(18,34,58,0.08);
            --shadow-md: 0 4px 24px rgba(18,34,58,0.12);
            --font-display: 'Playfair Display', Georgia, serif;
            --font-body: 'DM Sans', sans-serif;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            min-height: 100vh;
        }

        /* Sidebar (Reused from your admin template) */
        .sidebar {
            position: fixed; top: 0; left: 0;
            width: var(--sidebar-w); height: 100vh;
            background: var(--navy);
            display: flex; flex-direction: column;
            z-index: 1040;
            transition: transform 0.32s;
            overflow-y: auto;
        }
        @media (max-width: 991.98px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
        }
        .sidebar-brand {
            padding: 24px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.07);
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .sidebar-logo {
            width: 40px; height: 40px;
            border-radius: 50%;
            border: 1.5px solid rgba(200,146,58,0.5);
            background: rgba(200,146,58,0.12);
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: var(--font-display);
            font-size: 1.1rem;
            font-weight: 700;
            color: var(--gold-light);
        }
        .sidebar-brand-name {
            font-family: var(--font-display);
            font-size: 0.92rem;
            font-weight: 700;
            color: var(--white);
        }
        .sidebar-brand-sub {
            font-size: 0.68rem;
            color: rgba(255,255,255,0.38);
            text-transform: uppercase;
        }
        .sidebar-close {
            display: none;
            position: absolute;
            top: 18px; right: 14px;
            background: none;
            border: none;
            color: rgba(255,255,255,0.5);
            font-size: 1.4rem;
            cursor: pointer;
        }
        @media (max-width: 991.98px) { .sidebar-close { display: flex; } }
        .nav-section-label {
            font-size: 0.65rem;
            font-weight: 600;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            color: rgba(255,255,255,0.28);
            padding: 18px 20px 6px;
        }
        .sidebar-nav { padding: 8px 0; flex: 1; }
        .nav-item-link {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 11px 20px;
            color: rgba(255,255,255,0.60);
            text-decoration: none;
            font-size: 0.88rem;
            font-weight: 500;
            border-left: 3px solid transparent;
            transition: all 0.18s;
        }
        .nav-item-link i { font-size: 1rem; width: 18px; }
        .nav-item-link:hover { color: var(--white); background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
        .nav-item-link.active { color: var(--gold-light); background: rgba(200,146,58,0.10); border-left-color: var(--gold); font-weight: 600; }
        .sidebar-footer {
            padding: 16px 20px;
            border-top: 1px solid rgba(255,255,255,0.07);
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .sidebar-avatar {
            width: 34px; height: 34px;
            border-radius: 50%;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.8rem;
            font-weight: 700;
            color: var(--gold-light);
        }
        .sidebar-admin-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sidebar-admin-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; }
        @media (max-width: 991.98px) { .main-wrap { margin-left: 0; } }

        .topbar {
            height: var(--topbar-h);
            background: rgba(245,240,230,0.92);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--cream-border);
            padding: 0 28px;
            display: flex;
            align-items: center;
            gap: 16px;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        .burger-btn { display: none; background: none; border: none; font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991.98px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-date { font-size: 0.78rem; color: var(--text-muted); }
        @media (max-width: 576px) { .topbar-date { display: none; } }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }
        .page-header { margin-bottom: 28px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

        /* KPI Cards */
        .kpi-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            border: 1px solid var(--cream-border);
            transition: transform 0.2s;
            height: 100%;
        }
        .kpi-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
        .kpi-icon {
            width: 48px; height: 48px;
            border-radius: 12px;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            margin-bottom: 12px;
            color: var(--gold);
        }
        .kpi-value { font-family: var(--font-display); font-size: 1.8rem; font-weight: 700; margin-bottom: 4px; color: var(--navy); }
        .kpi-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .trend-up { color: var(--success); font-size: 0.7rem; }
        .trend-down { color: var(--danger); font-size: 0.7rem; }

        /* Filter Bar */
        .filter-bar {
            background: var(--white);
            border-radius: var(--radius);
            padding: 12px 20px;
            margin-bottom: 24px;
            border: 1px solid var(--cream-border);
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            flex-wrap: wrap;
        }
        .filter-btn {
            padding: 6px 18px;
            border-radius: 20px;
            text-decoration: none;
            font-size: 0.8rem;
            font-weight: 500;
            transition: all 0.2s;
            border: 1px solid var(--cream-border);
            color: var(--navy);
            background: var(--white);
        }
        .filter-btn:hover { border-color: var(--gold); background: var(--gold-pale); }
        .filter-btn.active { background: var(--gold); color: white; border-color: var(--gold); }

        /* Chart Cards */
        .chart-card {
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 24px;
        }
        .card-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
            font-family: var(--font-display);
            font-weight: 700;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .chart-container { padding: 20px; height: 320px; position: relative; }
        
        /* Top Products List */
        .product-list { list-style: none; padding: 0; margin: 0; }
        .product-item {
            padding: 12px 0;
            border-bottom: 1px solid var(--cream-border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .product-rank {
            width: 28px;
            height: 28px;
            border-radius: 50%;
            background: var(--gold-pale);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 0.75rem;
            font-weight: 700;
            margin-right: 10px;
            color: var(--gold);
        }
        
        .insight-text { font-size: 0.85rem; color: var(--text-muted); margin-bottom: 8px; }
        .divider { height: 1px; background: var(--cream-border); margin: 15px 0; }
        
        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-3 { margin-top: 12px; }
        .fw-bold { font-weight: 700; }
        .text-success { color: var(--success); }
        .text-danger { color: var(--danger); }
        .text-gold { color: var(--gold); }
        
        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade { animation: fadeUp 0.4s ease both; }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<!-- Sidebar -->
<aside class="sidebar" id="sidebar">
    <button class="sidebar-close" onclick="closeSidebar()"><i class="bi bi-x-lg"></i></button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">ERP System</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item-link"><i class="bi bi-grid-1x2-fill"></i> Dashboard</a>
        <div class="nav-section-label">Management</div>
        <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item-link"><i class="bi bi-people-fill"></i> User Management</a>
        <a href="${pageContext.request.contextPath}/admin/products.jsp" class="nav-item-link"><i class="bi bi-box-seam-fill"></i> Products</a>
        <a href="${pageContext.request.contextPath}/admin/inventory.jsp" class="nav-item-link"><i class="bi bi-archive-fill"></i> Inventory</a>
        <a href="${pageContext.request.contextPath}/admin/categories.jsp" class="nav-item-link"><i class="bi bi-tags-fill"></i> Categories</a>
        <div class="nav-section-label">Operations</div>
        <a href="${pageContext.request.contextPath}/admin/sales.jsp" class="nav-item-link"><i class="bi bi-receipt"></i> Sales</a>
        <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="nav-item-link"><i class="bi bi-wallet2"></i> Expenses</a>
        <a href="${pageContext.request.contextPath}/admin/suppliers.jsp" class="nav-item-link"><i class="bi bi-truck"></i> Suppliers</a>
        <a href="${pageContext.request.contextPath}/admin/purchases.jsp" class="nav-item-link"><i class="bi bi-cart-fill"></i> Purchases</a>
        <div class="nav-section-label">Insights</div>
        <a href="${pageContext.request.contextPath}/admin/bi_dashboard.jsp" class="nav-item-link active"><i class="bi bi-graph-up"></i> BI & Finance</a>
        <a href="${pageContext.request.contextPath}/admin/cashflow_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-arrow-left-right"></i> Cash Flow
        </a>
        <a href="${pageContext.request.contextPath}/admin/sales_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-line-fill"></i> Sales BI
        </a>
        <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item-link"><i class="bi bi-file-text-fill"></i> Reports</a>
        <a href="${pageContext.request.contextPath}/admin/analytics.jsp" class="nav-item-link"><i class="bi bi-bar-chart-steps"></i> Analytics</a>
        <div class="nav-section-label">System</div>
        <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item-link"><i class="bi bi-gear-fill"></i> Settings</a>
        <a href="${pageContext.request.contextPath}/admin/security.jsp" class="nav-item-link"><i class="bi bi-shield-lock-fill"></i> Security</a>
        <a href="${pageContext.request.contextPath}/admin/backup.jsp" class="nav-item-link"><i class="bi bi-database-fill"></i> Backup</a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sidebar-admin-role">Administrator</div>
        </div>
        <a href="${pageContext.request.contextPath}/logout" class="sidebar-logout" title="Logout"><i class="bi bi-box-arrow-right"></i></a>
    </div>
</aside>

<!-- Main Content -->
<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">BI & Financial Dashboard</span>
        <span class="topbar-date"><i class="bi bi-calendar3 me-1"></i><script>document.write(new Date().toLocaleDateString('en-ZA'));</script></span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Executive Decision Support</p>
                <h1 class="page-heading">Business Intelligence & Financial Dashboard</h1>
                <p class="text-muted mt-2">Real-time P&L, KPIs, and performance trends for data-driven decisions</p>
            </div>
        </div>
        
        <!-- Date Filter -->
        <div class="filter-bar">
            <a href="?period=week" class="filter-btn <%= "week".equals(period) ? "active" : "" %>">Last 7 Days</a>
            <a href="?period=month" class="filter-btn <%= "month".equals(period) ? "active" : "" %>">Last 30 Days</a>
            <a href="?period=quarter" class="filter-btn <%= "quarter".equals(period) ? "active" : "" %>">Last 3 Months</a>
            <a href="?period=year" class="filter-btn <%= "year".equals(period) ? "active" : "" %>">Last Year</a>
        </div>

        <!-- Row 1: Key Performance Indicators (Executive Summary) -->
        <div class="row g-3 mb-4">
            <div class="col-md-3 col-6">
                <div class="kpi-card animate-fade">
                    <div class="kpi-icon"><i class="bi bi-currency-exchange"></i></div>
                    <div class="kpi-value">R <%= df.format(totalRevenue) %></div>
                    <div class="kpi-label">Total Revenue</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="kpi-card animate-fade">
                    <div class="kpi-icon"><i class="bi bi-box-arrow-right"></i></div>
                    <div class="kpi-value">R <%= df.format(totalExpenses) %></div>
                    <div class="kpi-label">Total Expenses</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="kpi-card animate-fade">
                    <div class="kpi-icon"><i class="bi bi-trophy"></i></div>
                    <div class="kpi-value">R <%= df.format(netProfit) %></div>
                    <div class="kpi-label">Net Profit</div>
                    <div class="trend-up"><i class="bi bi-arrow-up"></i> Margin <%= pf.format(profitMargin) %>%</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="kpi-card animate-fade">
                    <div class="kpi-icon"><i class="bi bi-receipt"></i></div>
                    <div class="kpi-value"><%= transactionCount %></div>
                    <div class="kpi-label">Total Transactions</div>
                </div>
            </div>
        </div>

        <!-- Row 2: Financial Health (Profit & Loss Structure) -->
        <div class="row g-3 mb-4">
            <div class="col-md-7">
                <div class="chart-card">
                    <div class="card-header">
                        <span><i class="bi bi-graph-up"></i> Revenue Trend</span>
                        <span class="text-muted small"><%= periodLabel %></span>
                    </div>
                    <div class="chart-container">
                        <canvas id="revenueTrendChart"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-md-5">
                <div class="chart-card">
                    <div class="card-header">
                        <span><i class="bi bi-pie-chart-fill"></i> Revenue vs Expenses</span>
                    </div>
                    <div class="chart-container" style="height: 280px;">
                        <canvas id="pnlPieChart"></canvas>
                    </div>
                    <div class="p-3 pt-0">
                        <div class="d-flex justify-content-between">
                            <span>Profit Margin</span>
                            <span class="fw-bold"><%= pf.format(profitMargin) %>%</span>
                        </div>
                        <div class="progress mt-1" style="height: 6px;">
                            <div class="progress-bar bg-success" style="width: <%= profitMargin.compareTo(BigDecimal.ZERO) > 0 ? profitMargin : BigDecimal.ZERO %>%;"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Row 3: Operational BI (Top Products & Expense Drivers) -->
        <div class="row g-3">
            <div class="col-md-6">
                <div class="chart-card">
                    <div class="card-header">
                        <span><i class="bi bi-box-seam-fill"></i> Top 5 Selling Products</span>
                        <span class="text-muted small">Units sold</span>
                    </div>
                    <div class="p-3">
                        <% if (topProducts != null && !topProducts.isEmpty()) { 
                            int rank = 1; %>
                            <ul class="product-list">
                            <% for (mpeoa.models.Product p : topProducts) { %>
                                <li class="product-item">
                                    <div>
                                        <span class="product-rank"><%= rank++ %></span>
                                        <strong><%= p.getProductName() %></strong>
                                    </div>
                                    <span class="fw-bold"><%= p.getStockQuantity() %> units</span>
                                </li>
                            <% } %>
                            </ul>
                        <% } else { %>
                            <div class="text-center py-4 text-muted">No product sales data available</div>
                        <% } %>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="chart-card">
                    <div class="card-header">
                        <span><i class="bi bi-wallet2"></i> Top Expense Categories</span>
                    </div>
                    <div class="chart-container" style="height: 260px;">
                        <canvas id="expenseCategoryChart"></canvas>
                    </div>
                </div>
            </div>
        </div>

        <!-- Row 4: Actionable Insights -->
        <div class="chart-card mt-3">
            <div class="card-header">
                <span><i class="bi bi-lightbulb-fill"></i> Key Business Insights</span>
            </div>
            <div class="p-4">
                <div class="row">
                    <div class="col-md-6">
                        <div class="insight-text"><i class="bi bi-check-circle-fill text-success me-2"></i> <strong>Profitability:</strong> Net profit margin is <strong><%= pf.format(profitMargin) %>%</strong> over the selected period.</div>
                        <div class="insight-text mt-2"><i class="bi bi-graph-up me-2"></i> <strong>Revenue Driver:</strong> Top product contributed <strong><%= !topProducts.isEmpty() ? topProducts.get(0).getStockQuantity() : 0 %> units</strong> in sales.</div>
                    </div>
                    <div class="col-md-6">
                        <div class="insight-text"><i class="bi bi-exclamation-triangle-fill text-warning me-2"></i> <strong>Cost Control:</strong> Expenses are <strong><%= totalRevenue.compareTo(BigDecimal.ZERO) > 0 ? pf.format(totalExpenses.divide(totalRevenue, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100))) : "0" %>%</strong> of revenue.</div>
                        <div class="insight-text mt-2"><i class="bi bi-arrow-repeat me-2"></i> <strong>Action:</strong> Review expense categories with highest spend to optimize costs.</div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<script>
    function openSidebar() { document.getElementById('sidebar').classList.add('open'); document.getElementById('sidebarOverlay').classList.add('show'); document.body.style.overflow = 'hidden'; }
    function closeSidebar() { document.getElementById('sidebar').classList.remove('open'); document.getElementById('sidebarOverlay').classList.remove('show'); document.body.style.overflow = ''; }
    document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeSidebar(); });

    // Revenue Trend Chart
    const revCtx = document.getElementById('revenueTrendChart').getContext('2d');
    new Chart(revCtx, {
        type: 'line',
        data: {
            labels: [<%= chartLabels.toString().replaceAll(",$", "") %>],
            datasets: [{
                label: 'Revenue (R)',
                data: [<%= chartRevenue.toString().replaceAll(",$", "") %>],
                borderColor: '#C8923A',
                backgroundColor: 'rgba(200,146,58,0.1)',
                tension: 0.4,
                fill: true
            }]
        },
        options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'top' } } }
    });

    // P&L Pie Chart
    const pieCtx = document.getElementById('pnlPieChart').getContext('2d');
    new Chart(pieCtx, {
        type: 'doughnut',
        data: { labels: ['Revenue', 'Expenses'], datasets: [{ data: [<%= totalRevenue %>, <%= totalExpenses %>], backgroundColor: ['#2E7D52', '#C0392B'], borderWidth: 0 }] },
        options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { position: 'bottom' } } }
    });

    // Expense Category Chart
    const expCtx = document.getElementById('expenseCategoryChart').getContext('2d');
    new Chart(expCtx, {
        type: 'bar',
        data: {
            labels: [<%= expenseLabels.toString().replaceAll(",$", "") %>],
            datasets: [{
                label: 'Amount (R)',
                data: [<%= expenseValues.toString().replaceAll(",$", "") %>],
                backgroundColor: '#C8923A',
                borderRadius: 6
            }]
        },
        options: { responsive: true, maintainAspectRatio: true, plugins: { legend: { display: false } } }
    });
</script>

</body>
</html>