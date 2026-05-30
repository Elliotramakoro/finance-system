<%-- web/inventory/dashboard.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.ProductDAO, mpeoa.dao.SupplierDAO, mpeoa.dao.PurchaseDAO, java.text.*, java.math.BigDecimal, java.util.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Inventory Officer".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Initialize DAOs
    ProductDAO productDAO = new ProductDAO();
    SupplierDAO supplierDAO = new SupplierDAO();
    PurchaseDAO purchaseDAO = new PurchaseDAO();
    
    // Get all products
    List<mpeoa.models.Product> products = productDAO.getAllProducts();
    List<mpeoa.models.Product> lowStockProducts = productDAO.getLowStockProducts();
    List<mpeoa.models.Supplier> suppliers = supplierDAO.getAllSuppliers();
    List<mpeoa.models.Purchase> pendingPurchases = purchaseDAO.getPendingPurchases();
    
    // Calculate statistics
    int totalProducts = products.size();
    int lowStockCount = lowStockProducts.size();
    int outOfStockCount = 0;
    int totalSuppliers = suppliers.size();
    int pendingOrders = pendingPurchases.size();
    
    // Calculate total stock value
    BigDecimal totalStockValue = BigDecimal.ZERO;
    for (mpeoa.models.Product product : products) {
        BigDecimal productValue = product.getCostPrice().multiply(new BigDecimal(product.getStockQuantity()));
        totalStockValue = totalStockValue.add(productValue);
        if (product.getStockQuantity() <= 0) {
            outOfStockCount++;
        }
    }
    
    // Get recent purchase orders
    List<mpeoa.models.Purchase> recentPurchases = purchaseDAO.getRecentPurchases(5);
    
    // Get top products by stock value
    List<mpeoa.models.Product> topStockProducts = productDAO.getTopStockValueProducts(5);
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Build initials
    String initials = "A";
    String officerName = loggedInUser.getFullName();
    if (officerName != null && !officerName.trim().isEmpty()) {
        String[] parts = officerName.trim().split("\\s+");
        if (parts.length >= 2) initials = "" + parts[0].charAt(0) + parts[1].charAt(0);
        else initials = "" + parts[0].charAt(0);
        initials = initials.toUpperCase();
    }
    
    // Calculate healthy stock count
    int healthyStockCount = totalProducts - lowStockCount - outOfStockCount;
    double healthyPercentage = totalProducts > 0 ? ((double)healthyStockCount / totalProducts * 100) : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inventory Officer Dashboard — Mpeoa Supermarket ERP</title>
    
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
        .page-header { margin-bottom: 28px; display: flex; justify-content: space-between; align-items: flex-start; flex-wrap: wrap; gap: 16px; }
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
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .action-card {
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
        .action-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            border-color: var(--gold);
        }
        .action-icon {
            font-size: 2rem;
            margin-bottom: 12px;
            color: var(--gold);
        }
        .action-title {
            font-weight: 700;
            font-size: 0.9rem;
            margin-bottom: 5px;
        }
        .action-desc {
            font-size: 0.7rem;
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
        .btn-success-custom {
            background: var(--success);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.7rem;
            text-decoration: none;
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
            display: inline-block;
        }
        .badge-warning {
            background: var(--warning-pale);
            color: var(--warning);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
            display: inline-block;
        }
        .badge-danger {
            background: var(--danger-pale);
            color: var(--danger);
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 0.65rem;
            font-weight: 600;
            display: inline-block;
        }

        /* Alerts */
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
        .alert-danger {
            background: var(--danger-pale);
            border: 1px solid rgba(192,57,43,0.25);
            color: var(--danger);
        }

        /* Stock Indicator */
        .stock-bar {
            height: 6px;
            background: var(--cream-border);
            border-radius: 3px;
            overflow: hidden;
            margin-top: 5px;
        }
        .stock-fill {
            height: 100%;
            background: var(--success);
            border-radius: 3px;
        }
        .stock-fill.warning { background: var(--warning); }
        .stock-fill.danger { background: var(--danger); }

        /* Empty State */
        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 2rem;
            color: var(--cream-border);
        }
        .empty-state p {
            margin-top: 12px;
            font-size: 0.85rem;
        }

        /* Utilities */
        .d-flex { display: flex; }
        .align-items-center { align-items: center; }
        .justify-content-between { justify-content: space-between; }
        .gap-2 { gap: 8px; }
        .gap-3 { gap: 16px; }
        .mb-4 { margin-bottom: 24px; }
        .mt-2 { margin-top: 8px; }
        .mt-3 { margin-top: 16px; }
        .fw-bold { font-weight: 700; }
        .text-center { text-align: center; }
        .me-1 { margin-right: 4px; }
        .text-success { color: var(--success); }
        .text-danger { color: var(--danger); }
        .text-warning { color: var(--warning); }
        .fs-1 { font-size: 2.5rem; }

        @keyframes fadeUp {
            from { opacity: 0; transform: translateY(16px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .animate-fade { animation: fadeUp 0.4s ease both; }
        
        /* Responsive table fixes */
        @media (max-width: 768px) {
            .data-table thead th, .data-table tbody td {
                padding: 8px 12px;
            }
            .action-cards {
                grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
                gap: 12px;
            }
            .card-header-bar {
                flex-direction: column;
                align-items: flex-start;
            }
        }
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
            <div class="sidebar-brand-sub">Inventory Portal</div>
        </div>
    </div>
    <nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/inventory/dashboard.jsp" class="nav-item-link active">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Management</div>
        <a href="${pageContext.request.contextPath}/inventory/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> Products
        </a>
        <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="nav-item-link">
            <i class="bi bi-archive-fill"></i> Stock Management
        </a>
        <a href="${pageContext.request.contextPath}/inventory/suppliers.jsp" class="nav-item-link">
            <i class="bi bi-truck"></i> Suppliers
        </a>
        <a href="${pageContext.request.contextPath}/inventory/purchases.jsp" class="nav-item-link">
            <i class="bi bi-cart-fill"></i> Purchase Orders
        </a>

        <div class="nav-section-label">Reports</div>
        <a href="${pageContext.request.contextPath}/inventory/reports.jsp" class="nav-item-link">
            <i class="bi bi-graph-up"></i> Inventory Reports
        </a>
    </nav>
    <div class="sidebar-footer">
        <div class="sidebar-avatar"><%= initials %></div>
        <div>
            <div class="sidebar-admin-name"><%= officerName != null ? officerName : "Inventory Officer" %></div>
            <div class="sidebar-admin-role">Inventory Officer</div>
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
        <span class="topbar-title">Inventory Dashboard</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA', {weekday:'short', year:'numeric', month:'short', day:'numeric'}));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Stock Management</p>
                <h1 class="page-heading">Good day, <%= officerName != null ? officerName.split(" ")[0] : "Inventory Officer" %>.</h1>
                <p class="text-muted mt-2">Monitor stock levels, track inventory, and manage suppliers.</p>
            </div>
            <div>
                <span class="role-badge"><i class="bi bi-box-seam"></i> Inventory Officer Access</span>
                <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="btn-gold ms-2">
                    <i class="bi bi-plus-circle-fill"></i> Update Stock
                </a>
            </div>
        </div>

        <!-- Stock Alerts -->
        <% if (lowStockCount > 0 || outOfStockCount > 0) { %>
            <div class="row g-3 mb-4">
                <% if (outOfStockCount > 0) { %>
                    <div class="col-md-6">
                        <div class="alert alert-danger">
                            <i class="bi bi-exclamation-triangle-fill"></i>
                            <span><strong><%= outOfStockCount %></strong> product(s) are OUT OF STOCK! Immediate action required.</span>
                        </div>
                    </div>
                <% } %>
                <% if (lowStockCount > 0) { %>
                    <div class="col-md-6">
                        <div class="alert alert-warning">
                            <i class="bi bi-exclamation-triangle-fill"></i>
                            <span><strong><%= lowStockCount %></strong> product(s) are running low on stock. Please reorder soon!</span>
                        </div>
                    </div>
                <% } %>
            </div>
        <% } %>

        <!-- Key Statistics -->
        <div class="row g-3 mb-4">
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-box-seam-fill"></i></div>
                    <div class="stat-value"><%= totalProducts %></div>
                    <div class="stat-label">Total Products</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
                    <div class="stat-value"><%= lowStockCount %></div>
                    <div class="stat-label">Low Stock Items</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-truck"></i></div>
                    <div class="stat-value"><%= totalSuppliers %></div>
                    <div class="stat-label">Active Suppliers</div>
                </div>
            </div>
            <div class="col-md-3 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-currency-exchange"></i></div>
                    <div class="stat-value">R <%= df.format(totalStockValue) %></div>
                    <div class="stat-label">Total Stock Value</div>
                </div>
            </div>
        </div>

        <!-- Action Cards -->
        <div class="action-cards">
            <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-plus-circle-fill"></i></div>
                <div class="action-title">Update Stock</div>
                <div class="action-desc">Add or remove stock quantities</div>
            </a>
            <a href="${pageContext.request.contextPath}/inventory/products.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-box-seam-fill"></i></div>
                <div class="action-title">Manage Products</div>
                <div class="action-desc">Add, edit, or delete products</div>
            </a>
            <a href="${pageContext.request.contextPath}/inventory/purchases.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-cart-fill"></i></div>
                <div class="action-title">Create Purchase Order</div>
                <div class="action-desc">Order stock from suppliers</div>
            </a>
            <a href="${pageContext.request.contextPath}/inventory/suppliers.jsp" class="action-card">
                <div class="action-icon"><i class="bi bi-truck"></i></div>
                <div class="action-title">Manage Suppliers</div>
                <div class="action-desc">Add or edit supplier information</div>
            </a>
        </div>

        <!-- Low Stock Products Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-exclamation-triangle-fill"></i> Low Stock Products
                </h2>
                <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="btn-sm-outline">
                    Manage Stock <i class="bi bi-arrow-right"></i>
                </a>
            </div>
            <div class="table-responsive">
                <% if (lowStockProducts != null && !lowStockProducts.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Product Code</th>
                                <th>Product Name</th>
                                <th>Current Stock</th>
                                <th>Reorder Level</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (mpeoa.models.Product product : lowStockProducts) { 
                                String statusClass = product.getStockQuantity() <= 0 ? "badge-danger" : "badge-warning";
                                String statusText = product.getStockQuantity() <= 0 ? "Out of Stock" : "Low Stock";
                                String productName = product.getProductName();
                                if (productName != null && productName.length() > 30) {
                                    productName = productName.substring(0, 27) + "...";
                                }
                            %>
                                <tr>
                                    <td><strong><%= product.getProductCode() %></strong></td>
                                    <td><%= productName %></td>
                                    <td class="fw-bold"><%= product.getStockQuantity() %> units</td>
                                    <td><%= product.getReorderLevel() %> units</td>
                                    <td><span class="<%= statusClass %>"><%= statusText %></span></td>
                                    <td>
                                        <a href="${pageContext.request.contextPath}/inventory/stock.jsp?productId=<%= product.getProductId() %>" class="btn-sm-outline">
                                            Update Stock
                                        </a>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-check-circle-fill text-success"></i>
                        <p>All stock levels are healthy!</p>
                    </div>
                <% } %>
            </div>
        </div>

        <div class="row g-3">
            <!-- Recent Purchase Orders -->
            <div class="col-md-7">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-cart-fill"></i> Recent Purchase Orders
                        </h2>
                        <a href="${pageContext.request.contextPath}/inventory/purchases.jsp" class="btn-sm-outline">
                            View All <i class="bi bi-arrow-right"></i>
                        </a>
                    </div>
                    <div class="table-responsive">
                        <% if (recentPurchases != null && !recentPurchases.isEmpty()) { %>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>PO Number</th>
                                        <th>Date</th>
                                        <th>Supplier</th>
                                        <th>Amount</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (mpeoa.models.Purchase purchase : recentPurchases) { 
                                        String supplierName = purchase.getSupplierName();
                                        if (supplierName != null && supplierName.length() > 20) {
                                            supplierName = supplierName.substring(0, 17) + "...";
                                        }
                                    %>
                                        <tr>
                                            <td><strong><%= purchase.getPurchaseOrderNumber() %></strong></td>
                                            <td><%= purchase.getPurchaseDate() != null ? purchase.getPurchaseDate() : "-" %></td>
                                            <td><%= supplierName != null ? supplierName : "-" %></td>
                                            <td class="fw-bold">R <%= df.format(purchase.getTotalAmount()) %></td>
                                            <td>
                                                <% if ("Paid".equalsIgnoreCase(purchase.getPaymentStatus())) { %>
                                                    <span class="badge-success">Completed</span>
                                                <% } else { %>
                                                    <span class="badge-warning">Pending</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        <% } else { %>
                            <div class="empty-state">
                                <i class="bi bi-cart"></i>
                                <p>No purchase orders yet.</p>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>

            <!-- Top Stock Value Products -->
            <div class="col-md-5">
                <div class="content-card">
                    <div class="card-header-bar">
                        <h2 class="card-header-title">
                            <i class="bi bi-piggy-bank-fill"></i> Highest Stock Value
                        </h2>
                    </div>
                    <div class="table-responsive">
                        <% if (topStockProducts != null && !topStockProducts.isEmpty()) { %>
                            <table class="data-table">
                                <thead>
                                    <tr>
                                        <th>Product</th>
                                        <th>Stock</th>
                                        <th>Value</th>
                                    </thead>
                                <tbody>
                                    <% for (mpeoa.models.Product product : topStockProducts) { 
                                        BigDecimal stockValue = product.getCostPrice().multiply(new BigDecimal(product.getStockQuantity()));
                                        String productName = product.getProductName();
                                        if (productName != null && productName.length() > 20) {
                                            productName = productName.substring(0, 17) + "...";
                                        }
                                    %>
                                        <tr>
                                            <td><%= productName %></td>
                                            <td><%= product.getStockQuantity() %> units</td>
                                            <td class="fw-bold">R <%= df.format(stockValue) %></td>
                                        </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        <% } else { %>
                            <div class="empty-state">
                                <p>No product data available</p>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <!-- Stock Health Overview -->
        <div class="content-card mt-3">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-heart-pulse-fill"></i> Stock Health Overview
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-4">
                        <div class="text-center">
                            <h3 class="text-success"><%= healthyStockCount %></h3>
                            <p class="text-muted">Healthy Stock</p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="text-center">
                            <h3 class="text-warning"><%= lowStockCount %></h3>
                            <p class="text-muted">Low Stock</p>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="text-center">
                            <h3 class="text-danger"><%= outOfStockCount %></h3>
                            <p class="text-muted">Out of Stock</p>
                        </div>
                    </div>
                </div>
                <div class="stock-bar mt-3">
                    <div class="stock-fill" style="width: <%= healthyPercentage %>%;"></div>
                </div>
                <div class="text-center mt-2">
                    <small class="text-muted"><%= String.format("%.1f", healthyPercentage) %>% of products have healthy stock levels</small>
                </div>
            </div>
        </div>

        <!-- Inventory Officer Responsibilities -->
        <div class="content-card mt-3">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Inventory Officer Responsibilities
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Monitor stock levels and reorder alerts</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Update inventory when new stock arrives</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Track product expiry dates (especially for dairy)</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Process supplier deliveries</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Conduct regular stock counts</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Flag damaged or expired products</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Coordinate with suppliers for timely deliveries</li>
                            <li><i class="bi bi-check-circle-fill text-success me-1"></i> Generate inventory reports for management</li>
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