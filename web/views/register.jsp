<%-- web/views/register.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Administrator — Mpeoa Supermarket ERP</title>
    
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
            --danger: #DC3545;
            --primary: #667eea;
            --secondary: #764ba2;
            --info: #17a2b8;
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
            background: #FFFFFF;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        
        .contact-container {
            width: 100%;
            max-width: 600px;
        }
        
        .contact-card {
            background: white;
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.1);
            overflow: hidden;
            animation: fadeUp 0.5s ease;
            border: 1px solid var(--border);
        }
        
        .contact-header {
            background: #000000;
            color: white;
            padding: 35px;
            text-align: center;
        }
        
        .logo-icon {
            width: 70px;
            height: 70px;
            background: rgba(255,255,255,0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 15px;
            font-size: 2rem;
        }
        
        .contact-header h2 {
            font-family: var(--font-display);
            font-size: 1.5rem;
            margin-bottom: 8px;
        }
        
        .contact-header p {
            font-size: 0.85rem;
            opacity: 0.8;
        }
        
        .contact-body {
            padding: 35px;
        }
        
        .info-section {
            margin-bottom: 30px;
        }
        
        .info-title {
            font-size: 0.8rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--text-muted);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .info-title i {
            font-size: 1.2rem;
        }
        
        .contact-details {
            background: #F8F9FA;
            border-radius: 15px;
            padding: 25px;
            margin-bottom: 20px;
        }
        
        .contact-item {
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }
        
        .contact-item:last-child {
            border-bottom: none;
        }
        
        .contact-icon {
            width: 45px;
            height: 45px;
            background: white;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.3rem;
            color: #000000;
            border: 1px solid var(--border);
        }
        
        .contact-info h4 {
            font-size: 0.85rem;
            font-weight: 600;
            margin-bottom: 4px;
            color: var(--text);
        }
        
        .contact-info p {
            font-size: 0.8rem;
            color: var(--text-muted);
            margin: 0;
        }
        
        .contact-info a {
            color: var(--text);
            text-decoration: none;
            transition: opacity 0.3s;
        }
        
        .contact-info a:hover {
            opacity: 0.7;
            text-decoration: underline;
        }
        
        .request-form {
            margin-top: 30px;
        }
        
        .form-group {
            margin-bottom: 18px;
        }
        
        .form-group label {
            font-size: 0.75rem;
            font-weight: 600;
            margin-bottom: 6px;
            display: block;
            color: var(--text);
        }
        
        .input-group-custom {
            display: flex;
            align-items: center;
            border: 1px solid var(--border);
            border-radius: 10px;
            transition: all 0.3s;
            background: white;
        }
        
        .input-group-custom:focus-within {
            border-color: var(--text);
            box-shadow: 0 0 0 3px rgba(0,0,0,0.1);
        }
        
        .input-group-text-custom {
            padding: 10px 12px;
            background: var(--bg);
            border: none;
            color: var(--text-muted);
        }
        
        .input-group-custom input, 
        .input-group-custom textarea {
            border: none;
            padding: 10px 12px 10px 0;
            flex: 1;
            outline: none;
            font-size: 0.85rem;
            background: transparent;
            font-family: var(--font-body);
        }
        
        .input-group-custom textarea {
            resize: vertical;
            min-height: 80px;
        }
        
        .btn-submit {
            width: 100%;
            padding: 12px;
            background: #000000;
            color: white;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 0.9rem;
            transition: all 0.3s;
            margin-top: 10px;
        }
        
        .btn-submit:hover {
            background: #1a1a1a;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        
        .btn-email {
            width: 100%;
            padding: 12px;
            background: #000000;
            color: white;
            border: none;
            border-radius: 10px;
            font-weight: 600;
            font-size: 0.9rem;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.3s;
        }
        
        .btn-email:hover {
            background: #1a1a1a;
            transform: translateY(-2px);
            color: white;
        }
        
        .alert-custom {
            padding: 12px;
            border-radius: 10px;
            margin-bottom: 20px;
            font-size: 0.8rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-danger {
            background: rgba(220,53,69,0.1);
            border: 1px solid rgba(220,53,69,0.3);
            color: var(--danger);
        }
        
        .alert-success {
            background: rgba(40,167,69,0.1);
            border: 1px solid rgba(40,167,69,0.3);
            color: var(--success);
        }
        
        .alert-info {
            background: rgba(23,162,184,0.1);
            border: 1px solid rgba(23,162,184,0.3);
            color: var(--info);
        }
        
        .login-link {
            text-align: center;
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid var(--border);
        }
        
        .login-link a {
            color: var(--text);
            text-decoration: none;
            font-weight: 600;
        }
        
        .login-link a:hover {
            text-decoration: underline;
        }
        
        .back-home {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .back-home a {
            color: var(--text-muted);
            text-decoration: none;
            font-size: 0.85rem;
            transition: color 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        
        .back-home a:hover {
            color: #000000;
        }
        
        .office-hours {
            background: #F8F9FA;
            border-radius: 12px;
            padding: 15px;
            margin-top: 20px;
        }
        
        .office-hours h5 {
            font-size: 0.8rem;
            font-weight: 700;
            margin-bottom: 10px;
        }
        
        .office-hours p {
            font-size: 0.75rem;
            color: var(--text-muted);
            margin-bottom: 5px;
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
        
        @media (max-width: 576px) {
            .contact-body {
                padding: 25px;
            }
            
            .contact-header {
                padding: 25px;
            }
        }
    </style>
</head>
<body>
    <div class="contact-container">
        <div class="contact-card">
            <div class="contact-header">
                <div class="logo-icon">
                    <i class="bi bi-envelope-fill"></i>
                </div>
                <h2>Contact Administrator</h2>
                <p>Request Account Access</p>
            </div>
            
            <div class="contact-body">
                <!-- Back to Home Link -->
                <div class="back-home">
                    <a href="${pageContext.request.contextPath}/index.jsp">
                        <i class="bi bi-arrow-left"></i> Back to Home
                    </a>
                </div>
                
                <% if (error != null) { %>
                    <div class="alert-custom alert-danger">
                        <i class="bi bi-exclamation-triangle-fill"></i> 
                        <span><%= error %></span>
                    </div>
                <% } %>
                
                <% if (success != null) { %>
                    <div class="alert-custom alert-success">
                        <i class="bi bi-check-circle-fill"></i> 
                        <span><%= success %></span>
                    </div>
                <% } %>
                
                <div class="alert-custom alert-info">
                    <i class="bi bi-info-circle-fill"></i>
                    <span>New account requests must be approved by the system administrator. Please use the contact information below to request access.</span>
                </div>
                
                <!-- Admin Contact Information -->
                <div class="info-section">
                    <div class="info-title">
                        <i class="bi bi-person-badge"></i>
                        <span>SYSTEM ADMINISTRATOR</span>
                    </div>
                    
                    <div class="contact-details">
                        <div class="contact-item">
                            <div class="contact-icon">
                                <i class="bi bi-person-circle"></i>
                            </div>
                            <div class="contact-info">
                                <h4>Administrator Name</h4>
                                <p>Mr Raps</p>
                            </div>
                        </div>
                        
                        <div class="contact-item">
                            <div class="contact-icon">
                                <i class="bi bi-envelope"></i>
                            </div>
                            <div class="contact-info">
                                <h4>Email Address</h4>
                                <p><a href="mailto:admin@mpeoa.com">admin@mpeoa.com</a></p>
                            </div>
                        </div>
                        
                        <div class="contact-item">
                            <div class="contact-icon">
                                <i class="bi bi-telephone"></i>
                            </div>
                            <div class="contact-info">
                                <h4>Phone Number</h4>
                                <p><a href="tel:+26659436321">+26659436321</a></p>
                            </div>
                        </div>
                        
                        <div class="contact-item">
                            <div class="contact-icon">
                                <i class="bi bi-geo-alt"></i>
                            </div>
                            <div class="contact-info">
                                <h4>Office Location</h4>
                                <p>Maseru, Naleli</p>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Office Hours -->
                <div class="office-hours">
                    <h5><i class="bi bi-clock"></i> Office Hours</h5>
                    <p>Monday - Friday: 9:00 AM - 6:00 PM</p>
                    <p>Saturday: 10:00 AM - 4:00 PM</p>
                    <p>Sunday: Closed</p>
                </div>
                
                <!-- Quick Email Button -->
                <div class="request-form">
                    <a href="mailto:admin@mpeoa.com?subject=Account%20Request%20-%20Mpeoa%20ERP&body=Hello%20Administrator,%0A%0AI%20would%20like%20to%20request%20an%20account%20for%20Mpeoa%20ERP%20System.%0A%0AMy%20details:%0A-%20Full%20Name:%20%0A-%20Preferred%20Username:%20%0A-%20Email:%20%0A-%20Desired%20Role:%20%0A%0AThank%20you." 
                       class="btn-email">
                        <i class="bi bi-envelope-paper-fill"></i> Send Account Request Email
                    </a>
                </div>
                
                <!-- Additional Info -->
                <div class="info-section" style="margin-top: 20px;">
                    <div class="info-title">
                        <i class="bi bi-question-circle"></i>
                        <span>WHAT TO INCLUDE IN YOUR REQUEST</span>
                    </div>
                    <ul style="font-size: 0.8rem; color: var(--text-muted); padding-left: 20px;">
                        <li>Your full name</li>
                        <li>Preferred username</li>
                        <li>Email address</li>
                        <li>Desired role (Manager, Accountant, Cashier, or Inventory Officer)</li>
                        <li>Employee/Staff ID (if applicable)</li>
                    </ul>
                </div>
                
                <div class="login-link">
                    Already have an account? <a href="${pageContext.request.contextPath}/login">Sign In</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>