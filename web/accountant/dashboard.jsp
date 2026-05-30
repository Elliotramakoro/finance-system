<%-- web/accountant/dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.SaleDAO, mpeoa.dao.ExpenseDAO, mpeoa.dao.ProductDAO, mpeoa.dao.SupplierDAO, java.text.*, java.math.BigDecimal, java.util.*, java.sql.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Accountant".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Initialize DAOs
    SaleDAO saleDAO = new SaleDAO();
    ExpenseDAO expenseDAO = new ExpenseDAO();
    ProductDAO productDAO = new ProductDAO();
    SupplierDAO supplierDAO = new SupplierDAO();
    
    // Date ranges
    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
    java.sql.Date weekAgo = new java.sql.Date(System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000L);
    java.sql.Date monthAgo = new java.sql.Date(System.currentTimeMillis() - 30 * 24 * 60 * 60 * 1000L);
    java.sql.Date yearAgo = new java.sql.Date(System.currentTimeMillis() - 365 * 24 * 60 * 60 * 1000L);
    
    // Sales Data
    BigDecimal todaySales = saleDAO.getTotalSalesToday();
    BigDecimal weekSales = saleDAO.getTotalSalesByDateRange(weekAgo, today);
    BigDecimal monthSales = saleDAO.getTotalSalesByDateRange(monthAgo, today);
    BigDecimal yearSales = saleDAO.getTotalSalesByDateRange(yearAgo, today);
    
    // Expenses Data
    BigDecimal todayExpenses = expenseDAO.getTotalExpensesToday();
    BigDecimal weekExpenses = expenseDAO.getTotalExpensesByDateRange(weekAgo, today);
    BigDecimal monthExpenses = expenseDAO.getTotalExpensesByDateRange(monthAgo, today);
    BigDecimal yearExpenses = expenseDAO.getTotalExpensesByDateRange(yearAgo, today);
    
    // Profit Calculations
    BigDecimal todayProfit = todaySales.subtract(todayExpenses);
    BigDecimal monthProfit = monthSales.subtract(monthExpenses);
    BigDecimal yearProfit = yearSales.subtract(yearExpenses);
    BigDecimal profitMargin = monthSales.compareTo(BigDecimal.ZERO) > 0 ? 
        monthProfit.divide(monthSales, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100)) : BigDecimal.ZERO;
    
    // Other Metrics
    int totalSuppliers = supplierDAO.getSupplierCount();
    int totalProducts = productDAO.getProductCount();
    int totalTransactions = saleDAO.getSaleCount();
    int pendingExpenses = expenseDAO.getPendingExpensesCount();
    int approvedExpenses = expenseDAO.getApprovedExpensesCount();
    
    // Recent Expenses
    List<mpeoa.models.Expense> recentExpenses = expenseDAO.getRecentExpenses(5);
    
    // Top Products
    List<mpeoa.models.Product> topProducts = productDAO.getTopSellingProducts(5);
    
    // Expenses by category for current month
    List<Object[]> expensesByCategory = expenseDAO.getExpensesByCategoryForPeriod(monthAgo, today);
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    DecimalFormat pf = new DecimalFormat("#,##0.0");
    
    // Build initials
    String initials = "A";
    String accountantName = loggedInUser.getFullName();
    if (accountantName != null && !accountantName.trim().isEmpty()) {
        String[] parts = accountantName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
    
    // Prepare chart data for expenses by category
    StringBuilder categoryLabels = new StringBuilder();
    StringBuilder categoryValues = new StringBuilder();
    if (expensesByCategory != null && !expensesByCategory.isEmpty()) {
        for (int i = 0; i < expensesByCategory.size(); i++) {
            Object[] row = expensesByCategory.get(i);
            categoryLabels.append("'").append(row[0].toString()).append("'");
            categoryValues.append(row[1].toString());
            if (i < expensesByCategory.size() - 1) {
                categoryLabels.append(",");
                categoryValues.append(",");
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Accountant Dashboard — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    
    <style>
        :root {
            --cream:         #F5F0E6;
            --cream-dark:    #EDE6D4;
            --cream-border:  #DDD8CE;
            --gold:          #C8923A;
            --gold-light:    #DBA85A;
            --gold-pale:     rgba(200,146,58,0.10);
            --navy:          #12223A;
            --navy-mid:      #1A3050;
            --navy-light:    #243D5C;
            --white:         #FFFFFF;
            --text-muted:    #6B6670;
            --success:       #2E7D52;
            --success-pale:  rgba(46,125,82,0.10);
            --danger:        #C0392B;
            --danger-pale:   rgba(192,57,43,0.10);
            --warning:       #D4A42B;
            --warning-pale:  rgba(212,164,43,0.10);
            --info:          #17A2B8;
            --info-pale:     rgba(23,162,184,0.10);
            --sidebar-w:     260px;
            --topbar-h:      64px;
            --font-display:  'Playfair Display', Georgia, serif;
            --font-body:     'DM Sans', sans-serif;
            --radius:        12px;
            --shadow:        0 2px 16px rgba(18,34,58,0.08);
            --shadow-md:     0 4px 24px rgba(18,34,58,0.12);
        }

        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            margin: 0; min-height: 100vh;
        }

        /* Sidebar */
        .sidebar {
            position: fixed; top: 0; left: 0;
            width: var(--sidebar-w); height: 100vh;
            background: var(--navy);
            display: flex; flex-direction: column;
            z-index: 1040;
            transition: transform 0.32s cubic-bezier(0.4,0,0.2,1);
            overflow-y: auto; overflow-x: hidden;
        }
        @media (max-width: 991.98px) {
            .sidebar { transform: translateX(-100%); }
            .sidebar.open { transform: translateX(0); }
        }
        .sidebar-brand {
            padding: 24px 20px 20px;
            border-bottom: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 12px; flex-shrink: 0;
        }
        .sidebar-logo {
            width: 40px; height: 40px;
            border-radius: 50%;
            border: 1.5px solid rgba(200,146,58,0.5);
            background: rgba(200,146,58,0.12);
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-display); font-size: 1.1rem; font-weight: 700;
            color: var(--gold-light); flex-shrink: 0;
        }
        .sidebar-brand-text { line-height: 1.2; }
        .sidebar-brand-name { font-family: var(--font-display); font-size: 0.92rem; font-weight: 700; color: var(--white); }
        .sidebar-brand-sub  { font-size: 0.68rem; font-weight: 500; color: rgba(255,255,255,0.38); letter-spacing: 0.08em; text-transform: uppercase; }
        .sidebar-close {
            display: none; position: absolute; top: 18px; right: 14px;
            background: none; border: none; color: rgba(255,255,255,0.5);
            font-size: 1.4rem; cursor: pointer;
        }
        .sidebar-close:hover { color: var(--gold-light); }
        @media (max-width: 991.98px) { .sidebar-close { display: flex; } }
        .nav-section-label {
            font-size: 0.65rem; font-weight: 600; letter-spacing: 0.12em;
            text-transform: uppercase; color: rgba(255,255,255,0.28); padding: 18px 20px 6px;
        }
        .sidebar-nav { padding: 8px 0; flex: 1; }
        .nav-item-link {
            display: flex; align-items: center; gap: 12px; padding: 11px 20px;
            color: rgba(255,255,255,0.60); text-decoration: none;
            font-size: 0.88rem; font-weight: 500;
            border-left: 3px solid transparent; transition: all 0.18s;
        }
        .nav-item-link i { font-size: 1rem; width: 18px; text-align: center; }
        .nav-item-link:hover { color: var(--white); background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
        .nav-item-link.active { color: var(--gold-light); background: rgba(200,146,58,0.10); border-left-color: var(--gold); font-weight: 600; }
        .sidebar-footer {
            padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.07);
            display: flex; align-items: center; gap: 10px; flex-shrink: 0;
        }
        .sidebar-avatar {
            width: 34px; height: 34px; border-radius: 50%;
            background: var(--gold-pale); border: 1.5px solid rgba(200,146,58,0.4);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.8rem; font-weight: 700; color: var(--gold-light);
        }
        .sidebar-admin-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sidebar-admin-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

        /* Main Content */
        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; transition: margin-left 0.32s; }
        @media (max-width: 991.98px) { .main-wrap { margin-left: 0; } }

        /* Topbar */
        .topbar {
            height: var(--topbar-h);
            background: rgba(245,240,230,0.92);
            backdrop-filter: blur(12px);
            border-bottom: 1px solid var(--cream-border);
            padding: 0 28px;
            display: flex; align-items: center; gap: 16px;
            position: sticky; top: 0; z-index: 100;
        }
        .burger-btn { display: none; background: none; border: none; color: var(--navy); font-size: 1.35rem; cursor: pointer; }
        .burger-btn:hover { background: var(--gold-pale); border-radius: 6px; }
        @media (max-width: 991.98px) { .burger-btn { display: flex; } }
        .topbar-title { font-family: var(--font-display); font-size: 1.15rem; font-weight: 700; color: var(--navy); flex: 1; }
        .topbar-date { font-size: 0.78rem; color: var(--text-muted); }
        @media (max-width: 576px) { .topbar-date { display: none; } }
        .topbar-avatar { width: 36px; height: 36px; border-radius: 50%; background: var(--navy); display: flex; align-items: center; justify-content: center; font-size: 0.8rem; font-weight: 700; color: var(--gold-light); border: 2px solid var(--cream-border); }

        /* Page Body */
        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }
        .page-header { margin-bottom: 28px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

        /* Role Badge */
        .role-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.7rem;
            font-weight: 600;
            margin-left: 10px;
            background: var(--gold-pale);
            color: var(--gold);
        }

        /* Stat Cards */
        .stat-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            border: 1px solid var(--cream-border);
            transition: transform 0.2s, box-shadow 0.2s;
            height: 100%;
        }
        .stat-card:hover {
            transform: translateY(-3px);
            box-shadow: var(--shadow-md);
        }
        .stat-icon {
            width: 44px; height: 44px;
            border-radius: 10px;
            background: var(--gold-pale);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.2rem;
            margin-bottom: 12px;
            color: var(--gold);
        }
        .stat-value {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 700;
            margin-bottom: 4px;
            color: var(--navy);
        }
        .stat-label { font-size: 0.75rem; color: var(--text-muted); }

        /* Content Cards */
        .content-card {
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            box-shadow: var(--shadow);
            overflow: hidden;
            margin-bottom: 24px;
        }
        .card-header-bar {
            padding: 16px 20px;
            border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
        }
        .card-header-title {
            font-family: var(--font-display);
            font-size: 0.95rem;
            font-weight: 700;
            margin: 0;
            display: flex;
            align-items: center;
            gap: 8px;
            color: var(--navy);
        }
        .btn-sm-outline {
            background: transparent;
            border: 1px solid var(--cream-border);
            color: var(--navy);
            padding: 5px 12px;
            border-radius: 6px;
            font-size: 0.7rem;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.2s;
        }
        .btn-sm-outline:hover {
            border-color: var(--gold);
            background: var(--gold-pale);
            color: var(--gold);
        }
        .btn-gold {
            background: var(--gold);
            color: white;
            border: none;
            border-radius: 8px;
            padding: 10px 20px;
            font-size: 0.85rem;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-gold:hover {
            background: var(--gold-light);
            color: white;
        }

        /* Tables */
        .table-responsive { overflow-x: auto; }
        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.8rem;
        }
        .data-table thead th {
            background: var(--cream);
            padding: 12px 16px;
            text-align: left;
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            color: var(--navy);
            border-bottom: 1px solid var(--cream-border);
        }
        .data-table tbody td {
            padding: 12px 16px;
            border-bottom: 1px solid var(--cream-border);
            color: var(--navy);
        }
        .data-table tbody tr:hover {
            background: var(--cream);
        }

        /* Badges */
        .badge-success {
            background: var(--success-pale);
            color: var(--success);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }
        .badge-pending {
            background: var(--warning-pale);
            color: var(--warning);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }

        /* Chart Container */
        .chart-container { padding: 20px; height: 300px; }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 15px;
            opacity: 0.5;
        }

        /* Utilities */
        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
        .fw-bold { font-weight: 700; }
        .text-center { text-align: center; }
        .me-1 { margin-right: 4px; }
        .text-success { color: var(--success); }
        .text-danger { color: var(--danger); }
        .fs-1 { font-size: 2.5rem; }

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
    <button class="sidebar-close" onclick="closeSidebar()">
        <i class="bi bi-x-lg"></i>
    </button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">Finance Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/accountant/dashboard.jsp" class="nav-item-link active">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Financial</div>
        <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="nav-item-link">
            <i class="bi bi-wallet2"></i> Expenses
        </a>
        <a href="${pageContext.request.contextPath}/admin/sales.jsp" class="nav-item-link">
            <i class="bi bi-receipt"></i> Sales
        </a>
        <a href="${pageContext.request.contextPath}/admin/suppliers.jsp" class="nav-item-link">
            <i class="bi bi-truck"></i> Suppliers
        </a>

        <div class="nav-section-label">Reports</div>
        <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item-link">
            <i class="bi bi-graph-up"></i> Financial Reports
        </a>
        <a href="${pageContext.request.contextPath}/admin/analytics.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-steps"></i> Analytics
        </a>
        <a href="${pageContext.request.contextPath}/admin/bi_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-line-fill"></i> BI Dashboard
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= accountantName != null ? accountantName : "Accountant" %></div>
            <div class="sidebar-admin-role">Accountant</div>
        </div>
        <a href="${pageContext.request.contextPath}/logout" class="sidebar-logout" title="Logout">
            <i class="bi bi-box-arrow-right"></i>
        </a>
    </div>
</aside>

<!-- Main Content -->
<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Accountant Dashboard</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Financial Management</p>
                <h1 class="page-heading">Good day, <%= accountantName != null ? accountantName.split(" ")[0] : "Accountant" %>.</h1>
                <p class="text-muted mt-2">Monitor financial transactions, track expenses, and generate reports.</p>
            </div>
            <div>
                <span class="role-badge"><i class="bi bi-calculator-fill"></i> Accountant Access</span>
                <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="btn-gold ms-2">
                    <i class="bi bi-plus-circle-fill"></i> Record Expense
                </a>
            </div>
        </div>

        <!-- Key Financial Indicators -->
        <div class="row g-3 mb-4">
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-graph-up"></i></div>
                    <div class="stat-value">R <%= df.format(todaySales) %></div>
                    <div class="stat-label">Today's Sales</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-box-arrow-right"></i></div>
                    <div class="stat-value">R <%= df.format(todayExpenses) %></div>
                    <div class="stat-label">Today's Expenses</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-trophy"></i></div>
                    <div class="stat-value">R <%= df.format(todayProfit) %></div>
                    <div class="stat-label">Today's Profit</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                    <div class="stat-value"><%= totalTransactions %></div>
                    <div class="stat-label">Total Transactions</div>
                </div>
            </div>
        </div>

        <!-- Monthly & Yearly Summary -->
        <div class="row g-3 mb-4">
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(monthSales) %></div>
                            <div class="stat-label">Monthly Revenue</div>
                        </div>
                        <i class="bi bi-calendar-month fs-1 text-muted"></i>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(monthExpenses) %></div>
                            <div class="stat-label">Monthly Expenses</div>
                        </div>
                        <i class="bi bi-calendar-month fs-1 text-danger"></i>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(monthProfit) %></div>
                            <div class="stat-label">Monthly Profit</div>
                            <div class="text-success" style="font-size: 0.7rem;"><%= pf.format(profitMargin) %>% margin</div>
                        </div>
                        <i class="bi bi-trophy fs-1 text-success"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Annual Summary -->
        <div class="row g-3 mb-4">
            <div class="col-md-6">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(yearSales) %></div>
                            <div class="stat-label">Year-to-Date Revenue</div>
                        </div>
                        <i class="bi bi-calendar-year fs-1 text-muted"></i>
                    </div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(yearProfit) %></div>
                            <div class="stat-label">Year-to-Date Profit</div>
                        </div>
                        <i class="bi bi-trophy fs-1 text-success"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Expense Alerts -->
        <% if (pendingExpenses > 0) { %>
            <div class="alert alert-warning mb-4">
                <i class="bi bi-clock-history"></i>
                <span><strong><%= pendingExpenses %></strong> expense(s) have been recorded and are pending manager approval.</span>
            </div>
        <% } %>

        <div class="row g-3 mb-4">
            <!-- Expenses by Category Chart -->
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-pie-chart-fill"></i> Expenses by Category (This Month)
                        </h2>
                    </div>
                    <div class="chart-container">
                        <canvas id="expenseChart"></canvas>
                    </div>
                </div>
            </div>
            
            <!-- Financial Summary -->
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-calculator-fill"></i> Financial Summary
                        </h2>
                    </div>
                    <div style="padding: 20px;">
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Total Revenue (Month)</span>
                            <span class="fw-bold text-success">R <%= df.format(monthSales) %></span>
                        </div>
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Total Expenses (Month)</span>
                            <span class="fw-bold text-danger">R <%= df.format(monthExpenses) %></span>
                        </div>
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Net Profit (Month)</span>
                            <span class="fw-bold" style="color: var(--gold);">R <%= df.format(monthProfit) %></span>
                        </div>
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Profit Margin</span>
                            <span class="fw-bold text-success"><%= pf.format(profitMargin) %>%</span>
                        </div>
                        <div class="d-flex justify-content-between">
                            <span>Pending Approvals</span>
                            <span class="fw-bold text-warning"><%= pendingExpenses %></span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Recent Expenses Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-clock-history"></i> Recent Expenses
                </h2>
                <a href="${pageContext.request.contextPath}/admin/expenses.jsp" class="btn-sm-outline">
                    View All <i class="bi bi-arrow-right"></i>
                </a>
            </div>
            <div class="table-responsive">
                <% if (recentExpenses != null && !recentExpenses.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Category</th>
                                <th>Description</th>
                                <th>Amount</th>
                                <th>Recorded By</th>
                                <th>Status</th>
                            </thead>
                        <tbody>
                            <% for (mpeoa.models.Expense expense : recentExpenses) { %>
                                <tr>
                                    <td><%= expense.getExpenseDate() != null ? expense.getExpenseDate() : "-" %></td>
                                    <td><strong><%= expense.getExpenseCategory() %></strong></td>
                                    <td><%= expense.getDescription() != null && expense.getDescription().length() > 40 ? expense.getDescription().substring(0, 40) + "..." : expense.getDescription() %></td>
                                    <td class="fw-bold">R <%= df.format(expense.getAmount()) %></td>
                                    <td><%= expense.getRecordedByName() != null ? expense.getRecordedByName() : "Staff" %></td>
                                    <td>
                                        <% if ("Approved".equalsIgnoreCase(expense.getStatus())) { %>
                                            <span class="badge-success">Approved</span>
                                        <% } else { %>
                                            <span class="badge-pending">Pending</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-wallet2"></i>
                        <p>No expenses recorded yet.</p>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- Top Products and Supplier Stats -->
        <div class="row g-3">
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-trophy-fill"></i> Top Selling Products
                        </h2>
                    </div>
                    <div class="table-responsive">
                        <table class="data-table">
                            <thead>
                                <tr><th>Product</th><th>Units Sold</th><th>Revenue</th></thead>
                            <tbody>
                                <% if (topProducts != null && !topProducts.isEmpty()) { 
                                    for (mpeoa.models.Product product : topProducts) { 
                                        BigDecimal revenue = product.getUnitPrice().multiply(new BigDecimal(product.getStockQuantity())); %>
                                        <tr>
                                            <td><%= product.getProductName() %></td>
                                            <td><%= product.getStockQuantity() %></td>
                                            <td>R <%= df.format(revenue) %></td>
                                        </tr>
                                    <% }
                                } else { %>
                                    <tr><td colspan="3" class="empty-state">No sales data available</td></tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            
            <div class="col-md-6">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-building"></i> Supplier Statistics
                        </h2>
                    </div>
                    <div style="padding: 20px;">
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Total Suppliers</span>
                            <span class="fw-bold"><%= totalSuppliers %></span>
                        </div>
                        <div class="d-flex justify-content-between mb-3 pb-2 border-bottom">
                            <span>Active Suppliers</span>
                            <span class="fw-bold text-success"><%= totalSuppliers %></span>
                        </div>
                        <div class="mt-3">
                            <a href="${pageContext.request.contextPath}/admin/suppliers.jsp" class="btn-sm-outline w-100 text-center">
                                Manage Suppliers <i class="bi bi-arrow-right"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Accountant Responsibilities Guide -->
        <div class="content-card mt-3">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Accountant Responsibilities
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Record all business expenses</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Track revenue and sales transactions</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Monitor profit and loss statements</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Generate financial reports</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Handle supplier payment tracking</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Prepare monthly financial summaries</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Assist with budget planning</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Ensure financial data accuracy</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<script>
    function openSidebar() {
        document.getElementById('sidebar').classList.add('open');
        document.getElementById('sidebarOverlay').classList.add('show');
        document.body.style.overflow = 'hidden';
    }
    function closeSidebar() {
        document.getElementById('sidebar').classList.remove('open');
        document.getElementById('sidebarOverlay').classList.remove('show');
        document.body.style.overflow = '';
    }
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    // Expenses by Category Chart
    const ctx = document.getElementById('expenseChart').getContext('2d');
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: [<%= categoryLabels.toString().replaceAll(",$", "") %>],
            datasets: [{
                data: [<%= categoryValues.toString().replaceAll(",$", "") %>],
                backgroundColor: ['#C8923A', '#DBA85A', '#E8C88A', '#F5E0B5', '#FFEDCC', '#FFF5E6'],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'bottom',
                }
            }
        }
    });
</script>

</body>
</html>