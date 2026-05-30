<%-- web/admin/dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, java.text.*, java.math.BigDecimal, java.util.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Get data from request attributes (set by servlet)
    Integer totalUsers = (Integer) request.getAttribute("totalUsers");
    Integer totalProducts = (Integer) request.getAttribute("totalProducts");
    Integer totalSales = (Integer) request.getAttribute("totalSales");
    Integer totalSuppliers = (Integer) request.getAttribute("totalSuppliers");
    BigDecimal todaySales = (BigDecimal) request.getAttribute("todaySales");
    BigDecimal todayExpenses = (BigDecimal) request.getAttribute("todayExpenses");
    BigDecimal profit = (BigDecimal) request.getAttribute("profit");
    Integer lowStockCount = (Integer) request.getAttribute("lowStockCount");
    List<mpeoa.models.Sale> recentSales = (List<mpeoa.models.Sale>) request.getAttribute("recentSales");
    
    // If attributes are null (direct JSP access), fetch data directly
    if (totalUsers == null) {
        mpeoa.dao.UserDAO userDAO = new mpeoa.dao.UserDAO();
        mpeoa.dao.ProductDAO productDAO = new mpeoa.dao.ProductDAO();
        mpeoa.dao.SaleDAO saleDAO = new mpeoa.dao.SaleDAO();
        mpeoa.dao.ExpenseDAO expenseDAO = new mpeoa.dao.ExpenseDAO();
        mpeoa.dao.SupplierDAO supplierDAO = new mpeoa.dao.SupplierDAO();
        
        totalUsers = userDAO.getUserCount();
        totalProducts = productDAO.getProductCount();
        totalSales = saleDAO.getSaleCount();
        totalSuppliers = supplierDAO.getSupplierCount();
        todaySales = saleDAO.getTotalSalesToday();
        todayExpenses = expenseDAO.getTotalExpensesToday();
        profit = todaySales.subtract(todayExpenses);
        lowStockCount = productDAO.getLowStockProducts().size();
        recentSales = saleDAO.getRecentSales(5);
    }
    
    // Set defaults if null
    if (totalUsers == null) totalUsers = 0;
    if (totalProducts == null) totalProducts = 0;
    if (totalSales == null) totalSales = 0;
    if (totalSuppliers == null) totalSuppliers = 0;
    if (todaySales == null) todaySales = BigDecimal.ZERO;
    if (todayExpenses == null) todayExpenses = BigDecimal.ZERO;
    if (profit == null) profit = BigDecimal.ZERO;
    if (lowStockCount == null) lowStockCount = 0;
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Build initials
    String initials = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
    
    // Get real weekly sales data from database
    mpeoa.dao.SaleDAO saleDAO = new mpeoa.dao.SaleDAO();
    // Get sales for last 7 days to show weekly trend
    java.sql.Date endDate = new java.sql.Date(System.currentTimeMillis());
    Calendar cal = Calendar.getInstance();
    cal.add(Calendar.DAY_OF_MONTH, -7);
    java.sql.Date startDate = new java.sql.Date(cal.getTimeInMillis());
    List<Object[]> dailySales = saleDAO.getDailySalesForPeriod(startDate, endDate);
    
    // Map to days of week (Monday=1, Sunday=7 in MySQL)
    double[] weeklySalesData = {0, 0, 0, 0, 0, 0, 0}; // Mon, Tue, Wed, Thu, Fri, Sat, Sun
    String[] dayNames = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
    
    for (Object[] row : dailySales) {
        String dateStr = row[0].toString();
        BigDecimal amount = (BigDecimal) row[1];
        // Parse date to get day of week
        java.sql.Date saleDate = java.sql.Date.valueOf(dateStr);
        Calendar dateCal = Calendar.getInstance();
        dateCal.setTime(saleDate);
        int dayOfWeek = dateCal.get(Calendar.DAY_OF_WEEK); // Sunday=1, Monday=2, ..., Saturday=7
        // Convert to our array index (Monday=0, Sunday=6)
        int index;
        if (dayOfWeek == Calendar.SUNDAY) {
            index = 6;
        } else {
            index = dayOfWeek - 2; // Monday=2 -> index 0
        }
        weeklySalesData[index] = weeklySalesData[index] + amount.doubleValue();
    }
    
    // Build chart data string
    StringBuilder chartData = new StringBuilder();
    for (int i = 0; i < weeklySalesData.length; i++) {
        chartData.append(weeklySalesData[i]);
        if (i < weeklySalesData.length - 1) chartData.append(",");
    }
    
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard — Mpeoa Supermarket ERP</title>
    
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
            width: 34px; height: 34px;
            border-radius: 50%;
            background: var(--gold-pale); border: 1.5px solid rgba(200,146,58,0.4);
            display: flex; align-items: center; justify-content: center;
            font-size: 0.8rem; font-weight: 700; color: var(--gold-light);
        }
        .sidebar-admin-name { font-size: 0.8rem; font-weight: 600; color: rgba(255,255,255,0.8); }
        .sidebar-admin-role { font-size: 0.67rem; color: rgba(255,255,255,0.35); text-transform: uppercase; }
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; text-decoration: none; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

        /* Main Content */
        .main-wrap { margin-left: var(--sidebar-w); min-height: 100vh; transition: margin-left 0.32s; }
        @media (max-width: 991.98px) { .main-wrap { margin-left: 0; } }

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

        .page-body { padding: 28px; }
        @media (max-width: 576px) { .page-body { padding: 16px; } }
        .page-header { margin-bottom: 28px; display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 16px; }
        .page-eyebrow { font-size: 0.72rem; font-weight: 600; letter-spacing: 0.1em; text-transform: uppercase; color: var(--gold); margin-bottom: 4px; }
        .page-heading { font-family: var(--font-display); font-size: 1.7rem; font-weight: 700; color: var(--navy); margin: 0; }

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

        /* BI Dashboard Banner */
        .bi-banner {
            background: linear-gradient(135deg, var(--navy) 0%, var(--navy-mid) 100%);
            border-radius: var(--radius);
            padding: 25px 30px;
            margin-bottom: 28px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 20px;
            box-shadow: var(--shadow-md);
        }
        .bi-banner-content {
            color: white;
        }
        .bi-banner-content h3 {
            font-family: var(--font-display);
            font-size: 1.3rem;
            font-weight: 700;
            margin-bottom: 8px;
        }
        .bi-banner-content p {
            font-size: 0.85rem;
            opacity: 0.8;
            margin: 0;
        }
        .bi-banner-btn {
            background: var(--gold);
            color: var(--navy);
            border: none;
            border-radius: 30px;
            padding: 12px 28px;
            font-size: 0.9rem;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 10px;
            transition: all 0.3s;
            white-space: nowrap;
        }
        .bi-banner-btn:hover {
            background: var(--gold-light);
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
            color: var(--navy);
        }

        .module-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .module-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            text-align: center;
            border: 1px solid var(--cream-border);
            transition: all 0.3s;
            text-decoration: none;
            color: var(--navy);
            display: block;
        }
        .module-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            border-color: var(--gold);
        }
        .module-icon {
            font-size: 2rem;
            margin-bottom: 12px;
            color: var(--gold);
        }
        .module-title {
            font-weight: 600;
            font-size: 0.9rem;
            margin-bottom: 5px;
        }
        .module-desc {
            font-size: 0.7rem;
            color: var(--text-muted);
        }

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
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
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

        .badge-success {
            background: var(--success-pale);
            color: var(--success);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }

        .alert {
            padding: 12px 16px;
            border-radius: var(--radius);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-warning {
            background: var(--warning-pale);
            border: 1px solid rgba(212,164,43,0.25);
            color: var(--warning);
        }
        .alert-success {
            background: var(--success-pale);
            border: 1px solid rgba(46,125,82,0.25);
            color: var(--success);
        }
        .alert-info {
            background: rgba(107,102,112,0.10);
            border: 1px solid rgba(107,102,112,0.25);
            color: var(--text-muted);
        }

        .chart-container { padding: 20px; height: 300px; position: relative; }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 3rem;
            margin-bottom: 15px;
            opacity: 0.5;
        }
        .empty-state h4 {
            font-family: var(--font-display);
            font-size: 1.2rem;
            margin-bottom: 10px;
            color: var(--navy);
        }

        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
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
        .mt-2 { margin-top: 8px; }
        .mt-4 { margin-top: 24px; }
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
            <div class="sidebar-brand-sub">ERP System</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="<%= contextPath %>/admin/dashboard" class="nav-item-link active">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Management</div>
        <a href="<%= contextPath %>/admin/users.jsp" class="nav-item-link">
            <i class="bi bi-people-fill"></i> User Management
        </a>
        <a href="<%= contextPath %>/admin/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> Products
        </a>
        <a href="<%= contextPath %>/admin/inventory.jsp" class="nav-item-link">
            <i class="bi bi-archive-fill"></i> Inventory
        </a>
        <a href="<%= contextPath %>/admin/categories.jsp" class="nav-item-link">
            <i class="bi bi-tags-fill"></i> Categories
        </a>

        <div class="nav-section-label">Operations</div>
        <a href="<%= contextPath %>/admin/sales.jsp" class="nav-item-link">
            <i class="bi bi-receipt"></i> Sales
        </a>
        <a href="<%= contextPath %>/admin/expenses.jsp" class="nav-item-link">
            <i class="bi bi-wallet2"></i> Expenses
        </a>
        <a href="<%= contextPath %>/admin/suppliers.jsp" class="nav-item-link">
            <i class="bi bi-truck"></i> Suppliers
        </a>
        <a href="<%= contextPath %>/admin/purchases.jsp" class="nav-item-link">
            <i class="bi bi-cart-fill"></i> Purchases
        </a>

        <div class="nav-section-label">Reports & Analytics</div>
        <a href="<%= contextPath %>/admin/reports.jsp" class="nav-item-link">
            <i class="bi bi-graph-up"></i> Reports
        </a>
        <a href="<%= contextPath %>/admin/analytics.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-steps"></i> Analytics
        </a>
        <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-line-fill"></i> BI & Finance
        </a>

        <div class="nav-section-label">System</div>
        <a href="<%= contextPath %>/admin/settings.jsp" class="nav-item-link">
            <i class="bi bi-gear-fill"></i> Settings
        </a>
        <a href="<%= contextPath %>/admin/security.jsp" class="nav-item-link">
            <i class="bi bi-shield-lock-fill"></i> Security
        </a>
        <a href="<%= contextPath %>/admin/backup.jsp" class="nav-item-link">
            <i class="bi bi-database-fill"></i> Backup & Recovery
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= adminName != null ? adminName : "Administrator" %></div>
            <div class="sidebar-admin-role">Administrator</div>
        </div>
        <a href="<%= contextPath %>/logout" class="sidebar-logout" title="Logout">
            <i class="bi bi-box-arrow-right"></i>
        </a>
    </div>
</aside>

<!-- Main Content -->
<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Admin Dashboard</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Welcome back</p>
                <h1 class="page-heading">Good day, <%= adminName != null ? adminName.split(" ")[0] : "Admin" %>.</h1>
                <p class="text-muted mt-2">Here's what's happening with your supermarket today.</p>
            </div>
            <div class="d-flex gap-3">
                <a href="<%= contextPath %>/admin/users.jsp" class="btn-sm-outline">
                    <i class="bi bi-person-plus-fill"></i> Add User
                </a>
                <a href="<%= contextPath %>/admin/backup.jsp" class="btn-sm-outline">
                    <i class="bi bi-cloud-arrow-up"></i> Backup
                </a>
            </div>
        </div>

        <!-- BI Dashboard Banner -->
        <div class="bi-banner">
            <div class="bi-banner-content">
                <h3><i class="bi bi-bar-chart-line-fill me-2"></i> Business Intelligence Dashboard</h3>
                <p>View advanced financial analytics, profit & loss trends, top products, and expense breakdowns</p>
            </div>
            <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="bi-banner-btn">
                <i class="bi bi-graph-up"></i> Launch BI Dashboard
                <i class="bi bi-arrow-right"></i>
            </a>
        </div>

        <!-- Stats Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-people-fill"></i></div>
                    <div class="stat-value"><%= totalUsers %></div>
                    <div class="stat-label">System Users</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-box-seam-fill"></i></div>
                    <div class="stat-value"><%= totalProducts %></div>
                    <div class="stat-label">Products</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                    <div class="stat-value"><%= totalSales %></div>
                    <div class="stat-label">Total Sales</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-truck"></i></div>
                    <div class="stat-value"><%= totalSuppliers %></div>
                    <div class="stat-label">Suppliers</div>
                </div>
            </div>
        </div>

        <!-- Financial Stats -->
        <div class="row g-3 mb-4">
            <div class="col-md-4 col-6">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(todaySales) %></div>
                            <div class="stat-label">Today's Sales</div>
                        </div>
                        <i class="bi bi-graph-up fs-1 text-success"></i>
                    </div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(todayExpenses) %></div>
                            <div class="stat-label">Today's Expenses</div>
                        </div>
                        <i class="bi bi-box-arrow-right fs-1 text-danger"></i>
                    </div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <div class="stat-value">R <%= df.format(profit) %></div>
                            <div class="stat-label">Today's Profit</div>
                        </div>
                        <i class="bi bi-trophy fs-1 text-success"></i>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Access Modules -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-grid-3x3-gap-fill"></i> Quick Access Modules
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="module-grid">
                    <a href="<%= contextPath %>/admin/users.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-people-fill"></i></div>
                        <div class="module-title">User Management</div>
                        <div class="module-desc">Create, edit, delete users</div>
                    </a>
                    <a href="<%= contextPath %>/admin/products.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-box-seam-fill"></i></div>
                        <div class="module-title">Products</div>
                        <div class="module-desc">Manage product catalog</div>
                    </a>
                    <a href="<%= contextPath %>/admin/inventory.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-archive-fill"></i></div>
                        <div class="module-title">Inventory</div>
                        <div class="module-desc">Track stock levels</div>
                    </a>
                    <a href="<%= contextPath %>/admin/sales.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-receipt"></i></div>
                        <div class="module-title">Sales</div>
                        <div class="module-desc">View sales history</div>
                    </a>
                    <a href="<%= contextPath %>/admin/expenses.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-wallet2"></i></div>
                        <div class="module-title">Expenses</div>
                        <div class="module-desc">Track expenses</div>
                    </a>
                    <a href="<%= contextPath %>/admin/suppliers.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-truck"></i></div>
                        <div class="module-title">Suppliers</div>
                        <div class="module-desc">Manage suppliers</div>
                    </a>
                    <a href="<%= contextPath %>/admin/purchases.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-cart-fill"></i></div>
                        <div class="module-title">Purchases</div>
                        <div class="module-desc">Procurement orders</div>
                    </a>
                    <a href="<%= contextPath %>/admin/reports.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-graph-up"></i></div>
                        <div class="module-title">Reports</div>
                        <div class="module-desc">Financial reports</div>
                    </a>
                    <a href="<%= contextPath %>/admin/categories.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-tags-fill"></i></div>
                        <div class="module-title">Categories</div>
                        <div class="module-desc">Manage categories</div>
                    </a>
                    <a href="<%= contextPath %>/admin/settings.jsp" class="module-card">
                        <div class="module-icon"><i class="bi bi-gear-fill"></i></div>
                        <div class="module-title">Settings</div>
                        <div class="module-desc">System settings</div>
                    </a>
                    <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="module-card" style="background: linear-gradient(135deg, var(--cream-dark) 0%, var(--cream) 100%); border-color: var(--gold);">
                        <div class="module-icon"><i class="bi bi-bar-chart-line-fill" style="color: var(--gold);"></i></div>
                        <div class="module-title">BI & Financial Dashboard</div>
                        <div class="module-desc">Advanced analytics & KPIs</div>
                    </a>
                </div>
            </div>
        </div>

        <div class="row g-3 mb-4">
            <div class="col-md-8">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-graph-up"></i> Sales Overview (Last 7 Days)
                        </h2>
                        <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="btn-sm-outline">
                            <i class="bi bi-bar-chart-line-fill"></i> View Detailed Analytics
                        </a>
                    </div>
                    <div class="chart-container">
                        <canvas id="salesChart"></canvas>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-bell-fill"></i> Alerts
                        </h2>
                    </div>
                    <div style="padding: 20px;">
                        <% if (lowStockCount > 0) { %>
                            <div class="alert alert-warning">
                                <i class="bi bi-exclamation-triangle-fill"></i>
                                <strong><%= lowStockCount %></strong> products are below reorder level. 
                                Please review inventory.
                            </div>
                        <% } else { %>
                            <div class="alert alert-success">
                                <i class="bi bi-check-circle-fill"></i>
                                All stock levels are healthy.
                            </div>
                        <% } %>
                        <div class="alert alert-info mt-2">
                            <i class="bi bi-graph-up"></i>
                            <strong>BI Dashboard Available!</strong><br>
                            <small>View advanced financial analytics and KPIs</small>
                            <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="btn-sm-outline mt-2 d-block text-center">
                                Launch BI Dashboard <i class="bi bi-arrow-right"></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>


        <!-- Recent Sales Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-clock-history"></i> Recent Transactions
                </h2>
                <a href="${pageContext.request.contextPath}/admin/sales.jsp" class="btn-sm-outline">
                    View All <i class="bi bi-arrow-right"></i>
                </a>
            </div>
            <div class="table-responsive">
                <% if (recentSales != null && !recentSales.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Invoice No.</th>
                                <th>Date</th>
                                <th>Cashier</th>
                                <th>Amount</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (mpeoa.models.Sale sale : recentSales) { %>
                                <tr>
                                    <td><%= sale.getInvoiceNumber() %></td>
                                    <td><%= sale.getSaleDate() %></td>
                                    <td><%= sale.getUserName() != null ? sale.getUserName() : "Staff" %></td>
                                    <td class="fw-bold">R <%= df.format(sale.getFinalAmount()) %></td>
                                    <td><span class="badge-success">Completed</span></td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-receipt"></i>
                        <h4>No Transactions Yet</h4>
                        <p>Sales transactions will appear here once cashiers start processing sales.</p>
                        <a href="${pageContext.request.contextPath}/pos" class="btn-sm-outline">
                            <i class="bi bi-cash-register"></i> Go to POS
                        </a>
                    </div>
                <% } %>
            </div>
        </div>
        
        
        <!-- Welcome Message for Empty System -->
        <% if (totalSales == 0 && lowStockCount == 0 && totalProducts == 0) { %>
            <div class="content-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-rocket-takeoff-fill"></i> Getting Started
                    </h2>
                </div>
                <div class="empty-state" style="padding: 40px;">
                    <i class="bi bi-shop"></i>
                    <h4>Welcome to Mpeoa ERP System!</h4>
                    <p>Your supermarket management system is ready. Here's how to get started:</p>
                    <div class="d-flex justify-content-center gap-3 flex-wrap mt-4">
                        <a href="<%= contextPath %>/admin/categories.jsp" class="btn-sm-outline">
                            <i class="bi bi-tags-fill"></i> Add Categories
                        </a>
                        <a href="<%= contextPath %>/admin/products.jsp" class="btn-sm-outline">
                            <i class="bi bi-box-seam-fill"></i> Add Products
                        </a>
                        <a href="<%= contextPath %>/admin/users.jsp" class="btn-sm-outline">
                            <i class="bi bi-people-fill"></i> Add Staff Users
                        </a>
                        <a href="<%= contextPath %>/admin/suppliers.jsp" class="btn-sm-outline">
                            <i class="bi bi-truck"></i> Add Suppliers
                        </a>
                        <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="btn-sm-outline">
                            <i class="bi bi-bar-chart-line-fill"></i> View BI Dashboard
                        </a>
                    </div>
                </div>
            </div>
        <% } %>
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
    
    // Sales Chart - NOW USING REAL DATA FROM DATABASE
    const ctx = document.getElementById('salesChart').getContext('2d');
    const weeklyData = [<%= chartData.toString() %>];
    
    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            datasets: [{
                label: 'Sales (R)',
                data: weeklyData,
                backgroundColor: 'rgba(200,146,58,0.7)',
                borderColor: '#C8923A',
                borderWidth: 2,
                borderRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            plugins: {
                legend: {
                    position: 'top',
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            let value = context.raw;
                            if (value === 0) {
                                return 'No sales recorded';
                            }
                            return 'R ' + value.toLocaleString('en-ZA', {minimumFractionDigits: 2});
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    title: {
                        display: true,
                        text: 'Amount (R)',
                        color: '#6B6670'
                    },
                    ticks: {
                        callback: function(value) {
                            return 'R ' + value.toLocaleString();
                        }
                    }
                },
                x: {
                    title: {
                        display: true,
                        text: 'Day of Week',
                        color: '#6B6670'
                    }
                }
            }
        }
    });
</script>

</body>
</html>