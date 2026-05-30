<%-- web/cashier/dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.SaleDAO, mpeoa.dao.ProductDAO, java.text.*, java.math.BigDecimal, java.util.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Cashier".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Initialize DAOs
    SaleDAO saleDAO = new SaleDAO();
    ProductDAO productDAO = new ProductDAO();
    
    // Get today's date
    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
    java.sql.Date weekAgo = new java.sql.Date(System.currentTimeMillis() - 7 * 24 * 60 * 60 * 1000L);
    
    // Sales Data
    BigDecimal todaySales = saleDAO.getTotalSalesToday();
    int todayTransactions = saleDAO.getTodayTransactionCount();
    BigDecimal weekSales = saleDAO.getTotalSalesByDateRange(weekAgo, today);
    int weekTransactions = saleDAO.getWeekTransactionCount();
    
    // Get recent sales by this cashier
    int userId = loggedInUser.getUserId();
    List<mpeoa.models.Sale> myRecentSales = saleDAO.getSalesByCashier(userId, 5);
    
    // Get all products for quick view
    List<mpeoa.models.Product> products = productDAO.getAllProducts();
    int totalProducts = products.size();
    int lowStockCount = productDAO.getLowStockProducts().size();
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Build initials
    String initials = "A";
    String cashierName = loggedInUser.getFullName();
    if (cashierName != null && !cashierName.trim().isEmpty()) {
        String[] parts = cashierName.trim().split("\\s+");
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
    <title>Cashier Dashboard — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    
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

        /* Action Cards */
        .action-cards {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .action-card {
            background: var(--white);
            border-radius: var(--radius);
            padding: 25px;
            text-align: center;
            border: 1px solid var(--cream-border);
            transition: all 0.3s;
            text-decoration: none;
            color: var(--navy);
            display: block;
            cursor: pointer;
        }
        .action-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            border-color: var(--gold);
        }
        .action-icon {
            font-size: 2.5rem;
            margin-bottom: 15px;
            color: var(--gold);
        }
        .action-title {
            font-weight: 700;
            font-size: 1rem;
            margin-bottom: 8px;
        }
        .action-desc {
            font-size: 0.75rem;
            color: var(--text-muted);
        }

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
        .badge-warning {
            background: var(--warning-pale);
            color: var(--warning);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
        }

        /* Product Grid */
        .product-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 15px;
            max-height: 400px;
            overflow-y: auto;
            padding: 5px;
        }
        .product-mini-card {
            background: var(--cream);
            border-radius: 8px;
            padding: 10px;
            text-align: center;
            border: 1px solid var(--cream-border);
            transition: all 0.2s;
        }
        .product-mini-card:hover {
            border-color: var(--gold);
            background: var(--white);
        }
        .product-name {
            font-weight: 600;
            font-size: 0.8rem;
            margin-bottom: 5px;
        }
        .product-price {
            color: var(--gold);
            font-weight: 700;
            font-size: 0.85rem;
        }
        .product-stock {
            font-size: 0.65rem;
            color: var(--text-muted);
        }

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
            <div class="sidebar-brand-sub">Cashier Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/cashier/dashboard.jsp" class="nav-item-link active">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Operations</div>
        <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="nav-item-link">
            <i class="bi bi-cash-register"></i> Point of Sale
        </a>
        <a href="${pageContext.request.contextPath}/cashier/my-sales.jsp" class="nav-item-link">
            <i class="bi bi-receipt"></i> My Sales
        </a>

        <div class="nav-section-label">Products</div>
        <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> View Products
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= cashierName != null ? cashierName : "Cashier" %></div>
            <div class="sidebar-admin-role">Cashier</div>
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
        <span class="topbar-title">Cashier Dashboard</span>
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
                <h1 class="page-heading">Good day, <%= cashierName != null ? cashierName.split(" ")[0] : "Cashier" %>.</h1>
                <p class="text-muted mt-2">Process customer sales and manage your daily transactions.</p>
            </div>
            <div>
                <span class="role-badge"><i class="bi bi-cash-stack"></i> Cashier Access</span>
                <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="btn-gold ms-2">
                    <i class="bi bi-cash-register"></i> New Sale
                </a>
            </div>
        </div>

        <!-- Quick Stats Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-graph-up"></i></div>
                    <div class="stat-value">R <%= df.format(todaySales) %></div>
                    <div class="stat-label">Today's Sales</div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-receipt"></i></div>
                    <div class="stat-value"><%= todayTransactions %></div>
                    <div class="stat-label">Today's Transactions</div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-cash-stack"></i></div>
                    <div class="stat-value">R <%= df.format(weekSales) %></div>
                    <div class="stat-label">This Week's Sales</div>
                </div>
            </div>
        </div>

        <!-- Action Cards -->
        <div class="action-cards">
            <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-cash-register"></i></div>
                <div class="action-title">Start New Sale</div>
                <div class="action-desc">Process customer purchases quickly</div>
            </a>
            <a href="${pageContext.request.contextPath}/cashier/my-sales.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-clock-history"></i></div>
                <div class="action-title">View My Sales</div>
                <div class="action-desc">See your transaction history</div>
            </a>
            <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-box-seam-fill"></i></div>
                <div class="action-title">Browse Products</div>
                <div class="action-desc">Check product availability and prices</div>
            </a>
        </div>

        <div class="row g-3 mb-4">
            <!-- Recent My Sales -->
            <div class="col-md-7">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-clock-history"></i> My Recent Sales
                        </h2>
                        <a href="${pageContext.request.contextPath}/cashier/my-sales.jsp" class="btn-sm-outline">
                            View All <i class="bi bi-arrow-right"></i>
                        </a>
                    </div>
                    <div class="table-responsive">
                        <% if (myRecentSales != null && !myRecentSales.isEmpty()) { %>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Invoice No.</th>
                                        <th>Date</th>
                                        <th>Items</th>
                                        <th>Amount</th>
                                        <th>Payment</th>
                                        <th>Status</th>
                                    </thead>
                                <tbody>
                                    <% for (mpeoa.models.Sale sale : myRecentSales) { %>
                                        <tr>
                                            <td><strong><%= sale.getInvoiceNumber() %></strong></td>
                                            <td><%= sale.getSaleDate() != null ? sale.getSaleDate().toString() : "-" %></td>
                                            <td><%= sale.getItemCount() %> items</td>
                                            <td class="fw-bold">R <%= df.format(sale.getFinalAmount()) %></td>
                                            <td><%= sale.getPaymentMethod() != null ? sale.getPaymentMethod() : "Cash" %></td>
                                            <td><span class="badge-success">Completed</span></td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        <% } else { %>
                            <div class="empty-state">
                                <i class="bi bi-receipt"></i>
                                <p>No sales yet. Start processing customer purchases!</p>
                                <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="btn-gold mt-2">Start New Sale</a>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>

            <!-- Quick Product Access -->
            <div class="col-md-5">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-box-seam-fill"></i> Quick Products
                        </h2>
                        <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="btn-sm-outline">
                            Browse All <i class="bi bi-arrow-right"></i>
                        </a>
                    </div>
                    <div style="padding: 15px;">
                        <div class="product-grid">
                            <% if (products != null && !products.isEmpty()) { 
                                int count = 0;
                                for (mpeoa.models.Product product : products) { 
                                    if (count++ >= 8) break;
                            %>
                                <div class="product-mini-card">
                                    <div class="product-name"><%= product.getProductName().length() > 20 ? product.getProductName().substring(0, 20) + "..." : product.getProductName() %></div>
                                    <div class="product-price">R <%= df.format(product.getUnitPrice()) %></div>
                                    <div class="product-stock">Stock: <%= product.getStockQuantity() %></div>
                                </div>
                            <% } } else { %>
                                <div class="text-center text-muted">No products available</div>
                            <% } %>
                        </div>
                        <div class="text-center mt-3">
                            <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="btn-sm-outline">View All Products</a>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Today's Performance Tips -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-lightbulb-fill"></i> Today's Performance Tips
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-4">
                        <div class="text-center">
                            <i class="bi bi-emoji-smile fs-1 text-success"></i>
                            <p class="mt-2 mb-0">Friendly Service</p>
                            <small class="text-muted">Greet every customer with a smile</small>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="text-center">
                            <i class="bi bi-upc-scan fs-1 text-gold"></i>
                            <p class="mt-2 mb-0">Scan Efficiently</p>
                            <small class="text-muted">Use barcode scanner for speed</small>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="text-center">
                            <i class="bi bi-receipt fs-1 text-info"></i>
                            <p class="mt-2 mb-0">Always Offer Receipt</p>
                            <small class="text-muted">Print or email receipt to customers</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Quick Tips -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Quick Tips for Cashiers
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Always verify product prices before scanning</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Double-check quantities for bulk items</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Apply discounts only when authorized</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Count cash payments twice</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Keep your workstation organized</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Report any system issues to manager</li>
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
</script>

</body>
</html>