<%-- web/cashier/products.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="mpeoa.models.User, mpeoa.dao.ProductDAO, mpeoa.models.Product, java.util.*, java.text.*" %>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    // Allow only Cashier and Administrator
    String role = loggedInUser.getRoleName();
    if (!"Cashier".equalsIgnoreCase(role) && !"Administrator".equalsIgnoreCase(role)) {
        response.sendError(403, "Access Denied. Cashier access required.");
        return;
    }
    
    ProductDAO productDAO = new ProductDAO();
    List<Product> products = productDAO.getAllProducts();
    
    // Get category filter
    String categoryFilter = request.getParameter("category");
    String searchTerm = request.getParameter("search");
    
    // Filter products by category if needed
    List<Product> filteredProducts = new ArrayList<>();
    if (products != null) {
        for (Product product : products) {
            boolean match = true;
            if (categoryFilter != null && !categoryFilter.isEmpty() && !"all".equals(categoryFilter)) {
                if (product.getCategoryName() == null || !product.getCategoryName().equalsIgnoreCase(categoryFilter)) {
                    match = false;
                }
            }
            if (searchTerm != null && !searchTerm.isEmpty()) {
                if (!product.getProductName().toLowerCase().contains(searchTerm.toLowerCase()) &&
                    !product.getProductCode().toLowerCase().contains(searchTerm.toLowerCase())) {
                    match = false;
                }
            }
            if (match) {
                filteredProducts.add(product);
            }
        }
    }
    
    // Get unique categories for filter
    Set<String> categories = new TreeSet<>();
    if (products != null) {
        for (Product product : products) {
            if (product.getCategoryName() != null && !product.getCategoryName().isEmpty()) {
                categories.add(product.getCategoryName());
            }
        }
    }
    
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
    <title>View Products — Mpeoa Supermarket ERP</title>
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
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
            margin: 0; min-height: 100vh;
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

        /* Search and Filter */
        .search-filter-bar {
            background: var(--white);
            border-radius: var(--radius);
            padding: 20px;
            margin-bottom: 24px;
            border: 1px solid var(--cream-border);
        }
        .search-box {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .search-box input {
            flex: 1;
            padding: 10px 15px;
            border: 1.5px solid var(--cream-border);
            border-radius: 8px;
            font-size: 0.9rem;
            outline: none;
        }
        .search-box input:focus {
            border-color: var(--gold);
            box-shadow: 0 0 0 3px var(--gold-pale);
        }
        .search-box select {
            padding: 10px 15px;
            border: 1.5px solid var(--cream-border);
            border-radius: 8px;
            font-size: 0.9rem;
            background: var(--white);
            cursor: pointer;
        }
        .search-box button {
            padding: 10px 20px;
            background: var(--gold);
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
        }
        .search-box button:hover {
            background: var(--gold-light);
        }
        .search-box .btn-clear {
            background: transparent;
            border: 1.5px solid var(--cream-border);
            color: var(--navy);
        }
        .search-box .btn-clear:hover {
            border-color: var(--danger);
            color: var(--danger);
        }

        /* Product Grid */
        .product-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .product-card {
            background: var(--white);
            border-radius: var(--radius);
            border: 1px solid var(--cream-border);
            overflow: hidden;
            transition: all 0.3s;
        }
        .product-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            border-color: var(--gold);
        }
        .product-image {
            background: var(--cream-dark);
            height: 150px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 3rem;
            color: var(--gold);
        }
        .product-body {
            padding: 15px;
        }
        .product-code {
            font-size: 0.7rem;
            color: var(--text-muted);
            margin-bottom: 5px;
        }
        .product-name {
            font-weight: 700;
            font-size: 1rem;
            margin-bottom: 10px;
            color: var(--navy);
        }
        .product-category {
            font-size: 0.7rem;
            color: var(--text-muted);
            margin-bottom: 10px;
        }
        .product-price {
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--gold);
            margin-bottom: 10px;
        }
        .product-stock {
            font-size: 0.7rem;
            padding: 4px 8px;
            border-radius: 12px;
            display: inline-block;
        }
        .stock-in-stock {
            background: var(--success-pale);
            color: var(--success);
        }
        .stock-low-stock {
            background: var(--warning-pale);
            color: var(--warning);
        }
        .stock-out-stock {
            background: var(--danger-pale);
            color: var(--danger);
        }

        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-state i {
            font-size: 4rem;
            margin-bottom: 20px;
            opacity: 0.3;
        }
        .empty-state h4 {
            font-family: var(--font-display);
            font-size: 1.3rem;
            margin-bottom: 10px;
            color: var(--navy);
        }

        .pagination {
            display: flex;
            justify-content: center;
            gap: 8px;
            margin-top: 20px;
        }
        .page-btn {
            padding: 8px 14px;
            border: 1px solid var(--cream-border);
            border-radius: 6px;
            background: var(--white);
            color: var(--navy);
            text-decoration: none;
        }
        .page-btn.active {
            background: var(--gold);
            color: white;
            border-color: var(--gold);
        }
        .page-btn:hover {
            border-color: var(--gold);
        }

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
        <a href="${pageContext.request.contextPath}/cashier/dashboard.jsp" class="nav-item-link">
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
        <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="nav-item-link active">
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
        <span class="topbar-title">View Products</span>
        <span class="topbar-date">
            <i class="bi bi-calendar3 me-1"></i>
            <script>document.write(new Date().toLocaleDateString('en-ZA'));</script>
        </span>
        <div class="topbar-avatar"><%= initials %></div>
    </header>

    <main class="page-body">
        <div class="page-header">
            <div>
                <p class="page-eyebrow">Product Catalog</p>
                <h1 class="page-heading">View Products</h1>
                <p class="text-muted mt-2">Browse all available products and check stock levels.</p>
            </div>
            <div>
                <span class="role-badge"><i class="bi bi-box-seam"></i> Cashier View</span>
                <a href="${pageContext.request.contextPath}/cashier/pos.jsp" class="btn-sm-outline ms-2">
                    <i class="bi bi-cash-register"></i> Go to POS
                </a>
            </div>
        </div>

        <!-- Search and Filter Bar -->
        <div class="search-filter-bar">
            <form method="get" action="${pageContext.request.contextPath}/cashier/products.jsp">
                <div class="search-box">
                    <input type="text" name="search" placeholder="Search by name or code..." value="<%= searchTerm != null ? searchTerm : "" %>">
                    <select name="category">
                        <option value="all">All Categories</option>
                        <% for (String cat : categories) { %>
                            <option value="<%= cat %>" <%= (categoryFilter != null && categoryFilter.equals(cat)) ? "selected" : "" %>><%= cat %></option>
                        <% } %>
                    </select>
                    <button type="submit"><i class="bi bi-search"></i> Search</button>
                    <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="btn-clear">Clear</a>
                </div>
            </form>
        </div>

        <!-- Products Grid -->
        <% if (filteredProducts != null && !filteredProducts.isEmpty()) { %>
            <div class="product-grid">
                <% for (Product product : filteredProducts) { 
                    String stockClass = "";
                    String stockText = "";
                    int stock = product.getStockQuantity();
                    if (stock <= 0) {
                        stockClass = "stock-out-stock";
                        stockText = "Out of Stock";
                    } else if (stock <= product.getReorderLevel()) {
                        stockClass = "stock-low-stock";
                        stockText = "Low Stock";
                    } else {
                        stockClass = "stock-in-stock";
                        stockText = "In Stock";
                    }
                %>
                    <div class="product-card">
                        <div class="product-image">
                            <i class="bi bi-box-seam"></i>
                        </div>
                        <div class="product-body">
                            <div class="product-code"><%= product.getProductCode() %></div>
                            <div class="product-name"><%= product.getProductName() %></div>
                            <div class="product-category">
                                <i class="bi bi-tag"></i> <%= product.getCategoryName() != null ? product.getCategoryName() : "Uncategorized" %>
                            </div>
                            <div class="product-price">R <%= df.format(product.getUnitPrice()) %></div>
                            <div class="product-stock <%= stockClass %>">
                                <i class="bi bi-box"></i> <%= stockText %> (<%= stock %> units)
                            </div>
                        </div>
                    </div>
                <% } %>
            </div>
            
            <!-- Simple Pagination Info -->
            <div class="text-center text-muted">
                <small>Showing <%= filteredProducts.size() %> of <%= products != null ? products.size() : 0 %> products</small>
            </div>
        <% } else { %>
            <div class="empty-state">
                <i class="bi bi-box-seam"></i>
                <h4>No Products Found</h4>
                <p>No products match your search criteria.</p>
                <a href="${pageContext.request.contextPath}/cashier/products.jsp" class="btn-sm-outline mt-2">Clear Filters</a>
            </div>
        <% } %>
        
        <!-- Guidelines -->
        <div class="content-card mt-4">
            <div class="card-header-bar">
                <h2 class="card-header-title">
                    <i class="bi bi-info-circle-fill"></i> Product Information
                </h2>
            </div>
            <div style="padding: 20px;">
                <ul style="padding-left: 20px; color: var(--text-muted); font-size: 0.85rem; line-height: 1.8;">
                    <li><i class="bi bi-search me-1"></i> Use the search bar to find products by name or code</li>
                    <li><i class="bi bi-funnel me-1"></i> Filter by category to narrow down your search</li>
                    <li><i class="bi bi-exclamation-triangle-fill me-1"></i> <span class="text-danger">Out of Stock</span> - Product is currently unavailable</li>
                    <li><i class="bi bi-exclamation-triangle-fill me-1"></i> <span class="text-warning">Low Stock</span> - Product is running low, reorder soon</li>
                    <li><i class="bi bi-check-circle-fill me-1"></i> <span class="text-success">In Stock</span> - Product is available for purchase</li>
                    <li><i class="bi bi-cash-register me-1"></i> Click "Go to POS" to start processing customer sales</li>
                </ul>
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
</script>

</body>
</html>