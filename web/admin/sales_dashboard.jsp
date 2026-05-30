<%-- web/admin/sales_dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User" %>
<%@ page import="mpeoa.dao.SaleDAO" %>
<%@ page import="mpeoa.dao.ProductDAO" %>
<%@ page import="mpeoa.models.Product" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.sql.*" %>
<%
    // Access Control
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Administrator".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    // DAOs
    SaleDAO saleDAO = new SaleDAO();
    ProductDAO productDAO = new ProductDAO();

    // Date Range
    String period = request.getParameter("period");
    if (period == null) period = "month";

    java.sql.Date endDate = new java.sql.Date(System.currentTimeMillis());
    Calendar cal = Calendar.getInstance();
    String periodLabel = "";

    if (period.equals("week")) {
        cal.add(Calendar.DAY_OF_MONTH, -7);
        periodLabel = "Last 7 Days";
    } else if (period.equals("quarter")) {
        cal.add(Calendar.MONTH, -3);
        periodLabel = "Last 3 Months";
    } else if (period.equals("year")) {
        cal.add(Calendar.YEAR, -1);
        periodLabel = "Last 12 Months";
    } else {
        period = "month";
        cal.add(Calendar.MONTH, -1);
        periodLabel = "Last 30 Days";
    }
    java.sql.Date startDate = new java.sql.Date(cal.getTimeInMillis());
    
    // Debug: Print dates to see what range is being queried
    System.out.println("Start Date: " + startDate);
    System.out.println("End Date: " + endDate);

    // Sales Metrics
    BigDecimal totalRevenue = saleDAO.getTotalSalesByDateRange(startDate, endDate);
    if (totalRevenue == null) totalRevenue = BigDecimal.ZERO;
    
    // Get actual cost from database
    BigDecimal totalCost = saleDAO.getTotalCostByDateRange(startDate, endDate);
    
    BigDecimal grossProfit = totalRevenue.subtract(totalCost);
    BigDecimal profitMargin = BigDecimal.ZERO;
    if (totalRevenue.compareTo(BigDecimal.ZERO) > 0) {
        profitMargin = grossProfit.divide(totalRevenue, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100));
    }
    
    // Get actual transaction count from database
    int totalTransactions = saleDAO.getTransactionCountByDateRange(startDate, endDate);
    BigDecimal avgTransactionValue = BigDecimal.ZERO;
    if (totalTransactions > 0) {
        avgTransactionValue = totalRevenue.divide(new BigDecimal(totalTransactions), 2, BigDecimal.ROUND_HALF_UP);
    }

    // Trend Data - Daily Sales
    List<Object[]> dailySales = saleDAO.getDailySalesForPeriod(startDate, endDate);
    if (dailySales == null) dailySales = new ArrayList<Object[]>();
    
    // Debug: Print daily sales count
    System.out.println("Daily Sales records found: " + dailySales.size());
    for (Object[] row : dailySales) {
        System.out.println("Date: " + row[0] + " - Amount: " + row[1]);
    }
    
    // Get REAL hourly sales data from database
    List<Object[]> hourlySales = saleDAO.getHourlySalesForPeriod(startDate, endDate);
    if (hourlySales == null) hourlySales = new ArrayList<Object[]>();
    
    // Get all products
    List<Product> allProducts = productDAO.getAllProducts();
    if (allProducts == null) allProducts = new ArrayList<Product>();
    
    // Get REAL top selling products from database
    List<Object[]> topProducts = saleDAO.getTopSellingProducts(startDate, endDate, 5);
    if (topProducts == null) topProducts = new ArrayList<Object[]>();
    
    // Get REAL category sales from database
    List<Object[]> salesByCategory = saleDAO.getSalesByCategoryForPeriod(startDate, endDate);
    if (salesByCategory == null) salesByCategory = new ArrayList<Object[]>();
    
    // Previous Period Comparison
    Calendar prevCal = Calendar.getInstance();
    prevCal.setTime(startDate);
    long daysDiff = (endDate.getTime() - startDate.getTime()) / 86400000L;
    if (daysDiff < 1) daysDiff = 1;
    prevCal.add(Calendar.DAY_OF_MONTH, -(int)daysDiff);
    java.sql.Date prevStartDate = new java.sql.Date(prevCal.getTimeInMillis());
    java.sql.Date prevEndDate = startDate;
    
    BigDecimal prevRevenue = saleDAO.getTotalSalesByDateRange(prevStartDate, prevEndDate);
    if (prevRevenue == null) prevRevenue = BigDecimal.ZERO;
    BigDecimal revenueChange = totalRevenue.subtract(prevRevenue);
    double revenueChangePercent = 0.0;
    if (prevRevenue.compareTo(BigDecimal.ZERO) > 0) {
        revenueChangePercent = revenueChange.divide(prevRevenue, 4, BigDecimal.ROUND_HALF_UP).multiply(new BigDecimal(100)).doubleValue();
    } else if (totalRevenue.compareTo(BigDecimal.ZERO) > 0) {
        revenueChangePercent = 100.0;
    }

    // Chart Data Strings
    StringBuilder salesLabels = new StringBuilder();
    StringBuilder salesValues = new StringBuilder();
    for (Object[] row : dailySales) {
        if (row[0] != null && row[1] != null) {
            salesLabels.append("'").append(row[0].toString()).append("',");
            salesValues.append(row[1].toString()).append(",");
        }
    }
    
    StringBuilder productLabels = new StringBuilder();
    StringBuilder productValues = new StringBuilder();
    BigDecimal maxProductValue = BigDecimal.ZERO;
    for (Object[] row : topProducts) {
        BigDecimal val = new BigDecimal(row[1].toString());
        if (val.compareTo(maxProductValue) > 0) maxProductValue = val;
    }
    for (Object[] row : topProducts) {
        String name = row[0].toString();
        if (name.length() > 20) name = name.substring(0, 17) + "...";
        productLabels.append("'").append(name.replace("'", "\\'")).append("',");
        productValues.append(row[1].toString()).append(",");
    }
    
    StringBuilder categoryLabels = new StringBuilder();
    StringBuilder categoryValues = new StringBuilder();
    for (Object[] row : salesByCategory) {
        categoryLabels.append("'").append(row[0].toString()).append("',");
        categoryValues.append(row[1].toString()).append(",");
    }
    
    // Find peak hours from REAL hourly sales data
    String peakHours = "";
    if (!hourlySales.isEmpty()) {
        List<Integer> peakHourList = new ArrayList<Integer>();
        BigDecimal maxValue = BigDecimal.ZERO;
        for (Object[] row : hourlySales) {
            BigDecimal val = new BigDecimal(row[1].toString());
            if (val.compareTo(maxValue) > 0) {
                maxValue = val;
            }
        }
        BigDecimal threshold = maxValue.multiply(new BigDecimal("0.6"));
        for (Object[] row : hourlySales) {
            BigDecimal val = new BigDecimal(row[1].toString());
            if (val.compareTo(threshold) >= 0 && val.compareTo(BigDecimal.ZERO) > 0) {
                int hour = (Integer)row[0];
                peakHourList.add(hour);
            }
        }
        StringBuilder peakBuilder = new StringBuilder();
        for (int i = 0; i < peakHourList.size(); i++) {
            int h = peakHourList.get(i);
            peakBuilder.append(h).append(":00-").append(h+1).append(":00");
            if (i < peakHourList.size() - 1) peakBuilder.append(", ");
        }
        peakHours = peakBuilder.toString();
        if (peakHours.isEmpty()) peakHours = "No significant peaks detected";
    } else {
        peakHours = "No hourly data available";
    }

    // Formatters
    DecimalFormat df = new DecimalFormat("#,##0.00");
    DecimalFormat pf = new DecimalFormat("#,##0.0");
    DecimalFormat sf = new DecimalFormat("#,##0");

    // Admin Initials
    String initials = "A";
    String adminName = loggedInUser.getFullName();
    if (adminName != null && !adminName.trim().isEmpty()) {
        String[] parts = adminName.trim().split("\\s+");
        if (parts.length >= 2) {
            initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        } else {
            initials = "" + parts[0].charAt(0);
        }
        initials = initials.toUpperCase();
    }
    
    String contextPath = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sales BI Dashboard - Mpeoa Supermarket ERP</title>

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
            --radius:        12px;
            --shadow:        0 2px 16px rgba(18,34,58,0.08);
            --shadow-md:     0 4px 24px rgba(18,34,58,0.12);
            --font-display:  'Playfair Display', Georgia, serif;
            --font-body:     'DM Sans', sans-serif;
        }

        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            margin: 0;
            min-height: 100vh;
        }

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
        .sidebar-logout { margin-left: auto; background: none; border: none; color: rgba(255,255,255,0.3); font-size: 1rem; cursor: pointer; }
        .sidebar-logout:hover { color: #e74c3c; }
        .sidebar-overlay { display: none; position: fixed; inset: 0; background: rgba(18,34,58,0.55); z-index: 1039; backdrop-filter: blur(2px); }
        .sidebar-overlay.show { display: block; }

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

        .pill-row { display: flex; gap: 8px; flex-wrap: wrap; }
        .pill {
            padding: 6px 18px; border-radius: 30px; font-size: 0.75rem; font-weight: 600;
            text-decoration: none; color: var(--navy); background: var(--white);
            border: 1px solid var(--cream-border); transition: all 0.2s;
        }
        .pill:hover { border-color: var(--gold); color: var(--gold); background: var(--gold-pale); }
        .pill.active { background: var(--gold); color: var(--white); border-color: var(--gold); }

        .kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-bottom: 24px; }
        .kpi-card {
            background: var(--white); border: 1px solid var(--cream-border);
            border-radius: var(--radius); padding: 20px;
            position: relative; overflow: hidden;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .kpi-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
        .kpi-card::after { content: ''; position: absolute; top: 0; left: 0; right: 0; height: 3px; }
        .kpi-card.gold::after { background: var(--gold); }
        .kpi-card.success::after { background: var(--success); }
        .kpi-card.info::after { background: var(--info); }
        .kpi-card.warning::after { background: var(--warning); }
        .kpi-icon { font-size: 1.5rem; margin-bottom: 12px; }
        .kpi-card.gold .kpi-icon { color: var(--gold); }
        .kpi-card.success .kpi-icon { color: var(--success); }
        .kpi-card.info .kpi-icon { color: var(--info); }
        .kpi-card.warning .kpi-icon { color: var(--warning); }
        .kpi-val { font-family: var(--font-display); font-size: 1.6rem; font-weight: 700; line-height: 1; margin-bottom: 6px; }
        .kpi-label { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.08em; color: var(--text-muted); font-weight: 600; }
        .kpi-sub { font-size: 0.7rem; color: var(--text-muted); margin-top: 6px; }
        .trend-up { color: var(--success); }
        .trend-down { color: var(--danger); }

        .chart-card {
            background: var(--white); border: 1px solid var(--cream-border);
            border-radius: var(--radius); overflow: hidden; margin-bottom: 24px;
        }
        .cc-head {
            padding: 16px 20px; border-bottom: 1px solid var(--cream-border);
            background: var(--cream-dark);
            display: flex; justify-content: space-between; align-items: center;
            flex-wrap: wrap; gap: 10px;
        }
        .cc-title {
            font-family: var(--font-display); font-size: 0.95rem; font-weight: 700;
            color: var(--navy); display: flex; align-items: center; gap: 8px;
        }
        .cc-badge { font-size: 0.7rem; color: var(--text-muted); background: var(--cream); padding: 4px 10px; border-radius: 20px; }
        .cc-body { padding: 20px; }

        .top-products-table {
            width: 100%;
            border-collapse: collapse;
        }
        .top-products-table th,
        .top-products-table td {
            padding: 10px 8px;
            border-bottom: 1px solid var(--cream-border);
            text-align: left;
        }
        .top-products-table th {
            font-size: 0.7rem;
            font-weight: 600;
            text-transform: uppercase;
            color: var(--text-muted);
            letter-spacing: 0.05em;
        }
        .top-products-table td {
            font-size: 0.8rem;
        }
        .rank-badge {
            display: inline-block;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            background: var(--gold-pale);
            color: var(--gold);
            text-align: center;
            line-height: 24px;
            font-size: 0.7rem;
            font-weight: 700;
        }

        .hourly-grid {
            display: flex;
            align-items: flex-end;
            gap: 6px;
            height: 220px;
            padding-top: 20px;
            overflow-x: auto;
        }
        .hourly-bar-container {
            flex: 1;
            min-width: 40px;
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 6px;
        }
        .hourly-bar {
            width: 100%;
            background: var(--gold);
            border-radius: 4px 4px 0 0;
            transition: height 0.3s;
            min-height: 2px;
        }
        .hourly-label {
            font-size: 0.6rem;
            color: var(--text-muted);
            text-align: center;
        }
        .hourly-value {
            font-size: 0.65rem;
            font-weight: 600;
            color: var(--gold);
        }

        .insight-item {
            background: var(--cream);
            padding: 12px 16px;
            border-radius: var(--radius);
            font-size: 0.8rem;
            color: var(--text-muted);
            line-height: 1.5;
            margin-bottom: 12px;
        }
        .text-gold { color: var(--gold); }

        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .anim { animation: fadeUp 0.4s ease both; }
        .anim-d1 { animation-delay: 0.05s; }
        .anim-d2 { animation-delay: 0.10s; }
        .anim-d3 { animation-delay: 0.15s; }
        .anim-d4 { animation-delay: 0.20s; }
        
        .mt-3 { margin-top: 16px; }
        .text-center { text-align: center; }
        .text-muted { color: var(--text-muted); }
        .fw-bold { font-weight: 700; }
        .py-4 { padding-top: 24px; padding-bottom: 24px; }
        .small { font-size: 0.75rem; }
        .me-2 { margin-right: 8px; }
        .mt-2 { margin-top: 8px; }
        .mb-0 { margin-bottom: 0; }
    </style>
</head>
<body>

<div class="sidebar-overlay" id="sidebarOverlay" onclick="closeSidebar()"></div>

<aside class="sidebar" id="sidebar">
    <button class="sidebar-close" onclick="closeSidebar()">
        <i class="bi bi-x-lg"></i>
    </button>
    <div class="sidebar-brand">
        <div class="sidebar-logo">MS</div>
        <div class="sidebar-brand-text">
            <div class="sidebar-brand-name">Mpeoa Supermarket</div>
            <div class="sidebar-brand-sub">Admin Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="<%= contextPath %>/admin/dashboard" class="nav-item-link">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Management</div>
        <a href="<%= contextPath %>/admin/users.jsp" class="nav-item-link">
            <i class="bi bi-people-fill"></i> Users
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

        <div class="nav-section-label">Insights</div>
        <a href="<%= contextPath %>/admin/bi_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-graph-up"></i> BI and Finance
        </a>
        <a href="<%= contextPath %>/admin/cashflow_dashboard.jsp" class="nav-item-link">
            <i class="bi bi-arrow-left-right"></i> Cash Flow
        </a>
        <a href="<%= contextPath %>/admin/sales_dashboard.jsp" class="nav-item-link active">
            <i class="bi bi-bar-chart-line-fill"></i> Sales BI
        </a>
        <a href="<%= contextPath %>/admin/reports.jsp" class="nav-item-link">
            <i class="bi bi-file-text-fill"></i> Reports
        </a>
        <a href="<%= contextPath %>/admin/analytics.jsp" class="nav-item-link">
            <i class="bi bi-bar-chart-steps"></i> Analytics
        </a>

        <div class="nav-section-label">System</div>
        <a href="<%= contextPath %>/admin/settings.jsp" class="nav-item-link">
            <i class="bi bi-gear-fill"></i> Settings
        </a>
        <a href="<%= contextPath %>/admin/security.jsp" class="nav-item-link">
            <i class="bi bi-shield-lock-fill"></i> Security
        </a>
        <a href="<%= contextPath %>/admin/backup.jsp" class="nav-item-link">
            <i class="bi bi-database-fill"></i> Backup
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

<div class="main-wrap">
    <header class="topbar">
        <button class="burger-btn" onclick="openSidebar()"><i class="bi bi-list"></i></button>
        <span class="topbar-title">Sales BI Dashboard</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">

        <div class="page-header anim">
            <div>
                <p class="page-eyebrow">Business Intelligence</p>
                <h1 class="page-heading">Sales Analytics</h1>
                <p class="text-muted mt-2">Revenue · products · categories · performance — <%= periodLabel %></p>
                <p class="text-muted small mt-1">Based on <%= totalTransactions %> transactions totaling R <%= df.format(totalRevenue) %></p>
            </div>
            <div class="pill-row">
                <a href="?period=week"    class="pill <%= "week".equals(period) ? "active" : "" %>">7 Days</a>
                <a href="?period=month"   class="pill <%= "month".equals(period) ? "active" : "" %>">30 Days</a>
                <a href="?period=quarter" class="pill <%= "quarter".equals(period) ? "active" : "" %>">Quarter</a>
                <a href="?period=year"    class="pill <%= "year".equals(period) ? "active" : "" %>">Year</a>
            </div>
        </div>

        <div class="kpi-grid anim anim-d1">
            <div class="kpi-card gold">
                <div class="kpi-icon"><i class="bi bi-cash-stack"></i></div>
                <div class="kpi-val">R <%= df.format(totalRevenue) %></div>
                <div class="kpi-label">Total Revenue</div>
                <div class="kpi-sub">
                    <span class="<%= revenueChangePercent >= 0 ? "trend-up" : "trend-down" %>">
                        <i class="bi bi-arrow-<%= revenueChangePercent >= 0 ? "up" : "down" %>-short"></i>
                        <%= pf.format(Math.abs(revenueChangePercent)) %>% vs previous
                    </span>
                </div>
            </div>

            <div class="kpi-card success">
                <div class="kpi-icon"><i class="bi bi-graph-up"></i></div>
                <div class="kpi-val">R <%= df.format(grossProfit) %></div>
                <div class="kpi-label">Gross Profit</div>
                <div class="kpi-sub"><%= pf.format(profitMargin) %>% margin</div>
            </div>

            <div class="kpi-card info">
                <div class="kpi-icon"><i class="bi bi-receipt"></i></div>
                <div class="kpi-val"><%= sf.format(totalTransactions) %></div>
                <div class="kpi-label">Transactions</div>
                <div class="kpi-sub">Avg R <%= df.format(avgTransactionValue) %></div>
            </div>

            <div class="kpi-card warning">
                <div class="kpi-icon"><i class="bi bi-box-seam"></i></div>
                <div class="kpi-val"><%= allProducts.size() %></div>
                <div class="kpi-label">Total Products</div>
                <div class="kpi-sub">In inventory catalog</div>
            </div>
        </div>

        <div class="row g-3 anim anim-d2">
            <div class="col-lg-7">
                <div class="chart-card">
                    <div class="cc-head">
                        <div class="cc-title">
                            <i class="bi bi-activity" style="color: var(--gold)"></i>
                            Sales Trend (Daily Revenue)
                        </div>
                        <div class="cc-badge"><%= periodLabel %></div>
                    </div>
                    <div class="cc-body">
                        <% if (!dailySales.isEmpty()) { %>
                        <div style="position: relative; width: 100%; height: 320px;">
                            <canvas id="salesTrendChart"></canvas>
                        </div>
                        <div class="text-muted small text-center mt-2">
                            <i class="bi bi-info-circle"></i> Each point shows total sales for that day
                        </div>
                        <% } else { %>
                        <div class="text-center py-4">
                            <i class="bi bi-bar-chart-line" style="font-size: 2rem; color: var(--text-muted);"></i>
                            <p class="text-muted mt-2">No sales trend data available for <%= periodLabel %></p>
                            <p class="text-muted small">Try selecting a different period or add more sales records.</p>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="col-lg-5">
                <div class="chart-card">
                    <div class="cc-head">
                        <div class="cc-title">
                            <i class="bi bi-trophy-fill" style="color: var(--gold)"></i>
                            Top Selling Products
                        </div>
                        <div class="cc-badge">By revenue</div>
                    </div>
                    <div class="cc-body">
                        <% if (!topProducts.isEmpty()) { %>
                        <table class="top-products-table">
                            <thead>
                                <tr><th>Rank</th><th>Product</th><th>Revenue</th></tr>
                            </thead>
                            <tbody>
                                <% int rank = 1; for (Object[] row : topProducts) { 
                                    String productName = row[0].toString();
                                    if (productName.length() > 25) productName = productName.substring(0, 22) + "...";
                                %>
                                <tr>
                                    <td style="width: 50px;"><span class="rank-badge"><%= rank++ %></span></td>
                                    <td><%= productName %></td>
                                    <td class="fw-bold">R <%= df.format(new BigDecimal(row[1].toString())) %></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                        <div class="text-muted small mt-2 text-center">* Based on actual sales data</div>
                        <% } else { %>
                        <div class="text-center py-4 text-muted">No product sales data available</div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3 anim anim-d3">
            <div class="col-lg-6">
                <div class="chart-card" style="margin-bottom: 0; height: 100%;">
                    <div class="cc-head">
                        <div class="cc-title">
                            <i class="bi bi-pie-chart-fill" style="color: var(--gold)"></i>
                            Sales by Category
                        </div>
                    </div>
                    <div class="cc-body">
                        <% if (!salesByCategory.isEmpty()) { %>
                        <div style="position: relative; width: 100%; height: 300px;">
                            <canvas id="categoryChart"></canvas>
                        </div>
                        <% } else { %>
                        <div class="text-center py-4 text-muted">No category data available</div>
                        <% } %>
                    </div>
                </div>
            </div>

            <div class="col-lg-6">
                <div class="chart-card" style="margin-bottom: 0; height: 100%;">
                    <div class="cc-head">
                        <div class="cc-title">
                            <i class="bi bi-clock-history" style="color: var(--warning)"></i>
                            Hourly Sales Distribution
                        </div>
                        <div class="cc-badge">When sales happen</div>
                    </div>
                    <div class="cc-body">
                        <% if (!hourlySales.isEmpty()) { 
                            double maxHourly = 0;
                            for (Object[] row : hourlySales) {
                                double val = new BigDecimal(row[1].toString()).doubleValue();
                                if (val > maxHourly) maxHourly = val;
                            }
                        %>
                        <div class="hourly-grid">
                            <% for (Object[] row : hourlySales) { 
                                double val = new BigDecimal(row[1].toString()).doubleValue();
                                int heightPercent = maxHourly > 0 ? (int)((val / maxHourly) * 160) : 0;
                                int hour = (Integer)row[0];
                            %>
                            <div class="hourly-bar-container">
                                <div class="hourly-value">R<%= sf.format(val) %></div>
                                <div class="hourly-bar" style="height: <%= heightPercent %>px; background: var(--gold)"></div>
                                <div class="hourly-label"><%= hour %>h</div>
                            </div>
                            <% } %>
                        </div>
                        <div class="text-center mt-3 small text-muted">
                            <i class="bi bi-info-circle"></i> Peak hours: <%= peakHours %>
                        </div>
                        <% } else { %>
                        <div class="text-center py-4 text-muted">No hourly sales data available</div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <div class="chart-card mt-3 anim" style="animation-delay: 0.25s">
            <div class="cc-head">
                <div class="cc-title">
                    <i class="bi bi-lightbulb-fill" style="color: var(--warning)"></i>
                    Sales Insights and Recommendations
                </div>
                <div class="cc-badge"><%= periodLabel %></div>
            </div>
            <div class="cc-body">
                <div class="row">
                    <div class="col-md-6">
                        <div class="insight-item">
                            <i class="bi bi-graph-up text-success me-2"></i>
                            <strong>Revenue Performance:</strong>
                            <%= revenueChangePercent >= 0 
                                ? "Revenue increased by " + pf.format(revenueChangePercent) + "% compared to previous period. Great growth!"
                                : "Revenue decreased by " + pf.format(Math.abs(revenueChangePercent)) + "%. Consider promotional activities." %>
                        </div>
                        <div class="insight-item">
                            <i class="bi bi-box-seam text-gold me-2"></i>
                            <strong>Product Focus:</strong>
                            <% if (!topProducts.isEmpty()) { %>
                                "<%= topProducts.get(0)[0] %>" is your top seller generating R <%= df.format(new BigDecimal(topProducts.get(0)[1].toString())) %>.
                            <% } else { %>
                                No product sales data available yet.
                            <% } %>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="insight-item">
                            <i class="bi bi-calculator-fill text-info me-2"></i>
                            <strong>Margin Analysis:</strong>
                            <%= profitMargin.compareTo(new BigDecimal(25)) >= 0
                                ? "Profit margin of " + pf.format(profitMargin) + "%. Maintain pricing strategy."
                                : "Profit margin is " + pf.format(profitMargin) + "%. Review cost of goods or adjust pricing." %>
                        </div>
                        <div class="insight-item">
                            <i class="bi bi-clock-fill text-warning me-2"></i>
                            <strong>Peak Hours:</strong>
                            <% if (!peakHours.isEmpty() && !peakHours.equals("No significant peaks detected") && !peakHours.equals("No hourly data available")) { %>
                                Busiest hours: <%= peakHours %>. Consider scheduling more staff during these times.
                            <% } else { %>
                                No significant peak hours detected from current data.
                            <% } %>
                        </div>
                    </div>
                </div>
                <div class="alert alert-info mt-3 mb-0" style="background: var(--info-pale); border-color: var(--info-pale); color: var(--info); font-size: 0.75rem;">
                    <i class="bi bi-database-fill me-2"></i>
                    Data shown is from actual sales records in your database for <%= periodLabel %>.
                </div>
            </div>
        </div>

    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
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

    Chart.defaults.color = '#6B6670';
    Chart.defaults.font.family = 'DM Sans, sans-serif';
    Chart.defaults.font.size = 11;

    <% if (!dailySales.isEmpty()) { %>
    var trendCtx = document.getElementById('salesTrendChart').getContext('2d');
    var trendGrad = trendCtx.createLinearGradient(0, 0, 0, 320);
    trendGrad.addColorStop(0, 'rgba(200,146,58,0.15)');
    trendGrad.addColorStop(1, 'rgba(200,146,58,0.00)');

    var salesLabels = [<%= salesLabels.toString().replaceAll(",$", "") %>];
    var salesValues = [<%= salesValues.toString().replaceAll(",$", "") %>];

    new Chart(trendCtx, {
        type: 'line',
        data: {
            labels: salesLabels,
            datasets: [{
                label: 'Daily Revenue (R)',
                data: salesValues,
                borderColor: '#C8923A',
                backgroundColor: trendGrad,
                tension: 0.4,
                fill: true,
                pointRadius: 4,
                pointHoverRadius: 6,
                pointBackgroundColor: '#C8923A',
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#FFFFFF',
                    borderColor: '#DDD8CE',
                    borderWidth: 1,
                    padding: 10,
                    titleColor: '#12223A',
                    bodyColor: '#6B6670',
                    callbacks: {
                        label: function(ctx) {
                            return ' R ' + Number(ctx.raw).toLocaleString('en-ZA', {minimumFractionDigits: 2});
                        }
                    }
                }
            },
            scales: {
                x: {
                    ticks: { maxRotation: 45, color: '#6B6670' },
                    grid: { color: '#EDE6D4' },
                    title: {
                        display: true,
                        text: 'Date',
                        color: '#6B6670',
                        font: { size: 10 }
                    }
                },
                y: {
                    ticks: {
                        color: '#6B6670',
                        callback: function(v) {
                            if (v >= 1000000) {
                                return 'R ' + (v / 1000000).toFixed(1) + 'M';
                            }
                            return 'R ' + v.toLocaleString();
                        }
                    },
                    grid: { color: '#EDE6D4' },
                    title: {
                        display: true,
                        text: 'Revenue (R)',
                        color: '#6B6670',
                        font: { size: 10 }
                    }
                }
            }
        }
    });
    <% } %>

    <% if (!salesByCategory.isEmpty()) { %>
    var categoryLabels = [<%= categoryLabels.toString().replaceAll(",$", "") %>];
    var categoryValues = [<%= categoryValues.toString().replaceAll(",$", "") %>];
    
    new Chart(document.getElementById('categoryChart').getContext('2d'), {
        type: 'doughnut',
        data: {
            labels: categoryLabels,
            datasets: [{
                data: categoryValues,
                backgroundColor: ['#C8923A', '#2E7D52', '#D4A42B', '#17A2B8', '#C0392B', '#AB47BC', '#42A5F5', '#66BB6A'],
                borderWidth: 0,
                hoverOffset: 5
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '60%',
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { font: { size: 10 }, boxWidth: 10 }
                },
                tooltip: {
                    backgroundColor: '#FFFFFF',
                    borderColor: '#DDD8CE',
                    borderWidth: 1,
                    titleColor: '#12223A',
                    bodyColor: '#6B6670',
                    callbacks: {
                        label: function(ctx) {
                            var value = ctx.raw;
                            var total = ctx.dataset.data.reduce(function(a, b) { return a + b; }, 0);
                            var percent = ((value / total) * 100).toFixed(1);
                            return ' R ' + value.toLocaleString('en-ZA', {minimumFractionDigits: 2}) + ' (' + percent + '%)';
                        }
                    }
                }
            }
        }
    });
    <% } %>
</script>

</body>
</html>