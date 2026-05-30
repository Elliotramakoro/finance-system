<%-- web/views/login.jsp --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Check if user is already logged in
    if (session.getAttribute("user") != null) {
        response.sendRedirect(request.getContextPath() + "/admin/dashboard.jsp");
        return;
    }
    
    String error = (String) request.getAttribute("error");
    String success = (String) request.getAttribute("success");
    String rememberUsername = "";
    String selectedRole = "";
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if ("remembered_username".equals(cookie.getName())) {
                rememberUsername = cookie.getValue();
                break;
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login — Mpeoa Supermarket ERP</title>
    
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
            --accent-light: #1a1a1a;
            --border: #E5E5E5;
            --border-dark: #CCCCCC;
            --success: #28A745;
            --danger: #DC3545;
            --radius: 16px;
            --shadow: 0 4px 20px rgba(0,0,0,0.08);
            --shadow-md: 0 8px 30px rgba(0,0,0,0.12);
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
        
        .login-container {
            width: 100%;
            max-width: 480px;
        }
        
        .login-card {
            background: white;
            border-radius: var(--radius);
            box-shadow: var(--shadow-md);
            overflow: hidden;
            animation: fadeUp 0.6s ease;
        }
        
        .login-header {
            background: #FFFFFF;
            color: #000000;
            padding: 40px 30px;
            text-align: center;
            border-bottom: 1px solid var(--border);
        }
        
        .logo-icon {
            width: 80px;
            height: 80px;
            background: #F8F9FA;
            border: 2px solid var(--border);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
            font-size: 2.5rem;
            transition: all 0.3s;
            color: #000000;
        }
        
        .logo-icon:hover {
            transform: scale(1.05);
            border-color: #000000;
        }
        
        .login-header h2 {
            font-family: var(--font-display);
            font-size: 1.8rem;
            font-weight: 700;
            margin-bottom: 8px;
            letter-spacing: -0.5px;
            color: #000000;
        }
        
        .login-header p {
            font-size: 0.85rem;
            opacity: 0.7;
            letter-spacing: 0.5px;
            color: #6C757D;
        }
        
        .login-body {
            padding: 40px;
        }
        
        .form-group {
            margin-bottom: 24px;
        }
        
        .form-group label {
            font-size: 0.8rem;
            font-weight: 600;
            margin-bottom: 8px;
            display: block;
            color: var(--text);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .input-group-custom {
            display: flex;
            align-items: center;
            border: 1.5px solid var(--border);
            border-radius: 12px;
            transition: all 0.3s;
            background: white;
        }
        
        .input-group-custom:focus-within {
            border-color: #000000;
            box-shadow: 0 0 0 3px rgba(0,0,0,0.1);
        }
        
        .input-group-text-custom {
            padding: 12px 15px;
            background: transparent;
            border: none;
            color: var(--text-muted);
            cursor: pointer;
            transition: color 0.3s;
        }
        
        .input-group-text-custom:hover {
            color: #000000;
        }
        
        .input-group-custom input,
        .input-group-custom select {
            border: none;
            padding: 12px 15px 12px 0;
            flex: 1;
            outline: none;
            font-size: 0.9rem;
            background: transparent;
            font-family: var(--font-body);
        }
        
        .input-group-custom select {
            cursor: pointer;
        }
        
        .input-group-custom input::placeholder {
            color: var(--text-muted);
            font-size: 0.85rem;
        }
        
        /* Password strength indicator */
        .password-strength {
            margin-top: 8px;
            font-size: 0.7rem;
        }
        
        .strength-bar {
            height: 3px;
            background: var(--border);
            border-radius: 3px;
            margin-top: 8px;
            transition: all 0.3s;
        }
        
        .strength-bar.weak { width: 25%; background: #DC3545; }
        .strength-bar.medium { width: 50%; background: #FFC107; }
        .strength-bar.strong { width: 75%; background: #28A745; }
        .strength-bar.very-strong { width: 100%; background: #28A745; }
        
        .checkbox-group {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
        }
        
        .checkbox-custom {
            display: flex;
            align-items: center;
            gap: 8px;
            cursor: pointer;
            font-size: 0.8rem;
            color: var(--text-muted);
        }
        
        .checkbox-custom input {
            width: 16px;
            height: 16px;
            cursor: pointer;
        }
        
        .forgot-link {
            font-size: 0.8rem;
            color: #000000;
            text-decoration: none;
            font-weight: 500;
            transition: opacity 0.3s;
        }
        
        .forgot-link:hover {
            opacity: 0.7;
            text-decoration: underline;
        }
        
        .btn-login {
            width: 100%;
            padding: 14px;
            background: #000000;
            color: white;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            font-size: 0.9rem;
            transition: all 0.3s;
            margin-top: 10px;
            cursor: pointer;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .btn-login:hover {
            background: #1a1a1a;
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.2);
        }
        
        .register-link {
            text-align: center;
            margin-top: 24px;
            padding-top: 24px;
            border-top: 1px solid var(--border);
        }
        
        .register-link p {
            font-size: 0.85rem;
            color: var(--text-muted);
            margin: 0;
        }
        
        .register-link a {
            color: #000000;
            text-decoration: none;
            font-weight: 700;
            margin-left: 5px;
            transition: opacity 0.3s;
        }
        
        .register-link a:hover {
            opacity: 0.7;
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
        
        .alert-custom {
            padding: 12px 16px;
            border-radius: 12px;
            margin-bottom: 24px;
            font-size: 0.85rem;
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
        
        .role-hint {
            font-size: 0.7rem;
            color: var(--text-muted);
            margin-top: 6px;
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
            .login-body {
                padding: 30px 25px;
            }
            
            .login-header {
                padding: 30px 25px;
            }
            
            .login-header h2 {
                font-size: 1.5rem;
            }
        }
        
        /* Custom checkbox styling */
        .checkbox-custom input[type="checkbox"] {
            accent-color: #000000;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="login-card">
            <div class="login-header">
                <div class="logo-icon">
                    <i class="bi bi-shop"></i>
                </div>
                <h2>Mpeoa Supermarket</h2>
                <p>Enterprise Resource Planning System</p>
            </div>
            
            <div class="login-body">
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
                
                <form action="${pageContext.request.contextPath}/login" method="post" id="loginForm">
                    <div class="form-group">
                        <label>USERNAME</label>
                        <div class="input-group-custom">
                            <span class="input-group-text-custom">
                                <i class="bi bi-person"></i>
                            </span>
                            <input type="text" name="username" placeholder="Enter your username" 
                                   value="<%= rememberUsername %>" required autofocus>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>ROLE</label>
                        <div class="input-group-custom">
                            <span class="input-group-text-custom">
                                <i class="bi bi-briefcase"></i>
                            </span>
                            <select name="role" id="roleSelect" required>
                                <option value="">Select your role</option>
                                <option value="Administrator">Administrator</option>
                                <option value="Manager">Manager</option>
                                <option value="Accountant">Accountant</option>
                                <option value="Cashier">Cashier</option>
                                <option value="Inventory Officer">Inventory Officer</option>
                            </select>
                        </div>
                        <div class="role-hint">
                            <i class="bi bi-info-circle"></i> Select the role assigned to you by the administrator
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>PASSWORD</label>
                        <div class="input-group-custom">
                            <span class="input-group-text-custom">
                                <i class="bi bi-lock"></i>
                            </span>
                            <input type="password" name="password" id="password" placeholder="Enter your password" required>
                            <span class="input-group-text-custom toggle-password" onclick="togglePassword()">
                                <i class="bi bi-eye-slash" id="toggleIcon"></i>
                            </span>
                        </div>
                        <div class="password-strength" id="passwordStrength">
                            <span id="strengthText" style="color: var(--text-muted);">Password strength: </span>
                            <div class="strength-bar" id="strengthBar"></div>
                        </div>
                    </div>
                    
                    <div class="checkbox-group">
                        <label class="checkbox-custom">
                            <input type="checkbox" name="remember" <%= !rememberUsername.isEmpty() ? "checked" : "" %>>
                            <span>Remember me</span>
                        </label>
                        <a href="${pageContext.request.contextPath}/forgot-password" class="forgot-link">
                            Forgot Password?
                        </a>
                    </div>
                    
                    <button type="submit" class="btn-login">
                        <i class="bi bi-box-arrow-in-right"></i> Sign In
                    </button>
                </form>
                
                <div class="register-link">
                    <p>Don't have an account? 
                        <a href="${pageContext.request.contextPath}/views/register.jsp">
                            Contact Administrator <i class="bi bi-arrow-right"></i>
                        </a>
                    </p>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Toggle password visibility
        function togglePassword() {
            const passwordInput = document.getElementById('password');
            const toggleIcon = document.getElementById('toggleIcon');
            
            if (passwordInput.type === 'password') {
                passwordInput.type = 'text';
                toggleIcon.classList.remove('bi-eye-slash');
                toggleIcon.classList.add('bi-eye');
            } else {
                passwordInput.type = 'password';
                toggleIcon.classList.remove('bi-eye');
                toggleIcon.classList.add('bi-eye-slash');
            }
        }
        
        // Password strength checker
        const passwordInput = document.getElementById('password');
        const strengthText = document.getElementById('strengthText');
        const strengthBar = document.getElementById('strengthBar');
        
        function checkPasswordStrength(password) {
            let strength = 0;
            
            // Length check
            if (password.length >= 8) strength++;
            if (password.length >= 12) strength++;
            
            // Contains lowercase
            if (password.match(/[a-z]+/)) strength++;
            
            // Contains uppercase
            if (password.match(/[A-Z]+/)) strength++;
            
            // Contains numbers
            if (password.match(/[0-9]+/)) strength++;
            
            // Contains special characters
            if (password.match(/[$@#&!]+/)) strength++;
            
            return Math.min(strength, 4);
        }
        
        function updateStrengthIndicator() {
            const password = passwordInput.value;
            
            if (password.length === 0) {
                strengthText.innerHTML = 'Password strength: ';
                strengthBar.className = 'strength-bar';
                strengthBar.style.background = 'var(--border)';
                return;
            }
            
            const strength = checkPasswordStrength(password);
            
            switch(strength) {
                case 1:
                    strengthText.innerHTML = 'Password strength: <span style="color: #DC3545;">Weak</span>';
                    strengthBar.className = 'strength-bar weak';
                    break;
                case 2:
                    strengthText.innerHTML = 'Password strength: <span style="color: #FFC107;">Medium</span>';
                    strengthBar.className = 'strength-bar medium';
                    break;
                case 3:
                    strengthText.innerHTML = 'Password strength: <span style="color: #28A745;">Strong</span>';
                    strengthBar.className = 'strength-bar strong';
                    break;
                case 4:
                    strengthText.innerHTML = 'Password strength: <span style="color: #28A745;">Very Strong</span>';
                    strengthBar.className = 'strength-bar very-strong';
                    break;
                default:
                    strengthText.innerHTML = 'Password strength: <span style="color: #6C757D;">Too weak</span>';
                    strengthBar.className = 'strength-bar';
                    strengthBar.style.background = 'var(--border)';
            }
        }
        
        passwordInput.addEventListener('keyup', updateStrengthIndicator);
        
        // Form validation for strong password
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            const password = passwordInput.value;
            const strength = checkPasswordStrength(password);
            const role = document.getElementById('roleSelect').value;
            
            if (strength < 2) {
                e.preventDefault();
                alert('Please use a stronger password (minimum 8 characters, with uppercase, lowercase, and numbers)');
            }
            
            if (!role) {
                e.preventDefault();
                alert('Please select your role');
            }
        });
    </script>
</body>
</html>