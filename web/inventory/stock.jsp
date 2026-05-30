<%-- web/inventory/stock.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.ProductDAO, mpeoa.models.Product, java.util.*, java.text.*, java.math.BigDecimal" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !"Inventory Officer".equalsIgnoreCase(loggedInUser.getRoleName())) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    ProductDAO productDAO = new ProductDAO();
    List<Product> products = productDAO.getAllProducts();
    List<Product> lowStockProducts = productDAO.getLowStockProducts();
    
    String success = request.getParameter("success");
    String error = request.getParameter("error");
    String productIdParam = request.getParameter("product");
    
    // For quick stock update
    Product selectedProduct = null;
    if (productIdParam != null && !productIdParam.isEmpty()) {
        try {
            int pid = Integer.parseInt(productIdParam);
            selectedProduct = productDAO.getProductById(pid);
        } catch (NumberFormatException e) {}
    }
    
    DecimalFormat df = new DecimalFormat("#,##0.00");
    
    // Calculate totals
    int totalProducts = products != null ? products.size() : 0;
    int lowStockCount = lowStockProducts != null ? lowStockProducts.size() : 0;
    int outOfStockCount = 0;
    int healthyStockCount = 0;
    
    if (products != null) {
        for (Product p : products) {
            if (p.getStockQuantity() <= 0) outOfStockCount++;
            else if (p.getStockQuantity() <= p.getReorderLevel()) lowStockCount++;
            else healthyStockCount++;
        }
    }
    
    // Build initials
    String initials = "A";
    String officerName = loggedInUser.getFullName();
    if (officerName != null && !officerName.trim().isEmpty()) {
        String[] parts = officerName.trim().split("\\s+");
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
    <title>Stock Management — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    
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
            --success-pale: rgba(46,125,82,0.10);
            --danger: #C0392B;
            --danger-pale: rgba(192,57,43,0.10);
            --warning: #D4A42B;
            --warning-pale: rgba(212,164,43,0.10);
            --sidebar-w: 260px;
            --topbar-h: 64px;
            --radius: 12px;
            --shadow: 0 2px 16px rgba(18,34,58,0.08);
            --shadow-md: 0 4px 24px rgba(18,34,58,0.12);
            --font-display: 'Playfair Display', Georgia, serif;
            --font-body: 'DM Sans', sans-serif;
        }

        *, *::before, *::after { box-sizing: border-box; }
        body {
            font-family: var(--font-body);
            background: var(--cream);
            color: var(--navy);
            margin: 0;
            min-height: 100vh;
        }

        /* Sidebar */
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
            color: white;
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
        .nav-item-link:hover { color: white; background: rgba(255,255,255,0.05); border-left-color: rgba(200,146,58,0.4); }
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

        .stat-card {
            background: white;
            border-radius: var(--radius);
            padding: 20px;
            border: 1px solid var(--cream-border);
            transition: transform 0.2s;
            height: 100%;
        }
        .stat-card:hover { transform: translateY(-3px); box-shadow: var(--shadow-md); }
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
        .stat-value { font-family: var(--font-display); font-size: 1.5rem; font-weight: 700; margin-bottom: 4px; color: var(--navy); }
        .stat-label { font-size: 0.75rem; color: var(--text-muted); }

        .content-card {
            background: white;
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
        }
        .btn-sm-outline:hover { border-color: var(--gold); background: var(--gold-pale); color: var(--gold); }
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
        .btn-gold:hover { background: var(--gold-light); }
        .btn-success-custom {
            background: var(--success);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.7rem;
            cursor: pointer;
        }
        .btn-danger-custom {
            background: var(--danger);
            color: white;
            border: none;
            border-radius: 6px;
            padding: 5px 12px;
            font-size: 0.7rem;
            cursor: pointer;
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
        .data-table tbody tr:hover { background: var(--cream); }

        .badge-low-stock { background: var(--warning-pale); color: var(--warning); padding: 4px 8px; border-radius: 12px; font-size: 0.65rem; font-weight: 600; }
        .badge-in-stock { background: var(--success-pale); color: var(--success); padding: 4px 8px; border-radius: 12px; font-size: 0.65rem; font-weight: 600; }
        .badge-out-stock { background: var(--danger-pale); color: var(--danger); padding: 4px 8px; border-radius: 12px; font-size: 0.65rem; font-weight: 600; }

        .stock-update-form {
            display: flex;
            gap: 8px;
            align-items: center;
            flex-wrap: wrap;
        }
        .stock-input {
            width: 70px;
            padding: 5px 8px;
            border-radius: 6px;
            border: 1px solid var(--cream-border);
            text-align: center;
        }
        .alert-custom {
            padding: 12px 16px;
            border-radius: 10px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .alert-success { background: var(--success-pale); border: 1px solid rgba(46,125,82,0.25); color: var(--success); }
        .alert-danger { background: var(--danger-pale); border: 1px solid rgba(192,57,43,0.25); color: var(--danger); }

        .empty-state { text-align: center; padding: 60px 20px; color: var(--text-muted); }
        .empty-state i { font-size: 3rem; margin-bottom: 15px; opacity: 0.5; }
        .empty-state h4 { font-family: var(--font-display); font-size: 1.2rem; margin-bottom: 10px; color: var(--navy); }

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
        .text-warning { color: var(--warning); }
        
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
            <div class="sidebar-brand-sub">Inventory Portal</div>
        </div>
    </div>
<nav class="sidebar-nav">
        <div class="nav-section-label">Main</div>
        <a href="${pageContext.request.contextPath}/inventory/dashboard.jsp" class="nav-item-link">
            <i class="bi bi-grid-1x2-fill"></i> Dashboard
        </a>
        
        <div class="nav-section-label">Management</div>
        <a href="${pageContext.request.contextPath}/inventory/products.jsp" class="nav-item-link">
            <i class="bi bi-box-seam-fill"></i> Products
        </a>
        <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="nav-item-link active">
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
        <span class="topbar-title">Stock Management</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Inventory Control</p>
                <h1 class="page-heading">Stock Management</h1>
                <p class="text-muted mt-2">Monitor and update product stock levels in real-time.</p>
            </div>
            <div>
                <a href="${pageContext.request.contextPath}/inventory/reports.jsp" class="btn-sm-outline">
                    <i class="bi bi-graph-up"></i> Stock Reports
                </a>
            </div>
        </div>
        
        <% if (success != null) { %>
            <div class="alert-custom alert-success animate-fade">
                <i class="bi bi-check-circle-fill"></i>
                <span><%= success %></span>
            </div>
        <% } %>
        
        <% if (error != null) { %>
            <div class="alert-custom alert-danger animate-fade">
                <i class="bi bi-exclamation-triangle-fill"></i>
                <span><%= error %></span>
            </div>
        <% } %>

        <!-- Statistics Cards -->
        <div class="row g-3 mb-4">
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-box-seam-fill"></i></div>
                    <div class="stat-value"><%= totalProducts %></div>
                    <div class="stat-label">Total Products</div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-check-circle-fill"></i></div>
                    <div class="stat-value"><%= healthyStockCount %></div>
                    <div class="stat-label">Healthy Stock</div>
                </div>
            </div>
            <div class="col-md-4 col-6">
                <div class="stat-card animate-fade">
                    <div class="stat-icon"><i class="bi bi-exclamation-triangle-fill"></i></div>
                    <div class="stat-value"><%= lowStockCount + outOfStockCount %></div>
                    <div class="stat-label">Needs Attention</div>
                </div>
            </div>
        </div>

        <!-- Quick Stock Update for Selected Product -->
        <% if (selectedProduct != null) { %>
            <div class="content-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-pencil-square"></i> Quick Update: <%= selectedProduct.getProductName() %>
                    </h2>
                    <a href="${pageContext.request.contextPath}/inventory/stock.jsp" class="btn-sm-outline">
                        <i class="bi bi-x-lg"></i> Close
                    </a>
                </div>
                <div style="padding: 20px;">
                    <form action="${pageContext.request.contextPath}/inventory/stock-update" method="post" class="row g-3 align-items-end">
                        <input type="hidden" name="productId" value="<%= selectedProduct.getProductId() %>">
                        <div class="col-md-3">
                            <label class="form-label">Current Stock</label>
                            <input type="text" class="form-control" value="<%= selectedProduct.getStockQuantity() %> units" readonly style="background: var(--cream);">
                        </div>
                        <div class="col-md-3">
                            <label class="form-label">Action</label>
                            <select name="action" class="form-select" required>
                                <option value="add">Add Stock (+)</option>
                                <option value="remove">Remove Stock (-)</option>
                                <option value="set">Set Exact Quantity</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Quantity</label>
                            <input type="number" name="quantity" class="form-control" placeholder="0" required>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Reason</label>
                            <select name="reason" class="form-select">
                                <option value="New Shipment">New Shipment</option>
                                <option value="Return">Customer Return</option>
                                <option value="Damaged">Damaged Goods</option>
                                <option value="Expired">Expired Products</option>
                                <option value="Stock Count">Stock Count Adjustment</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <button type="submit" class="btn-gold w-100">Update Stock</button>
                        </div>
                    </form>
                </div>
            </div>
        <% } %>

        <!-- Stock Levels Table -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-list-ul"></i> Current Stock Levels
                </h2>
                <span class="btn-sm-outline">Total: <%= totalProducts %> products</span>
            </div>
            <div class="table-responsive">
                <% if (products != null && !products.isEmpty()) { %>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Code</th>
                                <th>Product Name</th>
                                <th>Category</th>
                                <th>Current Stock</th>
                                <th>Reorder Level</th>
                                <th>Status</th>
                                <th>Last Updated</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% for (Product product : products) { 
                                String statusClass = "";
                                String statusText = "";
                                int stockQty = product.getStockQuantity();
                                int reorderLvl = product.getReorderLevel();
                                
                                if (stockQty <= 0) {
                                    statusClass = "badge-out-stock";
                                    statusText = "Out of Stock";
                                } else if (stockQty <= reorderLvl) {
                                    statusClass = "badge-low-stock";
                                    statusText = "Low Stock";
                                } else {
                                    statusClass = "badge-in-stock";
                                    statusText = "In Stock";
                                }
                            %>
                                <tr>
                                    <td><strong><%= product.getProductCode() != null ? product.getProductCode() : "-" %></strong></td>
                                    <td><%= product.getProductName() != null ? product.getProductName() : "-" %></td>
                                    <td><%= product.getCategoryName() != null ? product.getCategoryName() : "-" %></td>
                                    <td class="fw-bold <%= stockQty <= reorderLvl ? "text-danger" : "" %>"><%= stockQty %> units</td>
                                    <td><%= reorderLvl %> units</td>
                                    <td><span class="<%= statusClass %>"><%= statusText %></span></td>
                                    <td>-</td>
                                    <td>
                                        <div class="stock-update-form">
                                            <input type="number" id="stock_qty_<%= product.getProductId() %>" class="stock-input" placeholder="Qty" value="1" min="1">
                                            <button class="btn-success-custom" onclick="quickUpdate(<%= product.getProductId() %>, 'add')">
                                                <i class="bi bi-plus"></i> Add
                                            </button>
                                            <button class="btn-danger-custom" onclick="quickUpdate(<%= product.getProductId() %>, 'remove')">
                                                <i class="bi bi-dash"></i> Remove
                                            </button>
                                            <button class="btn-sm-outline" onclick="fullUpdate(<%= product.getProductId() %>)">
                                                <i class="bi bi-pencil"></i> Full
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            <% } %>
                        </tbody>
                    </table>
                <% } else { %>
                    <div class="empty-state">
                        <i class="bi bi-archive"></i>
                        <h4>No Products Found</h4>
                        <p>Add products first before managing inventory.</p>
                        <a href="${pageContext.request.contextPath}/inventory/products.jsp" class="btn-sm-outline mt-2">
                            <i class="bi bi-box-seam-fill"></i> Go to Products
                        </a>
                    </div>
                <% } %>
            </div>
        </div>

        <!-- Stock Alerts Summary -->
        <% if (lowStockCount > 0 || outOfStockCount > 0) { %>
            <div class="content-card">
                <div class="card-header-bar">
                    <h2 class="card-header-title">
                        <i class="bi bi-bell-fill"></i> Stock Alerts
                    </h2>
                </div>
                <div style="padding: 20px;">
                    <div class="row">
                        <% if (outOfStockCount > 0) { %>
                            <div class="col-md-6">
                                <div class="alert alert-danger mb-0">
                                    <i class="bi bi-x-circle-fill"></i>
                                    <strong><%= outOfStockCount %></strong> product(s) are completely out of stock.
                                    <a href="${pageContext.request.contextPath}/inventory/purchases.jsp" class="alert-link ms-2">Order Now</a>
                                </div>
                            </div>
                        <% } %>
                        <% if (lowStockCount > 0) { %>
                            <div class="col-md-6">
                                <div class="alert alert-warning mb-0">
                                    <i class="bi bi-exclamation-triangle-fill"></i>
                                    <strong><%= lowStockCount %></strong> product(s) are below reorder level.
                                    <a href="${pageContext.request.contextPath}/inventory/purchases.jsp" class="alert-link ms-2">Reorder</a>
                                </div>
                            </div>
                        <% } %>
                    </div>
                </div>
            </div>
        <% } %>

        <!-- Stock Guidelines -->
        <div class="content-card">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Stock Management Guidelines
                </h2>
            </div>
            <div style="padding: 20px;">
                <div class="row">
                    <div class="col-md-6">
                        <ul class="text-muted" style="font-size: 0.85rem; padding-left: 20px;">
                            <li><i class="bi bi-plus-circle-fill text-success me-1"></i> Use <strong>Add (+)</strong> for new stock arrivals</li>
                            <li><i class="bi bi-dash-circle-fill text-danger me-1"></i> Use <strong>Remove (-)</strong> for damaged/expired items</li>
                            <li><i class="bi bi-pencil-square me-1"></i> Use <strong>Full Update</strong> for bulk adjustments</li>
                        </ul>
                    </div>
                    <div class="col-md-6">
                        <ul class="text-muted" style="font-size: 0.85rem; padding-left: 20px;">
                            <li><i class="bi bi-graph-up me-1"></i> Products below reorder level trigger low stock alerts</li>
                            <li><i class="bi bi-box-seam me-1"></i> Regular stock counts ensure inventory accuracy</li>
                            <li><i class="bi bi-truck me-1"></i> Create purchase orders when stock is low</li>
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
    
    function quickUpdate(productId, action) {
        var quantityInput = document.getElementById('stock_qty_' + productId);
        var quantity = quantityInput.value;
        
        if (!quantity || quantity <= 0) {
            alert('Please enter a valid quantity');
            return;
        }
        
        if (confirm('Are you sure you want to ' + action + ' ' + quantity + ' units?')) {
            window.location.href = '${pageContext.request.contextPath}/inventory/stock-update?productId=' + productId + '&action=' + action + '&quantity=' + quantity;
        }
    }
    
    function fullUpdate(productId) {
        window.location.href = '${pageContext.request.contextPath}/inventory/stock.jsp?product=' + productId;
    }
    
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeSidebar();
    });
    
    setTimeout(function() {
        var flashes = document.querySelectorAll('.alert-custom');
        flashes.forEach(function(flash) {
            flash.style.transition = 'opacity 0.4s';
            flash.style.opacity = '0';
            setTimeout(function() { flash.remove(); }, 500);
        });
    }, 5000);
</script>

</body>
</html>