<%-- web/index.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mpeoa Supermarket ERP — Complete Business Management Solution</title>
    
    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet"/>
    <!-- Bootstrap Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet"/>
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700;800&family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --bg: #FFFFFF;
            --text: #000000;
            --text-muted: #6C757D;
            --accent: #000000;
            --accent-light: #333333;
            --border: #E5E5E5;
            --success: #28A745;
            --primary: #667eea;
            --secondary: #764ba2;
            --radius: 12px;
            --shadow: 0 2px 12px rgba(0,0,0,0.06);
            --shadow-md: 0 4px 20px rgba(0,0,0,0.10);
            --font-display: 'Playfair Display', Georgia, serif;
            --font-body: 'DM Sans', sans-serif;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: var(--font-body);
            color: var(--text);
            overflow-x: hidden;
            position: relative;
        }
        
        /* Fixed Background Image for entire page */
        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: url('images/home image.png') no-repeat center center fixed;
            background-size: cover;
            z-index: -2;
        }
        
        /* Dark Overlay for better text readability across all sections */
        body::after {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.7);
            z-index: -1;
        }
        
        /* Navbar */
        .navbar {
            padding: 20px 0;
            background: transparent;
            transition: all 0.3s;
            position: fixed;
            width: 100%;
            z-index: 1000;
        }
        
        .navbar.scrolled {
            background: rgba(0, 0, 0, 0.9);
            box-shadow: var(--shadow);
            padding: 15px 0;
        }
        
        .navbar-brand {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 700;
            color: white !important;
        }
        
        .navbar-brand i {
            margin-right: 8px;
        }
        
        .nav-link {
            font-weight: 500;
            margin: 0 10px;
            transition: color 0.3s;
            color: white !important;
        }
        
        .nav-link:hover {
            color: var(--primary) !important;
        }
        
        .btn-outline-custom {
            border: 2px solid white;
            background: transparent;
            padding: 8px 24px;
            border-radius: 30px;
            font-weight: 600;
            color: white;
            transition: all 0.3s;
        }
        
        .btn-outline-custom:hover {
            background: white;
            color: var(--text);
        }
        
        .btn-primary-custom {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            border: none;
            padding: 12px 32px;
            border-radius: 30px;
            font-weight: 600;
            color: white;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .btn-primary-custom:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102,126,234,0.4);
            color: white;
        }
        
        /* Hero Section */
        .hero {
            min-height: 100vh;
            display: flex;
            align-items: center;
            position: relative;
            padding: 100px 0;
        }
        
        .hero-content {
            position: relative;
            z-index: 2;
            color: white;
        }
        
        .hero h1 {
            font-family: var(--font-display);
            font-size: 3.5rem;
            font-weight: 800;
            margin-bottom: 20px;
        }
        
        .hero p {
            font-size: 1.1rem;
            margin-bottom: 30px;
            opacity: 0.95;
        }
        
        .stats {
            margin-top: 50px;
            display: flex;
            gap: 40px;
        }
        
        .stat-item h3 {
            font-size: 2rem;
            font-weight: 700;
            margin-bottom: 5px;
            color: white;
        }
        
        .stat-item p {
            font-size: 0.85rem;
            opacity: 0.8;
            margin: 0;
            color: white;
        }
        
        /* Features Section */
        .features {
            padding: 80px 0;
            position: relative;
            background: transparent;
        }
        
        .section-title {
            text-align: center;
            margin-bottom: 60px;
        }
        
        .section-title h2 {
            font-family: var(--font-display);
            font-size: 2.5rem;
            font-weight: 700;
            margin-bottom: 15px;
            color: white;
        }
        
        .section-title p {
            color: rgba(255, 255, 255, 0.8);
            font-size: 1rem;
        }
        
        .feature-card {
            padding: 30px;
            border-radius: var(--radius);
            transition: all 0.3s;
            text-align: center;
            height: 100%;
            background: rgba(255, 255, 255, 0.95);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(0px);
        }
        
        .feature-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            background: white;
        }
        
        .feature-icon {
            width: 70px;
            height: 70px;
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 1.8rem;
            color: white;
        }
        
        .feature-card h3 {
            font-size: 1.2rem;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--text);
        }
        
        .feature-card p {
            color: var(--text-muted);
            font-size: 0.85rem;
        }
        
        /* Roles Section */
        .roles {
            padding: 80px 0;
            position: relative;
            background: transparent;
        }
        
        .role-card {
            background: rgba(255, 255, 255, 0.95);
            border-radius: var(--radius);
            padding: 25px;
            text-align: center;
            transition: all 0.3s;
            height: 100%;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .role-card:hover {
            transform: translateY(-5px);
            box-shadow: var(--shadow-md);
            background: white;
        }
        
        .role-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            font-size: 1.5rem;
            color: white;
        }
        
        .role-card h4 {
            font-size: 1rem;
            font-weight: 700;
            margin-bottom: 10px;
            color: var(--text);
        }
        
        .role-card p {
            font-size: 0.75rem;
            color: var(--text-muted);
        }
        
        /* CTA Section */
        .cta {
            padding: 80px 0;
            position: relative;
            background: rgba(0, 0, 0, 0.5);
            color: white;
            text-align: center;
            backdrop-filter: blur(5px);
            margin: 20px 0;
            border-radius: 20px;
        }
        
        .cta h2 {
            font-family: var(--font-display);
            font-size: 2rem;
            margin-bottom: 20px;
        }
        
        .cta p {
            margin-bottom: 30px;
            opacity: 0.95;
        }
        
        .btn-light-custom {
            background: white;
            color: var(--primary);
            border: none;
            padding: 12px 32px;
            border-radius: 30px;
            font-weight: 600;
            transition: transform 0.3s;
        }
        
        .btn-light-custom:hover {
            transform: translateY(-2px);
            color: var(--primary);
        }
        
        /* Footer */
        .footer {
            background: rgba(0, 0, 0, 0.9);
            color: rgba(255,255,255,0.7);
            padding: 60px 0 30px;
            position: relative;
            margin-top: 40px;
        }
        
        .footer h5 {
            color: white;
            font-size: 1rem;
            margin-bottom: 20px;
        }
        
        .footer p {
            font-size: 0.8rem;
        }
        
        .footer-links {
            list-style: none;
            padding: 0;
        }
        
        .footer-links li {
            margin-bottom: 10px;
        }
        
        .footer-links a {
            color: rgba(255,255,255,0.7);
            text-decoration: none;
            font-size: 0.8rem;
            transition: color 0.3s;
        }
        
        .footer-links a:hover {
            color: white;
        }
        
        .social-links {
            display: flex;
            gap: 15px;
        }
        
        .social-links a {
            width: 35px;
            height: 35px;
            border-radius: 50%;
            background: rgba(255,255,255,0.1);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            transition: all 0.3s;
        }
        
        .social-links a:hover {
            background: var(--primary);
            transform: translateY(-3px);
        }
        
        @keyframes fadeUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .animate {
            animation: fadeUp 0.6s ease forwards;
        }
        
        /* Responsive adjustments */
        @media (max-width: 768px) {
            .hero h1 {
                font-size: 2rem;
            }
            
            .hero p {
                font-size: 0.9rem;
            }
            
            .stats {
                gap: 20px;
            }
            
            .stat-item h3 {
                font-size: 1.5rem;
            }
            
            .section-title h2 {
                font-size: 1.8rem;
            }
            
            .feature-card, .role-card {
                margin: 10px;
            }
        }
        
        /* Container spacing */
        .container {
            position: relative;
            z-index: 2;
        }
    </style>
</head>
<body>

<!-- Navbar -->
<nav class="navbar navbar-expand-lg" id="navbar">
    <div class="container">
        <a class="navbar-brand" href="#">
            <i class="bi bi-shop"></i> Mpeoa ERP
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="#home">Home</a></li>
                <li class="nav-item"><a class="nav-link" href="#features">Features</a></li>
                <li class="nav-item"><a class="nav-link" href="#roles">Roles</a></li>
                <li class="nav-item"><a class="nav-link" href="#contact">Contact</a></li>
            </ul>
            <div class="ms-lg-3">
                <a href="${pageContext.request.contextPath}/login" class="btn btn-outline-custom">Sign In</a>
                <a href="${pageContext.request.contextPath}/views/register.jsp" class="btn btn-primary-custom ms-2">Get Started</a>
            </div>
        </div>
    </div>
</nav>

<!-- Hero Section -->
<section class="hero" id="home">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-lg-7 hero-content">
                <h1 class="animate">Complete ERP Solution for Modern Supermarkets</h1>
                <p class="animate" style="animation-delay: 0.1s;">Streamline your operations with our comprehensive Financial Information System. Manage sales, inventory, expenses, and more in one powerful platform.</p>
                <div class="animate" style="animation-delay: 0.2s;">
                    <a href="${pageContext.request.contextPath}/views/register.jsp" class="btn btn-primary-custom me-3">Get Started</a>
                    <a href="#features" class="btn btn-outline-custom">Learn More</a>
                </div>
                <div class="stats animate" style="animation-delay: 0.3s;">
                    <div class="stat-item">
                        <h3>500+</h3>
                        <p>Products Managed</p>
                    </div>
                    <div class="stat-item">
                        <h3>98%</h3>
                        <p>Accuracy Rate</p>
                    </div>
                    <div class="stat-item">
                        <h3>24/7</h3>
                        <p>Support</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Features Section -->
<section class="features" id="features">
    <div class="container">
        <div class="section-title">
            <h2>Powerful Features</h2>
            <p>Everything you need to run your supermarket efficiently</p>
        </div>
        <div class="row g-4">
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-cash-register"></i></div>
                    <h3>POS System</h3>
                    <p>Fast and intuitive point of sale with receipt printing and inventory auto-update.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-box-seam"></i></div>
                    <h3>Inventory Management</h3>
                    <p>Track stock levels, expiry dates, and get automatic low stock alerts.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-graph-up"></i></div>
                    <h3>Financial Reports</h3>
                    <p>Real-time profit & loss statements, expense tracking, and financial analytics.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-truck"></i></div>
                    <h3>Supplier Management</h3>
                    <p>Manage supplier relationships, track payments, and procurement orders.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-people"></i></div>
                    <h3>Role-Based Access</h3>
                    <p>5 different user roles with specific permissions for security.</p>
                </div>
            </div>
            <div class="col-md-4">
                <div class="feature-card">
                    <div class="feature-icon"><i class="bi bi-shield-check"></i></div>
                    <h3>Secure System</h3>
                    <p>Password hashing, session management, and input validation.</p>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Roles Section -->
<section class="roles" id="roles">
    <div class="container">
        <div class="section-title">
            <h2>System Roles</h2>
            <p>Designed for different team members with specific access levels</p>
        </div>
        <div class="row g-3 justify-content-center">
            <div class="col-md-2">
                <div class="role-card">
                    <div class="role-icon" style="background: #000;"><i class="bi bi-shield-fill-check"></i></div>
                    <h4>Administrator</h4>
                    <p>Full system control</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="role-card">
                    <div class="role-icon" style="background: #333;"><i class="bi bi-briefcase-fill"></i></div>
                    <h4>Manager</h4>
                    <p>Monitor operations</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="role-card">
                    <div class="role-icon" style="background: #555;"><i class="bi bi-calculator-fill"></i></div>
                    <h4>Accountant</h4>
                    <p>Financial management</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="role-card">
                    <div class="role-icon" style="background: #777;"><i class="bi bi-cash-stack"></i></div>
                    <h4>Cashier</h4>
                    <p>Process sales</p>
                </div>
            </div>
            <div class="col-md-2">
                <div class="role-card">
                    <div class="role-icon" style="background: #999;"><i class="bi bi-box-seam"></i></div>
                    <h4>Inventory Officer</h4>
                    <p>Manage stock</p>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- CTA Section -->
<section class="cta">
    <div class="container">
        <h2>Ready to Transform Your Business?</h2>
        <p>Join hundreds of supermarkets using Mpeoa ERP to streamline operations</p>
        <a href="${pageContext.request.contextPath}/views/register.jsp" class="btn btn-light-custom">Create Free Account</a>
    </div>
</section>

<!-- Footer -->
<footer class="footer" id="contact">
    <div class="container">
        <div class="row">
            <div class="col-md-4 mb-4">
                <h5>Mpeoa Supermarket ERP</h5>
                <p>Complete business management solution for modern supermarkets. Streamline your operations with our integrated platform.</p>
                <div class="social-links">
                    <a href="#"><i class="bi bi-facebook"></i></a>
                    <a href="#"><i class="bi bi-twitter"></i></a>
                    <a href="#"><i class="bi bi-linkedin"></i></a>
                </div>
            </div>
            <div class="col-md-2 mb-4">
                <h5>Quick Links</h5>
                <ul class="footer-links">
                    <li><a href="#home">Home</a></li>
                    <li><a href="#features">Features</a></li>
                    <li><a href="#roles">Roles</a></li>
                </ul>
            </div>
            <div class="col-md-3 mb-4">
                <h5>Contact Info</h5>
                <ul class="footer-links">
                    <li><i class="bi bi-geo-alt"></i> Maseru, Naleli</li>
                    <li><i class="bi bi-telephone"></i> +26659436321</li>
                    <li><i class="bi bi-envelope"></i> info@mpeoa.com</li>
                </ul>
            </div>
            <div class="col-md-3 mb-4">
                <h5>Business Hours</h5>
                <ul class="footer-links">
                    <li>Monday - Friday: 8am - 8pm</li>
                    <li>Saturday: 9am - 6pm</li>
                    <li>Sunday: 9am - 4pm</li>
                </ul>
            </div>
        </div>
        <hr class="my-3" style="border-color: rgba(255,255,255,0.1);">
        <div class="text-center">
            <p class="mb-0">&copy; 2024 Mpeoa Supermarket. All rights reserved.</p>
        </div>
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    // Change navbar background on scroll
    window.addEventListener('scroll', function() {
        const navbar = document.getElementById('navbar');
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });
</script>
</body>
</html>